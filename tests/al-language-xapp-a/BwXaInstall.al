// Install code and Company Triggers of cross-app fixture A (al-runtime-rs ADR-046 amendment 1, probes Q1 and Q3), writer BW.
// The two subscriber codeunits of BwXaOrder.al also subscribe to "Extension Triggers" and log each install call here, with how many
// Company Triggers calls (OnCompanyOpen + OnCompanyOpenCompleted) this app's subscriber counted in the same session so far.
// The AL Language Coverage Tests app's install routines log the same counter (Q3: does a dependency app's Company Triggers subscriber
// run in the install session of a later app?).
// Install code must never fail (check-install-triggers.py): every write is `if Insert() then;` into a DataPerCompany = false table.


table 61100 "LT BW XA Install Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; Routine; Text[30]) { }
        field(3; Company; Text[60]) { }
        field(4; "Session Id"; Integer) { }
        field(5; "Company Open Calls"; Integer) { }
        field(6; Context; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 61101 "LT BW XA Company Open Count"
{
    SingleInstance = true;

    var
        CallCount: Integer;

    procedure Add()
    begin
        CallCount += 1;
    end;

    procedure Calls(): Integer
    begin
        exit(CallCount);
    end;
}

codeunit 61102 "LT BW XA Company Open Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpen', '', false, false)]
    local procedure CompanyOpen()
    var
        Count: Codeunit "LT BW XA Company Open Count";
    begin
        Count.Add();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpenCompleted', '', false, false)]
    local procedure CompanyOpenCompleted()
    var
        Count: Codeunit "LT BW XA Company Open Count";
    begin
        Count.Add();
    end;
}

codeunit 61103 "LT BW XA Install Writer"
{
    procedure WriteRow(Routine: Text)
    var
        Row: Record "LT BW XA Install Log";
        Count: Codeunit "LT BW XA Company Open Count";
    begin
        Row.Init();
        Row.Routine := CopyStr(Routine, 1, MaxStrLen(Row.Routine));
        Row.Company := CopyStr(CompanyName(), 1, MaxStrLen(Row.Company));
        Row."Session Id" := SessionId();
        Row."Company Open Calls" := Count.Calls();
        Row.Context := CopyStr(Format(Session.GetExecutionContext()), 1, MaxStrLen(Row.Context));
        if Row.Insert() then;
    end;
}
