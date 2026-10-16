// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-pagehandler-attribute
// Scope: in-scope
// Fixtures used: P130Fixtures.al (table 73536, log 73538, pages 73541 and 73542 with triggers), Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a handler whose parameter is typed Page (not TestPage), on pages that declare OnInit, OnOpenPage, OnAfterGetRecord, OnAfterGetCurrRecord, OnQueryClosePage and OnClosePage:
//   which triggers run before the handler, which after, what GetRecord / Caption / Editable / LookupMode answer in it, what a Modify made through it leaves;
//   for [ModalPageHandler] (var Page; var Response: Action) and for the non-modal [PageHandler] (var Page); the same page with a TestPage handler for comparison
// Settles issue 130 reasons 11, 20, 24, 30, 33, 39 (Page-typed handlers: what they are handed, whether the page triggers run)
// BC versions: 29 (27 and 28 by CI)

codeunit 73545 "LT P130 Page Typed"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [ModalPageHandler]
    procedure ModalList_Typed(var P: Page "LT P130 Trig List"; var Response: Action)
    var
        Log: Codeunit "LT P130 Log";
        Item: Record "LT P130 Item";
    begin
        Log.Add('H.begin');
        P.GetRecord(Item);
        Log.Add('H.rec=' + Item."No." + '/' + Item.Name);
        Log.Add('H.lookup=' + Format(P.LookupMode()));
        Log.Add('H.response_before=' + Format(Response));
        Response := Action::LookupOK;
        Log.Add('H.end');
    end;

    [ModalPageHandler]
    procedure ModalList_TestPage(var P: TestPage "LT P130 Trig List")
    var
        Log: Codeunit "LT P130 Log";
    begin
        Log.Add('H.begin');
        Log.Add('H.rec=' + P."No.".Value() + '/' + P.Name.Value());
        P.OK().Invoke();
        Log.Add('H.end');
    end;

    [ModalPageHandler]
    procedure ModalCard_Typed(var P: Page "LT P130 Trig Card"; var Response: Action)
    var
        Log: Codeunit "LT P130 Log";
        Item: Record "LT P130 Item";
    begin
        Log.Add('H.begin');
        P.GetRecord(Item);
        Log.Add('H.rec=' + Item."No." + '/' + Item.Name);
        Response := Action::LookupOK;
        Log.Add('H.end');
    end;

    [ModalPageHandler]
    procedure ModalCard_TestPage(var P: TestPage "LT P130 Trig Card")
    var
        Log: Codeunit "LT P130 Log";
    begin
        Log.Add('H.begin');
        Log.Add('H.rec=' + P."No.".Value() + '/' + P.Name.Value());
        P.OK().Invoke();
        Log.Add('H.end');
    end;

    [PageHandler]
    procedure PlainList_Typed(var P: Page "LT P130 Trig List")
    var
        Log: Codeunit "LT P130 Log";
        Item: Record "LT P130 Item";
    begin
        Log.Add('H.begin');
        P.GetRecord(Item);
        Log.Add('H.rec=' + Item."No." + '/' + Item.Name);
        Log.Add('H.caption=' + P.Caption());
        Log.Add('H.editable=' + Format(P.Editable()));
        Log.Add('H.lookup=' + Format(P.LookupMode()));
        Log.Add('H.end');
    end;

    [PageHandler]
    procedure PlainCard_Typed(var P: Page "LT P130 Trig Card")
    var
        Log: Codeunit "LT P130 Log";
        Item: Record "LT P130 Item";
    begin
        Log.Add('H.begin');
        P.GetRecord(Item);
        Log.Add('H.rec=' + Item."No." + '/' + Item.Name);
        Log.Add('H.caption=' + P.Caption());
        Log.Add('H.editable=' + Format(P.Editable()));
        Log.Add('H.end');
    end;

    [PageHandler]
    procedure PlainCard_TypedModify(var P: Page "LT P130 Trig Card")
    var
        Log: Codeunit "LT P130 Log";
        Item: Record "LT P130 Item";
    begin
        Log.Add('H.begin');
        Item.Init();
        P.GetRecord(Item);
        Item.Validate(Name, 'Changed by handler');
        Item.Modify(true);
        Log.Add('H.modified=' + Item."No." + '/' + Item.Name);
        Log.Add('H.end');
    end;

    [PageHandler]
    procedure PlainList_TestPage(var P: TestPage "LT P130 Trig List")
    var
        Log: Codeunit "LT P130 Log";
    begin
        Log.Add('H.begin');
        Log.Add('H.rec=' + P."No.".Value() + '/' + P.Name.Value());
        Log.Add('H.end');
    end;

    [Test]
    [HandlerFunctions('ModalList_Typed')]
    procedure P130_ModalTyped_ListWithTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P130 Log";
        Pg: Page "LT P130 Trig List";
        Item: Record "LT P130 Item";
        Result: Action;
    begin
        Log.Seed();
        Pg.LookupMode(true);
        Result := Pg.RunModal();
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        Pg.GetRecord(Item);
        Observer.Observe('record_after', Item."No.");
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('log', 'L.OnInit;H.begin;H.rec=/;H.lookup=Yes;H.response_before=None;H.end;');
        Observer.Expect('record_after', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalList_Typed')]
    procedure P130_ModalTyped_ListWithTriggers_WithRecordAndFilter()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P130 Log";
        Item: Record "LT P130 Item";
        Result: Action;
    begin
        Log.Seed();
        Item.SetFilter(Qty, '>=2');
        Item.FindFirst();
        Result := Page.RunModal(Page::"LT P130 Trig List", Item);
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('log', 'L.OnInit;H.begin;H.rec=B/Beta;H.lookup=Yes;H.response_before=None;H.end;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalList_TestPage')]
    procedure P130_ModalTestPage_ListWithTriggers_ForComparison()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P130 Log";
        Pg: Page "LT P130 Trig List";
        Result: Action;
    begin
        Log.Seed();
        Pg.LookupMode(true);
        Result := Pg.RunModal();
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('log', 'L.OnInit;L.OnOpenPage filter=;L.OnAfterGetRecord(A);L.OnAfterGetRecord(B);L.OnAfterGetRecord(C);L.OnAfterGetRecord(A);L.OnAfterGetRecord(A);L.OnAfterGetCurrRecord(A);H.begin;H.rec=A/Alpha;L.OnQueryClosePage(LookupOK);L.OnClosePage;H.end;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalCard_Typed')]
    procedure P130_ModalTyped_CardWithTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P130 Log";
        Item: Record "LT P130 Item";
        Result: Action;
    begin
        Log.Seed();
        Item.Get('B');
        Result := Page.RunModal(Page::"LT P130 Trig Card", Item);
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('log', 'C.OnInit;H.begin;H.rec=B/Beta;H.end;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalCard_TestPage')]
    procedure P130_ModalTestPage_CardWithTriggers_ForComparison()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P130 Log";
        Item: Record "LT P130 Item";
        Result: Action;
    begin
        Log.Seed();
        Item.Get('B');
        Result := Page.RunModal(Page::"LT P130 Trig Card", Item);
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('log', 'C.OnInit;C.OnOpenPage rec=B;C.OnAfterGetRecord(B);C.OnAfterGetCurrRecord(B);H.begin;H.rec=B/Beta;C.OnQueryClosePage(LookupOK);C.OnClosePage;H.end;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PlainList_Typed')]
    procedure P130_PlainTyped_ListWithTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P130 Log";
    begin
        Log.Seed();
        Page.Run(Page::"LT P130 Trig List");
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'L.OnInit;H.begin;H.rec=/;H.caption=LT P130 Trig List Caption;H.editable=Yes;H.lookup=No;H.end;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PlainList_Typed')]
    procedure P130_PlainTyped_ListWithTriggers_WithRecord()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P130 Log";
        Item: Record "LT P130 Item";
    begin
        Log.Seed();
        Item.Get('C');
        Page.Run(Page::"LT P130 Trig List", Item);
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'L.OnInit;H.begin;H.rec=C/Gamma;H.caption=LT P130 Trig List Caption;H.editable=Yes;H.lookup=No;H.end;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PlainList_TestPage')]
    procedure P130_PlainTestPage_ListWithTriggers_ForComparison()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P130 Log";
    begin
        Log.Seed();
        Page.Run(Page::"LT P130 Trig List");
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'L.OnInit;L.OnOpenPage filter=;L.OnAfterGetRecord(A);L.OnAfterGetRecord(B);L.OnAfterGetRecord(C);L.OnAfterGetRecord(A);L.OnAfterGetRecord(A);L.OnAfterGetCurrRecord(A);H.begin;H.rec=A/Alpha;H.end;L.OnQueryClosePage(OK);L.OnClosePage;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PlainCard_Typed')]
    procedure P130_PlainTyped_CardWithTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P130 Log";
        Item: Record "LT P130 Item";
    begin
        Log.Seed();
        Item.Get('B');
        Page.Run(Page::"LT P130 Trig Card", Item);
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'C.OnInit;H.begin;H.rec=B/Beta;H.caption=LT P130 Trig Card Caption;H.editable=Yes;H.end;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PlainCard_TypedModify')]
    procedure P130_PlainTyped_CardModifyThroughGetRecord()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P130 Log";
        Item: Record "LT P130 Item";
    begin
        Log.Seed();
        Item.Get('B');
        Page.Run(Page::"LT P130 Trig Card", Item);
        Observer.Observe('log', Log.Take());
        Item.Get('B');
        Observer.Observe('stored_name_after', Item.Name);
        Item.Get('A');
        Observer.Observe('other_row_name', Item.Name);
        Observer.Expect('log', 'C.OnInit;H.begin;H.modified=B/Changed by handler;H.end;');
        Observer.Expect('stored_name_after', 'Changed by handler');
        Observer.Expect('other_row_name', 'Alpha');
        Observer.Verify();
    end;
}
