---
name: premortem
description: Tell what can go wrong in production, in the UI, in the CI or in other services if a PR is merged. Argument - the PR number.
disable-model-invocation: true
argument-hint: <PR number>
---

# Premortem

Assume the PR merged, deployed, and caused an incident. Find the incidents it can
cause. A code review asks "is this code correct?"; a premortem asks "what breaks
around this code?": the callers, the clients, the data, the deploy, the CI.

The skill is read-only. Do not comment on the PR, push, or edit the branch.

## 1. Load the PR

No argument: ask for the PR number and stop.

```sh
gh pr view <N> --json number,title,body,author,baseRefName,headRefName,files,additions,deletions
git fetch origin "+refs/heads/${base}:refs/premortem/<N>-base" "+pull/<N>/head:refs/premortem/<N>"
git worktree add --detach <scratchpad>/pr-<N> refs/premortem/<N>
git -C <scratchpad>/pr-<N> diff "refs/premortem/<N>-base...HEAD"
```

Fetch the base into its own ref: `origin/<base>` is missing for a stacked PR's base in a
clone whose fetch refspec is narrow. Write `${base}` with braces: in zsh, `$base:r` is a
modifier.

Read the code at the head in that worktree, not only the diff: a risk is usually in a
caller the diff does not show. Read the Shortcut story (`sc-NNNN` in the branch or the
title) when there is one: it tells what the change must do.

At the end, remove the worktree (`git worktree remove`) and the refs
(`git update-ref -d` on `refs/premortem/<N>` and `refs/premortem/<N>-base`).

## 2. Map the blast radius

For each changed file, name its **contracts**: what other code, people or systems
depend on. Examples: a function signature, a JSON field, an HTTP route, an event topic,
a table column, an env var, a CLI flag, a CI job, a default value.

For each contract that changes, find every consumer. Grep the whole repository at the
head, and the sibling repositories under `~` that share the contract (a frontend, a
client, another service). A consumer that you did not find is a risk you did not see.

The step is done when each changed file has a row in the coverage table of step 4,
with its contracts and their consumers, or "no contract: <reason>".

## 3. Hunt

Apply every lens of the table to the diff and to the consumers. A lens that does not
apply gets one line in the report: why not.

| Lens | Look for |
| --- | --- |
| Authentication, authorization | A route, handler or query that loses a middleware, a role check or a tenant filter. A token, session or cookie change. A new endpoint without the auth that its siblings have. |
| Wire contract | A field renamed, removed, retyped, made nullable or optional. An enum value added (old clients with an exhaustive switch). Omitted versus `null` versus zero. A changed status code, error shape, sort order, pagination, date format or unit. The UI, mobile apps, other services and stored payloads read the old shape. |
| Deploy and rollback | Old and new versions run at the same time during a deploy. Can each read what the other writes (messages, cache entries, rows)? Can you roll back after the migration ran? Must something deploy first (config, secret, migration, other service)? |
| Data and migrations | A lock on a large table, a backfill in a transaction, a `NOT NULL` without a default, a destructive change, a migration version below the newest one on the base. Data written in a new format that old code cannot read. |
| Logic | Inverted conditions, off-by-one, a missed branch, a changed default, a time zone, a rounding, an error swallowed or turned into success, a retry that duplicates a side effect. Check the code against the story. |
| Performance | A query in a loop (N+1), a missing index for a new filter, a full scan, O(n²) on data that grows, a new call on a hot path, a removed cache, a lower timeout or a higher one that holds resources. Give the size of the data in production when you can find it. |
| Memory and resources | A whole table, file or response loaded into memory, a cache or map without a bound or eviction, a goroutine, connection, file or timer that does not close, a buffer that grows with the input. |
| Concurrency | Shared state without a lock, a check-then-act race, an order of messages that the code assumes, two instances of the service doing the same job. |
| Open PRs | What happens to the other open PRs when this one merges: a generated or golden file they must regenerate, a renamed symbol they still call, a migration version they collide with. A PR whose CI ran before this merge can merge after it without a new run (`gh api repos/<owner>/<repo>/rulesets`, branch protection `strict`), and turn the base branch red. |
| CI and tooling | A workflow, Makefile, hook or lint config change. Tests that are slower, flaky, skipped or that no longer run. A new dependency or toolchain version. A cache key change. A required check renamed. |
| Configuration | A new env var, flag or secret without a value in each environment. A changed default. A feature flag that is on where it must be off. |
| Dependencies | A new or updated package: breaking changes in its changelog, license, size, transitive updates in the lock file. |
| Observability | Logs, metrics or alerts removed or renamed (dashboards and alerts read them). Secrets or personal data in a new log line. A new log line in a hot loop. |
| Security | Injection (SQL, shell, path, template), a secret in the code, an open redirect, a CORS or CSP change, user input that reaches a file path or a command. |

Add a lens when the PR touches an area the table does not cover.

## 4. Verify

For each risk, write the **failure chain**: trigger → what the code does → what a user,
an operator or the CI sees. Point to `file:line` at the head. A risk without a chain is
a worry: drop it, or name the fact that you could not check.

Then try to refute it: read the guard you assume is missing, the test that covers the
case, the config that sets the value. Run a cheap check when it settles the question:
a test, a query plan, a grep, `go vet`. Keep only the risks that survive, and say what
you ran.

Grade each one:

- **High**: likely, and it breaks a user path, leaks data, loses data, or blocks the
  deploy or the CI.
- **Medium**: needs a less usual input or load, or the damage is limited and easy to
  repair.
- **Low**: unlikely, or cosmetic.

## 5. Report

Use ASD-STE100 Simplified Technical English and few words.

1. One line: the PR, and the verdict: safe to merge, merge after the checks below, or
   do not merge.
2. The risks, high first. For each one: the grade, the lens, a one-line title, the
   failure chain, `file:line`, and the check or fix that removes it.
3. Before merge: the ordered list of actions (a deploy order, a config value to set, a
   test to run, a person to warn).
4. The coverage table: each changed file, its contracts, the consumers you checked, the
   lenses that found nothing and why.
5. What you could not check (a repository you could not read, production data sizes,
   a staging test), so the user knows where the report is blind.
