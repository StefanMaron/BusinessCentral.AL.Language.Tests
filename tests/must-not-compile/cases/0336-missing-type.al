// @expect AL0107 | Syntax error, identifier expected. Provide a valid name (letters, digits, and underscores only).
// A variable declaration without a type.
codeunit 50154 "MNC C336"
{
    procedure Run1()
    var
        X: ;
    begin
    end;
}
