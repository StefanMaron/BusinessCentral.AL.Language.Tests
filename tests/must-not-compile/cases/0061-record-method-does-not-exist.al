// @expect AL0132 | 'Record "MNC Table"' does not contain a definition for 'NoSuchMethod'
// Calling a method the Record type does not have.
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
        R.NoSuchMethod();
    end;
}
