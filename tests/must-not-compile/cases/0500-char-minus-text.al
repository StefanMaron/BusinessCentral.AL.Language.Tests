// @expect AL0175 | Operator '-' cannot be applied to operands of type 'Char' and 'Text'
// @expect AL0175 | Operator '-' cannot be applied to operands of type 'Text' and 'Char'
// Subtraction is not defined between a Char and a Text, in either order (issue 580 item 4). The compiler refuses both statements, so there is no runtime result to pin.
codeunit 50994 "MNC Char Minus Text"
{
    procedure Probe(): Text
    var
        C: Char;
        T: Text;
        R: Text;
    begin
        C := 'a';
        T := 'bc';
        R := Format(C - T);
        R := Format(T - C);
        exit(R);
    end;
}
