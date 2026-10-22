// @expect AL0104 | Syntax error, 'then' expected
// An if without then.
codeunit 50147 "MNC C329"
{
    procedure Run1()
    var
        I: Integer;
    begin
        if I = 1
            I := 2;
    end;
}
