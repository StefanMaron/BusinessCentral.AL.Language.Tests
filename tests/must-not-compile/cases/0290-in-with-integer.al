// @expect AL0104 | Syntax error, '[' expected
// @expect AL0104 | Syntax error, ']' expected
// The in operator is used with an Integer on the right side.
codeunit 50103 "MNC C290"
{
    procedure Run1()
    var
        I: Integer;
        B: Boolean;
    begin
        B := 1 in I;
    end;
}
