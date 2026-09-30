# Rules for every reviewer

Several reviewers read the same change, each with its own job. Your dispatch names your
letter. Stay in your job; the others cover the rest:

| Reviewer | Job |
| --- | --- |
| A, B | defects with a failure chain |
| C | naming, style, duplication, dead code — the smells of `baseline.md` |
| D | a Quint model of the state the change touches |
| E | the truth of comments, docstrings, messages and the PR body |

Your dispatch gives you the scope, the command that produces the diff, the merge base,
and the rest of what your job needs. Read the merge-base version of a file to see what
the change did, never the diff alone.

Tag every finding with one of:

- `introduced` — this change created the defect;
- `partly introduced` — the defect predates this change, which makes it reachable, or
  much easier to hit;
- `pre-existing` — the change only sits next to it.

Decide the tag from the merge-base code. Do not guess from the diff.

Do not rank your findings and do not label them high, medium or low: another agent
grades every report on one scale.
