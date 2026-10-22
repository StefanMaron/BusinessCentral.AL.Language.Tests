// @expect AL0130 | A 'var' argument must be an assignable variable (field, variable, or parameter), not a constant or expression.
// An expression is passed for a var parameter.
codeunit 50163 "MNC C345"
{
    local procedure Take(var A: Integer)
    begin
    end;

    procedure Run1()
    begin
        Take(1 + 2);
    end;
}
