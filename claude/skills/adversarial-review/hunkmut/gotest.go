package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"slices"
	"strings"
	"time"
)

// testResult is the outcome of one go test run.
type testResult struct {
	buildFailed []string // packages that did not compile
	failed      []string // failed tests as "package Test", and packages that failed outside a test
}

func (r testResult) passed() bool { return len(r.buildFailed) == 0 && len(r.failed) == 0 }

type testEvent struct {
	Action      string
	Package     string
	ImportPath  string
	Test        string
	FailedBuild string
}

// parseTestEvents reads the stream of go test -json.
func parseTestEvents(r io.Reader) (testResult, error) {
	var res testResult
	build := map[string]struct{}{}
	testFailed := map[string]struct{}{}
	var pkgFailed []string
	dec := json.NewDecoder(r)
	for {
		var e testEvent
		if err := dec.Decode(&e); errors.Is(err, io.EOF) {
			break
		} else if err != nil {
			return res, fmt.Errorf("read go test -json: %w", err)
		}
		switch {
		case e.Action == "build-fail":
			build[e.ImportPath] = struct{}{}
		case e.Action == "fail" && e.Test != "":
			res.failed = append(res.failed, e.Package+" "+e.Test)
			testFailed[e.Package] = struct{}{}
		case e.Action == "fail" && e.FailedBuild != "":
			build[e.FailedBuild] = struct{}{}
		case e.Action == "fail":
			pkgFailed = append(pkgFailed, e.Package)
		}
	}
	for _, p := range pkgFailed {
		if _, ok := testFailed[p]; !ok {
			if _, ok := build[p]; !ok {
				res.failed = append(res.failed, p+" (outside a test)")
			}
		}
	}
	for p := range build {
		res.buildFailed = append(res.buildFailed, p)
	}
	slices.Sort(res.buildFailed)
	return res, nil
}

// tester runs the tests of pkgs in dir.
type tester struct {
	dir     string
	pkgs    []string
	run     string
	tags    string
	timeout time.Duration
	memMax  string // the memory cap of a run, for systemd-run; "0" runs with none
}

// command returns a go command in dir, under the memory cap.
func (t tester) command(ctx context.Context, args ...string) *exec.Cmd {
	cmd := exec.CommandContext(ctx, "go", args...)
	if t.memMax != "" && t.memMax != "0" { // a mutant can make a test allocate without bound, and the OOM killer then takes the terminal
		cmd = exec.CommandContext(ctx, "systemd-run", slices.Concat([]string{"--user", "--scope", "--quiet",
			"--collect", "-p", "MemoryMax=" + t.memMax, "-p", "MemorySwapMax=0", "-p", "OOMPolicy=continue", "--", "go"},
			args)...)
	}
	cmd.Dir = t.dir
	cmd.Env = append(os.Environ(), "TESTCONTAINERS_RYUK_DISABLED=true")
	return cmd
}

// builds reports whether pkg compiles, test files left out.
func (t tester) builds(ctx context.Context, pkg string) (bool, error) {
	args := []string{"build", "-o", os.DevNull}
	if t.tags != "" {
		args = append(args, "-tags", t.tags)
	}
	cmd := t.command(ctx, append(args, pkg)...)
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	err := cmd.Run()
	if exitErr, ok := errors.AsType[*exec.ExitError](err); ok && exitErr.ExitCode() == 1 {
		return false, nil
	} else if err != nil {
		return false, fmt.Errorf("go build %s: %w\n%s", pkg, err, stderr.String())
	}
	return true, nil
}

// test runs the tests of all the packages.
func (t tester) test(ctx context.Context) (testResult, error) { return t.testPkgs(ctx, t.pkgs, false) }

// testPkgs runs the tests of pkgs. With failfast, a package stops at its first failed test.
func (t tester) testPkgs(ctx context.Context, pkgs []string, failfast bool) (testResult, error) {
	args := []string{"test", "-json", "-count=1", "-vet=off", "-timeout", t.timeout.String()}
	if failfast {
		args = append(args, "-failfast")
	}
	if t.tags != "" {
		args = append(args, "-tags", t.tags)
	}
	if t.run != "" {
		args = append(args, "-run", t.run)
	}
	args = append(args, pkgs...)
	runCtx, cancel := context.WithTimeout(ctx, t.timeout+2*time.Minute) // go test -timeout fires first
	defer cancel()
	cmd := t.command(runCtx, args...)
	var stdout, stderr bytes.Buffer
	cmd.Stdout, cmd.Stderr = &stdout, &stderr
	runErr := cmd.Run()
	if err := runCtx.Err(); err != nil {
		return testResult{}, fmt.Errorf("go test %s: %w", strings.Join(pkgs, " "), err)
	}
	res, err := parseTestEvents(&stdout)
	if err != nil {
		return res, err
	}
	if exitErr, ok := errors.AsType[*exec.ExitError](runErr); ok && res.passed() && exitErr.ExitCode() == 137 {
		res.failed = []string{"(go test killed at the memory cap)"}
		return res, nil
	}
	if runErr != nil && res.passed() { // a failure the JSON does not show, such as a package that does not exist
		return res, fmt.Errorf("go test %s: %w\n%s", strings.Join(pkgs, " "), runErr, stderr.String())
	}
	return res, nil
}
