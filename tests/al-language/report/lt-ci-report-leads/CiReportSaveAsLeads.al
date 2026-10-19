// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects of CiReportFixtures.al (84580-84591); Base Application table G/L Account
// Probe: corpus issue 667 items 132, 134, 140, 144 (odd AL behavior leads, reports). Values observed on a local BC 29.0 tier, then on the CI legs.
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    // Item 144: SaveAs Word, Excel, Html and Pdf of an RDLC-only report and SaveAs Word of an Excel-only report.
    [Test]
    procedure SaveAs_FormatsWithoutMatchingLayout()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start(0);
        SaveAs(Observer, 'rdlc word', Report::"LT CI Rdlc Rpt", ReportFormat::Word);
        SaveAs(Observer, 'rdlc excel', Report::"LT CI Rdlc Rpt", ReportFormat::Excel);
        SaveAs(Observer, 'rdlc html', Report::"LT CI Rdlc Rpt", ReportFormat::Html);
        SaveAs(Observer, 'excelonly pdf', Report::"LT CI ExcelOnly Rpt", ReportFormat::Pdf);
        SaveAs(Observer, 'excelonly html', Report::"LT CI ExcelOnly Rpt", ReportFormat::Html);
        Observer.Finish();
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
        Observer.Finish();
    end;

    // Item 144: SaveAs of a report id that does not exist, caught by a TryFunction and by asserterror.
    [Test]
    procedure SaveAs_UnknownId()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Start(0);
        SaveAs(Observer, 'try', 71999, ReportFormat::Xml);
        TempBlob.CreateOutStream(OutS);
        asserterror Report.SaveAs(71999, '', ReportFormat::Pdf, OutS);
        Observer.ObserveError('asserterror');
        Observer.Finish();
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
        Observer.Finish();
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
