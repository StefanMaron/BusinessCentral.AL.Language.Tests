# AL Language Coverage Gaps

> Working backlog for the AL language coverage suite. This document tracks what is already covered, what is intentionally out of scope, and what should be added next.

## Purpose

This repository is an executable specification for AL language behavior in BC Cloud. The gap list below is the working document for expanding coverage without drifting away from that goal.

## Source References

- Microsoft Learn AL reference overview: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/
- Microsoft Learn data types and methods: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/library
- Microsoft Learn Query data type: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/query-data-type
- Microsoft Learn Query object: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object

## Current Coverage Shape

Already covered well:

- `Record`, `RecordRef`, and `FieldRef`
- `Codeunit`, interfaces, and events
- `JSON`, `XML`, `Text`, `Streams`, and primitive `types`
- Session, database, and handler behavior that is observable in BC Cloud

Intentionally out of scope:

- `File.*`, `File.Upload`, `File.Download`
- `HttpClient`
- SMTP and mail sending
- OData / SOAP calls from AL
- Background task scheduling and job queue execution
- Report rendering to PDF, Word, or Excel
- Printing
- `.NET` interop

## Priority Gaps

### 1. Query objects

Status: implemented for the cloud-safe surface.

Why it matters:

- Microsoft documents `Query` as a first-class AL surface.
- Query objects are a natural fit for BC Cloud behavior proofs because they can be executed, filtered, and read without rendering.

Current coverage:

- `Open()`, `Read()`, `Close()`
- `SetFilter()`, `SetRange()`, `GetFilter()`, `GetFilters()`
- `ColumnName()`, `ColumnCaption()`, `ColumnNo()`
- `TopNumberOfRows()`
- `SecurityFiltering()`
- `SaveAsCsv()`, `SaveAsJson()`, `SaveAsXml()` through `OutStream`
- static `Query.SaveAsCsv(Integer, OutStream)`, `Query.SaveAsJson(Integer, OutStream)`, and `Query.SaveAsXml(Integer, OutStream)`

Notes:

- The file-name export overloads documented on Microsoft Learn are on-premises oriented and are not part of the cloud-targeted compile surface exercised by this repository configuration.
- Aggregate query behavior still needs separate fixture coverage if we want to document totals/grouping semantics beyond row iteration.

### 2. XmlPort objects

Status: broad baseline implemented; some specialized method/property coverage still pending.

Why it matters:

- Microsoft documents `XmlPort` separately from `XML` data types.
- The suite now covers the cloud-safe import/export object model rather than only raw XML document manipulation.

Current coverage:

- instance `SetDestination()` + `Export()`
- instance `SetSource()` + `Import()`
- `SetTableView()` for filtered export
- static `XmlPort.Export(Integer, OutStream [, Record])`
- static `XmlPort.Import(Integer, InStream)`
- nested `tableelement` trees with parent/child `LinkFields`
- `fieldattribute`, `textelement`, and `textattribute` nodes
- `OnBeforePassVariable()`, `OnAfterAssignVariable()`, and `OnAfterAssignField()`
- `AutoUpdate=true`
- `AutoReplace=true`
- `AutoSave=false` with manual insert/modify in record triggers
- `UseTemporary=true` with manual persistence from temporary rows

Notes:

- The current slice is still intentionally stream-based. File-name and request-page driven execution paths are less useful for the repo’s cloud-safe runtime focus.
- `Break()`, `BreakUnbound()`, `CurrentPath()`, `Skip()`, `OnPreXmlPort()` / `OnPostXmlPort()`, and text/fixed-width separator methods still need dedicated fixtures if we want full method-surface coverage.

### 3. SecretText

Status: implemented for the cloud-safe surface (`types/TestSecretText.al`, codeunit 60275).

Why it matters:

- `SecretText` is a distinct AL data type with security-sensitive behavior.
- It deserves a dedicated coverage slice rather than being folded into generic text tests.

Current coverage:

- construction through `SecretStrSubstNo()` -- template only, template from a `Text` variable,
  and substitution of one or several `SecretText` arguments
- `IsEmpty()` in both directions, including across reassignment
- assignment from a `Text` variable, and secret-to-secret copying in both directions
- round-tripping through `List of [SecretText]` and `Dictionary of [Text, SecretText]`

Notes:

- The rest of the type's contract is enforced by the AL compiler, not at runtime, so it cannot
  be expressed as a `[Test]`. Measured against this app's `Cloud` target: `Format(SecretText)`
  and `Message(Format(...))` are `AL0133`, assignment to a `Variant` is `AL0122`,
  `Assert.AreEqual` on two secrets is `AL0133`, `=` on two secrets is `AL0175`, and
  `Unwrap()` is `AL0296` (scope `OnPrem`). Those are recorded in the file's header comment.
- `Secret := 'literal'` does not compile (`AL0122`) while `Secret := SomeTextVariable` does --
  an asymmetry worth knowing before writing further `SecretText` tests.
- `SecretText` on `HttpClient` / `HttpHeaders` / `HttpContent` remains out of scope with the
  rest of the HTTP surface.

### 4. SessionSettings

Status: implemented for the cloud-safe surface (`session/TestSessionSettings.al`, codeunit 60277).

Why it matters:

- `SessionSettings` is a first-class AL data type with a documented 9-method surface, and
  nothing in the suite referenced it before this file.
- Every accessor is an in-memory get/set pair, so the whole type is observable from a test
  without a client attached -- despite `scripts/filter-inscope.py` marking it "UI-level, not
  testable". That classification is wrong and its own `al-surface-inscope.json` disagrees,
  still listing all 9 members.

Current coverage:

- round-tripping and mutual independence of `Company()`, `LanguageId()`, `LocaleId()`,
  `TimeZone()`, `ProfileId()` and `ProfileAppId()`
- `ProfileSystemScope()` discarding its argument -- deprecated, always tenant scope
- assignment being a by-value copy, so mutating the copy leaves the original alone
- `Init()` populating the instance, and overwriting values assigned beforehand
- `RequestSessionUpdate(false)` being callable from a test and not altering the running session
- `Format()` on a settings object, and `Assert.AreEqual` value-comparison through it
- `Clear()` returning an instance to its pristine state

Notes:

- `RequestSessionUpdate(true)` is deliberately not covered: it persists to table 2000000073
  "User Personalization", a durable side effect on the shared test tenant that would make the
  `Init()` tests order-dependent. Covering it needs a fixture that restores the row afterwards.
- Unlike `SecretText`, this type DOES convert to `Variant` and DOES support `Format()`, so its
  compile-time refusal surface is much smaller -- only `=` is rejected (`AL0175`). The file
  header records the measurements.

### 5. Additional platform/system surfaces

Status: partial or thin coverage.

Candidate areas:

- `Media` and `MediaSet`
- `TaskScheduler`
- `ModuleInfo` / related app metadata
- `WebServiceActionContext` -- no test file at all; the least-covered remaining candidate

These are lower priority than `Query` because the current suite is already strong on the most commonly used runtime behaviors.

## Query Coverage Target

The baseline query object surface is now covered for cloud-safe execution.

Remaining query-specific follow-up is narrower:

1. Add a grouped/aggregate query fixture if we want to document totals and grouping behavior.
2. Decide whether file-name export overloads need separate documentation-only notes beyond the current compile-surface note.

## Working Rule

Any item added here should be grounded in a Microsoft Learn page and mapped to a concrete AL test file or fixture object before implementation starts.
