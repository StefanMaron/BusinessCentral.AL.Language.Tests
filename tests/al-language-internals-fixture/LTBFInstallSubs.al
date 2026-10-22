// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-triggers-and-events
// Scope: in-scope
// Probe: corpus issue 661 items P4, P5 and P8 (writer BF). This app is published and installed before "AL Language Coverage Tests", which depends on it.
//   The subscribers below log every call of the "Extension Triggers" install events into a table of this app. The test codeunit
//   "LT BF Install Tests" (al-language, install/lt-bf-install-probes) counts the rows: 2 per-company rows and 1 per-database row mean the
//   subscribers ran only at this app's own install; more rows mean they also ran when a later app was installed.
// Install code must never fail (check-install-triggers.py): every write is `if Insert() then;` into a DataPerCompany = false table.
// BC versions: 27 - 29

table 61052 "LT BF Fixture Install Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; "Event Name"; Text[60]) { }
        field(3; "Company"; Text[60]) { }
        field(4; "Session Id"; Integer) { }
        field(5; "Context"; Text[30]) { }
        field(6; "Counter"; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 61053 "LT BF Fixture Install Subs"
{
    local procedure WriteRow(EventName: Text)
    var
        Row: Record "LT BF Fixture Install Log";
        State: Codeunit "LT BF Fixture Install State";
    begin
        Row.Init();
        Row."Event Name" := CopyStr(EventName, 1, MaxStrLen(Row."Event Name"));
        Row."Company" := CopyStr(CompanyName(), 1, MaxStrLen(Row."Company"));
        Row."Session Id" := SessionId();
        Row."Context" := CopyStr(Format(Session.GetExecutionContext()), 1, MaxStrLen(Row."Context"));
        Row."Counter" := State.Next();
        if Row.Insert() then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure InstallPerCompany()
    begin
        WriteRow('OnInstallAppPerCompany');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure InstallPerDatabase()
    begin
        WriteRow('OnInstallAppPerDatabase');
    end;
}

// The state of one session: Next() counts the calls. If the count goes on across the companies and the per-database run, the
// SingleInstance state is kept between them. "AL Language Coverage Tests" reads Current() inside its own install subscribers.
codeunit 61054 "LT BF Fixture Install State"
{
    SingleInstance = true;

    var
        Calls: Integer;

    procedure Next(): Integer
    begin
        Calls += 1;
        exit(Calls);
    end;

    procedure Current(): Integer
    begin
        exit(Calls);
    end;
}
