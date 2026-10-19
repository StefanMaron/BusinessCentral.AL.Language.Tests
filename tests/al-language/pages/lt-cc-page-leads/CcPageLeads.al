// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onqueryclosepage-page-trigger
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onmodifyrecord-page-trigger
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-background-tasks
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-flowfields
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-editable-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); CcFixtures.al (tables 84220-84223, pages 84230-84248, codeunit 84271); log 84270
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts (corpus issue 667, items 33-48): OnQueryClosePage without exit on a Card, a StandardDialog and in a page extension; OnModifyRecord with an
//   empty body, exit(false), Rec := other record, exit(true); a background task enqueued per row in OnAfterGetRecord and CurrPage.Update in the
//   completion trigger; the TestPage state after an error in each page trigger; CurrFieldNo in table, table extension OnBeforeInsert/OnAfterInsert
//   triggers for a TestPage write versus Validate from code; a Visible = false FlowField on OpenView; control expressions with a Record-returning
//   procedure, a BigInteger literal, a Date compared with 0D and a global Record; a 1100-character ToolTip; Rec.Reset plus CurrPage.Update(false)
//   with SourceTableView; Drilldown on a FactBox field that only has OnLookup; CurrPage.Editable(true) after CurrPage.Editable(false) in OnOpenPage.
// BC versions: 29 (27 and 28 by CI)

codeunit 84270 "LT CC Log"
{
    SingleInstance = true;

    var
        Buffer: Text;
        Mode: Integer;
        FailAt: Text;

    procedure Add(Entry: Text)
    begin
        Buffer += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Buffer;
        Buffer := '';
        exit(Result);
    end;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    procedure GetMode(): Integer
    begin
        exit(Mode);
    end;

    procedure SetFailAt(NewFailAt: Text)
    begin
        FailAt := NewFailAt;
    end;

    procedure GetFailAt(): Text
    begin
        exit(FailAt);
    end;
}

codeunit 84275 "LT CC Page Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT CC Log";
        OkTxt: Label 'LT CC step ok', Locked = true;

    local procedure Start()
    var
        Row: Record "LT CC Row";
        Line: Record "LT CC Line";
        CfnRow: Record "LT CC Cfn Row";
    begin
        Row.DeleteAll();
        Line.DeleteAll();
        CfnRow.DeleteAll();
        Log.SetMode(0);
        Log.SetFailAt('');
        Log.Take();
    end;

    local procedure AddRow(Id: Integer; Name: Text[30]; Grp: Integer)
    var
        Row: Record "LT CC Row";
    begin
        Row.Init();
        Row.Id := Id;
        Row.Name := Name;
        Row.Grp := Grp;
        Row.Insert();
    end;

    local procedure NameOf(Id: Integer): Text
    var
        Row: Record "LT CC Row";
    begin
        if not Row.Get(Id) then
            exit('<missing>');
        exit(Row.Name);
    end;

    local procedure Outcome(): Text
    var
        Result: Text;
    begin
        if GetLastErrorText() = OkTxt then
            Result := 'ok'
        else
            Result := 'error: ' + GetLastErrorText() + ' [' + GetLastErrorCode() + ']';
        ClearLastError();
        exit(Result);
    end;

    // ---------------------------------------------------------------- OnQueryClosePage without exit

    local procedure CloseQcCard(var P: TestPage "LT CC QC Card")
    begin
        P.Close();
        Error(OkTxt);
    end;

    local procedure ReadQcCard(var P: TestPage "LT CC QC Card")
    var
        V: Text;
    begin
        V := P.Name.Value();
        Error(OkTxt);
    end;

    [Test]
    procedure QueryClose_NoExit_Card_TestPageClose()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT CC QC Card";
    begin
        Start();
        AddRow(1, 'a', 0);
        P.OpenEdit();
        Log.Take();
        asserterror CloseQcCard(P);
        Observer.Observe('close', Outcome());
        Observer.Observe('log', Log.Take());
        asserterror ReadQcCard(P);
        Observer.Observe('read_after_close', Outcome());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('QcCardOk')]
    procedure QueryClose_NoExit_Card_RunModalOk()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CC Row";
        Ac: Action;
    begin
        Start();
        AddRow(1, 'a', 0);
        Row.Get(1);
        Ac := Page.RunModal(Page::"LT CC QC Card", Row);
        Observer.Observe('result', Format(Ac));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure QcCardOk(var P: TestPage "LT CC QC Card")
    begin
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('QcDialogOk')]
    procedure QueryClose_NoExit_StandardDialog_Ok()
    var
        Observer: Codeunit "Probe Observer";
        Ac: Action;
    begin
        Start();
        Ac := Page.RunModal(Page::"LT CC QC Dialog");
        Observer.Observe('result', Format(Ac));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure QcDialogOk(var P: TestPage "LT CC QC Dialog")
    begin
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('QcDialogCancel')]
    procedure QueryClose_NoExit_StandardDialog_Cancel()
    var
        Observer: Codeunit "Probe Observer";
        Ac: Action;
    begin
        Start();
        Ac := Page.RunModal(Page::"LT CC QC Dialog");
        Observer.Observe('result', Format(Ac));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure QcDialogCancel(var P: TestPage "LT CC QC Dialog")
    begin
        P.Cancel().Invoke();
    end;

    local procedure ClosePlain(var P: TestPage "LT CC QC Plain")
    begin
        P.Close();
        Error(OkTxt);
    end;

    local procedure ReadPlain(var P: TestPage "LT CC QC Plain")
    var
        V: Text;
    begin
        V := P.Name.Value();
        Error(OkTxt);
    end;

    [Test]
    procedure QueryClose_NoExit_PageExtension_TestPageClose()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT CC QC Plain";
    begin
        Start();
        AddRow(1, 'a', 0);
        P.OpenEdit();
        Log.Take();
        asserterror ClosePlain(P);
        Observer.Observe('close', Outcome());
        Observer.Observe('log', Log.Take());
        asserterror ReadPlain(P);
        Observer.Observe('read_after_close', Outcome());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('QcPlainOk')]
    procedure QueryClose_NoExit_PageExtension_RunModalOk()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CC Row";
        Ac: Action;
    begin
        Start();
        AddRow(1, 'a', 0);
        Row.Get(1);
        Ac := Page.RunModal(Page::"LT CC QC Plain", Row);
        Observer.Observe('result', Format(Ac));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure QcPlainOk(var P: TestPage "LT CC QC Plain")
    begin
        P.OK().Invoke();
    end;

    // ---------------------------------------------------------------- OnModifyRecord

    [Test]
    procedure ModifyRecord_EmptyBody_EditSaved()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT CC Mod Empty";
    begin
        Start();
        AddRow(1, 'a', 0);
        AddRow(2, 'b', 0);
        P.OpenEdit();
        P.GoToKey(1);
        P.Name.SetValue('x');
        P.Close();
        Observer.Observe('row1', NameOf(1));
        Observer.Observe('row2', NameOf(2));
        Observer.Finish();
    end;

    local procedure ModifyWithMode(Mode: Integer; var Observer: Codeunit "Probe Observer")
    var
        P: TestPage "LT CC Mod Mode";
    begin
        Start();
        AddRow(1, 'a', 0);
        AddRow(2, 'b', 0);
        Log.SetMode(Mode);
        P.OpenEdit();
        P.GoToKey(1);
        P.Name.SetValue('x');
        P.Close();
        Observer.Observe('log', Log.Take());
        Observer.Observe('row1', NameOf(1));
        Observer.Observe('row2', NameOf(2));
        Log.SetMode(0);
    end;

    [Test]
    procedure ModifyRecord_ExitFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyWithMode(1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure ModifyRecord_AssignsAnotherRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyWithMode(2, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure ModifyRecord_ExitTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyWithMode(3, Observer);
        Observer.Finish();
    end;

    // ---------------------------------------------------------------- page background tasks

    [Test]
    procedure BackgroundTask_EnqueuedPerRow_ThreeRows()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT CC Bg List";
    begin
        Start();
        AddRow(1, 'a', 0);
        AddRow(2, 'b', 0);
        AddRow(3, 'c', 0);
        P.OpenView();
        Observer.Observe('log_open', Log.Take());
        P.Close();
        Observer.Observe('log_close', Log.Take());
        Observer.Finish();
    end;

    local procedure OpenBg(var P: TestPage "LT CC Bg List")
    begin
        P.OpenView();
        Error(OkTxt);
    end;

    [Test]
    procedure BackgroundTask_UpdateInCompletionTrigger()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT CC Bg List";
    begin
        Start();
        AddRow(1, 'a', 0);
        Log.SetMode(1);
        asserterror OpenBg(P);
        Observer.Observe('open', Outcome());
        Observer.Observe('log', Log.Take());
        Log.SetMode(0);
        Observer.Finish();
    end;

    // ---------------------------------------------------------------- errors in page triggers

    local procedure ErrOpen(var P: TestPage "LT CC Err Card")
    begin
        P.OpenEdit();
        Error(OkTxt);
    end;

    local procedure ErrNext(var P: TestPage "LT CC Err Card")
    begin
        P.Next();
        Error(OkTxt);
    end;

    local procedure ErrNew(var P: TestPage "LT CC Err Card")
    begin
        P.New();
        Error(OkTxt);
    end;

    local procedure ErrInsert(var P: TestPage "LT CC Err Card")
    begin
        P.Id.SetValue(9);
        P.Name.SetValue('n');
        P.First();
        Error(OkTxt);
    end;

    local procedure ErrModify(var P: TestPage "LT CC Err Card")
    begin
        P.Name.SetValue('m');
        P.Next();
        Error(OkTxt);
    end;

    local procedure ErrClose(var P: TestPage "LT CC Err Card")
    begin
        P.Close();
        Error(OkTxt);
    end;

    local procedure ErrRead(var P: TestPage "LT CC Err Card")
    var
        V: Text;
    begin
        V := P.Name.Value();
        Error(OkTxt);
    end;

    // Step: 0 = the error comes during OpenEdit, 1 = Next, 2 = New, 3 = insert of a new row, 4 = modify, 5 = Close.
    local procedure ErrCase(TriggerName: Text; Step: Integer; var Observer: Codeunit "Probe Observer")
    var
        P: TestPage "LT CC Err Card";
    begin
        Start();
        AddRow(1, 'a', 0);
        AddRow(2, 'b', 0);
        if Step = 0 then begin
            Log.SetFailAt(TriggerName);
            asserterror ErrOpen(P);
        end else begin
            P.OpenEdit();
            P.First();
            if Step = 3 then
                P.New();
            Log.SetFailAt(TriggerName);
            case Step of
                1:
                    asserterror ErrNext(P);
                2:
                    asserterror ErrNew(P);
                3:
                    asserterror ErrInsert(P);
                4:
                    asserterror ErrModify(P);
                5:
                    asserterror ErrClose(P);
            end;
        end;
        Observer.Observe('step', Outcome());
        Log.SetFailAt('');
        asserterror ErrRead(P);
        Observer.Observe('read_after', Outcome());
        asserterror ErrClose(P);
        Observer.Observe('close_after', Outcome());
    end;

    [Test]
    procedure TriggerError_OnInit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrCase('OnInit', 0, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TriggerError_OnOpenPage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrCase('OnOpenPage', 0, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TriggerError_OnFindRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrCase('OnFindRecord', 0, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TriggerError_OnAfterGetRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrCase('OnAfterGetRecord', 0, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TriggerError_OnAfterGetCurrRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrCase('OnAfterGetCurrRecord', 0, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TriggerError_OnNextRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrCase('OnNextRecord', 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TriggerError_OnNewRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrCase('OnNewRecord', 2, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TriggerError_OnInsertRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrCase('OnInsertRecord', 3, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TriggerError_OnModifyRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrCase('OnModifyRecord', 4, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TriggerError_OnQueryClosePage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrCase('OnQueryClosePage', 5, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure TriggerError_OnClosePage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrCase('OnClosePage', 5, Observer);
        Observer.Finish();
    end;

    // ---------------------------------------------------------------- CurrFieldNo

    [Test]
    procedure CurrFieldNo_TestPageNewRow()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT CC Cfn Card";
    begin
        Start();
        P.OpenNew();
        P.Id.SetValue(1);
        Observer.Observe('after_set_id', Log.Take());
        P.Name.SetValue('x');
        Observer.Observe('after_set_name', Log.Take());
        P.Close();
        Observer.Observe('after_close', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure CurrFieldNo_TestPageExistingRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CC Cfn Row";
        P: TestPage "LT CC Cfn Card";
    begin
        Start();
        Row.Id := 1;
        Row.Name := 'a';
        Row.Insert();
        Log.Take();
        P.OpenEdit();
        P.GoToKey(1);
        P.Name.SetValue('y');
        Observer.Observe('after_set_name', Log.Take());
        P.Close();
        Observer.Observe('after_close', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure CurrFieldNo_ValidateFromCode()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CC Cfn Row";
    begin
        Start();
        Row.Init();
        Row.Id := 3;
        Row.Validate(Name, 'z');
        Observer.Observe('after_validate', Log.Take());
        Row.Insert(true);
        Observer.Observe('after_insert', Log.Take());
        Row.Validate(Name, 'w');
        Row.Modify(true);
        Observer.Observe('after_modify', Log.Take());
        Observer.Finish();
    end;

    // ---------------------------------------------------------------- FlowFields on OpenView

    [Test]
    procedure FlowField_VisibleFalse_OnOpenView()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT CC Line";
        P: TestPage "LT CC Flow Card";
    begin
        Start();
        AddRow(1, 'a', 0);
        Line.Id := 1;
        Line.LineNo := 1;
        Line.Amt := 5;
        Line.Insert();
        P.OpenView();
        Observer.Observe('log', Log.Take());
        Observer.Observe('shown_control', P.FlowShown.Value());
        P.Close();
        Observer.Finish();
    end;

    // ---------------------------------------------------------------- control expressions

    local procedure OpenRecFn(var P: TestPage "LT CC Expr RecFn")
    begin
        P.OpenEdit();
        Error(OkTxt);
    end;

    [Test]
    procedure Expr_RecordReturningProcedure_Editable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CC Row";
        P: TestPage "LT CC Expr RecFn";
        Res: Text;
    begin
        Start();
        AddRow(1, 'a', 0);
        asserterror OpenRecFn(P);
        Res := Outcome();
        Observer.Observe('open', Res);
        if Res = 'ok' then begin
            P.Close();
            Start();
            AddRow(1, 'a', 0);
            AddRow(2, 'b', 0);
            Row.Get(1);
            Row.Flag := true;
            Row.Modify();
            P.OpenEdit();
            P.GoToKey(1);
            Observer.Observe('editable_flag_true', Format(P.Name.Editable()));
            P.GoToKey(2);
            Observer.Observe('editable_flag_false', Format(P.Name.Editable()));
            P.Close();
        end;
        Observer.Finish();
    end;

    local procedure OpenBigInt(var P: TestPage "LT CC Expr BigInt")
    begin
        P.OpenView();
        Error(OkTxt);
    end;

    [Test]
    procedure Expr_BigIntegerLiteral_Enabled()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CC Row";
        P: TestPage "LT CC Expr BigInt";
        Res: Text;
    begin
        Start();
        AddRow(1, 'a', 0);
        asserterror OpenBigInt(P);
        Res := Outcome();
        Observer.Observe('open', Res);
        if Res = 'ok' then begin
            P.Close();
            Start();
            AddRow(1, 'a', 0);
            AddRow(2, 'b', 0);
            Row.Get(2);
            Row.Big := 5;
            Row.Modify();
            P.OpenView();
            P.GoToKey(1);
            Observer.Observe('enabled_big_0', Format(P.DoIt.Enabled()));
            P.GoToKey(2);
            Observer.Observe('enabled_big_5', Format(P.DoIt.Enabled()));
            P.Close();
        end;
        Observer.Finish();
    end;

    local procedure OpenDate(var P: TestPage "LT CC Expr Date")
    begin
        P.OpenEdit();
        Error(OkTxt);
    end;

    [Test]
    procedure Expr_DateEqualsZeroDate_Editable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CC Row";
        P: TestPage "LT CC Expr Date";
        Res: Text;
    begin
        Start();
        AddRow(1, 'a', 0);
        asserterror OpenDate(P);
        Res := Outcome();
        Observer.Observe('open', Res);
        if Res = 'ok' then begin
            P.Close();
            Start();
            AddRow(1, 'a', 0);
            AddRow(2, 'b', 0);
            Row.Get(2);
            Row.D := 20260101D;
            Row.Modify();
            P.OpenEdit();
            P.GoToKey(1);
            Observer.Observe('editable_date_0D', Format(P.Name.Editable()));
            P.GoToKey(2);
            Observer.Observe('editable_date_set', Format(P.Name.Editable()));
            P.Close();
        end;
        Observer.Finish();
    end;

    local procedure OpenGlobal(var P: TestPage "LT CC Expr Global")
    begin
        P.OpenView();
        Error(OkTxt);
    end;

    [Test]
    procedure Expr_GlobalRecord_ActionEnabled()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT CC Expr Global";
        Res: Text;
    begin
        Start();
        AddRow(1, 'a', 1);
        asserterror OpenGlobal(P);
        Res := Outcome();
        Observer.Observe('open', Res);
        if Res = 'ok' then begin
            P.Close();
            Start();
            AddRow(1, 'a', 1);
            AddRow(2, 'b', 2);
            P.OpenView();
            P.GoToKey(1);
            Observer.Observe('enabled_grp_1', Format(P.DoIt.Enabled()));
            P.GoToKey(2);
            Observer.Observe('enabled_grp_2', Format(P.DoIt.Enabled()));
            P.Close();
        end;
        Observer.Finish();
    end;

    // ---------------------------------------------------------------- long ToolTip

    [Test]
    procedure ToolTip_1100Characters_PageOpens()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT CC Long ToolTip";
    begin
        Start();
        AddRow(1, 'a', 0);
        P.OpenView();
        Observer.Observe('name', P.Name.Value());
        P.Close();
        Observer.Finish();
    end;

    // ---------------------------------------------------------------- Rec.Reset + CurrPage.Update(false) with SourceTableView

    local procedure VisibleIds(var P: TestPage "LT CC View List"): Text
    var
        Ids: Text;
        i: Integer;
    begin
        if not P.First() then
            exit('<none>');
        repeat
            Ids += '[' + P.Id.Value() + ']';
            i += 1;
        until (not P.Next()) or (i >= 6);
        exit(Ids);
    end;

    local procedure ViewResetCase(EditMode: Boolean; var Observer: Codeunit "Probe Observer")
    var
        P: TestPage "LT CC View List";
    begin
        Start();
        AddRow(1, 'a', 1);
        AddRow(2, 'b', 1);
        AddRow(3, 'c', 2);
        if EditMode then
            P.OpenEdit()
        else
            P.OpenView();
        Observer.Observe('rows_before', VisibleIds(P));
        P.First();
        P.ResetUpdate.Invoke();
        Observer.Observe('log', Log.Take());
        Observer.Observe('rows_after', VisibleIds(P));
        P.Close();
    end;

    [Test]
    procedure SourceTableView_ResetThenUpdate_EditMode()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewResetCase(true, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure SourceTableView_ResetThenUpdate_ViewMode()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewResetCase(false, Observer);
        Observer.Finish();
    end;

    // ---------------------------------------------------------------- FactBox field with only OnLookup

    local procedure FactDrill(var P: TestPage "LT CC Fact Host")
    begin
        P.Fact.Name.Drilldown();
        Error(OkTxt);
    end;

    local procedure FactLookup(var P: TestPage "LT CC Fact Host")
    begin
        P.Fact.Name.Lookup();
        Error(OkTxt);
    end;

    [Test]
    procedure FactBox_OnLookupOnly_DrilldownAndLookup()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT CC Fact Host";
    begin
        Start();
        AddRow(1, 'a', 0);
        P.OpenView();
        Log.Take();
        asserterror FactDrill(P);
        Observer.Observe('drilldown', Outcome());
        Observer.Observe('drilldown_log', Log.Take());
        asserterror FactLookup(P);
        Observer.Observe('lookup', Outcome());
        Observer.Observe('lookup_log', Log.Take());
        Observer.Finish();
    end;

    // ---------------------------------------------------------------- CurrPage.Editable(false) in OnOpenPage, then Editable(true)

    [Test]
    procedure Editable_FalseInOnOpenPage_ThenTrueFromAction()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT CC Lock Card";
    begin
        Start();
        AddRow(1, 'a', 0);
        P.OpenEdit();
        Observer.Observe('page_before', Format(P.Editable()));
        Observer.Observe('name_before', Format(P.Name.Editable()));
        P.SetEditableTrue.Invoke();
        Observer.Observe('page_after', Format(P.Editable()));
        Observer.Observe('name_after', Format(P.Name.Editable()));
        P.Close();
        Observer.Finish();
    end;
}
