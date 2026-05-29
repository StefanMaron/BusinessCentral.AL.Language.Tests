# AL Language Coverage Test Suite — Plan

## What This Is

A ground-up, human- and agent-readable test suite with two goals, in priority order:

**Primary — BC Cloud compatibility proofs.**
Every test proves that a documented AL language feature works correctly in the
BC Cloud (SaaS) runtime. The question this suite answers is: *does this AL feature
actually work in a BC Cloud tenant?* File operations, .NET interop, HttpClient, and
anything else that is unavailable in Cloud are out of scope for positive tests. Each
out-of-scope surface gets exactly one negative test confirming it throws.

**Secondary — Language surface coverage.**
Over time, cover the full in-scope AL language surface. Every in-scope method should
have at least one positive test and one negative test.

A reader — human or agent — should be able to open any test file, read one test
method, and know exactly:

1. Which AL language feature it covers
2. What the BC documentation says should happen
3. That BC Cloud actually does that thing when run against a real container

The working backlog for uncovered or thinly covered surfaces lives in
[`docs/al-language-coverage-gaps.md`](../../docs/al-language-coverage-gaps.md).

## Why Start From Scratch

The existing `tests/bucket-*` suites are runner regression tests. They were written
incrementally alongside runner development, mix concerns, have per-test boilerplate
tables and helper codeunits, and are not structured for language-coverage navigation.
Salvaging them into a coverage document would cost more than building clean.

The existing tests remain valuable — they stay in place as runner CI — but they are
not this.

## Relationship to the AL Runner — Contributing Runner Gaps

This suite serves as the **executable specification** for the AL Runner. If the runner
handles a language feature incorrectly:

1. Write a test here that proves the correct Cloud behavior.
2. The test becomes an executable spec the runner must pass.
3. Once the runner is fixed, promote the test to `tests/bucket-*/` as a regression guard.

A test that passes here but fails on the runner → **runner bug to fix**.
A test that passes on the runner but fails here → **runner has a gap**.

This folder is **isolated from the runner CI**. The runner picks up `tests/bucket-*/`
only. This folder has its own `app.json` and its own CI pipeline.

---

## How to Compile, Publish, and Run

### Prerequisites

A local BC Docker container must be running. Start it from the `bc-linux` repo:

```bash
cd ~/Documents/Repos/community/bc-linux
docker compose up -d --wait
```

First boot takes 5–10 minutes (image pull + DB restore). Subsequent starts ~20 seconds.
Default credentials: `BCRUNNER` / `Admin123!`.

Verify BC is up:
```bash
curl -sf -u BCRUNNER:Admin123! http://localhost:7049/BC/dev/metadata > /dev/null \
  && echo "BC is running" || echo "BC is NOT running"
```

### 1. Download symbols (first time only)

Run from `tests/al-language/`:

```bash
mkdir -p .alpackages
for app in "System" "System Application" "Application"; do
  curl -sf -u BCRUNNER:Admin123! \
    "http://localhost:7049/BC/dev/packages?publisher=Microsoft&appName=$(echo $app | sed 's/ /%20/g')&appVersion=0.0.0.0" \
    -o ".alpackages/${app}.app" && echo "Downloaded ${app}"
done
```

### 2. Compile

Run from `tests/al-language/`:

```bash
al-compile
```

Or directly with the AL compiler:
```bash
dotnet /path/to/alc/alc.dll /project:. /packagecachepath:.alpackages /out:ALLanguageCoverage.app
```

Compilation must produce zero errors. Warnings are allowed.

### 3. Publish

```bash
curl -sf -u BCRUNNER:Admin123! \
  -X POST \
  -F "file=@AL\ Language\ Coverage\ Tests_1.0.0.0.app;type=application/octet-stream" \
  "http://localhost:7049/BC/dev/apps?SchemaUpdateMode=forcesync" \
  && echo "Published OK"
```

Or using `bc-publish` (auto-detects credentials and server):
```bash
bc-publish
```

### 4. Run all tests

```bash
python3 run-bc-tests.py
```

Run a specific area (by codeunit ID range):
```bash
python3 run-bc-tests.py --ids "60000..60099"
```

Run a specific codeunit:
```bash
python3 run-bc-tests.py --ids "60010"
```

Workers default to 4 (parallel). Use `--workers 1` if tests share mutable data
or if you need ordered output:
```bash
python3 run-bc-tests.py --workers 1 --output results.json
```

### 5. Expected output

```
Connecting to BC...
Company ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Running 47 test codeunits with 4 workers...
  [1/47] PASS 60000
  [2/47] PASS 60001
  ...
  [47/47] PASS 60046

Results: 47 passed, 0 failed (of 47)
Saved to: results.json
```

Any failing test prints the method name and BC's error message:
```
  [12/47] FAIL 60010 (2 methods):
      Record_Insert_DuplicateKey_Throws: Assert.ExpectedError failed. Expected: already exists. Actual: ''
      Record_Get_NonExistentKey_ReturnsFalse: ...
```

### 6. Full cycle (compile → publish → run)

```bash
cd tests/al-language
al-compile && \
curl -sf -u "BCRUNNER:${BC_PASSWORD:-Admin123!}" \
  -X POST \
  -F "file=@AL\ Language\ Coverage\ Tests_1.0.0.0.app;type=application/octet-stream" \
  "http://${BC_SERVER:-localhost}:7049/BC/dev/apps?SchemaUpdateMode=forcesync" && \
python3 run-bc-tests.py
```

## Design Principles

### 1. One test = one thing
Each `[Test]` procedure covers exactly one method, one overload, or one behavioral
rule. If the test name does not tell you the complete scope, it is too broad.

Good: `Record_Insert_DuplicateKey_Throws`
Bad: `RecordTests`

### 2. Tests prove, not just execute
Every test must fail if the implementation is broken. Ask: would this test still pass
if the method always returned a default value (0, '', false)?  If yes, strengthen it.

Good: `Assert.AreEqual(3, Rec.Count(), '...')`
Bad: `Assert.IsTrue(Rec.FindFirst(), '...')` when you do not check the field values

### 3. No forced file separation
If the test needs a small helper procedure, it lives in the same file as the test.
Multi-object `.al` files are legal AL. Use them.

Only create a separate file when:
- The object is shared across more than one test area, OR
- The object is a fixture table / enum / interface from the shared fixture library

### 4. Minimal boilerplate
Every test uses shared fixture tables. No per-test table definitions.
`Initialize()` is a call to the shared cleanup codeunit — one line.
The test body is setup (2-5 lines) + act (1 line) + assert (1-2 lines).

### 5. Discoverable by name
A developer searching for "how does SetRange work with Date fields" must find the
test in under 10 seconds. Folder path + file name + procedure name together spell
out the complete claim.

Pattern: `tests/al-language/<area>/<type-or-feature>/Test<TypeName><Method>.al`
Procedure: `<Type>_<Method>_<Scenario>_<ExpectedOutcome>`

### 6. Documentation-anchored
Every test area has a doc-link comment pointing to the BC documentation page that
specifies the behavior being tested. If the BC docs change, the test must be reviewed.

---

## In-Scope Boundary

Derived from `docs/scope.md` in the runner repo. Tests are only written for features
the runner is designed to support. Out-of-scope features are explicitly listed so
agents do not write tests for them.

**In scope (test everything):**
- Record CRUD, filters, FlowFields, keys, triggers, locking, SystemId, RecordId
- RecordRef / FieldRef full API
- Codeunit instantiation, interfaces, events (subscribe/publish/bind)
- Error handling: Error(), asserterror, ErrorInfo, collected errors
- Text, TextBuilder, BigText
- JSON (JsonObject, JsonArray, JsonToken, JsonValue)
- XML (XmlDocument, XmlElement, XmlAttribute, XmlNamespaceManager)
- Query objects
- Streams (InStream, OutStream, Blob)
- Date/Time arithmetic and formatting
- Integer, Decimal, Boolean arithmetic and edge cases
- Guid, Variant, RecordId coercions
- List<T>, Dictionary<T,U>, Array
- Session functions: UserId, CompanyName, Today, CurrentDateTime, Format, Evaluate
- Database: Commit, IsEmpty, Count, LockTable (in-scope overloads)
- NavApp: GetCurrentModuleInfo, resource access
- Notification dispatch (handler-captured)
- Page handler dispatch (TestPage API — in-scope operations only)
- Report handler dispatch (RequestPage callback — no rendering)
- DataTransfer — out of scope outside upgrade/install context (test that it throws)

**Out of scope (do NOT write tests — write one negative test confirming it throws):**
- File.Upload / File.Download (browser round-trip)
- SMTP / email sending
- HttpClient (throws in runner; write one "blocks with error" test)
- OData / SOAP endpoints
- Background task scheduling / job queue execution
- Report rendering to PDF/Word
- Printing

---

## Fixture Library

All tests share a common set of objects defined in `_fixtures/`. These objects are
never modified by tests — tests insert/modify/delete data, not schema.

### Tables

| Object | Purpose |
|---|---|
| `ALT Universal` (50900) | All primitive field types on one table. Single integer PK. Covers filter, sort, validate, field metadata tests for every data type. |
| `ALT Composite` (50901) | 3-field composite PK: Integer + Code[20] + Integer. Covers multi-field Get, Rename, composite filter tests. |
| `ALT Triggered` (50902) | All five triggers (OnInsert, OnModify, OnDelete, OnRename, OnValidate on one field). Writes fired trigger name to `ALT Trigger Log`. |
| `ALT Trigger Log` (50903) | Side-car: records which trigger fired and with what values. Lets tests assert trigger sequence. |
| `ALT Parent` (50904) | Parent side of a FlowField pair. FlowFields: Count of children, Sum of child Amount, Lookup of first child Code. |
| `ALT Child` (50905) | Child side: FK to ALT Parent, Code[20] + Amount Decimal. |
| `ALT Keyed` (50906) | 3 secondary keys with different field combinations. Covers SetCurrentKey, key ordering, IsEmpty with filter. |
| `ALT Base` (50907) | Base table for table extension tests. Has 5 fields. |
| `ALT Extension` (table extension on 50907) | Adds 3 fields. Tests that extension fields participate in Get, filter, validate. |
| `ALT Blob` (50908) | Blob field + Code PK. Covers InStream/OutStream read-write, Blob.HasValue, export/import. |

### Enums

| Object | Purpose |
|---|---|
| `ALT Status` (50900) | 4-value enum (Draft, Active, Closed, Archived). Covers Enum.FromInteger, ordinal coercion, enum fields in filter/validate. |
| `ALT Color` (50901) | 3-value enum (Red, Green, Blue). Used in combination-filter tests. |

### Interfaces + Implementations

| Object | Purpose |
|---|---|
| `IALTCompute` | Interface with `Compute(X: Integer): Integer`. Two implementations: `ALTDouble` (returns 2×X) and `ALTSquare` (returns X²). Covers interface injection, typecheck, codeunit-as-variable. |

### Event Infrastructure

| Object | Purpose |
|---|---|
| `ALT Event Publisher` (50910) | Codeunit with 3 published events: `OnBeforeAction` (integration event), `OnAfterAction` (business event), `OnInternalStep` (internal event). Has `TriggerBefore`, `TriggerAfter`, `TriggerInternal` procedures that fire each. |
| `ALT Event Subscriber` (50911) | Default subscriber — records which codeunit-published events fired into `ALT Trigger Log`. Tests bind/unbind it explicitly. |
| `ALT Table Event Subscriber` (50912) | Subscriber fixture for `ALT Triggered` table-published events. Records `OnBeforeValidateEvent`, `OnAfterValidateEvent`, `OnBeforeInsertEvent`, `OnAfterInsertEvent`, `OnBeforeModifyEvent`, `OnAfterModifyEvent`, `OnBeforeDeleteEvent`, `OnAfterDeleteEvent`, `OnBeforeRenameEvent`, and `OnAfterRenameEvent` into `ALT Trigger Log`. |
| `ALT Internals Fanout Subscriber` (50913) | Additional subscribers for `ALT Internal Codeunit.OnValueComputed`. Used to prove integration-event fanout reaches multiple subscribers per publish. |
| `ALT Triggered Order Ext` (50914) | Tableextension fixture on `ALT Triggered`. Records tableextension field/table trigger order for `OnBeforeValidate`, `OnAfterValidate`, `OnBeforeInsert`, `OnInsert`, `OnAfterInsert`, `OnBeforeModify`, `OnModify`, `OnAfterModify`, `OnBeforeDelete`, `OnDelete`, `OnAfterDelete`, `OnBeforeRename`, `OnRename`, and `OnAfterRename`. |

### Pages

| Object | Purpose |
|---|---|
| `ALT List Page` (50900) | Minimal list page on ALT Universal. Covers page handler dispatch, TestPage navigation (FindFirst, Next), field access. |
| `ALT Card Page` (50901) | Card page on ALT Universal. Covers modal handler, action invocation dispatch. |

### Report

| Object | Purpose |
|---|---|
| `ALT Simple Report` (50900) | Single-dataitem report on ALT Universal. No rendering tested. Covers RequestPage handler dispatch, OnPreReport trigger, SaveAs (throws — out of scope). |

### Query

| Object | Purpose |
|---|---|
| `ALT Universal Query` (60022) | Query fixture over `ALT Universal`. Covers `Open()`, `Read()`, `Close()`, `SetFilter()`, `SetRange()`, `GetFilter()`, `GetFilters()`, `ColumnName()`, `ColumnCaption()`, `ColumnNo()`, `TopNumberOfRows()`, `SecurityFiltering()`, and the `SaveAs*` OutStream export surface. |

### XmlPort

| Object | Purpose |
|---|---|
| `ALT Universal XmlPort` (60023) | XmlPort fixture over `ALT Universal`. Covers instance `SetDestination()` + `Export()`, instance `SetSource()` + `Import()`, `SetTableView()`, and static `XmlPort.Export()` / `XmlPort.Import()` over streams. |
| `ALT Parent Child XmlPort` (60024) | Nested parent/child XmlPort fixture over `ALT Parent` and `ALT Child`. Covers multiple tableelements, LinkFields-based nesting, and `fieldattribute` import/export. |
| `ALT Variable XmlPort` (60025) | XmlPort fixture over `ALT Universal` with `textelement` and `textattribute` variables. Covers `OnBeforePassVariable()`, `OnAfterAssignVariable()`, and `OnAfterAssignField()`. |
| `ALT Universal Update XmlPort` (60026) | Partial import XmlPort over `ALT Universal`. Covers `AutoUpdate=true` semantics for preserving omitted fields. |
| `ALT Universal Replace XmlPort` (60027) | Partial import XmlPort over `ALT Universal`. Covers `AutoReplace=true` semantics for reinitializing omitted fields. |
| `ALT Universal Manual XmlPort` (60028) | Import XmlPort over `ALT Universal` with `AutoSave=false` and `AutoUpdate=true`. Covers manual persistence through `OnAfterInitRecord()`, `OnBeforeInsertRecord()`, `OnAfterInsertRecord()`, `OnBeforeModifyRecord()`, and `OnAfterModifyRecord()`. |
| `ALT Temp Universal XmlPort` (60029) | Import XmlPort over `ALT Universal` with `UseTemporary=true`. Covers temporary import buffering with manual persistence into real records. |

---

## Folder Structure

```
tests/al-language/
  PLAN.md                          ← this file
  app.json                         ← standalone AL package, id-range 60000..60999
  run-bc-tests.py                  ← same runner script as bucket-1
  _fixtures/
    tables/
      ALTUniversal.al
      ALTComposite.al
      ALTTriggered.al
      ALTTriggerLog.al
      ALTParentChild.al            ← ALT Parent + ALT Child in one file
      ALTKeyed.al
      ALTBase.al                   ← ALT Base + ALT Extension (tableextension) in one file
      ALTBlob.al
    enums/
      ALTStatus.al
      ALTColor.al
    interfaces/
      IALTCompute.al               ← interface + both implementations in one file
    events/
      ALTEventPublisher.al
      ALTEventSubscriber.al
    pages/
      ALTListPage.al
      ALTCardPage.al
    reports/
      ALTSimpleReport.al
    queries/
      ALTUniversalQuery.al
    xmlports/
      ALTUniversalXmlPort.al
      ALTParentChildXmlPort.al
      ALTVariableXmlPort.al
      ALTUniversalUpdateXmlPort.al
      ALTUniversalReplaceXmlPort.al
      ALTUniversalManualXmlPort.al
      ALTUniversalTemporaryXmlPort.al
    ALTFixtureCleanup.al           ← codeunit with DeleteAll on every fixture table
  record/
    TestRecordInsert.al
    TestRecordModify.al
    TestRecordDelete.al
    TestRecordGet.al
    TestRecordFind.al
    TestRecordFilter.al
    TestRecordSort.al
    TestRecordRename.al
    TestRecordFlowField.al
    TestRecordTriggers.al
    TestRecordLock.al
    TestRecordSystemId.al
    TestRecordRecordId.al
    TestRecordCount.al
    TestRecordTransferFields.al
    TestRecordValidate.al
    TestRecordTestField.al
  recordref/
    TestRecordRefOpen.al
    TestRecordRefCRUD.al
    TestRecordRefFilter.al
    TestRecordRefField.al
    TestRecordRefKeys.al
    TestRecordRefGetSet.al
  fieldref/
    TestFieldRefValue.al
    TestFieldRefValidate.al
    TestFieldRefFilter.al
    TestFieldRefMetadata.al
    TestFieldRefFieldError.al
  codeunit/
    TestCodeunitInstantiation.al
    TestCodeunitInterface.al
    TestCodeunitEvents.al
    TestCodeunitSubscriber.al
    TestCodeunitErrorPropagation.al
  error-handling/
    TestAssertError.al
    TestErrorInfo.al
    TestCollectedErrors.al
    TestGetLastError.al
  text/
    TestTextOperations.al
    TestTextBuilder.al
    TestBigText.al
    TestFormat.al
    TestEvaluate.al
  collections/
    TestList.al
    TestDictionary.al
    TestArray.al
  types/
    TestVariant.al
    TestGuid.al
    TestEnum.al
    TestOption.al
    TestDate.al
    TestDecimal.al
    TestBoolean.al
  json/
    TestJsonObject.al
    TestJsonArray.al
    TestJsonToken.al
    TestJsonValue.al
  query/
    TestQueryObject.al
  xmlport/
    TestXmlPortObject.al
    TestXmlPortAdvanced.al
  xml/
    TestXmlDocument.al
    TestXmlElement.al
    TestXmlNamespace.al
  streams/
    TestInOutStream.al
    TestBlob.al
  session/
    TestSessionFunctions.al
    TestDatabase.al
    TestNavApp.al
  handlers/
    TestNotificationHandler.al
    TestPageHandler.al
    TestReportHandler.al
    TestMessageHandler.al
  out-of-scope/
    TestOutOfScopeConfirmed.al    ← one test per OOS surface confirming it throws
```

---

## Naming Conventions

### Files
`Test<TypeName><Aspect>.al` — e.g., `TestRecordInsert.al`, `TestJsonObject.al`

### Procedures
`<Type>_<Method>_<Scenario>_<ExpectedOutcome>`

Examples:
- `Record_Insert_DuplicateKey_Throws`
- `Record_SetRange_DateField_FiltersCorrectly`
- `Record_Get_NonExistentKey_ReturnsFalse`
- `RecordRef_Field_UnboundRef_Throws`
- `JsonObject_Get_MissingKey_ReturnsFalse`
- `Enum_FromInteger_OutOfRange_ReturnsOrdinal`

The full claim is readable from the procedure name alone without opening the body.

### Doc-link comment
Each test file opens with a comment block:

```al
// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/
//   dev-itpro/developer/methods-auto/record/record-insert-method
// Scope: in-scope (runner supports Record.Insert)
// Fixtures used: ALT Universal, ALT Triggered
```

---

## Version Compatibility

The CI matrix runs the suite against BC 27.5 and BC 28.1. All tests must
pass on both versions by default.

For features introduced after BC 27.0, wrap the test in a preprocessor guard:

```al
#if BC28PLUS  // <brief reason why this guard exists>
[Test]
procedure SomeNewFeature_Works()
begin
    ...
end;
#endif
```

The symbols `BC27PLUS` and `BC28PLUS` are defined by the CI workflow per
matrix version. When compiling locally, define them in `app.json`:

```json
"preprocessorSymbols": ["BC27PLUS", "BC28PLUS"]
```

---

## How to Add a New Test

1. Identify the method and overload from `al-surface-inscope.json` (generated by scraper).
2. Pick the correct test file (or create one following naming conventions).
3. Write `Initialize();` as the first line.
4. Write setup in 2-5 lines using fixture tables.
5. Call the method under test.
6. Assert a specific, non-default value.
7. Run against BC container. Must pass.

---

## Build Workflow

### Phase 1 — Surface manifest (scripted)
`scripts/scrape-al-surface.py`:
- Crawls `learn.microsoft.com/.../methods-auto/library` and all linked subpages
- Extracts: type → method → overloads → parameters → return type
- Outputs `al-surface.json`

`scripts/filter-inscope.py`:
- Reads `al-surface.json` + `docs/scope.md`
- Outputs `al-surface-inscope.json` with in-scope/out-of-scope annotation

`scripts/coverage-gap.py`:
- Reads `al-surface-inscope.json`
- Greps existing test files for method name references
- Outputs `coverage-gap.md`: method → covered / not covered

### Phase 2 — Fixture library (human + agent)
Design and write the fixture objects in `_fixtures/`. This is done once.
Every subsequent phase depends on these being stable and correct.

### Phase 3 — Stub generation (scripted)
`scripts/generate-stubs.py`:
- Reads `al-surface-inscope.json`
- For each uncovered in-scope method, emits a stub test procedure:
  ```al
  [Test]
  procedure Record_Insert_DuplicateKey_Throws()
  // STUB — https://learn.microsoft.com/.../record-insert-method
  // TODO: fill in proving assertions
  begin
      Initialize();
      Assert.IsTrue(false, 'STUB — not implemented');
  end;
  ```
- Places stub in the correct file under the correct area folder
- Every stub fails by construction until filled

### Phase 4 — Fill stubs (Haiku agents, batched by area)
Each agent receives:
- The stub procedure(s) for one area (e.g., all Record.Insert overloads)
- The BC doc page for that method
- The fixture table definitions it can use
- 3 example filled tests from an adjacent area
- The rule: "would this test still pass if the method always returned a default value? If yes, rewrite."

Agent output: filled `.al` file. Compile + BC run after each batch.

### Phase 5 — Validate and lock
- All tests pass against BC container → suite is locked
- Suite is added to `docs/coverage.yaml` in the runner repo
- Any future runner work that touches a method in `al-surface-inscope.json` must
  also have a corresponding passing test in this suite

---

## What "Done" Looks Like

- `al-surface-inscope.json` exists and covers all in-scope types + methods
- Every in-scope method has at least one positive test and one negative test
- All tests pass against the BC 16.x container
- `coverage-gap.md` shows 0 uncovered in-scope methods
- Any agent can search for `Record_SetRange` and find the test in under 5 seconds
- Any agent can add a new test by following this document without asking questions
