// @expect AL0175 | Operator '+' cannot be applied to operands of type 'Text' and 'Integer'
// A Text and an Integer added.
codeunit 59590 "MNC P 0590"
{
    procedure Run1()
    var
        T: Text;
        I: Integer;
    begin
        T := T + I;
    end;
}
