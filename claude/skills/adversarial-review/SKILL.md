---
name: adversarial-review
description: Use when asked to review work, a change, a diff, a branch or a PR - dispatches two competing reviewers, a nitpicker, a Quint modeler and a claim auditor, mutates each changed line to find what no test pins, verifies every finding only one of them reported, then grades what survives as high, medium or low.
---

# Adversarial Review

Five agents review the same code in parallel. Two compete on defects that have a
failure chain; the third collects what has none; the fourth models the change in Quint
and runs the model to find the interleavings and edge cases a read misses; the fifth
checks every claim the change makes in prose. At the same time, `hunkmut` mutates the
changed lines one at a time and runs the tests, to find what no test pins. You
merge their reports, verify anything only one agent saw, grade the survivors on one
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
| D | `command -v quint` fails, or the diff changes no state that changes over steps — a state machine, a status and its transitions, locks, queues, retries, idempotency, ordering, a cache and its invalidation, a workflow of several steps, two actors on the same data |
| M | the file list holds no non-test `.go` file |

Find the PR body. For a PR, save `gh pr view <number> --json body -q .body` to
`<scratchpad>/pr-body.md`. For work that is not a PR yet, use the draft body the caller
passed as a path. None: say so in the report — E then audits the code's prose alone.

Write down the diff command, the merge base and the file list. All three go to every
reviewer verbatim.

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

Quote it into A's, B's and D's dispatch: a criterion you paraphrase is one they cannot
hold you to. For D, each criterion is a candidate invariant.

## 3. Dispatch five reviewers and M

One message, six calls, so they run concurrently. No agent edits the user's tree. A, B
and M each get their own throwaway worktree, where they may edit and run code. C, D and
E are read-only; D writes its model in the scratchpad only.

| Agent | How to run | Model |
| --- | --- | --- |
| A | `Agent`, `subagent_type: adversarial-reviewer` | Opus, medium effort (set in the agent definition — pass no `model`) |
| B | `Bash`, `codex` CLI, `run_in_background: true` | `gpt-6.1-sol`, medium reasoning effort |
| C | `Agent`, `subagent_type: adversarial-nitpicker` | Sonnet, medium effort (set in the agent definition) |
| D | `Agent`, `subagent_type: adversarial-modeler` | Opus, medium effort (set in the agent definition) |
| E | `Agent`, `subagent_type: adversarial-claim-auditor` | Opus, medium effort (set in the agent definition) |
| M | `Bash`, `hunkmut`, `run_in_background: true` | no model |

A and B get **identical** dispatches, because "only one agent found it" carries
information only when both had the same job. Their models differ on purpose: three
models disagree where one model repeats itself. D does a different job: agreement
between D and A or B means two methods found the same defect.

No reviewer grades its own findings. Severity is assigned once, in step 5, by you, so
one scale covers all the reports.

### Worktrees

Before the dispatch, make one worktree each for A, B and M, all at the head of the
change:

```sh
for w in review-a review-b hunkmut-tree; do git worktree add --detach <scratchpad>/$w <head>; done
```

`<head>` is `HEAD` for a branch. For a PR, run `git fetch origin pull/<number>/head`
first and use `FETCH_HEAD`. For uncommitted work, apply `git diff HEAD --binary` in each
worktree, copy the untracked files into it, and commit them there with
`git commit --no-verify`: `hunkmut` diffs commits and refuses a dirty tree. Remove the
three worktrees when step 4 is done.

### The dispatch

Every agent gets this, with the lines that do not apply to it left out:

> You are reviewer <letter>. Skill directory: `<skill dir>`. Review <scope>. Get the
> diff with `<command>`. The merge base is `<base>`.
>
> Your worktree: `<scratchpad>/review-a` (A) or `<scratchpad>/review-b` (B).
> PR body: `<path>`, or: there is no PR body yet (E).
> Write your model under `<scratchpad>/quint/` (D).
>
> The change is meant to implement this (A, B, D):
>
> <spec, quoted in full — or: no spec was found; judge the code on its own>
>
> Read `<skill dir>/prompts/common.md`, then `<skill dir>/prompts/<role file>`, in full
> before you start, and follow them.

The role files: `reviewer.md` for A and B, `nitpicker.md` for C, `modeler.md` for D,
`claims.md` for E.

For B, write the dispatch to `<scratchpad>/review-b-prompt.md` and start this, in the
same message as the `Agent` calls:

```sh
nice -n 19 systemd-run --user --scope --quiet --collect -p MemoryMax=8G -p MemorySwapMax=0 \
  -p OOMPolicy=continue -- \
  codex exec --model gpt-6.1-sol -c model_reasoning_effort=medium \
  --sandbox workspace-write --add-dir "$(go env GOCACHE)" -C <scratchpad>/review-b \
  -o <scratchpad>/review-b.md - < <scratchpad>/review-b-prompt.md
```

The codex sandbox cannot reach `systemd-run`, so the cap goes around the whole run.
Read `review-b.md` when the command ends. If `codex` fails mid-run, say so in the
report and adjudicate without B — never silently drop it.

### M

```sh
go -C <skill dir>/hunkmut build -o <scratchpad>/hunkmut .
nice -n 19 <scratchpad>/hunkmut -dir <scratchpad>/hunkmut-tree -base <base> -budget 10m \
  > <scratchpad>/hunkmut.md 2> <scratchpad>/hunkmut.log
```

`hunkmut -help` gives the options: `-pkgs` adds a package whose tests cover the change,
`-tags` and `-run` go to `go test`. Never pass `-mem 0`: a mutant can make a test
allocate without bound. It exits non-zero when the tests fail at the head: say so in
the report and go on without it.

## 4. Verify

One pool: A's findings, B's findings, C's escalated section, D's findings and E's
findings. C's ranked list and D's invariants that held are not in it. A skipped agent
adds nothing to the pool.

Do not wait for M to start this step. Settle the pool while M runs, and read M's report
when it ends — its budget sets the latest time. When the pool is settled before M ends,
wait for M before step 5.

M's report is not in the pool: a command produced it, so it needs no second reader.
Read it yourself:

- **A mutant no test kills** is a finding, `introduced`, tagged `[M]`. Read the
  mutated code, and drop the mutant only when it is equivalent — a log text, a rename,
  a refactor whose revert gives the same result, a statement the next line repeats.
  Merge it with an A or B finding on the same lines, which then counts as confirmed.
  Several mutants of one function are one finding.
- **No test fails on the base code** is a finding: nothing pins the change. When the
  tests do not compile on the base code, the check shows nothing; say so.
- **A mutant that breaks the build** gives no verdict. Leave it out.
- **Mutants not run** when the budget ran out: give their number in the report header.

Match the findings across the reports and record, for each one, which agents
reported it. Two agents that describe the same defect at the same place are one
finding, even if the wording differs.

- Two or more agents reported it → accept.
- C's escalated defects enter the pool as single reports.
- D's findings enter the pool as single reports, unless A or B reported the same
  defect.
- C's ranked list is never verified. Reading one costs less than checking it.

Every singleton gets settled, one way or the other. Do not drop one because it sounds
unlikely. Sort them first: a command answers some of them, and only the rest need a
second reader.

### Settle these yourself, with a command

Certain, fast, and not a matter of opinion. One pass, before any fan-out:

- **A finding that carries its experiment** [A or B] — run its command again, in
  that reviewer's worktree once the reviewer is done. The same output settles it,
  either way; it needs no second reader.
- **A test pins nothing** — the finding names an edit that should turn a suite red.
  When M or the reviewer already ran that edit, their output settles it. Otherwise work
  in a throwaway worktree, never in the user's tree:
  ```sh
  git worktree add <scratchpad>/mutate HEAD   # apply the edit here, run the suite
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
reviewer and M:

- **High** — fires as it stands.
- **Medium** — has a failure chain, but needs a second event to fire.
- **Low** — no failure chain.

Grade on the chain, not on how much the code annoys you. C's ranked list is low by
construction; grade only what came through the pool and M's report.

A mutant no test kills is medium: the second event is the change that breaks it unseen. A
false claim in prose is low, unless a reader who trusts it writes a defect — then grade
that chain.

A `pre-existing` finding is not graded. It leaves the levels for the follow-ups
section, whatever its chain: the levels decide what to fix before merge, and an old bug
is not this change's to fix. `partly introduced` stays in the levels.

## 6. Report

Name the models once, at the top:

> A = Opus medium · B = gpt-6.1-sol medium · C = Sonnet medium · D = Opus medium, Quint ·
> E = Opus medium, claims · M = hunkmut

Replace a skipped agent with its `X = skipped (<reason>)`. When D ran, give its model
path, so the human can run it again. When M ran, give the number of mutants it ran and
how many survived.

Then four sections, worst first. Every line keeps the shape its reviewer reported it
in, and gains a `[A]`, `[A,D]` or `[A,B,C]` tag, so the human can weigh agreeing agents
against one that saw what the others missed.

1. **High**
2. **Medium**
3. **Low** — one line each.
4. **Follow-ups, not this PR's to fix** — the `pre-existing` findings.

Then, below, the singletons you dropped and why — `[agent]` and one line each, so the
human can overrule you.

Offer the work as **three separate questions**, in this order:

1. Fix the high and medium findings.
2. Sweep the low ones.
3. File the follow-ups as stories.

Keep them apart: a nit sweep mixed into a bugfix diff makes the fix unreviewable, and a
pre-existing bug fixed in the same branch hides what the change itself did. Fix only
what was confirmed; do not repair things no reviewer raised.

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

When M found mutants that no test kills, run it again on the fix commits' head, with the
same base: each mutant the fixes meant to kill must now be killed.

There is no second reviewer, so every finding it returns is a singleton: trace each one
yourself under the step 4 rules. Then stop. Do not open a third round — a fix that
still fails after two goes is a design problem, and belongs in a conversation, not in
another review.
