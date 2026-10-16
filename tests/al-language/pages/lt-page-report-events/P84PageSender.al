// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-types
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 73036, page 73050, log codeunit 73051 (used only by test codeunit 73053), manual subscriber 73052
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: IncludeSender = true on an event published by a page (procedure, OnOpenPage, OnNewRecord, OnAfterGetRecord, OnQueryClosePage, OnClosePage): what Sender is and whether the subscriber can call the page procedures
// BC versions: 29 (27 and 28 by CI)

page 73050 "LT P84 Sender Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT P84 Row";

    layout
    {
        area(Content)
        {
            field(IdF; Rec.Id)
            {
                ApplicationArea = All;
            }
            field(NameF; Rec.Name)
            {
                ApplicationArea = All;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Marker := 'open';
        RaiseFromProc('open');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Marker := 'new';
        RaiseFromProc('new');
    end;

    trigger OnAfterGetRecord()
    begin
        Marker := 'get' + Format(Rec.Id);
        RaiseFromProc('get');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        RaiseFromProc('query');
        exit(true);
    end;

    trigger OnClosePage()
    begin
        RaiseFromProc('close');
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

codeunit 73051 "LT P84 PgSnd Log"
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

codeunit 73052 "LT P84 PgSnd Sub"
{
    EventSubscriberInstance = Manual;

    var
        SenderLog: Codeunit "LT P84 PgSnd Log";
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

    [EventSubscriber(ObjectType::Page, Page::"LT P84 Sender Card", 'OnPing', '', false, false)]
    local procedure HandlePing(Sender: Page "LT P84 Sender Card"; Where: Text)
    begin
        SenderLog.Add(Where + '|marker=' + Sender.GetMarker() + '|hits=' + Format(Sender.GetHits()));
        if ChangeMarker then
            Sender.SetMarker('sub-' + Where);
        if Nest and (Where = 'nest') then
            Sender.RaiseFromProc('inner');
    end;
}

codeunit 73053 "LT P84 PgSnd Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SenderLog: Codeunit "LT P84 PgSnd Log";

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
    procedure Proc_SenderIsPageInstance()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT P84 PgSnd Sub";
        Pg: Page "LT P84 Sender Card";
    begin
        SenderLog.Take();
        Sub.SetChangeMarker(true);
        BindSubscription(Sub);
        Pg.SetMarker('m1');
        Pg.RaiseFromProc('p');
        Observer.Observe('log', SenderLog.Take());
        Observer.Observe('marker_after', Pg.GetMarker());
        Observer.Observe('hits_after', Format(Pg.GetHits()));
        Observer.Observe('seen', Pg.GetSeen());
        Pg.RaiseFromProc('p2');
        Observer.Observe('log2', SenderLog.Take());
        Observer.Observe('seen2', Pg.GetSeen());
        UnbindSubscription(Sub);
        Observer.Finish();
    end;

    [Test]
    procedure Proc_TwoInstances()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT P84 PgSnd Sub";
        Pg1: Page "LT P84 Sender Card";
        Pg2: Page "LT P84 Sender Card";
    begin
        SenderLog.Take();
        Sub.SetChangeMarker(true);
        BindSubscription(Sub);
        Pg1.SetMarker('first');
        Pg2.SetMarker('second');
        Pg2.RaiseFromProc('x');
        Observer.Observe('log_second', SenderLog.Take());
        Observer.Observe('marker1', Pg1.GetMarker());
        Observer.Observe('marker2', Pg2.GetMarker());
        Observer.Observe('hits1', Format(Pg1.GetHits()));
        Observer.Observe('hits2', Format(Pg2.GetHits()));
        UnbindSubscription(Sub);
        Observer.Finish();
    end;

    [Test]
    procedure Proc_NestedRaiseFromSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT P84 PgSnd Sub";
        Pg: Page "LT P84 Sender Card";
    begin
        SenderLog.Take();
        Sub.SetNest(true);
        BindSubscription(Sub);
        Pg.SetMarker('m');
        Pg.RaiseFromProc('nest');
        Observer.Observe('log', SenderLog.Take());
        Observer.Observe('hits', Format(Pg.GetHits()));
        Observer.Observe('seen', Pg.GetSeen());
        UnbindSubscription(Sub);
        Observer.Finish();
    end;

    [Test]
    procedure Proc_NotBound()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT P84 Sender Card";
    begin
        SenderLog.Take();
        Pg.RaiseFromProc('p');
        Observer.Observe('log', SenderLog.Take());
        Observer.Observe('hits', Format(Pg.GetHits()));
        Observer.Finish();
    end;

    [Test]
    procedure TestPage_OpenNew_Triggers()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT P84 PgSnd Sub";
        Page: TestPage "LT P84 Sender Card";
    begin
        Seed();
        SenderLog.Take();
        Sub.SetChangeMarker(true);
        BindSubscription(Sub);
        Page.OpenNew();
        Observer.Observe('log_open', SenderLog.Take());
        Page.Close();
        Observer.Observe('log_close', SenderLog.Take());
        UnbindSubscription(Sub);
        Observer.Finish();
    end;

    [Test]
    procedure TestPage_OpenView_Triggers()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT P84 PgSnd Sub";
        Page: TestPage "LT P84 Sender Card";
    begin
        Seed();
        SenderLog.Take();
        BindSubscription(Sub);
        Page.OpenView();
        Observer.Observe('log_open', SenderLog.Take());
        Page.Next();
        Observer.Observe('log_next', SenderLog.Take());
        Page.Close();
        Observer.Observe('log_close', SenderLog.Take());
        UnbindSubscription(Sub);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('SenderCardHandler')]
    procedure RunModal_Triggers()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT P84 PgSnd Sub";
        Row: Record "LT P84 Row";
    begin
        Seed();
        Row.FindFirst();
        SenderLog.Take();
        BindSubscription(Sub);
        Page.RunModal(Page::"LT P84 Sender Card", Row);
        Observer.Observe('log', SenderLog.Take());
        UnbindSubscription(Sub);
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure SenderCardHandler(var Card: TestPage "LT P84 Sender Card")
    begin
    end;
}
