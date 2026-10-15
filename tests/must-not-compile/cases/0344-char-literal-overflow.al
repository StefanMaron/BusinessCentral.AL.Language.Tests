// @expect AL0369 | Constant value '70000' cannot be converted to a 'Char'.
// A Char variable assigned 70000.
codeunit 50162 "MNC C344"
{
    procedure Run1()
    var
        C: Char;
    begin
        C := 70000;
    end;
}
