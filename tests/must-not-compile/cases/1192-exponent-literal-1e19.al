// @expect AL0111 | Semicolon expected. Add a semicolon (;) to terminate the statement.
// AL has no number literal with an exponent: D := 1e19 is a syntax error (issue 649 item 22). A Decimal of 1E19 assigned to a Duration
// at run time is in tests/al-language/types/lt-ax-text-format-dates/AxDurationDateTime.al.
codeunit 51192 "MNC AX Exponent Literal"
{
    procedure Probe(): Duration
    var
        D: Duration;
    begin
        D := 1e19;
        exit(D);
    end;
}
