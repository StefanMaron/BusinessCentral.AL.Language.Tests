// @expect AL0104 | Syntax error, '(' expected
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, ':' expected
// @expect AL0104 | Syntax error, 'procedure' expected
// @expect AL0107 | Syntax error, identifier expected. Provide a valid name (letters, digits, and underscores only).
// @expect AL0107 | Syntax error, identifier expected. Provide a valid name (letters, digits, and underscores only).
// @expect AL0301 | A list must end with a member; not a separator ;.
// A protected variable of another codeunit is read.
codeunit 50176 "MNC C357"
{
    var
        protected Hidden: Integer;
}

codeunit 50177 "MNC D357"
{
    procedure Run1()
    var
        C: Codeunit "MNC C357";
        I: Integer;
    begin
        I := C.Hidden;
    end;
}
