// @expect AL0175 | Operator '=' cannot be applied to operands of type 'Option' and 'Boolean'
// An Option is compared with a Boolean.
codeunit 59447 "MNC P79 0447"
{
    procedure Run1()
    var
        O: Option A,B,C;
        B: Boolean;
        R: Boolean;
    begin
        R := O = B;
    end;
}
