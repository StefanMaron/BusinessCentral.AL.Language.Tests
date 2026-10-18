// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/bigtext/bigtext-write-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (codeunit 4100)
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: BigText.Write into a Blob OutStream. Non-ASCII text (a with umlaut, euro sign, a Cyrillic letter) on a default stream and on a UTF-8 stream,
//   the bytes read back with InStream.Read(Byte); a stream that was written with WriteText before; WriteText after BigText.Write;
//   streams created with UTF16, Windows and MSDos for ASCII text; an empty BigText (Blob length and HasValue).
// BC versions: all (CI)

codeunit 67412 "LT BTW Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure HexOf(B: Byte): Text
    var
        Digits: Text;
    begin
        Digits := '0123456789ABCDEF';
        exit(CopyStr(Digits, (B div 16) + 1, 1) + CopyStr(Digits, (B mod 16) + 1, 1));
    end;

    local procedure ObserveBlob(var Observer: Codeunit "Probe Observer"; Tag: Text; var TempBlob: Codeunit "Temp Blob")
    var
        Ins: InStream;
        B: Byte;
        Hex: Text;
    begin
        Observer.Observe(Tag + '.len', Format(TempBlob.Length()));
        Observer.Observe(Tag + '.hasvalue', Format(TempBlob.HasValue()));
        TempBlob.CreateInStream(Ins);
        while not Ins.EOS() do begin
            Ins.Read(B);
            if Hex <> '' then
                Hex += ' ';
            Hex += HexOf(B);
        end;
        Observer.Observe(Tag + '.bytes', '[' + Hex + ']');
    end;

    local procedure ObserveReadBack(var Observer: Codeunit "Probe Observer"; Tag: Text; var TempBlob: Codeunit "Temp Blob")
    var
        Ins: InStream;
        Back: BigText;
        T: Text;
        i: Integer;
        C: Integer;
        Codes: Text;
    begin
        TempBlob.CreateInStream(Ins);
        Back.Read(Ins);
        Observer.Observe(Tag + '.readlen', Format(Back.Length()));
        if Back.Length() > 0 then begin
            Back.GetSubText(T, 1);
            for i := 1 to StrLen(T) do begin
                if Codes <> '' then
                    Codes += ',';
                C := T[i];
                Codes += Format(C, 0, 9);
            end;
        end;
        Observer.Observe(Tag + '.readcodes', '[' + Codes + ']');
    end;

    local procedure NonAscii(): Text
    var
        T: Text;
    begin
        T[1] := 228;
        T[2] := 8364;
        T[3] := 1046;
        exit(T);
    end;

    [Test]
    procedure Write_NonAscii_DefaultStream()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Big: BigText;
        Out: OutStream;
    begin
        Big.AddText(NonAscii());
        TempBlob.CreateOutStream(Out);
        Big.Write(Out);
        ObserveBlob(Observer, 'default', TempBlob);
        ObserveReadBack(Observer, 'default', TempBlob);
        Observer.Finish();
    end;

    [Test]
    procedure Write_NonAscii_Utf8Stream()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Big: BigText;
        Out: OutStream;
    begin
        Big.AddText(NonAscii());
        TempBlob.CreateOutStream(Out, TextEncoding::UTF8);
        Big.Write(Out);
        ObserveBlob(Observer, 'utf8', TempBlob);
        ObserveReadBack(Observer, 'utf8', TempBlob);
        Observer.Finish();
    end;

    [Test]
    procedure Write_NonAscii_ExplicitEncodings()
    var
        Observer: Codeunit "Probe Observer";
        Utf16Blob: Codeunit "Temp Blob";
        WindowsBlob: Codeunit "Temp Blob";
        MsDosBlob: Codeunit "Temp Blob";
        Big: BigText;
        Out: OutStream;
    begin
        Big.AddText(NonAscii());
        Utf16Blob.CreateOutStream(Out, TextEncoding::UTF16);
        Big.Write(Out);
        ObserveBlob(Observer, 'utf16', Utf16Blob);
        ObserveReadBack(Observer, 'utf16', Utf16Blob);
        WindowsBlob.CreateOutStream(Out, TextEncoding::Windows);
        Big.Write(Out);
        ObserveBlob(Observer, 'windows', WindowsBlob);
        ObserveReadBack(Observer, 'windows', WindowsBlob);
        MsDosBlob.CreateOutStream(Out, TextEncoding::MSDos);
        Big.Write(Out);
        ObserveBlob(Observer, 'msdos', MsDosBlob);
        ObserveReadBack(Observer, 'msdos', MsDosBlob);
        Observer.Finish();
    end;

    [Test]
    procedure Write_AfterWriteText_SameStream()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Big: BigText;
        Out: OutStream;
    begin
        Big.AddText('def');
        TempBlob.CreateOutStream(Out);
        Out.WriteText('abc');
        Big.Write(Out);
        ObserveBlob(Observer, 'after-writetext', TempBlob);
        Observer.Finish();
    end;

    [Test]
    procedure WriteText_AfterBigTextWrite_SameStream()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Big: BigText;
        Out: OutStream;
    begin
        Big.AddText('abc');
        TempBlob.CreateOutStream(Out);
        Big.Write(Out);
        Out.WriteText('xyz');
        ObserveBlob(Observer, 'before-writetext', TempBlob);
        Observer.Finish();
    end;

    [Test]
    procedure Write_ExplicitEncodings_Ascii()
    var
        Observer: Codeunit "Probe Observer";
        Utf16Blob: Codeunit "Temp Blob";
        WindowsBlob: Codeunit "Temp Blob";
        MsDosBlob: Codeunit "Temp Blob";
        Big: BigText;
        Out: OutStream;
    begin
        Big.AddText('abc');
        Utf16Blob.CreateOutStream(Out, TextEncoding::UTF16);
        Big.Write(Out);
        ObserveBlob(Observer, 'utf16', Utf16Blob);
        WindowsBlob.CreateOutStream(Out, TextEncoding::Windows);
        Big.Write(Out);
        ObserveBlob(Observer, 'windows', WindowsBlob);
        MsDosBlob.CreateOutStream(Out, TextEncoding::MSDos);
        Big.Write(Out);
        ObserveBlob(Observer, 'msdos', MsDosBlob);
        Observer.Finish();
    end;

    [Test]
    procedure Write_EmptyBigText()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Big: BigText;
        Out: OutStream;
    begin
        TempBlob.CreateOutStream(Out);
        Big.Write(Out);
        ObserveBlob(Observer, 'empty', TempBlob);
        Observer.Finish();
    end;
}
