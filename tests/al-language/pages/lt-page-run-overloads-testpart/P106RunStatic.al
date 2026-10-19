// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P106 Item/Group/Log tables, LT P106 Log codeunit, pages LT P106 Card / List / Group List from P106Fixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: static Page.Run / Page.RunModal with a page number, a record, a field number, a field (Any) and a FieldRef: returned Action, what the handler sees (current row, rows, caption), trigger order, the record after the call
// BC versions: 29 (27 and 28 by CI)

// Writer BP (corpus issue 664, microsoft/AL issue 5209): Page.RunModal(Number, Record, X) where X is an Integer field of ANOTHER table
// whose value (2) is a field number of the page's table: a field named ...FieldId, a field with another name, and an Integer variable.
table 82566 "LT BP P106 Other"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(40; PickFieldId; Integer) { }
        field(41; PickPlain; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
codeunit 72410 "LT P106 Run Static"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT P106 Log";
        H: Text;
        Mode: Integer;

    local procedure Note(T: Text)
    begin
        if H <> '' then
            H += ';';
        H += T;
    end;

    local procedure Report(var Observer: Codeunit "Probe Observer"; Tag: Text; Act: Action)
    begin
        Observer.Observe(Tag + '_action', Format(Act));
        Observer.Observe(Tag + '_h', H);
        Observer.Observe(Tag + '_log', Log.Dump());
        H := '';
        Log.Reset();
    end;

    local procedure ReportNoAction(var Observer: Codeunit "Probe Observer"; Tag: Text)
    begin
        Observer.Observe(Tag + '_h', H);
        Observer.Observe(Tag + '_log', Log.Dump());
        H := '';
        Log.Reset();
    end;

    [ModalPageHandler]
    procedure ListH(var P: TestPage "LT P106 List")
    var
        Nos: Text;
    begin
        Note('cur=' + P.NoCtl.Value() + '/' + P.NameCtl.Value());
        Note('caption=' + P.Caption());
        if P.First() then
            repeat
                Nos += P.NoCtl.Value();
            until not P.Next();
        Note('rows=' + Nos);
        case Mode of
            0:
                P.OK().Invoke();
            1:
                P.Cancel().Invoke();
            2:
                begin
                    P.GoToKey('C');
                    P.OK().Invoke();
                end;
            3:
                P.ActClose.Invoke();
        end;
    end;

    [ModalPageHandler]
    procedure CardH(var P: TestPage "LT P106 Card")
    begin
        Note('card=' + P.NoCtl.Value() + '/' + P.NameCtl.Value() + '/' + P.QtyCtl.Value());
        case Mode of
            0:
                P.OK().Invoke();
            1:
                P.Cancel().Invoke();
            2:
                begin
                    P.NameCtl.SetValue('Edited');
                    P.OK().Invoke();
                end;
            3:
                P.ActClose.Invoke();
        end;
    end;

    [ModalPageHandler]
    procedure GroupH(var P: TestPage "LT P106 Group List")
    begin
        Note('group=' + P.CodeCtl.Value() + '/' + P.DescrCtl.Value());
        if Mode = 2 then
            P.GoToKey('G3');
        if Mode = 1 then
            P.Cancel().Invoke()
        else
            P.OK().Invoke();
    end;

    [PageHandler]
    procedure ListPlain(var P: TestPage "LT P106 List")
    begin
        Note('plain=' + P.NoCtl.Value() + '/' + P.NameCtl.Value());
    end;

    [PageHandler]
    procedure CardPlain(var P: TestPage "LT P106 Card")
    begin
        Note('plain=' + P.NoCtl.Value() + '/' + P.NameCtl.Value());
    end;

    [PageHandler]
    procedure CardPlainEdit(var P: TestPage "LT P106 Card")
    begin
        Note('plain=' + P.NoCtl.Value() + '/' + P.NameCtl.Value());
        P.NameCtl.SetValue('EditedPlain');
    end;

    // Page.RunModal#6 (Number: Integer, Record: Record, FieldNo: Integer)
    [Test]
    [HandlerFunctions('ListH')]
    procedure P106_RunModal_NumRecFieldNo_List()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P106 Item";
        Act: Action;
    begin
        Log.Seed();
        Mode := 0;
        Item.Get('B');
        Act := Page.RunModal(Page::"LT P106 List", Item, Item.FieldNo(Name));
        Report(Observer, 'name', Act);
        Observer.Observe('rec_after', Item."No." + '/' + Item.Name);
        Mode := 0;
        Act := Page.RunModal(Page::"LT P106 List", Item, Item.FieldNo(Qty));
        Report(Observer, 'qty', Act);
        Mode := 1;
        Act := Page.RunModal(Page::"LT P106 List", Item, Item.FieldNo("No."));
        Report(Observer, 'no_cancel', Act);
        Mode := 3;
        Act := Page.RunModal(Page::"LT P106 List", Item, Item.FieldNo(Grp));
        Report(Observer, 'grp_close', Act);
        Observer.Expect('name_action', 'LookupOK');
        Observer.Expect('name_h', 'cur=B/Beta;caption=LT P106 List Caption;rows=ABCD');
        Observer.Expect('name_log', 'List OnOpenPage filter=;List OnQueryClosePage(LookupOK)');
        Observer.Expect('rec_after', 'D/Delta');
        Observer.Expect('qty_action', 'LookupOK');
        Observer.Expect('qty_h', 'cur=D/Delta;caption=LT P106 List Caption;rows=ABCD');
        Observer.Expect('qty_log', 'List OnOpenPage filter=;List OnQueryClosePage(LookupOK)');
        Observer.Expect('no_cancel_action', 'LookupCancel');
        Observer.Expect('no_cancel_h', 'cur=D/Delta;caption=LT P106 List Caption;rows=ABCD');
        Observer.Expect('no_cancel_log', 'List OnOpenPage filter=;List OnQueryClosePage(LookupCancel)');
        Observer.Expect('grp_close_action', 'LookupCancel');
        Observer.Expect('grp_close_h', 'cur=D/Delta;caption=LT P106 List Caption;rows=ABCD');
        Observer.Expect('grp_close_log', 'List OnOpenPage filter=;List OnQueryClosePage(LookupCancel)');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListH')]
    procedure P106_RunModal_NumRecFieldNo_Pick()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P106 Item";
        Act: Action;
    begin
        Log.Seed();
        Mode := 2;
        Item.Get('A');
        Act := Page.RunModal(Page::"LT P106 List", Item, Item.FieldNo(Name));
        Report(Observer, 'pick', Act);
        Observer.Observe('rec_after', Item."No." + '/' + Item.Name);
        Observer.Observe('rec_count', Format(Item.Count()));
        Observer.Expect('pick_action', 'LookupOK');
        Observer.Expect('pick_h', 'cur=A/Alpha;caption=LT P106 List Caption;rows=ABCD');
        Observer.Expect('pick_log', 'List OnOpenPage filter=;List OnQueryClosePage(LookupOK)');
        Observer.Expect('rec_after', 'C/Gamma');
        Observer.Expect('rec_count', '4');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListH')]
    procedure P106_RunModal_NumRecFieldNo_Filtered()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P106 Item";
        Act: Action;
    begin
        Log.Seed();
        Mode := 0;
        Item.SetRange(Qty, 3);
        Item.FindFirst();
        Act := Page.RunModal(Page::"LT P106 List", Item, Item.FieldNo(Name));
        Report(Observer, 'filtered', Act);
        Observer.Observe('filters_after', Item.GetFilters());
        Item.Reset();
        Item.SetFilter("No.", 'A|B');
        Item.FindLast();
        Act := Page.RunModal(Page::"LT P106 List", Item, Item.FieldNo(Name));
        Report(Observer, 'filtered_ab', Act);
        Item.Reset();
        Act := Page.RunModal(Page::"LT P106 List", Item, Item.FieldNo(Name));
        Report(Observer, 'unpositioned', Act);
        Observer.Expect('filtered_action', 'LookupOK');
        Observer.Expect('filtered_h', 'cur=C/Gamma;caption=LT P106 List Caption;rows=CD');
        Observer.Expect('filtered_log', 'List OnOpenPage filter=Qty: 3;List OnQueryClosePage(LookupOK)');
        Observer.Expect('filters_after', 'Qty: 3');
        Observer.Expect('filtered_ab_action', 'LookupOK');
        Observer.Expect('filtered_ab_h', 'cur=B/Beta;caption=LT P106 List Caption;rows=AB');
        Observer.Expect('filtered_ab_log', 'List OnOpenPage filter=No.: A|B;List OnQueryClosePage(LookupOK)');
        Observer.Expect('unpositioned_action', 'LookupOK');
        Observer.Expect('unpositioned_h', 'cur=B/Beta;caption=LT P106 List Caption;rows=ABCD');
        Observer.Expect('unpositioned_log', 'List OnOpenPage filter=;List OnQueryClosePage(LookupOK)');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardH')]
    procedure P106_RunModal_NumRecFieldNo_Card()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P106 Item";
        Act: Action;
    begin
        Log.Seed();
        Mode := 0;
        Item.Get('C');
        Act := Page.RunModal(Page::"LT P106 Card", Item, Item.FieldNo(Name));
        Report(Observer, 'ok', Act);
        Mode := 1;
        Act := Page.RunModal(Page::"LT P106 Card", Item, Item.FieldNo(Qty));
        Report(Observer, 'cancel', Act);
        Mode := 3;
        Act := Page.RunModal(Page::"LT P106 Card", Item, 0);
        Report(Observer, 'close', Act);
        Observer.Expect('ok_action', 'LookupOK');
        Observer.Expect('ok_h', 'card=C/Gamma/3');
        Observer.Expect('ok_log', 'OnOpenPage;OnAfterGetRecord(C);OnQueryClosePage(LookupOK);OnClosePage');
        Observer.Expect('cancel_action', 'LookupCancel');
        Observer.Expect('cancel_h', 'card=C/Gamma/3');
        Observer.Expect('cancel_log', 'OnOpenPage;OnAfterGetRecord(C);OnAfterGetRecord(C);OnQueryClosePage(LookupCancel);OnClosePage');
        Observer.Expect('close_action', 'LookupCancel');
        Observer.Expect('close_h', 'card=C/Gamma/3');
        Observer.Expect('close_log', 'OnOpenPage;OnAfterGetRecord(C);OnAfterGetRecord(C);OnQueryClosePage(LookupCancel);OnClosePage;OnAfterGetRecord(C)');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardH')]
    procedure P106_RunModal_NumRecFieldNo_CardEdit()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P106 Item";
        Check: Record "LT P106 Item";
        Act: Action;
    begin
        Log.Seed();
        Mode := 2;
        Item.Get('B');
        Act := Page.RunModal(Page::"LT P106 Card", Item, Item.FieldNo(Name));
        Report(Observer, 'edit', Act);
        Observer.Observe('rec_name', Item.Name);
        Check.Get('B');
        Observer.Observe('db_name', Check.Name);
        Item.Get('B');
        Observer.Observe('reget_name', Item.Name);
        Observer.Expect('edit_action', 'LookupOK');
        Observer.Expect('edit_h', 'card=B/Beta/2');
        Observer.Expect('edit_log', 'OnOpenPage;OnAfterGetRecord(B);OnQueryClosePage(LookupOK);OnClosePage');
        Observer.Expect('rec_name', 'Edited');
        Observer.Expect('db_name', 'Edited');
        Observer.Expect('reget_name', 'Edited');
        Observer.Verify();
    end;

    // Page.RunModal#5 (Number, ?Record, ?Field: Any)
    [Test]
    [HandlerFunctions('ListH')]
    procedure P106_RunModal_NumRecFieldAny()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P106 Item";
        Act: Action;
    begin
        Log.Seed();
        Mode := 0;
        Item.Get('B');
        Act := Page.RunModal(Page::"LT P106 List", Item, Item.Name);
        Report(Observer, 'name', Act);
        Act := Page.RunModal(Page::"LT P106 List", Item, Item.Qty);
        Report(Observer, 'qty', Act);
        Act := Page.RunModal(Page::"LT P106 List", Item, Item."No.");
        Report(Observer, 'no', Act);
        Act := Page.RunModal(Page::"LT P106 List", Item);
        Report(Observer, 'rec_only', Act);
        Act := Page.RunModal(Page::"LT P106 List");
        Report(Observer, 'num_only', Act);
        Observer.Expect('name_action', 'LookupOK');
        Observer.Expect('name_h', 'cur=B/Beta;caption=LT P106 List Caption;rows=ABCD');
        Observer.Expect('name_log', 'List OnOpenPage filter=;List OnQueryClosePage(LookupOK)');
        Observer.Expect('qty_action', 'LookupOK');
        Observer.Expect('qty_h', 'cur=D/Delta;caption=LT P106 List Caption;rows=ABCD');
        Observer.Expect('qty_log', 'List OnOpenPage filter=;List OnQueryClosePage(LookupOK)');
        Observer.Expect('no_action', 'LookupOK');
        Observer.Expect('no_h', 'cur=D/Delta;caption=LT P106 List Caption;rows=ABCD');
        Observer.Expect('no_log', 'List OnOpenPage filter=;List OnQueryClosePage(LookupOK)');
        Observer.Expect('rec_only_action', 'LookupOK');
        Observer.Expect('rec_only_h', 'cur=D/Delta;caption=LT P106 List Caption;rows=ABCD');
        Observer.Expect('rec_only_log', 'List OnOpenPage filter=;List OnQueryClosePage(LookupOK)');
        Observer.Expect('num_only_action', 'LookupOK');
        Observer.Expect('num_only_h', 'cur=A/Alpha;caption=LT P106 List Caption;rows=ABCD');
        Observer.Expect('num_only_log', 'List OnOpenPage filter=;List OnQueryClosePage(LookupOK)');
        Observer.Verify();
    end;

    // Page.RunModal#7 (Number: Integer, Record: Record, FieldRef: FieldRef)
    [Test]
    [HandlerFunctions('ListH')]
    procedure P106_RunModal_NumRecFieldRef()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P106 Item";
        RecRef: RecordRef;
        FR: FieldRef;
        Act: Action;
    begin
        Log.Seed();
        Mode := 0;
        Item.Get('B');
        RecRef.GetTable(Item);
        FR := RecRef.Field(Item.FieldNo(Name));
        Act := Page.RunModal(Page::"LT P106 List", Item, FR);
        Report(Observer, 'name', Act);
        FR := RecRef.Field(Item.FieldNo(Qty));
        Act := Page.RunModal(Page::"LT P106 List", Item, FR);
        Report(Observer, 'qty', Act);
        Mode := 1;
        FR := RecRef.Field(Item.FieldNo("No."));
        Act := Page.RunModal(Page::"LT P106 List", Item, FR);
        Report(Observer, 'no_cancel', Act);
        Mode := 3;
        FR := RecRef.Field(Item.FieldNo(Grp));
        Act := Page.RunModal(Page::"LT P106 List", Item, FR);
        Report(Observer, 'grp_close', Act);
        Observer.Expect('name_action', 'LookupOK');
        Observer.Expect('name_h', 'cur=B/Beta;caption=LT P106 List Caption;rows=ABCD');
        Observer.Expect('name_log', 'List OnOpenPage filter=;List OnQueryClosePage(LookupOK)');
        Observer.Expect('qty_action', 'LookupOK');
        Observer.Expect('qty_h', 'cur=D/Delta;caption=LT P106 List Caption;rows=ABCD');
        Observer.Expect('qty_log', 'List OnOpenPage filter=;List OnQueryClosePage(LookupOK)');
        Observer.Expect('no_cancel_action', 'LookupCancel');
        Observer.Expect('no_cancel_h', 'cur=D/Delta;caption=LT P106 List Caption;rows=ABCD');
        Observer.Expect('no_cancel_log', 'List OnOpenPage filter=;List OnQueryClosePage(LookupCancel)');
        Observer.Expect('grp_close_action', 'LookupCancel');
        Observer.Expect('grp_close_h', 'cur=D/Delta;caption=LT P106 List Caption;rows=ABCD');
        Observer.Expect('grp_close_log', 'List OnOpenPage filter=;List OnQueryClosePage(LookupCancel)');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListH')]
    procedure P106_RunModal_NumRecFieldRef_Pick()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P106 Item";
        RecRef: RecordRef;
        FR: FieldRef;
        Act: Action;
    begin
        Log.Seed();
        Mode := 2;
        Item.Get('A');
        RecRef.GetTable(Item);
        FR := RecRef.Field(Item.FieldNo(Name));
        Act := Page.RunModal(Page::"LT P106 List", Item, FR);
        Report(Observer, 'pick', Act);
        Observer.Observe('rec_after', Item."No.");
        Observer.Observe('recref_after', Format(RecRef.Field(1).Value));
        Observer.Observe('fr_value', Format(FR.Value));
        Observer.Expect('pick_action', 'LookupOK');
        Observer.Expect('pick_h', 'cur=A/Alpha;caption=LT P106 List Caption;rows=ABCD');
        Observer.Expect('pick_log', 'List OnOpenPage filter=;List OnQueryClosePage(LookupOK)');
        Observer.Expect('rec_after', 'C');
        Observer.Expect('recref_after', 'A');
        Observer.Expect('fr_value', 'Alpha');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardH')]
    procedure P106_RunModal_NumRecFieldRef_Card()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P106 Item";
        RecRef: RecordRef;
        FR: FieldRef;
        Act: Action;
    begin
        Log.Seed();
        Mode := 0;
        Item.Get('C');
        RecRef.GetTable(Item);
        FR := RecRef.Field(Item.FieldNo(Qty));
        Act := Page.RunModal(Page::"LT P106 Card", Item, FR);
        Report(Observer, 'ok', Act);
        Mode := 2;
        FR := RecRef.Field(Item.FieldNo(Name));
        Act := Page.RunModal(Page::"LT P106 Card", Item, FR);
        Report(Observer, 'edit', Act);
        Observer.Observe('rec_name', Item.Name);
        Observer.Expect('ok_action', 'LookupOK');
        Observer.Expect('ok_h', 'card=C/Gamma/3');
        Observer.Expect('ok_log', 'OnOpenPage;OnAfterGetRecord(C);OnQueryClosePage(LookupOK);OnClosePage');
        Observer.Expect('edit_action', 'LookupOK');
        Observer.Expect('edit_h', 'card=C/Gamma/3');
        Observer.Expect('edit_log', 'OnOpenPage;OnAfterGetRecord(C);OnQueryClosePage(LookupOK);OnClosePage');
        Observer.Expect('rec_name', 'Edited');
        Observer.Verify();
    end;

    // Group list: the lookup page of a related table
    [Test]
    [HandlerFunctions('GroupH')]
    procedure P106_RunModal_Group_Variants()
    var
        Observer: Codeunit "Probe Observer";
        Grp: Record "LT P106 Group";
        RecRef: RecordRef;
        FR: FieldRef;
        Act: Action;
    begin
        Log.Seed();
        Mode := 0;
        Grp.Get('G2');
        Act := Page.RunModal(Page::"LT P106 Group List", Grp, Grp.FieldNo(Code));
        Report(Observer, 'fieldno', Act);
        Act := Page.RunModal(Page::"LT P106 Group List", Grp, Grp.Descr);
        Report(Observer, 'any', Act);
        RecRef.GetTable(Grp);
        FR := RecRef.Field(Grp.FieldNo(Descr));
        Act := Page.RunModal(Page::"LT P106 Group List", Grp, FR);
        Report(Observer, 'fieldref', Act);
        Mode := 2;
        Act := Page.RunModal(Page::"LT P106 Group List", Grp, Grp.FieldNo(Code));
        Report(Observer, 'pick', Act);
        Observer.Observe('grp_after', Grp.Code);
        Observer.Expect('fieldno_action', 'LookupOK');
        Observer.Expect('fieldno_h', 'group=G2/Two');
        Observer.Expect('fieldno_log', 'Group OnOpenPage filter=');
        Observer.Expect('any_action', 'LookupOK');
        Observer.Expect('any_h', 'group=G2/Two');
        Observer.Expect('any_log', 'Group OnOpenPage filter=');
        Observer.Expect('fieldref_action', 'LookupOK');
        Observer.Expect('fieldref_h', 'group=G2/Two');
        Observer.Expect('fieldref_log', 'Group OnOpenPage filter=');
        Observer.Expect('pick_action', 'LookupOK');
        Observer.Expect('pick_h', 'group=G2/Two');
        Observer.Expect('pick_log', 'Group OnOpenPage filter=');
        Observer.Expect('grp_after', 'G3');
        Observer.Verify();
    end;

    // Page.Run#5 (Number: Integer, Record: Record, FieldNo: Integer) and Page.Run#4 (Number, ?Record, ?Field: Any)
    [Test]
    [HandlerFunctions('ListPlain')]
    procedure P106_Run_NumRecFieldNo_List()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P106 Item";
    begin
        Log.Seed();
        Item.Get('C');
        Page.Run(Page::"LT P106 List", Item, Item.FieldNo(Qty));
        ReportNoAction(Observer, 'qty');
        Page.Run(Page::"LT P106 List", Item, Item.FieldNo(Name));
        ReportNoAction(Observer, 'name');
        Page.Run(Page::"LT P106 List", Item, 0);
        ReportNoAction(Observer, 'zero');
        Observer.Expect('qty_h', 'plain=C/Gamma');
        Observer.Expect('qty_log', 'List OnOpenPage filter=;List OnQueryClosePage(OK)');
        Observer.Expect('name_h', 'plain=C/Gamma');
        Observer.Expect('name_log', 'List OnOpenPage filter=;List OnQueryClosePage(OK)');
        Observer.Expect('zero_h', 'plain=C/Gamma');
        Observer.Expect('zero_log', 'List OnOpenPage filter=;List OnQueryClosePage(OK)');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardPlain')]
    procedure P106_Run_NumRecFieldNo_Card()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P106 Item";
    begin
        Log.Seed();
        Item.Get('B');
        Page.Run(Page::"LT P106 Card", Item, Item.FieldNo(Name));
        ReportNoAction(Observer, 'name');
        Observer.Expect('name_h', 'plain=B/Beta');
        Observer.Expect('name_log', 'OnOpenPage;OnAfterGetRecord(B);OnQueryClosePage(OK);OnClosePage');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardPlainEdit')]
    procedure P106_Run_NumRecFieldNo_CardEdit()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P106 Item";
        Check: Record "LT P106 Item";
    begin
        Log.Seed();
        Item.Get('B');
        Page.Run(Page::"LT P106 Card", Item, Item.FieldNo(Name));
        ReportNoAction(Observer, 'edit');
        Observer.Observe('rec_name', Item.Name);
        Check.Get('B');
        Observer.Observe('db_name', Check.Name);
        Observer.Expect('edit_h', 'plain=B/Beta');
        Observer.Expect('edit_log', 'OnOpenPage;OnAfterGetRecord(B);OnQueryClosePage(OK);OnClosePage');
        Observer.Expect('rec_name', 'Beta');
        Observer.Expect('db_name', 'EditedPlain');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListPlain')]
    procedure P106_Run_NumRecFieldAny()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P106 Item";
    begin
        Log.Seed();
        Item.Get('B');
        Page.Run(Page::"LT P106 List", Item, Item.Name);
        ReportNoAction(Observer, 'any_name');
        Page.Run(Page::"LT P106 List", Item);
        ReportNoAction(Observer, 'rec_only');
        Page.Run(Page::"LT P106 List");
        ReportNoAction(Observer, 'num_only');
        Observer.Expect('any_name_h', 'plain=B/Beta');
        Observer.Expect('any_name_log', 'List OnOpenPage filter=;List OnQueryClosePage(OK)');
        Observer.Expect('rec_only_h', 'plain=B/Beta');
        Observer.Expect('rec_only_log', 'List OnOpenPage filter=;List OnQueryClosePage(OK)');
        Observer.Expect('num_only_h', 'plain=A/Alpha');
        Observer.Expect('num_only_log', 'List OnOpenPage filter=;List OnQueryClosePage(OK)');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListPlain,CardPlain')]
    procedure P106_Run_LiteralNumbers()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P106 Item";
    begin
        Log.Seed();
        Item.Get('C');
        Page.Run(72401, Item, 2);
        ReportNoAction(Observer, 'list_fieldno');
        Page.Run(72400, Item, 1);
        ReportNoAction(Observer, 'card_fieldno');
        Page.Run(72401, Item);
        ReportNoAction(Observer, 'list_rec');
        Observer.Expect('list_fieldno_h', 'plain=C/Gamma');
        Observer.Expect('list_fieldno_log', 'List OnOpenPage filter=;List OnQueryClosePage(OK)');
        Observer.Expect('card_fieldno_h', 'plain=C/Gamma');
        Observer.Expect('card_fieldno_log', 'OnOpenPage;OnAfterGetRecord(C);OnQueryClosePage(OK);OnClosePage');
        Observer.Expect('list_rec_h', 'plain=C/Gamma');
        Observer.Expect('list_rec_log', 'List OnOpenPage filter=;List OnQueryClosePage(OK)');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListH')]
    procedure P106_RunModal_LiteralNumbers()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P106 Item";
        Act: Action;
    begin
        Log.Seed();
        Mode := 0;
        Item.Get('A');
        Act := Page.RunModal(72401, Item, 2);
        Report(Observer, 'lit_fieldno', Act);
        Act := Page.RunModal(72401, Item);
        Report(Observer, 'lit_rec', Act);
        Act := Page.RunModal(72401);
        Report(Observer, 'lit_num', Act);
        Observer.Expect('lit_fieldno_action', 'LookupOK');
        Observer.Expect('lit_fieldno_h', 'cur=A/Alpha;caption=LT P106 List Caption;rows=ABCD');
        Observer.Expect('lit_fieldno_log', 'List OnOpenPage filter=;List OnQueryClosePage(LookupOK)');
        Observer.Expect('lit_rec_action', 'LookupOK');
        Observer.Expect('lit_rec_h', 'cur=D/Delta;caption=LT P106 List Caption;rows=ABCD');
        Observer.Expect('lit_rec_log', 'List OnOpenPage filter=;List OnQueryClosePage(LookupOK)');
        Observer.Expect('lit_num_action', 'LookupOK');
        Observer.Expect('lit_num_h', 'cur=A/Alpha;caption=LT P106 List Caption;rows=ABCD');
        Observer.Expect('lit_num_log', 'List OnOpenPage filter=;List OnQueryClosePage(LookupOK)');
        Observer.Verify();
    end;

    // Writer BP (corpus issue 664, microsoft/AL issue 5209).
    [Test]
    [HandlerFunctions('ListH')]
    procedure P106_BP_RunModal_IntegerFieldOfAnotherTable()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P106 Item";
        Other: Record "LT BP P106 Other";
        Act: Action;
    begin
        Log.Seed();
        Mode := 0;
        Other.PickFieldId := 2;
        Other.PickPlain := 2;
        Item.Get('B');
        ClearLastError();
        Observer.Observe('field named FieldId ok', Format(TryRunModal(Item, Other, 1, Act)));
        Observer.ObserveError('field named FieldId');
        Report(Observer, 'field named FieldId', Act);
        Item.Get('B');
        Observer.Observe('field other name ok', Format(TryRunModal(Item, Other, 2, Act)));
        Observer.ObserveError('field other name');
        Report(Observer, 'field other name', Act);
        Item.Get('B');
        Observer.Observe('integer variable ok', Format(TryRunModal(Item, Other, 3, Act)));
        Observer.ObserveError('integer variable');
        Report(Observer, 'integer variable', Act);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryRunModal(var Item: Record "LT P106 Item"; Other: Record "LT BP P106 Other"; Which: Integer; var Act: Action)
    var
        I: Integer;
    begin
        case Which of
            1:
                Act := Page.RunModal(Page::"LT P106 List", Item, Other.PickFieldId);
            2:
                Act := Page.RunModal(Page::"LT P106 List", Item, Other.PickPlain);
            3:
                begin
                    I := Other.PickFieldId;
                    Act := Page.RunModal(Page::"LT P106 List", Item, I);
                end;
        end;
    end;
}
