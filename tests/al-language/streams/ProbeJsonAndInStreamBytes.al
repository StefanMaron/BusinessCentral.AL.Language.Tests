// Probe: bytes JsonObject.WriteTo(OutStream) produces per stream encoding, JsonObject.ReadFrom(InStream) on streams with
// a byte order mark and a partial read, and InStream.Read(Text) on WriteText / Write(Text) content.
codeunit 69521 "Probe Json Stream Bytes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure BytesOf(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Base64: Codeunit "Base64 Convert";
    begin
        TempBlob.CreateInStream(InS);
        exit(Format(TempBlob.Length()) + ' bytes, base64=' + Base64.ToBase64(InS));
    end;

    local procedure WriteJson(Enc: TextEncoding; Value: Text; var TempBlob: Codeunit "Temp Blob")
    var
        Obj: JsonObject;
        Out: OutStream;
    begin
        Obj.Add('a', Value);
        TempBlob.CreateOutStream(Out, Enc);
        Obj.WriteTo(Out);
    end;

    [Test]
    procedure WriteTo_OutStream_Utf8_Ascii()
    var
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
    begin
        WriteJson(TextEncoding::UTF8, 'x', TempBlob);
        Observer.Observe('utf8Ascii', BytesOf(TempBlob));
        Observer.Expect('utf8Ascii', '9 bytes, base64=eyJhIjoieCJ9');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_OutStream_Utf8_NonAscii()
    var
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
    begin
        WriteJson(TextEncoding::UTF8, 'é€', TempBlob);
        Observer.Observe('utf8NonAscii', BytesOf(TempBlob));
        Observer.Expect('utf8NonAscii', '13 bytes, base64=eyJhIjoiw6nigqwifQ==');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_OutStream_Utf16_AsciiAndNonAscii()
    var
        TempBlob: Codeunit "Temp Blob";
        Blob2: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
    begin
        WriteJson(TextEncoding::UTF16, 'x', TempBlob);
        Observer.Observe('utf16Ascii', BytesOf(TempBlob));
        WriteJson(TextEncoding::UTF16, 'é€', Blob2);
        Observer.Observe('utf16NonAscii', BytesOf(Blob2));
        Observer.Expect('utf16Ascii', '9 bytes, base64=eyJhIjoieCJ9');
        Observer.Expect('utf16NonAscii', '13 bytes, base64=eyJhIjoiw6nigqwifQ==');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_OutStream_Windows_AsciiAndNonAscii()
    var
        TempBlob: Codeunit "Temp Blob";
        Blob2: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
    begin
        WriteJson(TextEncoding::Windows, 'x', TempBlob);
        Observer.Observe('windowsAscii', BytesOf(TempBlob));
        WriteJson(TextEncoding::Windows, 'é', Blob2);
        Observer.Observe('windowsNonAscii', BytesOf(Blob2));
        Observer.Expect('windowsAscii', '9 bytes, base64=eyJhIjoieCJ9');
        Observer.Expect('windowsNonAscii', '10 bytes, base64=eyJhIjoiw6kifQ==');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_OutStream_MsDos_AsciiAndNonAscii()
    var
        TempBlob: Codeunit "Temp Blob";
        Blob2: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
    begin
        WriteJson(TextEncoding::MSDos, 'x', TempBlob);
        Observer.Observe('msdosAscii', BytesOf(TempBlob));
        WriteJson(TextEncoding::MSDos, 'é', Blob2);
        Observer.Observe('msdosNonAscii', BytesOf(Blob2));
        Observer.Expect('msdosAscii', '9 bytes, base64=eyJhIjoieCJ9');
        Observer.Expect('msdosNonAscii', '10 bytes, base64=eyJhIjoiw6kifQ==');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_InStream_WithBomAndWithout()
    var
        TempBlob: Codeunit "Temp Blob";
        Base64: Codeunit "Base64 Convert";
        Obj: JsonObject;
        InS: InStream;
        OutS: OutStream;
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        // UTF-8 BOM + {"a":1}
        TempBlob.CreateOutStream(OutS);
        Base64.FromBase64('77u/eyJhIjoxfQ==', OutS);
        TempBlob.CreateInStream(InS);
        Ok := TryRead(Obj, InS);
        Observer.Observe('bomUtf8_ok', Format(Ok));
        if Ok then
            Observer.Observe('bomUtf8_text', Format(Obj))
        else
            Observer.ObserveError('bomUtf8');
        Clear(Obj);
        Clear(TempBlob);
        // no BOM
        TempBlob.CreateOutStream(OutS);
        Base64.FromBase64('eyJhIjoxfQ==', OutS);
        TempBlob.CreateInStream(InS);
        Ok := TryRead(Obj, InS);
        Observer.Observe('noBom_ok', Format(Ok));
        if Ok then
            Observer.Observe('noBom_text', Format(Obj))
        else
            Observer.ObserveError('noBom');
        Observer.Expect('bomUtf8_ok', 'Yes');
        Observer.Expect('bomUtf8_text', '{"a":1}');
        Observer.Expect('noBom_ok', 'Yes');
        Observer.Expect('noBom_text', '{"a":1}');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRead(var Obj: JsonObject; var InS: InStream)
    begin
        Obj.ReadFrom(InS);
    end;

    [Test]
    procedure ReadFrom_InStream_AfterPartialRead_ReadsTheRest()
    var
        TempBlob: Codeunit "Temp Blob";
        Obj: JsonObject;
        InS: InStream;
        OutS: OutStream;
        Skipped: Text[1];
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('{"a":2}');
        TempBlob.CreateInStream(InS);
        InS.Read(Skipped, 1);
        Observer.Observe('skippedChar', Skipped);
        Ok := TryRead(Obj, InS);
        Observer.Observe('restParses', Format(Ok));
        if not Ok then
            Observer.ObserveError('restOfStream');
        Observer.Observe('positionAfter', Format(InS.Length() - 0));
        Observer.Expect('skippedChar', '{');
        Observer.Expect('restParses', 'No');
        Observer.Expect('restOfStream|text', 'JSON tokens of type ''String'' are not supported by this implementation.');
        Observer.Expect('restOfStream|code', 'InvalidJsonType');
        Observer.Expect('positionAfter', '7');
        Observer.Verify();
    end;

    [Test]
    procedure InStreamRead_Text_AfterWriteTextAndAfterWriteText_NonAscii()
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
        Txt: Text;
        Txt2: Text;
        Ret: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.Write('hello');
        OutS.Write('wörld');
        Observer.Observe('bytesWritten', BytesOf(TempBlob));
        TempBlob.CreateInStream(InS);
        Ret := InS.Read(Txt);
        Observer.Observe('firstReturn', Format(Ret));
        Observer.Observe('firstText', Txt);
        Ret := InS.Read(Txt2);
        Observer.Observe('secondReturn', Format(Ret));
        Observer.Observe('secondText', Txt2);
        Observer.Observe('eosAfter', Format(InS.EOS()));
        Observer.Expect('bytesWritten', '12 bytes, base64=aGVsbG8Ad/ZybGQA');
        Observer.Expect('firstReturn', '6');
        Observer.Expect('firstText', 'hello');
        Observer.Expect('secondReturn', '6');
        Observer.Expect('secondText', 'wörld');
        Observer.Expect('eosAfter', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure InStreamRead_Text_OnWriteTextContent_NoTerminator()
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
        Txt: Text;
        Ret: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('abc');
        TempBlob.CreateInStream(InS);
        Ret := TryReadText(InS, Txt);
        Observer.Observe('tryReadText', Format(Ret));
        Observer.ObserveError('readTextWithoutTerminator');
        Observer.Observe('text', Txt);
        Observer.Observe('eos', Format(InS.EOS()));
        Observer.Expect('tryReadText', '1');
        Observer.Expect('readTextWithoutTerminator|text', '');
        Observer.Expect('readTextWithoutTerminator|code', '');
        Observer.Expect('text', 'abc');
        Observer.Expect('eos', 'Yes');
        Observer.Verify();
    end;

    local procedure TryReadText(var InS: InStream; var Txt: Text): Integer
    begin
        if not TryRead2(InS, Txt) then
            exit(-1);
        exit(1);
    end;

    [TryFunction]
    local procedure TryRead2(var InS: InStream; var Txt: Text)
    begin
        InS.Read(Txt);
    end;

    [Test]
    procedure InStreamRead_Text_ReturnValueIsLength()
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
        Txt: Text;
        Code10: Code[10];
        Observer: Codeunit "Probe Observer";
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.Write('abcdef');
        OutS.Write('toolongvalueforcode');
        TempBlob.CreateInStream(InS);
        Observer.Observe('returnText', Format(InS.Read(Txt)));
        Observer.Observe('text', Txt);
        Observer.Observe('tryCodeRead', Format(TryReadCode(InS, Code10)));
        Observer.ObserveError('codeTooShort');
        Observer.Observe('code', Code10);
        Observer.Expect('returnText', '7');
        Observer.Expect('text', 'abcdef');
        Observer.Expect('tryCodeRead', 'Yes');
        Observer.Expect('codeTooShort|text', '');
        Observer.Expect('codeTooShort|code', '');
        Observer.Expect('code', 'TOOLONGVAL');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadCode(var InS: InStream; var C: Code[10])
    begin
        InS.Read(C);
    end;
}
