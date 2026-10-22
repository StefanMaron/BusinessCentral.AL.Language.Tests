// Batch 7 probes: JsonObject.WriteTo(OutStream) bytes per TextEncoding, JsonObject.ReadFrom(InStream) with a byte order mark and a partly read stream. Observe only.
codeunit 68553 "W7 Json Streams"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Ch(Code: Integer): Text
    var
        T: Text[1];
    begin
        T[1] := Code;
        exit(T);
    end;

    local procedure ObjectWith(Value: Text): JsonObject
    var
        Result: JsonObject;
    begin
        Result.Add('a', Value);
        exit(Result);
    end;

    [TryFunction]
    local procedure TryWriteTo(Json: JsonObject; Encoding: TextEncoding; var TempBlob: Codeunit "Temp Blob")
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, Encoding);
        Json.WriteTo(OutS);
    end;

    local procedure ObserveWrite(var Observer: Codeunit "Probe Observer"; Name: Text; Value: Text; Encoding: TextEncoding)
    var
        Util: Codeunit "W7 Stream Util";
        TempBlob: Codeunit "Temp Blob";
    begin
        if TryWriteTo(ObjectWith(Value), Encoding, TempBlob) then
            Observer.Observe(Name, Util.Hex(TempBlob))
        else begin
            Observer.Observe(Name, 'error');
            Observer.ObserveError(Name);
        end;
    end;

    local procedure ObserveAllTexts(var Observer: Codeunit "Probe Observer"; Encoding: TextEncoding)
    begin
        ObserveWrite(Observer, 'ascii', 'x', Encoding);
        ObserveWrite(Observer, 'empty', '', Encoding);
        ObserveWrite(Observer, 'e-acute', Ch(233), Encoding);
        ObserveWrite(Observer, 'euro', Ch(8364), Encoding);
        ObserveWrite(Observer, 'byte 150', Ch(150), Encoding);
        ObserveWrite(Observer, 'l-stroke', Ch(322), Encoding);
        ObserveWrite(Observer, 'hiragana a', Ch(12354), Encoding);
        ObserveWrite(Observer, 'surrogate pair', Ch(55357) + Ch(56832), Encoding);
        ObserveWrite(Observer, 'quote and backslash', '"\', Encoding);
        ObserveWrite(Observer, 'line feed', Ch(10), Encoding);
    end;

    [Test]
    procedure WriteToOutStream_Utf8()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveAllTexts(Observer, TextEncoding::UTF8);
        Observer.Expect('ascii', '7B 22 61 22 3A 22 78 22 7D');
        Observer.Expect('empty', '7B 22 61 22 3A 22 22 7D');
        Observer.Expect('e-acute', '7B 22 61 22 3A 22 C3 A9 22 7D');
        Observer.Expect('euro', '7B 22 61 22 3A 22 E2 82 AC 22 7D');
        Observer.Expect('byte 150', '7B 22 61 22 3A 22 C2 96 22 7D');
        Observer.Expect('l-stroke', '7B 22 61 22 3A 22 C5 82 22 7D');
        Observer.Expect('hiragana a', '7B 22 61 22 3A 22 E3 81 82 22 7D');
        Observer.Expect('surrogate pair', '7B 22 61 22 3A 22 F0 9F 98 80 22 7D');
        Observer.Expect('quote and backslash', '7B 22 61 22 3A 22 5C 22 5C 5C 22 7D');
        Observer.Expect('line feed', '7B 22 61 22 3A 22 5C 6E 22 7D');
        Observer.Verify();
    end;

    [Test]
    procedure WriteToOutStream_Utf16()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveAllTexts(Observer, TextEncoding::UTF16);
        Observer.Expect('ascii', '7B 22 61 22 3A 22 78 22 7D');
        Observer.Expect('empty', '7B 22 61 22 3A 22 22 7D');
        Observer.Expect('e-acute', '7B 22 61 22 3A 22 C3 A9 22 7D');
        Observer.Expect('euro', '7B 22 61 22 3A 22 E2 82 AC 22 7D');
        Observer.Expect('byte 150', '7B 22 61 22 3A 22 C2 96 22 7D');
        Observer.Expect('l-stroke', '7B 22 61 22 3A 22 C5 82 22 7D');
        Observer.Expect('hiragana a', '7B 22 61 22 3A 22 E3 81 82 22 7D');
        Observer.Expect('surrogate pair', '7B 22 61 22 3A 22 F0 9F 98 80 22 7D');
        Observer.Expect('quote and backslash', '7B 22 61 22 3A 22 5C 22 5C 5C 22 7D');
        Observer.Expect('line feed', '7B 22 61 22 3A 22 5C 6E 22 7D');
        Observer.Verify();
    end;

    [Test]
    procedure WriteToOutStream_Windows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveAllTexts(Observer, TextEncoding::Windows);
        Observer.Expect('ascii', '7B 22 61 22 3A 22 78 22 7D');
        Observer.Expect('empty', '7B 22 61 22 3A 22 22 7D');
        Observer.Expect('e-acute', '7B 22 61 22 3A 22 C3 A9 22 7D');
        Observer.Expect('euro', '7B 22 61 22 3A 22 E2 82 AC 22 7D');
        Observer.Expect('byte 150', '7B 22 61 22 3A 22 C2 96 22 7D');
        Observer.Expect('l-stroke', '7B 22 61 22 3A 22 C5 82 22 7D');
        Observer.Expect('hiragana a', '7B 22 61 22 3A 22 E3 81 82 22 7D');
        Observer.Expect('surrogate pair', '7B 22 61 22 3A 22 F0 9F 98 80 22 7D');
        Observer.Expect('quote and backslash', '7B 22 61 22 3A 22 5C 22 5C 5C 22 7D');
        Observer.Expect('line feed', '7B 22 61 22 3A 22 5C 6E 22 7D');
        Observer.Verify();
    end;

    [Test]
    procedure WriteToOutStream_MsDos()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveAllTexts(Observer, TextEncoding::MSDos);
        Observer.Expect('ascii', '7B 22 61 22 3A 22 78 22 7D');
        Observer.Expect('empty', '7B 22 61 22 3A 22 22 7D');
        Observer.Expect('e-acute', '7B 22 61 22 3A 22 C3 A9 22 7D');
        Observer.Expect('euro', '7B 22 61 22 3A 22 E2 82 AC 22 7D');
        Observer.Expect('byte 150', '7B 22 61 22 3A 22 C2 96 22 7D');
        Observer.Expect('l-stroke', '7B 22 61 22 3A 22 C5 82 22 7D');
        Observer.Expect('hiragana a', '7B 22 61 22 3A 22 E3 81 82 22 7D');
        Observer.Expect('surrogate pair', '7B 22 61 22 3A 22 F0 9F 98 80 22 7D');
        Observer.Expect('quote and backslash', '7B 22 61 22 3A 22 5C 22 5C 5C 22 7D');
        Observer.Expect('line feed', '7B 22 61 22 3A 22 5C 6E 22 7D');
        Observer.Verify();
    end;

    [Test]
    procedure WriteToOutStream_ArrayAndValue_Utf8()
    var
        Observer: Codeunit "Probe Observer";
        Util: Codeunit "W7 Stream Util";
        TempBlob: Codeunit "Temp Blob";
        Arr: JsonArray;
        Val: JsonValue;
        Token: JsonToken;
        OutS: OutStream;
    begin
        Arr.Add(1);
        Arr.Add('x');
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Arr.WriteTo(OutS);
        Observer.Observe('array', Util.Hex(TempBlob));

        Clear(TempBlob);
        Val.SetValue('v');
        Token := Val.AsToken();
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Token.WriteTo(OutS);
        Observer.Observe('value token', Util.Hex(TempBlob));

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('ab');
        ObjectWith('x').WriteTo(OutS);
        OutS.WriteText('cd');
        Observer.Observe('written after other text', Util.Hex(TempBlob));
        Observer.Expect('array', '5B 31 2C 22 78 22 5D');
        Observer.Expect('value token', '22 76 22');
        Observer.Expect('written after other text', '61 62 63 64 61 22 3A 22 78 22 7D');
        Observer.Verify();
    end;

    local procedure WriteBytes(var TempBlob: Codeunit "Temp Blob"; Bytes: List of [Integer])
    var
        OutS: OutStream;
        B: Byte;
        Value: Integer;
    begin
        TempBlob.CreateOutStream(OutS);
        foreach Value in Bytes do begin
            B := Value;
            OutS.Write(B);
        end;
    end;

    local procedure AsciiBytes(Text: Text; var Bytes: List of [Integer])
    var
        i: Integer;
        Code: Integer;
    begin
        for i := 1 to StrLen(Text) do begin
            Code := Text[i];
            Bytes.Add(Code);
        end;
    end;

    [TryFunction]
    local procedure TryReadFrom(var Json: JsonObject; var InS: InStream)
    begin
        Json.ReadFrom(InS);
    end;

    local procedure ReadResult(var Observer: Codeunit "Probe Observer"; Name: Text; var TempBlob: Codeunit "Temp Blob"; Encoding: TextEncoding)
    var
        Util: Codeunit "W7 Stream Util";
        Json: JsonObject;
        Token: JsonToken;
        InS: InStream;
    begin
        TempBlob.CreateInStream(InS, Encoding);
        if TryReadFrom(Json, InS) then begin
            Observer.Observe(Name + ' ok', 'true');
            Observer.Observe(Name + ' keys', Format(Json.Keys.Count()));
            if Json.Get('a', Token) then
                Observer.Observe(Name + ' a codes', Util.Codes(Token.AsValue().AsText()));
            Observer.Observe(Name + ' at end', Format(InS.EOS()));
        end else begin
            Observer.Observe(Name + ' ok', 'false');
            Observer.ObserveError(Name);
        end;
    end;

    [Test]
    procedure ReadFromInStream_ByteOrderMarks()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Bytes: List of [Integer];
    begin
        // UTF-8 BOM, then {"a":"x"}
        Bytes.Add(239); Bytes.Add(187); Bytes.Add(191);
        AsciiBytes('{"a":"x"}', Bytes);
        WriteBytes(TempBlob, Bytes);
        ReadResult(Observer, 'utf8 bom, read as UTF8', TempBlob, TextEncoding::UTF8);
        ReadResult(Observer, 'utf8 bom, read as Windows', TempBlob, TextEncoding::Windows);

        // UTF-16 little endian BOM, then {"a":"x"} in two bytes per character
        Clear(Bytes);
        Clear(TempBlob);
        Bytes.Add(255); Bytes.Add(254);
        AppendUtf16(Bytes, '{"a":"x"}');
        WriteBytes(TempBlob, Bytes);
        ReadResult(Observer, 'utf16 bom, read as UTF16', TempBlob, TextEncoding::UTF16);
        ReadResult(Observer, 'utf16 bom, read as UTF8', TempBlob, TextEncoding::UTF8);

        // UTF-16 little endian without BOM
        Clear(Bytes);
        Clear(TempBlob);
        AppendUtf16(Bytes, '{"a":"x"}');
        WriteBytes(TempBlob, Bytes);
        ReadResult(Observer, 'utf16 no bom, read as UTF16', TempBlob, TextEncoding::UTF16);

        // no BOM at all
        Clear(Bytes);
        Clear(TempBlob);
        AsciiBytes('{"a":"x"}', Bytes);
        WriteBytes(TempBlob, Bytes);
        ReadResult(Observer, 'plain ascii, read as UTF8', TempBlob, TextEncoding::UTF8);
        ReadResult(Observer, 'plain ascii, read as UTF16', TempBlob, TextEncoding::UTF16);
        Observer.Expect('utf8 bom, read as UTF8 ok', 'true');
        Observer.Expect('utf8 bom, read as UTF8 keys', '1');
        Observer.Expect('utf8 bom, read as UTF8 a codes', '120');
        Observer.Expect('utf8 bom, read as UTF8 at end', 'No');
        Observer.Expect('utf8 bom, read as Windows ok', 'true');
        Observer.Expect('utf8 bom, read as Windows keys', '1');
        Observer.Expect('utf8 bom, read as Windows a codes', '120');
        Observer.Expect('utf8 bom, read as Windows at end', 'No');
        Observer.Expect('utf16 bom, read as UTF16 ok', 'true');
        Observer.Expect('utf16 bom, read as UTF16 keys', '1');
        Observer.Expect('utf16 bom, read as UTF16 a codes', '120');
        Observer.Expect('utf16 bom, read as UTF16 at end', 'No');
        Observer.Expect('utf16 bom, read as UTF8 ok', 'true');
        Observer.Expect('utf16 bom, read as UTF8 keys', '1');
        Observer.Expect('utf16 bom, read as UTF8 a codes', '120');
        Observer.Expect('utf16 bom, read as UTF8 at end', 'No');
        Observer.Expect('utf16 no bom, read as UTF16 ok', 'true');
        Observer.Expect('utf16 no bom, read as UTF16 keys', '1');
        Observer.Expect('utf16 no bom, read as UTF16 at end', 'No');
        Observer.Expect('plain ascii, read as UTF8 ok', 'true');
        Observer.Expect('plain ascii, read as UTF8 keys', '1');
        Observer.Expect('plain ascii, read as UTF8 a codes', '120');
        Observer.Expect('plain ascii, read as UTF8 at end', 'No');
        Observer.Expect('plain ascii, read as UTF16 ok', 'true');
        Observer.Expect('plain ascii, read as UTF16 keys', '1');
        Observer.Expect('plain ascii, read as UTF16 a codes', '120');
        Observer.Expect('plain ascii, read as UTF16 at end', 'No');
        Observer.Verify();
    end;

    local procedure AppendUtf16(var Bytes: List of [Integer]; Text: Text)
    var
        i: Integer;
        Code: Integer;
    begin
        for i := 1 to StrLen(Text) do begin
            Code := Text[i];
            Bytes.Add(Code mod 256);
            Bytes.Add(Code div 256);
        end;
    end;

    [Test]
    procedure ReadFromInStream_NonAsciiPerEncoding()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('{"a":"' + Ch(233) + Ch(8364) + '"}');
        ReadResult(Observer, 'utf8 written, read as UTF8', TempBlob, TextEncoding::UTF8);
        ReadResult(Observer, 'utf8 written, read as Windows', TempBlob, TextEncoding::Windows);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS, TextEncoding::Windows);
        OutS.WriteText('{"a":"' + Ch(233) + Ch(8364) + '"}');
        ReadResult(Observer, 'windows written, read as Windows', TempBlob, TextEncoding::Windows);
        ReadResult(Observer, 'windows written, read as UTF8', TempBlob, TextEncoding::UTF8);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF16);
        OutS.WriteText('{"a":"' + Ch(233) + Ch(8364) + '"}');
        ReadResult(Observer, 'utf16 written, read as UTF16', TempBlob, TextEncoding::UTF16);
        Observer.Expect('utf8 written, read as UTF8 ok', 'true');
        Observer.Expect('utf8 written, read as UTF8 keys', '1');
        Observer.Expect('utf8 written, read as UTF8 a codes', '233 8364');
        Observer.Expect('utf8 written, read as UTF8 at end', 'No');
        Observer.Expect('utf8 written, read as Windows ok', 'true');
        Observer.Expect('utf8 written, read as Windows keys', '1');
        Observer.Expect('utf8 written, read as Windows a codes', '233 8364');
        Observer.Expect('utf8 written, read as Windows at end', 'No');
        Observer.Expect('windows written, read as Windows ok', 'true');
        Observer.Expect('windows written, read as Windows keys', '1');
        Observer.Expect('windows written, read as Windows a codes', '65533');
        Observer.Expect('windows written, read as Windows at end', 'No');
        Observer.Expect('windows written, read as UTF8 ok', 'true');
        Observer.Expect('windows written, read as UTF8 keys', '1');
        Observer.Expect('windows written, read as UTF8 a codes', '65533');
        Observer.Expect('windows written, read as UTF8 at end', 'No');
        Observer.Expect('utf16 written, read as UTF16 ok', 'true');
        Observer.Expect('utf16 written, read as UTF16 keys', '1');
        Observer.Expect('utf16 written, read as UTF16 at end', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromInStream_RestOfAPartlyReadStream()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Json: JsonObject;
        Token: JsonToken;
        Prefix: Text;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('xx{"a":"x"}');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        InS.Read(Prefix, 2);
        Observer.Observe('prefix', Prefix);
        Observer.Observe('read ok', Format(TryReadFrom(Json, InS)));
        Observer.ObserveError('read');
        Observer.Observe('has a', Format(Json.Get('a', Token)));
        Observer.Observe('at end', Format(InS.EOS()));

        Clear(TempBlob);
        Clear(Json);
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('{"a":"x"}');
        OutS.WriteText('{"a":"y"}');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('two objects read ok', Format(TryReadFrom(Json, InS)));
        Observer.ObserveError('two objects');
        Observer.Observe('two objects: has a', Format(Json.Get('a', Token)));
        Observer.Observe('two objects: at end', Format(InS.EOS()));

        Clear(TempBlob);
        Clear(Json);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('empty stream read ok', Format(TryReadFrom(Json, InS)));
        Observer.ObserveError('empty stream');
        Observer.Expect('prefix', 'xx');
        Observer.Expect('read ok', 'Yes');
        Observer.Expect('read|text', '');
        Observer.Expect('read|code', '');
        Observer.Expect('has a', 'Yes');
        Observer.Expect('at end', 'No');
        Observer.Expect('two objects read ok', 'Yes');
        Observer.Expect('two objects|text', '');
        Observer.Expect('two objects|code', '');
        Observer.Expect('two objects: has a', 'Yes');
        Observer.Expect('two objects: at end', 'No');
        Observer.Expect('empty stream read ok', 'No');
        Observer.Expect('empty stream|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('empty stream|code', 'InvalidJsonData');
        Observer.Verify();
    end;
}
