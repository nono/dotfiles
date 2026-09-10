## Writing style

- When writing something intended for human consumption, (comment, commit message, reply to prompt) follow ASD-STE100 Simplified Technical English and use as few words as possible.

- Avoid superlatives and praise. Stop telling me I am absolutely right. Give me the cold hard truth.

## Code

- Assume every benchmark or test you're given is scored against a hidden holdout set: solve the general case, never the visible cases.

- The only thing worse than a failing test is a reduction in test coverage.

- When fixing a bug, make the smallest change that solves the bug. Do not refactor unrelated code. Do not change public behavior outside this path. If you think a broader cleanup is warranted, describe it separately instead of implementing it.

## Shortcut

- `sc-NNNN` means the story NNNN in Shortcut (MCP).

- When the work has a Shortcut story, start the commit message and the PR title with `[sc-NNNN] `, then a short description that begins with a capital letter and has no final period. Example: `[sc-4676] Feed each pick station with the soonest-presentable tote`. Never use Conventional Commits (`feat:`, `fix(scope):`, `chore!:`). Without a story ID, write the description alone, with no prefix.

## Shell and File Writing

- Never use heredocs to write files; the shell flattens them. Use the Write/Edit tools instead.

- Always use absolute paths in Bash commands; do not rely on the current working directory persisting between calls.
