// @expect AL0191 | Constant value '20261301D' is outside the range for a Date.
// A date literal with month 13.
codeunit 59595 "MNC P 0595"
{
    procedure Run1()
    var
        D: Date;
    begin
        D := 20261301D;
    end;
}
