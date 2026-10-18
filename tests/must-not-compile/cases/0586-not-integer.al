// @expect AL0173 | Operator 'not' cannot be applied to an operand of type 'Integer'
// not on an Integer.
codeunit 59586 "MNC P 0586"
{
    procedure Run1()
    var
        I: Integer;
        Flag: Boolean;
    begin
        Flag := not I;
    end;
}
