# Must-not-compile corpus

Each file in `cases/` is a small AL file that the real AL compiler REJECTS. The file records the diagnostic(s) the compiler gives, so a
runtime that claims to accept or refuse AL source can be held to the same verdict as real Business Central (`code AL0161` and the text, not a
guess). The corpus is not an app: every file is compiled alone, in a fresh one-file project.

## One case = one file

`cases/NNNN-short-name.al`, numbered in the order they were added. The file holds every object the case needs (the base page and the extension
that fails, the table, ...); object ids use 50000 to 59999, names start with `MNC`.

The header is the run of `//` comment lines at the top. A line `// @key value` is machine readable, any other comment line is for people.

| line | meaning |
|---|---|
| `// @expect AL0161 \| 'Hidden' is inaccessible due to its protection level` | one expected diagnostic: code, then the text. Repeat the line for several diagnostics. The recorded text must be the START of the compiler's text (the compilers differ in the explanation they append), and the diagnostics found must match the `@expect` lines exactly, none missing, none extra. |
| `// @target OnPrem` | the app's target; default `Cloud`. |
| `// @depends Base Application,System Application` | the dependencies; this is the default (names are `Base Application` and `System Application`). |
| `// @appjson {"assemblyProbingPaths": ["./x"]}` | JSON merged into the generated app.json (for diagnostics about app.json). |
| `// @from 27` / `// @until 28` | the BC majors the verdict holds for (default all). |
| `// @max-al 17` | the case is skipped with a compiler newer than this AL major (the verdict is that of the AL 16 and 17 compilers; AL 18 and later accept the file). |
| `// @min-al 18` | the case is skipped with a compiler older than this AL major (AL 16 and 17 report AL0451 for a `dotnet` block before they reach the real error). |

The expected `AL` code and text are for the compiler of that BC major; where two majors differ, write two files (with `@from`/`@until`).

## How a case is checked

`.github/scripts/check-must-not-compile.py --al "<AL command>" --symbols <dir of .app symbol packages> --bc-major 27 [--al-major 16]` builds for
each file a project with a generated `app.json` (`runtime` 16.1 for BC 27, 17.1 for BC 28, 18.0 for BC 29, or `--runtime`; platform and application 27.0.0.0 unless `@appjson` says otherwise) and the file as
`src/case.al`, runs `AL compile /project:... /packagecachepath:... /out:... /define:BC<major>PLUS`, and requires: the compiler exits with errors, no
package is written, and the `error ALxxxx: text` lines equal the `@expect` lines. `.github/scripts/test-must-not-compile.py` tests the parsing and the
comparison without a compiler (it runs in the existing self-test job).

## For the runtime

The format is plain text on purpose. A runtime reads a case with: the header lines (`// @expect CODE | text`) and the rest of the file as source.
For every case the runtime should refuse the source (not run it) with a diagnostic whose code is the recorded one; the text is the compiler's and
is only a reference.

## Cases so far

| file | code | what |
|---|---|---|
| 0001 | AL0161 | page extension names a non-protected variable of its base page |
| 0002 | AL0161 | page extension calls a local procedure of its base page |
| 0003 | AL0440 | page extension procedure with the signature of a base page procedure |
| 0004 | AL0162 | OnInit trigger in a page extension |
| 0005 | AL0118 | `CreateSequentialGuid` does not exist |
| 0006 | AL0296 | Cloud app names a Scope = OnPrem table |
| 0007 | AL0124 | `assemblyProbingPaths` in app.json at runtime 16.0 |
| 0008 | AL0175 | `=` between two DotNet class objects (OnPrem, AL 18+) |
| 0009 | AL0365 | `DataItemLink` on a query data item with `SqlJoinType = CrossJoin` |
| 0010 to 0013 | AL0132 | `ExecutionMode::Install`, `Uninstall`, `Upgrade` and `Report` do not exist (only Standard and Debug) |
| 0014 | AL0296 | Cloud app names the Scope = OnPrem table `API Webhook Entity` |
| 0015 | AL0385 | `IncludeCaption` on a report column whose source is an expression |
| 0016 | AL0197 | two codeunits of the same name (one diagnostic per declaration) |
| 0017, 0018 | AL0162 | `OnFindRecord` and `OnNextRecord` in a page extension (every other page trigger, 12 of them, compiles in an extension: see tests/al-language/pageext/POPageExtTriggers.al) |
| 0019 | AL0132 | `ExecutionMode::Profile` does not exist |
| 0020 to 0024 | AL0296 (and AL0433 for removed tables) | all 123 platform tables of System.app with Scope = OnPrem named from a Cloud app, 30 per case; symbols of BC 27.0 only (`@from 27`, `@until 27`) |
| 0030 to 0033 | AL0118 | an unknown bare procedure name inside a table, a page, a report and a page extension |
| 0034, 0035 | AL0197 | two page extensions / two tables of the same name |
| 0036 | AL0264 | two codeunits with the same id |
| 0040 to 0042 | AL0161, AL0161, AL0440 | report extension forms of cases 0001 to 0003 |
| 0043 | AL0440 | two procedures with the same parameter types in one codeunit |
| 0044 | AL0121 | a variable declared twice |
| 0045, 0046 | AL0155, AL0231 | an enum with a duplicate value name / ordinal |
| 0047 | AL0280 | an event subscriber for an event the publisher does not have |
| 0048 | AL0139 | `exit(1)` in a procedure without a return value |
| 0049 | AL0499 | `HandlerFunctions` naming a procedure that does not exist |
| 0050 | AL0582 | a codeunit implements an interface and lacks a member |
| 0051 | AL0130 | a literal passed for a `var` parameter |
| 0053 | AL0111 | a statement without its semicolon |
| 0054, 0055 | AL0297, AL0305 | object id outside the `idRanges` of app.json / object name longer than 30 characters |
| 0056 | AL0152 | an Option variable that repeats a member |
| 0057 | AL0247 | a page extension of a page that does not exist |
| 0058 | AL0345, AL0353 | a query column over a field the table lacks |
| 0059 | AL0118 | `Rec` in a codeunit without `TableNo` |
| 0060, 0061 | AL0132 | a field / a method that a Record does not have |
| 0062, 0063, 0064 | AL0155, AL0206, AL0155 | a report column / table field id / table field name declared twice |
| 0065, 0068 | AL0244 | a `[Test]` procedure or a `[TryFunction]` with a return value |
| 0066, 0067 | AL0135, AL0126 | too few / too many arguments |
| 0069, 0070 | AL0122 | Integer to Text and Text to Integer assignment |
| 0071 to 0073 | AL0124 | `assemblyProbingPaths` at runtime 15.0, 16.1 and 17.0 (16.1 and 17.0 need AL 17 or newer) |
| 0074, 0075 | AL0122 | an enum assigned to an enum of another type whose TARGET lacks `AssignmentCompatibility` (the source's flag does not help) |
| 0076 | AL0126 | `Media.ImportStream` with a file name as a fourth argument (BC 27 has three) |
| 0100 | AL0390 | A DateFormula field whose InitValue is not a date formula. |
| 0101 | AL0342 | A query with two dataitems nested under the same parent dataitem (siblings). |
| 0102 | AL0353 | A query column with Method = Count that names a source field. |
| 0103 | AL0124 | OrderBy written on a query dataitem (it belongs to the query object). |
| 0105 | AL0167 | TextEncoding on an xmlport whose Format is Xml (it needs VariableText or FixedText). |
| 0106 | AL0169 | Encoding = MSDOS on an xmlport (Encoding takes UTF8 or UTF16). |
| 0107 | AL0132 | Text has no Length method (StrLen is the function). |
| 0108 | AL0347 | A query column with Method = Sum over a Text field. |
| 0109 | AL0347 | A query column with Method = Average over a Date field. |
| 0110 | AL0296 | GetLastErrorObject has scope OnPrem; a Cloud app names it. |
| 0111 | AL0130 | this passed to a var parameter of another codeunit. |
| 0112 | AL0296 | SecretText.Unwrap named from a Cloud app (the method has scope OnPrem). |
| 0113 | AL0296 | A variable of the File data type in a Cloud app. |
| 0722 | AL0284 | A subscriber to Global Triggers.OnGlobalInsert declares its parameter as Integer instead of RecordRef. |
| 0723 | AL0284 | A subscriber to Environment Triggers.OnAfterCopyEnvironmentPerDatabase declares the environment types as Integer instead of an Option (two diagnostics). |
| 0724 | AL0282 | A subscriber to Reporting Triggers.GetPrinterName declares a parameter the event does not have. |
| 0725 | AL0280 | A subscriber names an event that Company Triggers does not declare (OnCompanyOpened). |

Accepted by the compiler, so not cases: an overload in a page extension (the name of a base procedure with other parameter types: tests/al-language/pageext/POPageExtOverload.al), and a bare `exit;` in a procedure with a return value.

## CI

The reusable workflow compiles apps that must build, so it cannot run these. A job of its own is needed per BC major: install the AL compiler of
that major (`bc-linux/scripts/install-al-compiler.sh <bc_version>`), stage the symbols of that major (the step that fills `symbols/` in
`bc-test-from-source.yml`), then run `check-must-not-compile.py --al AL --symbols symbols --bc-major <major> --al-major <AL major>`. The job needs no
BC container. Run locally with the tools in `~/.al-tool-cache` it passes today with AL 16.2, 17.0.34, 18.0.43 and 30.0.42 on the 27.0 symbols.
