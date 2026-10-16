// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-callstack-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); codeunit 74337 and page 74341 of P136CsBase.al and P136CsPage.al; codeunit 74343
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SessionInformation.Callstack read inside a Message, Confirm and StrMenu handler and inside a modal and a non-modal page handler: the frames between the handler and the test procedure
// BC versions: 29 (27 and 28 by CI)

codeunit 74343 "LT P136 CS Handler Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT P136 CS Log";

    local procedure Show(var Observer: Codeunit "Probe Observer"; KeyName: Text)
    begin
        Observer.Observe(KeyName, Log.Frames(KeyName));
    end;

    [MessageHandler]
    procedure MsgHandler(Msg: Text[1024])
    begin
        Log.Capture('msgHandler');
    end;

    [ConfirmHandler]
    procedure ConfHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Log.Capture('confirmHandler');
        Reply := true;
    end;

    [StrMenuHandler]
    procedure MenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Log.Capture('strMenuHandler');
        Choice := 1;
    end;

    [ModalPageHandler]
    procedure ModalCardHandler(var Card: TestPage "LT P136 CS Card")
    begin
        Log.Capture('modalHandler');
        Card.OK().Invoke();
    end;

    [PageHandler]
    procedure CardHandler(var Card: TestPage "LT P136 CS Card")
    begin
        Log.Capture('pageHandler');
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfHandler,MenuHandler')]
    procedure P136_Callstack_MessageConfirmStrMenuHandlers()
    var
        Observer: Codeunit "Probe Observer";
        Choice: Integer;
    begin
        Log.Reset();
        Message('hello');
        Show(Observer, 'msgHandler');
        Observer.Observe('confirmResult', Format(Confirm('sure?')));
        Show(Observer, 'confirmHandler');
        Choice := StrMenu('a,b');
        Observer.Observe('strMenuResult', Format(Choice));
        Show(Observer, 'strMenuHandler');
        Observer.Expect('msgHandler', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Handler Tests"(CodeUnit 74343).MsgHandler line 2 < "LT P136 CS Handler Tests"(CodeUnit 74343).P136_Callstack_MessageConfirmStrMenuHandlers line 6');
        Observer.Expect('confirmResult', 'Yes');
        Observer.Expect('confirmHandler', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Handler Tests"(CodeUnit 74343).ConfHandler line 2 < "LT P136 CS Handler Tests"(CodeUnit 74343).P136_Callstack_MessageConfirmStrMenuHandlers line 8');
        Observer.Expect('strMenuResult', '1');
        Observer.Expect('strMenuHandler', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Handler Tests"(CodeUnit 74343).MenuHandler line 2 < "LT P136 CS Handler Tests"(CodeUnit 74343).P136_Callstack_MessageConfirmStrMenuHandlers line 10');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalCardHandler')]
    procedure P136_Callstack_ModalPageHandler()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P136 CS Row";
        Result: Action;
    begin
        Row.DeleteAll();
        Log.Reset();
        asserterror Result := Page.RunModal(Page::"LT P136 CS Card");
        Observer.ObserveError('af82');
        Observer.Observe('modalResult', Format(Result));
        Show(Observer, 'modalHandler');
        Show(Observer, 'pgOnInit');
        Show(Observer, 'pgOnOpenPage');
        Show(Observer, 'pgOnNewRecord');
        Show(Observer, 'pgOnAfterGetCurrRecord');
        Show(Observer, 'pgOnQueryClosePage');
        Show(Observer, 'pgOnClosePage');
        Observer.Expect('af82|text', 'The built-in action = OK is not found on the page.');
        Observer.Expect('af82|code', 'TestActionNotFound');
        Observer.Expect('modalResult', 'None');
        Observer.Expect('modalHandler', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Handler Tests"(CodeUnit 74343).ModalCardHandler line 2 < "LT P136 CS Handler Tests"(CodeUnit 74343).P136_Callstack_ModalPageHandler line 8');
        Observer.Expect('pgOnInit', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Card"(Page 74341).OnInit(Trigger) line 4 < "LT P136 CS Handler Tests"(CodeUnit 74343).P136_Callstack_ModalPageHandler line 8');
        Observer.Expect('pgOnOpenPage', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Card"(Page 74341).OnOpenPage(Trigger) line 4 < "LT P136 CS Handler Tests"(CodeUnit 74343).P136_Callstack_ModalPageHandler line 8');
        Observer.Expect('pgOnNewRecord', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Card"(Page 74341).OnNewRecord(Trigger) line 4 < "LT P136 CS Handler Tests"(CodeUnit 74343).P136_Callstack_ModalPageHandler line 8');
        Observer.Expect('pgOnAfterGetCurrRecord', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Card"(Page 74341).OnAfterGetCurrRecord(Trigger) line 4 < "LT P136 CS Handler Tests"(CodeUnit 74343).P136_Callstack_ModalPageHandler line 8');
        Observer.Expect('pgOnQueryClosePage', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Card"(Page 74341).OnQueryClosePage(Trigger) line 4 < "LT P136 CS Handler Tests"(CodeUnit 74343).P136_Callstack_ModalPageHandler line 8');
        Observer.Expect('pgOnClosePage', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Card"(Page 74341).OnClosePage(Trigger) line 4 < "LT P136 CS Handler Tests"(CodeUnit 74343).P136_Callstack_ModalPageHandler line 8');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure P136_Callstack_PageHandler()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P136 CS Row";
    begin
        Row.DeleteAll();
        Log.Reset();
        Page.Run(Page::"LT P136 CS Card");
        Show(Observer, 'pageHandler');
        Show(Observer, 'pgOnInit');
        Show(Observer, 'pgOnOpenPage');
        Observer.Expect('pageHandler', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Handler Tests"(CodeUnit 74343).CardHandler line 2 < "LT P136 CS Handler Tests"(CodeUnit 74343).P136_Callstack_PageHandler line 7');
        Observer.Expect('pgOnInit', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Card"(Page 74341).OnInit(Trigger) line 4 < "LT P136 CS Handler Tests"(CodeUnit 74343).P136_Callstack_PageHandler line 7');
        Observer.Expect('pgOnOpenPage', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Card"(Page 74341).OnOpenPage(Trigger) line 4 < "LT P136 CS Handler Tests"(CodeUnit 74343).P136_Callstack_PageHandler line 7');
        Observer.Verify();
    end;
}
