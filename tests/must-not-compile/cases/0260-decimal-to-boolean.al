// @expect AL0122 | Cannot implicitly convert type 'Decimal' to 'Boolean'. Use an explicit conversion or change the type.
// A Decimal is assigned to a Boolean.
codeunit 50068 "MNC C260"
{
    procedure Run1()
    var
        B: Boolean;
        D: Decimal;
    begin
        B := D;
    end;
}
