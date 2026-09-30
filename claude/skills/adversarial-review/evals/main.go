// Command revieweval runs reviewers of the adversarial-review skill on past pull requests, and checks each report
// against the findings of the human review of that pull request.
package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"os"
	"os/signal"
	"path/filepath"
	"slices"
	"strconv"
	"strings"
	"syscall"
)

// expectation is one finding of a human review, and the reviewers whose job covers it.
type expectation struct {
	ID      string   `json:"id"`
	Agents  []string `json:"agents"`
	Finding string   `json:"finding"`
}

// The splits of the cases. Prompts are tuned on train and scored on test; the human found nothing in a clean case.
const (
	splitTrain = "train"
	splitTest  = "test"
	splitClean = "clean"
)

type evalCase struct {
	PR     int           `json:"pr"`
	Title  string        `json:"title"`
	Split  string        `json:"split"`
	Base   string        `json:"base"` // the merge base
	Head   string        `json:"head"` // the commit the human reviewed
	Expect []expectation `json:"expect"`
}

type caseFile struct {
	Repo  string     `json:"repo"`
	Cases []evalCase `json:"cases"`
}

// roleFiles gives the prompt file of each reviewer, under prompts/ in the skill directory.
var roleFiles = map[string]string{"A": "reviewer.md", "B": "reviewer.md", "C": "nitpicker.md", "D": "modeler.md",
	"E": "claims.md"}

// agentTypes gives the Claude Code agent of each reviewer; B runs on codex.
var agentTypes = map[string]string{"A": "adversarial-reviewer", "C": "adversarial-nitpicker",
	"D": "adversarial-modeler", "E": "adversarial-claim-auditor"}

type config struct {
	skill      string
	out        string
	prs        []int
	agents     []string
	splits     []string
	reps       int
	parallel   int
	budgetUSD  float64
	memMax     string // the memory cap of each run, through systemd-run; "0" for none
	keep       bool
	judgeCheck bool
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "revieweval:", err)
		os.Exit(1)
	}
}

func run() error {
	home, err := os.UserHomeDir()
	if err != nil {
		return err
	}
	var cfg config
	var prs, agents, splits string
	flag.StringVar(&cfg.skill, "skill", filepath.Join(home, ".claude/skills/adversarial-review"), "the skill directory")
	flag.StringVar(&cfg.out, "out", "", "the directory for the reports and results (required)")
	flag.StringVar(&prs, "prs", "", "comma-separated pull requests to run (default: every case of the splits)")
	flag.StringVar(&agents, "agents", "A,E", "comma-separated reviewers to run: A, B, C, D or E")
	flag.StringVar(&splits, "splits", "train,clean", "comma-separated splits to run: train, test, clean")
	flag.IntVar(&cfg.reps, "reps", 3, "runs of each reviewer on each case")
	flag.IntVar(&cfg.parallel, "parallel", 2, "reviewers run at the same time")
	flag.Float64Var(&cfg.budgetUSD, "budget-usd", 10, "the spending cap of each Claude reviewer run")
	flag.StringVar(&cfg.memMax, "mem", "10G", "the memory cap of each reviewer run, through systemd-run; 0 for none")
	flag.BoolVar(&cfg.keep, "keep", false, "keep the repositories the reviewers ran in")
	flag.BoolVar(&cfg.judgeCheck, "judge-check", false, "run no reviewer; test the judge on reports whose "+
		"verdicts are known, twice each")
	flag.Parse()
	if cfg.out == "" {
		return errors.New("-out is required")
	}
	if cfg.out, err = filepath.Abs(cfg.out); err != nil {
		return err
	}
	if err := os.MkdirAll(cfg.out, 0o755); err != nil {
		return err
	}
	for p := range strings.SplitSeq(prs, ",") {
		if p == "" {
			continue
		}
		n, err := strconv.Atoi(p)
		if err != nil {
			return fmt.Errorf("-prs: %w", err)
		}
		cfg.prs = append(cfg.prs, n)
	}
	for a := range strings.SplitSeq(agents, ",") {
		if _, ok := roleFiles[a]; !ok {
			return fmt.Errorf("unknown reviewer %q", a)
		}
		cfg.agents = append(cfg.agents, a)
	}
	for s := range strings.SplitSeq(splits, ",") {
		if s != splitTrain && s != splitTest && s != splitClean {
			return fmt.Errorf("unknown split %q", s)
		}
		cfg.splits = append(cfg.splits, s)
	}
	cases, err := loadCases(filepath.Join(cfg.skill, "evals/cases.json"))
	if err != nil {
		return err
	}
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	if cfg.judgeCheck {
		return checkJudge(ctx, cfg, cases, os.Stderr)
	}
	results, err := evaluate(ctx, cfg, cases, os.Stderr)
	if err != nil {
		return err
	}
	return writeResults(cfg.out, results)
}

func loadCases(path string) (caseFile, error) {
	f, err := os.Open(path)
	if err != nil {
		return caseFile{}, err
	}
	defer f.Close()
	var cf caseFile
	dec := json.NewDecoder(f)
	dec.DisallowUnknownFields()
	if err := dec.Decode(&cf); err != nil {
		return caseFile{}, fmt.Errorf("%s: %w", path, err)
	}
	ids := map[string]struct{}{}
	for _, c := range cf.Cases {
		switch {
		case c.Split != splitTrain && c.Split != splitTest && c.Split != splitClean:
			return caseFile{}, fmt.Errorf("%s: #%d has unknown split %q", path, c.PR, c.Split)
		case c.Split == splitClean && len(c.Expect) > 0:
			return caseFile{}, fmt.Errorf("%s: clean case #%d holds expectations", path, c.PR)
		case c.Split != splitClean && len(c.Expect) == 0:
			return caseFile{}, fmt.Errorf("%s: #%d holds no expectation", path, c.PR)
		}
		for _, e := range c.Expect {
			if _, dup := ids[e.ID]; dup {
				return caseFile{}, fmt.Errorf("%s: expectation %s appears twice", path, e.ID)
			}
			ids[e.ID] = struct{}{}
			if len(e.Agents) == 0 {
				return caseFile{}, fmt.Errorf("%s: expectation %s names no reviewer", path, e.ID)
			}
			for _, a := range e.Agents {
				if _, ok := roleFiles[a]; !ok {
					return caseFile{}, fmt.Errorf("%s: expectation %s names unknown reviewer %q", path, e.ID, a)
				}
			}
		}
	}
	return cf, nil
}

// job is one run of one reviewer on one case.
type job struct {
	c      evalCase
	agent  string
	rep    int
	dir    string // the job's output directory
	tree   string // the repository at the reviewed commit
	expect []expectation
}

// selected returns the cases of cfg's splits and pull requests.
func selected(cfg config, cf caseFile) []evalCase {
	var cs []evalCase
	for _, c := range cf.Cases {
		if slices.Contains(cfg.splits, c.Split) && (len(cfg.prs) == 0 || slices.Contains(cfg.prs, c.PR)) {
			cs = append(cs, c)
		}
	}
	return cs
}

// jobsOf returns cfg.reps jobs for each selected case and each reviewer of cfg that has an expectation to meet
// there, or for every reviewer of cfg on a clean case.
func jobsOf(cfg config, cf caseFile) []job {
	var jobs []job
	for _, c := range selected(cfg, cf) {
		for _, a := range cfg.agents {
			var exp []expectation
			for _, e := range c.Expect {
				if slices.Contains(e.Agents, a) {
					exp = append(exp, e)
				}
			}
			if len(exp) == 0 && c.Split != splitClean {
				continue
			}
			for rep := 1; rep <= max(cfg.reps, 1); rep++ {
				dir := filepath.Join(cfg.out, fmt.Sprintf("%d-%s-r%d", c.PR, a, rep))
				jobs = append(jobs, job{c: c, agent: a, rep: rep, dir: dir, tree: filepath.Join(dir, "tree"), expect: exp})
			}
		}
	}
	return jobs
}

// dispatch returns the prompt the skill sends to the reviewer of j.
func dispatch(skill string, j job) string {
	var b strings.Builder
	fmt.Fprintf(&b, "You are reviewer %s. Skill directory: `%s`. Review PR #%d (%s). Get the diff with "+
		"`git -C %s diff %s HEAD`. The merge base is `%s`.\n\n", j.agent, skill, j.c.PR, j.c.Title, j.tree, j.c.Base,
		j.c.Base)
	switch j.agent {
	case "A", "B":
		fmt.Fprintf(&b, "Your worktree: `%s`.\n\n", j.tree)
	case "D":
		fmt.Fprintf(&b, "Write your model under `%s`.\n\n", filepath.Join(j.dir, "quint"))
	case "E":
		fmt.Fprintf(&b, "PR body: `%s`.\n\n", filepath.Join(skill, "evals/bodies", fmt.Sprintf("%d.md", j.c.PR)))
	}
	if j.agent != "C" && j.agent != "E" {
		b.WriteString("The change is meant to implement this:\n\nNo spec was found; judge the code on its own.\n\n")
	}
	fmt.Fprintf(&b, "Read `%s`, then `%s`, in full before you start, and follow them.\n",
		filepath.Join(skill, "prompts/common.md"), filepath.Join(skill, "prompts", roleFiles[j.agent]))
	return b.String()
}
