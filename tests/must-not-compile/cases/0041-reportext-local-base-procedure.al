// @expect AL0161 | 'SecretLocal()' is inaccessible due to its protection level
// A report extension names a variable, a local procedure, or repeats the signature of a procedure of its base report (the page extension forms are cases 0001 to 0003).
table 50000 "MNC Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

report 50001 "MNC Base Report"
{
    dataset { dataitem(Row; "MNC Table") { column(Id; Id) { } } }

    local procedure SecretLocal(): Integer
    begin
        exit(1);
    end;
}

reportextension 50002 "MNC Base Report Ext" extends "MNC Base Report"
{
    trigger OnPreReport()
    var
        V: Integer;
    begin
        V := SecretLocal();
    end;
}
