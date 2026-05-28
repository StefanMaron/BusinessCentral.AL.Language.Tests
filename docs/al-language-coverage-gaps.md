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

The baseline query object surface is now covered for cloud-safe execution.

Remaining query-specific follow-up is narrower:

1. Add a grouped/aggregate query fixture if we want to document totals and grouping behavior.
2. Decide whether file-name export overloads need separate documentation-only notes beyond the current compile-surface note.

## Working Rule

Any item added here should be grounded in a Microsoft Learn page and mapped to a concrete AL test file or fixture object before implementation starts.
