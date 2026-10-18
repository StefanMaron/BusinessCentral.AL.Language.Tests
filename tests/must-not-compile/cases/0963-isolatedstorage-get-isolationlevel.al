// @expect AL0126 | No overload for method 'Get' takes 4 arguments
// @until 28
// IsolatedStorage.Get with an IsolationLevel exists from BC 29. On BC 29 the call needs runtime 18.0, which the corpus app does not use (case 0998).
codeunit 58975 "MNC IsoGet 0963"
{
    procedure Run1(): Boolean
    var
        Value: Text;
    begin
        exit(IsolatedStorage.Get('key', DataScope::Module, IsolationLevel::ReadCommitted, Value));
    end;
}
