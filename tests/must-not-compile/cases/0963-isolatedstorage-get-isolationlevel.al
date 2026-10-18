// @expect AL0126 | No overload for method 'Get' takes 4 arguments
// @until 28
// @max-al 17
// IsolatedStorage.Get with an IsolationLevel exists from BC 29. Runtime tests for BC 29: tests/al-language/lt-ac.
codeunit 58975 "MNC IsoGet 0963"
{
    procedure Run1(): Boolean
    var
        Value: Text;
    begin
        exit(IsolatedStorage.Get('key', DataScope::Module, IsolationLevel::ReadCommitted, Value));
    end;
}
