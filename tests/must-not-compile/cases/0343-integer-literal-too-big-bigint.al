// @expect AL0103 | Constant value '99999999999999999999' is outside the range for an Integer
// A literal larger than BigInteger.
codeunit 50161 "MNC C343"
{
    procedure Run1()
    var
        I: BigInteger;
    begin
        I := 99999999999999999999;
    end;
}
