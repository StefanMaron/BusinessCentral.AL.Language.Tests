// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit-system-data-compression-data-compression
// Scope: in-scope (System Application "Data Compression"; its GZip methods use the DotNet GZipStream and CompressionMode inside the app)
// Fixtures used: Probe Observer (69160); self-contained codeunit 69349
// Probe: written against a real BC 29.0 service tier (29.0.54011.55816); every literal below is what that tier produced. Other BC versions were not measured.
//
// GZipCompress / GZipDecompress: text and the 256 byte values survive a round trip; the packed text of repeated input is smaller; the packed stream starts with the bytes 31 and 139 and IsGZip says Yes
// (IsZip No, plain text No). Empty input compresses to NO bytes at all (so IsGZip of it is No), and decompressing an empty stream answers an empty result without an error.
// Decompressing text that is not gzip raises "A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method." (DotNetInvoke:InvalidData);
// a truncated gzip stream decompresses without an error to a shorter result.
// BC versions: 29.0
codeunit 69349 "PZ Gzip Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Compress(Plain: Codeunit "Temp Blob"; var Packed: Codeunit "Temp Blob")
    var
        Compression: Codeunit "Data Compression";
        InS: InStream;
        OutS: OutStream;
    begin
        Plain.CreateInStream(InS);
        Packed.CreateOutStream(OutS);
        Compression.GZipCompress(InS, OutS);
    end;

    local procedure Decompress(Packed: Codeunit "Temp Blob"; var Plain: Codeunit "Temp Blob")
    var
        Compression: Codeunit "Data Compression";
        InS: InStream;
        OutS: OutStream;
    begin
        Packed.CreateInStream(InS);
        Plain.CreateOutStream(OutS);
        Compression.GZipDecompress(InS, OutS);
    end;

    [TryFunction]
    local procedure TryDecompress(Packed: Codeunit "Temp Blob"; var Plain: Codeunit "Temp Blob")
    begin
        Decompress(Packed, Plain);
    end;

    local procedure TextBlob(Value: Text; var Blob: Codeunit "Temp Blob")
    var
        OutS: OutStream;
    begin
        Blob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Value);
    end;

    local procedure ReadAll(Blob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Result: Text;
    begin
        Blob.CreateInStream(InS, TextEncoding::UTF8);
        if Blob.Length() = 0 then
            exit('');
        InS.ReadText(Result, Blob.Length());
        exit(Result);
    end;

    local procedure RepeatText(Piece: Text; Count: Integer): Text
    var
        Builder: TextBuilder;
        i: Integer;
    begin
        for i := 1 to Count do
            Builder.Append(Piece);
        exit(Builder.ToText());
    end;

    [Test]
    procedure GZip_TextRoundTrip()
    var
        Plain: Codeunit "Temp Blob";
        Packed: Codeunit "Temp Blob";
        Back: Codeunit "Temp Blob";
        Source: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Source := RepeatText('Hello gzip, aeoeue ', 200);
        TextBlob(Source, Plain);
        Compress(Plain, Packed);
        Decompress(Packed, Back);
        Observer.Observe('plain_length_gt_zero', Format(Plain.Length() > 0));
        Observer.Observe('packed_is_smaller', Format(Packed.Length() < Plain.Length()));
        Observer.Observe('back_length_equals_plain', Format(Back.Length() = Plain.Length()));
        Observer.Observe('back_text_equals_source', Format(ReadAll(Back) = Source));
        Observer.Expect('plain_length_gt_zero', 'Yes');
        Observer.Expect('packed_is_smaller', 'Yes');
        Observer.Expect('back_length_equals_plain', 'Yes');
        Observer.Expect('back_text_equals_source', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GZip_BinaryRoundTrip_AllByteValues()
    var
        Plain: Codeunit "Temp Blob";
        Packed: Codeunit "Temp Blob";
        Back: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Value: Byte;
        i: Integer;
        Same: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Plain.CreateOutStream(OutS);
        for i := 0 to 255 do begin
            Value := i;
            OutS.Write(Value);
        end;
        Compress(Plain, Packed);
        Decompress(Packed, Back);
        Observer.Observe('plain_length', Format(Plain.Length()));
        Observer.Observe('back_length', Format(Back.Length()));
        Back.CreateInStream(InS);
        Same := true;
        for i := 0 to 255 do begin
            InS.Read(Value);
            if Value <> i then
                Same := false;
        end;
        Observer.Observe('all_bytes_equal', Format(Same));
        Observer.Expect('plain_length', '256');
        Observer.Expect('back_length', '256');
        Observer.Expect('all_bytes_equal', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GZip_CompressedStartsWithTheGzipMagicNumber()
    var
        Compression: Codeunit "Data Compression";
        Plain: Codeunit "Temp Blob";
        Packed: Codeunit "Temp Blob";
        InS: InStream;
        First: Byte;
        FirstNumber: Integer;
        SecondNumber: Integer;
        Second: Byte;
        Observer: Codeunit "Probe Observer";
    begin
        TextBlob('abc', Plain);
        Compress(Plain, Packed);
        Packed.CreateInStream(InS);
        InS.Read(First);
        InS.Read(Second);
        FirstNumber := First;
        SecondNumber := Second;
        Observer.Observe('first_byte', Format(FirstNumber));
        Observer.Observe('second_byte', Format(SecondNumber));
        Packed.CreateInStream(InS);
        Observer.Observe('is_gzip_packed', Format(Compression.IsGZip(InS)));
        Packed.CreateInStream(InS);
        Observer.Observe('is_zip_packed', Format(Compression.IsZip(InS)));
        Plain.CreateInStream(InS);
        Observer.Observe('is_gzip_plain', Format(Compression.IsGZip(InS)));
        Observer.Expect('first_byte', '31');
        Observer.Expect('second_byte', '139');
        Observer.Expect('is_gzip_packed', 'Yes');
        Observer.Expect('is_zip_packed', 'No');
        Observer.Expect('is_gzip_plain', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure GZip_EmptyInput()
    var
        Compression: Codeunit "Data Compression";
        Plain: Codeunit "Temp Blob";
        Packed: Codeunit "Temp Blob";
        Back: Codeunit "Temp Blob";
        InS: InStream;
        Observer: Codeunit "Probe Observer";
    begin
        Compress(Plain, Packed);
        Observer.Observe('plain_length', Format(Plain.Length()));
        Observer.Observe('packed_length_gt_zero', Format(Packed.Length() > 0));
        Packed.CreateInStream(InS);
        Observer.Observe('is_gzip_packed', Format(Compression.IsGZip(InS)));
        Decompress(Packed, Back);
        Observer.Observe('back_length', Format(Back.Length()));
        Observer.Expect('plain_length', '0');
        Observer.Expect('packed_length_gt_zero', 'No');
        Observer.Expect('is_gzip_packed', 'No');
        Observer.Expect('back_length', '0');
        Observer.Verify();
    end;

    [Test]
    procedure GZip_Decompress_InvalidInput()
    var
        Plain: Codeunit "Temp Blob";
        Back: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
    begin
        TextBlob('this is not gzip data at all', Plain);
        asserterror Decompress(Plain, Back);
        Observer.ObserveError('plain_text');
        Observer.Expect('plain_text|text', 'A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.');
        Observer.Expect('plain_text|code', 'DotNetInvoke:InvalidData');
        Observer.Verify();
    end;

    [Test]
    procedure GZip_Decompress_EmptyAndTruncated()
    var
        Plain: Codeunit "Temp Blob";
        Packed: Codeunit "Temp Blob";
        Cut: Codeunit "Temp Blob";
        Empty: Codeunit "Temp Blob";
        Back: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
        Value: Byte;
        i: Integer;
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Ok := TryDecompress(Empty, Back);
        Observer.Observe('empty_input', Format(Ok) + ' back_length=' + Format(Back.Length()) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        TextBlob(RepeatText('truncate me ', 100), Plain);
        Compress(Plain, Packed);
        Packed.CreateInStream(InS);
        Cut.CreateOutStream(OutS);
        for i := 1 to Packed.Length() div 2 do begin
            InS.Read(Value);
            OutS.Write(Value);
        end;
        Clear(Back);
        Ok := TryDecompress(Cut, Back);
        Observer.Observe('truncated_input', Format(Ok) + ' back_shorter=' + Format(Back.Length() < Plain.Length()) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('empty_input', 'Yes back_length=0 |');
        Observer.Expect('truncated_input', 'Yes back_shorter=Yes |');
        Observer.Verify();
    end;
}
