---
name: adversarial-review
description: Use when asked to review work, a change, a diff, a branch or a PR - dispatches two competing reviewers plus a nitpicker, verifies every finding only one of them reported, then grades what survives as high, medium or low.
---

# Adversarial Review

Three agents review the same code in parallel. Two compete on defects that have a
failure chain; the third collects what has none. You merge their reports, verify
anything only one agent saw, grade the survivors on one scale, and present them.

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

Then prove the scope, before three agents find the hole for you:

```sh
git rev-parse --verify "$base" >/dev/null   # the ref resolves (cases 1 and 2)
git diff --name-only "$base...HEAD"         # the file list is not empty
command -v codex >/dev/null                 # B can run at all
```

A ref that does not resolve, or an empty file list: say so and stop. No `codex`: decide
here to run with A and C, and say so in the report.

When the target is a PR, find its author:

```sh
[ "$(gh pr view <number> --json author -q .author.login)" = "$(gh api user -q .login)" ]
```

False — someone else opened the PR: skip C, and say so in the report. Run C in all other
cases: your own PR, or work that is not a PR yet.

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

Quote it into A's and B's prompt: a criterion you paraphrase is one they cannot hold
you to.

## 3. Dispatch three reviewers

One message, three calls, so they run concurrently. All three are read-only: they
report, they never edit.

| Agent | How to run | Model |
| --- | --- | --- |
| A | `Agent`, `subagent_type: adversarial-reviewer` | Opus, medium effort (set in the agent definition — pass no `model`) |
| B | `Bash`, `codex` CLI, `run_in_background: true` | `gpt-6-sol`, medium reasoning effort |
| C | `Agent`, `subagent_type: adversarial-nitpicker` | Opus, low effort (set in the agent definition — pass no `model`) — skip on a PR someone else opened (step 1) |

A and B get **identical** prompts, because "only one agent found it" carries
information only when both had the same job. Their models differ on purpose: three
models disagree where one model repeats itself.

No reviewer grades its own findings. Severity is assigned once, in step 5, by you, so
one scale covers all three reports.

### How to run B

Write the prompt to `<scratchpad>/review-b-prompt.md`, then start this in the
background, in the same message as the two `Agent` calls:

```sh
codex exec --model gpt-6-sol -c model_reasoning_effort=medium \
  --sandbox read-only -C <repo root> \
  -o <scratchpad>/review-b.md - < <scratchpad>/review-b-prompt.md
```

`-o` writes the final report to the file. Read that file when the command ends; ignore
the progress log on stdout. If `codex` fails mid-run, say so in the report and
adjudicate with A and C alone — never silently drop B.

### Provenance, pasted into all three prompts

> Tag every finding with one of:
>
> - `introduced` — this change created the defect;
> - `partly introduced` — the defect predates this change, which makes it reachable, or
>   much easier to hit;
> - `pre-existing` — the change only sits next to it.
>
> Read the merge-base version of the file to decide. Do not guess from the diff.

### Prompt for A and B

> Review <scope>. Get the diff with `<command>`. The merge base is `<base>`. Read every
> changed file in full, and the callers of anything you doubt.
>
> The change is meant to implement this:
>
> <spec, quoted in full — or: no spec was found; judge the code on its own>
>
> Read it before you read the code.
>
> Another agent is reviewing this same code right now. Whichever of you reports the
> largest number of defects that survive verification gets five points. A false finding
> costs more than a missed one: it is scored against you. Do not submit anything you
> have not convinced yourself of.
>
> You have a 30 minute budget.
>
> Report any defect you can tie to a concrete failure chain:
>
> - wrong behaviour, data loss, security holes, broken contracts, unhandled failures,
>   race conditions;
> - a path this diff adds that no test pins — name the edit that guts it and the suite
>   that should go red. Do not run it: you cannot, and the verify step does it for you;
> - a docstring, comment, design document or PR body that contradicts the code it
>   describes;
> - a failure that is silent: no log, no metric, nothing returned to the caller;
> - a requirement the spec asks for that the change does not meet, or behaviour the
>   change adds that no requirement asks for. Quote the line of the spec you judge it
>   against.
>
> Leave naming, style, duplication and dead code to another agent.
>
> Do not rank your findings and do not label them high, medium or low. A third agent
> grades them all on one scale after you report.
>
> <the provenance block>
>
> Report each finding as:
>
> - `file:line`, and its provenance;
> - one sentence stating the defect;
> - **If not addressed**: the failure chain. Specific inputs or state, the wrong output
>   or crash that follows, and who pays for it. For an unmet requirement, the chain is
>   what the user asked for and does not get, and the story that closes unmet;
> - one line for the fix.
>
> A finding you cannot give a failure chain for is not a finding. Drop it.

### Prompt for C

> Review <scope> for everything the other reviewers are told to leave you. Get the diff
> with `<command>`. The merge base is `<base>`.
>
> Work through the baseline in `<skill dir>/baseline.md`, in order, against the diff.
> The same list every run makes a smell that keeps coming back visible.
>
> Judge against this repository — its CLAUDE.md, and the code next to the change — not
> against general style preferences. "The three neighbouring functions all do X" is a
> finding. "I prefer early returns" is not.
>
> <the provenance block>
>
> Report at most 30, ranked, best first: `file:line`, provenance, the baseline entry it
> falls under, one sentence.
>
> A defect with a concrete failure chain is not yours to rank. Put it in a separate
> section at the top: `file:line`, provenance, the defect, **If not addressed** and the
> chain, and one line for the fix.

## 4. Verify

One pool: A's findings, B's findings, and C's escalated section. C's ranked list is
not in it. When C was skipped, the pool is A's and B's findings alone.

Match the findings across the three reports and record, for each one, which agents
reported it. Two agents that describe the same defect at the same place are one
finding, even if the wording differs.

- Two or more agents reported it → accept.
- C's escalated defects enter the pool as single reports.
- C's ranked list is never verified. Reading one costs less than checking it.

Every singleton gets settled, one way or the other. Do not drop one because it sounds
unlikely. Sort them first: a command answers some of them, and only the rest need a
second reader.

### Settle these yourself, with a command

Certain, fast, and not a matter of opinion. One pass, before any fan-out:

- **A test pins nothing** — the finding names an edit that should turn a suite red. The
  reviewers are sandboxed and you are not, so this one is yours. Work in a throwaway
  worktree, never in the user's tree:
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
- **The comment contradicts the code** — read the two side by side.

### Fan out the rest

What is left is judgement: a claim about what production does, which no command
answers. One agent per finding, `subagent_type: general-purpose`, `model: "opus"`,
read-only, all of them in one message so they run at once.

> This finding comes from one reviewer out of three. The other two read the same code
> and did not report it, so it is more likely wrong than right. Find what makes it
> wrong.
>
> <the finding, quoted in full>
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

Grade every finding that survived step 4, in one pass, so one scale covers three
models:

- **High** — fires as it stands.
- **Medium** — has a failure chain, but needs a second event to fire.
- **Low** — no failure chain.

Grade on the chain, not on how much the code annoys you. C's ranked list is low by
construction; grade only what came through the pool.

A `pre-existing` finding is not graded. It leaves the levels for the follow-ups
section, whatever its chain: the levels decide what to fix before merge, and an old bug
is not this change's to fix. `partly introduced` stays in the levels.

## 6. Report

Name the models once, at the top:

> A = Opus medium · B = gpt-6-sol medium · C = Opus low

When C was skipped, write `C = skipped (PR by <author>)`.

Then four sections, worst first. Every line keeps the shape its reviewer reported it
in, and gains a `[A]`, `[A,B]` or `[A,B,C]` tag, so the human can weigh three agreeing
agents against one that saw what the others missed.

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
step 3 — on the fix commits alone:

> Review <the fix commits>. Get the diff with `<command>`. These are the findings they
> are meant to close:
>
> <the confirmed findings, quoted>
>
> Answer two questions for each: does the fix close the finding, or only its symptom?
> Does the fix introduce a defect of its own? Same reporting rules as before.

There is no second reviewer, so every finding it returns is a singleton: trace each one
yourself under the step 4 rules. Then stop. Do not open a third round — a fix that
still fails after two goes is a design problem, and belongs in a conversation, not in
another review.
