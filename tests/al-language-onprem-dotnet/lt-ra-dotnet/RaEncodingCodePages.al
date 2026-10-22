// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.text.encoding.getencoding
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99445
// Probe (writer RA, 2026-10-22): System.Text.Encoding.GetEncoding with a Windows code page (1252), DOS code pages (850, 437), Latin-1 (28591)
//   and an unknown code page (99999), by number and by name: WebName, CodePage, EncodingName, GetBytes of a fixed text (as hex) and GetString of
//   fixed bytes (as character codes). The question: does the BC server answer code-page encodings, and with which values.
//   Also the Base Application wrapper codeunit DotNet_Encoding.Encoding(code page) with a DotNet_StreamWriter / DotNet_StreamReader round trip.
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.Text.Encoding"; LtRaEncoding) { }
        type("System.Byte[]"; LtRaBytes) { }
        type("System.Convert"; LtRaConvert) { }
        type("System.BitConverter"; LtRaBitConverter) { }
    }
}

codeunit 99445 "LT RA Encoding Code Pages"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryByNumber(CodePage: Integer; var Enc: DotNet LtRaEncoding)
    begin
        Enc := Enc.GetEncoding(CodePage);
    end;

    [TryFunction]
    local procedure TryByName(Name: Text; var Enc: DotNet LtRaEncoding)
    begin
        Enc := Enc.GetEncoding(Name);
    end;

    [TryFunction]
    local procedure TryBytesHex(var Enc: DotNet LtRaEncoding; Value: Text; var Hex: Text)
    var
        BitConv: DotNet LtRaBitConverter;
    begin
        Hex := BitConv.ToString(Enc.GetBytes(Value));
    end;

    [TryFunction]
    local procedure TryStringCodes(var Enc: DotNet LtRaEncoding; Base64: Text; var Codes: Text)
    var
        Conv: DotNet LtRaConvert;
        Bytes: DotNet LtRaBytes;
        Decoded: Text;
        CharCode: Integer;
        i: Integer;
    begin
        Bytes := Conv.FromBase64String(Base64);
        Decoded := Enc.GetString(Bytes);
        Codes := '';
        for i := 1 to StrLen(Decoded) do begin
            CharCode := Decoded[i];
            Codes += Format(CharCode) + ',';
        end;
    end;

    local procedure Describe(Name: Text; var Enc: DotNet LtRaEncoding)
    var
        Hex: Text;
        Codes: Text;
    begin
        Observer.Observe(Name + ' identity', Enc.WebName + '|' + Format(Enc.CodePage) + '|' + Enc.EncodingName);
        // AE, O with stroke, A with ring, euro sign, ae, o with stroke, a with ring
        if TryBytesHex(Enc, 'ÆØÅ€æøå', Hex) then
            Observer.Observe(Name + ' GetBytes', Hex)
        else
            Observer.ObserveError(Name + ' GetBytes');
        // bytes 128, 138, 150, 159 (0x80 0x8A 0x96 0x9F) and 200, 230 (0xC8 0xE6)
        if TryStringCodes(Enc, 'gIqWn8jm', Codes) then
            Observer.Observe(Name + ' GetString', Codes)
        else
            Observer.ObserveError(Name + ' GetString');
    end;

    local procedure ObserveByNumber(CodePage: Integer)
    var
        Enc: DotNet LtRaEncoding;
        Name: Text;
    begin
        Name := 'cp ' + Format(CodePage);
        ClearLastError();
        if TryByNumber(CodePage, Enc) then begin
            Observer.Observe(Name + ' ok', 'Yes');
            Describe(Name, Enc);
        end else
            Observer.ObserveError(Name);
    end;

    local procedure ObserveByName(EncodingName: Text)
    var
        Enc: DotNet LtRaEncoding;
        Name: Text;
    begin
        Name := 'name ' + EncodingName;
        ClearLastError();
        if TryByName(EncodingName, Enc) then begin
            Observer.Observe(Name + ' ok', 'Yes');
            Describe(Name, Enc);
        end else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure RA_GetEncoding_WindowsCodePage1252()
    begin
        ObserveByNumber(1252);
        ObserveByName('windows-1252');
        Observer.Finish();
    end;

    [Test]
    procedure RA_GetEncoding_DosCodePages850And437()
    begin
        ObserveByNumber(850);
        ObserveByNumber(437);
        ObserveByName('ibm850');
        Observer.Finish();
    end;

    [Test]
    procedure RA_GetEncoding_Latin1_28591()
    begin
        ObserveByNumber(28591);
        ObserveByName('iso-8859-1');
        Observer.Finish();
    end;

    [Test]
    procedure RA_GetEncoding_UnknownCodePage()
    begin
        ObserveByNumber(99999);
        ObserveByName('no-such-encoding');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryWrapperEncoding(CodePage: Integer; var DotNetEnc: Codeunit DotNet_Encoding)
    begin
        DotNetEnc.Encoding(CodePage);
    end;

    [TryFunction]
    local procedure TryWrapperRoundTrip(var DotNetEnc: Codeunit DotNet_Encoding; Value: Text; var Hex: Text; var Codes: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        Writer: Codeunit DotNet_StreamWriter;
        Reader: Codeunit DotNet_StreamReader;
        OutS: OutStream;
        InS: InStream;
        B: Byte;
        Decoded: Text;
        CharCode: Integer;
        i: Integer;
    begin
        TempBlob.CreateOutStream(OutS);
        Writer.StreamWriter(OutS, DotNetEnc);
        Writer.Write(Value);
        Writer.Flush();
        Writer.Close();
        TempBlob.CreateInStream(InS);
        Hex := '';
        while not InS.EOS() do begin
            InS.Read(B);
            Hex += Format(B) + ',';
        end;
        TempBlob.CreateInStream(InS);
        Reader.StreamReader(InS, DotNetEnc);
        Decoded := Reader.ReadToEnd();
        Reader.Close();
        Codes := '';
        for i := 1 to StrLen(Decoded) do begin
            CharCode := Decoded[i];
            Codes += Format(CharCode) + ',';
        end;
    end;

    local procedure ObserveWrapper(CodePage: Integer)
    var
        DotNetEnc: Codeunit DotNet_Encoding;
        Name: Text;
        Hex: Text;
        Codes: Text;
    begin
        Name := 'DotNet_Encoding ' + Format(CodePage);
        ClearLastError();
        if not TryWrapperEncoding(CodePage, DotNetEnc) then begin
            Observer.ObserveError(Name);
            exit;
        end;
        Observer.Observe(Name + ' Codepage', Format(DotNetEnc.Codepage()));
        // AE, O with stroke, A with ring: written bytes (decimal) and the character codes read back
        if TryWrapperRoundTrip(DotNetEnc, 'ÆØÅ', Hex, Codes) then
            Observer.Observe(Name + ' round trip', Hex + '|' + Codes)
        else
            Observer.ObserveError(Name + ' round trip');
    end;

    [Test]
    procedure RA_DotNetEncodingCodeunit_StreamRoundTrip()
    begin
        ObserveWrapper(1252);
        ObserveWrapper(850);
        ObserveWrapper(28591);
        ObserveWrapper(99999);
        Observer.Finish();
    end;
}
