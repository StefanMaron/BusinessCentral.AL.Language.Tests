// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotokey-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT AI Row / LT AI Log Mgt (AiFixtures.al); own pages 86700 - 86702
// Probe: writer QG (runtime PR 380, lane-old-fails). AiListOrderTests.al:208 shows that an action right after a GoToKey on a list with
//        OnAfterGetRecord but no OnAfterGetCurrRecord reads the row twice before its trigger. Here: which next call after such a GoToKey
//        reads the row again: a field Value read, SetValue, Close, Previous, a RunObject action, an action without CurrPage.Update, an action
//        after a field read or SetValue, and OK in a lookup handler. Each test runs on a page with only OnAfterGetRecord (Plain) and on one
//        that also has OnFindRecord and OnNextRecord (Nav).
// Log format as AiFixtures.al: F:<Which>=<found> = OnFindRecord, N:<Steps>=<moved> = OnNextRecord, R:<no> = OnAfterGetRecord, A:<name> = an action
//        step, T:open = the RunObject target opened, H:<step> = a step of the lookup handler.
// BC versions: 27.0+

page 86700 "LT QG GoToKey Plain"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AI Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Act)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:act=' + Rec."No.");
                end;
            }
            action(UpdAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:update');
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
            action(OpenTarget)
            {
                ApplicationArea = All;
                RunObject = page "LT QG GoToKey Target";
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT AI Log Mgt";
    begin
        Log.Add('R:' + Rec."No.");
    end;
}

page 86701 "LT QG GoToKey Nav"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AI Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Act)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:act=' + Rec."No.");
                end;
            }
            action(UpdAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:update');
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
            action(OpenTarget)
            {
                ApplicationArea = All;
                RunObject = page "LT QG GoToKey Target";
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT AI Log Mgt";
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        Log.Add('F:' + Which + '=' + Format(Found));
        exit(Found);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "LT AI Log Mgt";
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        Log.Add('N:' + Format(Steps) + '=' + Format(Moved));
        exit(Moved);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT AI Log Mgt";
    begin
        Log.Add('R:' + Rec."No.");
    end;
}

page 86702 "LT QG GoToKey Target"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT AI Log Mgt";
    begin
        Log.Add('T:open');
    end;
}

codeunit 86703 "LT QG GoToKey Next Call"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT AI Log Mgt";

    local procedure Start()
    begin
        Log.Seed(6);
        Log.Clear();
    end;

    [PageHandler]
    procedure TargetHandler(var Target: TestPage "LT QG GoToKey Target")
    begin
        Log.Add('H:target');
        Target.Close();
    end;

    [ModalPageHandler]
    procedure PlainLookupHandler(var P: TestPage "LT QG GoToKey Plain")
    begin
        Log.Add('H:opened');
        P.GoToKey('R1003');
        Log.Add('H:goto');
        P.OK().Invoke();
        Log.Add('H:ok');
    end;

    [ModalPageHandler]
    procedure NavLookupHandler(var P: TestPage "LT QG GoToKey Nav")
    begin
        Log.Add('H:opened');
        P.GoToKey('R1003');
        Log.Add('H:goto');
        P.OK().Invoke();
        Log.Add('H:ok');
    end;

    [ModalPageHandler]
    procedure PlainLookupValueHandler(var P: TestPage "LT QG GoToKey Plain")
    begin
        Log.Add('H:opened');
        P.GoToKey('R1003');
        Log.Add('H:goto');
        Log.Add('H:value=' + P.NoCtl.Value());
        P.OK().Invoke();
        Log.Add('H:ok');
    end;

    // ---- Plain: OnAfterGetRecord only ----

    [Test]
    procedure Plain_GoToKey_ThenValueRead()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QG GoToKey Plain";
    begin
        Start();
        P.OpenView();
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1003')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        Observer.Observe('no', P.NoCtl.Value());
        Observer.Observe('no_log', Log.Dump());
        Log.Clear();
        Observer.Observe('qty', P.QtyCtl.Value());
        Observer.Observe('qty_log', Log.Dump());
        Log.Clear();
        P.Close();
        Observer.Observe('close_log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure Plain_GoToKey_ThenSetValue_ThenAction()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QG GoToKey Plain";
    begin
        Start();
        P.OpenEdit();
        P.GoToKey('R1003');
        Log.Clear();
        P.QtyCtl.SetValue(33);
        Observer.Observe('setvalue_log', Log.Dump());
        Log.Clear();
        P.Act.Invoke();
        Observer.Observe('action_log', Log.Dump());
        Log.Clear();
        P.Close();
        Observer.Observe('close_log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure Plain_GoToKey_ThenClose()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QG GoToKey Plain";
    begin
        Start();
        P.OpenView();
        P.GoToKey('R1003');
        Log.Clear();
        P.Close();
        Observer.Observe('close_log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure Plain_GoToKey_ThenPrevious()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QG GoToKey Plain";
    begin
        Start();
        P.OpenView();
        P.GoToKey('R1003');
        Log.Clear();
        Observer.Observe('previous', Format(P.Previous()));
        Observer.Observe('previous_log', Log.Dump());
        Log.Clear();
        Observer.Observe('no', P.NoCtl.Value());
        Observer.Observe('no_log', Log.Dump());
        Log.Clear();
        P.Act.Invoke();
        Observer.Observe('action_log', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('TargetHandler')]
    procedure Plain_GoToKey_ThenRunObjectAction()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QG GoToKey Plain";
    begin
        Start();
        P.OpenView();
        P.GoToKey('R1003');
        Log.Clear();
        P.OpenTarget.Invoke();
        Observer.Observe('runobject_log', Log.Dump());
        Log.Clear();
        P.Act.Invoke();
        Observer.Observe('action_log', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Plain_GoToKey_ThenActionWithoutUpdate_Twice()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QG GoToKey Plain";
    begin
        Start();
        P.OpenView();
        P.GoToKey('R1003');
        Log.Clear();
        P.Act.Invoke();
        Observer.Observe('action_log', Log.Dump());
        Log.Clear();
        P.Act.Invoke();
        Observer.Observe('second_action_log', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Plain_GoToKey_ThenValueRead_ThenAction()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QG GoToKey Plain";
    begin
        Start();
        P.OpenView();
        P.GoToKey('R1003');
        Log.Clear();
        Observer.Observe('no', P.NoCtl.Value());
        Log.Clear();
        P.Act.Invoke();
        Observer.Observe('action_log', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Plain_GoToKey_ThenValueRead_ThenUpdateAction()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QG GoToKey Plain";
    begin
        Start();
        P.OpenView();
        P.GoToKey('R1003');
        Observer.Observe('no', P.NoCtl.Value());
        Log.Clear();
        P.UpdAct.Invoke();
        Observer.Observe('action_log', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PlainLookupHandler')]
    procedure Plain_LookupHandler_GoToKey_ThenOK()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AI Row";
        P: Page "LT QG GoToKey Plain";
    begin
        Start();
        P.LookupMode(true);
        Observer.Observe('action', Format(P.RunModal()));
        Observer.Observe('log', Log.Dump());
        P.GetRecord(Row);
        Observer.Observe('selected', Row."No.");
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PlainLookupValueHandler')]
    procedure Plain_LookupHandler_GoToKey_ValueRead_ThenOK()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AI Row";
        P: Page "LT QG GoToKey Plain";
    begin
        Start();
        P.LookupMode(true);
        Observer.Observe('action', Format(P.RunModal()));
        Observer.Observe('log', Log.Dump());
        P.GetRecord(Row);
        Observer.Observe('selected', Row."No.");
        Observer.Finish();
    end;

    // ---- Nav: OnFindRecord, OnNextRecord and OnAfterGetRecord ----

    [Test]
    procedure Nav_GoToKey_ThenValueRead()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QG GoToKey Nav";
    begin
        Start();
        P.OpenView();
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1003')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        Observer.Observe('no', P.NoCtl.Value());
        Observer.Observe('no_log', Log.Dump());
        Log.Clear();
        Observer.Observe('qty', P.QtyCtl.Value());
        Observer.Observe('qty_log', Log.Dump());
        Log.Clear();
        P.Close();
        Observer.Observe('close_log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure Nav_GoToKey_ThenSetValue_ThenAction()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QG GoToKey Nav";
    begin
        Start();
        P.OpenEdit();
        P.GoToKey('R1003');
        Log.Clear();
        P.QtyCtl.SetValue(33);
        Observer.Observe('setvalue_log', Log.Dump());
        Log.Clear();
        P.Act.Invoke();
        Observer.Observe('action_log', Log.Dump());
        Log.Clear();
        P.Close();
        Observer.Observe('close_log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure Nav_GoToKey_ThenClose()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QG GoToKey Nav";
    begin
        Start();
        P.OpenView();
        P.GoToKey('R1003');
        Log.Clear();
        P.Close();
        Observer.Observe('close_log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure Nav_GoToKey_ThenPrevious()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QG GoToKey Nav";
    begin
        Start();
        P.OpenView();
        P.GoToKey('R1003');
        Log.Clear();
        Observer.Observe('previous', Format(P.Previous()));
        Observer.Observe('previous_log', Log.Dump());
        Log.Clear();
        Observer.Observe('no', P.NoCtl.Value());
        Observer.Observe('no_log', Log.Dump());
        Log.Clear();
        P.Act.Invoke();
        Observer.Observe('action_log', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('TargetHandler')]
    procedure Nav_GoToKey_ThenRunObjectAction()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QG GoToKey Nav";
    begin
        Start();
        P.OpenView();
        P.GoToKey('R1003');
        Log.Clear();
        P.OpenTarget.Invoke();
        Observer.Observe('runobject_log', Log.Dump());
        Log.Clear();
        P.Act.Invoke();
        Observer.Observe('action_log', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Nav_GoToKey_ThenActionWithoutUpdate_Twice()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QG GoToKey Nav";
    begin
        Start();
        P.OpenView();
        P.GoToKey('R1003');
        Log.Clear();
        P.Act.Invoke();
        Observer.Observe('action_log', Log.Dump());
        Log.Clear();
        P.Act.Invoke();
        Observer.Observe('second_action_log', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Nav_GoToKey_ThenValueRead_ThenAction()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QG GoToKey Nav";
    begin
        Start();
        P.OpenView();
        P.GoToKey('R1003');
        Log.Clear();
        Observer.Observe('no', P.NoCtl.Value());
        Log.Clear();
        P.Act.Invoke();
        Observer.Observe('action_log', Log.Dump());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Nav_GoToKey_ThenValueRead_ThenUpdateAction()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QG GoToKey Nav";
    begin
        Start();
        P.OpenView();
        P.GoToKey('R1003');
        Observer.Observe('no', P.NoCtl.Value());
        Log.Clear();
        P.UpdAct.Invoke();
        Observer.Observe('action_log', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('NavLookupHandler')]
    procedure Nav_LookupHandler_GoToKey_ThenOK()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AI Row";
        P: Page "LT QG GoToKey Nav";
    begin
        Start();
        P.LookupMode(true);
        Observer.Observe('action', Format(P.RunModal()));
        Observer.Observe('log', Log.Dump());
        P.GetRecord(Row);
        Observer.Observe('selected', Row."No.");
        Observer.Finish();
    end;
}
