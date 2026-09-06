# The nightly Windows run, and why it outranks CI

`.github/workflows/ci.yml` runs this corpus on
[`StefanMaron/MsDyn365Bc.On.Linux`](https://github.com/StefanMaron/MsDyn365Bc.On.Linux) on every
PR: eight BC minors, fast, free, and the merge gate. It is also **one particular container**, and
a container is not Business Central.

[Issue #213](https://github.com/StefanMaron/BusinessCentral.AL.Language.Tests/issues/213) showed
the gap concretely. A run against a real Microsoft SaaS sandbox (US BC 28.4, Platform
28.0.53667.0 + Application 28.4.53241.54031) failed 14 tests that CI reports green.

`.github/workflows/nightly-windows.yml` runs `master` against an **official Microsoft BC
container on Windows**. Its verdict is the authority. The operating rule, from #213:

> any test that fails on windows needs to be first fixed on
> https://github.com/StefanMaron/MsDyn365Bc.On.Linux

So: a failure on Windows is a real failure, in the corpus or in BC. A failure that appears only
on Linux is a bug in the Linux image, and it gets fixed there — not by editing the test.

## It is not a merge gate, on purpose

Do **not** add it to the branch ruleset. It takes on the order of an hour or two, and a nightly
that blocks merges stalls the repository. The eight `BC <ver> / test` contexts from `ci.yml`
remain the required checks. This one is a signal for humans.

## Running it on demand

```bash
gh workflow run nightly-windows.yml \
  --repo StefanMaron/BusinessCentral.AL.Language.Tests \
  --ref master \
  -f bc_version=28.4 -f artifact_type=onprem -f country=w1 -f culture=en-US
```

`workflow_dispatch` is only offered for workflows that exist on the **default branch**, so this
works once the file is on `master`. Before then, the workflow's `pull_request` trigger — filtered
to this workflow's own files — runs it on the PR that introduces it.

## The nightly condition

The owner asked for a run "whenever there was a new commit on main on the previous day". The
`gate` job implements exactly that, on a Linux runner so the decision never costs a Windows
minute: it checks out `master` and skips the run when the newest commit is more than 25 hours
old. The window is 25 rather than 24 because GitHub delays cron under load, and a flat 24 would
silently drop a day whenever the run started late relative to the commit.

## Why the environment is printed and not just pinned

Six of #213's 14 failures are properties of the tier, not of BC:

- **three formatting failures** — decimal comma and `dd.MM.yy`, from a European session region;
- **three refused writes** — `Your license does not grant you ... Insert`.

If this workflow's region or license drifts, it re-reports those six forever and people learn to
ignore it. So the session culture and timezone are pinned explicitly, the run **fails** rather
than proceeding if the pinning parameters are unavailable, and the license, container OS, generic
image, BC build and artifact URL are all written to `environment.json` beside the results.

The culture pin is self-verifying: cu 60142, 60624 and 60952 hardcode en-US formatting, so if
they pass, the session really was en-US.

## A green on the permission tests proves nothing

Codeunits 60013 and 60827 declare `TestPermissions = Disabled` and **no** `Permissions` property.
With no permission context of their own, every write falls through to whatever the license
grants. The tables involved (5902, 5406, 5957) are incidental; the missing declaration is the
defect.

A dev-licensed container is expected to **mask** that — the same masking that hid it until a SaaS
run exposed it. So when the comparison reports those three as "passes here", that is not the
defect being cleared, and `bc-test-results.py` prints a warning saying so.

The exposure is corpus-wide. At commit `28869bc2`, **185 test codeunits declare
`TestPermissions = Disabled` and exactly 2 declare `Permissions` at all.** Any of those 185 that
writes to a table a narrower license does not grant will fail the same way on any tier that is
not a dev-licensed container.

## Output

Each run uploads an artifact containing:

| file | what it is |
|---|---|
| `test-results/all-tests.tsv` | every test, one sorted line each: result, codeunit, name, message |
| `test-results/failures.tsv` | just the failures, same shape |
| `test-results/issue-213-comparison.md` | the four-way split against #213's list |
| `test-results/results.json` | the same data structured |
| `environment.json` | the tier the verdict is about |
| `license-information.txt` | full license dump |
| `xunit-*.xml` | raw BC output |

The comparison splits #213's list four ways: **also fails here** (real, and the reason the
nightly exists), **passes here** (a property of the sandbox), **did not run here**, and
**failing here but not listed in #213** — expected to be non-empty, because #213 says its own
list is partial.

`bc-test-results.py` exits non-zero when it parses **zero** tests, because an empty result file
otherwise reports as "0 failures" and reads exactly like a green run.
