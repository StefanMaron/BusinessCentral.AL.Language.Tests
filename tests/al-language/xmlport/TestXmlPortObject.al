// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-data-type
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Blob (60008), ALT Universal XmlPort (60023)

codeunit 60206 "Test XmlPort Object"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure XmlPort_Export_SetDestination_ProducesWellFormedXml()
    var
        BlobRec: Record "ALT Blob";
        OutStr: OutStream;
        XmlText: Text;
        UniversalXmlPort: XmlPort "ALT Universal XmlPort";
        ExportedDoc: XmlDocument;
        ParseOk: Boolean;
        Ok: Boolean;
    begin
        Initialize();
        InsertUniversalRow(1, 10, 'First');
        InsertUniversalRow(2, 20, 'Second');

        PrepareBlobOutStream('XP1', BlobRec, OutStr);
        UniversalXmlPort.SetDestination(OutStr);
        Ok := UniversalXmlPort.Export();
        BlobRec.Modify();

        XmlText := ReadBlobText('XP1');
        ParseOk := XmlDocument.ReadFrom(XmlText, ExportedDoc);

        Assert.IsTrue(Ok, 'XmlPort.Export() must report success after SetDestination(OutStream)');
        Assert.IsTrue(ParseOk, 'XmlPort export must produce well-formed XML');
        Assert.IsTrue(XmlText.Contains('<Universals>'), 'XmlPort export must include the configured root element');
        Assert.IsTrue(XmlText.Contains('<EntryNo>1</EntryNo>'), 'XmlPort export must include the first record field value');
        Assert.IsTrue(XmlText.Contains('<TextValue>Second</TextValue>'), 'XmlPort export must include the second record field value');
    end;

    [Test]
    procedure XmlPort_SetTableView_RestrictsExportedRows()
    var
        BlobRec: Record "ALT Blob";
        Universal: Record "ALT Universal";
        OutStr: OutStream;
        XmlText: Text;
        UniversalXmlPort: XmlPort "ALT Universal XmlPort";
        Ok: Boolean;
    begin
        Initialize();
        InsertUniversalRow(1, 10, 'First');
        InsertUniversalRow(2, 20, 'Second');

        Universal.SetRange("Entry No.", 2);
        PrepareBlobOutStream('XP2', BlobRec, OutStr);
        UniversalXmlPort.SetTableView(Universal);
        UniversalXmlPort.SetDestination(OutStr);
        Ok := UniversalXmlPort.Export();
        BlobRec.Modify();

        XmlText := ReadBlobText('XP2');

        Assert.IsTrue(Ok, 'XmlPort.Export() must report success when a filtered table view is applied');
        Assert.IsTrue(XmlText.Contains('<EntryNo>2</EntryNo>'), 'XmlPort.SetTableView must keep the filtered row in the export');
        Assert.IsFalse(XmlText.Contains('<EntryNo>1</EntryNo>'), 'XmlPort.SetTableView must exclude rows outside the record filter');
    end;

    [Test]
    procedure XmlPort_Export_StaticWithRecord_RespectsFilters()
    var
        BlobRec: Record "ALT Blob";
        Universal: Record "ALT Universal";
        OutStr: OutStream;
        XmlText: Text;
        Ok: Boolean;
    begin
        Initialize();
        InsertUniversalRow(1, 10, 'First');
        InsertUniversalRow(2, 20, 'Second');

        Universal.SetRange("Entry No.", 2);
        PrepareBlobOutStream('XP3', BlobRec, OutStr);
        Ok := XmlPort.Export(60023, OutStr, Universal);
        BlobRec.Modify();

        XmlText := ReadBlobText('XP3');

        Assert.IsTrue(Ok, 'XmlPort.Export(Integer, OutStream, Record) must report success for a valid XmlPort and filtered record');
        Assert.IsTrue(XmlText.Contains('<EntryNo>2</EntryNo>'), 'Static XmlPort.Export must export the filtered record');
        Assert.IsFalse(XmlText.Contains('<EntryNo>1</EntryNo>'), 'Static XmlPort.Export must respect record filters');
    end;

    [Test]
    procedure XmlPort_Import_SetSource_InsertsRows()
    var
        BlobRec: Record "ALT Blob";
        InStr: InStream;
        OutStr: OutStream;
        Universal: Record "ALT Universal";
        UniversalXmlPort: XmlPort "ALT Universal XmlPort";
        Ok: Boolean;
    begin
        Initialize();

        PrepareBlobOutStream('XP4', BlobRec, OutStr);
        WriteXmlPortInput(OutStr);
        BlobRec.Modify();
        BlobRec.Get('XP4');
        BlobRec.CalcFields(Data);
        BlobRec.Data.CreateInStream(InStr);

        UniversalXmlPort.SetSource(InStr);
        Ok := UniversalXmlPort.Import();

        Assert.IsTrue(Ok, 'XmlPort.Import() must report success after SetSource(InStream)');
        Assert.AreEqual(2, Universal.Count(), 'XmlPort import must insert both rows from the XML payload');

        Universal.Get(1);
        Assert.AreEqual(10, Universal."Integer Field", 'XmlPort import must populate integer field values');
        Assert.AreEqual('First', Universal."Text Field", 'XmlPort import must populate text field values');

        Universal.Get(2);
        Assert.AreEqual(20, Universal."Integer Field", 'XmlPort import must import the second row integer value');
        Assert.AreEqual('Second', Universal."Text Field", 'XmlPort import must import the second row text value');
    end;

    [Test]
    procedure XmlPort_Import_StaticFromStream_InsertsRows()
    var
        BlobRec: Record "ALT Blob";
        Universal: Record "ALT Universal";
        InStr: InStream;
        OutStr: OutStream;
        Ok: Boolean;
    begin
        Initialize();

        PrepareBlobOutStream('XP5', BlobRec, OutStr);
        WriteXmlPortInput(OutStr);
        BlobRec.Modify();
        BlobRec.Get('XP5');
        BlobRec.CalcFields(Data);
        BlobRec.Data.CreateInStream(InStr);

        Ok := XmlPort.Import(60023, InStr);

        Assert.IsTrue(Ok, 'XmlPort.Import(Integer, InStream) must report success for a valid XmlPort and XML payload');
        Assert.AreEqual(2, Universal.Count(), 'Static XmlPort.Import must insert both rows from the XML payload');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    local procedure InsertUniversalRow(EntryNo: Integer; IntegerValue: Integer; TextValue: Text)
    var
        Universal: Record "ALT Universal";
    begin
        Universal.Init();
        Universal."Entry No." := EntryNo;
        Universal."Integer Field" := IntegerValue;
        Universal."Text Field" := TextValue;
        Universal.Insert();
    end;

    local procedure PrepareBlobOutStream(BlobCode: Code[20]; var BlobRec: Record "ALT Blob"; var OutStr: OutStream)
    begin
        BlobRec.Init();
        BlobRec.Code := BlobCode;
        BlobRec.Insert();
        BlobRec.Data.CreateOutStream(OutStr);
    end;

    local procedure ReadBlobText(BlobCode: Code[20]): Text
    var
        BlobRec: Record "ALT Blob";
        InStr: InStream;
        Segment: Text;
        AllText: Text;
    begin
        BlobRec.Get(BlobCode);
        BlobRec.CalcFields(Data);
        BlobRec.Data.CreateInStream(InStr);

        while not InStr.EOS() do begin
            InStr.ReadText(Segment);
            AllText += Segment;
        end;

        exit(AllText);
    end;

    local procedure WriteXmlPortInput(var OutStr: OutStream)
    begin
        OutStr.WriteText('<?xml version="1.0" encoding="UTF-8"?>');
        OutStr.WriteText('<Universals>');
        OutStr.WriteText('<Universal><EntryNo>1</EntryNo><IntegerValue>10</IntegerValue><TextValue>First</TextValue></Universal>');
        OutStr.WriteText('<Universal><EntryNo>2</EntryNo><IntegerValue>20</IntegerValue><TextValue>Second</TextValue></Universal>');
        OutStr.WriteText('</Universals>');
    end;
}
