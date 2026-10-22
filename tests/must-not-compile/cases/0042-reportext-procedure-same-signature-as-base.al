// @expect AL0440 | The Report 'MNC Base Report' already defines a method called 'Bump' with the same parameter types in 'Must Not Compile by AL Language (1.0.0.0)'.
// A report extension names a variable, a local procedure, or repeats the signature of a procedure of its base report (the page extension forms are cases 0001 to 0003).
table 50000 "MNC Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

report 50001 "MNC Base Report"
{
    dataset { dataitem(Row; "MNC Table") { column(Id; Id) { } } }

    protected procedure Bump(): Integer
    begin
        exit(1);
    end;
}

reportextension 50002 "MNC Base Report Ext" extends "MNC Base Report"
{
    procedure Bump(): Integer
    begin
        exit(2);
    end;
}
