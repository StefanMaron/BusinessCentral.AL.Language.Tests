// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT PnG List (70135), LT PnG Card (70134), LT PnG Item (70130), LT PnG Log (70133)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md rows 82 (TestPage: CurrPage.Update outside SetValue/action schedules no re-read; a list that loses its only row after an action without Update), 83 (the re-read keeps the client's unsaved edits) and 89 (a repeater row keeps the buffer OnAfterGetRecord left; xRec of such a row)
// Facts: trigger logs (AGR / AGCR) of open with and without CurrPage.Update in OnOpenPage, of modify / delete actions with and without Update, of an edited unsaved field followed by Update, of an OnAfterGetRecord buffer edit
// BC versions: 29 (27 and 28 by CI)

codeunit 70177 "LT PnG Refresh"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Rows: Integer)
    var
        Item: Record "LT PnG Item";
        i: Integer;
    begin
        Item.DeleteAll();
        for i := 1 to Rows do begin
            Item.Init();
            Item."No." := 'U' + Format(i);
            Item.Name := 'Upd ' + Format(i);
            Item.Qty := i;
            Item.Insert();
        end;
    end;

    [Test]
    procedure ListOpenWithAndWithoutUpdateInOnOpenPage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
    begin
        Seed(3);
        Log.Reset();
        List.OpenView();
        Observer.Observe('plain-open', Log.Dump());
        List.Close();
        Log.Reset();
        Log.SetFlag('ListUpdateInOpen', true);
        List.OpenView();
        Observer.Observe('update-in-open', Log.Dump());
        List.Close();
        Log.SetFlag('ListUpdateInOpen', false);
        Observer.Expect('plain-open', 'List.OnInit;List.OnOpenPage;List.AGR(U1,Upd 1);List.AGR(U2,Upd 2);List.AGR(U3,Upd 3);List.AGR(U1,Upd 1);List.AGR(U1,Upd 1);List.AGCR(U1,)');
        Observer.Expect('update-in-open', 'List.OnInit;List.OnOpenPage;List.AGR(U1,Upd 1);List.AGR(U2,Upd 2);List.AGR(U3,Upd 3);List.AGR(U1,Upd 1);List.AGR(U1,Upd 1);List.AGCR(U1,)');
        Observer.Verify();
    end;

    [Test]
    procedure CardOpenWithAndWithoutUpdateInOnOpenPage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Card: TestPage "LT PnG Card";
    begin
        Seed(2);
        Log.Reset();
        Card.OpenView();
        Observer.Observe('plain-open', Log.Dump());
        Card.Close();
        Log.Reset();
        Log.SetFlag('CardUpdateInOpen', true);
        Card.OpenView();
        Observer.Observe('update-in-open', Log.Dump());
        Card.Close();
        Log.SetFlag('CardUpdateInOpen', false);
        Observer.Expect('plain-open', 'Card.OnInit;Card.OnOpenPage;Card.AGR(U1,Upd 1);Card.AGCR(U1,Upd 1)');
        Observer.Expect('update-in-open', 'Card.OnInit;Card.OnOpenPage;Card.AGR(U1,Upd 1);Card.AGCR(U1,Upd 1)');
        Observer.Verify();
    end;

    [Test]
    procedure ListModifyWithAndWithoutUpdate()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
    begin
        Seed(3);
        List.OpenEdit();
        List.GoToKey('U2');
        Log.Reset();
        List.ModifyNoUpdate.Invoke();
        Observer.Observe('no-update-name', List.NameCtl.Value());
        Observer.Observe('no-update-log', Log.Dump());
        List.GoToKey('U3');
        Log.Reset();
        List.ModifyWithUpdate.Invoke();
        Observer.Observe('update-name', List.NameCtl.Value());
        Observer.Observe('update-log', Log.Dump());
        List.Close();
        Observer.Expect('no-update-name', 'Changed');
        Observer.Expect('no-update-log', 'List.AGR(U2,Upd 2);List.AGR(U2,Changed);List.AGR(U2,Changed);List.AGR(U3,Upd 3);List.AGR(U2,Changed);List.AGR(U1,Upd 1);List.AGR(U2,Changed);List.AGR(U2,Changed);List.AGCR(U2,U2)');
        Observer.Expect('update-name', 'Changed');
        Observer.Expect('update-log', 'List.AGR(U3,Upd 3);List.AGR(U3,Changed);List.AGR(U3,Changed);List.AGR(U2,Changed);List.AGR(U1,Upd 1);List.AGR(U3,Changed);List.AGR(U3,Changed);List.AGCR(U3,U3)');
        Observer.Verify();
    end;

    [Test]
    procedure ListLosesOnlyRowDeleteNoUpdate()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
    begin
        Seed(1);
        List.OpenEdit();
        Log.Reset();
        List.DeleteNoUpdate.Invoke();
        Observer.Observe('stored', Format(Item.Count()));
        Observer.Observe('first', Format(List.First()));
        Observer.Observe('log', Log.Dump());
        List.Close();
        Observer.Expect('stored', '0');
        Observer.Expect('first', 'No');
        Observer.Expect('log', 'List.AGR(U1,Upd 1);List.OnNewRecord;List.AGCR(,);List.OnNewRecord;List.AGCR(,);List.OnNewRecord;List.AGCR(,)');
        Observer.Verify();
    end;

    [Test]
    procedure ListLosesOnlyRowDeleteWithUpdate()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
    begin
        Seed(1);
        List.OpenEdit();
        Log.Reset();
        List.DeleteWithUpdate.Invoke();
        Observer.Observe('stored', Format(Item.Count()));
        Observer.Observe('first', Format(List.First()));
        Observer.Observe('log', Log.Dump());
        List.Close();
        Observer.Expect('stored', '0');
        Observer.Expect('first', 'No');
        Observer.Expect('log', 'List.AGR(U1,Upd 1);List.OnNewRecord;List.AGCR(,);List.OnNewRecord;List.AGCR(,);List.OnNewRecord;List.AGCR(,)');
        Observer.Verify();
    end;

    [Test]
    procedure ListLosesOneOfTwoRowsWithoutUpdate()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
    begin
        Seed(2);
        List.OpenEdit();
        List.GoToKey('U1');
        Log.Reset();
        List.DeleteNoUpdate.Invoke();
        Observer.Observe('current-after', List.NoCtl.Value());
        Observer.Observe('first', Format(List.First()));
        Observer.Observe('first-no', List.NoCtl.Value());
        Observer.Observe('next', Format(List.Next()));
        Observer.Observe('log', Log.Dump());
        List.Close();
        Observer.Expect('current-after', 'U2');
        Observer.Expect('first', 'Yes');
        Observer.Expect('first-no', 'U2');
        Observer.Expect('next', 'Yes');
        Observer.Expect('log', 'List.AGR(U1,Upd 1);List.AGR(U2,Upd 2);List.AGR(U2,Upd 2);List.AGCR(U2,U1);List.AGR(U2,Upd 2);List.AGR(U2,Upd 2);List.AGCR(U2,U2);List.OnNewRecord;List.AGCR(,)');
        Observer.Verify();
    end;

    [Test]
    procedure UpdateKeepsUnsavedEditOfTheRow()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        Log: Codeunit "LT PnG Log";
        Card: TestPage "LT PnG Card";
    begin
        Seed(2);
        Card.OpenEdit();
        Log.Reset();
        Card.NameCtl.SetValue('Edited by client');
        Observer.Observe('log-after-setvalue', Log.Dump());
        Item.Get('U1');
        Observer.Observe('stored-after-setvalue', Item.Name);
        Log.Reset();
        Card.UpdateOnly.Invoke();
        Observer.Observe('name-after-update', Card.NameCtl.Value());
        Observer.Observe('log-after-update', Log.Dump());
        Item.Get('U1');
        Observer.Observe('stored-after-update', Item.Name);
        Card.Close();
        Item.Get('U1');
        Observer.Observe('stored-after-close', Item.Name);
        Observer.Expect('log-after-setvalue', 'TblVal(U1,Edited by client)');
        Observer.Expect('stored-after-setvalue', 'Upd 1');
        Observer.Expect('name-after-update', 'Edited by client');
        Observer.Expect('log-after-update', 'Card.AGR(U1,Edited by client);Card.AGR(U1,Edited by client);Card.AGR(U1,Edited by client);Card.AGCR(U1,Edited by client)');
        Observer.Expect('stored-after-update', 'Edited by client');
        Observer.Expect('stored-after-close', 'Edited by client');
        Observer.Verify();
    end;

    [Test]
    procedure UpdateWithSaveKeepsEditOfTheRow()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        Log: Codeunit "LT PnG Log";
        Card: TestPage "LT PnG Card";
    begin
        Seed(2);
        Card.OpenEdit();
        Card.QtyCtl.SetValue(77);
        Log.Reset();
        Card.UpdateAndSave.Invoke();
        Observer.Observe('qty-after-update', Card.QtyCtl.Value());
        Item.Get('U1');
        Observer.Observe('stored-qty-after-update', Format(Item.Qty));
        Observer.Observe('log', Log.Dump());
        Card.Close();
        Observer.Expect('qty-after-update', '77');
        Observer.Expect('stored-qty-after-update', '77');
        Observer.Expect('log', 'Card.AGR(U1,Upd 1);Card.AGR(U1,Upd 1);Card.AGR(U1,Upd 1);Card.AGCR(U1,Upd 1)');
        Observer.Verify();
    end;

    [Test]
    procedure BufferEditOfOnAfterGetRecordOnAList()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
    begin
        Seed(3);
        Log.SetFlag('ListBufferEdit', true);
        Log.Reset();
        List.OpenView();
        Observer.Observe('first-name', List.NameCtl.Value());
        Observer.Observe('open-log', Log.Dump());
        Observer.Observe('next', Format(List.Next()));
        Observer.Observe('second-name', List.NameCtl.Value());
        Item.Get('U2');
        Observer.Observe('stored-second-name', Item.Name);
        Item.Name := 'Changed elsewhere';
        Item.Modify();
        Log.Reset();
        Observer.Observe('goto-first', Format(List.GoToKey('U1')));
        Observer.Observe('goto-first-name', List.NameCtl.Value());
        Observer.Observe('goto-log', Log.Dump());
        Log.Reset();
        Observer.Observe('goto-second', Format(List.GoToKey('U2')));
        Observer.Observe('second-name-after-change', List.NameCtl.Value());
        Observer.Observe('second-log', Log.Dump());
        Log.SetFlag('ListBufferEdit', false);
        List.Close();
        Observer.Expect('first-name', 'Upd 1');
        Observer.Expect('open-log', 'List.OnInit;List.OnOpenPage;List.AGR(U1,Upd 1);List.AGR(U2,Upd 2);List.AGR(U3,Upd 3);List.AGR(U1,Upd 1);List.AGR(U1,Upd 1);List.AGCR(U1,)');
        Observer.Expect('next', 'Yes');
        Observer.Expect('second-name', 'Upd 2');
        Observer.Expect('stored-second-name', 'Upd 2');
        Observer.Expect('goto-first', 'Yes');
        Observer.Expect('goto-first-name', 'Upd 1');
        Observer.Expect('goto-log', 'List.AGR(U1,Upd 1);List.AGR(U1,Upd 1);List.AGCR(U1,U2)');
        Observer.Expect('goto-second', 'Yes');
        Observer.Expect('second-name-after-change', 'Changed elsewhere');
        Observer.Expect('second-log', 'List.AGR(U2,Changed elsewhere);List.AGR(U2,Changed elsewhere);List.AGCR(U2,U1)');
        Observer.Verify();
    end;

    [Test]
    procedure BufferEditOfOnAfterGetRecordOnACard()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        Log: Codeunit "LT PnG Log";
        Card: TestPage "LT PnG Card";
    begin
        Seed(1);
        Log.SetFlag('CardBufferEdit', true);
        Log.Reset();
        Card.OpenEdit();
        Observer.Observe('name', Card.NameCtl.Value());
        Observer.Observe('log', Log.Dump());
        Card.QtyCtl.SetValue(9);
        Item.Get('U1');
        Observer.Observe('stored-name', Item.Name);
        Observer.Observe('stored-qty', Format(Item.Qty));
        Observer.Observe('name-after-qty', Card.NameCtl.Value());
        Log.SetFlag('CardBufferEdit', false);
        Card.Close();
        Observer.Expect('name', 'Upd 1');
        Observer.Expect('log', 'Card.OnInit;Card.OnOpenPage;Card.AGR(U1,Upd 1);Card.AGCR(U1,Upd 1)');
        Observer.Expect('stored-name', 'Upd 1');
        Observer.Expect('stored-qty', '1');
        Observer.Expect('name-after-qty', 'Upd 1');
        Observer.Verify();
    end;

    // ---- Writer QL (2026-10-21), al-runtime-rs PR 387: a list action that puts another row into Rec (Rec := Other with changed fields),
    // then Close or the page stays open; a list filtered in filter group 2 to one template and batch that loses its only row to an action.
    // Fixtures: misc/lt-probes-needed-7/PnGQlFixtures.al. ----

    local procedure SeedQlRows()
    var
        Row: Record "LT QL Act Row";
        Log: Codeunit "LT PnG Log";
    begin
        Row.DeleteAll();
        Row."No." := 'A';
        Row.Name := 'orig A';
        Row.Qty := 1;
        Row.Insert();
        Row."No." := 'B';
        Row.Name := 'orig B';
        Row.Qty := 2;
        Row.Insert();
        Row."No." := 'C';
        Row.Name := 'orig C';
        Row.Qty := 3;
        Row.Insert();
        Log.Reset();
    end;

    local procedure QlRows(): Text
    var
        Row: Record "LT QL Act Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                if Result <> '' then
                    Result += ' ';
                Result += Row."No." + ':' + Row.Name + ',' + Format(Row.Qty);
            until Row.Next() = 0;
        exit(Result);
    end;

    local procedure QlTake(): Text
    var
        Log: Codeunit "LT PnG Log";
        Result: Text;
    begin
        Result := Log.Dump();
        Log.Reset();
        exit(Result);
    end;

    [Test]
    procedure QL_RecAssign_OtherChanged_ThenClose()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QL Act List";
    begin
        SeedQlRows();
        List.OpenEdit();
        Observer.Observe('log-open', QlTake());
        List.TakeOtherChanged.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('shown-after-action', List.NoF.Value() + ',' + List.NameF.Value());
        Observer.Observe('stored-after-action', QlRows());
        Observer.Observe('close-ok', Format(TryCloseQlList(List)));
        Observer.ObserveError('close');
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlRows());
        Observer.Finish();
    end;

    [Test]
    procedure QL_RecAssign_OtherChangedUpdate_ThenClose()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QL Act List";
    begin
        SeedQlRows();
        List.OpenEdit();
        Observer.Observe('log-open', QlTake());
        List.TakeOtherChangedUpdate.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('shown-after-action', List.NoF.Value() + ',' + List.NameF.Value());
        Observer.Observe('stored-after-action', QlRows());
        Observer.Observe('close-ok', Format(TryCloseQlList(List)));
        Observer.ObserveError('close');
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlRows());
        Observer.Finish();
    end;

    [Test]
    procedure QL_RecAssign_TempChanged_ThenClose()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QL Act List";
    begin
        SeedQlRows();
        List.OpenEdit();
        Observer.Observe('log-open', QlTake());
        List.TakeTempChanged.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('shown-after-action', List.NoF.Value() + ',' + List.NameF.Value());
        Observer.Observe('stored-after-action', QlRows());
        Observer.Observe('close-ok', Format(TryCloseQlList(List)));
        Observer.ObserveError('close');
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlRows());
        Observer.Finish();
    end;

    [Test]
    procedure QL_RecAssign_OtherUnchanged_ThenClose()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QL Act List";
    begin
        SeedQlRows();
        List.OpenEdit();
        Observer.Observe('log-open', QlTake());
        List.TakeOtherUnchanged.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('shown-after-action', List.NoF.Value() + ',' + List.NameF.Value());
        Observer.Observe('stored-after-action', QlRows());
        Observer.Observe('close-ok', Format(TryCloseQlList(List)));
        Observer.ObserveError('close');
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlRows());
        Observer.Finish();
    end;

    [Test]
    procedure QL_RecAssign_OwnRowChanged_ThenClose()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QL Act List";
    begin
        SeedQlRows();
        List.OpenEdit();
        Observer.Observe('log-open', QlTake());
        List.ChangeOwnRow.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('shown-after-action', List.NoF.Value() + ',' + List.NameF.Value());
        Observer.Observe('stored-after-action', QlRows());
        Observer.Observe('close-ok', Format(TryCloseQlList(List)));
        Observer.ObserveError('close');
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlRows());
        Observer.Finish();
    end;

    [Test]
    procedure QL_RecAssign_OtherChanged_StaysOpen_Next()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QL Act List";
    begin
        SeedQlRows();
        List.OpenEdit();
        QlTake();
        List.TakeOtherChanged.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('next', Format(List.Next()));
        Observer.Observe('log-next', QlTake());
        Observer.Observe('shown-after-next', List.NoF.Value() + ',' + List.NameF.Value());
        Observer.Observe('stored-after-next', QlRows());
        Observer.Observe('first', Format(List.First()));
        Observer.Observe('log-first', QlTake());
        Observer.Observe('shown-after-first', List.NoF.Value() + ',' + List.NameF.Value());
        Observer.Observe('close-ok', Format(TryCloseQlList(List)));
        Observer.ObserveError('close');
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlRows());
        Observer.Finish();
    end;

    [Test]
    procedure QL_RecAssign_TempChanged_StaysOpen_Next()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QL Act List";
    begin
        SeedQlRows();
        List.OpenEdit();
        QlTake();
        List.TakeTempChanged.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('next', Format(List.Next()));
        Observer.Observe('log-next', QlTake());
        Observer.Observe('shown-after-next', List.NoF.Value() + ',' + List.NameF.Value());
        Observer.Observe('stored-after-next', QlRows());
        Observer.Observe('first', Format(List.First()));
        Observer.Observe('log-first', QlTake());
        Observer.Observe('shown-after-first', List.NoF.Value() + ',' + List.NameF.Value());
        Observer.Observe('close-ok', Format(TryCloseQlList(List)));
        Observer.ObserveError('close');
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlRows());
        Observer.Finish();
    end;

    [Test]
    procedure QL_RecAssign_OtherChanged_CloseInAction()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QL Act List";
    begin
        SeedQlRows();
        List.OpenEdit();
        QlTake();
        List.TakeOtherChangedClose.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('stored-after-action', QlRows());
        Observer.Observe('close-ok', Format(TryCloseQlList(List)));
        Observer.ObserveError('close');
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlRows());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryCloseQlList(var List: TestPage "LT QL Act List")
    begin
        List.Close();
    end;

    local procedure SeedQlJournal(WithOnlyRow: Boolean)
    var
        Line: Record "LT QL Jnl Line";
        Log: Codeunit "LT PnG Log";
    begin
        Line.DeleteAll();
        Line.Template := 'T1';
        Line.Batch := 'B2';
        Line."Line No." := 10000;
        Line.Descr := 'other batch';
        Line.Insert();
        Line.Template := 'T2';
        Line.Batch := 'B1';
        Line."Line No." := 10000;
        Line.Descr := 'other template';
        Line.Insert();
        if WithOnlyRow then begin
            Line.Template := 'T1';
            Line.Batch := 'B1';
            Line."Line No." := 10000;
            Line.Descr := 'only';
            Line.Insert();
        end;
        Log.Reset();
    end;

    local procedure QlJournal(): Text
    var
        Line: Record "LT QL Jnl Line";
        Result: Text;
    begin
        if Line.FindSet() then
            repeat
                if Result <> '' then
                    Result += ' ';
                Result += Line.Template + '/' + Line.Batch + '/' + Format(Line."Line No.") + ':' + Line.Descr;
            until Line.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure QL_Jnl_SheetFG2_DeleteNoUpdate_OnlyRow()
    var
        Observer: Codeunit "Probe Observer";
        Jnl: TestPage "LT QL Jnl Sheet FG2";
    begin
        SeedQlJournal(true);
        Jnl.OpenEdit();
        Observer.Observe('log-open', QlTake());
        Jnl.DeleteNoUpdate.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('shown-after-action', Jnl.TemplateF.Value() + '/' + Jnl.BatchF.Value() + '/' + Jnl.LineNoF.Value() + ':' + Jnl.DescrF.Value());
        Observer.Observe('stored-after-action', QlJournal());
        Jnl.DescrF.SetValue('typed');
        Observer.Observe('log-typed', QlTake());
        Observer.Observe('shown-after-typed', Jnl.TemplateF.Value() + '/' + Jnl.BatchF.Value() + '/' + Jnl.LineNoF.Value() + ':' + Jnl.DescrF.Value());
        Jnl.Close();
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlJournal());
        Observer.Finish();
    end;

    [Test]
    procedure QL_Jnl_SheetFG2_DeleteWithUpdate_OnlyRow()
    var
        Observer: Codeunit "Probe Observer";
        Jnl: TestPage "LT QL Jnl Sheet FG2";
    begin
        SeedQlJournal(true);
        Jnl.OpenEdit();
        Observer.Observe('log-open', QlTake());
        Jnl.DeleteWithUpdate.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('shown-after-action', Jnl.TemplateF.Value() + '/' + Jnl.BatchF.Value() + '/' + Jnl.LineNoF.Value() + ':' + Jnl.DescrF.Value());
        Observer.Observe('stored-after-action', QlJournal());
        Jnl.DescrF.SetValue('typed');
        Observer.Observe('log-typed', QlTake());
        Observer.Observe('shown-after-typed', Jnl.TemplateF.Value() + '/' + Jnl.BatchF.Value() + '/' + Jnl.LineNoF.Value() + ':' + Jnl.DescrF.Value());
        Jnl.Close();
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlJournal());
        Observer.Finish();
    end;

    [Test]
    procedure QL_Jnl_ListFG2_DeleteWithUpdate_OnlyRow()
    var
        Observer: Codeunit "Probe Observer";
        Jnl: TestPage "LT QL Jnl List FG2";
    begin
        SeedQlJournal(true);
        Jnl.OpenEdit();
        Observer.Observe('log-open', QlTake());
        Jnl.DeleteWithUpdate.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('shown-after-action', Jnl.TemplateF.Value() + '/' + Jnl.BatchF.Value() + '/' + Jnl.LineNoF.Value() + ':' + Jnl.DescrF.Value());
        Observer.Observe('stored-after-action', QlJournal());
        Jnl.DescrF.SetValue('typed');
        Observer.Observe('log-typed', QlTake());
        Observer.Observe('shown-after-typed', Jnl.TemplateF.Value() + '/' + Jnl.BatchF.Value() + '/' + Jnl.LineNoF.Value() + ':' + Jnl.DescrF.Value());
        Jnl.Close();
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlJournal());
        Observer.Finish();
    end;

    [Test]
    procedure QL_Jnl_SheetFG0_DeleteWithUpdate_OnlyRow()
    var
        Observer: Codeunit "Probe Observer";
        Jnl: TestPage "LT QL Jnl Sheet FG0";
    begin
        SeedQlJournal(true);
        Jnl.OpenEdit();
        Observer.Observe('log-open', QlTake());
        Jnl.DeleteWithUpdate.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('shown-after-action', Jnl.TemplateF.Value() + '/' + Jnl.BatchF.Value() + '/' + Jnl.LineNoF.Value() + ':' + Jnl.DescrF.Value());
        Observer.Observe('stored-after-action', QlJournal());
        Jnl.DescrF.SetValue('typed');
        Observer.Observe('log-typed', QlTake());
        Observer.Observe('shown-after-typed', Jnl.TemplateF.Value() + '/' + Jnl.BatchF.Value() + '/' + Jnl.LineNoF.Value() + ':' + Jnl.DescrF.Value());
        Jnl.Close();
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlJournal());
        Observer.Finish();
    end;

    [Test]
    procedure QL_Jnl_SheetFG2_OpenOnNoRow()
    var
        Observer: Codeunit "Probe Observer";
        Jnl: TestPage "LT QL Jnl Sheet FG2";
    begin
        SeedQlJournal(false);
        Jnl.OpenEdit();
        Observer.Observe('log-open', QlTake());
        Observer.Observe('shown-after-open', Jnl.TemplateF.Value() + '/' + Jnl.BatchF.Value() + '/' + Jnl.LineNoF.Value() + ':' + Jnl.DescrF.Value());
        Jnl.DescrF.SetValue('typed');
        Observer.Observe('log-typed', QlTake());
        Jnl.Close();
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlJournal());
        Observer.Finish();
    end;
}
