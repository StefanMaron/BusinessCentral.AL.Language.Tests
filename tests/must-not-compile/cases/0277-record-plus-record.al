// @expect AL0175 | Operator '+' cannot be applied to operands of type 'Record "MNC T277"' and 'Record "MNC T277"'
// Two Records are added.
table 50088 "MNC T277"
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

codeunit 50089 "MNC C277"
{
    procedure Run1()
    var
        A: Record "MNC T277";
        B: Record "MNC T277";
        I: Integer;
    begin
        I := A + B;
    end;
}
