// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// `internal interface` (microsoft/AL issue 7808): the access modifier before the keyword is a syntax error. The text lists interface
// among the expected keywords. An interface is made internal with the property Access = Internal.
internal interface "MNC BP I1445"
{
    procedure MyMethod();
}
