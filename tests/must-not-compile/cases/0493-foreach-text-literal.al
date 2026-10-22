// @expect AL0421 | A ‘foreach’ statement can only be used with an expression of an enumerable type.
// foreach over a Text literal is refused: a Text literal is not an enumerable expression (a Text variable, a Code variable and a Label are: text/lt-foreach-text/ForeachText.al).
codeunit 50993 "MNC Foreach Text Literal"
{
    procedure Probe(): Integer
    var
        Ch: Char;
        Count: Integer;
    begin
        foreach Ch in 'a+/=b' do
            Count += 1;
        exit(Count);
    end;
}
