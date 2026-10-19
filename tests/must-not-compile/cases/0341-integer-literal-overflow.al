// @expect AL0103 | Constant value '3000000000' is outside the range for an Integer
// An Integer variable assigned the literal 3000000000.
codeunit 50159 "MNC C341"
{
    procedure Run1()
    var
        I: Integer;
    begin
        I := 3000000000;
    end;
}
