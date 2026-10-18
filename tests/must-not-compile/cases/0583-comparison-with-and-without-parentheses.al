// @expect AL0175 | Operator 'and' cannot be applied to operands of type 'Integer' and 'Integer'
// and binds tighter than <: the comparison needs parentheses.
codeunit 59583 "MNC P 0583"
{
    procedure Run1()
    var
        A: Integer;
        B: Integer;
        C: Integer;
    begin
        if A < B and B < C then
            exit;
    end;
}
