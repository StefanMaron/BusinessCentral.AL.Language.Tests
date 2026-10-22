// @expect AL0161 | 'BaseVar' is inaccessible due to its protection level
// this.<variable of the base> inside a report extension when the base variable is not protected.
table 50000 "MNC Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

report 50001 "MNC Base Report"
{
    dataset { dataitem(Row; "MNC Table") { } }

    var
        BaseVar: Text;
}

reportextension 50002 "MNC Base Report Ext" extends "MNC Base Report"
{
    trigger OnPreReport()
    begin
        this.BaseVar := 'x';
    end;
}
