// @expect AL0224 | Expression expected. Provide a valid expression (variable, constant, calculation, or method call).
// @expect AL0111 | Semicolon expected. Add a semicolon (;) to terminate the statement.
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0198 | Expected one of the application object keywords
// Corpus #664 items 23 and 24. Block comments do not nest: /* a /* b */ c */ ends at the first */, and ' c */' is then read as code
// (AL0224, AL0111). Braces are not a block comment in AL: a { ... } block inside a procedure body is a syntax error.
codeunit 51379 "MNC BM C1379"
{
    procedure Q(): Integer
    begin
        /* a /* b */ c */
        exit(1);
    end;

    procedure P(): Integer
    var
        i: Integer;
    begin
        i := 1;
        {
          i := 2;
        }
        exit(i);
    end;
}
