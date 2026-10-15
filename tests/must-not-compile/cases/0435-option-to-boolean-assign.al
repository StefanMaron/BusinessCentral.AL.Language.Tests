// @expect AL0122 | Cannot implicitly convert type 'Option' to 'Boolean'. Use an explicit conversion or change the type.
// An Option is assigned to a Boolean.
codeunit 59435 "MNC P79 0435"
{
    procedure Run1()
    var
        B: Boolean;
        O: Option A,B,C;
    begin
        B := O;
    end;
}
