// @expect AL0122 | Cannot implicitly convert type 'Integer' to 'Boolean'. Use an explicit conversion or change the type.
// An Integer is used as the condition of an if.
codeunit 50098 "MNC C285"
{
    procedure Run1()
    var
        I: Integer;
    begin
        if I then
            I := 0;
    end;
}
