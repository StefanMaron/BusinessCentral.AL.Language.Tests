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
- argument validation: a table id below 1 is refused, with the exact platform message asserted
- the trappable-return convention on `AddTable` and `SetView` -- empty string / `false` when the
  return value is captured, a catchable error when it is discarded -- asserted in both
  directions for both methods
- `AddField()` returning `true` for a known control and `false` for an unknown one, and its
  optional default-filter argument reaching the view (with the no-filter negative)
- `SetView()` / `GetView()` round-tripping a filter, and their asymmetry on an unknown control
  name: `GetView` returns empty, `SetView` errors
- `GetView(name, false)` rendering an option filter as its ordinal and `GetView(name, true)` as
  its member name
- `Name()` being 1-based and in insertion order, with both range ends erroring; the range
  message names both bounds, so asserting it in full independently restates the 1..`Count()`
  range
- `PageCaption()` returning a non-empty platform default when unset, an assigned caption
  replacing it, and last-write-wins
- assignment being **split**: the control collection is copied (`Count()` is independent) while
  the record behind each control is shared (a view written through either builder is visible
  from both)
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
- **Assignment is neither a deep copy nor a shared reference -- it is split**, and this is the
  most surprising thing about the type. The control collection is copied, so adding a control to
  the copy leaves the original's `Count()` alone; the `NavRecordRef` each control wraps is
  shared, so a view written through either builder is visible from both. An earlier revision of
  the test file asserted a full deep copy and all 8 cloud legs falsified it identically on every
  version. The mechanism is `NavRecordRef.Clone` in `Microsoft.Dynamics.Nav.Ncl.dll`: it builds
  a fresh wrapper and copies `Target` **by reference**. Compare `WebServiceActionContext`, whose
  assignment shares outright -- together the two files establish that AL's `:=` on a complex
  type is per-type behavior, and can even be per-*field* within one type.
- `=` is refused on the type (`AL0175`), but `Format()` and conversion to a `Variant` *and back*
  all work -- a wider surface than either `SecretText` or `WebServiceActionResultCode`.
- Deliberately not covered: `RunModal()`. It is the one genuinely UI-level member; covering it
  needs a handler fixture and is a separate suite.

### 7. TestPart

Status: implemented for the whole reachable surface (`testpart/TestTestPart.al`, codeunit 60346).

Why it matters:

- It carried a documented 20-member surface with **17 members entirely unmeasured**. The
  other three (`First`, `New`, `Next`) were used incidentally by other suites as a way to
  reach rows while testing something else -- never asserted as claims about `TestPart`.
- It is the type a test gets whenever it reaches a `part()` control through an open
  `TestPage`, so a great deal of this repository's existing page coverage runs *through* it
  while never measuring it.
- `scripts/al-surface-inscope.json` marks all 20 members "test-only". That label is **accurate
  here**, unlike the four preceding suites where it was wrong -- `TestPart` genuinely only
  exists inside a test. What it does not mean is "unreachable": a `[Test]` codeunit is exactly
  the context the type is for.

Current coverage:

- `Visible()` and `Enabled()` answering true for a reachable part, plus the finding that makes
  the obvious pair impossible: a part declared `Visible = false` is **not in the test page's
  control tree at all**, so reaching it errors rather than yielding a handle that reports false
- `Editable()` **not** following the host part control's `Editable` property -- two controls
  over the same part page agree despite differing in it
- `Caption()` answering the **part page's** caption rather than the host's or the hosting
  control's override, measured across two hosts
- `First()` / `Next()` / `Last()` / `Previous()` walking the part's own rowset in key order,
  with the empty-part arm, and the **asymmetry of the two ends**: `Previous()` before the first
  row answers false, while `Next()` past the last *data* row answers **true**, stepping onto an
  editable repeater's trailing blank new-row line
- `GoToKey()` on a **composite** primary key: positioning, the trappable-return convention in
  both directions, and the arity check
- `GoToRecord()` positioning from a `Record` variable
- `GetField()` refusing a **table field number**: its argument is a page **control** id
- `FindFirstField()` / `FindNextField()` / `FindPreviousField()` over two rows that
  deliberately share a value, plus the not-found arm
- `ValidationErrorCount()` and `GetValidationError()` against a real AL validation error
  raised by the fixture table's own `OnValidate`, including the 1-based index and its range check
- `New()` adding a row that persists to the part's own source table

Notes:

- **`Prev()` is a documented member that no longer exists.** `scripts/al-surface.json` lists
  `Prev` and `Previous` side by side, and Microsoft Learn still publishes
  `testpart-prev-method`, but this app targets runtime 16.0 and `alc` refuses the call with
  `error AL0666`: supported `3.0` until, but not including, `13.0`. So one of the twenty
  members is unreachable, and the obvious claim about the pair -- that the two are spellings
  of one operation -- is not expressible here. Every backward walk uses `Previous()`.
- **`GetField(Id)` compiles but is deprecated** (`warning AL0667`, runtime `3.0` or greater).
  It is covered because it is still callable; when that warning becomes an error the file will
  need the same treatment `Prev` just got.
- **`TestPart` is not a declarable variable type** -- `var P: TestPart` is `error AL0134`. A
  part handle exists *only* as the member access `Host.PartName`, so unlike
  `FilterPageBuilder` and `WebServiceActionContext` there is no assignment-semantics question
  to ask about it. Relatedly, `=` on two part handles is `AL0175` and the message names the
  two **control** types (`'Lines'` and `'ReadOnlyLines'`), not `TestPart` -- each part control
  on a host is its own generated type.
- The fixture table's primary key is deliberately **composite**. Every other part fixture in
  this repository keys on a single field, where a one-value `GoToKey` is correct and the arity
  check is invisible.
- **A real service tier falsified five of this file's first-revision assertions, identically
  on all 8 cloud legs**, and each correction is a sharper fact than the assertion it replaced.
  Reading `Ncl.dll` alone would have got three of them wrong: `NavTestPart` really does
  override `ALVisible`/`ALEnabled` to read the part control's own metadata, but AL cannot
  reach a control on which either would answer false, so the override is not observable from
  AL. The others: `Editable` on the host control does not propagate; `GetField` keys on
  control ids, not table field numbers.
- **`Expand()` and `IsExpanded()` are not coverable from AL at all**, and it took three
  tier-decided revisions to establish why. Rev 1 asserted `IsExpanded()` tracks the last
  `Expand()` and failed from `BindingManager.CollapseRow`. Rev 2 read that as "a flat ListPart
  cannot expand", asserted the refusal -- and *also* added a `First()`, changing two variables
  at once; it failed with "An error was expected inside an ASSERTERROR statement", so with the
  cursor on a data row `Expand(true)` succeeds and the rev-1 refusal came from the
  `Expand(false)` after it. Rev 3 asserted exactly that and failed again with the **same**
  `InvalidOperationException`, now reported from *inside* the `asserterror` body
  (`NavMethodScope.AssertErrorAsync` in the callstack).
  That is the answer: **`asserterror` traps AL errors, not a raw CLR exception surfacing from
  the client proxy.** The refusal is real and reproducible on all 8 legs, and no AL construct
  can observe it. A tree-view fixture would not help -- the obstacle is the exception boundary,
  not the control shape.

### 8. TestFilter

Status: implemented for the whole surface (`testfilter/TestTestFilter.al`, codeunit 60350).

Why it matters:

- Four of its five members -- `Ascending()`, `CurrentKey()`, `GetFilter()`, `SetCurrentKey()` --
  had **zero** occurrences anywhere in the suite. The fifth, `SetFilter()`, had nine, and every
  one was **incidental**: it arranged a rowset while some other claim was tested (page cursor
  position, new-row defaults, `SourceTableView` interaction). Not one of the nine read a filter
  back.
- It is the only route by which an AL test can change **which rows** an open page has and **in
  what order** it walks them, so a great deal of this repository's page coverage depends on it
  behaving as assumed, while nothing checked that it does.

Current coverage:

- `SetFilter`/`GetFilter` round-tripping a **range** expression, with the unfiltered-field arm
  reading back empty
- the filter restricting the actual **rowset**, not merely what `GetFilter` reports
- a field with **no control on the page** still being filterable, and really restricting
- `SetFilter` **replacing** per field but **combining** across fields, asserted as a pair
- `CurrentKey()` naming the key being walked, and not naming a field of a key it is not walking
- `SetCurrentKey()` changing both the reported key and the observed row order
- `SetCurrentKey` accepting a **composite** key, asserted to name both fields
- `Ascending()` defaulting true; `Ascending(false)` reversing the walk, being reported back, and
  restoring on `Ascending(true)`
- the direction applying to the key `SetCurrentKey` installed, not to the primary key
- a **part** carrying its own `Filter`, independent of a sibling part over the same table

Notes:

- **TestFilter's field argument resolves against the SOURCE TABLE, not the page's controls**, and
  this is the file's central finding. It is the exact opposite of `TestPart`/`TestPage.GetField(Id)`,
  whose argument is a page **control** id and which refuses a table field number. The fixture page
  names its control over `"Entry No."` as `EntryNo`, so the namespaces are distinguishable:
  `Filter.GetFilter(EntryNo)` is `AL0118` while `Filter.GetFilter("Entry No.")` compiles. The sharp
  end is the fixture's `OffPage` field, which carries **no control on the page at all** and is
  still a valid filter target -- and filtering it really does restrict the rowset. `Ncl.dll`
  explains why: `NavTestFilter.ALGetFilter`/`ALSetFilter` take a plain `int fieldNo`, and
  `NavTestFilter` carries `GetFieldName(int) => fieldNo.ToString()` -- the runtime type never had a
  control name to work with.
- **`Ncl.dll` fixed the AL boundary and settled none of the semantics.** `NavTestFilter` is a thin
  wrapper over an `ITestFilter`, and that interface is **not in `Ncl.dll`** -- it lives client-side.
  So the runtime assembly answered "the argument is a field number", "`SetFilter` is void" and
  "`SetCurrentKey`'s trapping overload catches `NavClientPageAbortException`", and answered nothing
  about whether a filter replaces or accumulates, what `CurrentKey`'s string looks like, or whether
  `Ascending` reorders an already-open page. Every one of those was decided by the service tier.
- **`var F: TestFilter` is `AL0134`**, exactly as for `TestPart`: the handle exists only as
  `Page.Filter`. So the assignment-semantics question that `FilterPageBuilder` (split copy) and
  `WebServiceActionContext` (shared reference) each answered is **inexpressible** here.
- **`SetFilter` has no return value** (`AL0122` on capture), so unlike `FilterPageBuilder.SetView`
  and `TestPart.GoToKey` there is no trappable-return convention to test on it. `CurrentKey`'s
  return is mandatory (`AL0192`), and `SetCurrentKey` requires at least one field (`AL0135`).
- **The `AL0135` message is misleading about arity.** It renders the signature as
  `SetCurrentKey(TestFilterField, [TestFilterField])`, which reads as "at most two fields". Three
  fields compile; the message renders only the first optional parameter of a variadic list, and
  `Ncl.dll` confirms `params int[] fields`. Not asserted, because the fixture declares no
  three-field key to observe.
- **Every test opens the list with `OpenView()`, not `OpenEdit()`, and that is load-bearing.** The
  `TestPart` suite established that an editable repeater carries a trailing blank new-row line that
  `Next()` steps onto answering true; walking such a page would append an empty entry to every
  order sequence the file builds. For the same reason the part test proves an excluded row is gone
  with `GoToKey` rather than `IsFalse(Next())`.
- Unusually for this series, **the tier falsified nothing** -- all 8 cloud legs passed on the first
  revision. The compiler did the falsifying instead, and did a lot of it: the control-name/table-
  field question, the missing `SetFilter` return, the mandatory `CurrentKey` return and the
  `TestFilter`-is-not-a-type refusal were all discovered by `alc` before CI ran.

### 9. Additional platform/system surfaces

Status: partial or thin coverage.

Candidate areas:

- `Media` and `MediaSet`
- `TaskScheduler`
- `ModuleInfo` / related app metadata

These are lower priority than `Query` because the current suite is already strong on the most commonly used runtime behaviors.

Still entirely unmeasured, with the next pick and the reasons the others were passed over:

- **`ErrorInfo` (21 members) -- the recommended next pick, and REACHABILITY IS CHECKED, not
  assumed.** It is the largest completely unmeasured surface left. Two things make it a
  stronger pick than its reference count suggests:

  **The existing `error-handling/TestErrorInfo.al` does not use the type at all.** Its six
  tests exercise plain `Error()` text formatting and `GetLastErrorText`/`GetLastErrorCode`;
  a grep for `: ErrorInfo` or `ErrorInfo.` in that file returns **zero**. The file is named
  for the type and measures none of it, so the name is why the surface looks covered and is
  not. Whoever picks this up should check whether the new tests belong beside it or in a
  file of their own.

  **Its header's scope note -- "ErrorInfo type is OnPrem-only" -- is falsified by the
  compiler.** Probed with the real `alc` against this app's Cloud target (runtime 16.0), all
  of the following compile: `ErrorInfo.Create(text, collectible)`, `Message()`, the `Title`
  and `DetailedMessage` setters, `Collectible()`, `Callstack()`,
  `AddAction(label, codeunit, method)`, `AddNavigationAction(label)` and
  `CustomDimensions.Get(key)`. So the type is reachable from a Cloud `[Test]` and the note
  should be corrected as part of the work. (What is NOT yet established is whether a
  collectible error's *runtime* behavior -- collection into an error set, the action
  callbacks actually firing -- is observable from a `[Test]` without a client. That is the
  question for the tier to settle, and it is exactly the shape of question this series
  exists to ask.)

  It carries real negative cases, which is what `ProductName` lacked: `Create` with and
  without collectibility, `AddAction` naming a method that does not exist, `Verbosity` and
  `DataClassification` enums with specific values, and `FieldNo`/`TableId`/`RecordId`
  round-tripping against a real record.

- **`XmlCData` and `XmlComment` (17 members each, 1 reference) -- plausible, and cheaper than
  they look.** Their member lists are nearly identical to each other and largely shared with
  the `XmlNode` surface the suite already covers under `xml/`, so much of the 17 is the
  common node protocol (`AddAfterSelf`, `Replacewith`, `GetParent`, `SelectNodes`, `WriteTo`)
  rather than 17 distinct behaviors. Worth taking as **one** suite covering both types, since
  the interesting claims are where CData and Comment differ from an element and from each
  other -- escaping, `Value` round-tripping, and what `SelectNodes` does with them.

- **`File` (48 members, 2 references) is the largest surface here and is deliberately NOT
  recommended.** It is out of scope on Cloud; the corpus app targets Cloud.

- **`ProductName` (3 members) -- examined and passed over as too thin.** `Full()`,
  `Marketing()` and `Short()` take no arguments, have no negative case, and return localized
  strings that differ by BC version, so nothing beyond "these three differ from each other and
  are non-empty" can be asserted without pinning a localization detail. That is roughly three
  tests, and padding it further would produce assertions that pass for the wrong reason. Worth
  folding into a broader "platform identity" suite alongside `SessionInformation` (4 members,
  6 references) rather than given a file of its own. **This judgement has now been made twice;
  do not resurrect it to pad a suite.**
- **`ProductName` (3 members) -- examined and passed over as too thin.** `Full()`,
  `Marketing()` and `Short()` take no arguments, have no negative case, and return localized
  strings that differ by BC version, so nothing beyond "these three differ from each other and
  are non-empty" can be asserted without pinning a localization detail. That is roughly three
  tests, and padding it further would produce assertions that pass for the wrong reason. Worth
  folding into a broader "platform identity" suite alongside `SessionInformation` (4 members,
  6 references) rather than given a file of its own.
- **`Cookie` and `Debugger` remain genuinely unreachable.** `Cookie` is only obtainable from an
  `HttpResponseMessage`, and the whole HTTP surface is out of scope; `Debugger` needs a
  debugging session attached to the tenant.
- **`TestHttpRequestMessage` / `TestHttpResponseMessage`** are zero-reference but belong to the
  out-of-scope HTTP surface.
- One caution for whoever picks next: a **zero-reference count in `scripts/al-surface.json` is
  not the same as an unmeasured surface**. `TextConst` shows 0 references and 20 members, but
  those 20 are the `Text` data type's own methods (`Contains`, `Split`, `PadLeft`, ...), which
  the suite covers thoroughly under `text/`. The count is zero only because nobody writes the
  literal word "TextConst". Check what the members actually are before trusting the ranking.

## Query Coverage Target

The baseline query object surface is now covered for cloud-safe execution.

Remaining query-specific follow-up is narrower:

1. Add a grouped/aggregate query fixture if we want to document totals and grouping behavior.
2. Decide whether file-name export overloads need separate documentation-only notes beyond the current compile-surface note.

## Working Rule

Any item added here should be grounded in a Microsoft Learn page and mapped to a concrete AL test file or fixture object before implementation starts.
