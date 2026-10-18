// @expect AL0175 | Operator '+' cannot be applied to operands of type 'Boolean' and 'Boolean'
// Two Booleans added.
codeunit 59592 "MNC P 0592"
{
    procedure Run1()
    var
        Flag: Boolean;
    begin
        Flag := Flag + Flag;
    end;
}
