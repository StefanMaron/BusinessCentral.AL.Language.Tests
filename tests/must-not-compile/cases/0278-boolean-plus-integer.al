// @expect AL0175 | Operator '+' cannot be applied to operands of type 'Boolean' and 'Integer'
// A Boolean and an Integer are added.
codeunit 50090 "MNC C278"
{
    procedure Run1()
    var
        B: Boolean;
        I: Integer;
    begin
        I := B + I;
    end;
}
