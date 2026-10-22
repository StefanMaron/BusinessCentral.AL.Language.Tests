// @expect AL0175 | Operator '=' cannot be applied to operands of type 'Record "MNC T284"' and 'Integer'
// A Record is compared to an Integer.
table 50096 "MNC T284"
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

codeunit 50097 "MNC C284"
{
    procedure Run1()
    var
        A: Record "MNC T284";
        B: Boolean;
    begin
        B := A = 1;
    end;
}
