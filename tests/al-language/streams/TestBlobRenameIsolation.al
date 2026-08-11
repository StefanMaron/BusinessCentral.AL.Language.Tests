// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/
//   dev-itpro/developer/methods-auto/record/record-rename-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Blob (60008)
// BC versions: 27.5+
//
// CLAIM (one per codeunit): does Rename() carry the same Blob store-aliasing
// boundary as Insert()/Modify() — i.e. does the shape of isolation for an
// uncommitted Blob write (written via CreateOutStream, never persisted with
// Modify()) survive a Rename() the same way it survives a plain Get()?
//
// Follow-up to TestBlobUncommittedWriteIsolation.al (60940), which pinned the
// Insert/Modify boundary: database-backed rows isolate an uncommitted write,
// temporary rows do not (the temp store holds the record's own Blob object).
// Rename() is a third store-entry point that neither that codeunit nor any
// other exercises for Blobs — this one measures it rather than assuming it
// matches Insert/Modify. Per the trap documented in 60940: a symmetric guess
// is not a substitute for CI on real BC, since the first attempt at 60940
// guessed isolation for both shapes and BC rejected exactly the temporary
// half. Any assertion below that CI rejects must be corrected to what BC
// actually does, not weakened to a no-op.
//
// Each case pairs a committed write (Modify() before Rename(), positive
// control — proves the Blob does round-trip through Rename at all) with an
// uncommitted write (no Modify() before Rename(), the isolation question).

codeunit 60943 "Test Blob Rename Isolation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Non-temporary ─────────────────────────────────────────────────────────

    [Test]
    procedure Blob_UncommittedWrite_Rename_SecondInstanceGet_ReadsEmpty()
    // CLAIM: Insert() with an empty Blob, write bytes through CreateOutStream
    //        WITHOUT Modify(), then Rename() the row. A second Record instance
    //        that Get()s the row under the NEW key must not see those bytes —
    //        Rename() does not persist an uncommitted field change.
    var
        Writer: Record "ALT Blob";
        Reader: Record "ALT Blob";
        OutStr: OutStream;
        InStr: InStream;
        ReadBack: Text;
    begin
        Initialize();

        Writer.Init();
        Writer.Code := 'RNLEAK1';
        Writer.Insert(true);

        Writer.Data.CreateOutStream(OutStr);
        OutStr.WriteText('RENAME-LEAKED-BYTES');
        // deliberately NO Modify()

        Writer.Rename('RNLEAK2');

        Reader.Get('RNLEAK2');
        Reader.CalcFields(Data);

        Assert.IsFalse(Reader.Data.HasValue(), 'A second Record instance must not see a Blob write that was never persisted with Modify, even after Rename');

        Reader.Data.CreateInStream(InStr);
        InStr.ReadText(ReadBack);
        Assert.AreEqual('', ReadBack, 'A second Record instance must read the stored (empty) Blob after Rename, not the uncommitted in-memory bytes');
        Assert.AreEqual(0, StrLen(ReadBack), 'The renamed row''s stored Blob must be zero-length — the uncommitted bytes must not reach it');
    end;

    [Test]
    procedure Blob_UncommittedWrite_Rename_SameInstanceReGet_DiscardsWrite()
    // CLAIM: same shape, but the re-read happens on the writing instance
    //        itself, keyed by the NEW value. Get() refreshes the buffer from
    //        the stored row, so the uncommitted bytes are discarded rather
    //        than surviving the Rename + round trip.
    var
        Writer: Record "ALT Blob";
        OutStr: OutStream;
        InStr: InStream;
        ReadBack: Text;
    begin
        Initialize();

        Writer.Init();
        Writer.Code := 'RNREGET1';
        Writer.Insert(true);

        Writer.Data.CreateOutStream(OutStr);
        OutStr.WriteText('RENAME-REGET-BYTES');
        // deliberately NO Modify()

        Writer.Rename('RNREGET2');

        Writer.Get('RNREGET2');
        Writer.CalcFields(Data);

        Assert.IsFalse(Writer.Data.HasValue(), 'Get() after Rename must refresh the Blob from the stored row, discarding an uncommitted write');

        Writer.Data.CreateInStream(InStr);
        InStr.ReadText(ReadBack);
        Assert.AreEqual('', ReadBack, 'Re-Get on the writing instance after Rename must read the stored (empty) Blob');
        Assert.AreEqual(0, StrLen(ReadBack), 'The re-fetched Blob after Rename must be zero-length');
    end;

    [Test]
    procedure Blob_CommittedWrite_Rename_SecondInstanceGet_ReadsWrittenBytes()
    // CLAIM (positive control): the very same sequence WITH Modify() before
    //        Rename() does reach the stored row and survives the Rename — a
    //        second instance reads the exact bytes back under the new key.
    //        This is what makes the two tests above a statement about
    //        Modify()/Rename() interaction and not a statement that Blobs
    //        never survive a Rename at all.
    var
        Writer: Record "ALT Blob";
        Reader: Record "ALT Blob";
        OutStr: OutStream;
        InStr: InStream;
        ReadBack: Text;
    begin
        Initialize();

        Writer.Init();
        Writer.Code := 'RNCOMMIT1';
        Writer.Insert(true);

        Writer.Data.CreateOutStream(OutStr);
        OutStr.WriteText('RENAME-COMMITTED-BYTES');
        Writer.Modify(true);

        Writer.Rename('RNCOMMIT2');

        Reader.Get('RNCOMMIT2');
        Reader.CalcFields(Data);

        Assert.IsTrue(Reader.Data.HasValue(), 'A second Record instance must see a Blob write that was persisted with Modify before Rename');

        Reader.Data.CreateInStream(InStr);
        InStr.ReadText(ReadBack);
        Assert.AreEqual('RENAME-COMMITTED-BYTES', ReadBack, 'A second Record instance must read exactly the persisted Blob bytes after Rename');
        Assert.AreEqual(23, StrLen(ReadBack), 'The persisted Blob must carry all 23 written characters after Rename');
    end;

    [Test]
    procedure Blob_UncommittedScalarWrite_Rename_SecondInstanceGet_ReadsEmpty()
    // CLAIM (discriminating control): the isolation asserted above is the
    //        ordinary Modify/Rename contract, not something specific to Blob
    //        fields. A plain Text field assigned without Modify() is
    //        invisible to a second instance after Rename in exactly the same
    //        way.
    var
        Writer: Record "ALT Blob";
        Reader: Record "ALT Blob";
    begin
        Initialize();

        Writer.Init();
        Writer.Code := 'RNSCALAR1';
        Writer.Insert(true);

        Writer.Description := 'RENAME-SCALAR-LEAK';
        // deliberately NO Modify()

        Writer.Rename('RNSCALAR2');

        Reader.Get('RNSCALAR2');
        Assert.AreEqual('', Reader.Description, 'A scalar field assigned without Modify must not be visible to a second Record instance after Rename');
    end;

    // ── Temporary ─────────────────────────────────────────────────────────────

    [Test]
    procedure TempBlob_UncommittedWrite_Rename_SameInstanceReGet_KeepsWrite()
    // CLAIM: the database contract does NOT carry over to a temporary record
    //        — matching the Insert/Modify boundary pinned by 60940. The temp
    //        store holds the record's own Blob object, so bytes written after
    //        Insert without Modify() are in the stored row already; Rename()
    //        only relocates that row under a new key and the already-shared
    //        Blob object comes with it. Get() reads the unpersisted bytes
    //        back instead of discarding them.
    var
        TempBlobRec: Record "ALT Blob" temporary;
        OutStr: OutStream;
        InStr: InStream;
        ReadBack: Text;
    begin
        Initialize();

        TempBlobRec.Init();
        TempBlobRec.Code := 'TRNREGET1';
        TempBlobRec.Insert(true);

        TempBlobRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('TEMP-RENAME-BYTES');
        // deliberately NO Modify()

        TempBlobRec.Rename('TRNREGET2');

        TempBlobRec.Get('TRNREGET2');
        TempBlobRec.CalcFields(Data);

        Assert.IsTrue(TempBlobRec.Data.HasValue(), 'A temporary row does pick up a Blob write made after Insert without Modify, and it survives Rename');

        TempBlobRec.Data.CreateInStream(InStr);
        InStr.ReadText(ReadBack);
        Assert.AreEqual('TEMP-RENAME-BYTES', ReadBack, 'Get() on a temporary record after Rename reads back the unpersisted in-memory bytes');
        Assert.AreEqual(18, StrLen(ReadBack), 'All 18 unpersisted characters are present in the temporary store after Rename');
    end;

    [Test]
    procedure TempBlob_UncommittedWrite_Rename_SharedBufferInstance_SeesWrite()
    // CLAIM: the same non-isolation is observable from a second record
    //        variable sharing the temp buffer (Copy(..., true)) after Rename
    //        — so it is the stored row that carries the bytes, not just the
    //        writing variable's own buffer.
    var
        TempWriter: Record "ALT Blob" temporary;
        TempReader: Record "ALT Blob" temporary;
        OutStr: OutStream;
        InStr: InStream;
        ReadBack: Text;
    begin
        Initialize();

        TempWriter.Init();
        TempWriter.Code := 'TRNSHARE1';
        TempWriter.Insert(true);

        TempWriter.Data.CreateOutStream(OutStr);
        OutStr.WriteText('TEMP-RENAME-SHARED');
        // deliberately NO Modify()

        TempWriter.Rename('TRNSHARE2');

        TempReader.Copy(TempWriter, true);
        TempReader.Get('TRNSHARE2');
        TempReader.CalcFields(Data);

        Assert.IsTrue(TempReader.Data.HasValue(), 'A second variable over a shared temp buffer does see the unpersisted Blob write after Rename');

        TempReader.Data.CreateInStream(InStr);
        InStr.ReadText(ReadBack);
        Assert.AreEqual('TEMP-RENAME-SHARED', ReadBack, 'A shared-buffer temp reader reads the unpersisted bytes out of the renamed stored row');
        Assert.AreEqual(19, StrLen(ReadBack), 'All 19 unpersisted characters are present for the shared-buffer reader after Rename');
    end;

    [Test]
    procedure TempBlob_CommittedWrite_Rename_SameInstanceReGet_ReadsWrittenBytes()
    // CLAIM (positive control for the temporary shape): with Modify() the
    //        bytes do reach the temp store and survive both a Rename() and a
    //        subsequent Get().
    var
        TempBlobRec: Record "ALT Blob" temporary;
        OutStr: OutStream;
        InStr: InStream;
        ReadBack: Text;
    begin
        Initialize();

        TempBlobRec.Init();
        TempBlobRec.Code := 'TRNCOMMIT1';
        TempBlobRec.Insert(true);

        TempBlobRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('TEMP-RENAME-COMMITTED');
        TempBlobRec.Modify(true);

        TempBlobRec.Rename('TRNCOMMIT2');

        TempBlobRec.Get('TRNCOMMIT2');
        TempBlobRec.CalcFields(Data);

        Assert.IsTrue(TempBlobRec.Data.HasValue(), 'A temporary row must keep a Blob write that was persisted with Modify, across a Rename');

        TempBlobRec.Data.CreateInStream(InStr);
        InStr.ReadText(ReadBack);
        Assert.AreEqual('TEMP-RENAME-COMMITTED', ReadBack, 'Get() on a temporary record after Rename must read exactly the persisted Blob bytes');
        Assert.AreEqual(22, StrLen(ReadBack), 'The persisted temporary Blob must carry all 22 written characters after Rename');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
