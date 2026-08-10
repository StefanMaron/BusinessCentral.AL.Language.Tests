# BusinessCentral.AL.Language.Tests

> An executable specification of the AL language — how it works, what it returns, and what it throws — verified against a real BC Cloud tenant on every commit.

[![AL Language Tests](https://github.com/StefanMaron/BusinessCentral.AL.Language.Tests/actions/workflows/ci.yml/badge.svg)](https://github.com/StefanMaron/BusinessCentral.AL.Language.Tests/actions/workflows/ci.yml)

## Why This Exists

AL documentation explains _what_ a method does. This repo shows _exactly_ how it behaves in practice.

Consider `Record.Copy` — the documentation describes the parameters, but many developers aren't sure whether it copies field values, filters, or both, whether a `TEMP` source record copies data or just structure, or how it interacts with `SetRange`. A single test answers that definitively, and the answer is machine-verified against a real BC Cloud tenant on every commit.

This repo is useful in two ways:

**As a language reference** — search by type name or method and find a test that documents the exact behavior, including edge cases and error conditions. Every test is a behavioral contract backed by a CI run, not a prose description that may be out of date.

**As a cross-version compatibility map** — the CI matrix runs against BC 27.5 and BC 28.1. Version-gated tests (`#if BC28PLUS`) document which features changed between versions and exactly how. This is the kind of precision that release notes rarely provide.

The primary goal is BC Cloud compatibility. Every in-scope AL feature gets at least one positive test proving it works and one negative test proving it fails predictably at the boundary. Cloud-restricted features (file I/O, .NET interop, `HttpClient`) get exactly one negative test confirming the expected error.

**AL Runner:** if `BusinessCentral.AL.Runner` handles a feature incorrectly, write the test here to document the correct Cloud behavior. Once the runner is fixed, the test moves to its regression suite.

---

## Quick Start

**CI:** Push to any branch. GitHub Actions runs the full matrix over BC 27.5 and 28.1 automatically — no self-hosted runner required.

**Local development** (requires a bc-linux Docker container at `localhost`):

```bash
cd tests/al-language
al-compile && bc-publish && python3 run-bc-tests.py
```

Default local dev credentials: `BCRUNNER` / `Admin123!`

See [StefanMaron/MsDyn365Bc.On.Linux](https://github.com/StefanMaron/MsDyn365Bc.On.Linux) for container setup.

---

## Test Areas

355 AL files, 211 test codeunits (ID range 60000–60999), target `Cloud`, runtime 16.1 (BC 27+).

| Area | Description |
|------|-------------|
| `record/` | Record CRUD, filters, locking, keys, copy, insert/modify/delete contracts |
| `recordref/` | Dynamic record access via RecordRef — field iteration, open/close, filters |
| `fieldref/` | FieldRef read/write, type coercion, option values |
| `codeunit/` | Codeunit instantiation, interface dispatch, run behavior, single-instance lifetime/scope |
| `collections/` | List, Dictionary, Queue, Stack — all collection types |
| `error-handling/` | Error/Commit semantics, nested try-functions, confirm behavior |
| `handlers/` | Message, Confirm, StrMenu, page handler, TestPage, and report execution/rendering contracts |
| `install/` | Install/upgrade-trigger seeding lifecycle |
| `json/` | JsonObject, JsonArray, JsonToken — parse, write, path traversal |
| `query/` | Query objects — open/read/close, filters, column metadata, security filtering, stream exports, join semantics |
| `out-of-scope/` | One negative test each for File, .NET, HttpClient — confirms Cloud throws |
| `session/` | Session variables, UserSecurityId, isolated storage, NavApp module info, regional settings, Company behavior |
| `streams/` | InStream/OutStream, TempBlob, BLOB field contracts |
| `text/` | String operations, formatting, regex, encoding |
| `types/` | Primitive type behavior — Integer, Decimal, Date, Time, DateTime, Boolean; interface dispatch and codeunit-as-variable |
| `xml/` | XmlDocument, XmlNode, namespace handling, serialization |
| `xmlport/` | XmlPort stream import/export, nested data items, trigger-driven variables, import property semantics |
| `_fixtures/` | Shared fixture library (see below) |

---

## Fixture Library

All tests share a single fixture library — no per-test table definitions. The library lives in `_fixtures/` and includes 10 tables, 2 enums, 1 interface, 2 pages, 1 report, 1 query, 6 XmlPorts, and 2 event codeunits.

Tests reference fixtures directly; they never define their own schema objects. This keeps test files focused on a single behavioral claim.

Full fixture reference: [PLAN.md](tests/al-language/PLAN.md)

Working backlog: [AL Language Coverage Gaps](docs/al-language-coverage-gaps.md)

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full guide, including:

- How to write a test (the two-rule contract, Initialize, fixture usage)
- Naming conventions
- Version-gated tests with preprocessor directives
- Local development setup
- PR checklist

### Quick example

```al
[Test]
procedure Record_Copy_TempSource_CopiesRows()
// CLAIM: Copy() from a TEMP record transfers all rows to the destination.
begin
    Initialize();

    Source.Init(); Source."No." := 1; Source.Insert();
    Source.Init(); Source."No." := 2; Source.Insert();

    Dest.Copy(Source);

    Assert.AreEqual(2, Dest.Count(), 'Copy from TEMP must transfer all rows');
end;
```

### Runner Gap Contribution Path

1. Identify behavior the AL Runner gets wrong
2. Write a test here that passes against BC Cloud and documents the correct behavior
3. Open a PR referencing the runner issue (use the [runner-gap issue template](.github/ISSUE_TEMPLATE/runner-gap.yml))
4. Once [BusinessCentral.AL.Runner](https://github.com/StefanMaron/BusinessCentral.AL.Runner) is fixed, the test is promoted to its regression suite

---

## Related Repos

- [StefanMaron/MsDyn365Bc.On.Linux](https://github.com/StefanMaron/MsDyn365Bc.On.Linux) — BC runtime on Linux; powers local dev and CI
- [StefanMaron/BusinessCentral.AL.Runner](https://github.com/StefanMaron/BusinessCentral.AL.Runner) — AL Runner; tests here feed its regression suite
