## What this PR adds or changes

<!-- One sentence describing what behavioral claim(s) this PR adds, fixes, or improves. -->

## Linked issue

Closes #<!-- issue number, or "n/a" -->

## Test area(s)

<!-- Which folder(s) under tests/al-language/ does this touch? -->

## Checklist

- [ ] `Initialize()` is the first line of every `[Test]` procedure
- [ ] `Initialize()` calls `DeleteAll()` on every table used in the codeunit
- [ ] No per-test fixture definitions — only `_fixtures/` objects used
- [ ] Test name uniquely identifies the claim without reading the body (`Type_Method_Scenario_Outcome`)
- [ ] Doc-link comment block is present at the top of each new file
- [ ] Out-of-scope tests are in `out-of-scope/` and confirm the error only
- [ ] Version-gated code uses `#if BC28PLUS` (or equivalent) with an explanatory comment
- [ ] CI passes on this pull request (all required checks: BC 27.5, 28.5 and 29.0)
