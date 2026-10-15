// @expect AL0175 | Operator '-' cannot be applied to operands of type 'Text' and 'Text'
// A Text is subtracted from a Text.
codeunit 50091 "MNC C279"
{
    procedure Run1()
    var
        A: Text;
        B: Text;
        C: Text;
    begin
        C := A - B;
    end;
}
