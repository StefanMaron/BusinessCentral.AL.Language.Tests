// @expect AL0111 | Semicolon expected.
// A decimal literal in scientific notation.
codeunit 59582 "MNC P 0582"
{
    procedure Run1()
    var
        Dec: Decimal;
    begin
        Dec := 1.5e3;
    end;
}
