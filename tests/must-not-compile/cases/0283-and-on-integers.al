// @expect AL0175 | Operator 'and' cannot be applied to operands of type 'Integer' and 'Integer'
// The and operator is applied to two Integers.
codeunit 50095 "MNC C283"
{
    procedure Run1()
    var
        A: Integer;
        B: Integer;
        C: Boolean;
    begin
        C := A and B;
    end;
}
