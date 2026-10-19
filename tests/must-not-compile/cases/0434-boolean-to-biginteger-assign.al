// @expect AL0122 | Cannot implicitly convert type 'Boolean' to 'BigInteger'. Use an explicit conversion or change the type.
// A Boolean is assigned to a BigInteger.
codeunit 59434 "MNC P79 0434"
{
    procedure Run1()
    var
        B: Boolean;
        Big: BigInteger;
    begin
        Big := B;
    end;
}
