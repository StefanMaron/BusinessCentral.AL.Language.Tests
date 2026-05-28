# AL Language Coverage Test Suite — Agent Instructions

## What This Repo Is

An executable specification that proves AL language features work correctly
in **BC Cloud** (SaaS). Every test is a behavioral contract: a documented
AL feature + the actual BC runtime + a passing assertion.

### Primary goal — Cloud compatibility

Prove that the AL features the community relies on actually work in BC Cloud.
If you are about to write a test, ask first: **does this feature work in a
BC Cloud tenant?** If yes, write a positive test. If no (File.Upload,
HttpClient, Report.SaveAs, .NET interop, etc.), write exactly one negative
test that confirms it throws the expected error, and stop there.

### Secondary goal — Language surface coverage

Over time, cover the full in-scope AL language surface documented in
`al-surface-inscope.json`. Every in-scope method should have at least one
positive and one negative test.

### The contributor path — runner gaps

If you encounter a feature that the AL Runner handles incorrectly or does not
support, the right step is:

1. Write a test here that proves the **correct** Cloud behavior.
2. The test becomes an executable spec the runner must pass.
3. Once the runner is fixed, promote the test to `tests/bucket-*/` in the
   runner repo as a regression guard.

A test that passes here but fails on the runner is a **runner bug to fix**.
A test that passes on the runner but fails here means the **runner has a gap**.

---

## In-Scope and Out-of-Scope

### Always in scope (write positive + negative tests)

- Record CRUD, filters, FlowFields, keys, triggers, SystemId, RecordId
- RecordRef / FieldRef full API
- Codeunit instantiation, interfaces, events (subscribe/publish/bind)
- Error handling: Error(), asserterror, ErrorInfo, collected errors
- Text, TextBuilder, BigText, Format, Evaluate
- JSON (JsonObject, JsonArray, JsonToken, JsonValue)
- XML (XmlDocument, XmlElement, XmlAttribute, XmlNamespaceManager)
- Query objects
- Streams (InStream, OutStream, Blob) -- in-memory only, no File
- Date/Time arithmetic and formatting
- Integer, Decimal, Boolean arithmetic and edge cases
- Guid, Variant, RecordId coercions
- List<T>, Dictionary<T,U>, Array
- Session functions: UserId, CompanyName, Today, CurrentDateTime
- Database: Commit, IsEmpty, Count, LockTable (in-scope overloads)
- NavApp: GetCurrentModuleInfo, resource access
- Notification, Page handler, Report handler (no rendering)

### Out of scope -- write exactly ONE negative test confirming it throws

- `File.*` -- direct file system access (not available in Cloud)
- `HttpClient` -- throws in runner; one test confirming the error
- `File.Upload` / `File.Download` -- browser round-trip
- SMTP / email sending
- OData / SOAP endpoint calls from AL
- Background task scheduling / job queue execution
- Report rendering to PDF/Word/Excel
- Printing
- `DotNet` interop of any kind

For out-of-scope items, one test per surface area is enough. Name it
`<Type>_<Method>_CloudSandbox_Throws` or similar.

---

## Writing a Test

### The test contract

Every [Test] procedure must satisfy two rules:

1. **It fails if the behavior is broken.** Ask: would this test pass if the
   method always returned a default value (0, '', false)? If yes, strengthen it.
2. **It proves, not just executes.** Assert a specific, non-default value.

### Structure

    [Test]
    procedure Record_Insert_DuplicateKey_Throws()
    // CLAIM: inserting a record with a key that already exists throws a runtime error.
    // DOCS: https://learn.microsoft.com/.../record-insert-boolean-method
    begin
        Initialize();

        Rec.Init();
        Rec."No." := 1;
        Rec.Insert(false);

        asserterror Rec.Insert(false);
        Assert.ExpectedError('already exists');
    end;

### Initialize()

Every test must call `Initialize()` as its first line. This calls
`ALTFixtureCleanup.DeleteAll()` -- the only acceptable way to reset state.
Never delete individual records by hand inside a test.

### Fixture objects

Use only the shared fixture objects from `_fixtures/`. Do not define
per-test tables, enums, pages, or codeunits.

| Object | When to use |
|---|---|
| ALT Universal (50900) | Any test involving primitive field types |
| ALT Composite (50901) | Multi-field PK, composite filter, Rename |
| ALT Triggered (50902) | Trigger verification (OnInsert/Modify/Delete/Rename) |
| ALT Trigger Log (50903) | Assert which triggers fired |
| ALT Parent / ALT Child (50904/50905) | FlowFields, Sum/Count/Lookup |
| ALT Keyed (50906) | SetCurrentKey, secondary key ordering |
| ALT Blob (50908) | InStream/OutStream, Blob.HasValue |
| IALTCompute / ALTDouble / ALTSquare | Interface injection, codeunit-as-variable |
| ALT Event Publisher (50910) | Published events, bind/unbind |

---

## Naming Conventions

### Files

`Test<TypeName><Aspect>.al` -- e.g. `TestRecordInsert.al`, `TestJsonObject.al`

Place in the area subfolder: `record/`, `json/`, `xml/`, `text/`, etc.
Out-of-scope confirming tests go in `out-of-scope/`.

### Procedures

`<Type>_<Method>_<Scenario>_<ExpectedOutcome>`

Examples:
- `Record_Insert_DuplicateKey_Throws`
- `Record_SetRange_DateField_FiltersCorrectly`
- `JsonObject_Get_MissingKey_ReturnsFalse`
- `HttpClient_Send_CloudSandbox_Throws`

The full claim must be readable from the procedure name alone.

### Doc-link comment block (top of each file)

    // BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/
    //   dev-itpro/developer/methods-auto/<type>/<method>-method
    // Scope: in-scope (Cloud-compatible)
    // Fixtures used: ALT Universal, ALT Triggered
    // BC versions: 27.5+

---

## Version Compatibility

All tests must pass on all versions in the CI matrix (currently 27.5 and 28.1).

For features that only exist from a specific BC version onwards, wrap the
test in a preprocessor guard:

    #if BC28PLUS
    [Test]
    procedure SomeNewBC28Feature_Works()
    begin
        ...
    end;
    #endif

Preprocessor symbols are defined in the workflow per version:

| Symbol    | Meaning                        |
|-----------|--------------------------------|
| BC27PLUS  | Available from BC 27.0 onwards |
| BC28PLUS  | Available from BC 28.0 onwards |

Add a comment explaining why the guard exists:

    #if BC28PLUS // System.GetLastErrorText overload with CallStack added in BC 28

---

## Verification Checklist

Before submitting a test:

1. `al-compile` produces zero errors (warnings are allowed).
2. The test passes against a real BC instance (local Docker or CI).
3. The test name uniquely identifies the claim without opening the body.
4. `Initialize()` is the first line of every [Test] procedure.
5. No per-test fixture definitions -- only shared `_fixtures/` objects.
6. Out-of-scope tests are in `out-of-scope/` and confirm the error only.
7. The doc-link comment block is present at the top of the file.

---

## Local Development Setup

See `tests/al-language/PLAN.md` for the full compile-publish-run cycle.

Quick reference:

    # 1. Start BC (from bc-linux repo)
    cd ~/Documents/Repos/community/bc-linux && docker compose up -d --wait

    # 2. Compile + publish + run (from tests/al-language/)
    al-compile && bc-publish && python3 run-bc-tests.py

    # 3. Run a single codeunit
    python3 run-bc-tests.py --ids 60100

Default credentials: BCRUNNER / Admin123! (local dev container only).
