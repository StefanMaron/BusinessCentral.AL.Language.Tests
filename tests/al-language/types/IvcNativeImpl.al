// Support codeunit for TestInterfaceVarCodeunitOut.al — implements "IIvc Backend".

codeunit 60374 "Ivc Native Impl" implements "IIvc Backend"
{
    procedure Produce(var Result: Codeunit "Temp Blob"; Payload: Text)
    var
        ResultOutStream: OutStream;
    begin
        Result.CreateOutStream(ResultOutStream);
        ResultOutStream.WriteText(Payload);
    end;
}
