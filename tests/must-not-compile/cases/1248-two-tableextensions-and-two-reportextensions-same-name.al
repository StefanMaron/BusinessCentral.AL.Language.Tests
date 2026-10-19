// @expect AL0197 | An application object of type 'TableExtension' with name 'MNC BB Ext' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// @expect AL0197 | An application object of type 'TableExtension' with name 'MNC BB Ext' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// @expect AL0197 | An application object of type 'ReportExtension' with name 'MNC BB Ext' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// @expect AL0197 | An application object of type 'ReportExtension' with name 'MNC BB Ext' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// Two table extensions of one name and two report extensions of one name (two page extensions are case 0034): AL0197 on each declaration.
// Two objects of one type and name in two different namespaces of one app also get AL0197 on each declaration (checked with a two-file
// project; a case here is one file, and a file holds one namespace). (4 diagnostics)
table 50000 "MNC BB Table"
{
    fields { field(1; Id; Integer) { } field(2; Name; Text[30]) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
tableextension 50001 "MNC BB Ext" extends "MNC BB Table"
{
    fields { field(50000; A; Integer) { } }
}
tableextension 50002 "MNC BB Ext" extends "MNC BB Table"
{
    fields { field(50001; B; Integer) { } }
}
report 50003 "MNC BB Report"
{
    dataset { dataitem(Row; "MNC BB Table") { column(Id; Id) { } } }
}
reportextension 50004 "MNC BB Ext" extends "MNC BB Report"
{
}
reportextension 50005 "MNC BB Ext" extends "MNC BB Report"
{
}
