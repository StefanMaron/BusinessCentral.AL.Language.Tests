// @expect AL0132 | 'Record "MNC T227"' does not contain a definition for 'Insertt'
// Record has no Insertt method.
table 50032 "MNC T227"
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

codeunit 50033 "MNC C227"
{
    procedure Run1()
    var
        R: Record "MNC T227";
    begin
        R.Insertt();
    end;
}
