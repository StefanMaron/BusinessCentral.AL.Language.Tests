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
| `// @min-al 18` | the case is skipped with a compiler older than this AL major (AL 16 and 17 report AL0451 for a `dotnet` block before they reach the real error). |

The expected `AL` code and text are for the compiler of that BC major; where two majors differ, write two files (with `@from`/`@until`).

## How a case is checked

`.github/scripts/check-must-not-compile.py --al "<AL command>" --symbols <dir of .app symbol packages> --bc-major 27 [--al-major 16]` builds for
each file a project with a generated `app.json` (`runtime` 16.0, platform and application 27.0.0.0 unless `@appjson` says otherwise) and the file as
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

## CI

The reusable workflow compiles apps that must build, so it cannot run these. A job of its own is needed per BC major: install the AL compiler of
that major (`bc-linux/scripts/install-al-compiler.sh <bc_version>`), stage the symbols of that major (the step that fills `symbols/` in
`bc-test-from-source.yml`), then run `check-must-not-compile.py --al AL --symbols symbols --bc-major <major> --al-major <AL major>`. The job needs no
BC container. Run locally with the tools in `~/.al-tool-cache` it passes today with AL 16.2, 17.0.34, 18.0.43 and 30.0.42 on the 27.0 symbols.
