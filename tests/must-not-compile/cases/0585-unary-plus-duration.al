// @expect AL0172 | Operator '+' is ambiguous on an operand of type 'Duration'
// Unary plus on a Duration.
codeunit 59585 "MNC P 0585"
{
    procedure Run1()
    var
        Dur: Duration;
    begin
        Dur := +Dur;
    end;
}
