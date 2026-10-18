// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope
// Fixtures used: Probe Observer (69160); AoFixtures.al (79500-79518); LT AO Dep Card (61051) in the internals fixture app
// Probe: corpus issue 641 (TestPage behavior the runtime decides without a pin, part 2), writer AO. Every literal is what the corpus CI tier produced.
// BC versions: 27, 28, 29

codeunit 79590 "LT AO TestPage Probes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ReqMode: Text;

    local procedure Clean()
    var
        Row: Record "LT AO Row";
        Hdr: Record "LT AO Hdr";
        Line: Record "LT AO Line";
        Dep: Record "LT AO Dep Row";
        Log: Codeunit "LT AO Log";
    begin
        Row.DeleteAll();
        Hdr.DeleteAll();
        Line.DeleteAll();
        Dep.DeleteAll();
        Log.Take();
    end;

    local procedure AddRow(Id: Integer; F: Code[10]; Op: Text[30])
    var
        Row: Record "LT AO Row";
    begin
        Row.Id := Id;
        Row.F := F;
        Row.Name := 'r' + Format(Id);
        Row.Op := Op;
        Row.Insert();
    end;

    local procedure ListIds(var TP: TestPage "LT AO Row List"): Text
    var
        S: Text;
    begin
        if not TP.First() then
            exit('<none>');
        repeat
            S += TP.Id.Value() + ',';
        until not TP.Next();
        exit(S);
    end;

    // ---- item 1: page background task worker does Commit, Codeunit.Run unguarded or Modify ----

    local procedure BgRun(var Observer: Codeunit "Probe Observer"; Op: Text[30])
    var
        Row: Record "LT AO Row";
        Log: Codeunit "LT AO Log";
        TP: TestPage "LT AO Bg Card";
    begin
        Clean();
        AddRow(1, '', Op);
        AddRow(2, '', '');
        TP.OpenView();
        Observer.Observe('log', Log.Take());
        TP.Close();
        Observer.Observe('rows', Format(Row.Count()));
        Row.Get(1);
        Observer.Observe('r1', Row.Name);
        Row.Get(2);
        Observer.Observe('r2', Row.Name);
        Observer.Observe('wtx', Format(Database.IsInWriteTransaction()));
    end;

    [Test]
    procedure Bg_Commit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BgRun(Observer, 'commit');
        Observer.Finish();
    end;

    [Test]
    procedure Bg_RunOkUnguarded()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BgRun(Observer, 'runok');
        Observer.Finish();
    end;

    [Test]
    procedure Bg_RunFailUnguarded()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BgRun(Observer, 'runfail');
        Observer.Finish();
    end;

    [Test]
    procedure Bg_ModifyShownRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BgRun(Observer, 'modify');
        Observer.Finish();
    end;

    [Test]
    procedure Bg_ModifyOtherRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BgRun(Observer, 'modifypend');
        Observer.Finish();
    end;

    // ---- item 2: SetValue on an invisible control ----

    [Test]
    procedure Invisible_DependencyAppPage()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT AO Dep Card";
    begin
        Clean();
        TP.OpenNew();
        Observer.Observe('ok', Format(TrySetHiddenDep(TP)));
        Observer.ObserveError('set');
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Invisible_SameAppPage()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT AO Vis Card";
    begin
        Clean();
        TP.OpenNew();
        Observer.Observe('ok', Format(TrySetHiddenSame(TP)));
        Observer.ObserveError('set');
        TP.Close();
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TrySetHiddenDep(var TP: TestPage "LT AO Dep Card")
    begin
        TP.Hidden.SetValue('x');
    end;

    [TryFunction]
    local procedure TrySetHiddenSame(var TP: TestPage "LT AO Vis Card")
    begin
        TP.Hidden.SetValue('x');
    end;

    [TryFunction]
    local procedure TryCallIt(var TP: TestPage "LT AO Addin Card")
    begin
        TP.CallIt.Invoke();
    end;

    // ---- item 3: a local variable named like the record field, passed bare to Record.TestField ----

    [TryFunction]
    local procedure TryTestFieldName(var Row: Record "LT AO Row")
    var
        Name: Text;
    begin
        Name := 'local';
        Row.TestField(Name);
    end;

    [Test]
    procedure TestField_LocalVariableNamedLikeField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AO Row";
    begin
        Row.Id := 3;
        Row.Name := '';
        Observer.Observe('blank', Format(TryTestFieldName(Row)));
        Observer.ObserveError('blank');
        Row.Name := 'x';
        Observer.Observe('set', Format(TryTestFieldName(Row)));
        Observer.Finish();
    end;

    // ---- item 4: header SetValue, part line modifies the header, then a card action ----

    [TryFunction]
    local procedure TryActLog(var Card: TestPage "LT AO Hdr Card")
    begin
        Card.ActLog.Invoke();
    end;

    [TryFunction]
    local procedure TryActModify(var Card: TestPage "LT AO Hdr Card")
    begin
        Card.ActModify.Invoke();
    end;

    local procedure HeaderChanged(var Observer: Codeunit "Probe Observer"; Modify: Boolean)
    var
        Hdr: Record "LT AO Hdr";
        Log: Codeunit "LT AO Log";
        Card: TestPage "LT AO Hdr Card";
        Ok: Boolean;
    begin
        Clean();
        Hdr."No." := 'H4';
        Hdr.Name := 'a';
        Hdr.Insert();
        Card.OpenEdit();
        Card.Name.SetValue('b');
        Card.Lines.New();
        Card.Lines.Descr.SetValue('l1');
        Hdr.Get('H4');
        Observer.Observe('db1', Hdr.Name + '/' + Format(Hdr.Total));
        if Modify then
            Ok := TryActModify(Card)
        else
            Ok := TryActLog(Card);
        Observer.Observe('ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('act');
        Observer.Observe('log', Log.Take());
        Hdr.Get('H4');
        Observer.Observe('db2', Hdr.Name + '/' + Format(Hdr.Total));
    end;

    [Test]
    procedure HeaderChangedByLine_ActionLogs()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HeaderChanged(Observer, false);
        Observer.Finish();
    end;

    [Test]
    procedure HeaderChangedByLine_ActionModifies()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HeaderChanged(Observer, true);
        Observer.Finish();
    end;

    // ---- item 7: SetValue of numbers on Text[30] / Code[30] controls ----

    [Test]
    procedure NumberIntoTextField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AO Row";
        TP: TestPage "LT AO Text Card";
    begin
        Clean();
        AddRow(1, '', '');
        TP.OpenEdit();
        TP.Txt.SetValue(14);
        Observer.Observe('i', TP.Txt.Value());
        TP.Txt.SetValue(14.0);
        Observer.Observe('d', TP.Txt.Value());
        TP.Txt.SetValue(1234);
        Observer.Observe('k', TP.Txt.Value());
        TP.Txt.SetValue(-3);
        Observer.Observe('n', TP.Txt.Value());
        TP.Close();
        Row.Get(1);
        Observer.Observe('db', Row.Txt);
        Observer.Finish();
    end;

    [Test]
    procedure NumberIntoCodeField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AO Row";
        TP: TestPage "LT AO Text Card";
    begin
        Clean();
        AddRow(1, '', '');
        TP.OpenEdit();
        TP.Cd.SetValue(14);
        Observer.Observe('i', TP.Cd.Value());
        TP.Cd.SetValue(14.0);
        Observer.Observe('d', TP.Cd.Value());
        TP.Cd.SetValue(1234);
        Observer.Observe('k', TP.Cd.Value());
        TP.Cd.SetValue(-3);
        Observer.Observe('n', TP.Cd.Value());
        TP.Close();
        Row.Get(1);
        Observer.Observe('db', Row.Cd);
        Observer.Finish();
    end;

    [Test]
    procedure NumberIntoTextVariable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AO Log";
        TP: TestPage "LT AO Text Card";
    begin
        Clean();
        AddRow(1, '', '');
        TP.OpenEdit();
        TP.VTxt.SetValue(14);
        TP.VTxt.SetValue(14.0);
        TP.VTxt.SetValue(1234);
        TP.VTxt.SetValue(-3);
        Observer.Observe('log', Log.Take());
        Observer.Observe('v', TP.VTxt.Value());
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure NumberIntoCodeVariable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AO Log";
        TP: TestPage "LT AO Text Card";
    begin
        Clean();
        AddRow(1, '', '');
        TP.OpenEdit();
        TP.VCd.SetValue(14);
        TP.VCd.SetValue(14.0);
        TP.VCd.SetValue(1234);
        TP.VCd.SetValue(-3);
        Observer.Observe('log', Log.Take());
        Observer.Observe('v', TP.VCd.Value());
        TP.Close();
        Observer.Finish();
    end;

    // ---- item 9: Page.Run on a record with SetRange(F, 'A') in filter group 0 or 2, then a new row ----

    local procedure FilteredNewRow(var Observer: Codeunit "Probe Observer"; Group: Integer)
    var
        Row: Record "LT AO Row";
        Stored: Record "LT AO Row";
        TP: TestPage "LT AO Row List";
    begin
        Clean();
        AddRow(1, 'A', '');
        AddRow(2, 'B', '');
        Row.FilterGroup(Group);
        Row.SetRange(F, 'A');
        Row.FilterGroup(0);
        TP.Trap();
        Page.Run(Page::"LT AO Row List", Row);
        Observer.Observe('rows', ListIds(TP));
        TP.New();
        Observer.Observe('newF', TP.F.Value());
        TP.Id.SetValue(9);
        TP.Name.SetValue('n');
        TP.Close();
        Observer.Observe('stored', Format(Stored.Get(9)));
        Observer.Observe('F', Stored.F);
    end;

    [Test]
    procedure FilterGroup0_NewRowField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FilteredNewRow(Observer, 0);
        Observer.Finish();
    end;

    [Test]
    procedure FilterGroup2_NewRowField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FilteredNewRow(Observer, 2);
        Observer.Finish();
    end;

    // ---- item 11: RunPageLink F = const('') and F = filter('') ----

    local procedure RunLinked(var Observer: Codeunit "Probe Observer"; UseConst: Boolean)
    var
        Card: TestPage "LT AO Text Card";
        TP: TestPage "LT AO Row List";
    begin
        Clean();
        AddRow(1, '', '');
        AddRow(2, 'A', '');
        AddRow(3, 'B', '');
        Card.OpenView();
        TP.Trap();
        if UseConst then
            Card.RunConst.Invoke()
        else
            Card.RunFilter.Invoke();
        Observer.Observe('rows', ListIds(TP));
        Observer.Observe('flt', '[' + TP.Filter.GetFilter(F) + ']');
        TP.Close();
        Card.Close();
    end;

    [Test]
    procedure RunPageLink_ConstBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunLinked(Observer, true);
        Observer.Finish();
    end;

    [Test]
    procedure RunPageLink_FilterBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunLinked(Observer, false);
        Observer.Finish();
    end;

    // ---- item 12: OpenNew on pages with OnFindRecord, table empty or not; xRec in OnNewRecord ----

    [Test]
    procedure FindList_OpenNew_EmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AO Log";
        TP: TestPage "LT AO Find List";
    begin
        Clean();
        TP.OpenNew();
        Observer.Observe('log', Log.Take());
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure FindList_OpenNew_WithRows()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AO Log";
        TP: TestPage "LT AO Find List";
    begin
        Clean();
        AddRow(1, '', '');
        AddRow(2, '', '');
        TP.OpenNew();
        Observer.Observe('log', Log.Take());
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure FindCard_OpenNew_EmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AO Log";
        TP: TestPage "LT AO Find Card";
    begin
        Clean();
        TP.OpenNew();
        Observer.Observe('log', Log.Take());
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure FindCard_OpenNew_WithRows()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AO Log";
        TP: TestPage "LT AO Find Card";
    begin
        Clean();
        AddRow(1, '', '');
        AddRow(2, '', '');
        TP.OpenNew();
        Observer.Observe('log', Log.Take());
        TP.Close();
        Observer.Finish();
    end;

    // ---- item 13: OpenNew on a card with a part linked on the card key ----

    [Test]
    procedure PartDraftLine_LinkFieldAfterKey()
    var
        Observer: Codeunit "Probe Observer";
        Hdr: Record "LT AO Hdr";
        Line: Record "LT AO Line";
        Card: TestPage "LT AO Hdr Card";
    begin
        Clean();
        Card.OpenNew();
        Observer.Observe('d0', '[' + Card.Lines."Doc No.".Value() + ']');
        Card."No.".SetValue('H13');
        Observer.Observe('d1', '[' + Card.Lines."Doc No.".Value() + ']');
        Observer.Observe('h1', Format(Hdr.Get('H13')));
        Card.Name.SetValue('nm');
        Observer.Observe('d2', '[' + Card.Lines."Doc No.".Value() + ']');
        Observer.Observe('lines', Format(Line.Count()));
        Card.Close();
        Observer.Finish();
    end;

    // ---- item 15: TestFilter SetFilter(F, ' ') and SetFilter(F, '') after a filter; the same on a request page ----

    local procedure ListFilterReset(var Observer: Codeunit "Probe Observer"; Reset: Text)
    var
        TP: TestPage "LT AO Row List";
    begin
        Clean();
        AddRow(1, '', '');
        AddRow(2, 'A', '');
        AddRow(3, 'B', '');
        TP.OpenView();
        TP.Filter.SetFilter(F, 'A');
        Observer.Observe('a', ListIds(TP));
        TP.Filter.SetFilter(F, Reset);
        Observer.Observe('flt', '[' + TP.Filter.GetFilter(F) + ']');
        Observer.Observe('rows', ListIds(TP));
        TP.Close();
    end;

    [Test]
    procedure TestFilter_SetFilterSpace()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListFilterReset(Observer, ' ');
        Observer.Finish();
    end;

    [Test]
    procedure TestFilter_SetFilterEmpty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListFilterReset(Observer, '');
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure RptHandler(var RP: TestRequestPage "LT AO Rpt")
    var
        Log: Codeunit "LT AO Log";
    begin
        RP.RowDI.SetFilter(F, 'A');
        RP.RowDI.SetFilter(F, ReqMode);
        Log.Add('rp=[' + RP.RowDI.GetFilter(F) + ']');
        RP.OK().Invoke();
    end;

    local procedure ReqFilterReset(var Observer: Codeunit "Probe Observer"; Reset: Text)
    var
        Log: Codeunit "LT AO Log";
    begin
        Clean();
        AddRow(1, '', '');
        AddRow(2, 'A', '');
        AddRow(3, 'B', '');
        Commit();
        ReqMode := Reset;
        Report.Run(Report::"LT AO Rpt");
        Observer.Observe('log', Log.Take());
    end;

    [Test]
    [HandlerFunctions('RptHandler')]
    procedure RequestPage_SetFilterSpace()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReqFilterReset(Observer, ' ');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RptHandler')]
    procedure RequestPage_SetFilterEmpty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReqFilterReset(Observer, '');
        Observer.Finish();
    end;

    // ---- item 17: a list action deletes the only row without CurrPage.Update ----

    [Test]
    procedure DeleteOnlyRow_NoUpdate_Trace()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AO Row";
        Log: Codeunit "LT AO Log";
        TP: TestPage "LT AO Del List";
    begin
        Clean();
        AddRow(1, '', '');
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.DelOnly.Invoke();
        Observer.Observe('act', Log.Take());
        Observer.Observe('id', '[' + TP.Id.Value() + ']');
        Observer.Observe('read', Log.Take());
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('rows', Format(Row.Count()));
        Observer.Finish();
    end;

    // ---- item 18: an action calls a control add-in procedure on a TestPage ----

    [Test]
    procedure AddinProcedureFromAction()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AO Log";
        TP: TestPage "LT AO Addin Card";
    begin
        Clean();
        AddRow(1, '', '');
        TP.OpenEdit();
        Observer.Observe('ok', Format(TryCallIt(TP)));
        Observer.ObserveError('call');
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;
}
