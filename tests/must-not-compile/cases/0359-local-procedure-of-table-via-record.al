// @expect AL0161 | 'Secret()' is inaccessible due to its protection level
// A local procedure of a table is called through a record.
table 50180 "MNC T359"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
    local procedure Secret()
    begin
    end;
}

codeunit 50181 "MNC D359"
{
    procedure Run1()
    var
        R: Record "MNC T359";
    begin
        R.Secret();
    end;
}
