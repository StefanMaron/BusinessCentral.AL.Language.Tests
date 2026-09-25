// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-import-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-instance-import-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Blob (60008), ALTFixtureCleanup (60019),
//                ALT Universal XmlPort (60023)
// Note: the XmlPort.Import counterpart of "Test Codeunit Run Write Tx" (60254). Whether the
// Boolean result is consumed decides which branch the platform takes: the statement form
// joins the caller's transaction and is allowed while an uncommitted write is pending; the
// value-consuming form opens a transaction world of its own, which the platform will not do
// while the caller holds an uncommitted write.
//
// The two spellings of the value-consuming form are asked separately because they need not
// agree: the STATIC XmlPort.Import(Id, InStream) traps errors raised inside it and turns them
// into a false result, while the INSTANCE XmlPortVar.Import() has no such wrapper. So the
// static form is expected to answer false without raising, and the instance form to raise.
// In both refused arms the xmlport never runs, so its rows do not exist.
//
// Asked by StefanMaron/BusinessCentral.AL.Runner#2184.
// BC versions: 24+

codeunit 60041 "Test XmlPort Import Write Tx"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        // Cleanup deletes rows, which itself opens a write transaction. Close it so each
        // test below starts from a known state and controls its own pending write.
        Commit();
    end;

    local procedure InsertPendingRow()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 1;
        ALTUniversal.Insert();
    end;

    local procedure ImportedRowCount(): Integer
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Reset();
        ALTUniversal.SetRange("Entry No.", 9301, 9302);
        exit(ALTUniversal.Count());
    end;

    local procedure OpenPayload(var BlobRec: Record "ALT Blob" temporary; var InStr: InStream)
    var
        OutStr: OutStream;
    begin
        BlobRec.Reset();
        BlobRec.DeleteAll();
        BlobRec.Init();
        BlobRec.Code := 'TMP';
        BlobRec.Insert();
        BlobRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('<?xml version="1.0" encoding="UTF-8"?><Universals>' +
            '<Universal><EntryNo>9301</EntryNo><IntegerValue>10</IntegerValue><TextValue>First</TextValue></Universal>' +
            '<Universal><EntryNo>9302</EntryNo><IntegerValue>20</IntegerValue><TextValue>Second</TextValue></Universal>' +
            '</Universals>');
        BlobRec.Data.CreateInStream(InStr);
    end;

    [Test]
    procedure StaticGuardedImport_WithUncommittedWrite_ReturnsFalse_AndImportsNothing()
    var
        BlobRec: Record "ALT Blob" temporary;
        InStr: InStream;
        Ok: Boolean;
    begin
        Initialize();
        OpenPayload(BlobRec, InStr);

        // [GIVEN] an uncommitted write, so the session holds an open write transaction
        InsertPendingRow();

        // [WHEN] the static XmlPort.Import is called with its Boolean result consumed
        Ok := XmlPort.Import(XmlPort::"ALT Universal XmlPort", InStr);

        // [THEN] it reports failure rather than raising, and the xmlport never ran
        Assert.IsFalse(Ok, 'A value-consuming static XmlPort.Import inside a write transaction must return false.');
        Assert.AreEqual(0, ImportedRowCount(),
            'The refused static XmlPort.Import must not have imported any row.');
    end;

    [Test]
    procedure InstanceGuardedImport_WithUncommittedWrite_IsRefused_AndImportsNothing()
    var
        BlobRec: Record "ALT Blob" temporary;
        UniversalXmlPort: XmlPort "ALT Universal XmlPort";
        InStr: InStream;
        Ok: Boolean;
    begin
        Initialize();
        OpenPayload(BlobRec, InStr);

        // [GIVEN] an uncommitted write, so the session holds an open write transaction
        InsertPendingRow();

        // [WHEN] the instance Import is called with its Boolean result consumed
        UniversalXmlPort.SetSource(InStr);
        asserterror Ok := UniversalXmlPort.Import();

        // [THEN] the platform refuses the call and the error reaches the caller
        Assert.ExpectedError('the transaction is stopped');
        Assert.IsFalse(Ok, 'A refused XmlPort Import must not assign a result.');
        Assert.AreEqual(0, ImportedRowCount(),
            'The refused instance XmlPort Import must not have imported any row.');
    end;

    [Test]
    procedure StaticStatementImport_WithUncommittedWrite_IsAllowed_AndImportsRows()
    var
        BlobRec: Record "ALT Blob" temporary;
        InStr: InStream;
    begin
        Initialize();
        OpenPayload(BlobRec, InStr);

        // [GIVEN] the same uncommitted write
        InsertPendingRow();

        // [WHEN] the static XmlPort.Import is called as a statement (result discarded)
        XmlPort.Import(XmlPort::"ALT Universal XmlPort", InStr);

        // [THEN] the call is allowed and both rows were imported
        Assert.AreEqual(2, ImportedRowCount(),
            'Statement-form XmlPort.Import is allowed in a write transaction and must import both rows.');
    end;

    [Test]
    procedure InstanceStatementImport_WithUncommittedWrite_IsAllowed_AndImportsRows()
    var
        BlobRec: Record "ALT Blob" temporary;
        UniversalXmlPort: XmlPort "ALT Universal XmlPort";
        InStr: InStream;
    begin
        Initialize();
        OpenPayload(BlobRec, InStr);

        // [GIVEN] the same uncommitted write
        InsertPendingRow();

        // [WHEN] the instance Import is called as a statement (result discarded)
        UniversalXmlPort.SetSource(InStr);
        UniversalXmlPort.Import();

        // [THEN] the call is allowed and both rows were imported
        Assert.AreEqual(2, ImportedRowCount(),
            'Statement-form XmlPort Import is allowed in a write transaction and must import both rows.');
    end;

    [Test]
    procedure StaticGuardedImport_AfterCommit_ReturnsTrue_AndImportsRows()
    var
        BlobRec: Record "ALT Blob" temporary;
        InStr: InStream;
        Ok: Boolean;
    begin
        Initialize();
        OpenPayload(BlobRec, InStr);

        // [GIVEN] a write that IS committed, so no write transaction is open
        InsertPendingRow();
        Commit();

        // [WHEN] the static XmlPort.Import is called with its Boolean result consumed
        Ok := XmlPort.Import(XmlPort::"ALT Universal XmlPort", InStr);

        // [THEN] it succeeds and both rows were imported
        Assert.IsTrue(Ok, 'A value-consuming static XmlPort.Import must succeed once Commit() has closed the write transaction.');
        Assert.AreEqual(2, ImportedRowCount(),
            'A value-consuming static XmlPort.Import after Commit() must import both rows.');
    end;

    [Test]
    procedure InstanceGuardedImport_AfterCommit_ReturnsTrue_AndImportsRows()
    var
        BlobRec: Record "ALT Blob" temporary;
        UniversalXmlPort: XmlPort "ALT Universal XmlPort";
        InStr: InStream;
        Ok: Boolean;
    begin
        Initialize();
        OpenPayload(BlobRec, InStr);

        // [GIVEN] a write that IS committed, so no write transaction is open
        InsertPendingRow();
        Commit();

        // [WHEN] the instance Import is called with its Boolean result consumed
        UniversalXmlPort.SetSource(InStr);
        Ok := UniversalXmlPort.Import();

        // [THEN] it succeeds and both rows were imported
        Assert.IsTrue(Ok, 'A value-consuming XmlPort Import must succeed once Commit() has closed the write transaction.');
        Assert.AreEqual(2, ImportedRowCount(),
            'A value-consuming XmlPort Import after Commit() must import both rows.');
    end;
}
