# Reviewers A and B

Read every changed file in full, and the callers of anything you doubt. When the
dispatch quotes a spec, read it before you read the code.

Other agents review this same code, and every finding is verified afterwards. A missed
defect costs more than a false finding: a verifier drops a false one, but nobody catches
a missed one. Report each candidate you can give a failure chain for, even when you are
not sure, and say how sure you are. You have a 30 minute budget.

## Experiments

The dispatch gives you your own worktree, at the head of the change. Edit and run code
only there. When a command can prove or kill a candidate, run it: apply the edit a test
should catch and run the suite; write the test that shows the race or the wrong output;
run a benchmark on both commits. Put the command, and the output lines that decide it,
in the finding. Put the tree back before the next experiment:
`git -C <worktree> checkout -- . && git -C <worktree> clean -fd`.

Run each `go` command through `reviewrun`, which adds `nice -n 19` and a memory cap, and
logs what the command used:
`<skill dir>/bin/reviewrun -log <resource log> -label <your letter> -- go test ...`.
Without a resource log in the dispatch, leave out `-log`. Run the
unit tests of named packages, with `-run` when you can. Run an integration test only by
name, never a whole shard or package. Follow the repository's CLAUDE.md on what may not
run at the same time.

## Searches

Nine searches that a read of the added lines misses:

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
- For each field, map entry, channel or row the change reads to take a decision, find
  every write and every delete of it with ast-grep (see Code search in `common.md`). A
  writer the change does not account for is a candidate.
- For each function whose result, error or side effect the diff changes, follow every
  caller to the final effect: a system stop, a dropped message, a stored record, a
  published payload, a log line. Find the callers with ast-grep. Compare it with the
  final effect at the merge base. A caller whose final effect changes is a candidate.
  For each migration the diff adds that can fail or refuse, follow what the migration
  runner does with the version it leaves dirty, at the next start of the service. A
  service that cannot start again is a candidate.
- For each input the change adds or reads anew — a parameter, a flag, an environment
  value, a payload field, a URL, the output of a command the code parses — list the
  values a caller can send: empty, malformed, out of range, with surrounding whitespace,
  with a space or a non-ASCII character, another scheme, a placeholder such as `-`.
  Follow each one to its effect. A value the code accepts and then mishandles is a
  candidate. For each switch on a closed set — a verb, a status, a step kind — check what
  a value the switch does not name does. A silent no-op or a success is a candidate.
- For each condition the diff adds or changes — an `if`, a `case`, a filter, a `WHERE`
  clause, a bound — read the tests that reach it and name the clause no test makes
  decide. Remove that clause alone, or move the bound by one, and run the tests of its
  package. Run at most five such edits in all, the ones the tests seem least to vary. A
  suite that stays green is a candidate. For each test the diff adds, list each
  dimension the changed code branches on — a status, zero or one item, a second entity,
  a nil field — and the values its fixtures take. A dimension that has one value in
  every fixture is a candidate, with no edit needed: name the value no fixture takes.
- For each key the diff renames, removes or makes optional in a JSON body, an HTTP
  response or an MQTT payload, find each reader that does not deploy with this change: a
  service on an older image, `~/ts/tgx-ui` (its types are generated from the OpenAPI
  specs, under `src/app/generated/`) and `~/ts/lifty-firmware`. grep each for the old
  key. A reader that still needs it after the deploy is a candidate, unless the change
  still writes the old key.

When the diff adds or changes a design under `docs/design/`, its rules are the code.
Run the sixth and seventh searches on them: for each closed set the design names — a
status, a code, a reason — what a value it does not class does; for each actor, what
happens when it runs at the same time as another, or after a stop or a disable; for each
call or wait, the outcome when no answer comes. A rule that gives no outcome, or a wrong
one, is a candidate. Its failure chain is the one the code will have when it follows the
design.

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
- the confidence: `proved` when an experiment you ran shows the failure; `traced` when
  you read each step of the chain in the code, with its `file:line`; `suspected` when a
  step is unread or uncertain — name that step;
- one line for the fix.

A finding you cannot give a failure chain for is not a finding. Drop it.
