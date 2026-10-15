// @expect AL0122 | Cannot implicitly convert type 'Integer' to 'Boolean'. Use an explicit conversion or change the type.
// An Integer is assigned to a Boolean.
codeunit 50074 "MNC C265"
{
    procedure Run1()
    var
        I: Integer;
        B: Boolean;
    begin
        B := I;
    end;
}
