// @expect AL0104 | Syntax error, ';' expected
// @expect AL0104 | Syntax error, 'end' expected
// A procedure body whose begin has no end (two begins).
codeunit 50148 "MNC C330"
{
    procedure Run1()
    begin
        begin
    end;
}
