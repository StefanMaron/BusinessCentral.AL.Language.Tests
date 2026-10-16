// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-strmenu-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table, pages and log of P134ModalPair.al; test codeunit 74120 (P134)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a StrMenu, Message or Confirm raised from inside a handler function (Message, Confirm, StrMenu, ModalPage and Page handlers): which handler answers, what the call returns, and the error when no handler of that kind is declared
// BC versions: 29 (27 and 28 by CI)

codeunit 74120 "LT P134 StrMenu In Handler"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT P134 Log";
        Depth: Integer;

    local procedure Seed()
    var
        Row: Record "LT P134 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Log.Take();
        Depth := 0;
    end;

    [MessageHandler]
    procedure MsgOpensMenu(Msg: Text[1024])
    var
        Choice: Integer;
    begin
        Log.Add('msg=' + Msg);
        Choice := StrMenu('m1,m2,m3', 1, 'from message');
        Log.Add('msg choice=' + Format(Choice));
    end;

    [MessageHandler]
    procedure MsgPlain(Msg: Text[1024])
    begin
        Log.Add('plain msg=' + Msg);
    end;

    [ConfirmHandler]
    procedure ConfOpensMenu(Question: Text[1024]; var Reply: Boolean)
    var
        Choice: Integer;
    begin
        Log.Add('conf=' + Question);
        Choice := StrMenu('c1,c2', 1, 'from confirm');
        Log.Add('conf choice=' + Format(Choice));
        Reply := Choice = 2;
    end;

    [ConfirmHandler]
    procedure ConfNested(Question: Text[1024]; var Reply: Boolean)
    begin
        Depth += 1;
        Log.Add('confN depth=' + Format(Depth) + ' q=' + Question);
        if Depth = 1 then
            Log.Add('confN inner=' + Format(Confirm('inner?')));
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfPlain(Question: Text[1024]; var Reply: Boolean)
    begin
        Log.Add('plain conf=' + Question);
        Reply := true;
    end;

    [StrMenuHandler]
    procedure MenuPlain(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Log.Add('menu options=' + Options + ' instr=' + Instruction + ' choice_in=' + Format(Choice));
        Choice := 2;
    end;

    [StrMenuHandler]
    procedure MenuNested(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    var
        Inner: Integer;
    begin
        Depth += 1;
        Log.Add('menuN depth=' + Format(Depth) + ' options=' + Options);
        if Depth = 1 then begin
            Inner := StrMenu('i1,i2', 1, 'inner');
            Log.Add('menuN inner=' + Format(Inner));
        end;
        Choice := 3;
    end;

    [StrMenuHandler]
    procedure MenuOpensMessageAndConfirm(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Log.Add('menuMC options=' + Options);
        Message('from menu');
        Log.Add('menuMC confirm=' + Format(Confirm('from menu?')));
        Choice := 1;
    end;

    [ModalPageHandler]
    procedure ModalOpensMenu(var P: TestPage "LT P134 ListB")
    var
        Choice: Integer;
    begin
        Log.Add('modal first=' + Format(P.First()));
        Choice := StrMenu('p1,p2', 1, 'from modal');
        Log.Add('modal choice=' + Format(Choice));
        P.OK().Invoke();
    end;

    [PageHandler]
    procedure PageOpensMenu(var P: TestPage "LT P134 ListA")
    var
        Choice: Integer;
    begin
        Log.Add('page first=' + Format(P.First()));
        Choice := StrMenu('n1,n2', 1, 'from page');
        Log.Add('page choice=' + Format(Choice));
    end;

    [Test]
    [HandlerFunctions('MsgOpensMenu,MenuPlain')]
    procedure P134_StrMenu_InsideMessageHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Message('hello');
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'msg=hello;menu options=m1,m2,m3 instr=from message choice_in=1;msg choice=2;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ConfOpensMenu,MenuPlain')]
    procedure P134_StrMenu_InsideConfirmHandler()
    var
        Observer: Codeunit "Probe Observer";
        Answer: Boolean;
    begin
        Seed();
        Answer := Confirm('ask?');
        Observer.Observe('answer', Format(Answer));
        Observer.Observe('log', Log.Take());
        Observer.Expect('answer', 'Yes');
        Observer.Expect('log', 'conf=ask?;menu options=c1,c2 instr=from confirm choice_in=1;conf choice=2;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MenuNested')]
    procedure P134_StrMenu_InsideStrMenuHandler()
    var
        Observer: Codeunit "Probe Observer";
        Choice: Integer;
    begin
        Seed();
        Choice := StrMenu('o1,o2,o3', 1, 'outer');
        Observer.Observe('choice', Format(Choice));
        Observer.Observe('depth', Format(Depth));
        Observer.Observe('log', Log.Take());
        Observer.Expect('choice', '3');
        Observer.Expect('depth', '2');
        Observer.Expect('log', 'menuN depth=1 options=o1,o2,o3;menuN depth=2 options=i1,i2;menuN inner=3;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ConfNested')]
    procedure P134_Confirm_InsideConfirmHandler()
    var
        Observer: Codeunit "Probe Observer";
        Answer: Boolean;
    begin
        Seed();
        Answer := Confirm('outer?');
        Observer.Observe('answer', Format(Answer));
        Observer.Observe('depth', Format(Depth));
        Observer.Observe('log', Log.Take());
        Observer.Expect('answer', 'Yes');
        Observer.Expect('depth', '2');
        Observer.Expect('log', 'confN depth=1 q=outer?;confN depth=2 q=inner?;confN inner=Yes;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MenuOpensMessageAndConfirm,MsgPlain,ConfPlain')]
    procedure P134_MessageAndConfirm_InsideStrMenuHandler()
    var
        Observer: Codeunit "Probe Observer";
        Choice: Integer;
    begin
        Seed();
        Choice := StrMenu('a,b', 1, 'outer');
        Observer.Observe('choice', Format(Choice));
        Observer.Observe('log', Log.Take());
        Observer.Expect('choice', '1');
        Observer.Expect('log', 'menuMC options=a,b;plain msg=from menu;plain conf=from menu?;menuMC confirm=Yes;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalOpensMenu,MenuPlain')]
    procedure P134_StrMenu_InsideModalPageHandler()
    var
        Observer: Codeunit "Probe Observer";
        Result: Action;
    begin
        Seed();
        Result := Page.RunModal(Page::"LT P134 ListB");
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('log', 'modal first=Yes;menu options=p1,p2 instr=from modal choice_in=1;modal choice=2;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PageOpensMenu,MenuPlain')]
    procedure P134_StrMenu_InsidePageHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Page.Run(Page::"LT P134 ListA");
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'page first=Yes;menu options=n1,n2 instr=from page choice_in=1;page choice=2;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MsgOpensMenu')]
    procedure P134_StrMenu_InsideMessageHandler_NoMenuHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        asserterror Message('hello');
        Observer.ObserveError('message');
        Observer.Observe('log', Log.Take());
        Observer.Expect('message|text', 'Unhandled UI: StrMenu m1,m2,m3');
        Observer.Expect('message|code', 'MissingUIHandler');
        Observer.Expect('log', 'msg=hello;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ConfOpensMenu')]
    procedure P134_StrMenu_InsideConfirmHandler_NoMenuHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        asserterror if Confirm('ask?') then;
        Observer.ObserveError('confirm');
        Observer.Observe('log', Log.Take());
        Observer.Expect('confirm|text', 'Unhandled UI: StrMenu c1,c2');
        Observer.Expect('confirm|code', 'MissingUIHandler');
        Observer.Expect('log', 'conf=ask?;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalOpensMenu')]
    procedure P134_StrMenu_InsideModalPageHandler_NoMenuHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        asserterror if Page.RunModal(Page::"LT P134 ListB") = Action::OK then;
        Observer.ObserveError('modal');
        Observer.Observe('log', Log.Take());
        Observer.Expect('modal|text', 'Unhandled UI: StrMenu p1,p2');
        Observer.Expect('modal|code', 'MissingUIHandler');
        Observer.Expect('log', 'modal first=Yes;');
        Observer.Verify();
    end;
}
