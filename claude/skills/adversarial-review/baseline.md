# The nit baseline

The fixed list agent C works through. Three rules bind it:

- **The repository wins.** A rule in CLAUDE.md, or the shape of the code next to the
  change, overrides any entry here. Where the repository endorses what an entry would
  flag, drop the entry.
- **Every entry is a judgement call**, never a violation. Report it as "possible
  duplicated code", and say what makes you think so.
- **Skip what tooling already reports.** The linter and the formatter run on every
  commit. A finding they produce costs the human nothing to get, and costs you a slot.

Each entry reads *what it is* → *what to do*:

- **Mysterious name**: a function, variable or type whose name hides what it does or
  holds. → Rename it. If no honest name comes, the design is unclear, and say so.
- **Duplicated code**: the same shape in two hunks or two files. → Extract it, call it
  from both.
- **Feature envy**: a function that reaches into another type's data more than its
  own. → Move it onto the data it envies.
- **Data clumps**: the same few fields travel together everywhere. → Give them one
  type and pass that.
- **Primitive obsession**: a string or an int standing in for a domain concept. → Give
  the concept its own small type.
- **Repeated switches**: the same switch on the same type, in several places. → One
  map both sites share, or polymorphism.
- **Shotgun surgery**: one logical change forced edits across many files in this diff.
  → Gather what changes together.
- **Divergent change**: one file edited in this diff for several unrelated reasons. →
  Split it, so each part changes for one reason.
- **Speculative generality**: a parameter, hook or abstraction for a need the spec does
  not have. → Delete it. Inline it back until a real need appears.
- **Message chains**: `a.b().c().d()` navigation the caller should not depend on. →
  Hide the walk behind one method.
- **Middle man**: a type or function that only delegates onward. → Call the real target.
- **Dead code**: a branch, field or export this diff leaves unreachable. → Delete it;
  git keeps it.
- **Comment rot**: a comment that describes what the code used to do, names its own
  caller, or states an invariant the code no longer holds. → Reword it in the present
  tense, or delete it.
- **Out of step with the neighbours**: the change does X where the code around it does
  Y — error wrapping, logging, test naming, table-driven tests. → Follow the
  neighbours, or say why this one differs.
