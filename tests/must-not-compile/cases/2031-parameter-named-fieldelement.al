// @expect AL0105 | Syntax error, identifier expected; 'fieldelement' is a keyword
// @expect AL0104 | Syntax error, ':' expected
// @expect AL0107 | Syntax error, identifier expected. Provide a valid name (letters, digits, and underscores only).
// @expect AL0107 | Syntax error, identifier expected. Provide a valid name (letters, digits, and underscores only).
// @expect AL0104 | Syntax error, ':' expected
// @expect AL0105 | Syntax error, identifier expected; 'fieldelement' is a keyword
// @expect AL0104 | Syntax error, ';' expected
// The keyword fieldelement as an unquoted parameter name: by value in codeunit "MNC QT 2031 Value" and after var in "MNC QT 2031 Var".
// The first diagnostic of each procedure is the one at the name; the rest come from the compiler's error recovery.
// Probe: al-runtime-rs PR 5656 (writer QT); measured with AL 30.0.42.60748-beta for BC 27, 28 and 29.
codeunit 50030 "MNC QT 2031 Value"
{
    procedure P1(fieldelement: Integer)
    begin
    end;
}

codeunit 50031 "MNC QT 2031 Var"
{
    procedure P2(var fieldelement: Integer)
    begin
    end;
}
