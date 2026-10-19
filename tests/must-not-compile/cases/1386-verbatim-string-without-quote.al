// @expect AL0224 | Expression expected. Provide a valid expression (variable, constant, calculation, or method call).
// @expect AL0870 | Expected verbatim string literal.
// @expect AL0111 | Semicolon expected. Add a semicolon (;) to terminate the statement.
// Corpus #664 item 11. An @ that is not followed by a quote (@abc) is AL0870 with AL0224 and AL0111. (An unterminated verbatim
// string @'abc is AL0360 "Text literal was not properly terminated", and the parser then reports AL0104 up to the end of the file.)
codeunit 51386 "MNC BM C1386"
{
    procedure Q()
    var
        t: Text;
    begin
        t := @abc;
    end;
}
