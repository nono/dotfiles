---
name: project-insights
description: Use when asked how Claude Code is being used on this repository, what the friction is, whether CLAUDE.md should change, or for a usage report or insights scoped to one project rather than the whole account.
---

# Project Insights

The built-in `/insights` reads every project you have ever worked on and reports on
your account. This one reads the transcripts of **one repository** — every worktree of
it — and reports what to change in that repository.

The value is in the last two sections: what the repo's own instructions get wrong, and
what to fix in the repo. A report that stops at counts is a failed report.

## 1. Collect

```sh
python3 <skill dir>/collect.py --repo <repo root> --out <scratchpad>/insights
```

It finds the project directories for every live worktree, and for removed worktrees
whose branch the repo still knows. It writes `digest.json` (counts) and
`messages.txt` (the shortest human messages, newest 500). `--days N` narrows the
window.

A worktree that was removed *and* whose branch was deleted is not found. Say so if the
session count looks low.

## 2. Read

Read `digest.json` in full. Read `messages.txt` in full — the numbers say what
happened, the messages say why.

Then read the repo's `CLAUDE.md`, and any nested one. You are about to judge it.

## 3. Cross-check the instructions against the behaviour

This is the step the built-in report cannot do. For each rule in `CLAUDE.md`:

| Look for | Where |
|---|---|
| A rule broken repeatedly | `failing_bash`, and grep the transcripts for the pattern the rule forbids |
| A rule a linter or hook already enforces | the rule's own text, `.golangci.yml`, `.claude/settings.json` hooks |
| A question asked more than once | `messages.txt` |
| A file the repo needs and does not have | `messages.txt` asks about it, or the rule points at nothing |
| A rule that fires in one directory only | its section topic vs. the repo layout |

Count the violations before you claim one. `grep -c` over the transcripts is the
evidence; a hunch is not.

## 4. Report

Publish an artifact. Load `artifact-design` and `dataviz` first, write the HTML to a
file, then call `Artifact` with a favicon.

The page has six sections, in this order:

1. **At a glance** — four short paragraphs: what works, what hinders, quick wins, what
   to prepare for. No numbers here.
2. **Corpus** — sessions, worktrees, window, human messages. One line and one chart of
   sessions per day.
3. **Work areas** — 4-5 areas from `messages.txt`, with the worktrees that belong to
   each. Skip Claude Code's own operations.
4. **Interaction style** — how the person drives: plan first or dive in, interrupt or
   let it run, which skills and subagents. Charts: tool calls with their error share,
   turn durations, slash commands.
5. **Instruction findings** — one row per CLAUDE.md rule that is wrong, duplicated,
   stale, missing, or misplaced. Each row carries its evidence count.
6. **Repo actions** — ranked, each one a change to a named file or setting, each with
   the count that justifies it.

Every claim in sections 5 and 6 carries a number from the digest or from a grep you
ran. Sections 1, 3 and 4 are prose.

Hand back the URL, and put the three highest-ranked actions in the terminal reply so
the person can act without opening the page.

## Common mistakes

- Reporting error counts as friction. A `grep` that exits 1 found nothing; that is not
  a problem. Read the sample before you call an error a failure.
- Ranking by count alone. Six two-minute timeouts beat two hundred harmless exit-1s.
- Repeating the digest as a table and calling it a report. The digest is the input.
- Recommending a rule the repo already has. Read `CLAUDE.md` before section 6.
