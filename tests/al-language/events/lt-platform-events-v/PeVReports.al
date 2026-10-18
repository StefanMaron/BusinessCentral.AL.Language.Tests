// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-triggers-and-events
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT V Subs, LT V Log, reports LT V Report A and B of PeVFixtures.al; tables Probe Rep Parent and Probe Rep Child
// Reporting Triggers events: which ones a Report.SaveAs / RunRequestPage / Execute in a test session raises, with which arguments, and what a subscriber that changes
// each var argument does to the result.
// BC versions: 27 - 29

codeunit 69854 "LT V Report Event Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT V Log";

    local procedure Seed()
    var
        Parent: Record "Probe Rep Parent";
        Child: Record "Probe Rep Child";
    begin
        Child.DeleteAll();
        Parent.DeleteAll();
        Parent.Id := 1;
        Parent.Name := 'one';
        Parent.Insert();
        Child.Id := 10;
        Child.ParentId := 1;
        Child.Code := 'a';
        Child.Insert();
        Commit();
    end;

    [TryFunction]
    local procedure TrySaveAs(ReportId: Integer; Fmt: ReportFormat; var Saved: Boolean; var Length: Integer; var Head: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        Saved := Report.SaveAs(ReportId, '', Fmt, OutStr);
        Length := TempBlob.Length();
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        if Length > 0 then
            InStr.ReadText(Head, 60);
    end;

    local procedure Run(Observer: Codeunit "Probe Observer"; Tag: Text; ReportId: Integer; Fmt: ReportFormat)
    var
        Saved: Boolean;
        Length: Integer;
        Head: Text;
        Ok: Boolean;
    begin
        Ok := TrySaveAs(ReportId, Fmt, Saved, Length, Head);
        if not Ok then
            Observer.ObserveError(Tag + ' error');
        if Head.StartsWith('%PDF') then
            Head := '%PDF';
        if Head.Contains('<ReportDataSet') then
            Head := CopyStr(Head, StrPos(Head, '<ReportDataSet'));
        Observer.Observe(Tag, Format(Ok) + '|saved=' + Format(Saved) + '|data=' + Format(Length > 0) + '|head=' + Head + '|' + Log.Take());
    end;

    [Test]
    procedure SaveAs_Pdf_RaisedEvents()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Log.Start();
        Run(Observer, 'pdf', Report::"LT V Report A", ReportFormat::Pdf);
        Log.Stop();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_Xml_RaisedEvents()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Log.Start();
        Run(Observer, 'xml', Report::"LT V Report A", ReportFormat::Xml);
        Log.Stop();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_Word_RaisedEvents()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Log.Start();
        Run(Observer, 'word', Report::"LT V Report A", ReportFormat::Word);
        Log.Stop();
        Observer.Finish();
    end;

    [Test]
    procedure SaveAs_Excel_RaisedEvents()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Log.Start();
        Run(Observer, 'excel', Report::"LT V Report A", ReportFormat::Excel);
        Log.Stop();
        Observer.Finish();
    end;

    [Test]
    procedure RunRequestPageAndExecute_RaisedEvents()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Log.Start();
        Parameters := Report.RunRequestPage(Report::"LT V Report A");
        Observer.Observe('request page log', Log.Take());
        Report.Execute(Report::"LT V Report A", '');
        Observer.Observe('execute log', Log.Take());
        Log.Stop();
        Observer.Finish();
    end;

    local procedure ChangeOne(Observer: Codeunit "Probe Observer"; EventName: Text; Fmt: ReportFormat)
    begin
        Log.Start();
        Log.SetValue('change', EventName);
        Run(Observer, EventName, Report::"LT V Report A", Fmt);
        Log.Stop();
    end;

    [Test]
    procedure SubstituteReport_SubscriberChangesTheReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ChangeOne(Observer, 'SubstituteReport', ReportFormat::Xml);
        Observer.Finish();
    end;

    [Test]
    procedure ChangeVarArguments_PdfSaveAs_First()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ChangeOne(Observer, 'HasCustomLayout', ReportFormat::Pdf);
        ChangeOne(Observer, 'SelectedBuiltinLayoutType', ReportFormat::Pdf);
        ChangeOne(Observer, 'SelectReportLayoutCode', ReportFormat::Pdf);
        Observer.Finish();
    end;

    [Test]
    procedure ChangeVarArguments_PdfSaveAs_Second()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ChangeOne(Observer, 'FetchReportLayoutByCode', ReportFormat::Pdf);
        ChangeOne(Observer, 'CustomDocumentMergerEx', ReportFormat::Pdf);
        ChangeOne(Observer, 'OnDocumentReady', ReportFormat::Pdf);
        Observer.Finish();
    end;

    [Test]
    procedure ChangeVarArguments_PdfSaveAs_Third()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ChangeOne(Observer, 'OnIntermediateDocumentReady', ReportFormat::Pdf);
        ChangeOne(Observer, 'OnDocumentPrintReady', ReportFormat::Pdf);
        ChangeOne(Observer, 'OnDocumentDownload', ReportFormat::Pdf);
        ChangeOne(Observer, 'GetPrinterName', ReportFormat::Pdf);
        Observer.Finish();
    end;

    [Test]
    procedure ChangeVarArguments_PdfSaveAs_Fourth()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ChangeOne(Observer, 'GetPaperTrayForReport', ReportFormat::Pdf);
        ChangeOne(Observer, 'ScheduleReport', ReportFormat::Pdf);
        ChangeOne(Observer, 'SetupPrinters', ReportFormat::Pdf);
        ChangeOne(Observer, 'SelectReportLayoutUI', ReportFormat::Pdf);
        ChangeOne(Observer, 'ApplicationReportMergeStrategy', ReportFormat::Pdf);
        ChangeOne(Observer, 'WordDocumentMergerAppMode', ReportFormat::Pdf);
        Observer.Finish();
    end;
}
