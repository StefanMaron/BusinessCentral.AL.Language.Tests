// @expect AL0103 | Constant value '9223372036854775807' is outside the range for an Integer
// A BigInteger literal above the Integer range written without the L suffix.
codeunit 59580 "MNC P 0580"
{
    procedure Run1()
    var
        Big: BigInteger;
    begin
        Big := 9223372036854775807;
    end;
}
