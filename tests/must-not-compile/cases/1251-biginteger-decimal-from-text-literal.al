// @expect AL0122 | Cannot implicitly convert type 'Text' to 'BigInteger'
// @expect AL0122 | Cannot implicitly convert type 'Text' to 'Decimal'
// A two-character literal ('xy', a Text) assigned to a BigInteger and to a Decimal. A one-character literal ('x') is a Char and compiles:
// tests/al-language/types/lt-bb-char-literal-numbers. (2 diagnostics)
codeunit 50000 "MNC BB Codeunit"
{
    procedure DoIt()
    var
        BI: BigInteger;
        D: Decimal;
    begin
        BI := 'xy';
        D := 'xy';
    end;
}
