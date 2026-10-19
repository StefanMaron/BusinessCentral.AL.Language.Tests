// @expect AL0244 | The signature of procedure 'Foo' does not match the signature required by attribute 'TryFunction': return value is expected to be of type 'None' but found type 'Integer'. The expected signature is: Foo().
// A TryFunction with a return value.
codeunit 50000 "MNC Try"
{
    [TryFunction]
    procedure Foo(): Integer
    begin
        exit(1);
    end;
}
