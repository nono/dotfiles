---
name: adversarial-review
description: Use when asked to review work, a change, a diff, a branch or a PR - dispatches two competing reviewers plus a nitpicker, verifies every finding only one of them reported, then reports confirmed issues and nits separately.
---

# Adversarial Review

Three agents review the same code in parallel. Two compete on serious issues; the
third collects nits. You merge their reports, verify anything only one agent saw,
and present what survives.

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

Write down the exact command that produces the diff, and the file list. Both go to
every reviewer verbatim.

## 2. Dispatch three reviewers

One message, three calls, so they run concurrently. All three are read-only: they
report, they never edit.

| Agent | How to run | Model |
| --- | --- | --- |
| A | `Agent`, `subagent_type: adversarial-reviewer` | Fable, low effort (set in the agent definition — pass no `model`) |
| B | `Bash`, `codex` CLI, `run_in_background: true` | `gpt-5.6-sol`, medium reasoning effort |
| C | `Agent`, `subagent_type: general-purpose` | `model: "opus"` |

A and B get **identical** prompts. Never split them by topic — "only one agent found
it" carries information only when both had the same job. Their models differ on
purpose: three models disagree where one model repeats itself, so a singleton finding
says more.

### How to run B

Write the prompt to `<scratchpad>/review-b-prompt.md`, then start this in the
background, in the same message as the two `Agent` calls:

```sh
codex exec --model gpt-5.6-sol -c model_reasoning_effort=medium \
  --sandbox read-only -C <repo root> \
  -o <scratchpad>/review-b.md - < <scratchpad>/review-b-prompt.md
```

`-o` writes the final report to the file. Read that file when the command ends; ignore
the progress log on stdout. If `codex` fails or is missing, say so in the report and
adjudicate with A and C alone — never silently drop B.

### Prompt for A and B

> Review <scope>. Get the diff with `<command>`. Read every changed file in full, and
> the callers of anything you doubt.
>
> Another agent is reviewing this same code right now. Whichever of you reports the
> largest number of serious issues gets five points. A false issue costs more than a
> missed one: it is scored against you. Do not submit anything you have not convinced
> yourself of.
>
> You have a 30 minute budget.
>
> Serious means wrong behaviour, data loss, security holes, broken contracts,
> unhandled failures, race conditions. Not style, not naming, not test coverage —
> another agent has those.
>
> Report each finding as: `file:line`; one sentence stating the defect; and a concrete
> failure scenario — specific inputs or state, and the wrong output or crash that
> follows. A finding you cannot give a failure scenario for is not a finding. Drop it.

### Prompt for C

> Review <scope> for everything the other reviewers are told to ignore: style, naming,
> dead code, test coverage, duplication, inconsistency with the code around the change.
> Get the diff with `<command>`.
>
> Judge against this repository — its CLAUDE.md, and the code next to the change — not
> against general style preferences. "The three neighbouring functions all do X" is a
> finding. "I prefer early returns" is not.
>
> Report at most 30, ranked, best first. `file:line` and one sentence each.
>
> If you trip over a real bug, report it in a separate section at the top, with a
> concrete failure scenario.

## 3. Adjudicate

Serious findings only.

Match the findings across the three reports and record, for each one, which agents
reported it. Two agents that describe the same defect at the same place are one
finding, even if the wording differs.

- Two or more agents reported it → accept.
- One agent reported it → **read the code yourself**. Trace the failure scenario. It
  holds: confirm. It does not: drop it, with a one-line reason.
- C's escalated bugs enter this pool as single reports, and get verified the same way.
- Nits are never verified. Reading one costs less than checking it.

Do not take a reviewer's word on a singleton, and do not drop one because it sounds
unlikely. Trace it or drop it explicitly.

## 4. Report

Every line carries the agents that reported it, as a `[A]`, `[A,B]` or `[A,B,C]` tag.
The human uses the tag to weigh the finding: three agents agree, or one saw what the
others missed. Name the models once, at the top of the report:

> A = Fable low · B = gpt-5.6-sol medium · C = Opus (nits)

Two sections, each ranked by severity:

1. **Confirmed issues** — `[agents]`, `file:line`, the defect, the failure scenario.
2. **Nits** — `[agents]`, `file:line`, one line each.

Then, below, the singletons you dropped and why — `[agent]` and one line each, so the
human can overrule you.

Offer the fixes as **two separate questions**: confirmed issues first, nits second.
Mixing a nit sweep into a bugfix diff makes the fix unreviewable. Fix only what was
confirmed; do not repair things no reviewer raised.
