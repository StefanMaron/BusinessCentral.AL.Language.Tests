// @expect AL0175 | Operator '-' cannot be applied to operands of type 'Char' and 'Text'
// @expect AL0175 | Operator '-' cannot be applied to operands of type 'Char' and 'Text'
// @expect AL0175 | Operator '-' cannot be applied to operands of type 'Text' and 'Char'
// @expect AL0175 | Operator '-' cannot be applied to operands of type 'Text' and 'Char'
// A Char minus a Text literal of two characters or of none, and the same literals minus a Char, do not compile. A one-character literal does (types/lt-af-char-literal/AfCharLiteralArithmetic.al).
codeunit 50995 "MNC AF Char Minus Long Literal"
{
    procedure Probe(): Integer
    var
        C: Char;
        I: Integer;
    begin
        C := 'a';
        I := C - 'AB';
        I := C - '';
        I := 'AB' - C;
        I := '' - C;
        exit(I);
    end;
}
