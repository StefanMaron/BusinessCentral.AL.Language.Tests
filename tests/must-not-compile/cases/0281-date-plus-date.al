// @expect AL0175 | Operator '+' cannot be applied to operands of type 'Date' and 'Date'
// Two Dates are added.
codeunit 50093 "MNC C281"
{
    procedure Run1()
    var
        A: Date;
        B: Date;
        C: Date;
    begin
        C := A + B;
    end;
}
