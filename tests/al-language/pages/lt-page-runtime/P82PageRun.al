// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P82 Card (71187), LT P82 List (71188), LT P82 Item (71184), LT P82 Log (71186) from P82Fixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Page.Run / Page.RunModal overloads (number; number and record; number, record and field), the Action returned by RunModal, SetRecord, SetTableView, GetRecord, LookupMode of a Page variable
// BC versions: 29 (27 and 28 by CI)

codeunit 71200 "LT P82 Page Run"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";

    local procedure Seed()
    var
        Item: Record "LT P82 Item";
    begin
        Item.DeleteAll();
        Log.Reset();
        Item."No." := 'A';
        Item.Name := 'Alpha';
        Item.Qty := 1;
        Item.Insert();
        Item."No." := 'B';
        Item.Name := 'Beta';
        Item.Qty := 2;
        Item.Insert();
        Item."No." := 'C';
        Item.Name := 'Gamma';
        Item.Qty := 3;
        Item.Insert();
    end;

    [ModalPageHandler]
    procedure CardOk(var P: TestPage "LT P82 Card")
    begin
        Observer.Observe('card-no', P.NoCtl.Value());
        Observer.Observe('card-name', P.NameCtl.Value());
        Observer.Observe('card-editable', Format(P.Editable()));
        Observer.Observe('card-caption', P.Caption());
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CardCancel(var P: TestPage "LT P82 Card")
    begin
        Observer.Observe('card-no', P.NoCtl.Value());
        P.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure CardActClose(var P: TestPage "LT P82 Card")
    begin
        Observer.Observe('card-no', P.NoCtl.Value());
        P.ActClose.Invoke();
    end;

    [ModalPageHandler]
    procedure ListOk(var P: TestPage "LT P82 List")
    begin
        Observer.Observe('list-no', P.NoCtl.Value());
        Observer.Observe('list-caption', P.Caption());
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ListScan(var P: TestPage "LT P82 List")
    var
        N: Integer;
    begin
        if P.First() then
            repeat
                N += 1;
                Observer.Observe('row' + Format(N), P.NoCtl.Value());
            until not P.Next();
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ListPickC(var P: TestPage "LT P82 List")
    begin
        P.GoToKey('C');
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ListClose(var P: TestPage "LT P82 List")
    begin
        P.ActClose.Invoke();
    end;

    [ModalPageHandler]
    procedure ListCancel(var P: TestPage "LT P82 List")
    begin
        P.Cancel().Invoke();
    end;

    [PageHandler]
    procedure CardPlain(var P: TestPage "LT P82 Card")
    begin
        Observer.Observe('plain-no', P.NoCtl.Value());
        Observer.Observe('plain-name', P.NameCtl.Value());
        Observer.Observe('plain-editable', Format(P.Editable()));
    end;

    [PageHandler]
    procedure ListPlain(var P: TestPage "LT P82 List")
    begin
        Observer.Observe('plain-no', P.NoCtl.Value());
        Observer.Observe('plain-rows', Format(P.First()));
    end;

    [Test]
    [HandlerFunctions('CardOk')]
    procedure RunModal_Number_OnCard()
    var
        Result: Action;
    begin
        Seed();
        Result := Page.RunModal(Page::"LT P82 Card");
        Observer.Observe('action', Format(Result));
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardOk')]
    procedure RunModal_NumberAndRecord()
    var
        Item: Record "LT P82 Item";
        Result: Action;
    begin
        Seed();
        Item.Get('B');
        Result := Page.RunModal(Page::"LT P82 Card", Item);
        Observer.Observe('action', Format(Result));
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardCancel')]
    procedure RunModal_NumberAndRecord_Cancel()
    var
        Item: Record "LT P82 Item";
        Result: Action;
    begin
        Seed();
        Item.Get('C');
        Result := Page.RunModal(Page::"LT P82 Card", Item);
        Observer.Observe('action', Format(Result));
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardActClose')]
    procedure RunModal_CurrPageClose_Action()
    var
        Item: Record "LT P82 Item";
        Result: Action;
    begin
        Seed();
        Item.Get('A');
        Result := Page.RunModal(Page::"LT P82 Card", Item);
        Observer.Observe('action', Format(Result));
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListClose')]
    procedure RunModal_List_CurrPageClose_Action()
    var
        Result: Action;
    begin
        Seed();
        Result := Page.RunModal(Page::"LT P82 List");
        Observer.Observe('action', Format(Result));
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListOk')]
    procedure RunModal_NumberRecordField()
    var
        Item: Record "LT P82 Item";
        Result: Action;
    begin
        Seed();
        Item.Get('B');
        Result := Page.RunModal(Page::"LT P82 List", Item, Item.FieldNo(Name));
        Observer.Observe('action', Format(Result));
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListOk')]
    procedure RunModal_NumberRecordField_NoFieldMatch()
    var
        Item: Record "LT P82 Item";
        Result: Action;
    begin
        Seed();
        Item.Get('C');
        Result := Page.RunModal(Page::"LT P82 List", Item, 0);
        Observer.Observe('action', Format(Result));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListScan')]
    procedure RunModal_List_NoRecord_AllRows()
    var
        Result: Action;
    begin
        Seed();
        Result := Page.RunModal(Page::"LT P82 List");
        Observer.Observe('action', Format(Result));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListScan')]
    procedure RunModal_List_RecordWithFilter_PassedFilterIgnored()
    var
        Item: Record "LT P82 Item";
        Result: Action;
    begin
        Seed();
        Item.SetFilter(Qty, '>=2');
        Item.FindFirst();
        Result := Page.RunModal(Page::"LT P82 List", Item);
        Observer.Observe('action', Format(Result));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListScan')]
    procedure PageVar_SetTableView_Filters()
    var
        Item: Record "LT P82 Item";
        Pg: Page "LT P82 List";
        Result: Action;
    begin
        Seed();
        Item.SetFilter(Qty, '>=2');
        Pg.SetTableView(Item);
        Result := Pg.RunModal();
        Observer.Observe('action', Format(Result));
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListScan')]
    procedure PageVar_SetTableView_Sorting()
    var
        Item: Record "LT P82 Item";
        Pg: Page "LT P82 List";
    begin
        Seed();
        Item.SetCurrentKey(Qty);
        Item.Ascending(false);
        Pg.SetTableView(Item);
        Pg.RunModal();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListOk')]
    procedure PageVar_SetRecord_Positions()
    var
        Item: Record "LT P82 Item";
        Pg: Page "LT P82 List";
    begin
        Seed();
        Item.Get('C');
        Pg.SetRecord(Item);
        Pg.RunModal();
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListPickC')]
    procedure PageVar_LookupMode_GetRecord()
    var
        Item: Record "LT P82 Item";
        Picked: Record "LT P82 Item";
        Pg: Page "LT P82 List";
        Result: Action;
    begin
        Seed();
        Observer.Observe('lookupmode-default', Format(Pg.LookupMode()));
        Pg.LookupMode(true);
        Observer.Observe('lookupmode-set', Format(Pg.LookupMode()));
        Item.Get('A');
        Pg.SetRecord(Item);
        Result := Pg.RunModal();
        Observer.Observe('action', Format(Result));
        Pg.GetRecord(Picked);
        Observer.Observe('picked', Picked."No.");
        Observer.Observe('picked-name', Picked.Name);
        Observer.Observe('lookupmode-after', Format(Pg.LookupMode()));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListCancel')]
    procedure PageVar_LookupMode_Cancel_Action()
    var
        Pg: Page "LT P82 List";
        Result: Action;
    begin
        Seed();
        Pg.LookupMode(true);
        Result := Pg.RunModal();
        Observer.Observe('action', Format(Result));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListPickC')]
    procedure PageVar_NotLookupMode_HandlerSees()
    var
        Pg: Page "LT P82 List";
        Result: Action;
    begin
        Seed();
        Result := Pg.RunModal();
        Observer.Observe('action', Format(Result));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardPlain')]
    procedure Run_NumberAndRecord_Modeless()
    var
        Item: Record "LT P82 Item";
    begin
        Seed();
        Item.Get('B');
        Page.Run(Page::"LT P82 Card", Item);
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardPlain')]
    procedure Run_Number_Modeless()
    begin
        Seed();
        Page.Run(Page::"LT P82 Card");
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListPlain')]
    procedure Run_NumberRecordField_Modeless()
    var
        Item: Record "LT P82 Item";
    begin
        Seed();
        Item.Get('C');
        Page.Run(Page::"LT P82 List", Item, Item.FieldNo(Qty));
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardPlain')]
    procedure PageVar_Run_AfterSetRecord()
    var
        Item: Record "LT P82 Item";
        Pg: Page "LT P82 Card";
    begin
        Seed();
        Item.Get('A');
        Pg.SetRecord(Item);
        Pg.Run();
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardPlain')]
    procedure PageVar_Editable_BeforeRun()
    var
        Item: Record "LT P82 Item";
        Pg: Page "LT P82 Card";
    begin
        Seed();
        Item.Get('A');
        Pg.SetRecord(Item);
        Observer.Observe('editable-default', Format(Pg.Editable()));
        Pg.Editable(false);
        Observer.Observe('editable-after-set', Format(Pg.Editable()));
        Pg.Run();
        Observer.Finish();
    end;

    [Test]
    procedure RunModal_UnknownPageNumber()
    begin
        asserterror Page.RunModal(71999);
        Observer.ObserveError('modal-unknown');
        asserterror Page.Run(71999);
        Observer.ObserveError('run-unknown');
        asserterror Page.RunModal(0);
        Observer.ObserveError('modal-zero');
        asserterror Page.Run(-1);
        Observer.ObserveError('run-negative');
        Observer.Finish();
    end;

    [Test]
    procedure RunModal_WithoutHandler()
    var
        Result: Action;
    begin
        Seed();
        asserterror Result := Page.RunModal(Page::"LT P82 List");
        Observer.ObserveError('modal-no-handler');
        asserterror Page.Run(Page::"LT P82 Card");
        Observer.ObserveError('run-no-handler');
        Observer.Finish();
    end;
}
