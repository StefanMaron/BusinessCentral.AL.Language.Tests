// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/
//   dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Blob (60008)
// BC versions: 27.5+
//
// CLAIM (one per codeunit): an in-memory Blob write that has NOT been persisted
// with Modify() stays local to the record variable that made it. The stored row
// is unchanged, so a *different* Record instance that Get()s the same row reads
// the Blob empty, and re-Get()ting on the *same* instance discards the write.
//
// This is the isolation direction. The complementary retention direction — the
// writing instance itself keeps the bytes across CalcFields — is covered by
// TestBlobCalcFieldsUncommittedWrite.al (60915); lazy loading after Get() is
// covered by TestBlob.al. Here the question is who else can see the write.
//
// The temporary-record counterpart is asserted separately and deliberately: a
// temporary table is an in-memory store, and whether it copies the Blob at
// Insert or hands out the record's own Blob object is not something the
// non-temporary case answers. Both shapes are pinned here so the Insert/Modify
// contract can be compared side by side against a real service tier.

codeunit 60940 "Test Blob Uncomm Isolation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Non-temporary ─────────────────────────────────────────────────────────

    [Test]
    procedure Blob_UncommittedWrite_SecondInstanceGet_ReadsEmpty()
    // CLAIM: Insert() with an empty Blob, then write bytes through CreateOutStream
    //        WITHOUT Modify(). A second Record instance that Get()s the row must
    //        not see those bytes — the stored row was never modified.
    var
        Writer: Record "ALT Blob";
        Reader: Record "ALT Blob";
        OutStr: OutStream;
        InStr: InStream;
        ReadBack: Text;
    begin
        Initialize();

        Writer.Init();
        Writer.Code := 'LEAK';
        Writer.Insert(true);

        Writer.Data.CreateOutStream(OutStr);
        OutStr.WriteText('LEAKED-BYTES');
        // deliberately NO Modify()

        Reader.Get('LEAK');
        Reader.CalcFields(Data);

        Assert.IsFalse(Reader.Data.HasValue(), 'A second Record instance must not see a Blob write that was never persisted with Modify');

        Reader.Data.CreateInStream(InStr);
        InStr.ReadText(ReadBack);
        Assert.AreEqual('', ReadBack, 'A second Record instance must read the stored (empty) Blob, not the uncommitted in-memory bytes');
        Assert.AreEqual(0, StrLen(ReadBack), 'The stored Blob must be zero-length — the 12 uncommitted bytes must not reach it');
    end;

    [Test]
    procedure Blob_UncommittedWrite_SameInstanceReGet_DiscardsWrite()
    // CLAIM: same shape, but the re-read happens on the writing instance itself.
    //        Get() refreshes the buffer from the stored row, so the uncommitted
    //        bytes are discarded rather than surviving the round trip.
    var
        Writer: Record "ALT Blob";
        OutStr: OutStream;
        InStr: InStream;
        ReadBack: Text;
    begin
        Initialize();

        Writer.Init();
        Writer.Code := 'REGET';
        Writer.Insert(true);

        Writer.Data.CreateOutStream(OutStr);
        OutStr.WriteText('REGET-BYTES');
        // deliberately NO Modify()

        Writer.Get('REGET');
        Writer.CalcFields(Data);

        Assert.IsFalse(Writer.Data.HasValue(), 'Get() must refresh the Blob from the stored row, discarding an uncommitted write');

        Writer.Data.CreateInStream(InStr);
        InStr.ReadText(ReadBack);
        Assert.AreEqual('', ReadBack, 'Re-Get on the writing instance must read the stored (empty) Blob');
        Assert.AreEqual(0, StrLen(ReadBack), 'The re-fetched Blob must be zero-length');
    end;

    [Test]
    procedure Blob_CommittedWrite_SecondInstanceGet_ReadsWrittenBytes()
    // CLAIM (positive control): the very same sequence WITH Modify() does reach
    //        the stored row — a second instance reads the exact bytes back. This
    //        is what makes the two tests above a statement about Modify() and not
    //        a statement that Blobs never round-trip.
    var
        Writer: Record "ALT Blob";
        Reader: Record "ALT Blob";
        OutStr: OutStream;
        InStr: InStream;
        ReadBack: Text;
    begin
        Initialize();

        Writer.Init();
        Writer.Code := 'COMMIT';
        Writer.Insert(true);

        Writer.Data.CreateOutStream(OutStr);
        OutStr.WriteText('COMMITTED-BYTES');
        Writer.Modify(true);

        Reader.Get('COMMIT');
        Reader.CalcFields(Data);

        Assert.IsTrue(Reader.Data.HasValue(), 'A second Record instance must see a Blob write that was persisted with Modify');

        Reader.Data.CreateInStream(InStr);
        InStr.ReadText(ReadBack);
        Assert.AreEqual('COMMITTED-BYTES', ReadBack, 'A second Record instance must read exactly the persisted Blob bytes');
        Assert.AreEqual(15, StrLen(ReadBack), 'The persisted Blob must carry all 15 written characters');
    end;

    [Test]
    procedure Blob_UncommittedScalarWrite_SecondInstanceGet_ReadsEmpty()
    // CLAIM (discriminating control): the isolation asserted above is the ordinary
    //        Insert/Modify contract, not something specific to Blob fields. A plain
    //        Text field assigned without Modify() is invisible to a second instance
    //        in exactly the same way.
    var
        Writer: Record "ALT Blob";
        Reader: Record "ALT Blob";
    begin
        Initialize();

        Writer.Init();
        Writer.Code := 'SCALAR';
        Writer.Insert(true);

        Writer.Description := 'SCALAR-LEAK';
        // deliberately NO Modify()

        Reader.Get('SCALAR');
        Assert.AreEqual('', Reader.Description, 'A scalar field assigned without Modify must not be visible to a second Record instance');
    end;

    // ── Temporary ─────────────────────────────────────────────────────────────

    [Test]
    procedure TempBlob_UncommittedWrite_SameInstanceReGet_DiscardsWrite()
    // CLAIM: the Insert/Modify contract holds for a temporary record too. The temp
    //        store keeps the row as inserted; a Blob written afterwards without
    //        Modify() is not in the store, so Get() reads it back empty.
    var
        TempBlobRec: Record "ALT Blob" temporary;
        OutStr: OutStream;
        InStr: InStream;
        ReadBack: Text;
    begin
        Initialize();

        TempBlobRec.Init();
        TempBlobRec.Code := 'TREGET';
        TempBlobRec.Insert(true);

        TempBlobRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('TEMP-BYTES');
        // deliberately NO Modify()

        TempBlobRec.Get('TREGET');
        TempBlobRec.CalcFields(Data);

        Assert.IsFalse(TempBlobRec.Data.HasValue(), 'A temporary row must not pick up a Blob write that was never persisted with Modify');

        TempBlobRec.Data.CreateInStream(InStr);
        InStr.ReadText(ReadBack);
        Assert.AreEqual('', ReadBack, 'Get() on a temporary record must read the stored (empty) Blob, not the uncommitted in-memory bytes');
        Assert.AreEqual(0, StrLen(ReadBack), 'The stored temporary Blob must be zero-length');
    end;

    [Test]
    procedure TempBlob_UncommittedWrite_SharedBufferInstance_ReadsEmpty()
    // CLAIM: the same isolation across two record variables that share one temp
    //        buffer (Copy(..., true)). The sharing is of the stored rows, not of
    //        the writing variable's in-memory Blob object.
    var
        TempWriter: Record "ALT Blob" temporary;
        TempReader: Record "ALT Blob" temporary;
        OutStr: OutStream;
        InStr: InStream;
        ReadBack: Text;
    begin
        Initialize();

        TempWriter.Init();
        TempWriter.Code := 'TSHARE';
        TempWriter.Insert(true);

        TempWriter.Data.CreateOutStream(OutStr);
        OutStr.WriteText('TEMP-SHARED');
        // deliberately NO Modify()

        TempReader.Copy(TempWriter, true);
        TempReader.Get('TSHARE');
        TempReader.CalcFields(Data);

        Assert.IsFalse(TempReader.Data.HasValue(), 'A second variable over a shared temp buffer must not see an unpersisted Blob write');

        TempReader.Data.CreateInStream(InStr);
        InStr.ReadText(ReadBack);
        Assert.AreEqual('', ReadBack, 'A shared-buffer temp reader must read the stored (empty) Blob');
        Assert.AreEqual(0, StrLen(ReadBack), 'The stored temporary Blob must be zero-length for the shared-buffer reader too');
    end;

    [Test]
    procedure TempBlob_CommittedWrite_SameInstanceReGet_ReadsWrittenBytes()
    // CLAIM (positive control for the temporary shape): with Modify() the bytes do
    //        reach the temp store and survive a Get().
    var
        TempBlobRec: Record "ALT Blob" temporary;
        OutStr: OutStream;
        InStr: InStream;
        ReadBack: Text;
    begin
        Initialize();

        TempBlobRec.Init();
        TempBlobRec.Code := 'TCOMMIT';
        TempBlobRec.Insert(true);

        TempBlobRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('TEMP-COMMITTED');
        TempBlobRec.Modify(true);

        TempBlobRec.Get('TCOMMIT');
        TempBlobRec.CalcFields(Data);

        Assert.IsTrue(TempBlobRec.Data.HasValue(), 'A temporary row must keep a Blob write that was persisted with Modify');

        TempBlobRec.Data.CreateInStream(InStr);
        InStr.ReadText(ReadBack);
        Assert.AreEqual('TEMP-COMMITTED', ReadBack, 'Get() on a temporary record must read exactly the persisted Blob bytes');
        Assert.AreEqual(14, StrLen(ReadBack), 'The persisted temporary Blob must carry all 14 written characters');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
