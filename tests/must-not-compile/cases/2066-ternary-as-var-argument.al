// @expect AL0130 | A 'var' argument must be an assignable variable (field, variable, or parameter), not a constant or expression.
// Writer QW (corpus issue 685): a conditional expression is not assignable, so it cannot be passed for a var parameter. By value it compiles
// (QW_Ternary_Contexts in tests/al-language/types/TestTernaryContracts.al).
codeunit 52068 "MNC QW Ternary Var Arg"
{
    procedure Run1(Cond: Boolean)
    var
        A: Integer;
        B: Integer;
    begin
        TakeVar(Cond ? A : B);
    end;

    local procedure TakeVar(var X: Integer)
    begin
        X := 1;
    end;
}
