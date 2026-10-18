// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-triggers-and-events
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT V Subs, LT V Log, LT V Event Log, LT V Row A - I and the LT V reports of PeVFixtures.al
// Platform events probed in one test codeunit (the log is SingleInstance, so it must belong to exactly one test codeunit):
//   1. Global Triggers: when each event fires, its arguments, what changing the mask, the four setup flags or the handed record does. Every scenario uses its own table,
//      because the platform asks for mask and setup once per table.
//   2. Events only a platform action raises (install, upgrade, environment copy, user initialization, company open and close, debugger, SmartList designer, Excel, the ChangeCompany
//      system action). The subscribers also write a row into the table LT V Event Log (no company), so an event raised before the test session started is visible too.
//   3. Reporting Triggers raised by Report.SaveAs / RunRequestPage / Execute, and what a subscriber that changes each var argument does.
// Note: the PDF, Word and Excel renders of Report.SaveAs run on the Linux tier of the CI (the 'Test Report SaveAs Pdf Body' test explains why they can refuse); their rows record what that tier raises.
// Not pinned: the PDF, Word and Excel renders and Report.Execute. The Linux tier of the CI stubs the RDLC renderer (it refuses with 'RDLC report rendering is not implemented on Linux BC'),
// so the events after the refusal are the stub's, not Business Central's. Only the Xml path and the request page are asserted.
// BC versions: 27 - 29

codeunit 69852 "LT V Platform Event Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT V Log";


    local procedure Cycle(TableNo: Integer; Observer: Codeunit "Probe Observer")
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableNo);
        RecRef.DeleteAll();
        Observer.Observe('open_and_deleteall', Log.Take());
        RecRef.Init();
        RecRef.Field(1).Value := 1;
        RecRef.Field(2).Value := 'a';
        RecRef.Field(3).Value := 1.5;
        RecRef.Insert(true);
        Observer.Observe('insert', Log.Take());
        RecRef.Field(2).Value := 'b';
        RecRef.Field(3).Value := 2.5;
        RecRef.Modify(true);
        Observer.Observe('modify', Log.Take());
        RecRef.Rename(2);
        Observer.Observe('rename', Log.Take());
        RecRef.Delete(true);
        Observer.Observe('delete', Log.Take());
        RecRef.Close();
        Log.Stop();
    end;

    [Test]
    procedure GlobalTriggers_SubscriberLeavesDefaults_RowA()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Start();
        Cycle(Database::"LT V Row A", Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GlobalTriggers_MaskFifteenAndAllSetupFlagsFalse_RowB()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Start();
        Cycle(Database::"LT V Row B", Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GlobalTriggers_MaskZeroAndAllSetupFlagsTrue_RowC()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Start();
        Cycle(Database::"LT V Row C", Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GlobalTriggers_MaskFifteenAndAllSetupFlagsTrue_Arguments_RowD()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Start();
        Cycle(Database::"LT V Row D", Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GlobalTriggers_OnlyInsertFlag_RowE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Start();
        Cycle(Database::"LT V Row E", Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GlobalTriggers_OnlyModifyFlag_RowF()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Start();
        Cycle(Database::"LT V Row F", Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GlobalTriggers_OnlyDeleteFlag_RowG()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Start();
        Cycle(Database::"LT V Row G", Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GlobalTriggers_OnlyRenameFlag_RowH()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Start();
        Cycle(Database::"LT V Row H", Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GlobalTriggers_SubscriberChangesTheRecordItIsHanded_RowI()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Check: Record "LT V Row I";
    begin
        Log.Start();
        RecRef.Open(Database::"LT V Row I");
        RecRef.DeleteAll();
        Observer.Observe('open_and_deleteall', Log.Take());
        RecRef.Init();
        RecRef.Field(1).Value := 1;
        RecRef.Field(2).Value := 'a';
        RecRef.Field(3).Value := 1.5;
        RecRef.Insert(true);
        Observer.Observe('insert_log', Log.Take());
        Observer.Observe('variable_after_insert', Format(RecRef.Field(2).Value) + '/' + Format(RecRef.Field(3).Value));
        Observer.Observe('found', Format(Check.Get(1)));
        Observer.Observe('stored_after_insert', Check.Name + '/' + Format(Check.Amount));
        RecRef.Field(2).Value := 'b';
        RecRef.Field(3).Value := 2.5;
        RecRef.Modify(true);
        Observer.Observe('modify_log', Log.Take());
        Observer.Observe('variable_after_modify', Format(RecRef.Field(2).Value) + '/' + Format(RecRef.Field(3).Value));
        Observer.Observe('found_again', Format(Check.Get(1)));
        Observer.Observe('stored_after_modify', Check.Name + '/' + Format(Check.Amount));
        RecRef.Close();
        Log.Stop();
        Observer.Finish();
    end;

    [Test]
    procedure GlobalTriggers_InsertWithoutTrigger_DoesNotAskOrRaise()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT V Row D";
    begin
        // Row D was asked in the test above, so this checks the raise, not the ask: Insert(false) and Modify(false) run no trigger and raise no event.
        Log.Start();
        Row.Id := 5;
        Row.Name := 'quiet';
        Row.Insert(false);
        Observer.Observe('insert_false', Log.Take());
        Row.Name := 'quiet2';
        Row.Modify(false);
        Observer.Observe('modify_false', Log.Take());
        Row.Delete(false);
        Observer.Observe('delete_false', Log.Take());
        Row.Id := 6;
        Row.Insert(true);
        Observer.Observe('insert_true', Log.Take());
        Row.Delete(true);
        Observer.Observe('delete_true', Log.Take());
        Log.Stop();
        Observer.Finish();
    end;


    local procedure RowsOf(EventName: Text): Integer
    var
        Row: Record "LT V Event Log";
    begin
        Row.SetRange("Event Name", EventName);
        exit(Row.Count());
    end;

    local procedure RowsOfSession(EventName: Text; Session: Integer): Integer
    var
        Row: Record "LT V Event Log";
    begin
        Row.SetRange("Event Name", EventName);
        Row.SetRange("Session Id", Session);
        exit(Row.Count());
    end;

    [Test]
    procedure EventLog_RowsWrittenBeforeTheTestSessionStarted()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT V Event Log";
        Names: List of [Text];
        N: Text;
    begin
        Names.Add('OnInstallAppPerCompany');
        Names.Add('OnInstallAppPerDatabase');
        Names.Add('OnUpgradePerCompany');
        Names.Add('OnUpgradePerDatabase');
        Names.Add('OnValidateUpgradePerCompany');
        Names.Add('OnValidateUpgradePerDatabase');
        Names.Add('OnAfterUpgradeCommitPerCompany');
        Names.Add('OnAfterUpgradeCommitPerDatabase');
        Names.Add('OnAfterCopyEnvironmentPerCompany');
        Names.Add('OnAfterCopyEnvironmentPerDatabase');
        Names.Add('OnAfterCopyEnvironmentToSandbox');
        Names.Add('OnAfterCopyEnvironmentToSandboxPerCompany');
        Names.Add('OnAfterUserInitialization');
        foreach N in Names do
            Observer.Observe('rows ' + N, Format(RowsOf(N)));
        Observer.Observe('early entries of the test session', Log.Early());
        Observer.Observe('total rows', Format(Row.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure EventLog_InstallRowCompany()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT V Event Log";
    begin
        Row.SetRange("Event Name", 'OnInstallAppPerCompany');
        if Row.FindSet() then
            repeat
                Observer.Observe('install per company #' + Format(Row.Id) + ' info is the company of the test session', Format(Row.Info = CompanyName()));
            until Row.Next() = 0;
        Observer.Finish();
    end;

    [Test]
    procedure InSession_NothingRaisesTheOtherEvents()
    var
        Observer: Codeunit "Probe Observer";
        Child: Record "Probe Rep Child";
    begin
        Log.Start();
        Child.Id := 90001;
        Child.Insert(true);
        Commit();
        Child.Delete(true);
        Commit();
        Observer.Observe('log after write and commit', Log.Take());
        Log.Stop();
        Observer.Finish();
    end;

    [Test]
    procedure StartSession_IsRefusedInATestSession()
    var
        Observer: Codeunit "Probe Observer";
        Session: Integer;
        Started: Boolean;
    begin
        // A new session would show OnCompanyOpen and OnCompanyOpenCompleted to the worker; the test session cannot start one.
        asserterror Started := StartSession(Session, Codeunit::"LT V Session Worker", CompanyName());
        Observer.ObserveError('start session');
        Observer.Observe('started', Format(Started));
        Observer.Finish();
    end;

    [Test]
    procedure ChangeCompany_RecordChangeCompanyDoesNotRaiseTheSystemActionEvent()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT V Row A";
    begin
        Log.Start();
        Log.SetValue('change', 'ChangeCompany');
        Log.SetValue('company', 'LT V No Such Company');
        Row.ChangeCompany(CompanyName());
        Observer.Observe('log', Log.Take());
        Observer.Observe('company of the variable', Row.CurrentCompany());
        Observer.Observe('count in the other company', Format(Row.Count()));
        Log.Stop();
        Observer.Finish();
    end;


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

    [TryFunction]
    local procedure TryRunRequestPage(var Parameters: Text)
    begin
        Parameters := Report.RunRequestPage(Report::"LT V Report A");
    end;

    [RequestPageHandler]
    procedure RequestPageA(var Request: TestRequestPage "LT V Report A")
    begin
        Request.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('RequestPageA')]
    procedure RunRequestPage_RaisedEvents()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Log.Start();
        Observer.Observe('request page ok', Format(TryRunRequestPage(Parameters)));
        Observer.ObserveError('request page error');
        Observer.Observe('request page log', Log.Take());
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
    procedure ChangeVarArguments_XmlSaveAs_First()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ChangeOne(Observer, 'HasCustomLayout', ReportFormat::Xml);
        ChangeOne(Observer, 'SelectedBuiltinLayoutType', ReportFormat::Xml);
        ChangeOne(Observer, 'SelectReportLayoutCode', ReportFormat::Xml);
        Observer.Finish();
    end;

    [Test]
    procedure ChangeVarArguments_XmlSaveAs_Second()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ChangeOne(Observer, 'FetchReportLayoutByCode', ReportFormat::Xml);
        ChangeOne(Observer, 'CustomDocumentMergerEx', ReportFormat::Xml);
        ChangeOne(Observer, 'OnDocumentReady', ReportFormat::Xml);
        Observer.Finish();
    end;

    [Test]
    procedure ChangeVarArguments_XmlSaveAs_Third()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ChangeOne(Observer, 'OnIntermediateDocumentReady', ReportFormat::Xml);
        ChangeOne(Observer, 'OnDocumentPrintReady', ReportFormat::Xml);
        ChangeOne(Observer, 'OnDocumentDownload', ReportFormat::Xml);
        ChangeOne(Observer, 'GetPrinterName', ReportFormat::Xml);
        Observer.Finish();
    end;

    [Test]
    procedure ChangeVarArguments_XmlSaveAs_Fourth()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ChangeOne(Observer, 'GetPaperTrayForReport', ReportFormat::Xml);
        ChangeOne(Observer, 'ScheduleReport', ReportFormat::Xml);
        ChangeOne(Observer, 'SetupPrinters', ReportFormat::Xml);
        ChangeOne(Observer, 'SelectReportLayoutUI', ReportFormat::Xml);
        ChangeOne(Observer, 'ApplicationReportMergeStrategy', ReportFormat::Xml);
        ChangeOne(Observer, 'WordDocumentMergerAppMode', ReportFormat::Xml);
        Observer.Finish();
    end;
}
