// @expect AL0175 | Operator '+' cannot be applied to operands of type 'Date' and 'Date'
// Two Dates added.
codeunit 59591 "MNC P 0591"
{
    procedure Run1()
    var
        D: Date;
    begin
        D := D + D;
    end;
}
