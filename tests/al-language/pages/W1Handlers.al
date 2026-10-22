// Probes: md:89 (UI call inside a handler, UI call outside a test method), md:90 (two handlers of one kind in one list),
// md:102 (ordinals of the Action members), md:104 / md:105 / md:106 (closing a handled page, SaveValues, torn-down modal page).
// md:88 is in W1HandlerNotRun.al.

codeunit 69241 "W1 Hnd Log"
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

    procedure Count(Prefix: Text): Integer
    var
        Parts: List of [Text];
        Part: Text;
        Hits: Integer;
    begin
        Parts := Entries.Split(';');
        foreach Part in Parts do
            if Part.StartsWith(Prefix) then
                Hits += 1;
        exit(Hits);
    end;
}

codeunit 69280 "W1 Msg Runner"
{
    trigger OnRun()
    var
        Log: Codeunit "W1 Hnd Log";
    begin
        Log.Add('runner:before');
        Message('from runner');
        Log.Add('runner:after');
    end;
}

codeunit 69281 "W1 Confirm Runner"
{
    trigger OnRun()
    var
        Log: Codeunit "W1 Hnd Log";
    begin
        Log.Add('runner:before');
        if Confirm('runner question?') then
            Log.Add('runner:answer yes')
        else
            Log.Add('runner:answer no');
    end;
}

page 69257 "W1 Save Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SaveValues = true;

    layout
    {
        area(Content)
        {
            field(Counter; Counter) { }
            field(Note; Note) { }
        }
    }

    var
        Counter: Integer;
        Note: Text[30];
        Log: Codeunit "W1 Hnd Log";

    trigger OnInit()
    begin
        Log.Add('OnInit counter=' + Format(Counter));
    end;

    trigger OnOpenPage()
    begin
        Log.Add('OnOpenPage counter=' + Format(Counter));
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('OnQueryClosePage(' + Format(CloseAction) + ') counter=' + Format(Counter));
        exit(true);
    end;

    trigger OnClosePage()
    begin
        Log.Add('OnClosePage counter=' + Format(Counter));
    end;
}

page 69258 "W1 Save Init Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SaveValues = true;

    layout
    {
        area(Content)
        {
            field(Counter; Counter) { }
        }
    }

    var
        Counter: Integer;
        Log: Codeunit "W1 Hnd Log";

    trigger OnInit()
    begin
        Counter := 99;
        Log.Add('OnInit assigned 99');
    end;

    trigger OnOpenPage()
    begin
        Log.Add('OnOpenPage counter=' + Format(Counter));
    end;
}

page 69259 "W1 Modal Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(Name; Rec.Name) { }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Rec.Name = 'boom' then
            Error('W1 boom');
    end;
}

codeunit 69261 "W1 Handler Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "W1 Hnd Log";

    local procedure SeedRows()
    var
        Row: Record "W1 Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Name := 'ok';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'boom';
        Row.Insert();
    end;

    // ---------- md:89: UI calls from inside a handler, and from code that is not a test method ----------

    [MessageHandler]
    procedure NestedMessageHandler(Msg: Text[1024])
    begin
        Log.Add('handler:' + Msg);
        if Log.Count('handler:') = 1 then
            Message('inner message');
    end;

    [Test]
    [HandlerFunctions('NestedMessageHandler')]
    procedure Handler_RaisesMessage_InsideMessageHandler()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Log.Take();
        Ok := Codeunit.Run(Codeunit::"W1 Msg Runner");
        Observer.Observe('run_ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('run');
        Observer.Observe('log', Log.Take());
        Observer.Expect('run_ok', 'Yes');
        Observer.Expect('log', 'runner:before;handler:from runner;handler:inner message;runner:after;');
        Observer.Verify();
    end;

    [MessageHandler]
    procedure MessageThenConfirmHandler(Msg: Text[1024])
    begin
        Log.Add('msghandler:' + Msg);
        if Confirm('question from handler?') then
            Log.Add('msghandler:confirm yes')
        else
            Log.Add('msghandler:confirm no');
    end;

    [ConfirmHandler]
    procedure AnswerYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Log.Add('confirmhandler:' + Question);
        Reply := true;
    end;

    [Test]
    [HandlerFunctions('MessageThenConfirmHandler,AnswerYesHandler')]
    procedure Handler_RaisesConfirm_InsideMessageHandler()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Log.Take();
        Ok := Codeunit.Run(Codeunit::"W1 Msg Runner");
        Observer.Observe('run_ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('run');
        Observer.Observe('log', Log.Take());
        Observer.Expect('run_ok', 'Yes');
        Observer.Expect('log', 'runner:before;msghandler:from runner;confirmhandler:question from handler?;msghandler:confirm yes;runner:after;');
        Observer.Verify();
    end;

    [MessageHandler]
    procedure PlainMessageHandler(Msg: Text[1024])
    begin
        Log.Add('msghandler:' + Msg);
    end;

    [Test]
    [HandlerFunctions('PlainMessageHandler')]
    procedure UiCall_InCodeunitOnRun_MessageIsHandled()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Log.Take();
        Ok := Codeunit.Run(Codeunit::"W1 Msg Runner");
        Observer.Observe('run_ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('run');
        Observer.Observe('log', Log.Take());
        Observer.Expect('run_ok', 'Yes');
        Observer.Expect('log', 'runner:before;msghandler:from runner;runner:after;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('AnswerYesHandler')]
    procedure UiCall_InCodeunitOnRun_ConfirmIsHandled()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Log.Take();
        Ok := Codeunit.Run(Codeunit::"W1 Confirm Runner");
        Observer.Observe('run_ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('run');
        Observer.Observe('log', Log.Take());
        Observer.Expect('run_ok', 'Yes');
        Observer.Expect('log', 'runner:before;confirmhandler:runner question?;runner:answer yes;');
        Observer.Verify();
    end;

    // ---------- md:90: two handler functions of one kind in one list ----------

    [MessageHandler]
    procedure FirstOfTwoHandler(Msg: Text[1024])
    begin
        Log.Add('first:' + Msg);
    end;

    [MessageHandler]
    procedure SecondOfTwoHandler(Msg: Text[1024])
    begin
        Log.Add('second:' + Msg);
    end;

    // ---------- md:102: ordinals of the Action members ----------

    [Test]
    procedure ActionMembers_Ordinals()
    var
        Observer: Codeunit "Probe Observer";
        A: Action;
        i: Integer;
        Parsed: Text;
    begin
        A := Action::None;
        Observer.Observe('None', Format(A, 0, 2));
        A := Action::OK;
        Observer.Observe('OK', Format(A, 0, 2));
        A := Action::Cancel;
        Observer.Observe('Cancel', Format(A, 0, 2));
        A := Action::LookupOK;
        Observer.Observe('LookupOK', Format(A, 0, 2));
        A := Action::LookupCancel;
        Observer.Observe('LookupCancel', Format(A, 0, 2));
        A := Action::Yes;
        Observer.Observe('Yes', Format(A, 0, 2));
        A := Action::No;
        Observer.Observe('No', Format(A, 0, 2));
        A := Action::RunObject;
        Observer.Observe('RunObject', Format(A, 0, 2));
        A := Action::RunSystem;
        Observer.Observe('RunSystem', Format(A, 0, 2));
        for i := 0 to 12 do
            if Evaluate(A, Format(i)) then
                Parsed += Format(i) + '=' + Format(A) + ','
            else
                Parsed += Format(i) + '=none,';
        Observer.Observe('evaluate_by_ordinal', Parsed);
        Observer.Expect('None', 'None');
        Observer.Expect('OK', 'OK');
        Observer.Expect('Cancel', 'Cancel');
        Observer.Expect('LookupOK', 'LookupOK');
        Observer.Expect('LookupCancel', 'LookupCancel');
        Observer.Expect('Yes', 'Yes');
        Observer.Expect('No', 'No');
        Observer.Expect('RunObject', 'RunObject');
        Observer.Expect('RunSystem', 'RunSystem');
        Observer.Expect('evaluate_by_ordinal', '0=None,1=OK,2=Cancel,3=LookupOK,4=LookupCancel,5=Yes,6=No,7=CloseOK,8=FormHelp,9=RunObject,10=RunSystem,11=Print,12=Preview,');
        Observer.Verify();
    end;

    // ---------- md:104: a non-modal page handled by a [PageHandler] is closed when the handler returns ----------

    [PageHandler]
    procedure NonModalSaveHandler(var Pg: TestPage "W1 Save Card")
    begin
        Log.Add('handler:counter=' + Pg.Counter.Value());
        Pg.Counter.SetValue(42);
        Log.Add('handler:returns');
    end;

    [Test]
    [HandlerFunctions('NonModalSaveHandler')]
    procedure NonModalPageHandler_ClosesThePageWhenItReturns()
    var
        Pg: TestPage "W1 Save Card";
        Observer: Codeunit "Probe Observer";
    begin
        Pg.OpenEdit();
        Pg.Counter.SetValue(0);
        Pg.Close();
        Log.Take();
        Page.Run(Page::"W1 Save Card");
        Observer.Observe('first_run', Log.Take());
        Page.Run(Page::"W1 Save Card");
        Observer.Observe('second_run', Log.Take());
        Observer.Expect('first_run', 'OnInit counter=0;OnOpenPage counter=0;handler:counter=0;handler:returns;OnQueryClosePage(OK) counter=42;OnClosePage counter=42;');
        Observer.Expect('second_run', 'OnInit counter=0;OnOpenPage counter=42;handler:counter=42;handler:returns;OnQueryClosePage(OK) counter=42;OnClosePage counter=42;');
        Observer.Verify();
    end;

    // ---------- md:105: SaveValues restores after OnInit and before OnOpenPage; Close() stores ----------

    [Test]
    procedure SaveValues_Card_CloseStores_RestoreBeforeOnOpenPage()
    var
        Pg: TestPage "W1 Save Card";
        Observer: Codeunit "Probe Observer";
    begin
        Pg.OpenEdit();
        Pg.Counter.SetValue(0);
        Pg.Close();
        Log.Take();
        Pg.OpenEdit();
        Observer.Observe('open_log_clean', Log.Take());
        Pg.Counter.SetValue(5);
        Pg.Note.SetValue('kept');
        Observer.Observe('log_after_set', Log.Take());
        Pg.Close();
        Observer.Observe('close_log', Log.Take());
        Pg.OpenEdit();
        Observer.Observe('reopen_log', Log.Take());
        Observer.Observe('reopen_counter', Pg.Counter.Value());
        Observer.Observe('reopen_note', Pg.Note.Value());
        Pg.Close();
        Log.Take();
        Observer.Expect('open_log_clean', 'OnInit counter=0;OnOpenPage counter=0;');
        Observer.Expect('log_after_set', '');
        Observer.Expect('close_log', 'OnQueryClosePage(OK) counter=5;OnClosePage counter=5;');
        Observer.Expect('reopen_log', 'OnInit counter=0;OnOpenPage counter=5;');
        Observer.Expect('reopen_counter', '5');
        Observer.Expect('reopen_note', 'kept');
        Observer.Verify();
    end;

    [Test]
    procedure SaveValues_Card_OnInitAssigns_StoredValueWins()
    var
        Pg: TestPage "W1 Save Init Card";
        Observer: Codeunit "Probe Observer";
    begin
        Pg.OpenEdit();
        Pg.Counter.SetValue(0);
        Pg.Close();
        Log.Take();
        Pg.OpenEdit();
        Observer.Observe('open_log_after_zero_stored', Log.Take());
        Observer.Observe('counter_after_zero_stored', Pg.Counter.Value());
        Pg.Counter.SetValue(5);
        Pg.Close();
        Log.Take();
        Pg.OpenEdit();
        Observer.Observe('reopen_log', Log.Take());
        Observer.Observe('reopen_counter', Pg.Counter.Value());
        Pg.Close();
        Observer.Expect('open_log_after_zero_stored', 'OnInit assigned 99;OnOpenPage counter=0;');
        Observer.Expect('counter_after_zero_stored', '0');
        Observer.Expect('reopen_log', 'OnInit assigned 99;OnOpenPage counter=5;');
        Observer.Expect('reopen_counter', '5');
        Observer.Verify();
    end;

    // ---------- md:106: a handler that tears its page down: what RunModal reports ----------

    [ModalPageHandler]
    procedure ReturnsAtOnceHandler(var Pg: TestPage "W1 Modal Card")
    begin
        Log.Add('handler:returns');
    end;

    [ModalPageHandler]
    procedure TearDownHandler(var Pg: TestPage "W1 Modal Card")
    begin
        asserterror Pg.GoToKey(2);
        Log.Add('handler:torn down');
    end;

    [ModalPageHandler]
    procedure TearDownThenOkHandler(var Pg: TestPage "W1 Modal Card")
    begin
        asserterror Pg.GoToKey(2);
        asserterror Pg.OK().Invoke();
        Log.Add('handler:' + GetLastErrorText());
        ClearLastError();
    end;

    [ModalPageHandler]
    procedure OkHandler(var Pg: TestPage "W1 Modal Card")
    begin
        Pg.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ReturnsAtOnceHandler')]
    procedure RunModal_HandlerReturnsWithoutClosing()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W1 Row";
        Result: Action;
    begin
        SeedRows();
        Log.Take();
        Result := Page.RunModal(Page::"W1 Modal Card");
        Observer.Observe('no_record', Format(Result));
        Row.Get(1);
        Result := Page.RunModal(Page::"W1 Modal Card", Row);
        Observer.Observe('with_record', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Expect('no_record', 'LookupCancel');
        Observer.Expect('with_record', 'LookupCancel');
        Observer.Expect('log', 'handler:returns;handler:returns;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TearDownHandler')]
    procedure RunModal_HandlerTearsThePageDown()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W1 Row";
        Result: Action;
    begin
        SeedRows();
        Log.Take();
        Result := Page.RunModal(Page::"W1 Modal Card");
        Observer.Observe('no_record', Format(Result));
        SeedRows();
        Row.Get(1);
        Result := Page.RunModal(Page::"W1 Modal Card", Row);
        Observer.Observe('with_record', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Expect('no_record', 'LookupCancel');
        Observer.Expect('with_record', 'LookupCancel');
        Observer.Expect('log', 'handler:torn down;handler:torn down;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TearDownThenOkHandler')]
    procedure RunModal_HandlerTearsDown_ThenOkIsRefused()
    var
        Observer: Codeunit "Probe Observer";
        Result: Action;
    begin
        SeedRows();
        Log.Take();
        Result := Page.RunModal(Page::"W1 Modal Card");
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Expect('result', 'LookupCancel');
        Observer.Expect('log', 'handler:The TestPage is not open.;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure RunModal_HandlerClosesWithOk_Contrast()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W1 Row";
        Result: Action;
    begin
        SeedRows();
        Result := Page.RunModal(Page::"W1 Modal Card");
        Observer.Observe('no_record', Format(Result));
        Row.Get(1);
        Result := Page.RunModal(Page::"W1 Modal Card", Row);
        Observer.Observe('with_record', Format(Result));
        Observer.Expect('no_record', 'LookupOK');
        Observer.Expect('with_record', 'LookupOK');
        Observer.Verify();
    end;
}
