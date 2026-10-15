// @expect AL0175 | Operator '*' cannot be applied to operands of type 'Text' and 'Integer'
// A Text is multiplied by an Integer.
codeunit 50092 "MNC C280"
{
    procedure Run1()
    var
        A: Text;
        I: Integer;
        C: Text;
    begin
        C := A * I;
    end;
}
