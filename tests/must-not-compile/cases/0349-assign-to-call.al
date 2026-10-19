// @expect AL0129 | The left-hand side of an assignment must be a variable or field
// A procedure call is the target of an assignment.
codeunit 50167 "MNC C349"
{
    local procedure Give(): Integer
    begin
    end;

    procedure Run1()
    begin
        Give() := 1;
    end;
}
