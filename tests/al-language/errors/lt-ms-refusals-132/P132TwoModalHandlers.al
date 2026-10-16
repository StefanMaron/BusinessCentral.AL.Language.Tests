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
}
