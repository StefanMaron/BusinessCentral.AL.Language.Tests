// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/
//   dev-itpro/developer/methods-auto/record/record-rename-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Blob (60008)
// BC versions: 27.5+
//
// CLAIM (one per codeunit): does Rename() carry the same Blob store-aliasing
// boundary as Insert()/Modify() — i.e. does the isolation of an uncommitted
// Blob write (written via CreateOutStream, never persisted with Modify())
// survive a Rename() the same way it survives a plain Get()?
//
// Measured, not assumed, against real BC 27.5 and 28.3 — and the answer is
// NO. Rename() does not have the Insert/Modify isolation boundary at all:
//
//   * Database-backed record: TestBlobUncommittedWriteIsolation.al (60940)
//     pins that an uncommitted Blob write (or plain scalar-field write) is
//     invisible to a second instance after a bare Get(). Adding a Rename()
//     call in between flips that outcome — the uncommitted write (Blob AND
//     plain scalar) IS visible under the new key. Rename() re-persists the
//     record variable's whole current buffer under the new key, not just the
//     primary-key field(s) that changed.
//
//   * Temporary record: 60940 pins that an uncommitted Blob write already IS
//     visible after a bare Get(), because the temp store holds the record's
//     own Blob object by reference. That stays true across a Rename() too —
//     unsurprising, since the object was already shared before Rename() ran.
//     But the committed shape (Modify() BEFORE Rename()) is the opposite of
//     what Insert/Modify predicts: real BC returns HasValue() = false for the
//     renamed row — the Blob that Modify() persisted is LOST across Rename()
//     for a temporary record. This was the biggest surprise of this
//     measurement and is pinned exactly as observed; both database and
//     temporary shapes disagree with the Insert/Modify boundary, and they
//     disagree with EACH OTHER on the committed-write case.
//
// First-attempt assertions here guessed the Insert/Modify boundary carried
// over unchanged and CI on real BC rejected every guess with identical
// failures on both 27.5 and 28.3 — see the trap 60940 documents about a
// symmetric guess not substituting for CI. The assertions below are what CI
// actually returned, not the original guess.

codeunit 60944 "Test Blob Rename Isolation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Non-temporary ─────────────────────────────────────────────────────────

    [Test]
    procedure Blob_UncommittedWrite_Rename_SecondInstanceGet_ReadsWrittenBytes()
    // CLAIM (measured): Insert() with an empty Blob, write bytes through
    //        CreateOutStream WITHOUT Modify(), then Rename() the row. Unlike
    //        a bare Get() (60940), Rename() DOES carry the uncommitted write
    //        to the renamed row — a second Record instance that Get()s the
    //        row under the new key reads the bytes back.
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

        Assert.IsTrue(Reader.Data.HasValue(), 'A Rename() call persists the current buffer, so a second Record instance DOES see a Blob write that was never persisted with Modify');

        Reader.Data.CreateInStream(InStr);
        InStr.ReadText(ReadBack);
        Assert.AreEqual('RENAME-LEAKED-BYTES', ReadBack, 'A second Record instance reads the exact uncommitted bytes back under the renamed key');
        Assert.AreEqual(19, StrLen(ReadBack), 'All 19 uncommitted characters reach the renamed row');
    end;

    [Test]
    procedure Blob_UncommittedWrite_Rename_SameInstanceReGet_KeepsWrite()
    // CLAIM (measured): same shape, re-read on the writing instance itself
    //        under the new key. Get() after Rename() reads back the bytes
    //        that Rename() carried over — it does not discard them the way a
    //        Get() without an intervening Rename() would (60940).
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

        Assert.IsTrue(Writer.Data.HasValue(), 'Get() after Rename() reads back the bytes that Rename() itself persisted from the buffer');

        Writer.Data.CreateInStream(InStr);
        InStr.ReadText(ReadBack);
        Assert.AreEqual('RENAME-REGET-BYTES', ReadBack, 'Re-Get on the writing instance after Rename reads the bytes Rename() carried over');
        Assert.AreEqual(18, StrLen(ReadBack), 'All 18 characters survive the Rename + re-Get round trip');
    end;

    [Test]
    procedure Blob_CommittedWrite_Rename_SecondInstanceGet_ReadsWrittenBytes()
    // CLAIM (positive control): the same sequence WITH Modify() before
    //        Rename() reaches the stored row and survives the Rename — a
    //        second instance reads the exact bytes back under the new key.
    //        Combined with the two tests above, Rename() persists whatever
    //        the buffer holds at the time it runs, committed or not.
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
        Assert.AreEqual(22, StrLen(ReadBack), 'The persisted Blob must carry all 22 written characters after Rename');
    end;

    [Test]
    procedure Blob_UncommittedScalarWrite_Rename_SecondInstanceGet_SeesUnpersistedValue()
    // CLAIM (measured, discriminating control): the Rename() behaviour above
    //        is not specific to Blob fields — a plain Text field assigned
    //        without Modify() is ALSO visible to a second instance after
    //        Rename(), the mirror image of the discriminating control in
    //        60940 (which showed the opposite for a bare Get() with no
    //        Rename). This confirms Rename() re-persists the whole buffer,
    //        not just the changed key field(s).
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
        Assert.AreEqual('RENAME-SCALAR-LEAK', Reader.Description, 'Rename() persists the current buffer''s non-key fields too, so a second instance sees the unmodified scalar value');
    end;

    // ── Temporary ─────────────────────────────────────────────────────────────

    [Test]
    procedure TempBlob_UncommittedWrite_Rename_SameInstanceReGet_KeepsWrite()
    // CLAIM: consistent with the Insert/Modify boundary pinned by 60940 for
    //        temporary records — the temp store holds the record's own Blob
    //        object, so bytes written after Insert without Modify() are in
    //        the stored row already. Rename() relocates that row under a new
    //        key and the already-shared Blob object comes with it; Get()
    //        reads the unpersisted bytes back.
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
        Assert.AreEqual(17, StrLen(ReadBack), 'All 17 unpersisted characters are present in the temporary store after Rename');
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
        Assert.AreEqual(18, StrLen(ReadBack), 'All 18 unpersisted characters are present for the shared-buffer reader after Rename');
    end;

    [Test]
    procedure TempBlob_CommittedWrite_Rename_SameInstanceReGet_LosesBlobValue()
    // CLAIM (measured — the one genuine surprise of this file): for a
    //        temporary record, a Blob persisted with Modify() BEFORE Rename()
    //        does NOT survive the Rename(). HasValue() on the renamed row is
    //        false, even though the exact same Insert -> write -> Modify
    //        sequence WITHOUT a Rename() call correctly round-trips the Blob
    //        (see TempBlob_CommittedWrite_SameInstanceReGet_ReadsWrittenBytes
    //        in 60940). This is the opposite of the database-backed shape,
    //        where Modify() before Rename() is the case that DOES survive
    //        (Blob_CommittedWrite_Rename_SecondInstanceGet_ReadsWrittenBytes
    //        above) — the two shapes disagree with each other here, not just
    //        with the Insert/Modify boundary.
    var
        TempBlobRec: Record "ALT Blob" temporary;
        OutStr: OutStream;
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

        Assert.IsFalse(TempBlobRec.Data.HasValue(), 'A temporary row loses a Blob that was persisted with Modify once Rename() runs — measured against real BC, not assumed');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
