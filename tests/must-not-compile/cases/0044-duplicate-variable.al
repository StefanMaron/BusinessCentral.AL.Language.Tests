// @expect AL0121 | The variable name 'I' is already defined.
// Two variables of one name in one scope.
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
        I: Text;
    begin
        I := 1;
    end;
}
