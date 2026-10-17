// @expect AL0122 | Cannot implicitly convert type 'BigInteger' to 'Enum "MNC BE Enum 0451"'
// @until 28
// A BigInteger is assigned to an Enum variable (an Option variable accepts it). AL 18 (BC 29) accepts it, see tests/al-language/types/lt-bigint-enum-option.
enum 59880 "MNC BE Enum 0451"
{
    value(0; Zero) { }
    value(1; One) { }
}

codeunit 59881 "MNC BE 0451"
{
    procedure Run1()
    var
        E: Enum "MNC BE Enum 0451";
        Big: BigInteger;
    begin
        E := Big;
    end;
}
