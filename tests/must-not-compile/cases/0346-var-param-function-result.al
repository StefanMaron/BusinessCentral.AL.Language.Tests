// @expect AL0130 | A 'var' argument must be an assignable variable (field, variable, or parameter), not a constant or expression.
// A function result is passed for a var parameter.
codeunit 50164 "MNC C346"
{
    local procedure Take(var A: Integer)
    begin
    end;

    local procedure Give(): Integer
    begin
    end;

    procedure Run1()
    begin
        Take(Give());
    end;
}
