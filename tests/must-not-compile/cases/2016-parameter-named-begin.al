// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0111 | Semicolon expected. Add a semicolon (;) to terminate the statement.
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0107 | Syntax error, identifier expected. Provide a valid name (letters, digits, and underscores only).
// @expect AL0104 | Syntax error, ':' expected
// @expect AL0105 | Syntax error, identifier expected; 'begin' is a keyword
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0111 | Semicolon expected. Add a semicolon (;) to terminate the statement.
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, ';' expected
// The keyword begin as an unquoted parameter name: by value in codeunit "MNC QT 2016 Value" and after var in "MNC QT 2016 Var".
// The first diagnostic of each procedure is the one at the name; the rest come from the compiler's error recovery.
// Probe: al-runtime-rs PR 5656 (writer QT); measured with AL 30.0.42.60748-beta for BC 27, 28 and 29.
codeunit 50000 "MNC QT 2016 Value"
{
    procedure P1(begin: Integer)
    begin
    end;
}

codeunit 50001 "MNC QT 2016 Var"
{
    procedure P2(var begin: Integer)
    begin
    end;
}
