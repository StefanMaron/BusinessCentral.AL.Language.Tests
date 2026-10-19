// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT CB Row / Empty / Log / Card / List / Navigate / Role Center (CbFixtures.al)
// Probe: corpus issue #667 items 25 to 32 (page triggers): a page-global Boolean handed to Rec in OnAfterGetCurrRecord as the table's
//        OnValidate sees it (the repro of microsoft/AL#7345); Find on an empty table in OnNewRecord under OpenNew; which triggers run around
//        an action Invoke on a NavigatePage, a Card and a List; a TestPage on a Role Center; AssistEdit in view mode; an error raised in
//        a table field OnLookup.
// BC versions: 27 to 29 (CI matrix)

codeunit 84169 "LT CB Page Trigger Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT CB Log";

    local procedure Seed()
    var
        Row: Record "LT CB Row";
        Empty: Record "LT CB Empty";
    begin
        Row.DeleteAll();
        Empty.DeleteAll();
        Row.Init();
        Row."No." := 'R1';
        Row.Name := 'One';
        Row.Insert();
        Row.Init();
        Row."No." := 'R2';
        Row.Name := 'Two';
        Row.Insert();
        Log.SetNewRecordMode(0);
        Log.Take();
    end;

    // ---------- item 25: page global handed to Rec in OnAfterGetCurrRecord, read in the table's OnValidate ----------

    [Test]
    procedure ListPage_FlagFromOnAfterGetCurrRecord_InTableOnValidate()
    var
        Observer: Codeunit "Probe Observer";
        ListPage: Page "LT CB List";
        List: TestPage "LT CB List";
    begin
        Seed();
        List.Trap();
        ListPage.SetPageFlagOnPage(true);
        ListPage.Run();
        List.First();
        Log.Take();
        List.ShowFlag.Invoke();
        Observer.Observe('action_existing', Log.Take());
        List.NameCtl.SetValue('Changed');
        Observer.Observe('validate_existing', Log.Take());
        List.New();
        List.NoCtl.SetValue('R3');
        Log.Take();
        List.NameCtl.SetValue('Three');
        Observer.Observe('validate_new', Log.Take());
        List.Close();
        Observer.Finish();
    end;

    // ---------- item 27: Find on an empty table in OnNewRecord, page opened with OpenNew ----------

    [TryFunction]
    local procedure TryOpenNew(var Card: TestPage "LT CB Card")
    begin
        Card.OpenNew();
    end;

    local procedure OpenNewWithMode(Mode: Integer; Name: Text; var Observer: Codeunit "Probe Observer")
    var
        Card: TestPage "LT CB Card";
    begin
        Seed();
        Log.SetNewRecordMode(Mode);
        ClearLastError();
        Observer.Observe(Name + '_ok', Format(TryOpenNew(Card)));
        Observer.ObserveError(Name);
        Observer.Observe(Name + '_log', Log.Take());
        Log.SetNewRecordMode(0);
    end;

    [Test]
    procedure OpenNew_OnNewRecordFindsInEmptyTable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OpenNewWithMode(1, 'findfirst', Observer);
        OpenNewWithMode(2, 'find', Observer);
        OpenNewWithMode(3, 'recfind', Observer);
        OpenNewWithMode(4, 'iffind', Observer);
        Observer.Finish();
    end;

    // ---------- item 28: triggers around an action Invoke on a NavigatePage, a Card and a List ----------

    [Test]
    procedure NavigatePage_ActionInvoke_TriggerOrder()
    var
        Observer: Codeunit "Probe Observer";
        Nav: TestPage "LT CB Navigate";
    begin
        Seed();
        Nav.OpenView();
        Observer.Observe('open', Log.Take());
        Nav.Act.Invoke();
        Observer.Observe('invoke1', Log.Take());
        Nav.Act.Invoke();
        Observer.Observe('invoke2', Log.Take());
        Nav.Close();
        Observer.Finish();
    end;

    [Test]
    procedure CardPage_ActionInvoke_TriggerOrder()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT CB Card";
    begin
        Seed();
        Card.OpenView();
        Observer.Observe('open', Log.Take());
        Card.Act.Invoke();
        Observer.Observe('invoke1', Log.Take());
        Card.Act.Invoke();
        Observer.Observe('invoke2', Log.Take());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure ListPage_ActionInvoke_TriggerOrder()
    var
        Observer: Codeunit "Probe Observer";
        ListPage: Page "LT CB List";
        List: TestPage "LT CB List";
    begin
        Seed();
        List.Trap();
        ListPage.SetLogTriggers(true);
        ListPage.Run();
        Observer.Observe('open', Log.Take());
        List.Act.Invoke();
        Observer.Observe('invoke1', Log.Take());
        List.Next();
        Observer.Observe('next', Log.Take());
        List.Act.Invoke();
        Observer.Observe('invoke2', Log.Take());
        List.Close();
        Observer.Finish();
    end;

    // ---------- item 29: a TestPage on a Role Center; AssistEdit in view mode ----------

    [TryFunction]
    local procedure TryOpenRoleCenter(var Rc: TestPage "LT CB Role Center")
    begin
        Rc.OpenView();
    end;

    [TryFunction]
    local procedure TryInvokeRoleCenterAction(var Rc: TestPage "LT CB Role Center")
    begin
        Rc.RcAct.Invoke();
    end;

    [PageHandler]
    procedure CardPageHandler(var Pg: TestPage "LT CB Card")
    begin
        Log.Add('card handler');
    end;

    [Test]
    [HandlerFunctions('CardPageHandler')]
    procedure RoleCenter_TestPage_OpenAndInvoke()
    var
        Observer: Codeunit "Probe Observer";
        Rc: TestPage "LT CB Role Center";
    begin
        Log.Take();
        ClearLastError();
        Observer.Observe('open_ok', Format(TryOpenRoleCenter(Rc)));
        Observer.ObserveError('open');
        Observer.Observe('invoke_ok', Format(TryInvokeRoleCenterAction(Rc)));
        Observer.ObserveError('invoke');
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryAssistEdit(var Card: TestPage "LT CB Card")
    begin
        Card.AssistCtl.AssistEdit();
    end;

    [Test]
    procedure AssistEdit_InViewMode()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT CB Card";
    begin
        Seed();
        Card.OpenView();
        Card.GoToKey('R1');
        Log.Take();
        ClearLastError();
        Observer.Observe('view_ok', Format(TryAssistEdit(Card)));
        Observer.ObserveError('view');
        Observer.Observe('view_log', Log.Take());
        Card.Close();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Log.Take();
        Observer.Observe('edit_ok', Format(TryAssistEdit(Card)));
        Observer.ObserveError('edit');
        Observer.Observe('edit_log', Log.Take());
        Card.Close();
        Observer.Finish();
    end;

    // ---------- item 32: an error raised in a table field OnLookup, reached through TestPage Lookup() ----------

    [TryFunction]
    local procedure TryLookupErr(var Card: TestPage "LT CB Card")
    begin
        Card.LookupErrCtl.Lookup();
    end;

    [Test]
    procedure TableOnLookup_RaisesError_ThroughTestPage()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT CB Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.LookupErrCtl.SetValue('KEEP');
        Log.Take();
        ClearLastError();
        Observer.Observe('ok', Format(TryLookupErr(Card)));
        Observer.ObserveError('lookup');
        Observer.Observe('log', Log.Take());
        Observer.Observe('value_after', Card.LookupErrCtl.Value());
        Card.Close();
        Observer.Finish();
    end;
}
