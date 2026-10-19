// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-creating-handler-methods
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects 80620-80626 (AzHandlerObjects.al)
// Probe: corpus issue 652 (test handlers, dialogs and error texts), items 1 (MessageHandler calling StrMenu, ConfirmHandler calling Confirm or StrMenu), 2 (Confirm), 3, 5, 6 (no handler) and 9, writer AZ.
// Already pinned: the other parts of items 1 and 2 (pages/W1Handlers.al, errors/lt-ms-refusals-133/P133MessageInHandlers.al,
// handlers/TestUnhandledUiAndDialogDefaults.al), item 4 (report/W3ReportRequestPageRun.al), 6 with a handler (platform/lt-platform-members/PlTFilterPageBuilder.al).
// BC versions: 27, 28, 29

codeunit 80627 "LT AZ Handler Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AZ Hnd Log";
        Mode: Text;
        Depth: Integer;

    local procedure Reset(NewMode: Text)
    begin
        Mode := NewMode;
        Depth := 0;
        Log.Take();
        ClearLastError();
    end;

    local procedure Inner()
    begin
        if Depth > 0 then
            exit;
        Depth += 1;
        case Mode of
            'message':
                begin
                    Message('az inner message');
                    Log.Add('inner message returned');
                end;
            'confirm':
                Log.Add('inner confirm=' + Format(Confirm('az inner confirm')));
            'strmenu':
                Log.Add('inner strmenu=' + Format(StrMenu('A,B,C', 1)));
        end;
    end;

    [TryFunction]
    local procedure TryMessage(Text: Text)
    begin
        Message(Text);
    end;

    [TryFunction]
    local procedure TryConfirm(Text: Text; var Answer: Boolean)
    begin
        Answer := Confirm(Text);
    end;

    local procedure ObserveMessage(Name: Text)
    begin
        Observer.Observe(Name + '_ok', Format(TryMessage('az outer message')));
        Observer.Observe(Name + '_log', Log.Take());
        Observer.ObserveError(Name);
    end;

    local procedure ObserveConfirm(Name: Text)
    var
        Answer: Boolean;
    begin
        Observer.Observe(Name + '_ok', Format(TryConfirm('az outer confirm', Answer)));
        Observer.Observe(Name + '_answer', Format(Answer));
        Observer.Observe(Name + '_log', Log.Take());
        Observer.ObserveError(Name);
    end;

    [MessageHandler]
    procedure AzMsgReenter(Msg: Text)
    begin
        Log.Add('msgh(' + Msg + ')');
        Inner();
    end;

    [ConfirmHandler]
    procedure AzConfirmReenter(Question: Text; var Reply: Boolean)
    begin
        Log.Add('confh(' + Question + ')');
        Reply := true;
        Inner();
    end;

    [StrMenuHandler]
    procedure AzStrMenu2(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Log.Add('strmenuh(' + Options + ')');
        Choice := 2;
    end;

    // ---- item 1: a MessageHandler or ConfirmHandler that itself calls Message, Confirm or StrMenu ----

    [Test]
    [HandlerFunctions('AzMsgReenter,AzStrMenu2')]
    procedure MessageHandler_CallsStrMenu_WithHandler()
    begin
        Reset('strmenu');
        ObserveMessage('m');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('AzMsgReenter')]
    procedure MessageHandler_CallsStrMenu_NoHandler()
    begin
        Reset('strmenu');
        ObserveMessage('m');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('AzConfirmReenter')]
    procedure ConfirmHandler_CallsConfirm()
    begin
        Reset('confirm');
        ObserveConfirm('c');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('AzConfirmReenter,AzStrMenu2')]
    procedure ConfirmHandler_CallsStrMenu_WithHandler()
    begin
        Reset('strmenu');
        ObserveConfirm('c');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('AzConfirmReenter')]
    procedure ConfirmHandler_CallsStrMenu_NoHandler()
    begin
        Reset('strmenu');
        ObserveConfirm('c');
        Observer.Finish();
    end;

    // ---- item 2: Message and Confirm in the OnRun of a codeunit started with Codeunit.Run, no handler in the test ----

    [Test]
    procedure CodeunitRun_Confirm_NoHandler()
    var
        Cu: Codeunit "LT AZ Hnd Confirm OnRun";
    begin
        Reset('');
        Observer.Observe('run', Format(Cu.Run()));
        Observer.Observe('result', Cu.GetResult());
        Observer.ObserveError('run');
        Observer.Finish();
    end;

    // ---- item 3: two MessageHandlers in one HandlerFunctions list ----

    [MessageHandler]
    procedure AzMsgA(Msg: Text)
    begin
        Log.Add('A(' + Msg + ')');
    end;

    [MessageHandler]
    procedure AzMsgB(Msg: Text)
    begin
        Log.Add('B(' + Msg + ')');
    end;

    [Test]
    [HandlerFunctions('AzMsgA,AzMsgB')]
    procedure TwoMessageHandlers_WhichOneRuns()
    begin
        Reset('');
        Message('az one');
        Message('az two');
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('AzMsgA,AzMsgB')]
    procedure TwoMessageHandlers_TestEndsNormally()
    begin
        Reset('');
        Message('az one');
    end;

    // ---- items 4 and 5: a RequestPageHandler that neither OKs nor cancels, and one that inserts a row before OK ----

    [RequestPageHandler]
    procedure AzReqInsertThenOk(var RP: TestRequestPage "LT AZ Hnd Report")
    var
        Row: Record "LT AZ Hnd Row";
    begin
        Log.Add('reqh');
        Row.Id := 99;
        Row.Name := 'from handler';
        Row.Insert();
        Log.Add('inserted');
        RP.Tag.SetValue('t5');
        RP.OK().Invoke();
    end;

    local procedure SeedRows()
    var
        Row: Record "LT AZ Hnd Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
    end;

    [Test]
    [HandlerFunctions('AzReqInsertThenOk')]
    procedure RequestPageHandler_InsertBeforeOk()
    var
        Row: Record "LT AZ Hnd Row";
    begin
        SeedRows();
        Reset('');
        Report.Run(Report::"LT AZ Hnd Report");
        Observer.Observe('log', Log.Take());
        Observer.Observe('row99', Format(Row.Get(99)));
        Observer.Observe('count', Format(Row.Count()));
        Observer.Finish();
    end;

    // ---- item 6: FilterPageBuilder.RunModal with a FilterPageHandler and without one ----

    [TryFunction]
    local procedure TryRunFpb(var Fpb: FilterPageBuilder; var Result: Boolean)
    begin
        Result := Fpb.RunModal();
    end;

    local procedure ObserveFpb(Name: Text)
    var
        Fpb: FilterPageBuilder;
        Result: Boolean;
    begin
        Fpb.AddTable('Rows', Database::"LT AZ Hnd Row");
        Fpb.SetView('Rows', 'WHERE(Id=FILTER(1..5))');
        Observer.Observe(Name + '_ok', Format(TryRunFpb(Fpb, Result)));
        Observer.Observe(Name + '_result', Format(Result));
        Observer.Observe(Name + '_view', Fpb.GetView('Rows'));
        Observer.Observe(Name + '_view_captions', Fpb.GetView('Rows', false));
        Observer.Observe(Name + '_log', Log.Take());
        Observer.ObserveError(Name);
    end;

    [Test]
    procedure FilterPageBuilder_NoHandler()
    begin
        Reset('');
        ObserveFpb('n');
        Observer.Finish();
    end;

    // ---- item 9: Dialog.Update without arguments on a closed dialog, Update of a number missing from the template ----

    [TryFunction]
    local procedure TryUpdateNoArgs(var D: Dialog)
    begin
        D.Update();
    end;

    [TryFunction]
    local procedure TryUpdate(var D: Dialog; No: Integer; Value: Variant)
    begin
        D.Update(No, Value);
    end;

    [TryFunction]
    local procedure TryOpen(var D: Dialog; Template: Text)
    begin
        D.Open(Template);
    end;

    [Test]
    procedure Dialog_UpdateEdges()
    var
        D: Dialog;
    begin
        Reset('');
        Observer.Observe('closed_noargs', Format(TryUpdateNoArgs(D)));
        Observer.ObserveError('closed_noargs');
        Observer.Observe('closed_one', Format(TryUpdate(D, 1, 'x')));
        Observer.ObserveError('closed_one');
        Observer.Observe('open', Format(TryOpen(D, 'Name #1########\Progress @2@@@@@@@@')));
        Observer.ObserveError('open');
        Observer.Observe('open_noargs', Format(TryUpdateNoArgs(D)));
        Observer.ObserveError('open_noargs');
        Observer.Observe('open_hash', Format(TryUpdate(D, 1, 'abc')));
        Observer.ObserveError('open_hash');
        Observer.Observe('open_at', Format(TryUpdate(D, 2, 5000)));
        Observer.ObserveError('open_at');
        Observer.Observe('open_missing', Format(TryUpdate(D, 3, 'zz')));
        Observer.ObserveError('open_missing');
        Observer.Observe('open_at_text', Format(TryUpdate(D, 2, 'not a number')));
        Observer.ObserveError('open_at_text');
        D.Close();
        Observer.Observe('after_close_noargs', Format(TryUpdateNoArgs(D)));
        Observer.ObserveError('after_close_noargs');
        Observer.Finish();
    end;
}
