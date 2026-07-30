/// <summary>
/// Helper codeunit used by the AL call stack tests to produce a two-frame AL stack:
/// "AL Call Stack Helper(CodeUnit 60212).RaiseError" on top of the test frame.
/// </summary>
codeunit 60212 "AL Call Stack Helper"
{
    procedure RaiseError()
    begin
        Error('AL call stack test error');
    end;
}
