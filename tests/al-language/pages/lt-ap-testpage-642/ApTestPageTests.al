// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 79600, log codeunit 79601, pages 79610-79619 (ApObjects.al)
// Settles corpus issue 642 (TestPage behavior, part 3), items 1-18. The log tokens are listed at the top of ApObjects.al.

codeunit 79650 "LT AP TestPage Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        HandlerFilter: Text;

    local procedure Seed()
    var
        Row: Record "LT AP Row";
    begin
        Row.DeleteAll();
        AddRow('A', 'Alpha', true, 'G1');
        AddRow('B', 'Beta', false, 'G1');
        AddRow('C', 'Charlie', true, 'G2');
        AddRow('D', 'Delta', false, 'G2');
    end;

    local procedure AddRow(NewCode: Code[20]; NewName: Text[50]; NewFlag: Boolean; NewGrp: Code[10])
    var
        Row: Record "LT AP Row";
    begin
        Row.Init();
        Row."Code" := NewCode;
        Row.Name := NewName;
        Row.Flag := NewFlag;
        Row.Grp := NewGrp;
        Row.Txt := 'txt';
        Row.Insert();
    end;

    local procedure Rows(var P: TestPage "LT AP List"): Text
    var
        Result: Text;
    begin
        if P.First() then
            repeat
                Result += P."Code".Value() + ',';
            until not P.Next();
        exit(Result);
    end;

    local procedure Start()
    var
        Log: Codeunit "LT AP Log";
    begin
        Clear(Observer);
        Log.Take();
    end;

    // ---- item 1: a part page with a group named Page and a part page with a field named Page; CurrPage.Part.Page.Proc() ----

    [Test]
    procedure Ap01_PartPage_ControlNamedPage()
    var
        Log: Codeunit "LT AP Log";
        Host: TestPage "LT AP Host";
    begin
        Start();
        Seed();
        Host.OpenView();
        Host.GoToKey('B');
        Log.Take();
        Host.CallG.Invoke();
        Host.CallF.Invoke();
        Observer.Observe('log', Log.Take());
        Observer.Observe('g-name', Host.PartG.Name.Value());
        Observer.Observe('f-page', Host.PartF."Page".Value());
        Host.Close();
        Observer.Finish();
    end;

    // ---- item 2: OpenNew, Filter.SetFilter on a key field / a non-key field, then SetValue on a non-key field ----

    local procedure Stored(Prefix: Text)
    var
        Row: Record "LT AP Row";
    begin
        Observer.Observe(Prefix + '-count', Format(Row.Count()));
        if Row.FindFirst() then
            Observer.Observe(Prefix + '-row', Row."Code" + '|' + Row.Name + '|' + Row.Grp);
    end;

    [Test]
    procedure Ap02_OpenNew_KeyFilter_SetValue()
    var
        Row: Record "LT AP Row";
        Log: Codeunit "LT AP Log";
        P: TestPage "LT AP List";
    begin
        Start();
        Row.DeleteAll();
        P.OpenNew();
        Observer.Observe('open', Log.Take());
        P.Filter.SetFilter("Code", 'K1');
        Observer.Observe('filter', Log.Take());
        Observer.Observe('code-on-page', P."Code".Value());
        P.Name.SetValue('typed');
        Observer.Observe('setvalue', Log.Take());
        Stored('sv');
        P.Close();
        Observer.Observe('close', Log.Take());
        Stored('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Ap02_OpenNew_NonKeyFilter_SetValue()
    var
        Row: Record "LT AP Row";
        Log: Codeunit "LT AP Log";
        P: TestPage "LT AP List";
    begin
        Start();
        Row.DeleteAll();
        P.OpenNew();
        Observer.Observe('open', Log.Take());
        P.Filter.SetFilter(Grp, 'G7');
        Observer.Observe('filter', Log.Take());
        Observer.Observe('grp-on-page', P.Grp.Value());
        P.Name.SetValue('typed');
        Observer.Observe('setvalue', Log.Take());
        Stored('sv');
        P.Close();
        Observer.Observe('close', Log.Take());
        Stored('closed');
        Observer.Finish();
    end;

    // ---- item 3: an empty list shows a row inserted by page code; reads of the action and of First() apart ----

    [Test]
    procedure Ap03_EmptyList_RowInsertedByAction()
    var
        Row: Record "LT AP Row";
        Log: Codeunit "LT AP Log";
        P: TestPage "LT AP List";
    begin
        Start();
        Row.DeleteAll();
        P.OpenEdit();
        Observer.Observe('open', Log.Take());
        P.InsertViaRec.Invoke();
        Observer.Observe('action', Log.Take());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first-log', Log.Take());
        Observer.Observe('code', P."Code".Value());
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next-log', Log.Take());
        P.Close();
        Observer.Observe('close', Log.Take());
        Observer.Finish();
    end;

    // ---- item 4: Filter.SetFilter on a Boolean field (non-modal list) and a Text field filter on a modal list ----

    local procedure BoolFilter(Word: Text)
    var
        P: TestPage "LT AP List";
    begin
        P.OpenView();
        P.Filter.SetFilter(Flag, Word);
        Observer.Observe(Word + '-filter', P.Filter.GetFilter(Flag));
        Observer.Observe(Word + '-rows', Rows(P));
        P.Close();
    end;

    [Test]
    procedure Ap04_BooleanFilter_NonModalList()
    begin
        Start();
        Seed();
        BoolFilter('Yes');
        BoolFilter('No');
        BoolFilter('true');
        BoolFilter('false');
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure FilterModalHandler(var P: TestPage "LT AP List")
    begin
        Observer.Observe('before', Rows(P));
        P.Filter.SetFilter(Name, HandlerFilter);
        Observer.Observe('filter', P.Filter.GetFilter(Name));
        Observer.Observe('after', Rows(P));
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('FilterModalHandler')]
    procedure Ap04_TextFilter_ModalList()
    var
        Row: Record "LT AP Row";
    begin
        Start();
        Seed();
        HandlerFilter := 'B*|D*';
        Page.RunModal(Page::"LT AP List", Row);
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure BoolModalHandler(var P: TestPage "LT AP List")
    begin
        P.Filter.SetFilter(Flag, HandlerFilter);
        Observer.Observe(HandlerFilter + '-filter', P.Filter.GetFilter(Flag));
        Observer.Observe(HandlerFilter + '-rows', Rows(P));
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('BoolModalHandler')]
    procedure Ap04_BooleanFilter_ModalList()
    var
        Row: Record "LT AP Row";
    begin
        Start();
        Seed();
        HandlerFilter := 'Yes';
        Page.RunModal(Page::"LT AP List", Row);
        HandlerFilter := 'false';
        Page.RunModal(Page::"LT AP List", Row);
        Observer.Finish();
    end;

    // ---- item 5: Page.RunModal over a temporary record: reads, where New() rows go ----

    [ModalPageHandler]
    procedure TempNewHandler(var P: TestPage "LT AP List")
    var
        Log: Codeunit "LT AP Log";
    begin
        Observer.Observe('h-open', Log.Take());
        Observer.Observe('h-cur', P."Code".Value());
        Observer.Observe('h-rows', Rows(P));
        Observer.Observe('h-walk', Log.Take());
        P.First();
        P.New();
        P."Code".SetValue('T4');
        P.Name.SetValue('n4');
        P.New();
        P."Code".SetValue('T0');
        P.Name.SetValue('n0');
        Observer.Observe('h-new', Log.Take());
        Observer.Observe('h-rows2', Rows(P));
        Log.Take();
        P.OK().Invoke();
        Observer.Observe('h-ok', Log.Take());
    end;

    [Test]
    [HandlerFunctions('TempNewHandler')]
    procedure Ap05_RunModal_TempRecord_NewRows()
    var
        Temp: Record "LT AP Row" temporary;
        Log: Codeunit "LT AP Log";
        Shown: Text;
    begin
        Start();
        Seed();
        Temp."Code" := 'T1';
        Temp.Name := 't1';
        Temp.Insert();
        Temp."Code" := 'T3';
        Temp.Name := 't3';
        Temp.Insert();
        Temp."Code" := 'T5';
        Temp.Name := 't5';
        Temp.Insert();
        Observer.Observe('result', Format(Page.RunModal(Page::"LT AP List", Temp)));
        Observer.Observe('after', Log.Take());
        Temp.Reset();
        if Temp.FindSet() then
            repeat
                Shown += Temp."Code" + ',';
            until Temp.Next() = 0;
        Observer.Observe('temp', Shown);
        Observer.Finish();
    end;

    // ---- item 6: the same OnValidate error on a card, a list and a list part ----

    [Test]
    procedure Ap06_ValidationError_Card()
    var
        P: TestPage "LT AP Card";
    begin
        Start();
        Seed();
        P.OpenEdit();
        P.GoToKey('A');
        asserterror P.Val.SetValue('BAD');
        Observer.ObserveError('card');
        Observer.Finish();
    end;

    [Test]
    procedure Ap06_ValidationError_List()
    var
        P: TestPage "LT AP List";
    begin
        Start();
        Seed();
        P.OpenEdit();
        P.GoToKey('A');
        asserterror P.Val.SetValue('BAD');
        Observer.ObserveError('list');
        Observer.Finish();
    end;

    [Test]
    procedure Ap06_ValidationError_ListPart()
    var
        P: TestPage "LT AP Host";
    begin
        Start();
        Seed();
        P.OpenEdit();
        P.GoToKey('A');
        asserterror P.PartF.Val.SetValue('BAD');
        Observer.ObserveError('listpart');
        Observer.Finish();
    end;

    // ---- items 7 and 18: ShowMandatory of Text and Code fields with and without NotBlank, and of page variables ----

    local procedure Mand(var P: TestPage "LT AP Card"; Name: Text)
    begin
        Observer.Observe(Name, 'Txt=' + Format(P.Txt.ShowMandatory()) + ' Cd=' + Format(P.Cd.ShowMandatory()) +
            ' TxtNB=' + Format(P.TxtNB.ShowMandatory()) + ' CdNB=' + Format(P.CdNB.ShowMandatory()) +
            ' VarTxt=' + Format(P.VarTxt.ShowMandatory()) + ' VarCd=' + Format(P.VarCd.ShowMandatory()));
    end;

    local procedure SeedMand()
    var
        Row: Record "LT AP Row";
    begin
        Row.DeleteAll();
        Row."Code" := 'V';
        Row.Txt := 'x';
        Row.Cd := 'X';
        Row.TxtNB := 'x';
        Row.CdNB := 'X';
        Row.Insert();
        Row.Init();
        Row."Code" := 'E';
        Row.Insert();
    end;

    [Test]
    procedure Ap07_ShowMandatory_OpenEdit()
    var
        P: TestPage "LT AP Card";
    begin
        Start();
        SeedMand();
        P.OpenEdit();
        P.GoToKey('V');
        Mand(P, 'value');
        P.GoToKey('E');
        Mand(P, 'blank');
        P.VarTxt.SetValue('x');
        P.VarCd.SetValue('X');
        Mand(P, 'vars-set');
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Ap07_ShowMandatory_OpenView()
    var
        P: TestPage "LT AP Card";
    begin
        Start();
        SeedMand();
        P.OpenView();
        P.GoToKey('V');
        Mand(P, 'value');
        P.GoToKey('E');
        Mand(P, 'blank');
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Ap07_ShowMandatory_OpenNew()
    var
        P: TestPage "LT AP Card";
    begin
        Start();
        SeedMand();
        P.OpenNew();
        Mand(P, 'new');
        P.Close();
        Observer.Finish();
    end;

    // ---- item 8: SetValue on a page with ModifyAllowed = false ----

    [TryFunction]
    local procedure TrySetName(var P: TestPage "LT AP NoModify Card"; V: Text)
    begin
        P.Name.SetValue(V);
    end;

    [TryFunction]
    local procedure TrySetCode(var P: TestPage "LT AP NoModify Card"; V: Text)
    begin
        P."Code".SetValue(V);
    end;

    [Test]
    procedure Ap08_ModifyAllowedFalse_StoredRow()
    var
        Row: Record "LT AP Row";
        P: TestPage "LT AP NoModify Card";
    begin
        Start();
        Seed();
        P.OpenEdit();
        P.GoToKey('A');
        Observer.Observe('editable', Format(P.Name.Editable()));
        if TrySetName(P, 'changed') then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        Observer.Observe('value', P.Name.Value());
        P.Close();
        Row.Get('A');
        Observer.Observe('stored', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure Ap08_ModifyAllowedFalse_NewRow()
    var
        Row: Record "LT AP Row";
        P: TestPage "LT AP NoModify Card";
    begin
        Start();
        Seed();
        P.OpenNew();
        Observer.Observe('editable', Format(P.Name.Editable()));
        if TrySetCode(P, 'NM1') then
            Observer.Observe('set-code', 'ok')
        else
            Observer.ObserveError('set-code');
        if TrySetName(P, 'new') then
            Observer.Observe('set-name', 'ok')
        else
            Observer.ObserveError('set-name');
        Observer.Observe('value', P.Name.Value());
        P.Close();
        Observer.Observe('stored', Format(Row.Get('NM1')) + '|' + Row.Name);
        Observer.Finish();
    end;

    // ---- item 9: Ratio control text ----

    local procedure RatioRow(NewCode: Code[20]; V: Decimal)
    var
        Row: Record "LT AP Row";
    begin
        Row.Init();
        Row."Code" := NewCode;
        Row.Rt := V;
        Row.Insert();
    end;

    [Test]
    procedure Ap09_RatioValue()
    var
        Row: Record "LT AP Row";
        P: TestPage "LT AP Card";
    begin
        Start();
        Row.DeleteAll();
        RatioRow('R1', 0.5);
        RatioRow('R2', 1);
        RatioRow('R3', 12.5);
        RatioRow('R4', 0.25);
        RatioRow('R5', -0.5);
        RatioRow('R6', 0.333);
        P.OpenView();
        P.GoToKey('R1');
        Observer.Observe('0.5', P.RtF.Value());
        P.GoToKey('R2');
        Observer.Observe('1', P.RtF.Value());
        P.GoToKey('R3');
        Observer.Observe('12.5', P.RtF.Value());
        P.GoToKey('R4');
        Observer.Observe('0.25', P.RtF.Value());
        P.GoToKey('R5');
        Observer.Observe('-0.5', P.RtF.Value());
        P.GoToKey('R6');
        Observer.Observe('0.333', P.RtF.Value());
        P.Close();
        Observer.Finish();
    end;

    // ---- item 10: SetSelectionFilter on a list whose filter hides every row of a table that has rows ----

    [Test]
    procedure Ap10_SetSelectionFilter_FilterHidesAll_TestPageFilter()
    var
        Log: Codeunit "LT AP Log";
        P: TestPage "LT AP List";
    begin
        Start();
        Seed();
        P.OpenView();
        P.Filter.SetFilter("Code", 'ZZZ');
        Observer.Observe('first', Format(P.First()));
        Log.Take();
        P.SelFilter.Invoke();
        Observer.Observe('log', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Ap10_SetSelectionFilter_FilterHidesAll_RunWithFilter()
    var
        Row: Record "LT AP Row";
        Log: Codeunit "LT AP Log";
        P: TestPage "LT AP List";
    begin
        Start();
        Seed();
        Row.SetFilter(Grp, 'G9');
        P.Trap();
        Page.Run(Page::"LT AP List", Row);
        Log.Take();
        P.SelFilter.Invoke();
        Observer.Observe('log', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    // ---- item 11: CurrPage.SaveRecord and CurrPage.Update in one action ----

    [Test]
    procedure Ap11_SaveRecordAndUpdate()
    var
        Row: Record "LT AP Row";
        Log: Codeunit "LT AP Log";
        P: TestPage "LT AP Card";
    begin
        Start();
        Seed();
        P.OpenEdit();
        P.GoToKey('A');
        P.Name.SetValue('edited');
        Observer.Observe('before', Log.Take());
        P.SaveUpd.Invoke();
        Observer.Observe('action', Log.Take());
        Row.Get('A');
        Observer.Observe('stored', Row.Name);
        P.Close();
        Observer.Observe('close', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Ap11_SaveRecordAndUpdateFalse()
    var
        Row: Record "LT AP Row";
        Log: Codeunit "LT AP Log";
        P: TestPage "LT AP Card";
    begin
        Start();
        Seed();
        P.OpenEdit();
        P.GoToKey('A');
        P.Name.SetValue('edited');
        Observer.Observe('before', Log.Take());
        P.SaveUpdF.Invoke();
        Observer.Observe('action', Log.Take());
        Row.Get('A');
        Observer.Observe('stored', Row.Name);
        P.Close();
        Observer.Observe('close', Log.Take());
        Observer.Finish();
    end;

    // ---- items 5 and 12: a Page variable with SetRecord of a temporary record whose key is before, between or after the table's keys ----

    [ModalPageHandler]
    procedure CurrentRowHandler(var P: TestPage "LT AP List")
    var
        Log: Codeunit "LT AP Log";
    begin
        Observer.Observe('h-open', Log.Take());
        Observer.Observe('h-cur', P."Code".Value() + '|' + P.Name.Value());
        Observer.Observe('h-rows', Rows(P));
        P.OK().Invoke();
    end;

    local procedure SetRecordTemp(TempCode: Code[20])
    var
        Row: Record "LT AP Row";
        Temp: Record "LT AP Row" temporary;
        Pg: Page "LT AP List";
    begin
        Row.DeleteAll();
        AddRow('B', 'db-b', false, '');
        AddRow('D', 'db-d', false, '');
        AddRow('F', 'db-f', false, '');
        Temp."Code" := TempCode;
        Temp.Name := 'temp';
        Temp.Insert();
        Pg.SetRecord(Temp);
        Pg.RunModal();
    end;

    [Test]
    [HandlerFunctions('CurrentRowHandler')]
    procedure Ap12_PageVar_SetRecordTemp_KeyBetween()
    begin
        Start();
        SetRecordTemp('C');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CurrentRowHandler')]
    procedure Ap12_PageVar_SetRecordTemp_KeyBefore()
    begin
        Start();
        SetRecordTemp('A');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CurrentRowHandler')]
    procedure Ap12_PageVar_SetRecordTemp_KeyAfter()
    begin
        Start();
        SetRecordTemp('G');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CurrentRowHandler')]
    procedure Ap12_PageVar_SetRecordTemp_KeyEqual()
    begin
        Start();
        SetRecordTemp('D');
        Observer.Finish();
    end;

    // ---- item 13: Cancel().Invoke() on a card and on a list that declare only OnAfterGetCurrRecord ----

    [ModalPageHandler]
    procedure CancelCardHandler(var P: TestPage "LT AP Cancel Card")
    var
        Log: Codeunit "LT AP Log";
    begin
        Observer.Observe('h-open', Log.Take());
        P.Cancel().Invoke();
        Observer.Observe('h-cancel', Log.Take());
    end;

    [ModalPageHandler]
    procedure CancelListHandler(var P: TestPage "LT AP Cancel List")
    var
        Log: Codeunit "LT AP Log";
    begin
        Observer.Observe('h-open', Log.Take());
        P.Cancel().Invoke();
        Observer.Observe('h-cancel', Log.Take());
    end;

    [Test]
    [HandlerFunctions('CancelCardHandler')]
    procedure Ap13_Cancel_Card_OnlyAfterGetCurrRecord()
    var
        Row: Record "LT AP Row";
        Log: Codeunit "LT AP Log";
    begin
        Start();
        Seed();
        Row.Get('B');
        Observer.Observe('result', Format(Page.RunModal(Page::"LT AP Cancel Card", Row)));
        Observer.Observe('after', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CancelListHandler')]
    procedure Ap13_Cancel_List_OnlyAfterGetCurrRecord()
    var
        Row: Record "LT AP Row";
        Log: Codeunit "LT AP Log";
    begin
        Start();
        Seed();
        Row.Get('B');
        Observer.Observe('result', Format(Page.RunModal(Page::"LT AP Cancel List", Row)));
        Observer.Observe('after', Log.Take());
        Observer.Finish();
    end;

    // ---- item 14: CaptionML in German only, English session (and a German one) ----

    [Test]
    procedure Ap14_CaptionML_GermanOnly()
    var
        P: TestPage "LT AP Caption DE";
        OldLanguage: Integer;
    begin
        Start();
        Seed();
        OldLanguage := GlobalLanguage();
        Observer.Observe('lang', Format(OldLanguage));
        P.OpenView();
        Observer.Observe('en-page', P.Caption());
        Observer.Observe('en-field', P.Name.Caption());
        P.Close();
        GlobalLanguage(1031);
        P.OpenView();
        Observer.Observe('de-page', P.Caption());
        Observer.Observe('de-field', P.Name.Caption());
        P.Close();
        GlobalLanguage(OldLanguage);
        Observer.Finish();
    end;

    // ---- item 15: SetSelectionFilter into a record that already has marks ----

    [Test]
    procedure Ap15_SetSelectionFilter_IntoMarkedRecord()
    var
        Log: Codeunit "LT AP Log";
        P: TestPage "LT AP List";
    begin
        Start();
        Seed();
        P.OpenView();
        P.GoToKey('C');
        Log.Take();
        P.SelMarks.Invoke();
        Observer.Observe('marks', Log.Take());
        P.SelMarksOnly.Invoke();
        Observer.Observe('marked-only', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    // ---- item 16: a field in a group with Enabled = false on a card page ----

    [TryFunction]
    local procedure TrySetQty(var P: TestPage "LT AP Card"; V: Decimal)
    begin
        P.Qty.SetValue(V);
    end;

    [Test]
    procedure Ap16_GroupEnabledFalse_Card()
    var
        Row: Record "LT AP Row";
        P: TestPage "LT AP Card";
    begin
        Start();
        Seed();
        P.OpenEdit();
        P.GoToKey('A');
        Observer.Observe('edit-enabled', Format(P.Qty.Enabled()));
        Observer.Observe('edit-editable', Format(P.Qty.Editable()));
        Observer.Observe('edit-visible', Format(P.Qty.Visible()));
        Observer.Observe('name-enabled', Format(P.Name.Enabled()));
        if TrySetQty(P, 5) then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        P.Close();
        Row.Get('A');
        Observer.Observe('stored', Format(Row.Qty));
        P.OpenView();
        P.GoToKey('A');
        Observer.Observe('view-enabled', Format(P.Qty.Enabled()));
        Observer.Observe('view-editable', Format(P.Qty.Editable()));
        P.Close();
        Observer.Finish();
    end;

    // ---- item 17: NotBlank on a list and on a page without a row; Masked under 11 characters; Numeric with other non-digits ----

    [Test]
    procedure Ap17_NotBlank_List()
    var
        P: TestPage "LT AP List";
    begin
        Start();
        Seed();
        P.OpenEdit();
        P.GoToKey('A');
        asserterror P.NameNB.SetValue('');
        Observer.ObserveError('list-blank');
        Observer.Finish();
    end;

    [Test]
    procedure Ap17_NotBlank_CardOnEmptyTable()
    var
        Row: Record "LT AP Row";
        P: TestPage "LT AP Card";
    begin
        Start();
        Row.DeleteAll();
        P.OpenEdit();
        Observer.Observe('code', P."Code".Value());
        asserterror P.NBF.SetValue('');
        Observer.ObserveError('empty-blank');
        Observer.Finish();
    end;

    [Test]
    procedure Ap17_NotBlank_PageWithoutSourceTable()
    var
        P: TestPage "LT AP NoSource";
    begin
        Start();
        P.OpenEdit();
        P.VarNB.SetValue('x');
        asserterror P.VarNB.SetValue('');
        Observer.ObserveError('nosource-blank');
        Observer.Finish();
    end;

    local procedure MaskRow(NewCode: Code[20]; V: Text[30])
    var
        Row: Record "LT AP Row";
    begin
        Row.Init();
        Row."Code" := NewCode;
        Row.Sec := V;
        Row.Insert();
    end;

    [Test]
    procedure Ap17_Masked_ShortTexts()
    var
        Row: Record "LT AP Row";
        P: TestPage "LT AP Card";
    begin
        Start();
        Row.DeleteAll();
        MaskRow('M0', '');
        MaskRow('M1', 'a');
        MaskRow('M5', 'abcde');
        MaskRow('M10', 'abcdefghij');
        MaskRow('M11', 'abcdefghijk');
        MaskRow('M20', 'abcdefghijklmnopqrst');
        P.OpenView();
        P.GoToKey('M0');
        Observer.Observe('0', P.SecF.Value());
        P.GoToKey('M1');
        Observer.Observe('1', P.SecF.Value());
        P.GoToKey('M5');
        Observer.Observe('5', P.SecF.Value());
        P.GoToKey('M10');
        Observer.Observe('10', P.SecF.Value());
        P.GoToKey('M11');
        Observer.Observe('11', P.SecF.Value());
        P.GoToKey('M20');
        Observer.Observe('20', P.SecF.Value());
        P.Close();
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TrySetNum(var P: TestPage "LT AP Card"; V: Text)
    begin
        P.NumF.SetValue(V);
    end;

    local procedure Num(var P: TestPage "LT AP Card"; V: Text)
    begin
        P.NumF.SetValue('0');
        if TrySetNum(P, V) then
            Observer.Observe('[' + V + ']', 'ok:' + P.NumF.Value())
        else
            Observer.Observe('[' + V + ']', 'error:' + GetLastErrorText());
        ClearLastError();
    end;

    [Test]
    procedure Ap17_Numeric_NonDigits()
    var
        P: TestPage "LT AP Card";
    begin
        Start();
        Seed();
        P.OpenEdit();
        P.GoToKey('A');
        Num(P, '12-3');
        Num(P, '-5');
        Num(P, '+5');
        Num(P, '1.5');
        Num(P, '1,5');
        Num(P, '1 2');
        Num(P, '#1');
        Num(P, '');
        P.Close();
        Observer.Finish();
    end;
}
