// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onqueryclosepage-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained page 70865, codeunits 70866 and 70867
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a modal page whose OnQueryClosePage returns false (always, only for OK, only for Cancel) while the handler closes it with OK, Cancel or Close: the RunModal outcome (result or error text and code), how often the trigger and OnClosePage ran, the CloseAction it saw, and whether a second Close in the handler is refused.
// BC versions: 29 (27 and 28 by CI)

page 70865 "LT QCVM Veto Modal"
{
    PageType = Card;
    ApplicationArea = All;
    Caption = 'LT QCVM Veto Modal';

    layout
    {
        area(Content)
        {
            field(Marker; MarkerVar)
            {
                ApplicationArea = All;
            }
        }
    }

    var
        Probe: Codeunit "LT QCVM Probe";
        MarkerVar: Text[10];

    trigger OnOpenPage()
    begin
        MarkerVar := 'OPENED';
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        exit(Probe.Answer(CloseAction));
    end;

    trigger OnClosePage()
    begin
        Probe.NoteClosePage();
    end;
}

codeunit 70866 "LT QCVM Probe"
{
    SingleInstance = true;

    var
        Mode: Integer;
        QueryCount: Integer;
        CloseCount: Integer;
        Seen: Text;

    procedure Reset(NewMode: Integer)
    begin
        Mode := NewMode;
        QueryCount := 0;
        CloseCount := 0;
        Seen := '';
    end;

    procedure Answer(CloseAction: Action): Boolean
    begin
        QueryCount += 1;
        Seen += Format(CloseAction) + ';';
        case Mode of
            1:
                exit(false);
            2:
                exit(not (CloseAction in [Action::OK, Action::LookupOK]));
            3:
                exit(not (CloseAction in [Action::Cancel, Action::LookupCancel]));
        end;
        exit(true);
    end;

    procedure NoteClosePage()
    begin
        CloseCount += 1;
    end;

    procedure Summary(): Text
    begin
        exit('query=' + Format(QueryCount) + ' close=' + Format(CloseCount) + ' seen=' + Seen);
    end;
}

codeunit 70867 "LT Modal Close Veto"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Probe: Codeunit "LT QCVM Probe";
        HandlerNote: Text;
        LookupFlag: Boolean;

    [TryFunction]
    local procedure TryRunModal(var Result: Text)
    var
        Modal: Page "LT QCVM Veto Modal";
    begin
        Modal.LookupMode(LookupFlag);
        Result := Format(Modal.RunModal());
    end;

    local procedure Run(Name: Text; var Observer: Codeunit "Probe Observer")
    var
        Result: Text;
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryRunModal(Result);
        Observer.Observe(Name + '_ok', Format(Ok));
        Observer.Observe(Name + '_result', Result);
        Observer.Observe(Name + '_err', GetLastErrorText());
        Observer.Observe(Name + '_code', GetLastErrorCode());
        Observer.Observe(Name + '_probe', Probe.Summary());
        Observer.Observe(Name + '_handler', HandlerNote);
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure Modal_HandlerOk_AllowedControl()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.Reset(0);
        HandlerNote := '';
        Run('allow_ok', Observer);
        Observer.Expect('allow_ok_ok', 'Yes');
        Observer.Expect('allow_ok_result', 'OK');
        Observer.Expect('allow_ok_err', '');
        Observer.Expect('allow_ok_code', '');
        Observer.Expect('allow_ok_probe', 'query=1 close=1 seen=OK;');
        Observer.Expect('allow_ok_handler', 'marker=OPENED');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure Modal_HandlerOk_VetoAlways()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.Reset(1);
        HandlerNote := '';
        Run('veto_ok', Observer);
        Observer.Expect('veto_ok_ok', 'Yes');
        Observer.Expect('veto_ok_result', 'None');
        Observer.Expect('veto_ok_err', 'The page cannot be closed at this time.');
        Observer.Expect('veto_ok_code', 'FormCloseNotAllowed');
        Observer.Expect('veto_ok_probe', 'query=2 close=0 seen=OK;OK;');
        Observer.Expect('veto_ok_handler', 'marker=OPENED');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LookupCancelHandler')]
    procedure Modal_HandlerCancel_VetoAlways()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.Reset(1);
        HandlerNote := '';
        LookupFlag := true;
        Run('veto_cancel', Observer);
        LookupFlag := false;
        Observer.Expect('veto_cancel_ok', 'Yes');
        Observer.Expect('veto_cancel_result', 'None');
        Observer.Expect('veto_cancel_err', 'The page cannot be closed at this time.');
        Observer.Expect('veto_cancel_code', 'FormCloseNotAllowed');
        Observer.Expect('veto_cancel_probe', 'query=2 close=0 seen=LookupCancel;LookupCancel;');
        Observer.Expect('veto_cancel_handler', 'marker=OPENED');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CloseHandler')]
    procedure Modal_HandlerClose_VetoAlways()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.Reset(1);
        HandlerNote := '';
        Run('veto_close', Observer);
        Observer.Expect('veto_close_ok', 'No');
        Observer.Expect('veto_close_result', '');
        Observer.Expect('veto_close_err', 'The RunModal procedure could not close the page 70865 as it has already been closed.');
        Observer.Expect('veto_close_code', 'TestCodeUnit');
        Observer.Expect('veto_close_probe', 'query=1 close=0 seen=OK;');
        Observer.Expect('veto_close_handler', 'marker=OPENED');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure Modal_HandlerOk_VetoOnlyOk()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.Reset(2);
        HandlerNote := '';
        Run('veto_only_ok', Observer);
        Observer.Expect('veto_only_ok_ok', 'Yes');
        Observer.Expect('veto_only_ok_result', 'None');
        Observer.Expect('veto_only_ok_err', 'The page cannot be closed at this time.');
        Observer.Expect('veto_only_ok_code', 'FormCloseNotAllowed');
        Observer.Expect('veto_only_ok_probe', 'query=2 close=0 seen=OK;OK;');
        Observer.Expect('veto_only_ok_handler', 'marker=OPENED');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LookupCancelHandler')]
    procedure Modal_HandlerCancel_VetoOnlyOk_Closes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.Reset(2);
        HandlerNote := '';
        LookupFlag := true;
        Run('veto_only_ok_cancel', Observer);
        LookupFlag := false;
        Observer.Expect('veto_only_ok_cancel_ok', 'Yes');
        Observer.Expect('veto_only_ok_cancel_result', 'LookupCancel');
        Observer.Expect('veto_only_ok_cancel_err', '');
        Observer.Expect('veto_only_ok_cancel_code', '');
        Observer.Expect('veto_only_ok_cancel_probe', 'query=1 close=1 seen=LookupCancel;');
        Observer.Expect('veto_only_ok_cancel_handler', 'marker=OPENED');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LookupCancelHandler')]
    procedure Modal_HandlerCancel_VetoOnlyCancel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.Reset(3);
        HandlerNote := '';
        LookupFlag := true;
        Run('veto_only_cancel', Observer);
        LookupFlag := false;
        Observer.Expect('veto_only_cancel_ok', 'Yes');
        Observer.Expect('veto_only_cancel_result', 'None');
        Observer.Expect('veto_only_cancel_err', 'The page cannot be closed at this time.');
        Observer.Expect('veto_only_cancel_code', 'FormCloseNotAllowed');
        Observer.Expect('veto_only_cancel_probe', 'query=2 close=0 seen=LookupCancel;LookupCancel;');
        Observer.Expect('veto_only_cancel_handler', 'marker=OPENED');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkThenCloseHandler')]
    procedure Modal_HandlerOkThenClose_VetoAlways()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.Reset(1);
        HandlerNote := '';
        Run('veto_ok_then_close', Observer);
        Observer.Expect('veto_ok_then_close_ok', 'No');
        Observer.Expect('veto_ok_then_close_result', '');
        Observer.Expect('veto_ok_then_close_err', 'The RunModal procedure could not close the page 70865 as it has already been closed.');
        Observer.Expect('veto_ok_then_close_code', 'TestCodeUnit');
        Observer.Expect('veto_ok_then_close_probe', 'query=2 close=0 seen=OK;OK;');
        Observer.Expect('veto_ok_then_close_handler', 'marker=OPENED after_ok_marker=OPENED close_returned');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NoInvokeHandler')]
    procedure Modal_HandlerDoesNothing_VetoAlways()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.Reset(1);
        HandlerNote := '';
        Run('veto_noinvoke', Observer);
        Observer.Expect('veto_noinvoke_ok', 'Yes');
        Observer.Expect('veto_noinvoke_result', 'None');
        Observer.Expect('veto_noinvoke_err', 'The page cannot be closed at this time.');
        Observer.Expect('veto_noinvoke_code', 'FormCloseNotAllowed');
        Observer.Expect('veto_noinvoke_probe', 'query=1 close=0 seen=OK;');
        Observer.Expect('veto_noinvoke_handler', 'marker=OPENED');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LookupOkHandler')]
    procedure Modal_Lookup_HandlerLookupOk_VetoAlways()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.Reset(1);
        HandlerNote := '';
        LookupFlag := true;
        Run('lookup_veto_ok', Observer);
        LookupFlag := false;
        Observer.Expect('lookup_veto_ok_ok', 'Yes');
        Observer.Expect('lookup_veto_ok_result', 'None');
        Observer.Expect('lookup_veto_ok_err', 'The page cannot be closed at this time.');
        Observer.Expect('lookup_veto_ok_code', 'FormCloseNotAllowed');
        Observer.Expect('lookup_veto_ok_probe', 'query=2 close=0 seen=LookupOK;LookupCancel;');
        Observer.Expect('lookup_veto_ok_handler', 'marker=OPENED');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure Modal_AfterVetoedRun_NextRunIsClean()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.Reset(1);
        HandlerNote := '';
        Run('first', Observer);
        Probe.Reset(0);
        HandlerNote := '';
        Run('second_allow', Observer);
        Observer.Expect('first_ok', 'Yes');
        Observer.Expect('first_result', 'None');
        Observer.Expect('first_err', 'The page cannot be closed at this time.');
        Observer.Expect('first_code', 'FormCloseNotAllowed');
        Observer.Expect('first_probe', 'query=2 close=0 seen=OK;OK;');
        Observer.Expect('first_handler', 'marker=OPENED');
        Observer.Expect('second_allow_ok', 'Yes');
        Observer.Expect('second_allow_result', 'OK');
        Observer.Expect('second_allow_err', '');
        Observer.Expect('second_allow_code', '');
        Observer.Expect('second_allow_probe', 'query=1 close=1 seen=OK;');
        Observer.Expect('second_allow_handler', 'marker=OPENED');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure OkHandler(var Modal: TestPage "LT QCVM Veto Modal")
    begin
        HandlerNote := 'marker=' + Modal.Marker.Value();
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure LookupCancelHandler(var Modal: TestPage "LT QCVM Veto Modal")
    begin
        HandlerNote := 'marker=' + Modal.Marker.Value();
        Modal.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure LookupOkHandler(var Modal: TestPage "LT QCVM Veto Modal")
    begin
        HandlerNote := 'marker=' + Modal.Marker.Value();
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CloseHandler(var Modal: TestPage "LT QCVM Veto Modal")
    begin
        HandlerNote := 'marker=' + Modal.Marker.Value();
        Modal.Close();
    end;

    [ModalPageHandler]
    procedure NoInvokeHandler(var Modal: TestPage "LT QCVM Veto Modal")
    begin
        HandlerNote := 'marker=' + Modal.Marker.Value();
    end;

    [ModalPageHandler]
    procedure OkThenCloseHandler(var Modal: TestPage "LT QCVM Veto Modal")
    begin
        HandlerNote := 'marker=' + Modal.Marker.Value();
        Modal.OK().Invoke();
        HandlerNote += ' after_ok_marker=' + TryMarker(Modal);
        Modal.Close();
        HandlerNote += ' close_returned';
    end;

    local procedure TryMarker(var Modal: TestPage "LT QCVM Veto Modal"): Text
    begin
        exit(Modal.Marker.Value());
    end;
}
