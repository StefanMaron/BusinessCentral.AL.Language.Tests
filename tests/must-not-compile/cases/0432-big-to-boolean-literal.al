// @expect AL0122 | Cannot implicitly convert type 'Integer' to 'Boolean'. Use an explicit conversion or change the type.
// The integer literal 1 is assigned to a Boolean.
codeunit 59432 "MNC P79 0432"
{
    procedure Run1()
    var
        B: Boolean;
    begin
        B := 1;
    end;
}
