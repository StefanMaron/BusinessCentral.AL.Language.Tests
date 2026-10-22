// @expect AL0122 | Cannot implicitly convert type 'BigInteger' to 'Boolean'. Use an explicit conversion or change the type.
// A BigInteger is used as the condition of an if.
codeunit 59438 "MNC P79 0438"
{
    procedure Run1()
    var
        Big: BigInteger;
    begin
        if Big then
            exit;
    end;
}
