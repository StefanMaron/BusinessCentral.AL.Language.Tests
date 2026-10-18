// @expect AL0172 | Operator '-' is ambiguous on an operand of type 'Duration'
// Unary minus on a Duration.
codeunit 59584 "MNC P 0584"
{
    procedure Run1()
    var
        Dur: Duration;
    begin
        Dur := -Dur;
    end;
}
