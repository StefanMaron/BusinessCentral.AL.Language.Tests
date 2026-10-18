// @expect AL0110 | Orphaned ELSE statement.
// A semicolon (the empty statement) between the then branch and else ends the if: else has no if.
codeunit 59593 "MNC P 0593"
{
    procedure Run1()
    var
        N: Integer;
    begin
        if true then
            ;
        else
            N := 2;
    end;
}
