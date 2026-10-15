// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// A page layout with a field directly under layout.
page 50157 "MNC P339"
{
    PageType = Card;
    layout
    {
        field(X; 1) { }
    }
}
