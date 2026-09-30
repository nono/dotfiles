# Reviewers A and B

Read every changed file in full, and the callers of anything you doubt. When the
dispatch quotes a spec, read it before you read the code.

Another agent reviews this same code, and every finding is verified afterwards. A false
finding costs more than a missed one: each one takes a verifier's time. Report only what
you have convinced yourself of. You have a 30 minute budget.

## Experiments

The dispatch gives you your own worktree, at the head of the change. Edit and run code
only there. When a command can prove or kill a candidate, run it: apply the edit a test
should catch and run the suite; write the test that shows the race or the wrong output;
run a benchmark on both commits. Put the command, and the output lines that decide it,
in the finding. Put the tree back before the next experiment:
`git -C <worktree> checkout -- . && git -C <worktree> clean -fd`.

Run each `go` command under `nice -n 19` and a memory cap:
`nice -n 19 systemd-run --user --scope --quiet --collect -p MemoryMax=8G -p MemorySwapMax=0 -- go test ...`
— or plain `nice -n 19 go test ...` when `systemd-run` fails in your sandbox. Run the
unit tests of named packages, with `-run` when you can. Run an integration test only by
name, never a whole shard or package. Follow the repository's CLAUDE.md on what may not
run at the same time.

## Searches

Six searches that a read of the added lines misses:

- For each line the diff deletes or replaces, name the behaviour it enforced — a guard,
  an error path, a validation, a test case. Then find where the new code enforces it
  again. If you find no such place, you have a candidate.
- For each type the diff adds or changes that wraps another — cache, proxy, decorator,
  adapter — check that every method calls the wrapped instance, not back through a
  registry, session or global. Also check that it forwards every method its callers use.
- For each feature flag, environment variable or config value the changed code reads,
  find the value each test runs with — read `TestMain` and the test setup. A value no
  test runs is a candidate: read the changed path under that value.
- For each function the diff changes, find its twins: the sync and the async variant,
  the same logic for another entity (`handleX` and `handleXPick`), a copy in another
  package, a package that uses the same pattern. A twin that the diff does not change
  the same way is a candidate.
- For each field, map entry, channel or row the change reads to take a decision, grep
  every write and every delete of it. A writer the change does not account for is a
  candidate.
- For each function whose result, error or side effect the diff changes, follow every
  caller to the final effect: a system stop, a dropped message, a stored record, a
  published payload, a log line. Compare it with the final effect at the merge base. A
  caller whose final effect changes is a candidate.

## What to report

Any defect you can tie to a concrete failure chain:

- wrong behaviour, data loss, security holes, broken contracts, unhandled failures, race
  conditions;
- a path this diff adds that no test pins — apply the edit that guts it in your
  worktree, run the suite, and report that it stays green;
- a fix that no test pins. When the change fixes a bug or a cost, put that bug or cost
  back with the smallest edit, in your worktree, and run the suite. Green is a finding,
  even when every output stays the same;
- a failure that is silent: no log, no metric, nothing returned to the caller;
- a requirement the spec asks for that the change does not meet, or behaviour the change
  adds that no requirement asks for. Quote the line of the spec you judge it against.

Report each finding as:

- `file:line`, and its provenance;
- one sentence stating the defect;
- **If not addressed**: the failure chain. Specific inputs or state, the wrong output or
  crash that follows, and who pays for it. For an unmet requirement, the chain is what
  the user asked for and does not get, and the story that closes unmet;
- the experiment, when you ran one: the command and the output lines that decide it;
- one line for the fix.

A finding you cannot give a failure chain for is not a finding. Drop it.
