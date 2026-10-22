// @expect AL0132 | 'Record "MNC T203"' does not contain a definition for 'Missing'
// A field that the table does not have is assigned.
table 50004 "MNC T203"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; D; Date) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 50005 "MNC C203"
{
    procedure Run1()
    var
        R: Record "MNC T203";
    begin
        R.Missing := 1;
    end;
}
