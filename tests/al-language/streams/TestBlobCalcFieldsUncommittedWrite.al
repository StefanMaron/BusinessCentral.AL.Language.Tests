// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/
//   dev-itpro/developer/methods-auto/record/record-calcfields-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Blob (60008)
// BC versions: 27.5+
//
// CLAIM (one per codeunit): CalcFields(BlobField) does NOT discard an in-memory
// Blob write that has not yet been persisted with Modify(). Writing through
// CreateOutStream leaves the bytes on the record buffer, and a subsequent
// CalcFields on that same Blob field must leave them there — it must not
// re-fetch the (still empty) stored value over the top of them.
//
// The complementary lazy-load direction — after Get(), an untouched Blob reads
// empty until CalcFields loads it — is already covered by TestBlob.al
// (Blob_Get_WithoutCalcFields_InStreamReadsEmpty). This file covers the case
// where the buffer is dirty when CalcFields runs.

codeunit 60915 "Test Blob CalcFields Uncomm"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Blob_CalcFields_AfterUncommittedWriteWithoutModify_KeepsWrite()
    // CLAIM: Insert() with an empty Blob, then write bytes through CreateOutStream
    //        WITHOUT Modify(), then CalcFields — the written bytes survive.
    var
        BlobRec: Record "ALT Blob";
        OutStr: OutStream;
        InStr: InStream;
        ReadBack: Text;
    begin
        Initialize();

        BlobRec.Init();
        BlobRec.Code := 'UNCOMMITTED';
        BlobRec.Insert(true);

        Clear(BlobRec.Data);
        BlobRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('HELLO-BYTES');

        BlobRec.CalcFields(Data);

        BlobRec.Data.CreateInStream(InStr);
        InStr.ReadText(ReadBack);

        Assert.AreEqual('HELLO-BYTES', ReadBack, 'CalcFields must not discard an uncommitted in-memory Blob write');
    end;

    [Test]
    procedure Blob_CalcFields_AfterModify_KeepsWrite()
    // CLAIM: control for the case above — the same sequence WITH Modify() before
    //        CalcFields also reads the written bytes back.
    var
        BlobRec: Record "ALT Blob";
        OutStr: OutStream;
        InStr: InStream;
        ReadBack: Text;
    begin
        Initialize();

        BlobRec.Init();
        BlobRec.Code := 'COMMITTED';
        BlobRec.Insert(true);

        Clear(BlobRec.Data);
        BlobRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('HELLO-BYTES');
        BlobRec.Modify(true);

        BlobRec.CalcFields(Data);

        BlobRec.Data.CreateInStream(InStr);
        InStr.ReadText(ReadBack);

        Assert.AreEqual('HELLO-BYTES', ReadBack, 'CalcFields after Modify must read back the persisted Blob write');
    end;

    [Test]
    procedure Blob_CalcFields_TwoUncommittedRecords_KeepsBothWrites()
    // CLAIM: the behavior is per-record and not order-dependent — two records each
    //        written and CalcFields'd without Modify keep their own distinct bytes.
    var
        FirstRec: Record "ALT Blob";
        SecondRec: Record "ALT Blob";
        OutStr: OutStream;
        InStr: InStream;
        FirstReadBack: Text;
        SecondReadBack: Text;
    begin
        Initialize();

        FirstRec.Init();
        FirstRec.Code := 'FIRST';
        FirstRec.Insert(true);
        Clear(FirstRec.Data);
        FirstRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('FIRST-RECORD');
        FirstRec.CalcFields(Data);

        SecondRec.Init();
        SecondRec.Code := 'SECOND';
        SecondRec.Insert(true);
        Clear(SecondRec.Data);
        SecondRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('SECOND-RECORD');
        SecondRec.CalcFields(Data);

        FirstRec.Data.CreateInStream(InStr);
        InStr.ReadText(FirstReadBack);
        SecondRec.Data.CreateInStream(InStr);
        InStr.ReadText(SecondReadBack);

        Assert.AreEqual('FIRST-RECORD', FirstReadBack, 'First record must keep its own uncommitted Blob write');
        Assert.AreEqual('SECOND-RECORD', SecondReadBack, 'Second record must keep its own uncommitted Blob write');
    end;

    [Test]
    procedure Blob_CalcFields_NoWriteAtAll_ReadsEmpty()
    // CLAIM (negative direction): CalcFields does not invent content. A row inserted
    //        with an untouched Blob still reads empty after Get() + CalcFields.
    var
        BlobRec: Record "ALT Blob";
        ReaderRec: Record "ALT Blob";
        InStr: InStream;
        ReadBack: Text;
    begin
        Initialize();

        BlobRec.Init();
        BlobRec.Code := 'EMPTY';
        BlobRec.Insert(true);

        ReaderRec.Get('EMPTY');
        ReaderRec.CalcFields(Data);

        Assert.IsFalse(ReaderRec.Data.HasValue(), 'A Blob never written to must have no value after CalcFields');

        ReaderRec.Data.CreateInStream(InStr);
        InStr.ReadText(ReadBack);
        Assert.AreEqual('', ReadBack, 'CalcFields on a never-written Blob must read back empty');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
