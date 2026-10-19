// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained tables 84880-84881, install codeunit 84882, test codeunit 84883, codeunit 84899
// Probe: corpus issue #669 (writer CN), items 46, 47 and 54.
//   46: the order of OnInstallAppPerDatabase and OnInstallAppPerCompany in one install codeunit, and whether the per-company trigger sees a row
//       the per-database trigger wrote (microsoft/AL#1495: in 2018 PerCompany ran first).
//   47: an install trigger inserts with Insert(true) into an AutoIncrement table of its own app (microsoft/AL#6573: a permission error on BC 18 SaaS).
//   54: CreateDateTime, DT2Date, DT2Time and Format(DateTime, 0, 9) inside install code, next to the same calls in the test session.
// The install trigger must never fail (a failing install breaks the whole corpus app), so it writes with "if Insert() then;" and calls nothing
// that can raise. A per-database log (DataPerCompany = false) numbers its rows in the order the triggers wrote them.
// BC versions: 27, 28, 29

table 84880 "LT CN Install Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "Key"; Code[50]) { }
        field(2; Seq; Integer) { }
        field(3; Note; Text[250]) { }
    }

    keys
    {
        key(PK; "Key") { Clustered = true; }
    }
}

table 84881 "LT CN Install Auto"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; Txt; Text[30]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

codeunit 84882 "LT CN Installer"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    begin
        AddLog('DB', '');
    end;

    trigger OnInstallAppPerCompany()
    var
        DbRow: Record "LT CN Install Log";
        Auto: Record "LT CN Install Auto";
        Facts: Codeunit "LT CN Time Facts";
    begin
        AddLog(CopyStr('CO:' + CompanyName(), 1, 50), Format(DbRow.Get('DB'), 0, 9));

        Auto.Init();
        Auto."Entry No." := 0;
        Auto.Txt := 'install';
        if Auto.Insert(true) then;

        AddLog(CopyStr('TIME:' + CompanyName(), 1, 50), CopyStr(Facts.TimeFacts(), 1, 250));
    end;

    local procedure AddLog(LogKey: Code[50]; LogNote: Text[250])
    var
        Log: Record "LT CN Install Log";
        Counter: Record "LT CN Install Log";
    begin
        Log.Init();
        Log."Key" := LogKey;
        Log.Seq := Counter.Count() + 1;
        Log.Note := LogNote;
        if Log.Insert() then;
    end;
}

codeunit 84899 "LT CN Time Facts"
{
    procedure TimeFacts(): Text
    var
        DT: DateTime;
        S: SessionSettings;
    begin
        DT := CreateDateTime(20240601D, 120000T);
        S.Init();
        exit(Format(DT, 0, 9) + '|' + Format(DT2Date(DT), 0, 9) + '|' + Format(DT2Time(DT), 0, 9) + '|' + S.TimeZone());
    end;

}

codeunit 84883 "LT CN Install Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // No Initialize/DeleteAll: these tests read rows the install triggers wrote before any test ran.

    [Test]
    procedure Install_TriggerOrder()
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT CN Install Log";
        DbSeq: Integer;
    begin
        Observer.Observe('db row', Format(Log.Get('DB')));
        DbSeq := Log.Seq;
        Observer.Observe('db seq', Format(DbSeq));
        Observer.Observe('company row', Format(Log.Get(CopyStr('CO:' + CompanyName(), 1, 50))));
        Observer.Observe('company after db', Format(Log.Seq > DbSeq));
        Observer.Observe('company saw db row', Log.Note);
        Observer.Finish();
    end;

    [Test]
    procedure Install_AutoIncrementInsertTrue()
    var
        Observer: Codeunit "Probe Observer";
        Auto: Record "LT CN Install Auto";
    begin
        Observer.Observe('count', Format(Auto.Count()));
        if Auto.FindFirst() then begin
            Observer.Observe('entry no', Format(Auto."Entry No."));
            Observer.Observe('txt', Auto.Txt);
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Install_TimeFactsMatchTestSession()
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT CN Install Log";
        Facts: Codeunit "LT CN Time Facts";
    begin
        Observer.Observe('time row', Format(Log.Get(CopyStr('TIME:' + CompanyName(), 1, 50))));
        Observer.Observe('install', Log.Note);
        Observer.Observe('test session', Facts.TimeFacts());
        Observer.Finish();
    end;
}
