// Probes: md:97 (GoToKey / GoToRecord scan), md:128 (new row on a page handed a filtered record), md:130 (an action and the pending row),
// md:132 (TestFilter CurrentKey / SetCurrentKey), md:133 (blank row after a filter that matches nothing).

table 69234 "W1 Trg Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer)
        {
            trigger OnValidate()
            var
                Log: Codeunit "W1 Nav Log";
            begin
                Log.Add('table:Id=' + Format(Id));
            end;
        }
        field(2; Parent; Integer)
        {
            trigger OnValidate()
            var
                Log: Codeunit "W1 Nav Log";
            begin
                Log.Add('table:Parent=' + Format(Parent));
            end;
        }
        field(3; Grp; Integer)
        {
            trigger OnValidate()
            var
                Log: Codeunit "W1 Nav Log";
            begin
                Log.Add('table:Grp=' + Format(Grp));
            end;
        }
        field(4; Name; Text[30])
        {
            trigger OnValidate()
            var
                Log: Codeunit "W1 Nav Log";
            begin
                Log.Add('table:Name=' + Name);
            end;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByParent; Parent, Grp) { }
        key(ByName; Name) { }
    }
}

codeunit 69244 "W1 Nav Log"
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

page 69268 "W1 Trg List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Trg Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { }
                field(Parent; Rec.Parent)
                {
                    trigger OnValidate()
                    begin
                        Log.Add('page:Parent=' + Format(Rec.Parent));
                    end;
                }
                field(Grp; Rec.Grp) { }
                field(Name; Rec.Name) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadStored)
            {
                trigger OnAction()
                var
                    Stored: Record "W1 Trg Row";
                begin
                    if Stored.Get(Rec.Id) then
                        Log.Add('stored(' + Format(Rec.Id) + ')=' + Stored.Name)
                    else
                        Log.Add('stored(' + Format(Rec.Id) + ')=none');
                end;
            }
        }
    }

    var
        Log: Codeunit "W1 Nav Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('r' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('c' + Format(Rec.Id));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('OnNewRecord(id=' + Format(Rec.Id) + ',parent=' + Format(Rec.Parent) + ',grp=' + Format(Rec.Grp) + ')');
    end;
}

page 69269 "W1 Trg Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Trg Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(Parent; Rec.Parent)
            {
                trigger OnValidate()
                begin
                    Log.Add('page:Parent=' + Format(Rec.Parent));
                end;
            }
            field(Grp; Rec.Grp) { }
            field(Name; Rec.Name) { }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadStored)
            {
                trigger OnAction()
                var
                    Stored: Record "W1 Trg Row";
                begin
                    if Stored.Get(Rec.Id) then
                        Log.Add('stored(' + Format(Rec.Id) + ')=' + Stored.Name)
                    else
                        Log.Add('stored(' + Format(Rec.Id) + ')=none');
                end;
            }
        }
    }

    var
        Log: Codeunit "W1 Nav Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('r' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('c' + Format(Rec.Id));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('OnNewRecord(id=' + Format(Rec.Id) + ',parent=' + Format(Rec.Parent) + ',grp=' + Format(Rec.Grp) + ')');
    end;
}

codeunit 69302 "W1 Nav Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "W1 Nav Log";

    local procedure Seed(Count: Integer)
    var
        Row: Record "W1 Trg Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to Count do begin
            Row.Init();
            Row.Id := i;
            Row.Parent := 10 - i;
            Row.Grp := (i + 1) div 2;
            Row.Name := 'n' + Format(i);
            Row.Insert();
        end;
        Log.Take();
    end;

    [TryFunction]
    local procedure TryGoToKey(var Pg: TestPage "W1 Trg List"; KeyValue: Integer)
    begin
        Pg.GoToKey(KeyValue);
    end;

    // ---------- md:97 ----------

    [Test]
    procedure GoToKey_List_FiveRows_WhichRowsAreRead()
    var
        Pg: TestPage "W1 Trg List";
        Observer: Codeunit "Probe Observer";
        Found: Boolean;
    begin
        Seed(5);
        Pg.OpenView();
        Observer.Observe('open', Log.Take());
        Found := Pg.GoToKey(4);
        Observer.Observe('goto_4', Format(Found) + ' ' + Log.Take() + ' id=' + Pg.Id.Value());
        Found := Pg.GoToKey(2);
        Observer.Observe('goto_2_back', Format(Found) + ' ' + Log.Take() + ' id=' + Pg.Id.Value());
        Found := Pg.GoToKey(99);
        Observer.Observe('goto_99_miss', Format(Found) + ' ' + Log.Take() + ' id=' + Pg.Id.Value());
        Pg.Close();
        Observer.Expect('open', 'r1;r2;r3;r4;r5;r1;r1;c1;');
        Observer.Expect('goto_4', 'Yes r2;r2;c2;r3;r3;c3;r4;r4;c4; id=4');
        Observer.Expect('goto_2_back', 'Yes r1;r1;c1;r2;r2;c2; id=2');
        Observer.Expect('goto_99_miss', 'No r1;r1;c1;r2;r2;c2;r3;r3;c3;r4;r4;c4;r5;r5;c5;r2;r2;c2; id=2');
        Observer.Verify();
    end;

    [Test]
    procedure GoToKey_List_FiftyRows_RowsReadByAFarJump()
    var
        Pg: TestPage "W1 Trg List";
        Observer: Codeunit "Probe Observer";
        Found: Boolean;
    begin
        Seed(50);
        Pg.OpenView();
        Observer.Observe('open', Log.Take());
        Found := Pg.GoToKey(45);
        Observer.Observe('goto_45', Format(Found) + ' ' + Log.Take());
        Found := Pg.GoToKey(3);
        Observer.Observe('goto_3_back', Format(Found) + ' ' + Log.Take());
        Pg.Close();
        Observer.Expect('open', 'r1;r2;r3;r4;r5;r6;r7;r8;r9;r10;r11;r12;r13;r14;r15;r16;r17;r18;r19;r20;r1;r1;c1;');
        Observer.Expect('goto_45', 'Yes r2;r2;c2;r3;r3;c3;r4;r4;c4;r5;r5;c5;r6;r6;c6;r7;r7;c7;r8;r8;c8;r9;r9;c9;r10;r10;c10;r11;r11;c11;r12;r12;c12;r13;r13;c13;r14;r14;c14;r15;r15;c15;r16;r16;c16;r17;r17;c17;r18;r18;c18;r19;r19;c19;r20;r21;r22;r23;r24;r25;r26;r27;r28;r29;r30;r31;r32;r33;r34;r35;r36;r37;r38;r39;r40;r20;r20;c20;r21;r21;c21;r22;r22;c22;r23;r23;c23;r24;r24;c24;r25;r25;c25;r26;r26;c26;r27;r27;c27;r28;r28;c28;r29;r29;c29;r30;r30;c30;r31;r31;c31;r32;r32;c32;r33;r33;c33;r34;r34;c34;r35;r35;c35;r36;r36;c36;r37;r37;c37;r38;r38;c38;r39;r39;c39;r40;r41;r42;r43;r44;r45;r46;r47;r48;r49;r50;r40;r40;c40;r41;r41;c41;r42;r42;c42;r43;r43;c43;r44;r44;c44;r45;r45;c45;');
        Observer.Expect('goto_3_back', 'Yes r1;r1;c1;r2;r2;c2;r3;r3;c3;');
        Observer.Verify();
    end;

    [Test]
    procedure GoToKey_Card_WhichRowsAreRead()
    var
        Pg: TestPage "W1 Trg Card";
        Observer: Codeunit "Probe Observer";
        Found: Boolean;
    begin
        Seed(5);
        Pg.OpenView();
        Observer.Observe('open', Log.Take());
        Found := Pg.GoToKey(4);
        Observer.Observe('goto_4', Format(Found) + ' ' + Log.Take() + ' id=' + Pg.Id.Value());
        Found := Pg.GoToKey(99);
        Observer.Observe('goto_99_miss', Format(Found) + ' ' + Log.Take() + ' id=' + Pg.Id.Value());
        Found := Pg.GoToKey(2);
        Observer.Observe('goto_2_back', Format(Found) + ' ' + Log.Take() + ' id=' + Pg.Id.Value());
        Pg.Close();
        Observer.Expect('open', 'r1;c1;');
        Observer.Expect('goto_4', 'Yes r1;c1;r2;c2;r3;c3;r4;c4; id=4');
        Observer.Expect('goto_99_miss', 'No r1;c1;r2;c2;r3;c3;r4;c4;r5;c5;r1;c1;r2;c2;r3;c3;r4;c4; id=4');
        Observer.Expect('goto_2_back', 'Yes r1;c1;r2;c2; id=2');
        Observer.Verify();
    end;

    [Test]
    procedure GoToRecord_List_WhichRowsAreRead()
    var
        Pg: TestPage "W1 Trg List";
        Row: Record "W1 Trg Row";
        Missing: Record "W1 Trg Row";
        Observer: Codeunit "Probe Observer";
        Found: Boolean;
    begin
        Seed(5);
        Pg.OpenView();
        Log.Take();
        Row.Get(4);
        Found := Pg.GoToRecord(Row);
        Observer.Observe('gotorecord_4', Format(Found) + ' ' + Log.Take() + ' id=' + Pg.Id.Value());
        Missing.Id := 99;
        Found := Pg.GoToRecord(Missing);
        Observer.Observe('gotorecord_99_miss', Format(Found) + ' ' + Log.Take() + ' id=' + Pg.Id.Value());
        Pg.Close();
        Observer.Expect('gotorecord_4', 'Yes r2;r2;c2;r3;r3;c3;r4;r4;c4; id=4');
        Observer.Expect('gotorecord_99_miss', 'No r1;r1;c1;r2;r2;c2;r3;r3;c3;r4;r4;c4;r5;r5;c5;r4;r4;c4; id=4');
        Observer.Verify();
    end;

    [Test]
    procedure GoToKey_List_FilteredOutKey()
    var
        Pg: TestPage "W1 Trg List";
        Observer: Codeunit "Probe Observer";
        Found: Boolean;
    begin
        Seed(5);
        Pg.OpenView();
        Pg.Filter.SetFilter(Id, '2..4');
        Log.Take();
        Found := Pg.GoToKey(5);
        Observer.Observe('goto_5_outside_filter', Format(Found) + ' ' + Log.Take() + ' id=' + Pg.Id.Value());
        Found := Pg.GoToKey(3);
        Observer.Observe('goto_3_inside_filter', Format(Found) + ' ' + Log.Take() + ' id=' + Pg.Id.Value());
        Pg.Close();
        Observer.Expect('goto_5_outside_filter', 'No r3;r3;c3;r4;r4;c4;r2;r2;c2; id=2');
        Observer.Expect('goto_3_inside_filter', 'Yes r3;r3;c3; id=3');
        Observer.Verify();
    end;

    // ---------- md:128: a page handed a filtered record, then New() in the handler ----------

    [ModalPageHandler]
    procedure NewRowHandler(var Pg: TestPage "W1 Trg List")
    begin
        Log.Add('--- handler opened, first row id=' + Pg.Id.Value());
        Pg.New();
        Log.Add('--- after New: id=' + Pg.Id.Value() + ' parent=' + Pg.Parent.Value() + ' grp=' + Pg.Grp.Value() + ' name=' + Pg.Name.Value());
    end;

    local procedure RunWithFilter(var Filtered: Record "W1 Trg Row"): Text
    begin
        Page.RunModal(Page::"W1 Trg List", Filtered);
        exit(Log.Take());
    end;

    [Test]
    [HandlerFunctions('NewRowHandler')]
    procedure NewRow_PageHandedRecord_NonKeySingleValueFilter()
    var
        Filtered: Record "W1 Trg Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(5);
        Filtered.SetRange(Parent, 9);
        Observer.Observe('parent_9', RunWithFilter(Filtered));
        Observer.Expect('parent_9', 'r1;r1;c1;--- handler opened, first row id=1;OnNewRecord(id=0,parent=0,grp=0);c0;--- after New: id=0 parent=0 grp=0 name=;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NewRowHandler')]
    procedure NewRow_PageHandedRecord_PrimaryKeySingleValueFilter()
    var
        Filtered: Record "W1 Trg Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(5);
        Filtered.SetRange(Id, 3);
        Observer.Observe('id_3', RunWithFilter(Filtered));
        Observer.Expect('id_3', 'r3;r3;c3;--- handler opened, first row id=3;table:Id=3;OnNewRecord(id=3,parent=0,grp=0);c3;--- after New: id=3 parent=0 grp=0 name=;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NewRowHandler')]
    procedure NewRow_PageHandedRecord_TwoSingleValueFilters()
    var
        Filtered: Record "W1 Trg Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(5);
        Filtered.SetRange(Parent, 9);
        Filtered.SetRange(Grp, 1);
        Observer.Observe('parent_9_grp_1', RunWithFilter(Filtered));
        Observer.Expect('parent_9_grp_1', 'r1;r1;c1;--- handler opened, first row id=1;OnNewRecord(id=0,parent=0,grp=0);c0;--- after New: id=0 parent=0 grp=0 name=;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NewRowHandler')]
    procedure NewRow_PageHandedRecord_FilterWithTwoValues()
    var
        Filtered: Record "W1 Trg Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(5);
        Filtered.SetFilter(Parent, '9|8');
        Observer.Observe('parent_9_or_8', RunWithFilter(Filtered));
        Observer.Expect('parent_9_or_8', 'r1;r2;r1;r1;c1;--- handler opened, first row id=1;OnNewRecord(id=0,parent=0,grp=0);c0;--- after New: id=0 parent=0 grp=0 name=;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NewRowHandler')]
    procedure NewRow_PageHandedRecord_FilterOnTextField()
    var
        Filtered: Record "W1 Trg Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(5);
        Filtered.SetRange(Name, 'n2');
        Observer.Observe('name_n2', RunWithFilter(Filtered));
        Observer.Expect('name_n2', 'r2;r2;c2;--- handler opened, first row id=2;OnNewRecord(id=0,parent=0,grp=0);c0;--- after New: id=0 parent=0 grp=0 name=;');
        Observer.Verify();
    end;

    // ---------- md:130: what an action sees of a pending row ----------

    [Test]
    procedure Action_PendingEdit_OnListRow()
    var
        Pg: TestPage "W1 Trg List";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(3);
        Pg.OpenEdit();
        Pg.GoToKey(2);
        Pg.Name.SetValue('dirty');
        Log.Take();
        Pg.ReadStored.Invoke();
        Observer.Observe('action_log', Log.Take());
        Pg.Close();
        Observer.Expect('action_log', 'r2;stored(2)=dirty;r2;r2;r3;r2;r1;r2;r2;c2;');
        Observer.Verify();
    end;

    [Test]
    procedure Action_PendingEdit_OnCard()
    var
        Pg: TestPage "W1 Trg Card";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(3);
        Pg.OpenEdit();
        Pg.GoToKey(2);
        Pg.Name.SetValue('dirty');
        Log.Take();
        Pg.ReadStored.Invoke();
        Observer.Observe('action_log', Log.Take());
        Pg.Close();
        Observer.Expect('action_log', 'r2;stored(2)=dirty;r2;r2;c2;');
        Observer.Verify();
    end;

    [Test]
    procedure Action_PendingNewRow_OnList()
    var
        Pg: TestPage "W1 Trg List";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(3);
        Pg.OpenEdit();
        Pg.New();
        Pg.Id.SetValue(77);
        Pg.Name.SetValue('fresh');
        Log.Take();
        Pg.ReadStored.Invoke();
        Observer.Observe('action_log', Log.Take());
        Pg.Close();
        Observer.Expect('action_log', 'r77;stored(77)=fresh;r77;r77;r3;r2;r1;r77;r77;c77;');
        Observer.Verify();
    end;

    [Test]
    procedure Action_PendingNewRow_OnCard()
    var
        Pg: TestPage "W1 Trg Card";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(3);
        Pg.OpenNew();
        Pg.Id.SetValue(88);
        Pg.Name.SetValue('fresh');
        Log.Take();
        Pg.ReadStored.Invoke();
        Observer.Observe('action_log', Log.Take());
        Pg.Close();
        Observer.Expect('action_log', 'r88;stored(88)=fresh;r88;r88;c88;');
        Observer.Verify();
    end;

    // ---------- md:132: TestFilter CurrentKey / SetCurrentKey ----------

    [TryFunction]
    local procedure TrySetKeyParent(var Pg: TestPage "W1 Trg List")
    begin
        Pg.Filter.SetCurrentKey(Parent);
    end;

    [TryFunction]
    local procedure TrySetKeyParentGrp(var Pg: TestPage "W1 Trg List")
    begin
        Pg.Filter.SetCurrentKey(Parent, Grp);
    end;

    [TryFunction]
    local procedure TrySetKeyGrpParent(var Pg: TestPage "W1 Trg List")
    begin
        Pg.Filter.SetCurrentKey(Grp, Parent);
    end;

    [TryFunction]
    local procedure TrySetKeyNameGrp(var Pg: TestPage "W1 Trg List")
    begin
        Pg.Filter.SetCurrentKey(Name, Grp);
    end;

    [TryFunction]
    local procedure TrySetKeyGrpOnly(var Pg: TestPage "W1 Trg List")
    begin
        Pg.Filter.SetCurrentKey(Grp);
    end;

    [TryFunction]
    local procedure TrySetKeyId(var Pg: TestPage "W1 Trg List")
    begin
        Pg.Filter.SetCurrentKey(Id);
    end;

    local procedure Walk(var Pg: TestPage "W1 Trg List") Seq: Text
    begin
        if not Pg.First() then
            exit('');
        repeat
            Seq += Pg.Id.Value() + ' ';
        until not Pg.Next();
    end;

    [Test]
    procedure TestFilter_CurrentKey_Text()
    var
        Pg: TestPage "W1 Trg List";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(5);
        Pg.OpenView();
        Observer.Observe('key_at_open', Pg.Filter.CurrentKey());
        if TrySetKeyParent(Pg) then
            Observer.Observe('key_after_Parent', Pg.Filter.CurrentKey())
        else
            Observer.ObserveError('set_Parent');
        Observer.Observe('walk_Parent', Walk(Pg));
        if TrySetKeyParentGrp(Pg) then
            Observer.Observe('key_after_Parent_Grp', Pg.Filter.CurrentKey())
        else
            Observer.ObserveError('set_Parent_Grp');
        if TrySetKeyId(Pg) then
            Observer.Observe('key_after_Id', Pg.Filter.CurrentKey())
        else
            Observer.ObserveError('set_Id');
        Pg.Close();
        Observer.Expect('key_at_open', 'Id');
        Observer.Expect('key_after_Parent', 'Parent,Grp');
        Observer.Expect('walk_Parent', '5 4 3 2 1 ');
        Observer.Expect('key_after_Parent_Grp', 'Parent,Grp');
        Observer.Expect('key_after_Id', 'Id');
        Observer.Verify();
    end;

    [Test]
    procedure TestFilter_SetCurrentKey_WithoutAMatchingKey_Grp_Parent()
    var
        Pg: TestPage "W1 Trg List";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(5);
        Pg.OpenView();
        if TrySetKeyGrpParent(Pg) then
            Observer.Observe('Grp_Parent', 'accepted, key=' + Pg.Filter.CurrentKey())
        else
            Observer.ObserveError('Grp_Parent');
        Observer.Observe('walk', Walk(Pg));
        Observer.Observe('key_at_end', Pg.Filter.CurrentKey());
        Pg.Close();
        Observer.Expect('Grp_Parent', 'accepted, key=Grp,Parent');
        Observer.Expect('walk', '2 1 4 3 5 ');
        Observer.Expect('key_at_end', 'Grp,Parent');
        Observer.Verify();
    end;

    [Test]
    procedure TestFilter_SetCurrentKey_WithoutAMatchingKey_Name_Grp()
    var
        Pg: TestPage "W1 Trg List";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(5);
        Pg.OpenView();
        if TrySetKeyNameGrp(Pg) then
            Observer.Observe('Name_Grp', 'accepted, key=' + Pg.Filter.CurrentKey())
        else
            Observer.ObserveError('Name_Grp');
        Observer.Observe('walk', Walk(Pg));
        Observer.Observe('key_at_end', Pg.Filter.CurrentKey());
        Pg.Close();
        Observer.Expect('Name_Grp', 'accepted, key=Name,Grp');
        Observer.Expect('walk', '1 2 3 4 5 ');
        Observer.Expect('key_at_end', 'Name,Grp');
        Observer.Verify();
    end;

    [Test]
    procedure TestFilter_SetCurrentKey_WithoutAMatchingKey_Grp_Only()
    var
        Pg: TestPage "W1 Trg List";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(5);
        Pg.OpenView();
        if TrySetKeyGrpOnly(Pg) then
            Observer.Observe('Grp_only', 'accepted, key=' + Pg.Filter.CurrentKey())
        else
            Observer.ObserveError('Grp_only');
        Observer.Observe('walk', Walk(Pg));
        Observer.Observe('key_at_end', Pg.Filter.CurrentKey());
        Pg.Close();
        Observer.Expect('Grp_only', 'accepted, key=Grp');
        Observer.Expect('walk', '1 2 3 4 5 ');
        Observer.Expect('key_at_end', 'Grp');
        Observer.Verify();
    end;

    [Test]
    procedure TestFilter_Changes_SaveTheRow_AndMoveToTheFirstMatch()
    var
        Pg: TestPage "W1 Trg List";
        Row: Record "W1 Trg Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(5);
        Pg.OpenEdit();
        Pg.GoToKey(3);
        Pg.Name.SetValue('dirty3');
        Log.Take();
        Pg.Filter.SetFilter(Grp, '2..3');
        Observer.Observe('after_filter_log', Log.Take());
        Observer.Observe('after_filter_id', Pg.Id.Value());
        Row.Get(3);
        Observer.Observe('stored_name_3_after_filter', Row.Name);
        Pg.GoToKey(4);
        Pg.Name.SetValue('dirty4');
        Pg.Filter.SetCurrentKey(Parent);
        Observer.Observe('after_setkey_id', Pg.Id.Value());
        Row.Get(4);
        Observer.Observe('stored_name_4_after_setkey', Row.Name);
        Pg.Close();
        Observer.Expect('after_filter_log', 'r3;r4;r5;r3;r3;c3;');
        Observer.Expect('after_filter_id', '3');
        Observer.Expect('stored_name_3_after_filter', 'dirty3');
        Observer.Expect('after_setkey_id', '5');
        Observer.Expect('stored_name_4_after_setkey', 'dirty4');
        Observer.Verify();
    end;

    // ---------- md:133: a filter that leaves the page without a row ----------

    [Test]
    procedure BlankRow_Card_FilterMatchesNothing_KeyFilter()
    var
        Pg: TestPage "W1 Trg Card";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(3);
        Pg.OpenEdit();
        Log.Take();
        Pg.Filter.SetFilter(Id, '90');
        Observer.Observe('log', Log.Take());
        Observer.Observe('id', Pg.Id.Value());
        Observer.Observe('name', Pg.Name.Value());
        Pg.Close();
        Observer.Expect('log', 'table:Id=90;OnNewRecord(id=90,parent=0,grp=0);c90;');
        Observer.Expect('id', '');
        Observer.Expect('name', '');
        Observer.Verify();
    end;

    [Test]
    procedure BlankRow_Card_FilterMatchesNothing_NonKeyFilters()
    var
        Pg: TestPage "W1 Trg Card";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(3);
        Pg.OpenEdit();
        Log.Take();
        Pg.Filter.SetFilter(Parent, '90');
        Observer.Observe('log', Log.Take());
        Observer.Observe('id', Pg.Id.Value());
        Observer.Observe('parent', Pg.Parent.Value());
        Observer.Observe('grp', Pg.Grp.Value());
        Pg.Filter.SetFilter(Grp, '91');
        Observer.Observe('log2', Log.Take());
        Observer.Observe('parent2', Pg.Parent.Value());
        Observer.Observe('grp2', Pg.Grp.Value());
        Pg.Close();
        Observer.Expect('log', 'OnNewRecord(id=0,parent=0,grp=0);c0;');
        Observer.Expect('id', '');
        Observer.Expect('parent', '');
        Observer.Expect('grp', '');
        Observer.Expect('log2', 'OnNewRecord(id=0,parent=0,grp=0);c0;');
        Observer.Expect('parent2', '');
        Observer.Expect('grp2', '');
        Observer.Verify();
    end;

    [Test]
    procedure BlankRow_Card_FilterMatchesNothing_RangeFilter()
    var
        Pg: TestPage "W1 Trg Card";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(3);
        Pg.OpenEdit();
        Log.Take();
        Pg.Filter.SetFilter(Id, '90..95');
        Observer.Observe('log_range', Log.Take());
        Observer.Observe('id_range', Pg.Id.Value());
        Pg.Filter.SetFilter(Id, '90|91');
        Observer.Observe('log_or', Log.Take());
        Observer.Observe('id_or', Pg.Id.Value());
        Pg.Close();
        Observer.Expect('log_range', 'OnNewRecord(id=0,parent=0,grp=0);c0;');
        Observer.Expect('id_range', '');
        Observer.Expect('log_or', 'OnNewRecord(id=0,parent=0,grp=0);c0;');
        Observer.Expect('id_or', '');
        Observer.Verify();
    end;

    [Test]
    procedure BlankRow_List_FilterMatchesNothing_SingleValue()
    var
        Pg: TestPage "W1 Trg List";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(3);
        Pg.OpenEdit();
        Log.Take();
        Pg.Filter.SetFilter(Parent, '90');
        Observer.Observe('log', Log.Take());
        Observer.Observe('id', Pg.Id.Value());
        Observer.Observe('parent', Pg.Parent.Value());
        Observer.Observe('first', Format(Pg.First()));
        Observer.Observe('id_after_first', Pg.Id.Value());
        Observer.Observe('parent_after_first', Pg.Parent.Value());
        Pg.Close();
        Observer.Expect('log', 'OnNewRecord(id=0,parent=0,grp=0);c0;OnNewRecord(id=0,parent=0,grp=0);c0;');
        Observer.Expect('id', '0');
        Observer.Expect('parent', '0');
        Observer.Expect('first', 'No');
        Observer.Expect('id_after_first', '0');
        Observer.Expect('parent_after_first', '0');
        Observer.Verify();
    end;
}
