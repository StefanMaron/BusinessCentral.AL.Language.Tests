// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-modalpagehandler-attribute
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own pages 73725 and 73726, log 73728 (used only by test codeunit 73727)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

page 73725 "LT P132 Modal A"
{
    PageType = Card;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(TxtA; TxtVar) { ApplicationArea = All; }
        }
    }

    var
        TxtVar: Text[20];
}

page 73726 "LT P132 Modal B"
{
    PageType = Card;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(TxtB; TxtVar) { ApplicationArea = All; }
        }
    }

    var
        TxtVar: Text[20];
}

codeunit 73728 "LT P132 Modal Log"
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

codeunit 73727 "LT P132 Two Modals"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT P132 Modal Log";
        PwLastB: Text;

    [ModalPageHandler]
    procedure HandlerA(var P: TestPage "LT P132 Modal A")
    begin
        Log.Add('A');
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure HandlerB(var P: TestPage "LT P132 Modal B")
    begin
        Log.Add('B');
        P.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure TypedA(var P: Page "LT P132 Modal A"; var Response: Action)
    begin
        Log.Add('typedA');
        Response := Action::LookupOK;
    end;

    [ModalPageHandler]
    procedure TypedB(var P: Page "LT P132 Modal B"; var Response: Action)
    begin
        Log.Add('typedB');
        Response := Action::OK;
    end;

    [Test]
    [HandlerFunctions('HandlerA,HandlerB')]
    procedure P132_TwoTestPageHandlers_AThenB()
    var
        Observer: Codeunit "Probe Observer";
        RA: Action;
        RB: Action;
    begin
        Log.Take();
        RA := Page.RunModal(Page::"LT P132 Modal A");
        RB := Page.RunModal(Page::"LT P132 Modal B");
        Observer.Observe('a_result', Format(RA));
        Observer.Observe('b_result', Format(RB));
        Observer.Observe('log', Log.Take());
        Observer.Expect('a_result', 'LookupOK');
        Observer.Expect('b_result', 'LookupCancel');
        Observer.Expect('log', 'A;B;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandlerA,HandlerB')]
    procedure P132_TwoTestPageHandlers_BThenA()
    var
        Observer: Codeunit "Probe Observer";
        RA: Action;
        RB: Action;
    begin
        Log.Take();
        RB := Page.RunModal(Page::"LT P132 Modal B");
        RA := Page.RunModal(Page::"LT P132 Modal A");
        Observer.Observe('a_result', Format(RA));
        Observer.Observe('b_result', Format(RB));
        Observer.Observe('log', Log.Take());
        Observer.Expect('a_result', 'LookupOK');
        Observer.Expect('b_result', 'LookupCancel');
        Observer.Expect('log', 'B;A;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TypedA,TypedB')]
    procedure P132_TwoTypedHandlers_BThenA()
    var
        Observer: Codeunit "Probe Observer";
        RA: Action;
        RB: Action;
    begin
        Log.Take();
        RB := Page.RunModal(Page::"LT P132 Modal B");
        RA := Page.RunModal(Page::"LT P132 Modal A");
        Observer.Observe('a_result', Format(RA));
        Observer.Observe('b_result', Format(RB));
        Observer.Observe('log', Log.Take());
        Observer.Expect('a_result', 'LookupOK');
        Observer.Expect('b_result', 'OK');
        Observer.Expect('log', 'typedB;typedA;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TypedA,TypedB')]
    procedure P132_TwoTypedHandlers_AThenB()
    var
        Observer: Codeunit "Probe Observer";
        RA: Action;
        RB: Action;
    begin
        Log.Take();
        RA := Page.RunModal(Page::"LT P132 Modal A");
        RB := Page.RunModal(Page::"LT P132 Modal B");
        Observer.Observe('a_result', Format(RA));
        Observer.Observe('b_result', Format(RB));
        Observer.Observe('log', Log.Take());
        Observer.Expect('a_result', 'LookupOK');
        Observer.Expect('b_result', 'OK');
        Observer.Expect('log', 'typedA;typedB;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TypedA,HandlerB')]
    procedure P132_MixedHandlers_TypedAAndTestPageB()
    var
        Observer: Codeunit "Probe Observer";
        RA: Action;
        RB: Action;
    begin
        Log.Take();
        RB := Page.RunModal(Page::"LT P132 Modal B");
        RA := Page.RunModal(Page::"LT P132 Modal A");
        Observer.Observe('a_result', Format(RA));
        Observer.Observe('b_result', Format(RB));
        Observer.Observe('log', Log.Take());
        Observer.Expect('a_result', 'LookupOK');
        Observer.Expect('b_result', 'LookupCancel');
        Observer.Expect('log', 'B;typedA;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandlerA,TypedB')]
    procedure P132_MixedHandlers_TestPageAAndTypedB()
    var
        Observer: Codeunit "Probe Observer";
        RA: Action;
        RB: Action;
    begin
        Log.Take();
        RA := Page.RunModal(Page::"LT P132 Modal A");
        RB := Page.RunModal(Page::"LT P132 Modal B");
        Observer.Observe('a_result', Format(RA));
        Observer.Observe('b_result', Format(RB));
        Observer.Observe('log', Log.Take());
        Observer.Expect('a_result', 'LookupOK');
        Observer.Expect('b_result', 'OK');
        Observer.Expect('log', 'A;typedB;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandlerA,HandlerB')]
    procedure P132_TwoHandlers_ARunTwiceThenB()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Page.RunModal(Page::"LT P132 Modal A");
        Page.RunModal(Page::"LT P132 Modal A");
        asserterror Page.RunModal(Page::"LT P132 Modal B");
        Observer.ObserveError('af210');
        Observer.Observe('log', Log.Take());
        Observer.Expect('af210|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('af210|code', 'TestActionNotFound');
        Observer.Expect('log', 'A;A;B;');
        Observer.Verify();
    end;
    // Writer PW: failure-triage "Cancel not found after a page ran twice" (73727 P132_TwoHandlers_ARunTwiceThenB). The probe handlers try
    // Cancel first; when it raises they log the error code and close the page with OK, then with Close if OK raises too.
    [TryFunction]
    local procedure PwTryCancelA(var P: TestPage "LT P132 Modal A")
    begin
        P.Cancel().Invoke();
    end;

    [TryFunction]
    local procedure PwTryOkA(var P: TestPage "LT P132 Modal A")
    begin
        P.OK().Invoke();
    end;

    [TryFunction]
    local procedure PwTryCancelB(var P: TestPage "LT P132 Modal B")
    begin
        P.Cancel().Invoke();
    end;

    [TryFunction]
    local procedure PwTryOkB(var P: TestPage "LT P132 Modal B")
    begin
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PwProbeA(var P: TestPage "LT P132 Modal A")
    begin
        if PwTryCancelA(P) then begin
            Log.Add('A cancel');
            exit;
        end;
        Log.Add('A cancel ' + GetLastErrorCode());
        ClearLastError();
        if PwTryOkA(P) then begin
            Log.Add('A ok');
            exit;
        end;
        Log.Add('A ok ' + GetLastErrorCode());
        ClearLastError();
        P.Close();
    end;

    [ModalPageHandler]
    procedure PwProbeB(var P: TestPage "LT P132 Modal B")
    begin
        if PwTryCancelB(P) then begin
            Log.Add('B cancel');
            exit;
        end;
        Log.Add('B cancel ' + GetLastErrorCode());
        ClearLastError();
        if PwTryOkB(P) then begin
            Log.Add('B ok');
            exit;
        end;
        Log.Add('B ok ' + GetLastErrorCode());
        ClearLastError();
        P.Close();
    end;

    local procedure PwRunA(): Text
    begin
        exit(Format(Page.RunModal(Page::"LT P132 Modal A")) + ',');
    end;

    local procedure PwRunB(): Text
    begin
        exit(Format(Page.RunModal(Page::"LT P132 Modal B")) + ',');
    end;

    [Test]
    [HandlerFunctions('HandlerA,PwProbeB')]
    procedure PW_ARunTwice_ThenProbeB()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        Log.Take();
        R := PwRunA() + PwRunA() + PwRunB();
        Observer.Observe('results', R);
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerA,PwProbeB')]
    procedure PW_AOnce_ThenProbeB()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        Log.Take();
        R := PwRunA() + PwRunB();
        Observer.Observe('results', R);
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerA,PwProbeB')]
    procedure PW_AThrice_ThenProbeB()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        Log.Take();
        R := PwRunA() + PwRunA() + PwRunA() + PwRunB();
        Observer.Observe('results', R);
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerA,PwProbeB')]
    procedure PW_ABAB_ProbeB()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        Log.Take();
        R := PwRunA() + PwRunB() + PwRunA() + PwRunB();
        Observer.Observe('results', R);
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PwProbeB')]
    procedure PW_ProbeB_ThreeTimes()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        Log.Take();
        R := PwRunB() + PwRunB() + PwRunB();
        Observer.Observe('results', R);
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PwProbeA')]
    procedure PW_ProbeA_ThreeTimes()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        Log.Take();
        R := PwRunA() + PwRunA() + PwRunA();
        Observer.Observe('results', R);
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PwProbeA,HandlerB')]
    procedure PW_ProbeA_Twice_ThenB()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        Log.Take();
        R := PwRunA() + PwRunA();
        Observer.Observe('results', R);
        if TryRunB() then
            Observer.Observe('b', PwLastB)
        else
            Observer.Observe('b', 'error ' + GetLastErrorCode());
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryRunB()
    begin
        PwLastB := PwRunB();
    end;

    [Test]
    [HandlerFunctions('HandlerA,HandlerB')]
    procedure PW_ARunTwice_ThenB_ThenB()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        PwRunA();
        PwRunA();
        if TryRunB() then
            Observer.Observe('b1', PwLastB)
        else
            Observer.Observe('b1', 'error ' + GetLastErrorCode());
        ClearLastError();
        if TryRunB() then
            Observer.Observe('b2', PwLastB)
        else
            Observer.Observe('b2', 'error ' + GetLastErrorCode());
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;
}
