// @expect AL0122 | Cannot implicitly convert type 'Option' to 'Boolean'. Use an explicit conversion or change the type.
// An Option is used as the condition of an if.
codeunit 59448 "MNC P79 0448"
{
    procedure Run1()
    var
        O: Option A,B,C;
    begin
        if O then
            exit;
    end;
}
