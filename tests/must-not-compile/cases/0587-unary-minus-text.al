// @expect AL0173 | Operator '-' cannot be applied to an operand of type 'Text'
// Unary minus on a Text.
codeunit 59587 "MNC P 0587"
{
    procedure Run1()
    var
        T: Text;
    begin
        T := -T;
    end;
}
