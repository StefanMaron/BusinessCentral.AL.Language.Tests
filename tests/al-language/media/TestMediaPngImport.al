// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/media/media-importstream-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/media/media-exportstream-method
// Scope: in-scope
// Fixtures used: ALT Media (60980)
//
// Companion of StefanMaron/BusinessCentral.AL.Runner#2570, which reports that AL Runner
// refuses to import ANY recognized image format into a Media field (it needs
// System.Drawing to decode, which has no support on the runner's Linux host), and proposes
// narrowing that refusal for PNG specifically, since PNG validity is checkable
// structurally (signature, chunk order, per-chunk CRC32, well-formed IHDR) without
// decoding. These tests pin the real BC behavior the narrowed runner implementation must
// match: a structurally valid PNG imports successfully and round-trips byte-for-byte, and
// a PNG whose bytes are corrupt (valid signature, damaged IHDR chunk CRC) is rejected by
// BC's own image-loading error path.
//
// The PNG payloads below are the minimum valid 1x1-pixel PNG (68 bytes) and the same file
// with one byte of its IHDR chunk's CRC flipped, both base64-encoded so the AL source stays
// plain text. Verified independently (Python's zlib.crc32 against each chunk) that the
// "valid" payload's three chunks (IHDR, IDAT, IEND) all have correct CRCs, and that the
// "corrupted" payload differs from it only in the IHDR CRC field.
codeunit 60130 "Test Media Png Import"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        ValidPngBase64: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=', Locked = true;
        CorruptIhdrCrcPngBase64: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAADFfptVAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=', Locked = true;

    [Test]
    procedure Media_ImportStream_ValidPng_HasValueTrue()
    // CLAIM: a structurally valid PNG imports into a Media field successfully, and the
    // field reports HasValue() = true afterwards.
    var
        Rec: Record "ALT Media";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        InStr: InStream;
        OutStr: OutStream;
    begin
        Initialize();

        Rec.Code := 'PNG1';
        Rec.Insert();

        TempBlob.CreateOutStream(OutStr);
        Base64Convert.FromBase64(ValidPngBase64, OutStr);
        TempBlob.CreateInStream(InStr);

        Rec.Picture.ImportStream(InStr, 'a png');
        Rec.Modify();

        Rec.Get('PNG1');
        Assert.IsTrue(Rec.Picture.HasValue(), 'Media field must have a value after importing a valid PNG');
    end;

    [Test]
    procedure Media_ExportStream_ValidPng_SameByteLengthAsImported()
    // CLAIM: ExportStream() returns the same number of bytes that were imported — the
    // stored media is the imported PNG's own bytes, not a re-encoded/decoded copy.
    var
        Rec: Record "ALT Media";
        ImportBlob: Codeunit "Temp Blob";
        ExportBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        InStr: InStream;
        ImportOutStr: OutStream;
        ExportOutStr: OutStream;
        ImportedLength: Integer;
    begin
        Initialize();

        Rec.Code := 'PNG2';
        Rec.Insert();

        ImportBlob.CreateOutStream(ImportOutStr);
        Base64Convert.FromBase64(ValidPngBase64, ImportOutStr);
        ImportedLength := ImportBlob.Length();
        ImportBlob.CreateInStream(InStr);

        Rec.Picture.ImportStream(InStr, 'a png');
        Rec.Modify();

        Rec.Get('PNG2');
        ExportBlob.CreateOutStream(ExportOutStr);
        Rec.Picture.ExportStream(ExportOutStr);

        Assert.AreEqual(ImportedLength, ExportBlob.Length(),
            'ExportStream() must return the same byte length that was imported');
    end;

    [Test]
    procedure Media_ImportStream_PngWithCorruptIhdrCrc_Fails()
    // CLAIM (negative): a PNG whose signature is valid but whose IHDR chunk CRC is
    // corrupted is rejected by BC's own image-loading error path, not silently accepted.
    var
        Rec: Record "ALT Media";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        InStr: InStream;
        OutStr: OutStream;
    begin
        Initialize();

        Rec.Code := 'PNG3';
        Rec.Insert();

        TempBlob.CreateOutStream(OutStr);
        Base64Convert.FromBase64(CorruptIhdrCrcPngBase64, OutStr);
        TempBlob.CreateInStream(InStr);

        asserterror Rec.Picture.ImportStream(InStr, 'corrupt png');
        Assert.ExpectedError('The media object could not be loaded because it is not a valid image type, such as JPEG, GIF, or PNG');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
