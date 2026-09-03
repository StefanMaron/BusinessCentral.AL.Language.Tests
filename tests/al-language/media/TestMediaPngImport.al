// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/media/media-importstream-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/media/media-exportstream-method
// Scope: in-scope
// Fixtures used: ALT Media (60980)
//
// Companion of StefanMaron/BusinessCentral.AL.Runner#2570, which reports that AL Runner
// refuses to import ANY recognized image format into a Media field (it needs
// System.Drawing to decode, which has no support on the runner's Linux host), and proposes
// narrowing that refusal for PNG.
//
// MEASURED, not assumed: this file went through two rounds of corpus CI (27.0-28.4, all 8
// legs both times) correcting assumptions a decompiled exception mapper could not settle.
// Round 1 asserted a corrupt IHDR-chunk-CRC PNG is rejected; BC accepted it. Round 2 tried
// to separate "BC skips CRC checks" from "BC validates structure at all" with three more
// negative cases (signature-only, truncated mid-chunk, IHDR width=0) — BC accepted every
// one of those too, identically across all 8 legs both times. The conclusion this file now
// encodes: BC's PNG acceptance for a Media field is the 8-byte signature match and nothing
// more — no chunk CRC check, no IHDR structural validation, not even "is there a single
// byte of chunk data after the signature". A PNG-signature-prefixed stream of ANY content
// is accepted. This is the actual answer, not a hedge — see each test's CLAIM for the
// specific round-2 case it pins.
//
// All PNG payloads are byte-verified independently with Python (struct + zlib.crc32) and
// base64-encoded so the AL source stays plain text.
codeunit 60130 "Test Media Png Import"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        // Minimum valid 1x1-pixel PNG (68 bytes): signature + IHDR(13, width=1, height=1)
        // + IDAT(11) + IEND(0), every chunk CRC verified correct independently.
        ValidPngBase64: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=', Locked = true;
        // Same 68 bytes with one byte of the IHDR chunk's CRC field flipped — every other
        // byte, including the IHDR data itself (width=1, height=1), is unchanged.
        CorruptIhdrCrcPngBase64: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAADFfptVAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=', Locked = true;
        // Just the 8-byte PNG signature, nothing else — no IHDR, no pixel data at all.
        SignatureOnlyPngBase64: Label 'iVBORw0KGgo=', Locked = true;
        // Signature + IHDR chunk header (length=13, type="IHDR") + only the first 4 of
        // IHDR's 13 data bytes, then nothing — cut off mid-chunk, no CRC, no IDAT/IEND.
        TruncatedMidIhdrPngBase64: Label 'iVBORw0KGgoAAAANSUhEUgAAAAE=', Locked = true;
        // Structurally complete otherwise (correct CRCs throughout, real IDAT/IEND), but
        // IHDR's width field is 0.
        ZeroWidthIhdrPngBase64: Label 'iVBORw0KGgoAAAANSUhEUgAAAAAAAAABCAAAAADVvPBrAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=', Locked = true;
        // Plain text with no PNG signature at all — the pre-existing "not an image, falls
        // back to octet-stream" path this PR must NOT change.
        NonPngBase64: Label 'dGhpcyBpcyBub3QgYSBwbmcgYXQgYWxsLCBqdXN0IHBsYWluIHRleHQgYnl0ZXM=', Locked = true;

    [Test]
    procedure Media_ImportStream_ValidPng_HasValueTrue()
    // CLAIM: a structurally valid PNG imports into a Media field successfully, and the
    // field reports HasValue() = true afterwards.
    var
        Rec: Record "ALT Media";
    begin
        Initialize();
        ImportBase64(Rec, 'PNG1', ValidPngBase64);
        Rec.Get('PNG1');
        Assert.IsTrue(Rec.Picture.HasValue(), 'Media field must have a value after importing a valid PNG');
    end;

    [Test]
    procedure Media_ExportStream_ValidPng_SameByteLengthAsImported()
    // CLAIM: ExportStream() returns the same number of bytes that were imported — the
    // stored media is the imported PNG's own bytes, not a re-encoded/decoded copy.
    var
        Rec: Record "ALT Media";
        ExportBlob: Codeunit "Temp Blob";
        ExportOutStr: OutStream;
        ImportedLength: Integer;
    begin
        Initialize();
        ImportedLength := ImportBase64(Rec, 'PNG2', ValidPngBase64);

        Rec.Get('PNG2');
        ExportBlob.CreateOutStream(ExportOutStr);
        Rec.Picture.ExportStream(ExportOutStr);

        Assert.AreEqual(ImportedLength, ExportBlob.Length(),
            'ExportStream() must return the same byte length that was imported');
    end;

    [Test]
    procedure Media_ImportStream_PngWithCorruptIhdrCrc_Succeeds()
    // CLAIM: a PNG whose signature and IHDR data are valid but whose IHDR chunk CRC is
    // wrong still imports successfully. MEASURED: the first version of this test asserted
    // the opposite (rejection) and real BC (27.0-28.4, all 8 legs) falsified it.
    var
        Rec: Record "ALT Media";
    begin
        Initialize();
        ImportBase64(Rec, 'PNG3', CorruptIhdrCrcPngBase64);
        Rec.Get('PNG3');
        Assert.IsTrue(Rec.Picture.HasValue(),
            'A PNG with a wrong IHDR CRC (but otherwise valid structure) must still import — BC does not check chunk CRCs');
    end;

    [Test]
    procedure Media_ImportStream_SignatureOnly_Succeeds()
    // CLAIM: a stream that is just the 8-byte PNG signature, with no IHDR and no pixel
    // data at all, still imports successfully. MEASURED (27.0-28.4, all 8 legs, twice):
    // the original version of this test asserted rejection and BC accepted it both times.
    // BC's PNG acceptance for a Media field really is the signature match alone.
    var
        Rec: Record "ALT Media";
    begin
        Initialize();
        ImportBase64(Rec, 'PNG4', SignatureOnlyPngBase64);
        Rec.Get('PNG4');
        Assert.IsTrue(Rec.Picture.HasValue(), 'A signature-only stream (no IHDR at all) must still import');
    end;

    [Test]
    procedure Media_ImportStream_TruncatedMidIhdr_Succeeds()
    // CLAIM: a stream cut off in the middle of the IHDR chunk (no CRC, no IDAT/IEND at
    // all) still imports successfully. MEASURED, same as the signature-only case above.
    var
        Rec: Record "ALT Media";
    begin
        Initialize();
        ImportBase64(Rec, 'PNG5', TruncatedMidIhdrPngBase64);
        Rec.Get('PNG5');
        Assert.IsTrue(Rec.Picture.HasValue(), 'A stream truncated mid-IHDR-chunk must still import');
    end;

    [Test]
    procedure Media_ImportStream_ZeroWidthIhdr_Succeeds()
    // CLAIM: a structurally complete PNG (correct CRCs, real IDAT/IEND) whose IHDR
    // declares width=0 still imports successfully. MEASURED, same as the two cases above —
    // BC does not sanity-check IHDR's declared dimensions either.
    var
        Rec: Record "ALT Media";
    begin
        Initialize();
        ImportBase64(Rec, 'PNG6', ZeroWidthIhdrPngBase64);
        Rec.Get('PNG6');
        Assert.IsTrue(Rec.Picture.HasValue(), 'A PNG with IHDR width=0 must still import');
    end;

    [Test]
    procedure Media_ImportStream_NonPngContent_StillFallsBackToOctetStream()
    // CLAIM: content with no PNG (or other image) signature at all still imports via the
    // pre-existing "not an image, fall back to application/octet-stream" path — this PR
    // must not change that.
    var
        Rec: Record "ALT Media";
    begin
        Initialize();
        ImportBase64(Rec, 'PNG7', NonPngBase64);
        Rec.Get('PNG7');
        Assert.IsTrue(Rec.Picture.HasValue(), 'Non-image content must still import via the octet-stream fallback');
    end;

    local procedure ImportBase64(var Rec: Record "ALT Media"; Code: Code[20]; Base64Content: Text) ImportedLength: Integer
    var
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        InStr: InStream;
        OutStr: OutStream;
    begin
        Rec.Init();
        Rec.Code := Code;
        Rec.Insert();

        TempBlob.CreateOutStream(OutStr);
        Base64Convert.FromBase64(Base64Content, OutStr);
        ImportedLength := TempBlob.Length();
        TempBlob.CreateInStream(InStr);

        Rec.Picture.ImportStream(InStr, 'test content');
        Rec.Modify();
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
