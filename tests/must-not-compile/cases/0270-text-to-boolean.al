// @expect AL0122 | Cannot implicitly convert type 'Text' to 'Boolean'. Use an explicit conversion or change the type.
// A Text literal is assigned to a Boolean.
codeunit 50081 "MNC C270"
{
    procedure Run1()
    var
        B: Boolean;
    begin
        B := 'true';
    end;
}
