// @expect AL0173 | Operator 'not' cannot be applied to an operand of type 'Text'
// The not operator is applied to a Text.
codeunit 50094 "MNC C282"
{
    procedure Run1()
    var
        A: Text;
        B: Boolean;
    begin
        B := not A;
    end;
}
