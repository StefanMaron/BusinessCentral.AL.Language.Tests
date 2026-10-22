// @expect AL0121 | The variable name 'A' is already defined.
// A local variable has the name of a parameter.
codeunit 50117 "MNC C303"
{
    local procedure Take(A: Integer)
    var
        A: Integer;
    begin
    end;

    procedure Run1()
    begin
    end;
}
