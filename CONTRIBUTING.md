# Contributing to BusinessCentral.AL.Language.Tests

Thank you for contributing! This repo is an executable specification proving AL language features work in BC Cloud — every PR should add or strengthen a behavioral contract.

## Table of Contents

- [What to contribute](#what-to-contribute)
- [Writing a test](#writing-a-test)
- [Naming conventions](#naming-conventions)
- [Fixture library](#fixture-library)
- [Coverage gaps](#coverage-gaps)
- [Version-gated tests (preprocessor directives)](#version-gated-tests-preprocessor-directives)
- [Out-of-scope features](#out-of-scope-features)
- [Local development](#local-development)
- [Running CI locally](#running-ci-locally)
- [Pull request checklist](#pull-request-checklist)
- [Runner gap path](#runner-gap-path)

---

## What to contribute

**Positive tests** — prove an AL language feature works correctly in BC Cloud. This is the primary contribution type. See the in-scope list in [CLAUDE.md](CLAUDE.md#in-scope-and-out-of-scope) for what belongs here.

**Negative tests (out-of-scope)** — prove that Cloud-restricted features throw the expected error. One test per surface area, placed in `tests/al-language/out-of-scope/`. Do not add more than one per feature.

**Runner gap tests** — prove the correct Cloud behavior for something `BusinessCentral.AL.Runner` gets wrong. Write the test here; once the runner is fixed the test is promoted to its regression suite.

If you are unsure whether something is in scope, open an issue first and describe what you want to test.

---

## Writing a test

### The two-rule contract

Every `[Test]` procedure must satisfy:

1. **It fails if the behavior is broken.** Would the test pass if the method always returned a default value (`0`, `''`, `false`)? If yes, strengthen the assertion.
2. **It proves, not just executes.** Assert a specific, non-default value that can only appear if the feature worked correctly.

### File structure

One codeunit per file, one behavioral claim per codeunit:

```al
// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/
//   dev-itpro/developer/methods-auto/record/record-insert-boolean-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Universal (50900)
// BC versions: 27.5+

codeunit 60XXX "Record Insert Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Rec: Record "ALT Universal";
        Assert: Codeunit "Library Assert";

    [Test]
    procedure Record_Insert_AssignsSystemId()
    // CLAIM: Insert() assigns a non-empty SystemId to the record.
    begin
        Initialize();

        Rec.Init();
        Rec."No." := 1;
        Rec.Insert(false);

        Assert.AreNotEqual('', Format(Rec.SystemId), 'SystemId must be assigned after Insert');
    end;

    local procedure Initialize()
    begin
        Rec.DeleteAll();
    end;
}
```

### Rules

- **`Initialize()` first** — every `[Test]` procedure must call `Initialize()` as its first line. `Initialize()` must call `DeleteAll()` on every table used by the codeunit.
- **No per-test fixture definitions** — only use shared objects from `_fixtures/`. Never define tables, enums, pages, or codeunits in a test file.
- **One claim per codeunit** — a file named `TestRecordInsert.al` should only test `Record.Insert`.
- **Doc-link comment** — the top-of-file comment block must link to the relevant BC documentation page.

---

## Naming conventions

### Files

`Test<TypeName><Aspect>.al` — placed in the matching area subfolder:

```
tests/al-language/
  record/          TestRecordInsert.al, TestRecordFindFirst.al
  json/            TestJsonObjectGet.al, TestJsonArrayAdd.al
  query/           TestQueryOpen.al, TestQueryFilters.al
  xml/             TestXmlDocumentLoad.al
  text/            TestTextBuilderAppend.al
  out-of-scope/    TestFileSystemThrows.al, TestHttpClientThrows.al
```

### Procedures

`<Type>_<Method>_<Scenario>_<Outcome>` — the full claim must be readable from the name alone:

| Good | Bad |
|------|-----|
| `Record_Insert_DuplicateKey_Throws` | `TestInsert` |
| `Record_FindFirst_EmptyTable_ReturnsFalse` | `FindFirstOnEmptyTable` |
| `JsonObject_Get_MissingKey_ReturnsFalse` | `TestGetMissing` |
| `Record_Insert_AssignsSystemId` | `InsertSetsId` |

When there is no special condition, omit it: `Record_Insert_AssignsSystemId`.

### Codeunit IDs

Use the next available ID in the `60000–60999` range. Check existing files to avoid conflicts — the last assigned ID is visible in the test area you're adding to.

---

## Fixture library

All tests share a single fixture library in `_fixtures/`. Never define your own schema objects in a test file.

| Object | ID | When to use |
|--------|-----|-------------|
| ALT Universal | 50900 | Primitive field types: Integer, Text, Boolean, Decimal, Date, etc. |
| ALT Composite | 50901 | Multi-field primary keys, composite filters, Rename |
| ALT Triggered | 50902 | Verifying OnInsert / OnModify / OnDelete / OnRename triggers |
| ALT Trigger Log | 50903 | Asserting which triggers fired |
| ALT Parent / ALT Child | 50904/50905 | FlowFields: Sum, Count, Lookup |
| ALT Keyed | 50906 | SetCurrentKey, secondary key ordering |
| ALT Blob | 50908 | InStream / OutStream, Blob.HasValue |
| IALTCompute / ALTDouble / ALTSquare | — | Interface injection, codeunit-as-variable |
| ALT Event Publisher | 50910 | Published events, bind / unbind |

---

## Version-gated tests (preprocessor directives)

Tests that rely on APIs only available from a specific BC version must be wrapped in a preprocessor guard:

```al
#if BC28PLUS // XYZ overload added in BC 28
[Test]
procedure Record_NewBC28Feature_Works()
begin
    Initialize();
    // ...
end;
#endif
```

The CI matrix defines these symbols per version:

| Symbol | Meaning |
|--------|---------|
| `BC27PLUS` | Available from BC 27.0 onwards (always defined) |
| `BC28PLUS` | Available from BC 28.0 onwards |

The guard comment must explain **why** the guard exists — which API or behavior changed.

If you are writing a test for a feature available in all supported BC versions (27.5+), **no guard is needed**.

---

## Out-of-scope features

Features that are not available in BC Cloud each get **exactly one** negative test:

```al
[Test]
procedure File_Open_CloudSandbox_Throws()
// CLAIM: File.Open throws in a BC Cloud tenant.
begin
    Initialize();

    asserterror SomeFile.Open('test.txt');
    Assert.ExpectedError('');
end;
```

- Place in `tests/al-language/out-of-scope/`
- Name: `<Type>_<Method>_CloudSandbox_Throws`
- Do not add more than one test per out-of-scope surface area

Out-of-scope features: `File.*`, `HttpClient`, `File.Upload` / `File.Download`, SMTP, OData/SOAP calls from AL, background job scheduling, report rendering to PDF/Word/Excel, printing, `DotNet` interop.

---

## Coverage gaps

The working backlog for expanding language coverage lives in [docs/al-language-coverage-gaps.md](docs/al-language-coverage-gaps.md).

Use that document to pick the next AL surface to add before writing tests.

---

## Local development

You need a running BC on Linux container. See [StefanMaron/MsDyn365Bc.On.Linux](https://github.com/StefanMaron/MsDyn365Bc.On.Linux) for setup.

```bash
# Start BC (from bc-linux repo)
cd ~/Documents/Repos/bc-linux
docker compose up -d --wait

# Compile, publish, and run all tests
cd tests/al-language
al-compile && bc-publish && python3 run-bc-tests.py

# Run a single codeunit by ID
python3 run-bc-tests.py --ids 60100

# Run only tests in a specific ID range
python3 run-bc-tests.py --ids "60100..60199"
```

Default local credentials: `BCRUNNER` / `Admin123!`

---

## Running CI locally

Push your branch and GitHub Actions runs the full matrix automatically — BC 27.5 and BC 28.1, no self-hosted runner required. Check the [Actions tab](https://github.com/StefanMaron/BusinessCentral.AL.Language.Tests/actions) for results.

You can also trigger a single-version run manually via **Actions → AL Language Test Suite → Run workflow** and entering a specific BC version.

---

## Pull request checklist

Before opening a PR, verify:

- [ ] `Initialize()` is the first line of every `[Test]` procedure
- [ ] `Initialize()` calls `DeleteAll()` on every table used in the codeunit
- [ ] No per-test fixture definitions — only `_fixtures/` objects
- [ ] Test name uniquely identifies the claim without opening the body
- [ ] Doc-link comment block is present at the top of the file
- [ ] Out-of-scope tests are in `out-of-scope/` and confirm the error only
- [ ] Version-gated code uses `#if BC28PLUS` (or equivalent) with an explanatory comment
- [ ] The test fails for the right reason (remove the assertion and confirm it passes; restore it and confirm it fails)
- [ ] CI passes on your branch

---

## Runner gap path

If `BusinessCentral.AL.Runner` handles a feature incorrectly:

1. Write a test here that **passes** against BC Cloud and documents the correct behavior
2. Open a PR referencing the AL Runner issue (link it in the PR description)
3. Once [BusinessCentral.AL.Runner](https://github.com/StefanMaron/BusinessCentral.AL.Runner) is fixed, the test is promoted to its regression suite

A test that passes here but fails on the runner is a runner bug to fix, not a test to delete.
