// @expect AL0105 | Syntax error, identifier expected; 'end' is a keyword
// @expect AL0104 | Syntax error, ':' expected
// @expect AL0107 | Syntax error, identifier expected. Provide a valid name (letters, digits, and underscores only).
// @expect AL0107 | Syntax error, identifier expected. Provide a valid name (letters, digits, and underscores only).
// @expect AL0104 | Syntax error, ':' expected
// @expect AL0105 | Syntax error, identifier expected; 'end' is a keyword
// @expect AL0104 | Syntax error, ';' expected
// The keyword end as an unquoted parameter name: by value in codeunit "MNC QT 2019 Value" and after var in "MNC QT 2019 Var".
// The first diagnostic of each procedure is the one at the name; the rest come from the compiler's error recovery.
// Probe: al-runtime-rs PR 5656 (writer QT); measured with AL 30.0.42.60748-beta for BC 27, 28 and 29.
codeunit 50006 "MNC QT 2019 Value"
{
    procedure P1(end: Integer)
    begin
    end;
}

codeunit 50007 "MNC QT 2019 Var"
{
    procedure P2(var end: Integer)
    begin
    end;
}
