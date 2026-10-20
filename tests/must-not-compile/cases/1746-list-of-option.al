// @expect AL0107 | Syntax error, identifier expected. Provide a valid name (letters, digits, and underscores only).
// @expect AL0104 | Syntax error, ']' expected
// Corpus issue 670 item 2 (microsoft/AL#5827): List of [Option] does not parse.
codeunit 50746 "MNC C1746"
{
    procedure Run1()
    var
        L: List of [Option];
    begin
    end;
}
