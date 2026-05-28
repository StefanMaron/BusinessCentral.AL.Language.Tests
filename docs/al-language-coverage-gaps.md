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

Status: not yet covered.

Why it matters:

- Microsoft documents `Query` as a first-class AL surface.
- Query objects are a natural fit for BC Cloud behavior proofs because they can be executed, filtered, and read without rendering.

Recommended first slice:

- Add a query fixture over `ALT Universal`.
- Cover `Open()`, `Read()`, `Close()`, `SetRange()`, and `GetFilter()`.
- Add a second test for `TopNumberOfRows()` once the basic open/read path is in place.

### 2. XmlPort objects

Status: not yet covered.

Why it matters:

- Microsoft documents `XmlPort` separately from `XML` data types.
- The suite currently covers XML document manipulation, but not the object model used for import/export style processing.

### 3. SecretText

Status: not yet covered.

Why it matters:

- `SecretText` is a distinct AL data type with security-sensitive behavior.
- It deserves a dedicated coverage slice rather than being folded into generic text tests.

### 4. Additional platform/system surfaces

Status: partial or thin coverage.

Candidate areas:

- `SessionSettings`
- `Media` and `MediaSet`
- `TaskScheduler`
- `ModuleInfo` / related app metadata
- `WebServiceActionContext`

These are lower priority than `Query` because the current suite is already strong on the most commonly used runtime behaviors.

## Query Coverage Target

The first query implementation should prove:

1. A query object can be opened against fixture data.
2. `Read()` returns each row in the dataset.
3. Query column values can be asserted from AL.
4. Filters change the returned dataset in a predictable way.

After that, the next additions should be:

- `TopNumberOfRows()`
- `GetFilter()`
- `GetFilters()`
- `ColumnName()` / `ColumnNo()`
- aggregate query behavior if we need more than row-by-row access

## Working Rule

Any item added here should be grounded in a Microsoft Learn page and mapped to a concrete AL test file or fixture object before implementation starts.
