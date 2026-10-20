// @expect AL0224 | Expression expected. Provide a valid expression (variable, constant, calculation, or method call).
// @expect AL0104 | Syntax error, ',' expected
// Record.Get cannot skip a key value in the middle: an empty argument is a syntax error (corpus issue 668). Get with fewer values than key
// fields (trailing values left out) compiles; its run-time result is pinned in tests/al-language/record/lt-record-read/RcAGetFind.al.
table 50456 "MNC T1453"
{
    fields
    {
        field(1; A; Code[10]) { }
        field(2; B; Integer) { }
        field(3; C; Date) { }
    }
    keys { key(PK; A, B, C) { Clustered = true; } }
}

codeunit 50457 "MNC C1453"
{
    procedure Run1()
    var
        R: Record "MNC T1453";
    begin
        R.Get('A', , 0D);
    end;
}
