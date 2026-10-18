// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-triggers-and-events
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT V Subs, LT V Log, LT V Event Log of PeVFixtures.al
// Events that only a platform action raises (install, upgrade, environment copy, user initialization, company open and close, debugger, SmartList designer,
// Excel and the ChangeCompany system action): does a subscriber ever see them in a test session, and what does a subscriber that changes the var argument do.
// The subscribers also write a row into the table LT V Event Log (no company), so an event raised before the test session started is visible too.
// BC versions: 27 - 29

codeunit 69855 "LT V Session Worker"
{
    trigger OnRun()
    var
        Row: Record "LT V Event Log";
    begin
        Row.Init();
        Row."Event Name" := 'Worker';
        Row."Session Id" := SessionId();
        Row.Insert();
    end;
}

codeunit 69853 "LT V Session Event Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT V Log";

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
        Names.Add('OnCompanyOpen');
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
        Observer.Observe('rows OnCompanyOpen for this session', Format(RowsOfSession('OnCompanyOpen', SessionId())));
        Observer.Observe('rows OnCompanyOpenCompleted for this session', Format(RowsOfSession('OnCompanyOpenCompleted', SessionId())));
        Observer.Observe('rows OnCompanyClose for this session', Format(RowsOfSession('OnCompanyClose', SessionId())));
        Observer.Observe('any OnCompanyOpenCompleted row', Format(RowsOf('OnCompanyOpenCompleted') > 0));
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
        Row.SetRange("Event Name", 'OnCompanyOpenCompleted');
        Row.SetRange("Session Id", SessionId());
        if Row.FindFirst() then
            Observer.Observe('open completed info is the company of the test session', Format(Row.Info = CompanyName()));
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
    procedure StartSession_RaisesCompanyOpenAndClose()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT V Event Log";
        Session: Integer;
        Started: Boolean;
        Deadline: DateTime;
        OpenId: Integer;
        WorkerId: Integer;
        CloseId: Integer;
    begin
        Started := StartSession(Session, Codeunit::"LT V Session Worker", CompanyName());
        Observer.Observe('started', Format(Started));
        Deadline := CurrentDateTime() + 60000;
        while (RowsOfSession('Worker', Session) = 0) and (CurrentDateTime() < Deadline) do
            Sleep(250);
        Deadline := CurrentDateTime() + 30000;
        while (RowsOfSession('OnCompanyClose', Session) = 0) and (CurrentDateTime() < Deadline) do
            Sleep(250);
        Row.SetRange("Session Id", Session);
        Row.SetRange("Event Name", 'OnCompanyOpenCompleted');
        if Row.FindFirst() then
            OpenId := Row.Id;
        Row.SetRange("Event Name", 'Worker');
        if Row.FindFirst() then
            WorkerId := Row.Id;
        Row.SetRange("Event Name", 'OnCompanyClose');
        if Row.FindFirst() then
            CloseId := Row.Id;
        Observer.Observe('open rows', Format(RowsOfSession('OnCompanyOpen', Session)));
        Observer.Observe('open completed rows', Format(RowsOfSession('OnCompanyOpenCompleted', Session)));
        Observer.Observe('worker rows', Format(RowsOfSession('Worker', Session)));
        Observer.Observe('close rows', Format(RowsOfSession('OnCompanyClose', Session)));
        Observer.Observe('open completed before worker', Format((OpenId > 0) and (OpenId < WorkerId)));
        Observer.Observe('worker before close', Format((WorkerId > 0) and (WorkerId < CloseId)));
        Row.SetRange("Event Name", 'OnCompanyOpenCompleted');
        if Row.FindFirst() then
            Observer.Observe('open completed info is the company', Format(Row.Info = CompanyName()));
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
}
