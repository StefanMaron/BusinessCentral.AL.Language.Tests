// @expect AL0104 | Syntax error, ',' expected
// @expect AL0104 | Syntax error, ']' expected
// Corpus issue 670 item 2 (microsoft/AL#5827): Dictionary of [Guid, Option "a","b"] does not parse either.
codeunit 50745 "MNC C1745"
{
    procedure Run1()
    var
        D: Dictionary of [Guid, Option "a","b"];
    begin
    end;
}
