// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (System Application); objects of AqFixtures.al; test codeunits 79750-79753
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced (corpus issue 646).
// Facts: CurrReport.Language out of range (item 11), the data item systemId of two SaveAs runs (12), RequestOptionsPage.Caption set in
// OnOpenPage (13), SaveValues on a report extension request page (14), stored filter against SetTableView and a record passed to
// Report.RunModal (15), CalcFields on an extension data item and on a normal field (16), a procedure filter before RunModal (17),
// WordMergeDataItem and the SaveAs Xml data set (18), Report.WordXmlPart texts (19), the legacy ExcelLayout property (22),
// a layout without Subtype (24), RunRequestPage with a pending insert (5), seeded parameters against OnInit and an unknown option control (8),
// Invoke on a disabled and on a hidden request page action (9).
// BC versions: 27-29

codeunit 79750 "LT AQ Report Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT AQ Log";

    local procedure Seed()
    var
        Row: Record "LT AQ Row";
        Entry: Record "LT AQ Entry";
    begin
        Row.DeleteAll();
        Entry.DeleteAll();
        AddRow('A1', 1.5, 'n1');
        AddRow('A2', 2, 'n2');
        AddRow('B1', 3, 'n3');
        AddRow('C1', 4, '');
        Entry.EntryNo := 1; Entry.RowCode := 'A1'; Entry.Qty := 2; Entry.Insert();
        Entry.EntryNo := 2; Entry.RowCode := 'A1'; Entry.Qty := 3; Entry.Insert();
        Entry.EntryNo := 3; Entry.RowCode := 'B1'; Entry.Qty := 7; Entry.Insert();
        Commit();
        Log.Take();
    end;

    local procedure AddRow(NewCode: Code[20]; NewAmount: Decimal; NewName: Text[30])
    var
        Row: Record "LT AQ Row";
    begin
        Row.Code := NewCode;
        Row.Amount := NewAmount;
        Row.Name := NewName;
        Row.Insert();
    end;

    local procedure XmlOf(ReportId: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Xml: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(ReportId, '', ReportFormat::Xml, OutS);
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Xml += Line + '|';
        end;
        exit(Xml);
    end;

    [TryFunction]
    local procedure TryXmlOf(ReportId: Integer; var Xml: Text)
    begin
        Xml := XmlOf(ReportId);
    end;

    local procedure DataItemsOf(Xml: Text): Text
    var
        At: Integer;
    begin
        At := StrPos(Xml, '<DataItems>');
        if At = 0 then
            exit('no DataItems element');
        exit(CopyStr(Xml, At));
    end;

    // Every systemId attribute value of the text, comma separated.
    local procedure SystemIds(Xml: Text): Text
    var
        Marker: Text;
        At: Integer;
        Result: Text;
    begin
        Marker := ' systemId="';
        At := StrPos(Xml, Marker);
        while At > 0 do begin
            Xml := CopyStr(Xml, At + StrLen(Marker));
            Result += CopyStr(Xml, 1, StrPos(Xml, '"') - 1) + ',';
            At := StrPos(Xml, Marker);
        end;
        exit(Result);
    end;

    // Per layout of the report: every column of the Report Layout List row except the report id.
    local procedure LayoutRows(ReportId: Integer): Text
    var
        LayoutList: Record "Report Layout List";
        RR: RecordRef;
        FR: FieldRef;
        i: Integer;
        Result: Text;
    begin
        LayoutList.SetRange("Report ID", ReportId);
        if LayoutList.FindSet() then
            repeat
                RR.GetTable(LayoutList);
                Result += '[';
                for i := 1 to RR.FieldCount() do begin
                    FR := RR.FieldIndex(i);
                    if (FR.Name <> 'Report ID') and (FR.Class = FieldClass::Normal) and (FR.Type <> FieldType::Blob) and (FR.Type <> FieldType::Media) then
                        Result += FR.Name + '=' + Format(FR.Value) + ' ';
                end;
                Result += ']';
            until LayoutList.Next() = 0
        else
            Result := 'no layouts';
        exit(Result);
    end;

    [Test]
    procedure Language_OutOfRange_SaveAs()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        XmlOf(Report::"LT AQ Lang");
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Language_OutOfRange_Run()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT AQ Lang Run");
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure SystemId_TwoRuns_SameAsRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AQ Row";
        First: Text;
        Second: Text;
        Expected: Text;
    begin
        Seed();
        First := SystemIds(XmlOf(Report::"LT AQ Rows"));
        Second := SystemIds(XmlOf(Report::"LT AQ Rows"));
        Row.FindSet();
        repeat
            Expected += LowerCase(DelChr(Format(Row.SystemId), '=', '{}')) + ',';
        until Row.Next() = 0;
        Observer.Observe('count', Format(StrLen(First) div 37));
        Observer.Observe('runs equal', Format(First = Second));
        Observer.Observe('equal to row SystemIds', Format(First = Expected));
        Observer.Finish();
    end;

    [Test]
    procedure CalcFields_ExtensionDataItem_Values()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
    begin
        Seed();
        Xml := DataItemsOf(XmlOf(Report::"LT AQ CalcF Base"));
        Observer.Observe('log', Log.Take());
        Observer.Observe('xml', Xml);
        Observer.Finish();
    end;

    [Test]
    procedure CalcFields_NormalField_Run()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
    begin
        Seed();
        ClearLastError();
        Observer.Observe('ok', Format(TryXmlOf(Report::"LT AQ CalcF Normal", Xml)));
        Observer.ObserveError('error');
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure WordMergeDataItem_SaveAsXml_SameDataSet()
    var
        Observer: Codeunit "Probe Observer";
        WithProp: Text;
        Without: Text;
    begin
        Seed();
        WithProp := DataItemsOf(XmlOf(Report::"LT AQ WM On"));
        Without := DataItemsOf(XmlOf(Report::"LT AQ WM Off"));
        Observer.Observe('equal', Format(WithProp = Without));
        Observer.Observe('length on', Format(StrLen(WithProp)));
        Observer.Observe('length off', Format(StrLen(Without)));
        Observer.Observe('on', CopyStr(WithProp, 1, 700));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_NestedSpecialNames()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT AQ Word Xml"));
        Observer.Observe('extended equal', Format(Report.WordXmlPart(Report::"LT AQ Word Xml", true) = Report.WordXmlPart(Report::"LT AQ Word Xml")));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_ReportExtension()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT AQ Word Xml Ext Base"));
        Observer.Observe('extended', Report.WordXmlPart(Report::"LT AQ Word Xml Ext Base", true));
        Observer.Finish();
    end;

    [Test]
    procedure ExcelLayout_Legacy_DefaultAndLayoutList()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('default', Format(Report.DefaultLayout(Report::"LT AQ Excel Legacy")));
        Observer.Observe('rows', LayoutRows(Report::"LT AQ Excel Legacy"));
        Observer.Finish();
    end;

    [Test]
    procedure Layout_NoSubtype_DefaultAndLayoutList()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('default', Format(Report.DefaultLayout(Report::"LT AQ No Subtype")));
        Observer.Observe('rows', LayoutRows(Report::"LT AQ No Subtype"));
        Observer.Finish();
    end;
}

codeunit 79751 "LT AQ Req Page Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT AQ Log";
        SeenCaption: Text;
        SeenValues: Text;
        ActionResults: Text;
        ReadPhase: Boolean;

    [Test]
    [HandlerFunctions('CaptionHandler')]
    procedure Caption_SetInOnOpenPage_TestRequestPageCaption()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeenCaption := '';
        Report.Run(Report::"LT AQ Caption");
        Observer.Observe('caption', SeenCaption);
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure CaptionHandler(var RP: TestRequestPage "LT AQ Caption")
    begin
        SeenCaption := RP.Caption();
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('ActionsHandler')]
    procedure Actions_DisabledAndHidden_Invoke()
    var
        Observer: Codeunit "Probe Observer";
        Params: Text;
    begin
        Log.SetMode(0);
        Log.Take();
        ActionResults := '';
        Params := Report.RunRequestPage(Report::"LT AQ Req Page");
        Observer.Observe('results', ActionResults);
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure ActionsHandler(var RP: TestRequestPage "LT AQ Req Page")
    begin
        asserterror RP.DisAct.Invoke();
        ActionResults += 'disabled: ' + GetLastErrorText() + ' code=' + GetLastErrorCode() + ';';
        asserterror RP.InvAct.Invoke();
        ActionResults += 'hidden: ' + GetLastErrorText() + ' code=' + GetLastErrorCode() + ';';
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('ValuesHandler')]
    procedure Seeded_OnInitSetsControl_HandlerReads()
    var
        Observer: Codeunit "Probe Observer";
        Params: Text;
    begin
        Log.SetMode(1);
        Log.Take();
        Params := Report.RunRequestPage(Report::"LT AQ Req Page");
        Log.Take();
        SeenValues := '';
        ReadPhase := true;
        Params := Report.RunRequestPage(Report::"LT AQ Req Page", Params);
        ReadPhase := false;
        Log.SetMode(0);
        Observer.Observe('handler', SeenValues);
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ValuesHandler')]
    procedure Seeded_UnknownOptionControl()
    var
        Observer: Codeunit "Probe Observer";
        Params: Text;
    begin
        Log.SetMode(0);
        Log.Take();
        Params := Report.RunRequestPage(Report::"LT AQ Req Page");
        Observer.Observe('has OptCtl', Format(Params.Contains('name="OptCtl"')));
        Params := Params.Replace('name="OptCtl"', 'name="GoneOpt"');
        Log.Take();
        SeenValues := '';
        ClearLastError();
        ReadPhase := true;
        Params := Report.RunRequestPage(Report::"LT AQ Req Page", Params);
        ReadPhase := false;
        Observer.ObserveError('error');
        Observer.Observe('handler', SeenValues);
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    // The first RunRequestPage of a test (no value seeded) sets IntCtl 9 and OptCtl Gamma; the second one reads them.
    [RequestPageHandler]
    procedure ValuesHandler(var RP: TestRequestPage "LT AQ Req Page")
    begin
        if ReadPhase then
            SeenValues := 'int=' + RP.IntCtl.Value() + ' opt=' + RP.OptCtl.Value()
        else begin
            RP.IntCtl.SetValue(9);
            RP.OptCtl.SetValue('Gamma');
        end;
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('CancelHandler')]
    procedure PendingInsert_RunRequestPage_InTheTest()
    var
        Observer: Codeunit "Probe Observer";
        Params: Text;
        Row: Record "LT AQ Row";
    begin
        Row.DeleteAll();
        Commit();
        Row.Code := 'P1';
        Row.Insert();
        asserterror Params := Report.RunRequestPage(Report::"LT AQ Req Page");
        Observer.ObserveError('error');
        Observer.Observe('count after', Format(Row.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure PendingInsert_RunRequestPage_NextTest()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AQ Row";
    begin
        Observer.Observe('count', Format(Row.Count()));
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure CancelHandler(var RP: TestRequestPage "LT AQ Req Page")
    begin
        RP.Cancel().Invoke();
    end;
}

codeunit 79752 "LT AQ Saved Ext Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT AQ Log";
        SeenValues: Text;

    [Test]
    [HandlerFunctions('SetHandler')]
    procedure SavedExt_1_SetAndOK()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Report.Run(Report::"LT AQ Saved");
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ReadHandler')]
    procedure SavedExt_2_NextRunShows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        SeenValues := '';
        Report.Run(Report::"LT AQ Saved");
        Observer.Observe('handler', SeenValues);
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure SetHandler(var RP: TestRequestPage "LT AQ Saved")
    begin
        RP.BaseCtl.SetValue(11);
        RP.ExtVarCtl.SetValue(22);
        RP.ExtFieldCtl.SetValue('nm');
        RP.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure ReadHandler(var RP: TestRequestPage "LT AQ Saved")
    begin
        SeenValues := 'base=' + RP.BaseCtl.Value() + ' ext var=' + RP.ExtVarCtl.Value() + ' ext field=[' + RP.ExtFieldCtl.Value() + ']';
        RP.OK().Invoke();
    end;
}

codeunit 79753 "LT AQ Filter Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT AQ Log";
        SeenFilter: Text;

    local procedure Seed()
    var
        Row: Record "LT AQ Row";
    begin
        Row.DeleteAll();
        Row.Code := 'A1'; Row.Insert();
        Row.Code := 'A2'; Row.Insert();
        Row.Code := 'B1'; Row.Insert();
        Row.Code := 'C1'; Row.Insert();
        Commit();
        Log.Take();
    end;

    [Test]
    [HandlerFunctions('FilterHandler')]
    procedure SavedFilter_StoredThenSetTableViewAndRunModalRecord()
    var
        Observer: Codeunit "Probe Observer";
        View: Record "LT AQ Row";
        Stored: Report "LT AQ Saved Filter";
        WithView: Report "LT AQ Saved Filter";
        Plain: Report "LT AQ Saved Filter";
    begin
        Seed();
        Log.SetMode(1);
        Stored.RunModal();
        Observer.Observe('stored A* run', Log.Take());

        Log.SetMode(2);
        SeenFilter := '';
        View.SetFilter(Code, 'C*');
        WithView.SetTableView(View);
        WithView.RunModal();
        Observer.Observe('SetTableView C* page', SeenFilter);
        Observer.Observe('SetTableView C* run', Log.Take());

        SeenFilter := '';
        Report.RunModal(Report::"LT AQ Saved Filter", true, false, View);
        Observer.Observe('RunModal record C* page', SeenFilter);
        Observer.Observe('RunModal record C* run', Log.Take());

        Log.SetMode(3);
        SeenFilter := '';
        Plain.RunModal();
        Log.SetMode(0);
        Observer.Observe('plain afterwards page', SeenFilter);
        Observer.Observe('plain afterwards run', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ProcFilterHandler')]
    procedure ProcedureFilter_BeforeRunModal_OK()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT AQ Proc Filter";
    begin
        Seed();
        SeenFilter := '';
        Rep.SetCallerFilter('B*');
        Rep.RunModal();
        Observer.Observe('page', SeenFilter);
        Observer.Observe('run', Log.Take());
        Observer.Finish();
    end;

    // Mode 1: set A* and OK. Mode 2: read the filter and OK. Mode 3: read the filter and Cancel.
    [RequestPageHandler]
    procedure FilterHandler(var RP: TestRequestPage "LT AQ Saved Filter")
    begin
        if Log.Mode() = 1 then begin
            RP.RowDi.SetFilter(Code, 'A*');
            RP.OK().Invoke();
            exit;
        end;
        SeenFilter := '[' + RP.RowDi.GetFilter(Code) + ']';
        if Log.Mode() = 2 then
            RP.OK().Invoke()
        else
            RP.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure ProcFilterHandler(var RP: TestRequestPage "LT AQ Proc Filter")
    begin
        SeenFilter := '[' + RP.RowDi.GetFilter(Code) + ']';
        RP.OK().Invoke();
    end;
}
