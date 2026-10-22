// @expect AL0107 | Syntax error, identifier expected. Provide a valid name (letters, digits, and underscores only).
// @expect AL0104 | Syntax error, ']' expected
// Corpus issue 670 item 2 (microsoft/AL#5827): Option is not a type argument of Dictionary; the parser wants option members after Option.
codeunit 50744 "MNC C1744"
{
    procedure Run1()
    var
        D: Dictionary of [Guid, Option];
    begin
    end;
}
