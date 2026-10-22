// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'String' of 'Evaluate(var Joker, Text, [Integer])'
// Evaluate is called with one argument.
codeunit 50058 "MNC C252"
{
    procedure Run1()
    var
        I: Integer;
    begin
        Evaluate(I);
    end;
}
