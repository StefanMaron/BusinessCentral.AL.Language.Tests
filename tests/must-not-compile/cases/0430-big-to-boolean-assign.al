// @expect AL0122 | Cannot implicitly convert type 'BigInteger' to 'Boolean'. Use an explicit conversion or change the type.
// A BigInteger is assigned to a Boolean.
codeunit 59430 "MNC P79 0430"
{
    procedure Run1()
    var
        B: Boolean;
        Big: BigInteger;
    begin
        B := Big;
    end;
}
