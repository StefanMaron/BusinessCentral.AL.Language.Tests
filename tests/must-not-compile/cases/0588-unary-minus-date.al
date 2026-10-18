// @expect AL0173 | Operator '-' cannot be applied to an operand of type 'Date'
// Unary minus on a Date.
codeunit 59588 "MNC P 0588"
{
    procedure Run1()
    var
        D: Date;
    begin
        D := -D;
    end;
}
