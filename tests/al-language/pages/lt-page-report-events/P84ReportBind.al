// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-bindsubscription-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 73036, report 73045, codeunits 73046-73048 (log 73047 used only by test codeunit 73049)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: BindSubscription / UnbindSubscription called inside report triggers (OnInitReport, OnPreReport, OnAfterGetRecord, OnPostReport) with a manual subscriber codeunit. BindSubscription(this) with the report itself is not possible (this is a report, BindSubscription takes a codeunit): skipped
// BC versions: 29 (27 and 28 by CI)

report 73045 "LT P84 Bind Rpt"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P84 Row")
        {
            trigger OnAfterGetRecord()
            begin
                Pub.Raise('get' + Format(Row.Id) + '-a');
                if Modes.Contains('bindget') then
                    TryBindNote();
                Pub.Raise('get' + Format(Row.Id) + '-b');
                if Modes.Contains('unbindget') then
                    UnbindSubscription(Sub);
                Pub.Raise('get' + Format(Row.Id) + '-c');
            end;
        }
    }

    trigger OnInitReport()
    begin
        Pub.Raise('init-1');
        if Modes.Contains('bindinit') then
            TryBindNote();
        Pub.Raise('init-2');
        if Modes.Contains('unbindinit') then
            UnbindSubscription(Sub);
        Pub.Raise('init-3');
    end;

    trigger OnPreReport()
    begin
        Pub.Raise('pre-1');
        if Modes.Contains('bindpre') then
            TryBindNote();
        Pub.Raise('pre-2');
        if Modes.Contains('unbindpre') then
            UnbindSubscription(Sub);
        Pub.Raise('pre-3');
    end;

    trigger OnPostReport()
    begin
        Pub.Raise('post-1');
        if Modes.Contains('bindpost') then
            TryBindNote();
        Pub.Raise('post-2');
        if Modes.Contains('unbindpost') then
            UnbindSubscription(Sub);
        Pub.Raise('post-3');
    end;

    var
        Pub: Codeunit "LT P84 Bind Pub";
        Sub: Codeunit "LT P84 Bind Sub";
        Modes: List of [Text];

    [TryFunction]
    local procedure TryBind()
    begin
        BindSubscription(Sub);
    end;

    local procedure TryBindNote()
    begin
        if not TryBind() then
            Pub.Raise('bindfail:' + GetLastErrorText());
    end;

    procedure AddMode(Mode: Text)
    begin
        Modes.Add(Mode);
    end;

    procedure BindOutside()
    begin
        BindSubscription(Sub);
    end;

    procedure CleanUp(): Integer
    var
        Count: Integer;
        I: Integer;
    begin
        for I := 1 to 3 do
            if UnbindSubscription(Sub) then
                Count += 1;
        exit(Count);
    end;
}

codeunit 73046 "LT P84 Bind Pub"
{
    procedure Raise(Where: Text)
    begin
        OnPing(Where);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPing(Where: Text)
    begin
    end;
}

codeunit 73047 "LT P84 Bind Log"
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

codeunit 73048 "LT P84 Bind Sub"
{
    EventSubscriberInstance = Manual;

    var
        BindLog: Codeunit "LT P84 Bind Log";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT P84 Bind Pub", 'OnPing', '', false, false)]
    local procedure HandlePing(Where: Text)
    begin
        BindLog.Add(Where);
    end;
}

codeunit 73049 "LT P84 Bind Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        BindLog: Codeunit "LT P84 Bind Log";

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

    local procedure RunWith(var Observer: Codeunit "Probe Observer"; Tag: Text; ModeList: Text; Outside: Boolean)
    var
        Pub: Codeunit "LT P84 Bind Pub";
        Rpt: Report "LT P84 Bind Rpt";
        Mode: Text;
    begin
        Seed();
        BindLog.Take();
        foreach Mode in ModeList.Split(',') do
            if Mode <> '' then
                Rpt.AddMode(Mode);
        if Outside then
            Rpt.BindOutside();
        Rpt.Run();
        Observer.Observe(Tag + '_run', BindLog.Take());
        Pub.Raise('after-1');
        Observer.Observe(Tag + '_after', BindLog.Take());
        Observer.Observe(Tag + '_unbinds', Format(Rpt.CleanUp()));
        Pub.Raise('after-2');
        Observer.Observe(Tag + '_cleaned', BindLog.Take());
    end;

    [Test]
    procedure Init_BindUnbind()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWith(Observer, 'bind', 'bindinit', false);
        Observer.Observe('af185', 'no error');
        RunWith(Observer, 'both', 'bindinit,unbindinit', false);
        Observer.Observe('af187', 'no error');
        RunWith(Observer, 'unbind_only', 'unbindinit', false);
        RunWith(Observer, 'outside_unbind', 'unbindinit', true);
        Observer.Finish();
    end;

    [Test]
    procedure Pre_BindUnbind()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWith(Observer, 'bind', 'bindpre', false);
        Observer.Observe('af198', 'no error');
        RunWith(Observer, 'both', 'bindpre,unbindpre', false);
        Observer.Observe('af201', 'no error');
        RunWith(Observer, 'unbind_only', 'unbindpre', false);
        RunWith(Observer, 'outside_unbind', 'unbindpre', true);
        Observer.Finish();
    end;

    [Test]
    procedure Get_BindUnbind()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWith(Observer, 'bind', 'bindget', false);
        Observer.Observe('af211', 'no error');
        RunWith(Observer, 'both', 'bindget,unbindget', false);
        Observer.Observe('af215', 'no error');
        RunWith(Observer, 'unbind_only', 'unbindget', false);
        RunWith(Observer, 'outside_unbind', 'unbindget', true);
        Observer.Finish();
    end;

    [Test]
    procedure Post_BindUnbind()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWith(Observer, 'bind', 'bindpost', false);
        Observer.Observe('af224', 'no error');
        RunWith(Observer, 'both', 'bindpost,unbindpost', false);
        Observer.Observe('af229', 'no error');
        RunWith(Observer, 'unbind_only', 'unbindpost', false);
        RunWith(Observer, 'outside_unbind', 'unbindpost', true);
        Observer.Finish();
    end;

    [Test]
    procedure DoubleBind_AcrossTriggers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWith(Observer, 'init_pre', 'bindinit,bindpre', false);
        Observer.Observe('af237', 'no error');
        RunWith(Observer, 'init_pre_unbind_pre', 'bindinit,bindpre,unbindpre', false);
        Observer.Observe('af243', 'no error');
        RunWith(Observer, 'init_post', 'bindinit,bindpost', false);
        RunWith(Observer, 'outside_init', 'bindinit', true);
        RunWith(Observer, 'outside_pre_unbind', 'bindpre,unbindpre', true);
        Observer.Observe('af249', 'no error');
        Observer.Finish();
    end;

    [Test]
    procedure BindOutside_NoTriggerBinding()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWith(Observer, 'outside_plain', '', true);
        Observer.Observe('af251', 'no error');
        RunWith(Observer, 'none', '', false);
        Observer.Observe('af258', 'no error');
        Observer.Finish();
    end;
}
