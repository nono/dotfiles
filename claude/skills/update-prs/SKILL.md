---
name: update-prs
description: Use when asked to update open PRs from main, to list which PRs are behind main or have git conflicts, or to fix the conflicts of several PRs.
---

# Update PRs

List the open PRs of the user with how far each is behind its base and how many files conflict. Ask which to
update. Merge the base into each one, check it, and push it.

## 1. List

Run `<skill dir>/list-prs.sh` from a clone of the repository. It fetches `origin` and prints one row per PR:

- `BEHIND`: the commits of `origin/<base>` that the PR does not have. The base is the PR's base branch: a stacked
  PR counts against the branch of the PR below it, not against main.
- `CONFLICTS`: the files that conflict when `origin/<base>` is merged into `origin/<head>`. It touches no worktree.
- `?`: the head branch is missing on `origin`, or `git merge-tree` failed.

Show the table as it is.

## 2. Ask

Ask in text which PRs to update; the user types the numbers. Do not use `AskUserQuestion`: it shows 4 options at
most. Do not update a PR that the user did not name.

## 3. Update

Use one subagent per PR, in parallel. When the user names a stacked PR and the PR below it, update and push the
lower PR first, then start the stacked one.

Give each subagent these steps:

1. Find the worktree whose branch is the PR's head branch (`git worktree list --porcelain`). If there is none,
   add one at `~/ts/<sc-NNNN number or branch slug>`.
2. Stop, and report why, when the worktree has uncommitted changes, or when the local branch differs from
   `origin/<head>` (`git fetch origin`, then compare `git rev-parse HEAD origin/<head>`).
3. `git merge origin/<base>`. Resolve each conflict so that the intent of both sides stays: read the commits of
   both sides that touch the conflicting lines. When the right resolution is not clear, run `git merge --abort`
   and report the files and the question.
4. Commit the merge with the default message and the attribution trailer.
5. Run `make check`. On a failure caused by the merge, fix it in a new commit and run it again. On a failure that
   `origin/<base>` has too, report it and do not push.
6. Do not push when a resolved conflict is in a file that triggers the tote batch move harness (the list is in
   the root `AGENTS.md`): report it, because the harness must run before a push.
7. Push with `git push`. Never force push.

## 4. Report

One line per PR: the commits merged, the files that had a conflict, the `make check` result, and the pushed sha or
the reason it stopped. Then run `list-prs.sh` again and show the table.
