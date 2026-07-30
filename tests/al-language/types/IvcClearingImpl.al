// Support codeunit for TestInterfaceVarCodeunitOut.al.
//
/// <summary>
/// Reproduces a document-writer prologue: Clear() the by-var result codeunit, then open
/// its stream — with and without an explicit TextEncoding. Both sit between the
/// caller's variable and the bytes.
/// </summary>
codeunit 60375 "Ivc Clearing Impl"
{
    procedure ProduceAfterClear(var Result: Codeunit "Temp Blob"; Payload: Text)
    var
        ResultOutStream: OutStream;
    begin
        Clear(Result);
        Result.CreateOutStream(ResultOutStream);
        ResultOutStream.WriteText(Payload);
    end;

    procedure ProduceWithEncoding(var Result: Codeunit "Temp Blob"; Payload: Text)
    var
        ResultOutStream: OutStream;
    begin
        Clear(Result);
        Result.CreateOutStream(ResultOutStream, TextEncoding::Windows);
        ResultOutStream.WriteText(Payload);
    end;
}
