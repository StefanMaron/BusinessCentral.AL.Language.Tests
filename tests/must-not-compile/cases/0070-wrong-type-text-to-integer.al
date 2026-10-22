// @expect AL0122 | Cannot implicitly convert type 'Text' to 'Integer'
// Assigning a Text literal to an Integer variable.
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
        I := 'text';
    end;
}
