// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-types
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 73036, report 73041, log codeunit 73042 (used only by test codeunit 73044), manual subscriber 73043
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: IncludeSender = true on an event published by a report: what Sender is, whether the subscriber can call the report procedures and see its state
// BC versions: 29 (27 and 28 by CI)

report 73041 "LT P84 Sender Rpt"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P84 Row")
        {
            trigger OnAfterGetRecord()
            begin
                Marker := 'get' + Format(Row.Id);
                RaiseFromProc('get');
            end;
        }
    }

    trigger OnInitReport()
    begin
        Marker := 'init';
        RaiseFromProc('init');
    end;

    trigger OnPreReport()
    begin
        Marker := 'pre';
        RaiseFromProc('pre');
    end;

    trigger OnPostReport()
    begin
        Marker := 'post';
        RaiseFromProc('post');
    end;

    var
        Marker: Text;
        Hits: Integer;
        Seen: Text;

    procedure SetMarker(NewMarker: Text)
    begin
        Marker := NewMarker;
    end;

    procedure GetMarker(): Text
    begin
        exit(Marker);
    end;

    procedure GetHits(): Integer
    begin
        exit(Hits);
    end;

    procedure GetSeen(): Text
    begin
        exit(Seen);
    end;

    procedure RaiseFromProc(Where: Text)
    begin
        Hits += 1;
        OnPing(Where);
        Seen += Where + '=' + Marker + ';';
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPing(Where: Text)
    begin
    end;
}

codeunit 73042 "LT P84 RptSnd Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

codeunit 73043 "LT P84 RptSnd Sub"
{
    EventSubscriberInstance = Manual;

    var
        SenderLog: Codeunit "LT P84 RptSnd Log";
        Nest: Boolean;
        ChangeMarker: Boolean;

    procedure SetNest(NewNest: Boolean)
    begin
        Nest := NewNest;
    end;

    procedure SetChangeMarker(NewChange: Boolean)
    begin
        ChangeMarker := NewChange;
    end;

    [EventSubscriber(ObjectType::Report, Report::"LT P84 Sender Rpt", 'OnPing', '', false, false)]
    local procedure HandlePing(Sender: Report "LT P84 Sender Rpt"; Where: Text)
    begin
        SenderLog.Add(Where + '|marker=' + Sender.GetMarker() + '|hits=' + Format(Sender.GetHits()));
        if ChangeMarker then
            Sender.SetMarker('sub-' + Where);
        if Nest and (Where = 'nest') then
            Sender.RaiseFromProc('inner');
    end;
}

codeunit 73044 "LT P84 RptSnd Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SenderLog: Codeunit "LT P84 RptSnd Log";

    local procedure Seed()
    var
        Row: Record "LT P84 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'One';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'Two';
        Row.Insert();
    end;

    [Test]
    procedure Proc_SenderIsReportInstance()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT P84 RptSnd Sub";
        Rpt: Report "LT P84 Sender Rpt";
    begin
        SenderLog.Take();
        Sub.SetChangeMarker(true);
        BindSubscription(Sub);
        Rpt.SetMarker('m1');
        Rpt.RaiseFromProc('p');
        Observer.Observe('log', SenderLog.Take());
        Observer.Observe('marker_after', Rpt.GetMarker());
        Observer.Observe('hits_after', Format(Rpt.GetHits()));
        Observer.Observe('seen', Rpt.GetSeen());
        Rpt.RaiseFromProc('p2');
        Observer.Observe('log2', SenderLog.Take());
        Observer.Observe('seen2', Rpt.GetSeen());
        UnbindSubscription(Sub);
        Observer.Finish();
    end;

    [Test]
    procedure Proc_NotBound_NoSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT P84 Sender Rpt";
    begin
        SenderLog.Take();
        Rpt.SetMarker('m1');
        Rpt.RaiseFromProc('p');
        Observer.Observe('log', SenderLog.Take());
        Observer.Observe('marker_after', Rpt.GetMarker());
        Observer.Observe('hits_after', Format(Rpt.GetHits()));
        Observer.Finish();
    end;

    [Test]
    procedure Proc_TwoInstances()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT P84 RptSnd Sub";
        Rpt1: Report "LT P84 Sender Rpt";
        Rpt2: Report "LT P84 Sender Rpt";
    begin
        SenderLog.Take();
        Sub.SetChangeMarker(true);
        BindSubscription(Sub);
        Rpt1.SetMarker('first');
        Rpt2.SetMarker('second');
        Rpt2.RaiseFromProc('x');
        Observer.Observe('log_second', SenderLog.Take());
        Observer.Observe('marker1', Rpt1.GetMarker());
        Observer.Observe('marker2', Rpt2.GetMarker());
        Observer.Observe('hits1', Format(Rpt1.GetHits()));
        Observer.Observe('hits2', Format(Rpt2.GetHits()));
        Rpt1.RaiseFromProc('y');
        Observer.Observe('log_first', SenderLog.Take());
        Observer.Observe('marker1_after', Rpt1.GetMarker());
        Observer.Observe('marker2_after', Rpt2.GetMarker());
        UnbindSubscription(Sub);
        Observer.Finish();
    end;

    [Test]
    procedure Proc_NestedRaiseFromSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT P84 RptSnd Sub";
        Rpt: Report "LT P84 Sender Rpt";
    begin
        SenderLog.Take();
        Sub.SetNest(true);
        BindSubscription(Sub);
        Rpt.SetMarker('m');
        Rpt.RaiseFromProc('nest');
        Observer.Observe('log', SenderLog.Take());
        Observer.Observe('hits', Format(Rpt.GetHits()));
        Observer.Observe('seen', Rpt.GetSeen());
        UnbindSubscription(Sub);
        Observer.Finish();
    end;

    [Test]
    procedure Triggers_Run_SenderInEachTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT P84 RptSnd Sub";
        Rpt: Report "LT P84 Sender Rpt";
    begin
        Seed();
        SenderLog.Take();
        BindSubscription(Sub);
        Rpt.Run();
        Observer.Observe('log', SenderLog.Take());
        Observer.Observe('marker_after', Rpt.GetMarker());
        Observer.Observe('hits_after', Format(Rpt.GetHits()));
        Observer.Observe('seen', Rpt.GetSeen());
        UnbindSubscription(Sub);
        Observer.Finish();
    end;

    [Test]
    procedure Triggers_Run_SubscriberChangesMarker()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT P84 RptSnd Sub";
        Rpt: Report "LT P84 Sender Rpt";
    begin
        Seed();
        SenderLog.Take();
        Sub.SetChangeMarker(true);
        BindSubscription(Sub);
        Rpt.Run();
        Observer.Observe('log', SenderLog.Take());
        Observer.Observe('marker_after', Rpt.GetMarker());
        Observer.Observe('hits_after', Format(Rpt.GetHits()));
        Observer.Observe('seen', Rpt.GetSeen());
        UnbindSubscription(Sub);
        Observer.Finish();
    end;

    [Test]
    procedure Triggers_StaticRun_SubscriberStillSeesSender()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT P84 RptSnd Sub";
    begin
        Seed();
        SenderLog.Take();
        Sub.SetChangeMarker(true);
        BindSubscription(Sub);
        Report.Run(Report::"LT P84 Sender Rpt");
        Observer.Observe('log', SenderLog.Take());
        UnbindSubscription(Sub);
        Observer.Finish();
    end;

    [Test]
    procedure Triggers_Run_NoRows()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT P84 RptSnd Sub";
        Row: Record "LT P84 Row";
        Rpt: Report "LT P84 Sender Rpt";
    begin
        Row.DeleteAll();
        SenderLog.Take();
        BindSubscription(Sub);
        Rpt.Run();
        Observer.Observe('log', SenderLog.Take());
        Observer.Observe('seen', Rpt.GetSeen());
        UnbindSubscription(Sub);
        Observer.Finish();
    end;

    [Test]
    procedure Triggers_Run_AfterUnbind()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT P84 RptSnd Sub";
        Rpt: Report "LT P84 Sender Rpt";
    begin
        Seed();
        SenderLog.Take();
        BindSubscription(Sub);
        UnbindSubscription(Sub);
        Rpt.Run();
        Observer.Observe('log', SenderLog.Take());
        Observer.Observe('seen', Rpt.GetSeen());
        Observer.Observe('hits', Format(Rpt.GetHits()));
        Observer.Finish();
    end;
}
