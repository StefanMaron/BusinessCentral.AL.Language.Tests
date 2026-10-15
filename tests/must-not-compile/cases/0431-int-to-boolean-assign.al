// @expect AL0122 | Cannot implicitly convert type 'Integer' to 'Boolean'. Use an explicit conversion or change the type.
// An Integer is assigned to a Boolean.
codeunit 59431 "MNC P79 0431"
{
    procedure Run1()
    var
        B: Boolean;
        I: Integer;
    begin
        B := I;
    end;
}
