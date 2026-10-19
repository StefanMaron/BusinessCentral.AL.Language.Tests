// @expect AL0117 | Illegal statement. Only assignment and method invocation can be used as a statement.
// An assignment written with = instead of :=.
codeunit 50156 "MNC C338"
{
    procedure Run1()
    var
        I: Integer;
    begin
        I = 1;
    end;
}
