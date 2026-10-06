## Writing style

- When writing something intended for human consumption, (comment, commit message, reply to prompt) follow ASD-STE100 Simplified Technical English and use as few words as possible.

- Avoid superlatives and praise. Give me the cold hard truth.

## Code

- Solve the general case. Never special-case the inputs of the visible tests or benchmarks.

- The only thing worse than a failing test is a reduction in test coverage.

- When fixing a bug, make the smallest change that solves the bug. Do not refactor unrelated code. Do not change public behavior outside this path. If you think a broader cleanup is warranted, describe it separately instead of implementing it.

- For a performance change, measure the gain of each part of the change alone. Keep only the parts that give a measurable gain, and give the figures of each part in the PR body.

- For a change to a Makefile, a CI workflow, a script or a hook, list in the PR body each check the old version ran and where the new version runs it. Then run the real target, not a stub, on a planted defect that each check must catch, such as an unused import, a line that is too long, or a finding only `go vet` reports.

- Before you suggest a follow-up PR, examine if one more commit in the current PR can do it. Each PR costs the team a review. Do it in the current PR when the change is small, related to the PR, and does not delay the merge. Suggest a follow-up only when there is a good reason: the change is large, has a different risk, needs a different reviewer, or must wait for a decision or a deploy. Give that reason.

- Design documents go in `docs/design/`, named `YYYY-MM-DD-<topic>-design.md`. This overrides the `docs/superpowers/specs/` default of the superpowers brainstorming skill. Implementation plans are temporary: delete them before merge.

## Shortcut

- `sc-NNNN` means the story NNNN in Shortcut (MCP).

- When the work has a Shortcut story, start the commit message and the PR title with `[sc-NNNN] `, then a short description that begins with a capital letter and has no final period. Example: `[sc-4676] Feed each pick station with the soonest-presentable tote`. Never use Conventional Commits (`feat:`, `fix(scope):`, `chore!:`). Without a story ID, write the description alone, with no prefix.

## Shell and File Writing

- Never use heredocs to write files; the shell flattens them, or hangs until the command is killed. Use the Write/Edit tools instead, and `git commit -F <file>` for a multi-line commit message.

- The Bash tool runs zsh. In zsh, a glob that matches no file stops the command with `no matches found`. Quote each glob that is for the command and not for the shell: `grep -rn X --include='*.go' .`, not `--include=*.go`. Or use `git grep X -- '*.go'`. Quote a word that starts with `=` too: zsh reads `echo ===` as a command path and fails with `== not found`.

- Give `git grep` its options before the pattern: `git grep -n -A3 X`, not `git grep -n X -A3`, which fails with `unable to resolve revision: -A3`.

- Always use absolute paths in Bash commands; do not rely on the current working directory persisting between calls.

- If a tool that is not installed can help, ask me to install it. Give the `apt` or `mise` command. Do not install it yourself.

- Do not write a new shell script of more than 100 lines (soft limit). Use a better language, such as Go. More lines of code are acceptable: static typing, tooling and tests make the work easier and faster.
