// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Dialog Open / Update / Close in a test (no UI), Confirm / StrMenu / Message with handlers (text the handler receives, returned value) and without handlers, Error with format arguments and ErrorInfo
// BC versions: 29 (27 and 28 by CI)

codeunit 71206 "LT P82 Dialog"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        ConfirmAnswer: Boolean;
        MenuAnswer: Integer;

    [TryFunction]
    local procedure TryUpdateNumber(var Dlg: Dialog; FieldNo: Integer; Value: Integer)
    begin
        Dlg.Update(FieldNo, Value);
    end;

    [TryFunction]
    local procedure TryUpdateText(var Dlg: Dialog; FieldNo: Integer; Value: Text)
    begin
        Dlg.Update(FieldNo, Value);
    end;

    [TryFunction]
    local procedure TryOpen(var Dlg: Dialog; Template: Text)
    begin
        Dlg.Open(Template);
    end;

    [TryFunction]
    local procedure TryClose(var Dlg: Dialog)
    begin
        Dlg.Close();
    end;

    [ConfirmHandler]
    procedure ConfirmAnswerHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Observer.Observe('question', Question);
        Reply := ConfirmAnswer;
    end;

    [StrMenuHandler]
    procedure MenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Observer.Observe('options', Options);
        Observer.Observe('instruction', Instruction);
        Observer.Observe('default-choice', Format(Choice));
        Choice := MenuAnswer;
    end;

    [MessageHandler]
    procedure MessageObserver(Message: Text[1024])
    begin
        Observer.Observe('message', Message);
    end;

    [Test]
    procedure Dialog_Open_Update_Close()
    var
        Dlg: Dialog;
    begin
        Dlg.Open('Working #1###### and @2@@@@@@@@');
        Observer.Observe('open', 'ok');
        Dlg.Update(1, 'text');
        Observer.Observe('update-text', 'ok');
        Dlg.Update(1, 42);
        Observer.Observe('update-integer', 'ok');
        Dlg.Update(2, 5000);
        Observer.Observe('update-progress', 'ok');
        Dlg.Update(2, 10000);
        Observer.Observe('update-progress-full', 'ok');
        Dlg.Update(1, 1.5);
        Observer.Observe('update-decimal', 'ok');
        Dlg.Update(1, Today());
        Observer.Observe('update-date-no-error', 'ok');
        Dlg.Close();
        Observer.Observe('close', 'ok');
        Observer.Finish();
    end;

    [Test]
    procedure Dialog_EdgeCases()
    var
        Dlg: Dialog;
        Dlg2: Dialog;
    begin
        Observer.Observe('close-unopened', Format(TryClose(Dlg2)));
        Observer.Observe('close-unopened-error', GetLastErrorText());
        Observer.Observe('update-unopened', Format(TryUpdateNumber(Dlg2, 1, 1)));
        Observer.Observe('update-unopened-error', GetLastErrorText());
        Observer.Observe('open-empty-template', Format(TryOpen(Dlg, '')));
        Observer.Observe('open-empty-error', GetLastErrorText());
        Observer.Observe('update-unknown-field', Format(TryUpdateNumber(Dlg, 9, 1)));
        Observer.Observe('update-unknown-field-error', GetLastErrorText());
        Observer.Observe('update-zero-field', Format(TryUpdateNumber(Dlg, 0, 1)));
        Observer.Observe('update-zero-field-error', GetLastErrorText());
        Observer.Observe('close-twice-first', Format(TryClose(Dlg)));
        Observer.Observe('close-twice-second', Format(TryClose(Dlg)));
        Observer.Observe('close-twice-error', GetLastErrorText());
        Observer.Observe('open-plain-text', Format(TryOpen(Dlg, 'Just text')));
        Observer.Observe('update-no-placeholder', Format(TryUpdateText(Dlg, 1, 'x')));
        Observer.Observe('update-no-placeholder-error', GetLastErrorText());
        Observer.Observe('open-reopen', Format(TryOpen(Dlg, 'Again #1##')));
        Observer.Observe('open-reopen-error', GetLastErrorText());
        Dlg.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ConfirmAnswerHandler')]
    procedure Confirm_WithHandler_True()
    var
        Result: Boolean;
    begin
        ConfirmAnswer := true;
        Result := Confirm('Proceed with %1 and %2?', false, 'one', 2);
        Observer.Observe('result', Format(Result));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ConfirmAnswerHandler')]
    procedure Confirm_WithHandler_False_DefaultTrue()
    var
        Result: Boolean;
    begin
        ConfirmAnswer := false;
        Result := Confirm('Default true?', true);
        Observer.Observe('result', Format(Result));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ConfirmAnswerHandler')]
    procedure Confirm_QuestionOnly()
    var
        Result: Boolean;
    begin
        ConfirmAnswer := true;
        Result := Confirm('Plain question');
        Observer.Observe('result', Format(Result));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ConfirmAnswerHandler')]
    procedure Confirm_EmptyAndLongQuestion()
    var
        Result: Boolean;
        Long: Text;
    begin
        ConfirmAnswer := true;
        Result := Confirm('');
        Observer.Observe('empty-result', Format(Result));
        Long := PadStr('', 1100, 'x');
        asserterror Result := Confirm(Long);
        Observer.ObserveError('af163');
        Observer.Observe('long-result', Format(Result));
        Observer.Finish();
    end;

    [Test]
    procedure Confirm_WithoutHandler()
    var
        Answer: Boolean;
    begin
        asserterror Answer := Confirm('No handler question');
        Observer.ObserveError('confirm');
        asserterror Answer := Confirm('No handler %1', true, 'again');
        Observer.ObserveError('confirm-with-args');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MenuHandler')]
    procedure StrMenu_WithHandler_Choice()
    var
        Result: Integer;
    begin
        MenuAnswer := 2;
        Result := StrMenu('First,Second,Third', 3, 'Pick one');
        Observer.Observe('result', Format(Result));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MenuHandler')]
    procedure StrMenu_WithHandler_Cancel()
    var
        Result: Integer;
    begin
        MenuAnswer := 0;
        Result := StrMenu('First,Second', 1);
        Observer.Observe('result', Format(Result));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MenuHandler')]
    procedure StrMenu_OptionsOnly_Defaults()
    var
        Result: Integer;
    begin
        MenuAnswer := 1;
        Result := StrMenu('Only');
        Observer.Observe('result', Format(Result));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MenuHandler')]
    procedure StrMenu_ChoiceOutOfRange_ReturnedAsIs()
    var
        Result: Integer;
    begin
        MenuAnswer := 9;
        Result := StrMenu('A,B', 1, 'x');
        Observer.Observe('result-9', Format(Result));
        MenuAnswer := -1;
        Result := StrMenu('A,B', 1, 'x');
        Observer.Observe('result-minus-1', Format(Result));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MenuHandler')]
    procedure StrMenu_EmptyAndEmptyItems()
    var
        Result: Integer;
    begin
        MenuAnswer := 1;
        Result := StrMenu('', 0, '');
        Observer.Observe('empty-result', Format(Result));
        Result := StrMenu(',,A,,', 2, 'items');
        Observer.Observe('empty-items-result', Format(Result));
        Observer.Finish();
    end;

    [Test]
    procedure StrMenu_WithoutHandler()
    var
        Pick: Integer;
    begin
        asserterror Pick := StrMenu('A,B', 1, 'Instr');
        Observer.ObserveError('strmenu');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MessageObserver')]
    procedure Message_WithHandler()
    begin
        Message('Hello %1 and %2', 'world', 5);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MessageObserver')]
    procedure Message_TwoMessages_TwoCalls()
    begin
        Message('first');
        Message('second');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MessageObserver')]
    procedure Message_FormatCharacters()
    begin
        Message('100% sure %1', 'x');
        Observer.Finish();
    end;

    [Test]
    procedure Message_WithoutHandler()
    begin
        asserterror Message('No handler message');
        Observer.ObserveError('message');
        asserterror Message('No handler %1', 'x');
        Observer.ObserveError('message-with-args');
        Observer.Finish();
    end;

    [Test]
    procedure Error_Texts()
    begin
        asserterror Error('plain');
        Observer.ObserveError('plain');
        asserterror Error('with %1 and %2', 'text', 3);
        Observer.ObserveError('args');
        asserterror Error('missing %1 %2', 'one');
        Observer.ObserveError('missing-arg');
        asserterror Error('extra', 'unused');
        Observer.ObserveError('unused-arg');
        asserterror Error('');
        Observer.ObserveError('empty');
        asserterror Error('percent 100%');
        Observer.ObserveError('percent');
        asserterror Error('decimal %1 date %2 bool %3', 1.5, DMY2Date(2, 3, 2024), true);
        Observer.ObserveError('formatted');
        asserterror Error(PadStr('', 3000, 'e'));
        Observer.Observe('long-length', Format(StrLen(GetLastErrorText())));
        ClearLastError();
        Observer.Finish();
    end;

    [Test]
    procedure Error_ErrorInfo()
    var
        Info: ErrorInfo;
    begin
        asserterror Error(ErrorInfo.Create('info message'));
        Observer.ObserveError('create');
        Info.Message := 'set message';
        Info.Title := 'a title';
        asserterror Error(Info);
        Observer.ObserveError('set');
        Observer.Finish();
    end;

    [Test]
    procedure Error_Rolls_Back_And_Clears()
    begin
        asserterror Error('first');
        Observer.Observe('has-error', Format(GetLastErrorText() <> ''));
        ClearLastError();
        Observer.Observe('after-clear', GetLastErrorText());
        Observer.Observe('code-after-clear', GetLastErrorCode());
        Observer.Finish();
    end;
}
