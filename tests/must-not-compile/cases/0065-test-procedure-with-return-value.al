// @expect AL0244 | The signature of procedure 'T' does not match the signature required by attribute 'Test': return value is expected to be of type 'None' but found type 'Integer'. The expected signature is: T().
// A [Test] procedure with a return value.
codeunit 50000 "MNC Test"
{
    Subtype = Test;

    [Test]
    procedure T(): Integer
    begin
        exit(1);
    end;
}
