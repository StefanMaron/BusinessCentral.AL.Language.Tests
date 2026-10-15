// @expect AL0133 | Argument 1: cannot convert from 'BigInteger' to 'Boolean'
// A BigInteger is passed to a Boolean parameter.
codeunit 59439 "MNC P79 0439"
{
    procedure Run1()
    var
        Big: BigInteger;
    begin
        TakeBool(Big);
    end;

    local procedure TakeBool(B: Boolean)
    begin
    end;
}
