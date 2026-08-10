// Support codeunit for TestInterfaceVarCodeunitOut.al — reads a Temp Blob back as text.

codeunit 60376 "Ivc Reader"
{
    procedure ReadAll(var Blob: Codeunit "Temp Blob") Contents: Text
    var
        BlobInStream: InStream;
        Line: Text;
    begin
        Blob.CreateInStream(BlobInStream);
        while not BlobInStream.EOS() do begin
            BlobInStream.ReadText(Line);
            Contents += Line;
        end;
    end;
}
