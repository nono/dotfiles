# Rules for every reviewer

Several reviewers read the same change, each with its own job. Your dispatch names your
letter. Stay in your job; the others cover the rest:

| Reviewer | Job |
| --- | --- |
| A, B | defects with a failure chain |
| C | over-engineering, code out of step with the repository, and the smells of `baseline.md` |
| D | a Quint model of the state the change touches |
| E | the truth of comments, docstrings, messages and the PR body |
| F | defects with a failure chain, against the rules of `ocr` |

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

## Code search

To find code by its shape, use `ast-grep run -l go -p 'PATTERN' .`, not grep. grep
misses a call split over two lines and matches the name in comments and strings.

| To find | Pattern |
| --- | --- |
| the calls of a method or function | `-p 'x := $X.Claim($$$)' --selector call_expression` |
| the declarations of a method | `-p 'func ($R $T) Claim($$$)'` |
| the writes of a field | `-p '$X.status = $V'` |
| the deletes from a map | `-p 'delete($M, $K)'` |
| the literals of a struct | `-p 'models.PickEntry{$$$}'` |

The pattern `$X.Claim($$$)` alone parses as a type and matches nothing: give the
context and the selector, as above. Use grep for plain text: a string, a log message,
a config key. Call the tool `ast-grep`, never `sg`.
