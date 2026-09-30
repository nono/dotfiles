// Command hunkmut finds the hunks of a Go change that no test pins. It reverts each non-test hunk alone, runs the
// tests, and lists the hunks whose revert leaves every test green. It also runs the tests against the base code, to
// show whether any of them fails without the change.
//
// It edits the files of the worktree it is given, and restores them after each run. Give it a throwaway worktree.
package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"os"
	"os/exec"
	"os/signal"
	"path"
	"path/filepath"
	"slices"
	"strings"
	"syscall"
	"time"
)

type config struct {
	tester
	base   string
	kinds  map[string]bool // the kinds of mutant to run
	budget time.Duration   // no mutant starts after this time from the start; 0 for no limit
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "hunkmut:", err)
		os.Exit(1)
	}
}

func run() error {
	var cfg config
	var pkgs string
	flag.StringVar(&cfg.dir, "dir", ".", "a clean throwaway worktree at the head of the change; hunkmut edits its files")
	flag.StringVar(&cfg.base, "base", "", "the base of the change (required); hunkmut diffs its merge base with HEAD")
	flag.StringVar(&pkgs, "pkgs", "", "comma-separated packages to test (default: the packages of the changed Go files)")
	flag.StringVar(&cfg.run, "run", "", "passed to go test -run")
	flag.StringVar(&cfg.tags, "tags", "", "passed to go test -tags")
	flag.DurationVar(&cfg.timeout, "timeout", 10*time.Minute,
		"passed to go test -timeout for the run at HEAD; a mutant gets twice that run's time plus 30s, up to this")
	flag.StringVar(&cfg.memMax, "mem", "8G", "the memory cap of each go test run, through systemd-run; 0 for none")
	flag.DurationVar(&cfg.budget, "budget", 0, "start no mutant after this time from the start, and list the "+
		"mutants not run; 0 for no limit")
	kinds := flag.String("kinds", "revert,drop,negate", "comma-separated kinds of mutant: "+
		"revert a hunk, drop a statement, negate an if")
	flag.Parse()
	cfg.kinds = map[string]bool{}
	for k := range strings.SplitSeq(*kinds, ",") {
		if k != kindRevert && k != kindDrop && k != kindNegate {
			return fmt.Errorf("unknown kind of mutant %q", k)
		}
		cfg.kinds[k] = true
	}
	if cfg.base == "" {
		return errors.New("-base is required")
	}
	if pkgs != "" {
		cfg.pkgs = strings.Split(pkgs, ",")
	}
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	rep, err := mutate(ctx, cfg, os.Stderr)
	if err != nil {
		return err
	}
	rep.write(os.Stdout)
	return nil
}

type report struct {
	mergeBase   string
	pkgs        []string
	onBase      testResult // the tests at the head, run against the base code
	survived    []mutant
	broke       []mutant
	killed      []mutant
	commentOnly int
	deleted     []string // files the change deletes, not mutated
	notRun      []mutant // mutants left when the budget ran out
	budget      time.Duration
}

func mutate(ctx context.Context, cfg config, progress io.Writer) (report, error) {
	began := time.Now()
	if out, err := git(ctx, cfg.dir, "status", "--porcelain"); err != nil {
		return report{}, err
	} else if out != "" {
		return report{}, fmt.Errorf("%s has uncommitted changes; run hunkmut in a clean throwaway worktree", cfg.dir)
	}
	mb, err := git(ctx, cfg.dir, "merge-base", cfg.base, "HEAD")
	if err != nil {
		return report{}, err
	}
	mb = strings.TrimSpace(mb)
	text, err := git(ctx, cfg.dir, "-c", "core.quotePath=false", "diff", "-U0", "--no-color", "--no-ext-diff",
		"--no-renames", "--src-prefix=a/", "--dst-prefix=b/", mb, "HEAD", "--", "*.go")
	if err != nil {
		return report{}, err
	}
	files, err := parseDiff(text)
	if err != nil {
		return report{}, err
	}
	var code []fileDiff
	dirs := map[string]struct{}{}
	for _, f := range files {
		if strings.Contains("/"+f.path, "/testdata/") {
			continue
		}
		dirs[path.Dir(f.path)] = struct{}{}
		if !strings.HasSuffix(f.path, "_test.go") {
			code = append(code, f)
		}
	}
	if len(code) == 0 {
		return report{}, errors.New("the change holds no non-test Go file")
	}
	if len(cfg.pkgs) == 0 {
		cfg.pkgs = packagesOf(cfg.dir, dirs)
	}
	rep := report{mergeBase: mb, pkgs: cfg.pkgs, budget: cfg.budget}

	fmt.Fprintf(progress, "hunkmut: testing HEAD (%s)\n", strings.Join(cfg.pkgs, " "))
	start := time.Now()
	res, err := cfg.test(ctx)
	if err != nil {
		return rep, err
	}
	if !res.passed() {
		return rep, fmt.Errorf("the tests fail at HEAD, so no hunk can be judged:\n%s", describe(res))
	}
	cfg.timeout = min(cfg.timeout, 2*time.Since(start)+30*time.Second) // a mutant that hangs a test fails it

	ws := &workspace{dir: cfg.dir, saved: map[string]savedFile{}}
	defer ws.restore()

	fmt.Fprintln(progress, "hunkmut: testing the base code")
	for _, f := range code {
		if f.added {
			err = ws.remove(f.path)
		} else {
			var data string
			if data, err = git(ctx, cfg.dir, "show", mb+":"+f.path); err == nil {
				err = ws.write(f.path, data)
			}
		}
		if err != nil {
			return rep, err
		}
	}
	if rep.onBase, err = cfg.test(ctx); err != nil {
		return rep, err
	}
	if err := ws.restore(); err != nil {
		return rep, err
	}

	var ms []mutant
	for _, f := range code {
		if f.deleted {
			rep.deleted = append(rep.deleted, f.path)
			continue
		}
		fm, comments := mutantsOf(f, cfg.kinds)
		ms = append(ms, fm...)
		rep.commentOnly += comments
	}
	heads := map[string][]string{}
	trailings := map[string]bool{}
	for i, m := range ms {
		if cfg.budget > 0 && time.Since(began) >= cfg.budget {
			rep.notRun = ms[i:]
			fmt.Fprintf(progress, "hunkmut: the budget of %s is spent; %d mutants not run\n", cfg.budget, len(ms)-i)
			break
		}
		if _, ok := heads[m.path]; !ok {
			data, err := os.ReadFile(filepath.Join(cfg.dir, m.path))
			if err != nil {
				return rep, err
			}
			heads[m.path], trailings[m.path] = splitLines(string(data))
		}
		mutated, err := m.apply(heads[m.path])
		if err != nil {
			return rep, fmt.Errorf("%s: %w", m.path, err)
		}
		if err := ws.write(m.path, joinLines(mutated, trailings[m.path])); err != nil {
			return rep, err
		}
		res, err := cfg.testMutant(ctx, m.path)
		if err != nil {
			return rep, err
		}
		if err := ws.restore(); err != nil {
			return rep, err
		}
		m.killers = res.failed
		var verdict string
		switch {
		case len(res.buildFailed) > 0:
			rep.broke, verdict = append(rep.broke, m), "breaks the build"
		case len(res.failed) > 0:
			rep.killed, verdict = append(rep.killed, m), "killed"
		default:
			rep.survived, verdict = append(rep.survived, m), "SURVIVED"
		}
		fmt.Fprintf(progress, "hunkmut: [%d/%d] %s %s %s\n", i+1, len(ms), m.kind, location(m), verdict)
	}
	return rep, nil
}

// testMutant compiles the package of the mutated file, then runs its tests, then the tests of the other packages
// only if its own pass. A failed build is reported as the package's build failure.
func (cfg config) testMutant(ctx context.Context, file string) (testResult, error) {
	own := packageOf(path.Dir(file))
	if ok, err := cfg.builds(ctx, own); err != nil || !ok {
		return testResult{buildFailed: []string{own}}, err
	}
	var rest []string
	if slices.Contains(cfg.pkgs, own) {
		res, err := cfg.testPkgs(ctx, []string{own}, true)
		if err != nil || !res.passed() {
			return res, err
		}
		rest = slices.DeleteFunc(slices.Clone(cfg.pkgs), func(p string) bool { return p == own })
	} else {
		rest = cfg.pkgs
	}
	if len(rest) == 0 {
		return testResult{}, nil
	}
	return cfg.testPkgs(ctx, rest, true)
}

func packageOf(dir string) string {
	if dir == "." {
		return "."
	}
	return "./" + dir
}

// packagesOf returns the package pattern of each directory that holds Go files at the head.
func packagesOf(dir string, dirs map[string]struct{}) []string {
	var pkgs []string
	for d := range dirs {
		if matches, _ := filepath.Glob(filepath.Join(dir, d, "*.go")); len(matches) == 0 {
			continue
		}
		pkgs = append(pkgs, packageOf(d))
	}
	slices.Sort(pkgs)
	return pkgs
}

func git(ctx context.Context, dir string, args ...string) (string, error) {
	cmd := exec.CommandContext(ctx, "git", append([]string{"-C", dir}, args...)...)
	var stderr strings.Builder
	cmd.Stderr = &stderr
	out, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("git %s: %w: %s", strings.Join(args, " "), err, stderr.String())
	}
	return string(out), nil
}

type savedFile struct {
	exists bool
	data   []byte
	mode   fs.FileMode
}

// workspace edits the files of a worktree and puts back their head state.
type workspace struct {
	dir   string
	saved map[string]savedFile
}

func (w *workspace) save(rel string) error {
	if _, ok := w.saved[rel]; ok {
		return nil
	}
	p := filepath.Join(w.dir, rel)
	info, err := os.Stat(p)
	if errors.Is(err, fs.ErrNotExist) {
		w.saved[rel] = savedFile{}
		return nil
	} else if err != nil {
		return err
	}
	data, err := os.ReadFile(p)
	if err != nil {
		return err
	}
	w.saved[rel] = savedFile{exists: true, data: data, mode: info.Mode().Perm()}
	return nil
}

func (w *workspace) write(rel, data string) error {
	if err := w.save(rel); err != nil {
		return err
	}
	p := filepath.Join(w.dir, rel)
	if err := os.MkdirAll(filepath.Dir(p), 0o755); err != nil {
		return err
	}
	return os.WriteFile(p, []byte(data), 0o644)
}

func (w *workspace) remove(rel string) error {
	if err := w.save(rel); err != nil {
		return err
	}
	return os.Remove(filepath.Join(w.dir, rel))
}

func (w *workspace) restore() error {
	var errs []error
	for rel, s := range w.saved {
		p := filepath.Join(w.dir, rel)
		if s.exists {
			errs = append(errs, os.WriteFile(p, s.data, s.mode))
		} else if err := os.Remove(p); err != nil && !errors.Is(err, fs.ErrNotExist) {
			errs = append(errs, err)
		}
	}
	clear(w.saved)
	return errors.Join(errs...)
}

func location(m mutant) string {
	switch {
	case m.kind != kindRevert, m.h.newCount == 1:
		return fmt.Sprintf("%s:%d", m.path, m.line)
	case m.h.newCount == 0:
		return fmt.Sprintf("%s:%d+", m.path, m.h.newStart)
	default:
		return fmt.Sprintf("%s:%d-%d", m.path, m.h.newStart, m.h.newStart+m.h.newCount-1)
	}
}

func describe(r testResult) string {
	var b strings.Builder
	for _, p := range r.buildFailed {
		fmt.Fprintf(&b, "- build failed: %s\n", p)
	}
	for _, t := range r.failed {
		fmt.Fprintf(&b, "- %s\n", t)
	}
	return b.String()
}

func (r report) write(w io.Writer) {
	fmt.Fprintf(w, "# hunkmut\n\nMerge base %.12s. Packages tested: %s.\n\n", r.mergeBase, strings.Join(r.pkgs, " "))
	fmt.Fprint(w, "## The tests on the base code\n\n")
	switch {
	case len(r.onBase.buildFailed) > 0:
		fmt.Fprintf(w, "The tests do not compile against the base code, so this check shows nothing:\n\n%s\n",
			describe(testResult{buildFailed: r.onBase.buildFailed}))
	case r.onBase.passed():
		fmt.Fprint(w, "**No test fails on the base code: no test pins this change.**\n\n")
	default:
		fmt.Fprintf(w, "These tests fail on the base code, so they pin the change:\n\n%s\n", describe(r.onBase))
	}
	fmt.Fprintf(w, "## Mutants no test kills (%d)\n\n", len(r.survived))
	if len(r.survived) > 0 {
		fmt.Fprint(w, "Each mutant below was applied alone, and every test stayed green.\n\n")
	}
	for _, m := range r.survived {
		switch m.kind {
		case kindRevert:
			fmt.Fprintf(w, "- `%s` revert of the hunk:\n", location(m))
			for _, l := range m.h.oldLines {
				fmt.Fprintf(w, "  - `-%s`\n", strings.TrimSpace(l))
			}
			for _, l := range m.h.newLines {
				fmt.Fprintf(w, "  - `+%s`\n", strings.TrimSpace(l))
			}
		case kindDrop:
			fmt.Fprintf(w, "- `%s` drop `%s`\n", location(m), strings.TrimSpace(m.text))
		case kindNegate:
			negated, _ := negateIf(m.text)
			fmt.Fprintf(w, "- `%s` negate: `%s`\n", location(m), strings.TrimSpace(negated))
		}
	}
	fmt.Fprintf(w, "\n## Mutants a test kills (%d)\n\n", len(r.killed))
	for _, m := range r.killed {
		k := m.killers
		if len(k) > 3 {
			k = append(k[:3:3], fmt.Sprintf("%d more", len(m.killers)-3))
		}
		fmt.Fprintf(w, "- `%s` %s, by %s\n", location(m), m.kind, strings.Join(k, ", "))
	}
	fmt.Fprintf(w, "\n## Not judged\n\n")
	fmt.Fprintf(w, "- %d mutants that break the build\n", len(r.broke))
	fmt.Fprintf(w, "- %d comment-only hunks\n", r.commentOnly)
	if len(r.notRun) > 0 {
		fmt.Fprintf(w, "- %d mutants not run: the budget of %s was spent\n", len(r.notRun), r.budget)
		for _, m := range r.notRun {
			fmt.Fprintf(w, "  - `%s` %s\n", location(m), m.kind)
		}
	}
	for _, p := range r.deleted {
		fmt.Fprintf(w, "- deleted file `%s`\n", p)
	}
}
