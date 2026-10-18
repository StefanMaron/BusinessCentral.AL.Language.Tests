// @expect AL0196 | The call is ambiguous between the method 'Write(Boolean)' defined in Class 'File' by the extension '' and the method 'Write(Byte)' defined in Class 'File' by the extension ''.
// @target OnPrem
// File.Write(Value: Any) is not callable with a Variant: the call is ambiguous between the scalar overloads (OutStream.Write accepts a Variant: streams/lt-stream-value-types/OutStreamWriteVariant.al).
codeunit 50994 "MNC File Write Variant"
{
    procedure Probe()
    var
        F: File;
        V: Variant;
    begin
        V := 7;
        F.Write(V);
    end;
}
