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
| 0640 | AL0666 | `JsonArray.SelectTokens` needs runtime 17; the BC 27 app runs on 16.1 (BC 28 and 29 compile it) |
| 0641, 0642 | AL0126 | `MediaSet.ImportStream` and `Media.ImportStream` with a file name as fourth argument (0642: on 27, 28 and 29) |
| 0643 to 0646 | AL0296 | `Media.ExportFile`, `Media.ImportFile`, `MediaSet.ExportFile` and `MediaSet.ImportFile` named from a Cloud app (Scope = OnPrem) |
| 0647 to 0650 | AL0133 | `Query.SaveAsCsv` and `Query.SaveAsXml` with a file name (instance and by object number): in a Cloud app only the OutStream forms exist |
| 0651 to 0653 | AL0296 | `HttpClient.UseDefaultNetworkWindowsAuthentication` and `UseWindowsAuthentication` (Text and SecretText) named from a Cloud app |
| 0660 | AL0296 | Report.SaveAsExcel, SaveAsHtml, SaveAsPdf, SaveAsWord and SaveAsXml of the global Report object (object id and file name) are Scope = OnPrem: a Target = Cloud app cannot name them. (5 diagnostics) |
| 0661 | AL0296 | Report.SaveAsExcel, SaveAsHtml, SaveAsPdf, SaveAsWord and SaveAsXml on a Report variable (file name) are Scope = OnPrem: a Target = Cloud app cannot call them. (5 diagnostics) |
| 0664 | AL0666 | The fully qualified name overloads of Report.Run, Report.RunModal, Report.Execute, Page.Run and RecordRef.Open and RecordRef.FullyQualifiedName need runtime 17.0: the BC 27 app runtime is 16.1 and cannot call them (the BC 28 and 29 apps run on 17.1 and 18.0, where tests/al-language pins them). (6 diagnostics) |
| 0665 | AL0666 | The fully qualified name overloads of Report.Run, Report.RunModal, Report.Execute, Page.Run, Page.RunModal and RecordRef.Open and RecordRef.FullyQualifiedName need runtime 17.0: an app with runtime 16.0 (the default here) cannot call them on any BC major. (8 diagnostics) |
| 0680 | AL0246 | A page extension cannot change DecimalPlaces of a base field with modify. |
| 0681 | AL0246 | A page extension cannot change DrillDown of a base field with modify. |
| 0682 | AL0246 | A page extension cannot change Lookup of a base field with modify. |
| 0683 | AL0246 | A page extension cannot change ShowFilter of a base part with modify. |
| 0684 | AL0666 | A page extension cannot change Editable of a base part with modify (runtime 16.0). |
| 0685 | AL0169 | UpdatePropagation knows Both and SubPart only. |
| 0686 | AL0246 | A page extension cannot change UpdatePropagation of a base part with modify. |
| 0687 | AL0223 | DataAccessIntent is allowed on an API page only, and then only with Editable = false. (2 diagnostics) |
| 0688 | AL0167 | IsPreview is allowed on PromptDialog and ConfigurationDialog pages only. |
| 0689 | AL0674 | A custom action of type Flow needs a FlowId. |
| 0690 | AL0169 | CustomActionType takes a known value only. |
| 0691 | AL0169 | Scope of a file upload action takes Page or Repeater only. |
| 0692 | AL0825 | MovedFrom on a field of a base table (not of a table extension). |
| 0693 | AL0734 | MovedFrom takes the id of an app, a GUID. |
| 0694 | AL0167 | MovedTo needs ObsoleteState PendingMove or Moved. |
| 0695 | AL0167 | ExternalSchema needs TableType CRM, ExternalSQL or CDS. |
| 0696 | AL0167 | OptionOrdinalValues needs TableType CRM or CDS and an ExternalType of Picklist, State or Status. (2 diagnostics) |
| 0697 | AL0447 | TableType ExternalSQL cannot be used for Cloud development (ExternalSchema is meant for it). |
| 0698 | AL0124 | MaxLength is a modifier of Caption only; on a field it is not a property. |
| 0699 | AL0829 | MovedTo names the app of the extension itself. |
| 0700 | AL0456 | OptionOrdinalValues needs one value per option member. |
| 0701 | AL0124 | Width is not a property of a report column. |
| 0702 | AL0439 | A report label takes Comment, Locked and MaxLength only; CaptionClass is not one of them. |
| 0703 | AL0706 | RDLCLayout and WordLayout cannot be used while the report has a rendering section. (2 diagnostics) |
| 0704 | AL0124 | TableRelation is not a property of an XmlPort field element (the table field carries it). |
| 0705 | AL0850, AL0296 | Scope = OnPrem on an interface is refused for a Cloud app. (2 diagnostics) |
| 0706 | AL0223 | TestIsolation is a property of a test runner codeunit; a test codeunit cannot state it. |
| 0707 | AL0195 | InherentPermissions on a report takes X only. |
| 0708 | AL0674 | An entitlement of type ConcurrentUserServicePlan needs an Id. (2 diagnostics) |
| 0709 | AL0169, AL0327 | Removed is not a value of ObsoleteState for these object kinds (it is for table fields). (9 diagnostics) |
| 0710 | AL0169 | Removed is not a value of ObsoleteState for an enum value or an enum extension value. (2 diagnostics) |
| 0711 | AL0169 | Removed is not a value of ObsoleteState for a page group, cue group, label, field or separator. (4 diagnostics) |
| 0712 | AL0169 | Removed is not a value of ObsoleteState for a page extension, or for a group, field or action it adds. (4 diagnostics) |
| 0713 | AL0223 | ObsoleteReason and ObsoleteTag need ObsoleteState = Pending, on every object kind. (14 diagnostics) |
| 0714 | AL0169 | RoleType takes Local or Delegated only. |
| 0715 | AL0674 | An entitlement of type Role needs an Id. |
| 0716 | AL0223 | RoleType needs Type = Role, and GroupName needs Type = ConcurrentUserServicePlan. (2 diagnostics) |
| 0722 | AL0284 | A subscriber to Global Triggers.OnGlobalInsert declares its parameter as Integer instead of RecordRef. |
| 0723 | AL0284 | A subscriber to Environment Triggers.OnAfterCopyEnvironmentPerDatabase declares the environment types as Integer instead of an Option (two diagnostics). |
| 0724 | AL0282 | A subscriber to Reporting Triggers.GetPrinterName declares a parameter the event does not have. |
| 0725 | AL0280 | A subscriber names an event that Company Triggers does not declare (OnCompanyOpened). |
| 0740 | AL0161 | An app subscribes to GetRoleCenterBannerPartID of the platform codeunit "System Action Triggers"; the event is declared an InternalEvent. |
| 0760 | AL0844 | A Date field cannot carry DateFormula = true (the property exists only on Text-like fields). |
| 0761 | AL0843 | SQLDataType is allowed on Code fields only. |
| 0762 | AL0169 | MaskType takes None or Concealed. |
| 0763 | AL0103 | Width on a table field with a value that does not fit an Integer. |
| 0764 | AL0232 | Width with a negative value. |
| 0765 | AL0169 | AllowInCustomizations takes ToBeClassified, Never, AsReadOnly or AsReadWrite. |
| 0766 | AL0169 | Same as 0765, on a table extension. |
| 0767 | AL0186 | ColumnStoreIndex names a field the table does not have. |
| 0768 | AL0223 | LinkedInTransaction on a table that is not LinkedObject. |
| 0769 | AL0185 | DrillDownPageId of a table extension names a page that does not exist. |
| 0770 | AL0185 | LookupPageId of a table extension names a page that does not exist. |
| 0771 | AL0169 | modify() of a field with an invalid MaskType value. |
| 0772 | AL0103 | modify() of a field with a Width out of range. |
| 0773 | AL0876 | MaskType = Concealed together with ExtendedDatatype = Masked. |
| 0774 | AL0843 | SQLTimestamp on an Integer field. |
| 0775 | AL0843 | OptionCaptionML on a Text field. |
| 0777 | AL0666 | BC 28 only: a page content area and an action area take none of ObsoleteState, ObsoleteReason and ObsoleteTag (not available in runtime 17.1). (6 diagnostics) |
| 0778 | AL0666 | BC 29 and later: the same as 0777 at runtime 18.0. (6 diagnostics) |
| 0780 | AL0223 | RequiredTestIsolation is only allowed on a codeunit with Subtype = Test. |
| 0781 | AL0223 | TestType is only allowed on a codeunit with Subtype = Test. |
| 0782 | AL0169 | TestType takes UnitTest, IntegrationTest, Uncategorized or AITest. |
| 0783 | AL0169 | RequiredTestIsolation takes None, Disabled, Codeunit or Function. |
| 0784 | AL0666, AL0928 | BC 27 only: TestHandlers needs runtime 18.0, and the BC 27 symbols lack the system enum TestHandler. (2 diagnostics) |
| 0787 | AL0103 | MaximumHeight of a control add-in does not fit an Integer. |
| 0788 | AL0103 | MaximumWidth of a control add-in does not fit an Integer. |
| 0789 | AL0223 | AssignmentCompatibilityReason needs AssignmentCompatibility = true. |
| 0790 | AL0185 | ExcludedPermissionSets names a permission set that does not exist. |
| 0791 | AL0428, AL0543 | A query sets HelpLink and ContextSensitiveHelpPage together. (3 diagnostics) |
| 0792 | AL0543 | ContextSensitiveHelpPage on a query needs contextSensitiveHelpUrl in app.json. |
| 0793 | AL0471 | HelpLink on a query with a text that is not a URL. |
| 0794 | AL0223 | EntityCaption on a query that is not of QueryType API. |
| 0795 | AL0160 | ProfileDescriptionML with a language code that does not exist. |
| 0796 | AL0428 | EntityCaption together with EntityCaptionML, and EntitySetCaption together with EntitySetCaptionML, on a query. (4 diagnostics) |
| 0797 | AL0169 | Removed is not a value of ObsoleteState for page controls and actions. (11 diagnostics) |
| 0798 | AL0169 | Removed is not a value of ObsoleteState for a table field group, page customization, permission set, profile, query column and query filter. (8 diagnostics) |
| 0799 | AL0666 | BC 27 only: the same as 0777 at runtime 16.1. (6 diagnostics) |
| 0800 | AL0666 | Report parts need runtime 18.0 (BC 29). BC 27 compiles at runtime 16.1, BC 28 at 17.1: the text differs only in the version, so the recorded text stops before it. BC 29: positive test report/lt-y-report-props/YReportParts.al. (@until BC 28) |
| 0801 | AL0666 | Report parts need runtime 18.0 (BC 29). BC 27 compiles at runtime 16.1, BC 28 at 17.1: the text differs only in the version, so the recorded text stops before it. BC 29: positive test report/lt-y-report-props/YReportParts.al. (@until BC 28) |
| 0802 | AL0666 | Report parts need runtime 18.0 (BC 29). BC 27 compiles at runtime 16.1, BC 28 at 17.1: the text differs only in the version, so the recorded text stops before it. BC 29: positive test report/lt-y-report-props/YReportParts.al. (@until BC 28) |
| 0803 | AL0666 | Report parts need runtime 18.0 (BC 29). BC 27 compiles at runtime 16.1, BC 28 at 17.1: the text differs only in the version, so the recorded text stops before it. BC 29: positive test report/lt-y-report-props/YReportParts.al. (@until BC 28) |
| 0804 | AL0666 | Report parts need runtime 18.0 (BC 29). BC 27 compiles at runtime 16.1, BC 28 at 17.1: the text differs only in the version, so the recorded text stops before it. BC 29: positive test report/lt-y-report-props/YReportParts.al. (@until BC 28) |
| 0805 | AL0223 | Runtime 18.0 (BC 29): layout Subtype needs Type = Word. BC 27 and 28 give AL0666 for Subtype instead (case 0803). (@from BC 29) |
| 0806 | AL0296 | . |
| 0807 | AL0169 | . |
| 0808 | AL0169 | . |
| 0809 | AL0169 | . |
| 0810 | AL0169 | . |
| 0811 | AL0436 | . |
| 0812 | AL0543 | ContextSensitiveHelpPage needs the manifest property contextSensitiveHelpUrl, which the corpus apps do not set. |
| 0813 | AL0543, AL0428 | . |
| 0814 | AL0471 | . |
| 0815 | AL0185 | . |
| 0816 | AL0428 | . |
| 0817 | AL0324 | . |
| 0818 | AL0160 | . |
| 0819 | AL0359 | . |
| 0820 | AL0373 | . |
| 0821 | AL0103 | . |
| 0822 | AL0103 | . |
| 0823 | AL0103 | . |
| 0824 | AL0103 | . |
| 0825 | AL0169 | . |
| 0826 | AL0124 | . |
| 0840 | AL0543, AL0428 | HelpLink and ContextSensitiveHelpPage cannot both be set on a page. (3 diagnostics) |
| 0841 | AL0543 | ContextSensitiveHelpPage needs the manifest property contextSensitiveHelpUrl (app.json has none). |
| 0842 | AL0428 | EntityCaption and EntityCaptionML cannot both be set on an API page. (2 diagnostics) |
| 0843 | AL0428 | EntitySetCaption and EntitySetCaptionML cannot both be set on an API page. (2 diagnostics) |
| 0844 | AL0428 | PromotedActionCategories and PromotedActionCategoriesML cannot both be set on a page. (2 diagnostics) |
| 0845 | AL0428 | AdditionalSearchTerms and AdditionalSearchTermsML cannot both be set in a page extension. (2 diagnostics) |
| 0846 | AL0169 | PromptMode knows Prompt, Content and Generate only. |
| 0847 | AL0223 | A PromptDialog page must set Extensible = false. |
| 0848 | AL0471 | HelpLink must be a URL. |
| 0849 | AL0246 | A page extension cannot change DecimalPlaces with modify. |
| 0850 | AL0246 | A page extension cannot change DrillDown with modify. |
| 0851 | AL0246 | A page extension cannot change Lookup with modify. |
| 0852 | AL0246 | A page extension cannot change ShowFilter of a part with modify. |
| 0853 | AL0246 | A page extension cannot change UpdatePropagation of a part with modify. |
| 0854 | AL0185 | CardPageId must name an existing page. |
| 0855 | AL0185 | LookupPageId must name an existing page. |
| 0856 | AL0169 | MaskType knows None and Concealed only. |
| 0857 | AL0169 | Style knows the ten named styles only. |
| 0858 | AL0232 | Width must be within the allowed range (a negative value). |
| 0860 | AL0808 | A page customization cannot set Editable = true on a control whose source field has AllowInCustomizations ToBeClassified. |
| 0861 | AL0223 | ClearViews is for list pages only. |
| 0862 | AL0169 | Importance knows Standard, Promoted and Additional only. |
| 0863 | AL0169 | MaskType knows None and Concealed only. |
| 0864 | AL0232 | Width must be within the allowed range (a negative value). |
| 0865 | AL0161 | A page customization cannot name a variable of the page it customizes in an expression. |
| 0866 | AL0270 | modify() names a control that the customized page does not have. |
| 0868 | AL0208 | QuickEntry takes a boolean constant. |
| 0869 | AL0844 | BlankZero on a Text field of a page extension (a number property). |
| 0870 | AL0843 | OptionCaptionML on a Text field. |
| 0920 | AL0314 | FreezeColumn is a repeater property: a cue group refuses it (an unknown field name does not matter, the container is refused first). |
| 0921 | AL0591 | GridLayout is a grid property: a cue group refuses it. |
| 0922 | AL0314 | IndentationColumn is a repeater property: a cue group refuses it. |
| 0923 | AL0314 | IndentationControls is a repeater property: a cue group refuses it (a field that exists). |
| 0924 | AL0314 | IndentationControls is a repeater property: a cue group refuses it (a control that does not exist). |
| 0925 | AL0591 | TreeInitialState is a repeater property: a cue group refuses it. |
| 0926 | AL0169 | CuegroupLayout has one value, Wide (case does not matter: pages/lt-ab-group-properties/ABLayouts.al compiles Wide and wide). |
| 0927 | AL0169 | CuegroupLayout has one value, Wide. |
| 0928 | AL0169 | CuegroupLayout has one value, Wide: any other name is refused. |
| 0929 | AL0186 | FileUploadAction names an action of the page; an action that does not exist is refused. |
| 0930 | AL0591 | FileUploadRowAction is a repeater property: a cue group refuses it even when the action exists. |
| 0931 | AL0591 | CuegroupLayout is a cue group property: a fixed group refuses it. |
| 0932 | AL0314 | FreezeColumn is a repeater property: a fixed group refuses it. |
| 0933 | AL0591 | GridLayout is a grid property: a fixed group refuses it. |
| 0934 | AL0314 | IndentationColumn is a repeater property: a fixed group refuses it. |
| 0935 | AL0314 | IndentationControls is a repeater property: a fixed group refuses it. |
| 0936 | AL0591 | TreeInitialState is a repeater property: a fixed group refuses it. |
| 0937 | AL0186 | FileUploadAction names an action of the page; an action that does not exist is refused. |
| 0938 | AL0591 | FileUploadRowAction is a repeater property: a fixed group refuses it even when the action exists. |
| 0939 | AL0591 | CuegroupLayout is a cue group property: a grid refuses it. |
| 0940 | AL0314 | FreezeColumn is a repeater property: a grid refuses it. |
| 0941 | AL0314 | IndentationColumn is a repeater property: a grid refuses it. |
| 0942 | AL0314 | IndentationControls is a repeater property: a grid refuses it. |
| 0943 | AL0591 | TreeInitialState is a repeater property: a grid refuses it. |
| 0944 | AL0169 | GridLayout has the values Rows and Columns (pages/lt-ab-group-properties/ABLayouts.al): any other name is refused. |
| 0945 | AL0186 | FileUploadAction names an action of the page; an action that does not exist is refused. |
| 0946 | AL0591 | FileUploadRowAction is a repeater property: a grid refuses it even when the action exists. |
| 0947 | AL0162 | A control add-in trigger of a page field cannot be added to a field through a page extension modify block: OnControlAddIn is not a valid trigger there. |
| 0948 | AL0162 | A request page extension refuses the trigger OnFindRecord (every other page trigger compiles there: report/lt-ab-request-page-triggers/ABRequestPageExt.al); a page extension refuses the same two (0017, 0018). |
| 0949 | AL0162 | A request page extension refuses the trigger OnNextRecord (every other page trigger compiles there: report/lt-ab-request-page-triggers/ABRequestPageExt.al); a page extension refuses the same two (0017, 0018). |
| 0950 | AL0161 | The Rec variable of the base request page is not accessible from a trigger of a request page extension (the base page's own triggers use it: report/lt-ab-request-page-triggers/ABRequestPageFixtures.al). |
| 0951 | AL0477 | OnValidateUpgradePerCompany and OnValidateUpgradePerDatabase are valid only in a codeunit with Subtype = Upgrade (such a codeunit runs at publish, so the corpus holds none: .github/scripts/check-install-triggers.py). (two diagnostics). |
| 0960 | AL0132 | Record.IsDirty() exists from BC 29 (AL 18); BC 27 and 28 reject it. Runtime tests for BC 29: tests/al-language/lt-ac. |
| 0961 | AL0134 | The DataSourceContext type exists from BC 29. Runtime test for BC 29: tests/al-language/lt-ac/ACContexts.al. |
| 0962 | AL0134 | The TestHandlerContext type exists from BC 29. Runtime test for BC 29: tests/al-language/lt-ac/ACContexts.al. |
| 0963 | AL0126 | IsolatedStorage.Get with an IsolationLevel exists from BC 29. Runtime tests for BC 29: tests/al-language/lt-ac. |
| 0964 | AL0132 | ModuleInfo.ContextSensitiveHelpUrl, EULA, Help and PrivacyStatement exist from BC 29. Runtime tests for BC 29: tests/al-language/lt-ac. (4 diagnostics) |
| 0965 | AL0133 | NavApp.GetResource, GetResourceAsText and GetResourceAsJson with an AppId exist from BC 29. Runtime tests for BC 29: tests/al-language/lt-ac. (4 diagnostics) |
| 0966 | AL0126, AL0132 | NavApp.ListResources(AppId) and NavApp.ListAppsWithPublicResources exist from BC 29. Runtime tests for BC 29: tests/al-language/lt-ac. (2 diagnostics) |
| 0967 | AL0895 | The Native attribute on a procedure with a body outside the platform symbols app. (2 diagnostics) |
| 0968 | AL0112 | The Scope attribute takes OnPrem, Internal or Cloud; any other value is reported as an unknown attribute. |
| 0969 | AL0195 | InherentPermissions with a permission letter that is not R, I, M or D. |
| 0970 | AL0433 | A table with ObsoleteState = Removed is used as a record variable. A codeunit cannot be Removed (AL0169), a table can. |
| 0971 | AL0112 | The RequiredPending attribute exists from BC 29. |
| 0972 | AL0772 | RequiredPermissions is only valid on an external business event. |
| 0973 | AL0187, AL0296 | RunOnClient on a procedure: it is only valid on variables, and it has scope OnPrem. (2 diagnostics) |
| 0974 | AL0187, AL0296 | SuppressDispose on a procedure: it is only valid on variables, and it has scope OnPrem. (2 diagnostics) |
| 0975 | AL0187, AL0296 | WithEvents on a procedure: it is only valid on variables, and it has scope OnPrem. (2 diagnostics) |
| 0976 | AL0187 | SecurityFiltering on a procedure (it belongs on a Record variable: tests/al-language/lt-ac/ACAttributes.al). |
| 0977 | AL0187 | InDataSet on a procedure. The attribute is deprecated (AL0667 warning) and valid only on variables. |
| 0978 | AL0243 | The TestPermissions attribute on a procedure of a codeunit that is not a test codeunit. |
| 0979 | AL0132 | TestPermissions has Disabled, Restrictive, NonRestrictive and InheritFromTestRunner; there is no Normal. |
| 0980 | AL0619 | The Caption attribute on a procedure of a test codeunit (a plain codeunit accepts it). With ServiceEnabled it compiles: tests/al-language/lt-ac/ACAttributes.al. |
| 0981 | AL0296 | A procedure with [Scope('OnPrem')] called from the same Cloud app. |
| 0982 | AL0296 | A procedure with [Scope('Internal')] called from the same Cloud app. |
| 0983 | AL0296 | The HttpClientHandler attribute in a Cloud app (it has scope OnPrem). |
| 0984 | AL0241 | An HttpClientHandler procedure without parameters. |
| 0985 | AL0241 | A ReportHandler procedure without the Report parameter. Runtime test: tests/al-language/lt-ac/ACAttributes.al. |
| 0986 | AL0243 | The ReportHandler attribute in a codeunit that is not a test codeunit. |
| 0987 | AL0112 | The TestDataSource attribute exists from BC 29. |
| 0988 | AL0595 | On BC 29 the TestDataSource attribute names a codeunit that must implement ITestDataSource. |
| 0989 | AL0175 | PageStyle is option-like: it supports = and <> but not an ordering operator. The same holds for HttpRequestType, AuditCategory, SecurityOperationResult and PageBackgroundTaskErrorLevel. |
| 0990 | AL0132, AL0122 | HttpRequestType is option-like: no AsInteger, and an Integer cannot be assigned. The same holds for PageStyle, AuditCategory, SecurityOperationResult and PageBackgroundTaskErrorLevel. (2 diagnostics) |
| 0991 | AL0132 | A page calls a procedure that the control add-in does not declare. Runtime test for the valid call: tests/al-language/lt-ac/ACControlAddIn.al. |
| 0992 | AL0458 | WithEvents on a variable of a type that has no events (OnPrem app). Runtime test for a DotNet variable: tests/al-language-onprem-dotnet/lt-ac/AcDnAttributes.al. |
| 0993 | AL0458 | RunOnClient on a Boolean variable (OnPrem app): the attribute is valid only on DotNet variables. Runtime test: tests/al-language-onprem-dotnet/lt-ac/AcDnAttributes.al. |
| 0994 | AL0895 | The Native attribute needs runtime 17.0; at that runtime a procedure with a body outside the platform symbols app is rejected (once for the object, once for the attribute). (2 diagnostics) |
| 0995 | AL0666 | The DataSourceContext type needs runtime 18.0 (BC 29 and later). An app below that runtime gets AL0666 on every BC major (the AL 16 and 17 compilers' verdict for BC 27 and 28 is in cases 0961, 0962, 0971). |
| 0996 | AL0666 | The TestHandlerContext type needs runtime 18.0 (BC 29 and later). An app below that runtime gets AL0666 on every BC major (the AL 16 and 17 compilers' verdict for BC 27 and 28 is in cases 0961, 0962, 0971). |
| 0997 | AL0666 | The RequiredPending attribute needs runtime 18.0 (BC 29 and later). An app below that runtime gets AL0666 on every BC major (the AL 16 and 17 compilers' verdict for BC 27 and 28 is in cases 0961, 0962, 0971). |
| 0998 | AL0666 | The BC 29 methods Record.IsDirty, IsolatedStorage.Get with an IsolationLevel, ModuleInfo.ContextSensitiveHelpUrl, EULA, Help, PrivacyStatement and the NavApp resource methods need runtime 18.0. An app declared at runtime 16.0 gets AL0666 for each, on every BC major; the corpus app itself uses runtime 18.0 on BC 29 and guards them with BC29PLUS. (14 diagnostics) |
| 1040 | AL0175 | A Char minus a Text literal of two characters or of none, and the same literals minus a Char (four diagnostics). A one-character literal compiles. |
| 1041 | AL0122 | A Char minus a one-character literal is an Integer and cannot be assigned to a Text; a Char plus a two-character literal is a Text and cannot be assigned to an Integer (two diagnostics). |
| 1050 | AL0124 | XmlPort fieldelement: Occurrence belongs to attributes; elements use MinOccurs and MaxOccurs. |
| 1051 | AL0124 | XmlPort textelement: Occurrence belongs to attributes; elements use MinOccurs and MaxOccurs. |
| 1052 | AL0124 | XmlPort tableelement: Occurrence belongs to attributes; elements use MinOccurs and MaxOccurs. |
| 1053 | AL0169 | XmlPort fieldattribute: Occurrence takes Optional or Required. |
| 1060 | AL0316 | A tree repeater whose IndentationColumn is a Decimal field. |
| 1061 | AL0316 | A tree repeater whose IndentationColumn is a Text field. |
| 1062 | AL0316 | A tree repeater whose IndentationColumn is an Option field. |
| 1063 | AL0171 | An XmlPort table element sets LinkFields but no LinkTable. |
| 1090 | AL0132 | CurrPage.PromptMode is set to PromptMode::Lookup on a PromptDialog page: PromptMode has no member Lookup. |
| 1091 | AL0124 | ApplicationArea on a page group: the property is not available on a group. |
| 1792 | AL0175 | `FieldRef.Value = Text`: '=' between Joker and Text. |
| 1793 | AL0175 | `FieldRef.Value = 2`: '=' between Joker and Integer. |
| 1794 | AL0175 | A Variant compared with a Text using '='. |

Accepted by the compiler, so not cases: an overload in a page extension (the name of a base procedure with other parameter types: tests/al-language/pageext/POPageExtOverload.al), and a bare `exit;` in a procedure with a return value.

## CI

The reusable workflow compiles apps that must build, so it cannot run these. A job of its own is needed per BC major: install the AL compiler of
that major (`bc-linux/scripts/install-al-compiler.sh <bc_version>`), stage the symbols of that major (the step that fills `symbols/` in
`bc-test-from-source.yml`), then run `check-must-not-compile.py --al AL --symbols symbols --bc-major <major> --al-major <AL major>`. The job needs no
BC container. Run locally with the tools in `~/.al-tool-cache` it passes today with AL 16.2, 17.0.34, 18.0.43 and 30.0.42 on the 27.0 symbols.
