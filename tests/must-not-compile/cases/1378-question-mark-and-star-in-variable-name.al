// @expect AL0104 | Syntax error, ':' expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0107 | Syntax error, identifier expected. Provide a valid name (letters, digits, and underscores only).
// @expect AL0104 | Syntax error, ':' expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0107 | Syntax error, identifier expected. Provide a valid name (letters, digits, and underscores only).
// Corpus #664 item 22. 'my?Int' and 'my*Int' as variable names are both syntax errors with the same three diagnostics each
// (AL0104 twice and AL0107 at the '?' or '*'; the lead said AL0183 for '?' and nothing for '*').
codeunit 51378 "MNC BM C1378"
{
    procedure P()
    var
        my?Int: Integer;
    begin
    end;

    procedure Q()
    var
        my*Int: Integer;
    begin
    end;
}
