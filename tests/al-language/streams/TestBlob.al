// Fixtures used: ALT Blob (60008)

codeunit 60110 "Test Blob"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Blob Tests ───────────────────────────────────────────────────────────────

    [Test]
    procedure Blob_HasValue_Empty_ReturnsFalse()
    var
        BlobRec: Record "ALT Blob";
    begin
        Initialize();
        BlobRec.Code := 'B1';
        BlobRec.Insert();
        BlobRec.Get('B1');
        Assert.IsFalse(BlobRec.Data.HasValue(), 'HasValue() must return false for empty blob');
    end;

    [Test]
    procedure Blob_HasValue_AfterWrite_ReturnsTrue()
    var
        BlobRec: Record "ALT Blob";
        OutStr: OutStream;
    begin
        Initialize();
        BlobRec.Code := 'B2';
        BlobRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('content');
        BlobRec.Insert();
        BlobRec.Get('B2');
        BlobRec.CalcFields(Data);
        Assert.IsTrue(BlobRec.Data.HasValue(), 'HasValue() must return true after writing to blob');
    end;

    [Test]
    procedure Blob_Export_Import_PreservesContent()
    var
        BlobRec: Record "ALT Blob";
        OutStr: OutStream;
        InStr: InStream;
        ReadText: Text;
    begin
        Initialize();
        BlobRec.Code := 'B3';
        BlobRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('ExportContent');
        BlobRec.Insert();
        BlobRec.Get('B3');
        BlobRec.CalcFields(Data);
        BlobRec.Data.CreateInStream(InStr);
        InStr.ReadText(ReadText);
        // WriteText writes text with CR/LF, ReadText reads until CR/LF
        // After Insert/Get from DB, fresh InStream reads the stored data
        Assert.AreEqual('ExportContent', ReadText, 'Blob export/import must preserve exact content');
    end;

    [Test]
    procedure Blob_Length_AfterWrite_GreaterThanZero()
    var
        BlobRec: Record "ALT Blob";
        OutStr: OutStream;
    begin
        Initialize();
        BlobRec.Code := 'B4';
        BlobRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('LengthTest');
        BlobRec.Insert();
        BlobRec.Get('B4');
        BlobRec.CalcFields(Data);
        Assert.IsTrue(BlobRec.Data.Length() > 0, 'Blob Length() must be greater than zero after writing');
    end;

    [Test]
    procedure Blob_CreateOutStream_ThenInStream_Works()
    var
        BlobRec: Record "ALT Blob";
        OutStr: OutStream;
        InStr: InStream;
        ReadText: Text;
    begin
        Initialize();
        BlobRec.Code := 'B5';
        BlobRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('StreamTest');
        BlobRec.Insert();
        BlobRec.Modify();
        BlobRec.Data.CreateInStream(InStr);
        InStr.ReadText(ReadText);
        Assert.AreEqual('StreamTest', ReadText, 'Creating in/out streams sequentially must work correctly');
    end;

    // ── CalcFields requirement ────────────────────────────────────────────────────

    [Test]
    procedure Blob_Get_WithoutCalcFields_InStreamReadsEmpty()
    // CLAIM: After Rec.Get(), Blob fields are NOT loaded from the database (lazy loading).
    //        Reading from an InStream created on an unloaded Blob returns empty string.
    //        CalcFields(BlobField) must be called after Get() before reading Blob data.
    var
        BlobRec: Record "ALT Blob";
        OutStr: OutStream;
        InStr: InStream;
        Content: Text;
    begin
        Initialize();
        BlobRec.Code := 'LAZY';
        BlobRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('NotLoaded');
        BlobRec.Insert();

        // Re-fetch without CalcFields — Blob data is NOT loaded
        BlobRec.Get('LAZY');
        // Intentionally NO CalcFields call here
        BlobRec.Data.CreateInStream(InStr);
        InStr.ReadText(Content);

        // Blob data is lazily loaded; without CalcFields the stream is empty
        Assert.AreEqual('', Content, 'Reading Blob InStream without CalcFields returns empty — CalcFields required after Get');
    end;

    [Test]
    procedure Blob_CopyStream_WithoutCalcFields_DestinationIsEmpty()
    // CLAIM: CopyStream from a Blob field that has not been CalcFields'd copies nothing.
    //        The source InStream reads from an unloaded Blob = empty stream.
    //        Both ReadText and CopyStream require CalcFields to be called after Get().
    var
        Src: Record "ALT Blob";
        Dst: Record "ALT Blob";
        OutStr: OutStream;
        SrcIn: InStream;
        DstOut: OutStream;
        DstIn: InStream;
        Content: Text;
    begin
        Initialize();
        Src.Code := 'CS1';
        Src.Data.CreateOutStream(OutStr);
        OutStr.WriteText('OriginalContent');
        Src.Insert();

        // Re-fetch WITHOUT CalcFields — unloaded Blob
        Src.Get('CS1');
        // Intentionally NO CalcFields call here

        Dst.Code := 'CS2';
        Dst.Data.CreateOutStream(DstOut);
        Src.Data.CreateInStream(SrcIn);
        CopyStream(DstOut, SrcIn);  // Source stream is empty — CalcFields was skipped
        Dst.Insert();

        Dst.Get('CS2');
        Dst.CalcFields(Data);
        Dst.Data.CreateInStream(DstIn);
        DstIn.ReadText(Content);
        Assert.AreEqual('', Content, 'CopyStream from unloaded Blob (no CalcFields) copies nothing — CalcFields required before CopyStream');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
