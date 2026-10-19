// Probes: md:134 (SourceTableTemporary page), md:135 (CurrPage.Update outside SetValue/action; a list that loses its only row),
// md:136 (re-read after CurrPage.Update and unsaved edits), md:137 (CurrPage.Editable outside OnOpenPage), md:150 (buffer left by OnAfterGetRecord).

codeunit 69245 "W1 Upd Log"
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

page 69273 "W1 Upd Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(Name; Rec.Name) { }
            field(Amount; Rec.Amount) { }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UpdateNoSave)
            {
                trigger OnAction()
                begin
                    Log.Add('action UpdateNoSave: rec.name=' + Rec.Name);
                    CurrPage.Update(false);
                    Log.Add('action UpdateNoSave done: rec.name=' + Rec.Name);
                end;
            }
            action(UpdateSave)
            {
                trigger OnAction()
                begin
                    Log.Add('action UpdateSave: rec.name=' + Rec.Name);
                    CurrPage.Update(true);
                    Log.Add('action UpdateSave done: rec.name=' + Rec.Name);
                end;
            }
            action(MemoryThenUpdate)
            {
                trigger OnAction()
                begin
                    Rec.Name := 'memory';
                    CurrPage.Update(false);
                    Log.Add('action MemoryThenUpdate done: rec.name=' + Rec.Name);
                end;
            }
            action(ReadOnly)
            {
                trigger OnAction()
                begin
                    Log.Add('action ReadOnly: rec.name=' + Rec.Name);
                end;
            }
        }
    }

    var
        Log: Codeunit "W1 Upd Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('AGR(' + Format(Rec.Id) + ',' + Rec.Name + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('AGCR(' + Format(Rec.Id) + ',' + Rec.Name + ')');
    end;
}

page 69274 "W1 Upd Open Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(Name; Rec.Name) { }
        }
    }

    var
        Log: Codeunit "W1 Upd Log";

    trigger OnOpenPage()
    begin
        Log.Add('OnOpenPage before Update');
        CurrPage.Update(false);
        Log.Add('OnOpenPage after Update');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('AGR(' + Format(Rec.Id) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('AGCR(' + Format(Rec.Id) + ')');
    end;
}

page 69275 "W1 Upd Agcr Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(Name; Rec.Name) { }
        }
    }

    var
        Log: Codeunit "W1 Upd Log";
        UpdatedOnce: Boolean;

    trigger OnAfterGetRecord()
    begin
        Log.Add('AGR(' + Format(Rec.Id) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('AGCR(' + Format(Rec.Id) + ')');
        if not UpdatedOnce then begin
            UpdatedOnce := true;
            Log.Add('Update inside AGCR');
            CurrPage.Update(false);
            Log.Add('Update inside AGCR returned');
        end;
    end;
}

page 69276 "W1 Upd List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { }
                field(Name; Rec.Name) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteRowNoUpdate)
            {
                trigger OnAction()
                begin
                    Rec.Delete();
                    Log.Add('action DeleteRowNoUpdate done');
                end;
            }
            action(DeleteRowThenUpdate)
            {
                trigger OnAction()
                begin
                    Rec.Delete();
                    CurrPage.Update(false);
                    Log.Add('action DeleteRowThenUpdate done');
                end;
            }
            action(UpdateNoSave)
            {
                trigger OnAction()
                begin
                    Log.Add('action UpdateNoSave: rec.name=' + Rec.Name);
                    CurrPage.Update(false);
                    Log.Add('action UpdateNoSave done: rec.name=' + Rec.Name);
                end;
            }
        }
    }

    var
        Log: Codeunit "W1 Upd Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('r' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('c' + Format(Rec.Id));
    end;
}

page 69277 "W1 Edit Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(Free; Rec.Name) { }
            field(Locked; Rec.Amount) { Editable = false; }
            field(Expr; Rec.Grp) { Editable = EditVar; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EditableFalse)
            {
                trigger OnAction()
                begin
                    CurrPage.Editable(false);
                end;
            }
            action(EditableTrue)
            {
                trigger OnAction()
                begin
                    CurrPage.Editable(true);
                end;
            }
            action(ExprOff)
            {
                trigger OnAction()
                begin
                    EditVar := false;
                end;
            }
            action(ArmAgcr)
            {
                trigger OnAction()
                begin
                    AgcrMakesReadOnly := true;
                end;
            }
        }
    }

    var
        EditVar: Boolean;
        AgcrMakesReadOnly: Boolean;

    trigger OnInit()
    begin
        EditVar := true;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if AgcrMakesReadOnly then
            CurrPage.Editable(false);
    end;
}

page 69278 "W1 Edit Ro Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Row";
    Editable = false;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(Free; Rec.Name) { }
            field(Locked; Rec.Amount) { Editable = false; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EditableTrue)
            {
                trigger OnAction()
                begin
                    CurrPage.Editable(true);
                end;
            }
        }
    }
}

page 69279 "W1 Buffer List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { }
                field(Name; Rec.Name) { }
                field(Amount; Rec.Amount) { }
            }
        }
    }

    var
        Log: Codeunit "W1 Upd Log";

    trigger OnAfterGetRecord()
    begin
        Rec.Amount := Rec.Id * 100;
        Log.Add('r' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('c' + Format(Rec.Id) + ':amount=' + Format(Rec.Amount) + ':x.amount=' + Format(xRec.Amount) + ':x.name=' + xRec.Name);
    end;
}

page 69320 "W1 Temp List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Row";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { }
                field(Name; Rec.Name) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowCount)
            {
                trigger OnAction()
                var
                    Stored: Record "W1 Row";
                begin
                    Log.Add('action: rec.count=' + Format(Rec.Count()) + ' rec.istemporary=' + Format(Rec.IsTemporary()) + ' stored.count=' + Format(Stored.Count()));
                end;
            }
            action(DeleteRow)
            {
                trigger OnAction()
                begin
                    Rec.Delete();
                end;
            }
        }
    }

    var
        Log: Codeunit "W1 Upd Log";

    trigger OnOpenPage()
    begin
        Rec.Init();
        Rec.Id := 1;
        Rec.Name := 'one';
        Rec.Insert();
        Rec.Id := 2;
        Rec.Name := 'two';
        Rec.Insert();
        Rec.Id := 3;
        Rec.Name := 'three';
        Rec.Insert();
        Rec.FindFirst();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('OnModifyRecord(' + Format(Rec.Id) + ',' + Rec.Name + ')');
        exit(true);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('OnInsertRecord(' + Format(Rec.Id) + ',' + Rec.Name + ')');
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Log.Add('OnDeleteRecord(' + Format(Rec.Id) + ')');
        exit(true);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('OnNewRecord');
    end;
}

codeunit 69304 "W1 Update Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "W1 Upd Log";

    local procedure Seed(Count: Integer)
    var
        Row: Record "W1 Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to Count do begin
            Row.Init();
            Row.Id := i;
            Row.Name := 'row' + Format(i);
            Row.Amount := 1;
            Row.Insert();
        end;
        Log.Take();
    end;

    // ---------- md:135 ----------

    [Test]
    procedure Update_InOnOpenPage_Card()
    var
        Pg: TestPage "W1 Upd Open Card";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(2);
        Pg.OpenEdit();
        Observer.Observe('open_log', Log.Take());
        Pg.Close();
        Observer.Expect('open_log', 'OnOpenPage before Update;OnOpenPage after Update;AGR(1);AGCR(1);');
        Observer.Verify();
    end;

    [Test]
    procedure Update_InOnAfterGetCurrRecord_Card()
    var
        Pg: TestPage "W1 Upd Agcr Card";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(2);
        Pg.OpenEdit();
        Observer.Observe('open_log', Log.Take());
        Pg.Next();
        Observer.Observe('next_log', Log.Take());
        Pg.Close();
        Observer.Expect('open_log', 'AGR(1);AGCR(1);Update inside AGCR;Update inside AGCR returned;');
        Observer.Expect('next_log', 'AGR(2);AGCR(2);');
        Observer.Verify();
    end;

    [Test]
    procedure List_ActionDeletesTheOnlyRow_WithoutUpdate()
    var
        Pg: TestPage "W1 Upd List";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(1);
        Pg.OpenView();
        Observer.Observe('open_log', Log.Take());
        Pg.DeleteRowNoUpdate.Invoke();
        Observer.Observe('action_log', Log.Take());
        Observer.Observe('id_after', Pg.Id.Value());
        Observer.Observe('name_after', Pg.Name.Value());
        Observer.Observe('first', Format(Pg.First()));
        Observer.Observe('first_log', Log.Take());
        Pg.Close();
        Observer.Expect('open_log', 'r1;r1;c1;');
        Observer.Expect('action_log', 'r1;action DeleteRowNoUpdate done;');
        Observer.Expect('id_after', '');
        Observer.Expect('name_after', '');
        Observer.Expect('first', 'No');
        Observer.Expect('first_log', '');
        Observer.Verify();
    end;

    [Test]
    procedure List_ActionDeletesTheOnlyRow_ThenUpdates()
    var
        Pg: TestPage "W1 Upd List";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(1);
        Pg.OpenView();
        Log.Take();
        Pg.DeleteRowThenUpdate.Invoke();
        Observer.Observe('action_log', Log.Take());
        Observer.Observe('id_after', Pg.Id.Value());
        Observer.Observe('first', Format(Pg.First()));
        Pg.Close();
        Observer.Expect('action_log', 'r1;action DeleteRowThenUpdate done;');
        Observer.Expect('id_after', '');
        Observer.Expect('first', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure List_ActionDeletesOneOfTwoRows_WithoutUpdate()
    var
        Pg: TestPage "W1 Upd List";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(2);
        Pg.OpenView();
        Log.Take();
        Pg.DeleteRowNoUpdate.Invoke();
        Observer.Observe('action_log', Log.Take());
        Observer.Observe('id_after', Pg.Id.Value());
        Observer.Observe('first', Format(Pg.First()));
        Observer.Observe('id_after_first', Pg.Id.Value());
        Pg.Close();
        Observer.Expect('action_log', 'r1;action DeleteRowNoUpdate done;r2;r2;c2;r2;r2;c2;');
        Observer.Expect('id_after', '2');
        Observer.Expect('first', 'Yes');
        Observer.Expect('id_after_first', '2');
        Observer.Verify();
    end;

    // ---------- md:136 ----------

    [Test]
    procedure Card_UpdateFalse_KeepsTheUnsavedEdit()
    var
        Pg: TestPage "W1 Upd Card";
        Row: Record "W1 Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(2);
        Pg.OpenEdit();
        Pg.Name.SetValue('dirty');
        Log.Take();
        Pg.UpdateNoSave.Invoke();
        Observer.Observe('log', Log.Take());
        Observer.Observe('name_on_page', Pg.Name.Value());
        Row.Get(1);
        Observer.Observe('name_stored', Row.Name);
        Pg.Close();
        Observer.Expect('log', 'AGR(1,dirty);action UpdateNoSave: rec.name=dirty;action UpdateNoSave done: rec.name=dirty;AGR(1,dirty);AGR(1,dirty);AGCR(1,dirty);');
        Observer.Expect('name_on_page', 'dirty');
        Observer.Expect('name_stored', 'dirty');
        Observer.Verify();
    end;

    [Test]
    procedure Card_UpdateTrue_SavesTheEdit()
    var
        Pg: TestPage "W1 Upd Card";
        Row: Record "W1 Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(2);
        Pg.OpenEdit();
        Pg.Name.SetValue('dirty');
        Log.Take();
        Pg.UpdateSave.Invoke();
        Observer.Observe('log', Log.Take());
        Observer.Observe('name_on_page', Pg.Name.Value());
        Row.Get(1);
        Observer.Observe('name_stored', Row.Name);
        Pg.Close();
        Observer.Expect('log', 'AGR(1,dirty);action UpdateSave: rec.name=dirty;action UpdateSave done: rec.name=dirty;AGR(1,dirty);AGR(1,dirty);AGCR(1,dirty);');
        Observer.Expect('name_on_page', 'dirty');
        Observer.Expect('name_stored', 'dirty');
        Observer.Verify();
    end;

    [Test]
    procedure Card_InMemoryChange_ThenUpdateFalse_WithUnsavedEdit()
    var
        Pg: TestPage "W1 Upd Card";
        Row: Record "W1 Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(2);
        Pg.OpenEdit();
        Pg.Name.SetValue('dirty');
        Log.Take();
        Pg.MemoryThenUpdate.Invoke();
        Observer.Observe('log', Log.Take());
        Observer.Observe('name_on_page', Pg.Name.Value());
        Row.Get(1);
        Observer.Observe('name_stored', Row.Name);
        Pg.Close();
        Observer.Expect('log', 'AGR(1,dirty);action MemoryThenUpdate done: rec.name=memory;AGR(1,memory);AGR(1,dirty);AGCR(1,dirty);');
        Observer.Expect('name_on_page', 'dirty');
        Observer.Expect('name_stored', 'dirty');
        Observer.Verify();
    end;

    [Test]
    procedure List_UpdateFalse_KeepsTheUnsavedEdit()
    var
        Pg: TestPage "W1 Upd List";
        Row: Record "W1 Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(3);
        Pg.OpenEdit();
        Pg.GoToKey(2);
        Pg.Name.SetValue('dirty');
        Log.Take();
        Pg.UpdateNoSave.Invoke();
        Observer.Observe('log', Log.Take());
        Observer.Observe('name_on_page', Pg.Name.Value());
        Row.Get(2);
        Observer.Observe('name_stored', Row.Name);
        Pg.Close();
        Observer.Expect('log', 'r2;action UpdateNoSave: rec.name=dirty;action UpdateNoSave done: rec.name=dirty;r2;r2;r3;r2;r1;r2;r2;c2;');
        Observer.Expect('name_on_page', 'dirty');
        Observer.Expect('name_stored', 'dirty');
        Observer.Verify();
    end;

    // ---------- md:137 ----------

    local procedure ObserveEditable(var Observer: Codeunit "Probe Observer"; var Pg: TestPage "W1 Edit Card"; Label: Text)
    begin
        Observer.Observe(Label + '|page', Format(Pg.Editable()));
        Observer.Observe(Label + '|free', Format(Pg.Free.Editable()));
        Observer.Observe(Label + '|locked', Format(Pg.Locked.Editable()));
        Observer.Observe(Label + '|expr', Format(Pg.Expr.Editable()));
    end;

    [Test]
    procedure Editable_FalseAndTrueFromActions()
    var
        Pg: TestPage "W1 Edit Card";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(2);
        Pg.OpenEdit();
        ObserveEditable(Observer, Pg, 'open');
        Pg.EditableFalse.Invoke();
        ObserveEditable(Observer, Pg, 'after_Editable_false');
        Pg.EditableTrue.Invoke();
        ObserveEditable(Observer, Pg, 'after_Editable_true');
        Pg.ExprOff.Invoke();
        ObserveEditable(Observer, Pg, 'after_expr_off');
        Pg.EditableTrue.Invoke();
        ObserveEditable(Observer, Pg, 'after_expr_off_and_Editable_true');
        Pg.Close();
        Observer.Expect('open|page', 'Yes');
        Observer.Expect('open|free', 'Yes');
        Observer.Expect('open|locked', 'No');
        Observer.Expect('open|expr', 'Yes');
        Observer.Expect('after_Editable_false|page', 'Yes');
        Observer.Expect('after_Editable_false|free', 'Yes');
        Observer.Expect('after_Editable_false|locked', 'No');
        Observer.Expect('after_Editable_false|expr', 'Yes');
        Observer.Expect('after_Editable_true|page', 'Yes');
        Observer.Expect('after_Editable_true|free', 'Yes');
        Observer.Expect('after_Editable_true|locked', 'No');
        Observer.Expect('after_Editable_true|expr', 'Yes');
        Observer.Expect('after_expr_off|page', 'Yes');
        Observer.Expect('after_expr_off|free', 'Yes');
        Observer.Expect('after_expr_off|locked', 'No');
        Observer.Expect('after_expr_off|expr', 'No');
        Observer.Expect('after_expr_off_and_Editable_true|page', 'Yes');
        Observer.Expect('after_expr_off_and_Editable_true|free', 'Yes');
        Observer.Expect('after_expr_off_and_Editable_true|locked', 'No');
        Observer.Expect('after_expr_off_and_Editable_true|expr', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Editable_FalseFromOnAfterGetCurrRecord()
    var
        Pg: TestPage "W1 Edit Card";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(2);
        Pg.OpenEdit();
        Pg.ArmAgcr.Invoke();
        ObserveEditable(Observer, Pg, 'armed');
        Pg.Next();
        ObserveEditable(Observer, Pg, 'after_next');
        Pg.Close();
        Observer.Expect('armed|page', 'Yes');
        Observer.Expect('armed|free', 'Yes');
        Observer.Expect('armed|locked', 'No');
        Observer.Expect('armed|expr', 'Yes');
        Observer.Expect('after_next|page', 'Yes');
        Observer.Expect('after_next|free', 'Yes');
        Observer.Expect('after_next|locked', 'No');
        Observer.Expect('after_next|expr', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Editable_TrueOnAPageThatIsNotEditable()
    var
        Pg: TestPage "W1 Edit Ro Card";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(2);
        Pg.OpenEdit();
        Observer.Observe('open|page', Format(Pg.Editable()));
        Observer.Observe('open|free', Format(Pg.Free.Editable()));
        Pg.EditableTrue.Invoke();
        Observer.Observe('after_true|page', Format(Pg.Editable()));
        Observer.Observe('after_true|free', Format(Pg.Free.Editable()));
        Observer.Observe('after_true|locked', Format(Pg.Locked.Editable()));
        Pg.Close();
        Observer.Expect('open|page', 'No');
        Observer.Expect('open|free', 'No');
        Observer.Expect('after_true|page', 'No');
        Observer.Expect('after_true|free', 'No');
        Observer.Expect('after_true|locked', 'No');
        Observer.Verify();
    end;

    // ---------- md:150 ----------

    [Test]
    procedure List_BufferLeftByOnAfterGetRecord_WhileTheRowIsUnchanged()
    var
        Pg: TestPage "W1 Buffer List";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(4);
        Pg.OpenView();
        Observer.Observe('open_log', Log.Take());
        Observer.Observe('amount_row1', Pg.Amount.Value());
        Pg.Next();
        Observer.Observe('next_log', Log.Take());
        Observer.Observe('amount_row2', Pg.Amount.Value());
        Pg.First();
        Observer.Observe('first_log', Log.Take());
        Observer.Observe('amount_row1_again', Pg.Amount.Value());
        Pg.GoToKey(3);
        Observer.Observe('goto3_log', Log.Take());
        Observer.Observe('amount_row3', Pg.Amount.Value());
        Pg.Close();
        Observer.Expect('open_log', 'r1;r2;r3;r4;r1;r1;c1:amount=100:x.amount=0:x.name=;');
        Observer.Expect('amount_row1', '100.00');
        Observer.Expect('next_log', 'r2;r2;c2:amount=200:x.amount=100:x.name=row1;');
        Observer.Expect('amount_row2', '200.00');
        Observer.Expect('first_log', 'r1;r1;c1:amount=100:x.amount=200:x.name=row2;');
        Observer.Expect('amount_row1_again', '100.00');
        Observer.Expect('goto3_log', 'r2;r2;c2:amount=200:x.amount=100:x.name=row1;r3;r3;c3:amount=300:x.amount=200:x.name=row2;');
        Observer.Expect('amount_row3', '300.00');
        Observer.Verify();
    end;

    [Test]
    procedure List_BufferLeftByOnAfterGetRecord_AfterTheStoredRowChanged()
    var
        Pg: TestPage "W1 Buffer List";
        Row: Record "W1 Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(4);
        Pg.OpenView();
        Log.Take();
        Row.Get(2);
        Row.Name := 'changed';
        Row.Amount := 5;
        Row.Modify();
        Pg.GoToKey(2);
        Observer.Observe('goto2_log', Log.Take());
        Observer.Observe('name_row2', Pg.Name.Value());
        Observer.Observe('amount_row2', Pg.Amount.Value());
        Pg.Next();
        Observer.Observe('next_log', Log.Take());
        Pg.Previous();
        Observer.Observe('previous_log', Log.Take());
        Observer.Observe('name_row2_again', Pg.Name.Value());
        Observer.Observe('amount_row2_again', Pg.Amount.Value());
        Pg.Close();
        Observer.Expect('goto2_log', 'r2;r2;c2:amount=200:x.amount=100:x.name=row1;');
        Observer.Expect('name_row2', 'changed');
        Observer.Expect('amount_row2', '200.00');
        Observer.Expect('next_log', 'r3;r3;c3:amount=300:x.amount=200:x.name=changed;');
        Observer.Expect('previous_log', 'r2;r2;c2:amount=200:x.amount=300:x.name=row3;');
        Observer.Expect('name_row2_again', 'changed');
        Observer.Expect('amount_row2_again', '200.00');
        Observer.Verify();
    end;

    // ---------- md:134 ----------

    [Test]
    procedure TempSourcePage_ReadWriteLikeAStoredOne()
    var
        Pg: TestPage "W1 Temp List";
        Stored: Record "W1 Row";
        Observer: Codeunit "Probe Observer";
        Walk: Text;
    begin
        Stored.DeleteAll();
        Log.Take();
        Pg.OpenEdit();
        Observer.Observe('open_log', Log.Take());
        if Pg.First() then
            repeat
                Walk += Pg.Id.Value() + '=' + Pg.Name.Value() + ' ';
            until not Pg.Next();
        Observer.Observe('walk', Walk);
        Pg.GoToKey(2);
        Log.Take();
        Pg.Name.SetValue('edited');
        Pg.Next();
        Observer.Observe('edit_then_next_log', Log.Take());
        Pg.Previous();
        Observer.Observe('name_after_return', Pg.Name.Value());
        Pg.ShowCount.Invoke();
        Observer.Observe('count_log', Log.Take());
        Pg.Close();
        Observer.Observe('stored_count_after_close', Format(Stored.Count()));
        Observer.Expect('open_log', '');
        Observer.Expect('walk', '1=one 2=two 3=three 0= ');
        Observer.Expect('edit_then_next_log', 'OnModifyRecord(2,edited);');
        Observer.Expect('name_after_return', 'edited');
        Observer.Expect('count_log', 'action: rec.count=3 rec.istemporary=Yes stored.count=0;');
        Observer.Expect('stored_count_after_close', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TempSourcePage_NewRowAndDelete()
    var
        Pg: TestPage "W1 Temp List";
        Stored: Record "W1 Row";
        Observer: Codeunit "Probe Observer";
    begin
        Stored.DeleteAll();
        Pg.OpenEdit();
        Log.Take();
        Pg.New();
        Observer.Observe('new_log', Log.Take());
        Pg.Id.SetValue(10);
        Pg.Name.SetValue('added');
        Pg.First();
        Observer.Observe('leave_new_row_log', Log.Take());
        Observer.Observe('goto_10', Format(Pg.GoToKey(10)));
        Observer.Observe('name_10', Pg.Name.Value());
        Pg.DeleteRow.Invoke();
        Observer.Observe('delete_log', Log.Take());
        Observer.Observe('id_after_delete', Pg.Id.Value());
        Observer.Observe('goto_10_after_delete', Format(Pg.GoToKey(10)));
        Pg.ShowCount.Invoke();
        Observer.Observe('count_log', Log.Take());
        Pg.Close();
        Observer.Observe('stored_count_after_close', Format(Stored.Count()));
        Observer.Expect('new_log', 'OnNewRecord;');
        Observer.Expect('leave_new_row_log', 'OnInsertRecord(10,);OnModifyRecord(10,added);');
        Observer.Expect('goto_10', 'Yes');
        Observer.Expect('name_10', 'added');
        Observer.Expect('delete_log', '');
        Observer.Expect('id_after_delete', '1');
        Observer.Expect('goto_10_after_delete', 'No');
        Observer.Expect('count_log', 'OnNewRecord;action: rec.count=3 rec.istemporary=Yes stored.count=0;');
        Observer.Expect('stored_count_after_close', '0');
        Observer.Verify();
    end;
}
