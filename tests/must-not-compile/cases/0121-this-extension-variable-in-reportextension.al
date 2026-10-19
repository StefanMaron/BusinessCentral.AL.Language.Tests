// @expect AL0847 | 'Report "MNC Base Report"' does not contain a definition for 'ExtVar'
// this.<variable of the extension> inside a report extension: this is the base report, which does not know it.
table 50000 "MNC Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

report 50001 "MNC Base Report"
{
    dataset { dataitem(Row; "MNC Table") { } }
}

reportextension 50002 "MNC Base Report Ext" extends "MNC Base Report"
{
    var
        ExtVar: Text;

    trigger OnPreReport()
    begin
        this.ExtVar := 'x';
    end;
}
