// @expect AL0119 | The parameter name 'A' is already defined.
// A procedure has two parameters of the same name.
codeunit 50111 "MNC C298"
{
    local procedure Take(A: Integer; A: Text)
    begin
    end;

    procedure Run1()
    begin
    end;
}
