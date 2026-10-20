// @expect AL0371 | The operation overflows at compile time.
// A BigInteger variable assigned the product of Integer literals 30 * 24 * 60 * 60 * 1000 = 2,592,000,000 (microsoft/AL issue 5718):
// the product is computed as Integer at compile time and overflows, although the target is a BigInteger.
codeunit 51444 "MNC BP C1444"
{
    procedure P(): BigInteger
    var
        bigInt: BigInteger;
    begin
        bigInt := 30 * 24 * 60 * 60 * 1000;
        exit(bigInt);
    end;
}
