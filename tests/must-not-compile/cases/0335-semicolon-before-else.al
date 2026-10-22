// @expect AL0110 | Orphaned ELSE statement. This is most likely because of an unnecessary semicolon placed just before the ELSE keyword
// A semicolon before else.
codeunit 50153 "MNC C335"
{
    procedure Run1()
    var
        I: Integer;
    begin
        if I = 1 then
            I := 2;
        else
            I := 3;
    end;
}
