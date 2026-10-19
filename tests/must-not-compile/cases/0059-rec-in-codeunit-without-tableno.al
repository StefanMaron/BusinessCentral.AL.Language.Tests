// @expect AL0118 | The name 'Rec' does not exist in the current context.
// Rec in a codeunit that has no TableNo.
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
    begin
        Rec.Id := 1;
    end;
}
