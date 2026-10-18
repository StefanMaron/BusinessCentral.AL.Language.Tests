// @expect AL0173 | Operator '-' cannot be applied to an operand of type 'Boolean'
// Unary minus on a Boolean.
codeunit 59589 "MNC P 0589"
{
    procedure Run1()
    var
        Flag: Boolean;
    begin
        Flag := -Flag;
    end;
}
