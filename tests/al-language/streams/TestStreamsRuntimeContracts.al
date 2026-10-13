// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-data-type
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/instream/instream-readtext-method
// Scope: in-scope
// Fixtures used: ALT Blob (60008), ALTFixtureCleanup (60019), shared Assert (60021)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins the bytes OutStream.Write and WriteText produce (as Base64, so the bytes are exact), the
// default and explicit text encodings, how ReadText splits lines, that CreateOutStream does not
// empty a Blob that already holds data, that an InStream sees later writes, Blob.Length of a
// Blob that was not loaded with CalcFields, ArrayLen, and the ordinals of TextEncoding.
// BC versions: 27.5

codeunit 68136 "Probe Streams Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    local procedure Base64Of(var TempBlob: Codeunit "Temp Blob"): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        InStr: InStream;
    begin
        TempBlob.CreateInStream(InStr);
        exit(Base64Convert.ToBase64(InStr));
    end;

    [Test]
    procedure WriteText_DefaultEncodingIsWindows1252_NotUtf8()
    // CLAIM: without an encoding argument 'é' is the single byte E9; with UTF8 it is C3 A9.
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        Initialize();

        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('héllo');
        Assert.AreEqual('68E96C6C6F', HexOf(TempBlob), 'default encoding');
    end;

    local procedure HexOf(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InStr: InStream;
        Value: Byte;
        Result: Text;
        Digits: Text;
    begin
        Digits := '0123456789ABCDEF';
        TempBlob.CreateInStream(InStr);
        while not InStr.EOS() do begin
            InStr.Read(Value);
            Result += CopyStr(Digits, (Value div 16) + 1, 1) + CopyStr(Digits, (Value mod 16) + 1, 1);
        end;
        exit(Result);
    end;

    [Test]
    procedure WriteText_ExplicitEncodings_Bytes()
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        Initialize();

        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText('héllo');
        Assert.AreEqual('68C3A96C6C6F', HexOf(TempBlob), 'UTF8');

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF16);
        OutStr.WriteText('hé');
        Assert.AreEqual('6800E900', HexOf(TempBlob), 'UTF16: little endian, no byte order mark');

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr, TextEncoding::Windows);
        OutStr.WriteText('hé€Ж');
        Assert.AreEqual('68E9803F', HexOf(TempBlob), 'Windows: the euro sign is 80 and a character with no mapping is ?');

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr, TextEncoding::MSDos);
        OutStr.WriteText('hé€Ж');
        Assert.AreEqual('68E9803F', HexOf(TempBlob), 'MSDos gives the same bytes as Windows');
    end;

    [Test]
    procedure OutStream_Write_BinaryFormsOfEachType()
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        BigValue: BigInteger;
    begin
        Initialize();

        TempBlob.CreateOutStream(OutStr);
        OutStr.Write(1);
        OutStr.Write(258);
        Assert.AreEqual('0100000002010000', HexOf(TempBlob), 'Integer: 4 bytes little endian');

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        OutStr.Write(true);
        Assert.AreEqual('01000000', HexOf(TempBlob), 'Boolean: 4 bytes');

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        Evaluate(BigValue, '5000000000');
        OutStr.Write(BigValue);
        Assert.AreEqual('00F2052A01000000', HexOf(TempBlob), 'BigInteger: 8 bytes little endian');

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        OutStr.Write(DMY2Date(5, 3, 2024));
        Assert.AreEqual('E78F1600', HexOf(TempBlob), 'Date: 4 bytes');

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        OutStr.Write(143005T);
        Assert.AreEqual('C9951C03', HexOf(TempBlob), 'Time: 4 bytes');

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        OutStr.Write('text');
        Assert.AreEqual('7465787400', HexOf(TempBlob), 'Text: the characters and a zero byte');

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        OutStr.Write(1.5);
        Assert.AreEqual('400000000000000000150000', HexOf(TempBlob), 'Decimal: 12 bytes');
    end;

    [Test]
    procedure OutStream_WriteText_WithoutArgument_WritesCarriageReturnLineFeed()
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        Initialize();

        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('abc');
        OutStr.WriteText();
        OutStr.WriteText('def');

        Assert.AreEqual('6162630D0A646566', HexOf(TempBlob), 'WriteText with a text writes no terminator; WriteText() writes CR LF');
    end;

    local procedure LinesOf(Content: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText(Content);
        TempBlob.CreateInStream(InStr);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result += '[' + Line + ']';
        end;
        exit(Result);
    end;

    [Test]
    procedure InStream_ReadText_SplitsAtLineFeed_AndDropsALoneCarriageReturn()
    var
        Cr: Text[1];
        Lf: Text[1];
    begin
        Initialize();
        Cr[1] := 13;
        Lf[1] := 10;

        Assert.AreEqual('[a][b]', LinesOf('a' + Lf + 'b'), 'LF');
        Assert.AreEqual('[a][b]', LinesOf('a' + Cr + Lf + 'b'), 'CR LF is one terminator');
        Assert.AreEqual('[a][b]', LinesOf('a' + Lf + Cr + 'b'), 'LF CR: the CR is dropped');
        Assert.AreEqual('[ab]', LinesOf('a' + Cr + 'b'), 'a lone CR is not a terminator and is dropped');
        Assert.AreEqual('[ab]', LinesOf('a' + Cr + Cr + 'b'), 'two CRs are dropped');
        Assert.AreEqual('[a][][b]', LinesOf('a' + Lf + Lf + 'b'), 'an empty line');
        Assert.AreEqual('[a]', LinesOf('a' + Lf), 'a final terminator does not add an empty line');
        Assert.AreEqual('[a]', LinesOf('a' + Cr), 'a final CR does not add a line either');
        Assert.AreEqual('', LinesOf(''), 'no content, no line');
    end;

    [Test]
    procedure BlobField_CreateOutStream_DoesNotEmptyExistingData()
    // CLAIM: writing a shorter text over an existing one replaces only the leading bytes; the Length stays 15.
    var
        ALTBlob: Record "ALT Blob";
        OutStr: OutStream;
        InStr: InStream;
        Content: Text;
    begin
        Initialize();
        ALTBlob.Init();
        ALTBlob.Code := 'S3';
        ALTBlob.Insert();
        ALTBlob.Data.CreateOutStream(OutStr);
        OutStr.WriteText('first-long-text');
        ALTBlob.Modify();

        ALTBlob.Data.CreateOutStream(OutStr);
        OutStr.WriteText('x');
        ALTBlob.Modify();

        ALTBlob.CalcFields(Data);
        ALTBlob.Data.CreateInStream(InStr);
        InStr.ReadText(Content);
        Assert.AreEqual('xirst-long-text', Content, 'content');
        Assert.AreEqual(15, ALTBlob.Data.Length(), 'length');
    end;

    [Test]
    procedure InStream_CreatedBeforeAWrite_SeesTheWrite()
    // CLAIM: an InStream is a live view of the Blob, not a snapshot taken when it was created.
    var
        ALTBlob: Record "ALT Blob";
        OutStr: OutStream;
        InStr: InStream;
        Content: Text;
    begin
        Initialize();
        ALTBlob.Init();
        ALTBlob.Code := 'S4';
        ALTBlob.Insert();
        ALTBlob.Data.CreateOutStream(OutStr);
        OutStr.WriteText('first-long-text');

        ALTBlob.Data.CreateInStream(InStr);
        ALTBlob.Data.CreateOutStream(OutStr);
        OutStr.WriteText('later');
        InStr.ReadText(Content);

        Assert.AreEqual('later-long-text', Content, 'the InStream sees the later write');
    end;

    [Test]
    procedure Blob_Length_WithoutCalcFields_ReportsTheStoredSize()
    // CLAIM: after Modify the loaded length is 5; after a Get without CalcFields it is 11 (not 0 and not 5); after CalcFields it is 5.
    var
        ALTBlob: Record "ALT Blob";
        OutStr: OutStream;
    begin
        Initialize();
        ALTBlob.Init();
        ALTBlob.Code := 'S';
        ALTBlob.Insert();
        ALTBlob.Data.CreateOutStream(OutStr);
        OutStr.WriteText('hello');
        ALTBlob.Modify();

        Assert.AreEqual(5, ALTBlob.Data.Length(), 'after Modify');
        ALTBlob.Get('S');
        Assert.AreEqual(11, ALTBlob.Data.Length(), 'after Get, before CalcFields');
        ALTBlob.CalcFields(Data);
        Assert.AreEqual(5, ALTBlob.Data.Length(), 'after CalcFields');
    end;

    [Test]
    procedure ArrayLen_MultiDimensional_WithAndWithoutDimension()
    var
        Grid: array[2, 3] of Integer;
    begin
        Initialize();

        Assert.AreEqual(2, ArrayLen(Grid, 1), 'dimension 1');
        Assert.AreEqual(3, ArrayLen(Grid, 2), 'dimension 2');
        Assert.AreEqual(6, ArrayLen(Grid), 'without a dimension: the total');
    end;

    [Test]
    procedure TextEncoding_Ordinals()
    begin
        Initialize();

        Assert.AreEqual('0', Format(TextEncoding::MSDos, 0, 2), 'MSDos');
        Assert.AreEqual('1', Format(TextEncoding::UTF8, 0, 2), 'UTF8');
        Assert.AreEqual('2', Format(TextEncoding::UTF16, 0, 2), 'UTF16');
        Assert.AreEqual('3', Format(TextEncoding::Windows, 0, 2), 'Windows');
    end;
}
