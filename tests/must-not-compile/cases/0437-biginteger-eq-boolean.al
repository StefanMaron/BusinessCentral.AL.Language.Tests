// @expect AL0175 | Operator '=' cannot be applied to operands of type 'BigInteger' and 'Boolean'
// A BigInteger is compared with a Boolean.
codeunit 59437 "MNC P79 0437"
{
    procedure Run1()
    var
        B: Boolean;
        Big: BigInteger;
        R: Boolean;
    begin
        R := Big = B;
    end;
}
