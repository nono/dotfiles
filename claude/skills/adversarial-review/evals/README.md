# Test set of the adversarial-review skill

Each case is a pull request that a human reviewed, at the commit they reviewed. Its
expectations are the findings of that review, each with the reviewers whose job covers
it. `revieweval` runs those reviewers on each case with the skill's current prompts,
then a judge (Opus) says which expectations each report states, and counts the defects
the report states.

## Splits

- **train**: tune the prompts on these. #806, #812 and #823 are here because the
  prompts were already tuned on them; #811 was drawn at random.
- **test**: drawn at random. Score these to check a change, and never tune on them:
  a gain on train that test does not show is overfitting.
- **clean**: pull requests the human approved with no finding. The findings a reviewer
  reports there show how much noise it adds.

## Run

```sh
go -C ~/.claude/skills/adversarial-review/evals build -o /tmp/revieweval .
/tmp/revieweval -out <dir> -agents A,E                  # train and clean, 3 runs each
/tmp/revieweval -out <dir> -agents A,E -splits test     # to check a change
/tmp/revieweval -out <dir> -judge-check -splits train,test
```

`-help` gives the options. The reviewers give different answers from run to run, so
each case runs 3 times (`-reps`), and `results.md` gives the noise next to each rate:
a difference smaller than the noise shows nothing. A run of E costs about $1, a run of
A more. Each run is capped at 10 GB of memory through `systemd-run` (`-mem`), because
A and B run tests that a mutation can make allocate without bound.

Run `-judge-check` after any change to the judge prompt: it judges, twice each, a
report that states every expectation, one that lists each as checked and fine, and an
empty one. All three must get their known verdicts, the same way both times.

## What keeps the answers away from the reviewers

- Each run gets a new repository that holds one branch at the reviewed commit, and
  borrows the objects of the real one. No ref, remote or log shows the fixes made
  after the review.
- `bodies/` holds each PR body as it was when the human reviewed it, from GitHub's
  edit history, without the CodeRabbit summary: in a real review, E reads the draft
  body before the PR exists.
- `results.md` lists the leak signs in each run's actions: `gh`, `pull/`, `origin/`,
  `--all`, the path of the real repository. A run with a sign needs a look at its
  `transcript.jsonl` before its score counts.

## Add a case

1. Take the commit the human reviewed (`reviews.commit.oid` in the GitHub API), its
   merge base with the base branch, and the PR body at the time of the review
   (`userContentEdits`). Save the body to `bodies/<number>.md`, without CodeRabbit's
   summary.
2. In `cases.json`, write each finding the skill must catch as one expectation: what
   is wrong and where, in one or two sentences, and the reviewers whose job covers it
   (see `../prompts/common.md`). Leave out findings no reviewer is meant to catch.
   Put a new case in test unless a prompt was tuned on it.
3. `go test .` checks the file.
