// @expect AL0104 | Syntax error, ')' expected
// @expect AL0162 | '' is not a valid trigger for this object type. Check the object documentation for supported triggers.
// @expect AL0107 | Syntax error, identifier expected. Provide a valid name (letters, digits, and underscores only).
// @expect AL0104 | Syntax error, '(' expected
// @expect AL0104 | Syntax error, ':' expected
// @expect AL0107 | Syntax error, identifier expected. Provide a valid name (letters, digits, and underscores only).
// @expect AL0107 | Syntax error, identifier expected. Provide a valid name (letters, digits, and underscores only).
// @expect AL0104 | Syntax error, ':' expected
// @expect AL0105 | Syntax error, identifier expected; 'trigger' is a keyword
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0162 | '' is not a valid trigger for this object type. Check the object documentation for supported triggers.
// @expect AL0107 | Syntax error, identifier expected. Provide a valid name (letters, digits, and underscores only).
// @expect AL0104 | Syntax error, '(' expected
// @expect AL0104 | Syntax error, ':' expected
// @expect AL0107 | Syntax error, identifier expected. Provide a valid name (letters, digits, and underscores only).
// The keyword trigger as an unquoted parameter name: by value in codeunit "MNC QT 2018 Value" and after var in "MNC QT 2018 Var".
// The first diagnostic of each procedure is the one at the name; the rest come from the compiler's error recovery.
// Probe: al-runtime-rs PR 5656 (writer QT); measured with AL 30.0.42.60748-beta for BC 27, 28 and 29.
codeunit 50004 "MNC QT 2018 Value"
{
    procedure P1(trigger: Integer)
    begin
    end;
}

codeunit 50005 "MNC QT 2018 Var"
{
    procedure P2(var trigger: Integer)
    begin
    end;
}
