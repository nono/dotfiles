package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

func TestTheCasesFileIsValid(t *testing.T) {
	cf, err := loadCases("cases.json")
	if err != nil {
		t.Fatal(err)
	}
	splits := map[string]int{}
	for _, c := range cf.Cases {
		splits[c.Split]++
		if len(c.Base) != 40 || len(c.Head) != 40 {
			t.Errorf("#%d: base and head must be full commit ids", c.PR)
		}
		body, err := os.ReadFile(filepath.Join("bodies", fmt.Sprintf("%d.md", c.PR)))
		if err != nil {
			t.Errorf("#%d: no PR body: %v", c.PR, err)
		}
		if strings.Contains(strings.ToLower(string(body)), "coderabbit") {
			t.Errorf("#%d: the PR body holds a CodeRabbit summary, which no draft body has", c.PR)
		}
	}
	for _, s := range []string{splitTrain, splitTest, splitClean} {
		if splits[s] == 0 {
			t.Errorf("no case in split %s", s)
		}
	}
}

func TestJobsOf(t *testing.T) {
	cf := caseFile{Cases: []evalCase{
		{PR: 1, Split: splitTrain, Expect: []expectation{{ID: "a", Agents: []string{"A"}}}},
		{PR: 2, Split: splitTest, Expect: []expectation{{ID: "b", Agents: []string{"A", "E"}}}},
		{PR: 3, Split: splitClean},
	}}
	cfg := config{out: "/out", agents: []string{"A", "E"}, splits: []string{splitTrain, splitClean}, reps: 2}
	var got []string
	for _, j := range jobsOf(cfg, cf) {
		got = append(got, fmt.Sprintf("%d-%s-r%d", j.c.PR, j.agent, j.rep))
	}
	want := "1-A-r1 1-A-r2 3-A-r1 3-A-r2 3-E-r1 3-E-r2"
	if strings.Join(got, " ") != want {
		t.Errorf("jobs = %v, want %s", got, want)
	}
}

func TestDispatch(t *testing.T) {
	c := evalCase{PR: 7, Title: "Fix it", Base: "b4se"}
	a := dispatch("/skill", job{c: c, agent: "A", dir: "/out/7-A-r1", tree: "/out/7-A-r1/tree"})
	for _, want := range []string{"You are reviewer A.", "Your worktree: `/out/7-A-r1/tree`", "No spec was found",
		"`/skill/prompts/common.md`, then `/skill/prompts/reviewer.md`", "git -C /out/7-A-r1/tree diff b4se HEAD"} {
		if !strings.Contains(a, want) {
			t.Errorf("dispatch of A lacks %q:\n%s", want, a)
		}
	}
	e := dispatch("/skill", job{c: c, agent: "E", dir: "/out/7-E-r1", tree: "/out/7-E-r1/tree"})
	for _, want := range []string{"You are reviewer E.", "PR body: `/skill/evals/bodies/7.md`", "prompts/claims.md"} {
		if !strings.Contains(e, want) {
			t.Errorf("dispatch of E lacks %q:\n%s", want, e)
		}
	}
	if strings.Contains(e, "Your worktree") || strings.Contains(e, "No spec") {
		t.Errorf("dispatch of E holds a line for A, B or D:\n%s", e)
	}
}

func TestParseJudgement(t *testing.T) {
	answer := "Here it is:\n```json\n{\"findings\": 3, \"verdicts\": [{\"id\": \"x-1\", \"found\": true, " +
		"\"quote\": \"The comment is false.\"}, {\"id\": \"x-2\", \"found\": false}]}\n```\n"
	jd, err := parseJudgement(answer)
	if err != nil {
		t.Fatal(err)
	}
	if jd.Findings != 3 {
		t.Errorf("findings = %d, want 3", jd.Findings)
	}
	vs := jd.verdictsFor([]expectation{{ID: "x-1"}, {ID: "x-2"}, {ID: "x-3"}})
	if !vs[0].Found || vs[0].Quote != "The comment is false." || vs[1].Found {
		t.Errorf("verdicts = %+v", vs)
	}
	if vs[2].Found || !strings.Contains(vs[2].Quote, "no verdict") {
		t.Errorf("x-3 = %+v, want a missed verdict", vs[2])
	}
	if _, err := parseJudgement("no JSON here"); err == nil {
		t.Error("an answer without JSON gave no error")
	}
}

func TestLeakSigns(t *testing.T) {
	actions := `{"command":"git -C /tmp/x/tree diff abc HEAD"}` + "\n" + `{"command":"git log origin/main"}` + "\n" +
		`{"file_path":"/home/me/repo/CLAUDE.md"}`
	got := strings.Join(leakSigns(actions, "/home/me/repo"), " ")
	if got != "origin/ /home/me/repo" {
		t.Errorf("leak signs = %q", got)
	}
	if s := leakSigns(`{"command":"go test ./common/models"}`, "/home/me/repo"); len(s) != 0 {
		t.Errorf("leak signs in a clean run: %v", s)
	}
}

func gitIn(t *testing.T, dir string, args ...string) string {
	t.Helper()
	cmd := exec.Command("git", append([]string{"-C", dir, "-c", "user.name=t", "-c", "user.email=t@t"}, args...)...)
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("git %v: %v\n%s", args, err, out)
	}
	return strings.TrimSpace(string(out))
}

// newRepo makes a repository with a base commit, the reviewed commit, and a later commit that fixes the review.
func newRepo(t *testing.T) (repo, base, head string) {
	t.Helper()
	t.Setenv("GIT_CONFIG_GLOBAL", os.DevNull)
	repo = t.TempDir()
	gitIn(t, repo, "init", "-q")
	gitIn(t, repo, "commit", "-q", "--allow-empty", "-m", "base")
	base = gitIn(t, repo, "rev-parse", "HEAD")
	gitIn(t, repo, "commit", "-q", "--allow-empty", "-m", "reviewed")
	head = gitIn(t, repo, "rev-parse", "HEAD")
	gitIn(t, repo, "commit", "-q", "--allow-empty", "-m", "the fix the review asked for")
	return repo, base, head
}

func TestPrepareHidesLaterHistory(t *testing.T) {
	repo, base, head := newRepo(t)
	dir := t.TempDir()
	j := job{c: evalCase{Base: base, Head: head}, dir: dir, tree: filepath.Join(dir, "tree")}
	if err := prepare(t.Context(), repo, j); err != nil {
		t.Fatal(err)
	}
	if got := gitIn(t, j.tree, "rev-parse", "HEAD"); got != head {
		t.Errorf("HEAD = %s, want the reviewed commit %s", got, head)
	}
	if log := gitIn(t, j.tree, "log", "--all", "--format=%s"); strings.Contains(log, "fix") {
		t.Errorf("the repository shows a commit after the reviewed one:\n%s", log)
	}
	if refs := gitIn(t, j.tree, "for-each-ref", "--format=%(refname)"); refs != "refs/heads/review" {
		t.Errorf("refs = %q, want only refs/heads/review", refs)
	}
	gitIn(t, j.tree, "diff", "--quiet", base, "HEAD")
}

// fakeClaude answers as a reviewer, in stream-json, when called with --agent, and as the judge otherwise.
const fakeClaude = `#!/bin/sh
cat > /dev/null
case " $* " in
*" --agent "*)
  sleep 1
  printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"tool_use","input":{"command":"git log origin/main"}}]}}'
  printf '%s\n' '{"type":"result","result":"The pool comment is false.","total_cost_usd":0.5}' ;;
*) printf '%s\n' '{"type":"result","result":"{\"findings\": 1, \"verdicts\": [{\"id\": \"x-1\", \"found\": true, \"quote\": \"The pool comment is false.\"}, {\"id\": \"x-2\", \"found\": false}]}","total_cost_usd":0.1}' ;;
esac
`

func TestEvaluate(t *testing.T) {
	bin := t.TempDir()
	if err := os.WriteFile(filepath.Join(bin, "claude"), []byte(fakeClaude), 0o755); err != nil {
		t.Fatal(err)
	}
	t.Setenv("PATH", bin+string(os.PathListSeparator)+os.Getenv("PATH"))
	repo, base, head := newRepo(t)
	c := evalCase{PR: 7, Title: "Fix it", Split: splitTrain, Base: base, Head: head, Expect: []expectation{
		{ID: "x-1", Agents: []string{"E"}, Finding: "the pool comment"},
		{ID: "x-2", Agents: []string{"E"}, Finding: "the docstring"},
		{ID: "x-3", Agents: []string{"A"}, Finding: "not for E"},
	}}
	out := t.TempDir()
	cfg := config{skill: "/skill", out: out, agents: []string{"E"}, splits: []string{splitTrain}, reps: 2, parallel: 2,
		budgetUSD: 1, memMax: "0"}
	results, err := evaluate(t.Context(), cfg, caseFile{Repo: repo, Cases: []evalCase{c}}, os.Stderr)
	if err != nil {
		t.Fatal(err)
	}
	if len(results) != 2 {
		t.Fatalf("results = %+v, want one per rep", results)
	}
	for _, r := range results {
		if r.Err != "" || len(r.Verdicts) != 2 || !r.Verdicts[0].Found || r.Verdicts[1].Found || r.Findings != 1 {
			t.Errorf("result = %+v", r)
		}
		if r.Seconds < 1 {
			t.Errorf("seconds = %d, want the time of the run", r.Seconds)
		}
		if got := r.CostUSD; got < 0.59 || got > 0.61 {
			t.Errorf("cost = %v, want 0.6", got)
		}
		if strings.Join(r.Leaks, " ") != "origin/" {
			t.Errorf("leaks = %v, want the look at origin/main", r.Leaks)
		}
	}
	if _, err := os.Stat(filepath.Join(out, "7-E-r1", "tree")); !os.IsNotExist(err) {
		t.Errorf("the repository is still there: %v", err)
	}
	if _, err := os.Stat(filepath.Join(out, "7-E-r1", "transcript.jsonl")); err != nil {
		t.Errorf("no transcript: %v", err)
	}
	results = append(results, result{PR: 7, Split: splitTrain, Agent: "E", Rep: 3, Err: "claude: boom"})
	if err := writeResults(out, results); err != nil {
		t.Fatal(err)
	}
	md, err := os.ReadFile(filepath.Join(out, "results.md"))
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{"| train | E | 2 of 4 (50%) | ±50 pts | 50%, 50% | 1.0 |", "2 runs scored, 1 failed",
		"- #7 E r3: claude: boom", "`x-1` E: found in 2 of 2 runs — The pool comment is false.", "| origin/ |"} {
		if !strings.Contains(string(md), want) {
			t.Errorf("results.md lacks %q:\n%s", want, md)
		}
	}
	var back []result
	data, err := os.ReadFile(filepath.Join(out, "results.json"))
	if err != nil || json.Unmarshal(data, &back) != nil || len(back) != 3 {
		t.Errorf("results.json does not hold the results: %v", err)
	}
}

func TestProbes(t *testing.T) {
	ps := probesOf(evalCase{Expect: []expectation{{ID: "a", Finding: "The lock leaks."}}})
	if len(ps) != 3 || !ps[0].found || ps[1].found || ps[2].found || ps[2].report != "" {
		t.Fatalf("probes = %+v", ps)
	}
	if !strings.Contains(ps[0].report, "The lock leaks.") || !strings.Contains(ps[1].report, "does not hold") {
		t.Errorf("probes = %+v", ps)
	}
}
