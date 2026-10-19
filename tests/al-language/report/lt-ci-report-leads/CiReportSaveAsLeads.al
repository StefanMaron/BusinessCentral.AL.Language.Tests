// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects of CiReportFixtures.al (84580-84591); Base Application table G/L Account
// Probe: corpus issue 667 items 132, 134, 140, 144 (odd AL behavior leads, reports). Every literal asserted below is what a local BC 29.0.54011.55816 tier produced; 27 and 28 are checked by the corpus CI legs.
// Facts: CurrReport.TargetFormat and CurrReport.PageNo under SaveAs of each format; an invalid CurrReport.FormatRegion; SaveAs of an unknown report id
// (TryFunction and asserterror); SaveAs Word, Excel and Html of reports without such a layout; SaveAs of a G/L Account data item filtered on a decimal
// FlowField (microsoft/AL#7224).
// BC versions: 27, 28, 29

codeunit 84593 "LT CI Report SaveAs Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT CI Log";

    local procedure Start(Mode: Integer)
    begin
        L.Take();
        L.SetMode(Mode);
    end;

    [TryFunction]
    local procedure TrySaveAsId(ReportId: Integer; Fmt: ReportFormat; var Result: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Result := Format(Report.SaveAs(ReportId, '', Fmt, OutS)) + ' length>0=' + Format(TempBlob.Length() > 0);
    end;

    local procedure SaveAs(var Observer: Codeunit "Probe Observer"; Name: Text; ReportId: Integer; Fmt: ReportFormat)
    var
        Result: Text;
    begin
        Observer.Observe(Name, Format(TrySaveAsId(ReportId, Fmt, Result)));
        Observer.Observe(Name + ' result', Result);
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' log', L.Take());
    end;

    local procedure SeedRows(Count: Integer)
    var
        Row: Record "LT CI Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to Count do begin
            Row.Id := i;
            Row.Insert();
        end;
    end;

    // Items 134 and 140: TargetFormat and PageNo under SaveAs, per format.
    [Test]
    procedure TargetFormat_PageNo_WordDefaultLayout()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start(0);
        SaveAs(Observer, 'pdf', Report::"LT CI Layouts Rpt", ReportFormat::Pdf);
        SaveAs(Observer, 'word', Report::"LT CI Layouts Rpt", ReportFormat::Word);
        SaveAs(Observer, 'excel', Report::"LT CI Layouts Rpt", ReportFormat::Excel);
        SaveAs(Observer, 'html', Report::"LT CI Layouts Rpt", ReportFormat::Html);
        SaveAs(Observer, 'xml', Report::"LT CI Layouts Rpt", ReportFormat::Xml);
        Observer.Expect('pdf', 'Yes');
        Observer.Expect('pdf result', 'Yes length>0=Yes');
        Observer.Expect('pdf|text', '');
        Observer.Expect('pdf|code', '');
        Observer.Expect('pdf log', 'pre targetformat=Pdf;post pagenos=1,;');
        Observer.Expect('word', 'Yes');
        Observer.Expect('word result', 'Yes length>0=Yes');
        Observer.Expect('word|text', '');
        Observer.Expect('word|code', '');
        Observer.Expect('word log', 'pre targetformat=Word;post pagenos=1,;');
        Observer.Expect('excel', 'Yes');
        Observer.Expect('excel result', 'No length>0=No');
        Observer.Expect('excel|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('excel|code', 'ReportUnsupportedFormat');
        Observer.Expect('excel log', '');
        Observer.Expect('html', 'Yes');
        Observer.Expect('html result', 'Yes length>0=Yes');
        Observer.Expect('html|text', '');
        Observer.Expect('html|code', '');
        Observer.Expect('html log', 'pre targetformat=Html;post pagenos=1,;');
        Observer.Expect('xml', 'Yes');
        Observer.Expect('xml result', 'Yes length>0=Yes');
        Observer.Expect('xml|text', '');
        Observer.Expect('xml|code', '');
        Observer.Expect('xml log', 'pre targetformat=Xml;post pagenos=1,;');
        Observer.Verify();
    end;

    [Test]
    procedure TargetFormat_PageNo_NoLayout()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start(0);
        SeedRows(3);
        SaveAs(Observer, 'xml', Report::"LT CI NoLayout Rpt", ReportFormat::Xml);
        SaveAs(Observer, 'pdf', Report::"LT CI NoLayout Rpt", ReportFormat::Pdf);
        Observer.Expect('xml', 'Yes');
        Observer.Expect('xml result', 'Yes length>0=Yes');
        Observer.Expect('xml|text', '');
        Observer.Expect('xml|code', '');
        Observer.Expect('xml log', 'pre targetformat=Xml;row 1 pageno=1;row 2 pageno=1;row 3 pageno=1;post;');
        Observer.Expect('pdf', 'Yes');
        Observer.Expect('pdf result', 'No length>0=No');
        Observer.Expect('pdf|text', 'Report 84583 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('pdf|code', 'ReportNoLayout');
        Observer.Expect('pdf log', '');
        Observer.Verify();
    end;

    // Item 144: SaveAs Html of an RDLC-only report, SaveAs Pdf and Html of an Excel-only report.
    [Test]
    procedure SaveAs_FormatsWithoutMatchingLayout()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start(0);
        // SaveAs Word and Excel of the RDLC-only report are not asserted: the Linux CI tier stubs RDLC rendering (queued for the Windows check).
        SaveAs(Observer, 'rdlc html', Report::"LT CI Rdlc Rpt", ReportFormat::Html);
        SaveAs(Observer, 'excelonly pdf', Report::"LT CI ExcelOnly Rpt", ReportFormat::Pdf);
        SaveAs(Observer, 'excelonly html', Report::"LT CI ExcelOnly Rpt", ReportFormat::Html);
        Observer.Expect('rdlc html', 'Yes');
        Observer.Expect('rdlc html result', 'No length>0=No');
        Observer.Expect('rdlc html|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('rdlc html|code', 'ReportUnsupportedFormat');
        Observer.Expect('rdlc html log', '');
        Observer.Expect('excelonly pdf', 'Yes');
        Observer.Expect('excelonly pdf result', 'No length>0=No');
        Observer.Expect('excelonly pdf|text', 'The Pdf output format is not supported by the current report layout format.');
        Observer.Expect('excelonly pdf|code', 'ReportUnsupportedFormat');
        Observer.Expect('excelonly pdf log', '');
        Observer.Expect('excelonly html', 'Yes');
        Observer.Expect('excelonly html result', 'No length>0=No');
        Observer.Expect('excelonly html|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('excelonly html|code', 'ReportUnsupportedFormat');
        Observer.Expect('excelonly html log', '');
        Observer.Verify();
    end;

    // Item 140: CurrReport.FormatRegion set to an unknown name, to empty, and to de-DE in OnPreReport.
    [Test]
    procedure FormatRegion_Invalid_Empty_Valid()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedRows(1);
        Start(1);
        SaveAs(Observer, 'invalid', Report::"LT CI NoLayout Rpt", ReportFormat::Xml);
        Start(2);
        SaveAs(Observer, 'empty', Report::"LT CI NoLayout Rpt", ReportFormat::Xml);
        Start(3);
        SaveAs(Observer, 'de-DE', Report::"LT CI NoLayout Rpt", ReportFormat::Xml);
        Observer.Expect('invalid', 'Yes');
        Observer.Expect('invalid result', 'No length>0=No');
        Observer.Expect('invalid|text', 'An unsupported language was selected (''xx-NOPE'' - ''Requested culture is not supported by the current platform'').');
        Observer.Expect('invalid|code', 'ReportFormatCultureNotFound');
        Observer.Expect('invalid log', 'pre targetformat=Xml;');
        Observer.Expect('empty', 'Yes');
        Observer.Expect('empty result', 'No length>0=No');
        Observer.Expect('empty|text', 'Invalid language ID supplied: 0.');
        Observer.Expect('empty|code', 'Argument');
        Observer.Expect('empty log', 'pre targetformat=Xml;');
        Observer.Expect('de-DE', 'Yes');
        Observer.Expect('de-DE result', 'Yes length>0=Yes');
        Observer.Expect('de-DE|text', '');
        Observer.Expect('de-DE|code', '');
        Observer.Expect('de-DE log', 'pre targetformat=Xml;region=[de-DE] dec=1.234,5;row 1 pageno=1;post;');
        Observer.Verify();
    end;

    // Item 144: SaveAs of a report id that does not exist, caught by a TryFunction and by asserterror.
    [Test]
    procedure SaveAs_UnknownId()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Start(0);
        Observer.Observe('try', Format(TrySaveAsId(71999, ReportFormat::Xml, Result)));
        Observer.Observe('try result', Result);
        // The text starts and ends with line breaks and indentation: only its first sentence is asserted.
        Observer.Observe('try text has', Format(GetLastErrorText().Contains('The metadata object Report 71999 was not found.')));
        Observer.Observe('try code', GetLastErrorCode());
        ClearLastError();
        TempBlob.CreateOutStream(OutS);
        asserterror Report.SaveAs(71999, '', ReportFormat::Pdf, OutS);
        Observer.ObserveError('asserterror');
        Observer.Expect('try', 'Yes');
        Observer.Expect('try result', 'No length>0=No');
        Observer.Expect('try text has', 'Yes');
        Observer.Expect('try code', 'MetadataNotFound');
        Observer.Expect('asserterror|text', 'You tried to invoke the Report object with the ID 71999 from the object LT CI Report SaveAs Leads. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('asserterror|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    // Item 132: SaveAs of a G/L Account data item with a filter on a decimal FlowField.
    [Test]
    procedure GLAccount_FilterOnDecimalFlowField()
    var
        Observer: Codeunit "Probe Observer";
        GLAccount: Record "G/L Account";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
        Xml: Text;
        Ok: Boolean;
    begin
        Start(0);
        GLAccount.Init();
        GLAccount."No." := 'LTCI-1';
        GLAccount.Name := 'LT CI';
        GLAccount.Insert(false);
        GLAccount.Reset();
        GLAccount.SetRange("No.", 'LTCI-1');
        GLAccount.SetFilter("Net Change", '0');
        TempBlob.CreateOutStream(OutS);
        Ok := TrySaveAsGL(GLAccount, OutS);
        Observer.Observe('net change = 0', Format(Ok));
        Observer.ObserveError('net change = 0');
        TempBlob.CreateInStream(InS);
        InS.Read(Xml);
        Observer.Observe('net change = 0 has row', Format(Xml.Contains('LTCI-1')));
        Clear(TempBlob);
        Xml := '';
        GLAccount.SetFilter("Net Change", '<>0');
        TempBlob.CreateOutStream(OutS);
        Ok := TrySaveAsGL(GLAccount, OutS);
        Observer.Observe('net change <> 0', Format(Ok));
        Observer.ObserveError('net change <> 0');
        TempBlob.CreateInStream(InS);
        InS.Read(Xml);
        Observer.Observe('net change <> 0 has row', Format(Xml.Contains('LTCI-1')));
        Clear(TempBlob);
        Xml := '';
        GLAccount.SetRange("Net Change");
        GLAccount.SetFilter(Balance, '0');
        TempBlob.CreateOutStream(OutS);
        Ok := TrySaveAsGL(GLAccount, OutS);
        Observer.Observe('balance = 0', Format(Ok));
        Observer.ObserveError('balance = 0');
        TempBlob.CreateInStream(InS);
        InS.Read(Xml);
        Observer.Observe('balance = 0 has row', Format(Xml.Contains('LTCI-1')));
        Observer.Expect('net change = 0', 'Yes');
        Observer.Expect('net change = 0|text', '');
        Observer.Expect('net change = 0|code', '');
        Observer.Expect('net change = 0 has row', 'Yes');
        Observer.Expect('net change <> 0', 'Yes');
        Observer.Expect('net change <> 0|text', '');
        Observer.Expect('net change <> 0|code', '');
        Observer.Expect('net change <> 0 has row', 'No');
        Observer.Expect('balance = 0', 'Yes');
        Observer.Expect('balance = 0|text', '');
        Observer.Expect('balance = 0|code', '');
        Observer.Expect('balance = 0 has row', 'Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySaveAsGL(var GLAccount: Record "G/L Account"; var OutS: OutStream)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(GLAccount);
        Report.SaveAs(Report::"LT CI GL Rpt", '', ReportFormat::Xml, OutS, RecRef);
    end;
}
