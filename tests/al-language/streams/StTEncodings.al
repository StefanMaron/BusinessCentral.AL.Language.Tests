// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/blob/blob-createinstream-method
// Scope: in-scope
// Fixtures used: table 74200, codeunit 69160 "Probe Observer"
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74201 "LT StT Encodings"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Fresh(var Rec: Record "LT StT Rec")
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 1;
        Rec.Insert();
    end;

    local procedure Sample(): Text
    var
        T: Text;
    begin
        // a-umlaut, o-umlaut, u-umlaut, sharp s, euro sign, e-acute
        T := 'a';
        T[2] := 228;
        T[3] := 246;
        T[4] := 252;
        T[5] := 223;
        T[6] := 8364;
        T[7] := 233;
        exit(T);
    end;

    local procedure LengthWith(Enc: TextEncoding; Value: Text): Integer
    var
        Rec: Record "LT StT Rec";
        Out: OutStream;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out, Enc);
        Out.WriteText(Value);
        Rec.Modify();
        Rec.CalcFields(Data);
        exit(Rec.Data.Length());
    end;

    local procedure RoundTrip(WEnc: TextEncoding; REnc: TextEncoding; Value: Text): Text
    var
        Rec: Record "LT StT Rec";
        Out: OutStream;
        Ins: InStream;
        T: Text;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out, WEnc);
        Out.WriteText(Value);
        Rec.Modify();
        Rec.Data.CreateInStream(Ins, REnc);
        Ins.ReadText(T);
        exit(T);
    end;

    local procedure Codes(Value: Text): Text
    var
        i: Integer;
        R: Text;
    begin
        for i := 1 to StrLen(Value) do begin
            if R <> '' then
                R += ',';
            R += Format(Value[i]);
        end;
        exit(R);
    end;

    [Test]
    procedure AsciiLengthPerEncoding()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('utf8', Format(LengthWith(TextEncoding::UTF8, 'abc')));
        Observer.Observe('utf16', Format(LengthWith(TextEncoding::UTF16, 'abc')));
        Observer.Observe('msdos', Format(LengthWith(TextEncoding::MSDos, 'abc')));
        Observer.Observe('windows', Format(LengthWith(TextEncoding::Windows, 'abc')));
        Observer.Observe('utf8-empty', Format(LengthWith(TextEncoding::UTF8, '')));
        Observer.Observe('utf16-empty', Format(LengthWith(TextEncoding::UTF16, '')));
        Observer.Expect('utf8', '3');
        Observer.Expect('utf16', '6');
        Observer.Expect('msdos', '3');
        Observer.Expect('windows', '3');
        Observer.Expect('utf8-empty', '0');
        Observer.Expect('utf16-empty', '0');
        Observer.Verify();
    end;

    [Test]
    procedure NonAsciiLengthPerEncoding()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('strlen', Format(StrLen(Sample())));
        Observer.Observe('utf8', Format(LengthWith(TextEncoding::UTF8, Sample())));
        Observer.Observe('utf16', Format(LengthWith(TextEncoding::UTF16, Sample())));
        Observer.Observe('msdos', Format(LengthWith(TextEncoding::MSDos, Sample())));
        Observer.Observe('windows', Format(LengthWith(TextEncoding::Windows, Sample())));
        Observer.Expect('strlen', '7');
        Observer.Expect('utf8', '14');
        Observer.Expect('utf16', '14');
        Observer.Expect('msdos', '7');
        Observer.Expect('windows', '7');
        Observer.Verify();
    end;

    [Test]
    procedure DefaultEncodingLength()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.WriteText(Sample());
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('default', Format(Rec.Data.Length()));
        Observer.Observe('utf8-same', Format(Rec.Data.Length() = LengthWith(TextEncoding::UTF8, Sample())));
        Observer.Observe('utf16-same', Format(Rec.Data.Length() = LengthWith(TextEncoding::UTF16, Sample())));
        Observer.Expect('default', '7');
        Observer.Expect('utf8-same', 'No');
        Observer.Expect('utf16-same', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure RoundTripSameEncoding()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('utf8', Codes(RoundTrip(TextEncoding::UTF8, TextEncoding::UTF8, Sample())));
        Observer.Observe('utf16', Codes(RoundTrip(TextEncoding::UTF16, TextEncoding::UTF16, Sample())));
        Observer.Observe('msdos', Codes(RoundTrip(TextEncoding::MSDos, TextEncoding::MSDos, Sample())));
        Observer.Observe('windows', Codes(RoundTrip(TextEncoding::Windows, TextEncoding::Windows, Sample())));
        Observer.Expect('utf8', 'a,ä,ö,ü,ß,€,é');
        Observer.Expect('utf16', 'a,ä,ö,ü,ß,€,é');
        Observer.Expect('msdos', 'a,ä,ö,ü,ß,€,é');
        Observer.Expect('windows', 'a,ä,ö,ü,ß,€,é');
        Observer.Verify();
    end;

    [Test]
    procedure CrossEncodingUtf8ToOthers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('utf8-as-utf16', Codes(RoundTrip(TextEncoding::UTF8, TextEncoding::UTF16, Sample() + 'x')));
        Observer.Observe('utf8-as-msdos', Codes(RoundTrip(TextEncoding::UTF8, TextEncoding::MSDos, Sample())));
        Observer.Observe('utf8-as-windows', Codes(RoundTrip(TextEncoding::UTF8, TextEncoding::Windows, Sample())));
        Observer.Expect('utf8-as-utf16', '썡,쎤,쎶,쎼,,겂,꧃');
        Observer.Expect('utf8-as-msdos', 'a,Ã,¤,Ã,¶,Ã,¼,Ã,Ÿ,â,‚,¬,Ã,©');
        Observer.Expect('utf8-as-windows', 'a,Ã,¤,Ã,¶,Ã,¼,Ã,Ÿ,â,‚,¬,Ã,©');
        Observer.Verify();
    end;

    [Test]
    procedure CrossEncodingWindowsToOthers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Observer.Observe('windows-as-utf8', Codes(RoundTrip(TextEncoding::Windows, TextEncoding::UTF8, Sample())));
        Observer.ObserveError('af150');
        Observer.Observe('windows-as-msdos', Codes(RoundTrip(TextEncoding::Windows, TextEncoding::MSDos, Sample())));
        Observer.Observe('windows-as-utf16', Codes(RoundTrip(TextEncoding::Windows, TextEncoding::UTF16, Sample() + 'xy')));
        Observer.Expect('af150|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af150|code', 'InvalidStreamData');
        Observer.Expect('windows-as-msdos', 'a,ä,ö,ü,ß,€,é');
        Observer.Expect('windows-as-utf16', ',ﳶ,胟,磩');
        Observer.Verify();
    end;

    [Test]
    procedure CrossEncodingMsDosAndUtf16()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Observer.Observe('msdos-as-utf8', Codes(RoundTrip(TextEncoding::MSDos, TextEncoding::UTF8, Sample())));
        Observer.ObserveError('af162');
        Observer.Observe('msdos-as-windows', Codes(RoundTrip(TextEncoding::MSDos, TextEncoding::Windows, Sample())));
        Observer.Observe('utf16-as-utf8', Codes(RoundTrip(TextEncoding::UTF16, TextEncoding::UTF8, 'ab')));
        Observer.Observe('utf16-as-windows', Codes(RoundTrip(TextEncoding::UTF16, TextEncoding::Windows, 'ab')));
        Observer.Expect('af162|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af162|code', 'InvalidStreamData');
        Observer.Expect('msdos-as-windows', 'a,ä,ö,ü,ß,€,é');
        Observer.Expect('utf16-as-utf8', 'a');
        Observer.Expect('utf16-as-windows', 'a');
        Observer.Verify();
    end;

    [Test]
    procedure UnmappableCharacters()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        T := 'a';
        T[2] := 8364; // euro
        T[3] := 960; // pi
        T[4] := 1078; // cyrillic zhe
        T[5] := 20013; // CJK
        T[6] := 'b';
        Observer.Observe('utf8', Codes(RoundTrip(TextEncoding::UTF8, TextEncoding::UTF8, T)));
        Observer.Observe('utf16', Codes(RoundTrip(TextEncoding::UTF16, TextEncoding::UTF16, T)));
        Observer.Observe('msdos', Codes(RoundTrip(TextEncoding::MSDos, TextEncoding::MSDos, T)));
        Observer.Observe('windows', Codes(RoundTrip(TextEncoding::Windows, TextEncoding::Windows, T)));
        Observer.Observe('windows-len', Format(LengthWith(TextEncoding::Windows, T)));
        Observer.Observe('msdos-len', Format(LengthWith(TextEncoding::MSDos, T)));
        Observer.Expect('utf8', 'a,€,π,ж,中,b');
        Observer.Expect('utf16', 'a,€,π,ж,中,b');
        Observer.Expect('msdos', 'a,€,p,?,?,b');
        Observer.Expect('windows', 'a,€,p,?,?,b');
        Observer.Expect('windows-len', '6');
        Observer.Expect('msdos-len', '6');
        Observer.Verify();
    end;

    [Test]
    procedure SurrogatePair()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        T[1] := 55357; // D83D
        T[2] := 56832; // DE00 grinning face
        Observer.Observe('strlen', Format(StrLen(T)));
        Observer.Observe('utf8-len', Format(LengthWith(TextEncoding::UTF8, T)));
        Observer.Observe('utf16-len', Format(LengthWith(TextEncoding::UTF16, T)));
        Observer.Observe('utf8-rt', Codes(RoundTrip(TextEncoding::UTF8, TextEncoding::UTF8, T)));
        Observer.Observe('utf16-rt', Codes(RoundTrip(TextEncoding::UTF16, TextEncoding::UTF16, T)));
        Observer.Expect('strlen', '2');
        Observer.Expect('utf8-len', '4');
        Observer.Expect('utf16-len', '4');
        Observer.Expect('utf8-rt', '\uD83D,\uDE00');
        Observer.Expect('utf16-rt', '\uD83D,\uDE00');
        Observer.Verify();
    end;

    [Test]
    procedure LoneSurrogate()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        T[1] := 'a';
        T[2] := 55357;
        T[3] := 'b';
        Observer.Observe('utf8-len', Format(LengthWith(TextEncoding::UTF8, T)));
        Observer.Observe('utf8-rt', Codes(RoundTrip(TextEncoding::UTF8, TextEncoding::UTF8, T)));
        Observer.Observe('utf16-len', Format(LengthWith(TextEncoding::UTF16, T)));
        Observer.Observe('utf16-rt', Codes(RoundTrip(TextEncoding::UTF16, TextEncoding::UTF16, T)));
        Observer.Expect('utf8-len', '5');
        Observer.Expect('utf8-rt', 'a,�,b');
        Observer.Expect('utf16-len', '6');
        Observer.Expect('utf16-rt', 'a,�,b');
        Observer.Verify();
    end;

    [Test]
    procedure LineEndingsPerEncoding()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out, TextEncoding::UTF8);
        Out.WriteText('a');
        Out.WriteText();
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('utf8', Format(Rec.Data.Length()));
        Rec.Data.CreateOutStream(Out, TextEncoding::UTF16);
        Out.WriteText('a');
        Out.WriteText();
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('utf16', Format(Rec.Data.Length()));
        Rec.Data.CreateOutStream(Out, TextEncoding::MSDos);
        Out.WriteText('a');
        Out.WriteText();
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('msdos', Format(Rec.Data.Length()));
        Rec.Data.CreateOutStream(Out, TextEncoding::Windows);
        Out.WriteText('a');
        Out.WriteText();
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('windows', Format(Rec.Data.Length()));
        Observer.Expect('utf8', '3');
        Observer.Expect('utf16', '6');
        Observer.Expect('msdos', '6');
        Observer.Expect('windows', '6');
        Observer.Verify();
    end;

    [Test]
    procedure ReadLinesInUtf16()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        T: Text;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out, TextEncoding::UTF16);
        Out.WriteText(Sample());
        Out.WriteText();
        Out.WriteText('second');
        Out.WriteText();
        Rec.Modify();
        Rec.Data.CreateInStream(Ins, TextEncoding::UTF16);
        Ins.ReadText(T);
        Observer.Observe('l1', Codes(T));
        Ins.ReadText(T);
        Observer.Observe('l2', T);
        Observer.Observe('eos', Format(Ins.EOS()));
        Observer.Expect('l1', 'a,ä,ö,ü,ß,€,é');
        Observer.Expect('l2', 'second');
        Observer.Expect('eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadTextLengthMultiByte()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        T: Text;
        N: Integer;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out, TextEncoding::UTF8);
        Out.WriteText(Sample());
        Rec.Modify();
        Rec.Data.CreateInStream(Ins, TextEncoding::UTF8);
        N := Ins.ReadText(T, 3);
        Observer.Observe('n1', Format(N));
        Observer.Observe('t1', Codes(T));
        N := Ins.ReadText(T, 10);
        Observer.Observe('n2', Format(N));
        Observer.Observe('t2', Codes(T));
        Observer.Expect('n1', '5');
        Observer.Expect('t1', 'a,ä,ö');
        Observer.Expect('n2', '9');
        Observer.Expect('t2', 'ü,ß,€,é');
        Observer.Verify();
    end;

    [Test]
    procedure PositionPerEncoding()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        T: Text;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out, TextEncoding::UTF8);
        Out.WriteText(Sample());
        Rec.Modify();
        Rec.Data.CreateInStream(Ins, TextEncoding::UTF8);
        Ins.ReadText(T);
        Observer.Observe('utf8-pos', Format(Ins.Position()));
        Rec.Data.CreateOutStream(Out, TextEncoding::UTF16);
        Out.WriteText(Sample());
        Rec.Modify();
        Rec.Data.CreateInStream(Ins, TextEncoding::UTF16);
        Ins.ReadText(T);
        Observer.Observe('utf16-pos', Format(Ins.Position()));
        Observer.Expect('utf8-pos', '15');
        Observer.Expect('utf16-pos', '3');
        Observer.Verify();
    end;

    [Test]
    procedure EosAfterEncodedRead()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        T: Text;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out, TextEncoding::UTF16);
        Out.WriteText('x');
        Rec.Modify();
        Rec.Data.CreateInStream(Ins, TextEncoding::UTF16);
        Observer.Observe('eos-before', Format(Ins.EOS()));
        Ins.ReadText(T);
        Observer.Observe('eos-after', Format(Ins.EOS()));
        Observer.Expect('eos-before', 'No');
        Observer.Expect('eos-after', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure WriteBinaryIgnoresEncoding()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out, TextEncoding::UTF16);
        Out.Write(1);
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('int-utf16', Format(Rec.Data.Length()));
        Rec.Data.CreateOutStream(Out, TextEncoding::UTF8);
        Out.Write('abc');
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('text-write-utf8', Format(Rec.Data.Length()));
        Rec.Data.CreateOutStream(Out, TextEncoding::UTF16);
        Out.Write('abc');
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('text-write-utf16', Format(Rec.Data.Length()));
        Rec.Data.CreateOutStream(Out, TextEncoding::Windows);
        Out.Write(Sample());
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('text-write-windows-nonascii', Format(Rec.Data.Length()));
        Observer.Expect('int-utf16', '4');
        Observer.Expect('text-write-utf8', '4');
        Observer.Expect('text-write-utf16', '8');
        Observer.Expect('text-write-windows-nonascii', '8');
        Observer.Verify();
    end;
}
