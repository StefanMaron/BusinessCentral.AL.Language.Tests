// @expect AL0152 | The value 'A' is used more than once
// A procedure whose Option variable repeats a member.
table 50000 "MNC Table"
{
    fields { field(1; Id; Integer) { } field(2; Name; Text[30]) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 50001 "MNC Codeunit"
{
    procedure DoIt()
    var
        I: Integer;
        T: Text;
        R: Record "MNC Table";
        O: Option A,B,A;
    begin
        I := 1;
    end;
}
