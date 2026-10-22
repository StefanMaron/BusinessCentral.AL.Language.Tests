// @expect AL0117 | Illegal statement. Only assignment and method invocation can be used as a statement.
// Writer QW (corpus issue 685): a conditional expression whose branches are procedure calls is not a statement on its own.
codeunit 52070 "MNC QW Ternary Statement"
{
    procedure Run1(Cond: Boolean)
    begin
        Cond ? Take(1) : Take(2);
    end;

    local procedure Take(X: Integer): Integer
    begin
        exit(X);
    end;
}
