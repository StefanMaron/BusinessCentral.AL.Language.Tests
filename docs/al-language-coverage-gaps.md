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
- `Init()` populating the instance, being repeatable, and overwriting values assigned beforehand
- `RequestSessionUpdate(false)` routing through a `[SessionSettingsHandler]`: the handler is
  invoked exactly once, receives the assigned settings, leaves the instance intact, and does
  not change the running session's language
- `Format()` on a settings object, and `Assert.AreEqual` value-comparison through it
- `Clear()` returning an instance to its pristine state

Notes:

- `RequestSessionUpdate(true)` is deliberately not covered: it persists to table 2000000073
  "User Personalization", a durable side effect on the shared test tenant that would make the
  `Init()` tests order-dependent. Covering it needs a fixture that restores the row afterwards.
- Unlike `SecretText`, this type DOES convert to `Variant` and DOES support `Format()`, so its
  compile-time refusal surface is much smaller -- only `=` is rejected (`AL0175`). The file
  header records the measurements.
- Two behaviors were measured on real BC and are NOT what the docs suggest, so the tests are
  shaped around them: `Init()` leaves `Company` **empty** on BC 27.5 (cloud) while populating
  it on 28.0-28.4, so no assertion pins a company value after `Init()`; and
  `RequestSessionUpdate()` is a genuine UI interaction that fails with
  "Unhandled UI: SessionSettings" unless a `[SessionSettingsHandler]` is declared. That single
  method is the only part of the type the "UI-level" label fits.

### 5. WebServiceActionContext

Status: implemented for the whole method surface (`session/TestWebServiceActionContext.al`, codeunit 60278).

Why it matters:

- It was the last entry in this document with no test file at all.
- All 7 documented members are get/set pairs plus one collection-add on an in-memory object,
  so the entire type is observable from a plain `[Test]` with no web service request in
  flight. `scripts/al-surface-inscope.json` marks all 7 "out-of-scope"; that label classifies
  by the type's name rather than by what the members do, and is wrong in the same way it was
  wrong for `SecretText` and `SessionSettings`.

Current coverage:

- defaults on a fresh instance: object id `0`, result code `None`, and an object type that is
  none of the seven members AL can name
- round-tripping, last-write-wins and mutual independence of `SetObjectId()`/`GetObjectId()`
  and `SetObjectType()`/`GetObjectType()`
- `SetObjectId()` storing an out-of-range (negative) id without validating it
- `SetResultCode()`/`GetResultCode()` round-tripping `None`, `Get`, `Created` and `Deleted`
- the `Get`/`Updated` collision -- both are valued 200, so `SetResultCode(Updated)` reads back
  as `Get` -- asserted in three ways, plus the negative case that `Created` and `Deleted`
  stay distinguishable
- `AddEntityKey()` accepting distinct field ids and value types, and obeying the trappable-
  return convention: `false` for a duplicate field id when the return value is captured, a
  catchable error naming the type when it is not
- `Clear()` resetting the scalar properties **and** emptying the entity keys
- assignment sharing the underlying context -- the opposite of `SessionSettings`
- `Format()` on the result code, and one-directional conversion to `Variant`

Notes:

- `WebServiceActionResultCode` declares five members over four values (`None = 0`, `Get = 200`,
  `Created = 201`, `Updated = 200`, `Deleted = 204`) and the platform round-trips the code by
  NAME through a second, separately-declared enum, so the 200-valued pair collapses onto the
  first-declared name. This is the single most surprising thing about the type and the reason
  the file is worth having.
- The default object type CANNOT be named in AL. `ObjectType` exposes exactly seven members
  (`Table`, `Page`, `Report`, `Codeunit`, `XmlPort`, `Query`, `MenuSuite`), while the platform
  enum behind it starts at `TableData = 0`. Two tests therefore state the default relatively --
  it differs from all seven, and `Clear()` restores it -- rather than pinning a name.
- **A `WebServiceActionResultCode` cannot be passed to a `Variant` parameter on a real BC
  server, and `alc` does not catch it.** `Assert.AreEqual(WebServiceActionResultCode::Created,
  ...)` compiles cleanly, then the codeunit fails to LOAD, because the server's per-object C#
  codegen emits `error CS1503: cannot convert from ... WebServiceActionResultCode to ...
  NavValue`. `NavValue` is the runtime's boxed-value base — `NavWebServiceActionContext`
  derives from it and boxes fine, `NavWebServiceActionResultCode` (a `NavEnumBase`) does not.
  This was found only by running against a service tier: the first revision of the suite
  produced 71 instances of that one error, BC reported "C# compilation has failed for the
  application object CodeUnit_60278", and **none of the tests ran on any of the 16 legs** while
  all 2639 other tests passed. Every result-code assertion therefore compares `Format(...)`.
- `=` is refused on both `WebServiceActionContext` and `WebServiceActionResultCode` (`AL0175`),
  and `AsInteger()` does not exist on the result code (`AL0132`). With the `Variant` path also
  unusable, `Format()` is the **only** way AL can compare two result codes. Conversion to
  `Variant` works for the context itself; conversion back is `AL0122`. The file header records
  all of these with their error codes.
- Deliberately not covered: the OData side of the contract -- that a real API page action
  returning this context makes the platform emit the corresponding HTTP status and redirect.
  That needs a web service request against a published API page, outside what a `[Test]`
  codeunit can provoke.

### 6. FilterPageBuilder

Status: implemented for everything except `RunModal()` (`filterpage/TestFilterPageBuilder.al`,
codeunit 60279).

Why it matters:

- It had no test file and no mention in this document, while carrying a documented 12-member
  surface -- the largest completely unmeasured type left in the suite.
- Eleven of the twelve members are plain object-graph operations over an ordered dictionary of
  `RecordRef`s. A client is only needed for `RunModal()`, the point at which the accumulated
  controls are finally shown. `scripts/al-surface-inscope.json` marks all 12 "out-of-scope",
  classifying by the type's name on the assumption that anything ending in "PageBuilder" is UI;
  that is wrong in the same way it was wrong for `SecretText`, `SessionSettings` and
  `WebServiceActionContext`.

Current coverage:

- `AddTable()`, `AddRecord()` and `AddRecordRef()` returning the control name, and distinct
  names accumulating
- name-keyed identity: re-adding a name against the same table is idempotent (`Count()` stays
  at 1), and re-adding it against a *different* table is a redefinition error
- argument validation: a table id below 1 is refused
- the trappable-return convention on `AddTable` and `SetView` -- empty string / `false` when the
  return value is captured, a catchable error when it is discarded -- asserted in both
  directions for both methods
- `AddField()` returning `true` for a known control and `false` for an unknown one, and its
  optional default-filter argument reaching the view (with the no-filter negative)
- `SetView()` / `GetView()` round-tripping a filter, and their asymmetry on an unknown control
  name: `GetView` returns empty, `SetView` errors
- `GetView(name, false)` rendering an option filter as its ordinal and `GetView(name, true)` as
  its member name
- `Name()` being 1-based and in insertion order, with both range ends erroring
- `PageCaption()` returning a non-empty platform default when unset, an assigned caption
  replacing it, and last-write-wins
- assignment being a deep copy: `Count()`, pre-existing views and post-assignment writes are all
  independent in both directions
- `Clear()` emptying the controls and allowing a cleared name to be reused
- `Format()` and round-tripping through a `Variant`

Notes:

- **`AddField(Name, FieldNo: Integer)` is not callable from AL.** Microsoft Learn documents it
  as `filterpagebuilder-addfieldno-method`, but only the `FieldRef` overload is exposed --
  passing an Integer is `AL0133`. Every `AddField` test therefore goes through a
  `RecordRef`/`FieldRef` pair. `GetView(Index: Integer)` likewise does not exist; controls are
  addressed by name, and `Name(Index)` is the bridge between the two.
- **`Name()` is the one method whose return value is mandatory** (`AL0192` if discarded), which
  is why its two range tests assign into a variable inside `asserterror`. `AddTable`,
  `AddField` and `SetView` all compile with theirs discarded -- which is exactly what makes
  their trappable-return behavior testable.
- **`Clear()` does NOT reset the page caption.** "Clear resets the whole object" is the obvious
  reading and it is wrong: the caption is not part of the control collection `Clear()` walks, so
  a cleared builder reports `Count() = 0` while still returning the caption it was assigned. The
  test asserts both halves together, because an implementation that reset everything would pass
  every other `Clear` test in the file.
- **Assignment is a deep copy**, the opposite of `WebServiceActionContext`, whose assignment
  shares the underlying object. The two files together establish that AL's `:=` on a complex
  type is per-type behavior rather than one uniform rule.
- `=` is refused on the type (`AL0175`), but `Format()` and conversion to a `Variant` *and back*
  all work -- a wider surface than either `SecretText` or `WebServiceActionResultCode`.
- Deliberately not covered: `RunModal()`. It is the one genuinely UI-level member; covering it
  needs a handler fixture and is a separate suite.

### 7. Additional platform/system surfaces

Status: partial or thin coverage.

Candidate areas:

- `Media` and `MediaSet`
- `TaskScheduler`
- `ModuleInfo` / related app metadata

These are lower priority than `Query` because the current suite is already strong on the most commonly used runtime behaviors.

Still entirely unmeasured, and the natural next picks after `FilterPageBuilder`: `ProductName`
(3 members, trivially observable). `Cookie` and `Debugger` are genuinely unreachable here --
`Cookie` is only obtainable from an `HttpResponseMessage`, and the whole HTTP surface is out of
scope; `Debugger` needs a debugging session attached to the tenant.

## Query Coverage Target

The baseline query object surface is now covered for cloud-safe execution.

Remaining query-specific follow-up is narrower:

1. Add a grouped/aggregate query fixture if we want to document totals and grouping behavior.
2. Decide whether file-name export overloads need separate documentation-only notes beyond the current compile-surface note.

## Working Rule

Any item added here should be grounded in a Microsoft Learn page and mapped to a concrete AL test file or fixture object before implementation starts.
