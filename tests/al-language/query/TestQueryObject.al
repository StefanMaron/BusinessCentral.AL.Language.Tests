// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/query-data-type
//   dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Universal Query (60022), ALT Blob (60008)

codeunit 60205 "Test Query Object"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Query_Open_Read_ReturnsInsertedRows()
    var
        RowCount: Integer;
        UniversalQuery: Query "ALT Universal Query";
    begin
        Initialize();
        InsertQueryRows();

        UniversalQuery.Open();
        RowCount := 0;

        Assert.IsTrue(UniversalQuery.Read(), 'Query must return the first inserted row');
        RowCount += 1;
        Assert.AreEqual(1, UniversalQuery.EntryNo, 'First query row must be entry 1');
        Assert.AreEqual(10, UniversalQuery.IntegerValue, 'First query row must expose the integer field value');
        Assert.AreEqual('First', UniversalQuery.TextValue, 'First query row must expose the text field value');

        Assert.IsTrue(UniversalQuery.Read(), 'Query must return the second inserted row');
        RowCount += 1;
        Assert.AreEqual(2, UniversalQuery.EntryNo, 'Second query row must be entry 2');
        Assert.AreEqual(20, UniversalQuery.IntegerValue, 'Second query row must expose the integer field value');
        Assert.AreEqual('Second', UniversalQuery.TextValue, 'Second query row must expose the text field value');

        Assert.IsFalse(UniversalQuery.Read(), 'Query must stop after the inserted rows');
        UniversalQuery.Close();

        Assert.AreEqual(2, RowCount, 'Query must return both inserted rows');
    end;

    [Test]
    procedure Query_Close_Reopen_RestartsDatasetFromFirstRow()
    var
        UniversalQuery: Query "ALT Universal Query";
    begin
        Initialize();
        InsertQueryRows();

        UniversalQuery.Open();
        Assert.IsTrue(UniversalQuery.Read(), 'Initial query open must return the first row');
        Assert.AreEqual(1, UniversalQuery.EntryNo, 'Initial query open must start at entry 1');

        UniversalQuery.Close();
        UniversalQuery.Open();

        Assert.IsTrue(UniversalQuery.Read(), 'Reopened query must return rows again from the beginning');
        Assert.AreEqual(1, UniversalQuery.EntryNo, 'Reopened query must restart at the first row');
        UniversalQuery.Close();
    end;

    [Test]
    procedure Query_SetRange_FiltersToMatchingRow()
    var
        UniversalQuery: Query "ALT Universal Query";
    begin
        Initialize();
        InsertQueryRows();

        UniversalQuery.SetRange(EntryNo, 2);
        UniversalQuery.Open();

        Assert.IsTrue(UniversalQuery.Read(), 'Filtered query must return the matching row');
        Assert.AreEqual(2, UniversalQuery.EntryNo, 'Filtered query row must be entry 2');
        Assert.AreEqual(20, UniversalQuery.IntegerValue, 'Filtered query row must keep its integer value');
        Assert.AreEqual('Second', UniversalQuery.TextValue, 'Filtered query row must keep its text value');
        Assert.IsFalse(UniversalQuery.Read(), 'Filtered query must only return one row');
        UniversalQuery.Close();
    end;

    [Test]
    procedure Query_SetFilter_WithPlaceholder_FiltersToMatchingRow()
    var
        UniversalQuery: Query "ALT Universal Query";
    begin
        Initialize();
        InsertQueryRows();

        UniversalQuery.SetFilter(IntegerValue, '>%1', 10);
        UniversalQuery.Open();

        Assert.IsTrue(UniversalQuery.Read(), 'SetFilter must return the row that matches the placeholder expression');
        Assert.AreEqual(2, UniversalQuery.EntryNo, 'SetFilter must keep only the row whose integer value is greater than 10');
        Assert.AreEqual(20, UniversalQuery.IntegerValue, 'SetFilter must preserve the matching integer value');
        Assert.IsFalse(UniversalQuery.Read(), 'SetFilter must exclude rows that do not match the placeholder expression');
        UniversalQuery.Close();
    end;

    [Test]
    procedure Query_GetFilter_AfterSetRange_ReturnsFilterText()
    var
        FilterText: Text;
        UniversalQuery: Query "ALT Universal Query";
    begin
        Initialize();
        InsertQueryRows();

        UniversalQuery.SetRange(EntryNo, 2);
        FilterText := UniversalQuery.GetFilter(EntryNo);

        Assert.AreEqual('2', FilterText, 'Query.GetFilter must return the value applied by SetRange');
    end;

    [Test]
    procedure Query_GetFilters_AfterMultipleFilters_ReturnsCombinedText()
    var
        FiltersText: Text;
        UniversalQuery: Query "ALT Universal Query";
    begin
        Initialize();
        InsertQueryRows();

        UniversalQuery.SetRange(EntryNo, 2);
        UniversalQuery.SetFilter(TextValue, 'S*');
        FiltersText := UniversalQuery.GetFilters();

        Assert.IsTrue(FiltersText <> '', 'Query.GetFilters must return text when filters are applied');
        Assert.IsTrue(FiltersText.Contains('2'), 'Query.GetFilters must include the SetRange filter value');
        Assert.IsTrue(FiltersText.Contains('S*'), 'Query.GetFilters must include the SetFilter expression');
    end;

    [Test]
    procedure Query_ColumnMetadata_ReturnsConfiguredNamesCaptionsAndNumbers()
    var
        UniversalQuery: Query "ALT Universal Query";
        EntryNoColumnNo: Integer;
        IntegerValueColumnNo: Integer;
    begin
        Initialize();

        Assert.AreEqual('EntryNo', UniversalQuery.ColumnName(EntryNo), 'Query.ColumnName must return the column name from the query definition');
        Assert.AreEqual('Entry No.', UniversalQuery.ColumnCaption(EntryNo), 'Query.ColumnCaption must return the configured caption');
        Assert.AreEqual('Text Value', UniversalQuery.ColumnCaption(TextValue), 'Query.ColumnCaption must return the configured caption for each column');

        EntryNoColumnNo := UniversalQuery.ColumnNo(EntryNo);
        IntegerValueColumnNo := UniversalQuery.ColumnNo(IntegerValue);

        Assert.IsTrue(EntryNoColumnNo > 0, 'Query.ColumnNo must return a non-zero query column number');
        Assert.IsTrue(IntegerValueColumnNo > 0, 'Query.ColumnNo must return a non-zero query column number for each column');
        Assert.AreNotEqual(EntryNoColumnNo, IntegerValueColumnNo, 'Query.ColumnNo must distinguish different query columns');
    end;

    [Test]
    procedure Query_TopNumberOfRows_LimitsResultSet()
    var
        UniversalQuery: Query "ALT Universal Query";
    begin
        Initialize();
        InsertQueryRows();

        UniversalQuery.TopNumberOfRows(1);
        UniversalQuery.Open();

        Assert.IsTrue(UniversalQuery.Read(), 'TopNumberOfRows(1) must still return the first row');
        Assert.AreEqual(1, UniversalQuery.EntryNo, 'TopNumberOfRows(1) must keep the first row only');
        Assert.IsFalse(UniversalQuery.Read(), 'TopNumberOfRows(1) must limit the dataset to one row');
        UniversalQuery.Close();
    end;

    [Test]
    procedure Query_SecurityFiltering_SetIgnored_GetIgnored()
    var
        UniversalQuery: Query "ALT Universal Query";
    begin
        Initialize();

        UniversalQuery.SecurityFiltering(SecurityFilter::Ignored);

        Assert.AreEqual(SecurityFilter::Ignored, UniversalQuery.SecurityFiltering(), 'Query.SecurityFiltering must return Ignored after setting Ignored');
    end;

    [Test]
    procedure Query_SecurityFiltering_SetFiltered_GetFiltered()
    var
        UniversalQuery: Query "ALT Universal Query";
    begin
        Initialize();

        UniversalQuery.SecurityFiltering(SecurityFilter::Ignored);
        UniversalQuery.SecurityFiltering(SecurityFilter::Filtered);

        Assert.AreEqual(SecurityFilter::Filtered, UniversalQuery.SecurityFiltering(), 'Query.SecurityFiltering must return Filtered after setting Filtered');
    end;

    [Test]
    procedure Query_SecurityFiltering_Validated_Throws()
    var
        UniversalQuery: Query "ALT Universal Query";
    begin
        Initialize();

        asserterror UniversalQuery.SecurityFiltering(SecurityFilter::Validated);
        Assert.IsTrue(GetLastErrorText() <> '', 'Query.SecurityFiltering(Validated) must throw because Validated is not allowed for queries');
    end;

    [Test]
    procedure Query_SaveAsCsv_OutStream_ExportsFilteredDataset()
    var
        BlobRec: Record "ALT Blob";
        ExportText: Text;
        OutStr: OutStream;
        UniversalQuery: Query "ALT Universal Query";
        Ok: Boolean;
    begin
        Initialize();
        InsertQueryRows();

        UniversalQuery.SetRange(EntryNo, 2);
        PrepareBlobOutStream('QCSV1', BlobRec, OutStr);
        Ok := UniversalQuery.SaveAsCsv(OutStr);
        BlobRec.Modify();
        ExportText := ReadBlobText('QCSV1');

        Assert.IsTrue(Ok, 'Query.SaveAsCsv(OutStream) must report success for a valid export stream');
        Assert.IsTrue(ExportText.Contains('Second'), 'Query.SaveAsCsv(OutStream) must export the filtered row values');
        Assert.IsFalse(ExportText.Contains('First'), 'Query.SaveAsCsv(OutStream) must respect instance filters during export');
    end;

    [Test]
    procedure Query_SaveAsJson_OutStream_ExportsFilteredDataset()
    var
        BlobRec: Record "ALT Blob";
        ExportText: Text;
        OutStr: OutStream;
        UniversalQuery: Query "ALT Universal Query";
        ExportRows: JsonArray;
        Ok: Boolean;
    begin
        Initialize();
        InsertQueryRows();

        UniversalQuery.SetRange(EntryNo, 2);
        PrepareBlobOutStream('QJSON1', BlobRec, OutStr);
        Ok := UniversalQuery.SaveAsJson(OutStr);
        BlobRec.Modify();
        ExportText := ReadBlobText('QJSON1');
        ExportRows.ReadFrom(ExportText);

        Assert.IsTrue(Ok, 'Query.SaveAsJson(OutStream) must report success for a valid export stream');
        Assert.AreEqual(1, ExportRows.Count(), 'Query.SaveAsJson(OutStream) must export only the filtered row');
        Assert.IsTrue(ExportText.Contains('Second'), 'Query.SaveAsJson(OutStream) must include the filtered row values');
        Assert.IsFalse(ExportText.Contains('First'), 'Query.SaveAsJson(OutStream) must respect instance filters during export');
    end;

    [Test]
    procedure Query_SaveAsXml_OutStream_ExportsFilteredDataset()
    var
        BlobRec: Record "ALT Blob";
        ExportText: Text;
        OutStr: OutStream;
        UniversalQuery: Query "ALT Universal Query";
        Ok: Boolean;
    begin
        Initialize();
        InsertQueryRows();

        UniversalQuery.SetRange(EntryNo, 2);
        PrepareBlobOutStream('QXML1', BlobRec, OutStr);
        Ok := UniversalQuery.SaveAsXml(OutStr);
        BlobRec.Modify();
        ExportText := ReadBlobText('QXML1');

        Assert.IsTrue(Ok, 'Query.SaveAsXml(OutStream) must report success for a valid export stream');
        Assert.IsTrue(ExportText.Contains('Second'), 'Query.SaveAsXml(OutStream) must include the filtered row values');
        Assert.IsFalse(ExportText.Contains('First'), 'Query.SaveAsXml(OutStream) must respect instance filters during export');
    end;

    [Test]
    procedure Query_SaveAsCsv_StaticOutStream_ExportsDataset()
    var
        BlobRec: Record "ALT Blob";
        ExportText: Text;
        OutStr: OutStream;
        Ok: Boolean;
    begin
        Initialize();
        InsertQueryRows();

        PrepareBlobOutStream('QCSV2', BlobRec, OutStr);
        Ok := Query.SaveAsCsv(60022, OutStr);
        BlobRec.Modify();
        ExportText := ReadBlobText('QCSV2');

        Assert.IsTrue(Ok, 'Query.SaveAsCsv(Integer, OutStream) must report success for a valid query ID and stream');
        Assert.IsTrue(ExportText.Contains('First'), 'Query.SaveAsCsv(Integer, OutStream) must export the first inserted row');
        Assert.IsTrue(ExportText.Contains('Second'), 'Query.SaveAsCsv(Integer, OutStream) must export the second inserted row');
    end;

    [Test]
    procedure Query_SaveAsJson_StaticOutStream_ExportsDataset()
    var
        BlobRec: Record "ALT Blob";
        ExportText: Text;
        OutStr: OutStream;
        ExportRows: JsonArray;
        Ok: Boolean;
    begin
        Initialize();
        InsertQueryRows();

        PrepareBlobOutStream('QJSON2', BlobRec, OutStr);
        Ok := Query.SaveAsJson(60022, OutStr);
        BlobRec.Modify();
        ExportText := ReadBlobText('QJSON2');
        ExportRows.ReadFrom(ExportText);

        Assert.IsTrue(Ok, 'Query.SaveAsJson(Integer, OutStream) must report success for a valid query ID and stream');
        Assert.AreEqual(2, ExportRows.Count(), 'Query.SaveAsJson(Integer, OutStream) must export all query rows');
        Assert.IsTrue(ExportText.Contains('First'), 'Query.SaveAsJson(Integer, OutStream) must export the first inserted row');
        Assert.IsTrue(ExportText.Contains('Second'), 'Query.SaveAsJson(Integer, OutStream) must export the second inserted row');
    end;

    [Test]
    procedure Query_SaveAsXml_StaticOutStream_ExportsDataset()
    var
        BlobRec: Record "ALT Blob";
        ExportText: Text;
        OutStr: OutStream;
        Ok: Boolean;
    begin
        Initialize();
        InsertQueryRows();

        PrepareBlobOutStream('QXML2', BlobRec, OutStr);
        Ok := Query.SaveAsXml(60022, OutStr);
        BlobRec.Modify();
        ExportText := ReadBlobText('QXML2');

        Assert.IsTrue(Ok, 'Query.SaveAsXml(Integer, OutStream) must report success for a valid query ID and stream');
        Assert.IsTrue(ExportText.Contains('First'), 'Query.SaveAsXml(Integer, OutStream) must export the first inserted row');
        Assert.IsTrue(ExportText.Contains('Second'), 'Query.SaveAsXml(Integer, OutStream) must export the second inserted row');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    local procedure InsertQueryRows()
    var
        Rec: Record "ALT Universal";
    begin
        InsertQueryRow(Rec, 1, 10, 'First');
        InsertQueryRow(Rec, 2, 20, 'Second');
    end;

    local procedure InsertQueryRow(var Rec: Record "ALT Universal"; EntryNo: Integer; IntegerValue: Integer; TextValue: Text)
    begin
        Rec.Init();
        Rec."Entry No." := EntryNo;
        Rec."Integer Field" := IntegerValue;
        Rec."Text Field" := TextValue;
        Rec.Insert();
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
}
