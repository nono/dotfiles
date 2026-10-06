---
name: adversarial-review
description: Use when asked to review work, a change, a diff, a branch or a PR - dispatches three competing reviewers (one guided by ocr rules), a simplifier, a Quint modeler and a claim auditor, verifies every finding only one of them reported, then grades what survives as high, medium or low.
---

# Adversarial Review

Six agents review the same code in parallel. Three compete on defects that have a
failure chain, one of them against the rules of `ocr`; the fourth finds what is bigger
than it needs to be, or out of step with the repository; the fifth models the change in Quint and runs the model to find the interleavings
and edge cases a read misses; the sixth checks every claim the change makes in prose.
You merge their reports, verify anything only one agent saw, grade the survivors on one
scale, and present them.

Each agent's instructions live in `prompts/`: `common.md` for all of them, and one file
per role. You send only the letter, the values of the review and the file names.
`evals/` holds the test set for a change to these prompts.

## 1. Resolve the target

Do this before dispatching. Every reviewer must see the same bytes.

1. An explicit argument — path, branch, commit range, PR number. Use it.
2. Else, commits on this branch that are not on the default branch:
   ```sh
   base=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD | sed 's#^origin/##')
   base=${base:-main}
   git log --oneline --no-merges "$base..HEAD"
   ```
   Non-empty: the scope is `git diff $base...HEAD`.
3. Else, uncommitted work: `git diff HEAD`, plus `git ls-files --others --exclude-standard`.
4. Nothing: say so and stop. Do not invent a scope.

Then prove the scope: `git rev-parse --verify "$base"` resolves, and
`git diff --name-only "$base...HEAD"` is not empty. Otherwise say so and stop.

Decide who runs. Write each skip in the report header as `X = skipped (<reason>)`.

| Agent | Skip when |
| --- | --- |
| B | `command -v codex` fails |
| C | the target is a PR someone else opened: `gh pr view <number> --json author -q .author.login` differs from `gh api user -q .login` |
| D | `command -v quint` fails, or you cannot name two actors that change the same state in the diff — two goroutines, handlers, services, plans or retries — and the state they share. Write the two actors and the state in D's dispatch |
| F | `command -v ocr` fails, or `ocr delegate preview --from <base> --to <head>` lists no reviewable file |

Find the PR body. For a PR, save `gh pr view <number> --json body -q .body` to
`<scratchpad>/pr-body.md`. For work that is not a PR yet, use the draft body the caller
passed as a path. None: say so in the report — E then audits the code's prose alone.

Find the PRs that can use this change, for C: for a PR, the other open PRs of its
author, `gh pr list --author <login> --state open --json number,title`. None, or no PR:
C checks the repository alone.

Write down the diff command, the merge base and the file list. All three go to every
reviewer verbatim.

Make the review directory, which outlives the scratchpad:
`<review dir>` = `~/.claude/review-ledger/<repo>-<PR number or branch>-<UTC time, YYYYMMDDTHHMMSS>`.
It holds `resources.jsonl`, the resource log, and `ledger.json` (step 6).
`<skill dir>/bin/reviewrun -log <review dir>/resources.jsonl -label <agent> -- <command>`
runs a command under `nice -n 19` and an 8G memory cap, and logs its wall time, CPU
time and memory peak. Run B and every test or mutation of step 4 through it.

## 2. Resolve the spec

The reviewers read the code against itself, so a requirement nobody implemented leaves
them nothing to find. The spec closes that gap.

Look for it in this order, and stop at the first hit:

1. A path, ticket or story the user passed as an argument.
2. A Shortcut story id in the branch name or in a commit subject (`sc-NNNN`). Fetch the
   story through the Shortcut MCP: its description and every acceptance criterion.
3. A design document under `docs/` whose name matches the branch or the feature, plus
   the PR body when the target is a PR.
4. Nothing: say so in the report and dispatch without it. Do not invent requirements.

Quote it into A's, B's, C's, D's and F's dispatch: a criterion you paraphrase is one they
cannot hold you to. Also save it to `<scratchpad>/spec.md`, for F to give to `ocr`.
For D, each criterion is a candidate invariant.

## 3. Dispatch six reviewers

One message, six calls, so they run concurrently. No agent edits the user's tree. A, B,
C, E and F each get their own throwaway worktree, where they may edit and run code. D is
read-only, and writes its model in the scratchpad only.

| Agent | How to run | Model |
| --- | --- | --- |
| A | `Agent`, `subagent_type: adversarial-reviewer` | Opus, medium effort (set in the agent definition — pass no `model`) |
| B | `Bash`, `codex` CLI, `run_in_background: true` | `gpt-6.1-sol`, medium reasoning effort |
| C | `Agent`, `subagent_type: adversarial-nitpicker` | Sonnet, medium effort (set in the agent definition) |
| D | `Agent`, `subagent_type: adversarial-modeler` | Opus, medium effort (set in the agent definition) |
| E | `Agent`, `subagent_type: adversarial-claim-auditor` | Opus, medium effort (set in the agent definition) |
| F | `Agent`, `subagent_type: adversarial-ocr` | Opus, medium effort (set in the agent definition) |

A and B get **identical** dispatches, because "only one agent found it" carries
information only when both had the same job. Their models differ on purpose: three
models disagree where one model repeats itself. F gets the same dispatch, plus the
spec file, and finds the same kind of defect by another method: the rules of `ocr`
instead of the searches of `reviewer.md`. D does a different job: agreement between D
and A, B or F means two methods found the same defect.

No reviewer grades its own findings. Severity is assigned once, in step 5, by you, so
one scale covers all the reports.

### Worktrees

Before the dispatch, make one worktree each for A, B, C, E and F, all at the head of the
change:

```sh
for w in review-a review-b review-c review-e review-f; do git worktree add --detach <scratchpad>/$w <head>; done
```

`<head>` is `HEAD` for a branch. For a PR, run `git fetch origin pull/<number>/head`
first and use `FETCH_HEAD`. For uncommitted work, apply `git diff HEAD --binary` in each
worktree, and copy the untracked files into it. Remove the five worktrees when step 4 is
done.

### The dispatch

Every agent gets this, with the lines that do not apply to it left out:

> You are reviewer <letter>. Skill directory: `<skill dir>`. Review <scope>. Get the
> diff with `<command>`. The merge base is `<base>`.
>
> Your worktree: `<scratchpad>/review-a` (A), `<scratchpad>/review-b` (B),
> `<scratchpad>/review-c` (C), `<scratchpad>/review-e` (E) or `<scratchpad>/review-f` (F).
> Spec file: `<scratchpad>/spec.md` (F, when a spec was found).
> PR body: `<path>`, or: there is no PR body yet (E).
> Open PRs that can use this change: <#number title, one per line> (C, when there are).
> Resource log: `<review dir>/resources.jsonl` (A, C, D, E, F).
> The actors and the state they share: <the two actors and the state, from the skip check> (D).
> Write your model under `<scratchpad>/quint/` (D).
>
> The change is meant to implement this (A, B, C, D, F):
>
> <spec, quoted in full — or: no spec was found; judge the code on its own>
>
> Read `<skill dir>/prompts/common.md`, then `<skill dir>/prompts/<role file>`, in full
> before you start, and follow them.

The role files: `reviewer.md` for A and B, `nitpicker.md` for C, `modeler.md` for D,
`claims.md` for E, `ocr.md` for F.

For B, write the dispatch to `<scratchpad>/review-b-prompt.md` and start this, in the
same message as the `Agent` calls:

```sh
<skill dir>/bin/reviewrun -log <review dir>/resources.jsonl -label B -- \
  codex exec --model gpt-6.1-sol -c model_reasoning_effort=medium \
  --sandbox workspace-write -c sandbox_workspace_write.network_access=true \
  --add-dir "$(go env GOCACHE)" -C <scratchpad>/review-b \
  -o <scratchpad>/review-b.md - < <scratchpad>/review-b-prompt.md
```

The codex sandbox cannot reach `systemd-run`, so the cap and the log go around the whole
run. Without `network_access`, the sandbox refuses every socket: each test that starts an
`httptest` server fails with `socket: operation not permitted`, and B reviews without the
tests. The setting opens all the network, not only loopback.
Read `review-b.md` when the command ends. If `codex` fails mid-run, say so in the
report and adjudicate without B — never silently drop it.

## 4. Verify

One pool: the findings of A, B, D, E and F, and C's escalated section. C's ranked list
and D's invariants that held are not in it. A skipped agent adds nothing to the pool.

Match the findings across the reports and record, for each one, which agents
reported it. Two agents that describe the same defect at the same place are one
finding, even if the wording differs.

- Two or more agents reported it → accept.
- C's escalated defects enter the pool as single reports.
- D's findings enter the pool as single reports, unless A, B or F reported the same
  defect.
- C's ranked list is not fanned out: reading one costs less than checking it. Two
  checks still apply. A C finding that carries its experiment is settled like A's, by
  running it again. A C finding that deletes a test is dropped when the spec asks for
  the test, or when an edit of the code it checks turns that test red and leaves every
  other test green: run that edit as under "A test pins nothing" below.

Every singleton gets settled, one way or the other. Do not drop one because it sounds
unlikely. Sort them first: a command answers some of them, and only the rest need a
second reader.

### Settle these yourself, with a command

Certain, fast, and not a matter of opinion. One pass, before any fan-out:

- **A finding that carries its experiment** [A, B or F], marked `proved` — run its
  command again, in that reviewer's worktree once the reviewer is done. The same output
  settles it, either way; it needs no second reader.
- **A test pins nothing** — the finding names an edit that should turn a suite red.
  When the reviewer already ran that edit, its output settles it. Otherwise work
  in a throwaway worktree, never in the user's tree:
  ```sh
  git worktree add <scratchpad>/mutate HEAD   # apply the edit here, run the suite with reviewrun -label verify
  git worktree remove --force <scratchpad>/mutate
  ```
  Green under the edit: the finding holds, and the report says the mutation ran. Red: a
  test does pin the path — drop it, and name the test.
- **Provenance** — agents disagree, or the tag decides which section the finding lands
  in. Read the merge-base version of the file.
- **Nothing handles this** — a missing error check, an unread return, a caller that
  cannot cope. Grep the callers.
- **The comment contradicts the code** — read the two side by side. Most of E's
  findings are settled here: read the claim and the `file:line` E gives against it.
- **A Quint trace [D]** — the model can be wrong where the code is right. When the
  suite can express the trace, write it as a test in the throwaway worktree above. Red:
  the finding holds, and the report names the test. Green: drop it. When the suite
  cannot express it, fan it out, with the trace quoted.

### Fan out the rest

What is left is judgement: a claim about what production does, which no command
answers. One agent per finding, `subagent_type: general-purpose`, `model: "opus"`,
read-only, all of them in one message so they run at once.

> This finding comes from one reviewer out of several. The others read the same code
> and did not report it, so it is more likely wrong than right. Find what makes it
> wrong.
>
> <the finding, quoted in full>
>
> <for a finding from D: It comes from a Quint model. Check that the code can take each
> step of the trace, in that order. A step it cannot take is a reason to drop it.>
>
> Get the diff with `<command>`. The merge base is `<base>`. Read the file, its callers,
> and the tests that cover it. Change nothing.
>
> Answer with `HOLDS` or `DROPPED`, then the `file:line` that decides it with the line
> quoted, then one sentence.
>
> `DROPPED` needs something that makes the failure impossible: a guard, a check in the
> caller, a test that pins it, an input no caller can produce. "I could not reproduce
> it" and "it seems unlikely" are not reasons. Without one, the answer is `HOLDS`.

You decide from the verdicts, not from the agents' count. A verdict whose quoted line
does not convince you costs one read to check — do that rather than take it. The
reviewers may not be believed on a singleton, and neither may the verifiers.

## 5. Grade

Grade every finding that survived step 4, in one pass, so one scale covers every
reviewer:

- **High** — fires as it stands.
- **Medium** — has a failure chain, but needs a second event to fire.
- **Low** — no failure chain.

Grade on the chain, not on how much the code annoys you. C's ranked list is low by
construction; grade only what came through the pool.

A change no test pins is medium: the second event is the change that breaks it unseen. A
false claim in prose is low, unless a reader who trusts it writes a defect — then grade
that chain.

A `pre-existing` finding is not graded. It leaves the levels for the follow-ups
section, whatever its chain: the levels decide what to fix before merge, and an old bug
is not this change's to fix. `partly introduced` stays in the levels.

## 6. Report

Name the models once, at the top:

> A = Opus medium · B = gpt-6.1-sol medium · C = Sonnet medium · D = Opus medium, Quint ·
> E = Opus medium, claims · F = Opus medium, ocr

Replace a skipped agent with its `X = skipped (<reason>)`. When D ran, give its model
path, so the human can run it again.

Then four sections, worst first. Every line keeps the shape its reviewer reported it
in, and gains a `[A]`, `[A,D]` or `[A,B,C]` tag, so the human can weigh agreeing agents
against one that saw what the others missed.

1. **High**
2. **Medium**
3. **Low** — one line each. It holds every item of C's list that step 4 kept, not a
   selection, with its **Cost if left**.
4. **Follow-ups, not this PR's to fix** — the `pre-existing` findings.

Then, below, the singletons you dropped and why — `[agent]` and one line each, so the
human can overrule you.

Offer the work as **three separate questions**, in this order:

1. Fix the high and medium findings.
2. Sweep the low ones.
3. Fix the follow-ups here, or file them as stories.

Keep them apart: a nit sweep mixed into a bugfix diff makes the fix unreviewable, and a
pre-existing bug fixed in the same commit hides what the change itself did. Fix only
what was confirmed; do not repair things no reviewer raised.

For each follow-up, recommend a fix in this PR, in its own commit, when it is small,
related to the PR, and does not delay the merge: each PR costs a review. Recommend a
story only for a stated reason — the fix is large, has a different risk, needs a
different reviewer, or must wait for a decision or a deploy — and give that reason in
the option.

### Ledger

Write `<review dir>/ledger.json` when the report is out, before the questions. It is
the record that tells, after a week, what each agent is worth: keep every finding,
dropped ones too.

```json
{
  "repo": "system-services", "pr": 815, "branch": "sc-5028-hb", "base": "<sha>", "head": "<sha>",
  "started": "<UTC>", "reported": "<UTC>", "session": "<Claude Code session id>",
  "agents": {
    "A": {"status": "ran", "findings": 3},
    "B": {"status": "failed", "reason": "codex exited 1"},
    "D": {"status": "skipped", "reason": "no state over steps"}
  },
  "findings": [
    {"id": 1, "agents": ["A", "F"], "file": "a/b.go", "line": 640, "summary": "<one sentence>",
     "provenance": "introduced", "confidence": "traced", "settled_by": "agreement",
     "verdict": "accepted",
     "grade": "high", "decision": null}
  ]
}
```

- `status`: `ran`, `skipped` or `failed`; `findings` counts what the agent reported,
  before any merge.
- `agents` of a finding: every agent that reported it, and `C-list` for an
  item of C's ranked list. Each item of C's list is one finding, dropped ones too.
- `confidence`: as the reviewer gave it (`proved`, `traced`, `suspected`), or null.
- `settled_by`: `agreement`, `command`, `fan-out`, or `none` for C's ranked list.
- `verdict`: `accepted` or `dropped`. `grade`: `high`, `medium`, `low`, `pre-existing`,
  or null when dropped.

When the human answers the questions, set each finding's `decision`: `fixed`,
`declined-false` (the human says it is wrong), `declined-minor` (true, not worth the
work), or `filed` (a story; put its id in `story`). When the human overrules a dropped
finding, set its `decision` too. When step 7 runs, add `"fix_review"` with its findings
in the same shape.

## 7. Review the fix

The fixes are code written fast, against a list of complaints, and no reviewer has seen
them. When they land, dispatch **one** agent — `adversarial-reviewer`, same terms as
step 3, with a fresh worktree at the head of the fixes — on the fix commits alone. Add
to its dispatch:

> These are the findings the fix commits are meant to close:
>
> <the confirmed findings, quoted>
>
> Answer two questions for each: does the fix close the finding, or only its symptom?
> Does the fix introduce a defect of its own?

When a confirmed finding said no test pins a change, run its edit again on the fix
commits' head: the suite must now go red.

There is no second reviewer, so every finding it returns is a singleton: trace each one
yourself under the step 4 rules. Then stop. Do not open a third round — a fix that
still fails after two goes is a design problem, and belongs in a conversation, not in
another review.
