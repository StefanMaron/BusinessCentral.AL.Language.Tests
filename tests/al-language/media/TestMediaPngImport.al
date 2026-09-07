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
//
// ROUND 3 (issue #247) corrected the one test in this file that did NOT rest on CI: the
// export test asserted ExportStream() returns the same byte COUNT that was imported. BC
// re-encodes the image on import, so it does not -- 68 bytes in gives 99 out on two
// independent real-BC-on-Windows tiers. That test's own comment now records the mechanism
// and the three different output lengths three encoders produce; it asserts the imported
// PNG's DIMENSIONS survive the round-trip instead, which is the part a conforming encoder
// must preserve. Do not re-add a byte-length assertion here.
codeunit 60130 "Test Media Png Import"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        // Minimum valid 1x1-pixel PNG (68 bytes): signature + IHDR(13, width=1, height=1)
        // + IDAT(11) + IEND(0), every chunk CRC verified correct independently.
        ValidPngBase64: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=', Locked = true;
        // Base64 of bytes 0-14 of any PNG whose first chunk is a spec-conformant IHDR:
        // the 8-byte signature, the 4-byte chunk length 13, and "IHD". 20 characters is
        // exactly 5 Base64 groups, so this span pins bytes 0-14 and nothing beyond them.
        PngSignatureAndIhdrHeaderBase64: Label 'iVBORw0KGgoAAAANSUhE', Locked = true;
        // Base64 of bytes 15-23: the "R" of "IHDR", then width=1 and height=1 as big-endian
        // uint32s. Bytes 15 and 24 are both group boundaries (15 = 3*5, 24 = 3*8), so this
        // span pins the two dimension fields exactly and carries nothing from byte 24 (bit
        // depth) or byte 25 (colour type), which a re-encoder is entitled to change.
        IhdrOneByOneDimensionsBase64: Label 'UgAAAAEAAAAB', Locked = true;
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
    procedure Media_ExportStream_ValidPng_RoundTripsPreservingDimensions()
    // CLAIM: what ExportStream() returns is a PNG whose IHDR declares the SAME DIMENSIONS
    // (1x1) as the PNG that was imported. The image survives the round-trip; its byte
    // layout need not.
    //
    // WHY NOT BYTE LENGTH. This test previously asserted ExportStream() returns the same
    // byte COUNT that ImportStream() was given. That is not BC behaviour, and it must not
    // be re-added. BC does not store the incoming stream: NavMediaImport's
    // ImportMediaObjectCoreAsync calls NavMediaFactory.ProcessMediaObject(mediaStream,
    // saveStream: false, ...) and stores navMedia.Bytes(). With saveStream false the
    // NavMediaImage holds a decoded Image and no imageStream, so BytesAsync falls past its
    // stream-copy branch to image.Save(...) -- a re-encode. The output is whatever that
    // encoder emits: its own colour type, bit depth, filtering, zlib settings and ancillary
    // chunks. Measured, from the same 68-byte import:
    //
    //     68 bytes in  ->  99 bytes out   real BC on Windows (MS SaaS sandbox BC 28.4, and
    //                                     an official MS Windows container BC 28.4 onprem
    //                                     w1 -- two independent tiers, identical number)
    //     68 bytes in  ->  93 bytes out   BC-on-Linux once it re-encodes through SkiaSharp
    //     68 bytes in  ->  68 bytes out   BC-on-Linux today, where libgdiplus is stubbed so
    //                                     Image.FromStream cannot succeed and the import
    //                                     falls into the byte-preserving NavMediaBinaryFile
    //                                     path instead
    //
    // Three encoders, three lengths, none of them equal to the import. A byte-length claim
    // can only ever pin one encoder build. The old green on Linux measured the ABSENCE of an
    // image decoder, not BC.
    //
    // Dimensions are the part every conforming PNG encoder must preserve -- re-encoding a
    // 1x1 image yields a 1x1 image whatever it does to the pixel representation -- so that
    // is what this pins. It holds on all three paths above, including the byte-preserving
    // one, because a 1x1 PNG passed through verbatim still declares 1x1 in its IHDR.
    //
    // HOW THE BYTES ARE READ. Media exposes no Width/Height in AL, so the dimensions are
    // read out of the exported PNG itself. ReadText would be wrong for binary -- it is line-
    // and encoding-oriented and a PNG is full of NUL and 0x0A/0x0D -- so the blob goes
    // through Base64Convert.ToBase64, which is lossless over arbitrary bytes. This is the
    // pattern established by TestReportSaveAsPdfContent.al (cu 60774).
    //
    // WHICH BYTES EACH ASSERTION CONSTRAINS. Base64 packs 3 input bytes into 4 output
    // characters on a fixed grid, so a character span pins a byte span exactly when both
    // ends fall on a group boundary. Both spans below do, and Base64 is injective on a
    // 3-byte group, so character equality IS byte equality -- there is no bleed from any
    // byte outside the stated range:
    //
    //   chars 1-20  <-> bytes 0-14  : the 8-byte PNG signature, IHDR's length field (13),
    //                                 and the first three bytes of the type "IHD".
    //   chars 21-32 <-> bytes 15-23 : the "R" completing "IHDR", then WIDTH as a big-endian
    //                                 uint32 (bytes 16-19) and HEIGHT as a big-endian
    //                                 uint32 (bytes 20-23).
    //
    // Byte 24 (bit depth) and byte 25 (colour type) are deliberately OUTSIDE both spans.
    // Those are exactly the fields a re-encoder is free to change -- the fixture is
    // greyscale colour type 0, and GDI+ re-emits as RGB or RGBA -- so pinning them would
    // re-introduce the encoder dependence this test exists to remove.
    //
    // The second assertion is falsifiable in each dimension independently: width 2 gives
    // 'UgAAAAIAAAAB', height 2 gives 'UgAAAAEAAAAC', width 0 gives 'UgAAAAAAAAAB', and
    // 16x16 gives 'UgAAABAAAAAQ'. Only 1x1 gives the expected value.
    var
        Rec: Record "ALT Media";
        ExportBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        ExportOutStr: OutStream;
        ExportInStr: InStream;
        Encoded: Text;
        ExportedLength: Integer;
    begin
        Initialize();
        ImportBase64(Rec, 'PNG2', ValidPngBase64);

        Rec.Get('PNG2');
        ExportBlob.CreateOutStream(ExportOutStr);
        Rec.Picture.ExportStream(ExportOutStr);
        ExportedLength := ExportBlob.Length();

        // A zero-length export would make every prefix comparison below vacuous, so fail it
        // as itself first.
        Assert.IsTrue(ExportedLength > 0, 'ExportStream() must write bytes for a Media field that HasValue()');

        ExportBlob.CreateInStream(ExportInStr);
        Encoded := Base64Convert.ToBase64(ExportInStr);

        // Guard the CopyStr calls: a payload too short to carry an IHDR must fail saying so,
        // not as a confusing prefix mismatch.
        Assert.IsTrue(StrLen(Encoded) >= 32,
            StrSubstNo('ExportStream() wrote only %1 bytes -- too short to carry a PNG signature and IHDR header.', ExportedLength));

        // Bytes 0-14: it is a PNG, and the first chunk is an IHDR of the spec-mandated
        // length 13. Separates a PNG from an error payload, a zero-fill, or a non-image
        // blob.
        Assert.AreEqual(PngSignatureAndIhdrHeaderBase64, CopyStr(Encoded, 1, 20),
            StrSubstNo('ExportStream() wrote %1 bytes that do not begin with a PNG signature and IHDR chunk header.', ExportedLength));

        // Bytes 15-23: width = 1 and height = 1, big-endian, exactly as the imported PNG
        // declared them. This is the round-trip claim.
        Assert.AreEqual(IhdrOneByOneDimensionsBase64, CopyStr(Encoded, 21, 12),
            StrSubstNo('ExportStream() returned a PNG whose IHDR does not declare 1x1 -- the imported image''s dimensions did not survive the round-trip (%1 bytes exported).', ExportedLength));
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

    // Returns nothing on purpose. It used to return the imported byte length, which existed
    // only for the byte-length equality assertion issue #247 removed. BC re-encodes on
    // import, so the imported length says nothing about what ExportStream() gives back --
    // leaving the value here would invite exactly the comparison that was wrong.
    local procedure ImportBase64(var Rec: Record "ALT Media"; Code: Code[20]; Base64Content: Text)
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
        TempBlob.CreateInStream(InStr);

        Rec.Picture.ImportStream(InStr, 'test content');
        Rec.Modify();
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
