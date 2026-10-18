// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT AB Row" (77000), codeunit "LT AB Flags" (77001), codeunit "LT AB Log" (77050) and the pages, reports and extensions of the
// lt-ab-* folders (pages/lt-ab-group-properties, events/lt-ab-page-events, report/lt-ab-request-page-triggers, pages/lt-ab-action-addin, report/lt-ab-report-ext-prerendering)
// Probe: written against a BC service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 27 to 29 (CI matrix)
// One test codeunit holds all probes of writer AB that use the SingleInstance codeunits "LT AB Flags" and "LT AB Log" (a SingleInstance fixture may belong to only one test codeunit).
// Facts, by procedure prefix:
//   Fixed, Grid, Cue: Editable, Enabled and Visible of a fixed group, grid and cue group (true, false, an expression) as a TestPage sees them on the field inside; input on a
//     non-editable field; ShowAsTree and FileUploadAction on the container with a TestPage that still lists every row (issues 622 and 623).
//   PageEvt: the page trigger events (OnOpenPageEvent ... OnQueryClosePageEvent) against the page triggers: order, arguments, the allow flags, several subscribers (issue 628 items 19 to 25).
//   ReqPage: the record triggers of a request page and of its request page extensions (issue 628 items 6 to 18).
//   ActionAddIn: OnBeforeAction of an action extension and OnControlAddIn (issue 628 items 1 and 2).
//   Render: OnPreRendering of a report extension (issue 628 item 3).

codeunit 77099 "LT AB Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // ---------------------------------------------------------------- Fixed

    local procedure FixedSeed()
    var
        Row: Record "LT AB Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'First';
        Row.Insert();
    end;

    [TryFunction]
    local procedure FixedTryHiddenValue(var Card: TestPage "LT AB Fixed Props")
    var
        Dummy: Text;
    begin
        Dummy := Card.FxHiddenF.Value();
    end;

    [TryFunction]
    local procedure FixedTryVisExprValue(var Card: TestPage "LT AB Fixed Props")
    var
        Dummy: Text;
    begin
        Dummy := Card.FxVisExprF.Value();
    end;

    local procedure FixedRun(Ed: Boolean; En: Boolean; Vi: Boolean)
    var
        Observer: Codeunit "Probe Observer";
        Flags: Codeunit "LT AB Flags";
        Card: TestPage "LT AB Fixed Props";
    begin
        FixedSeed();
        Flags.Set(Ed, En, Vi);
        Card.OpenEdit();
        Observer.Observe('true-editable', Format(Card.FxTrueF.Editable()));
        Observer.Observe('true-enabled', Format(Card.FxTrueF.Enabled()));
        Observer.Observe('true-visible', Format(Card.FxTrueF.Visible()));
        Observer.Observe('true-value', Card.FxTrueF.Value());
        Observer.Observe('false-editable', Format(Card.FxFalseF.Editable()));
        Observer.Observe('false-enabled', Format(Card.FxFalseF.Enabled()));
        Observer.Observe('false-visible', Format(Card.FxFalseF.Visible()));
        Observer.Observe('false-value', Card.FxFalseF.Value());
        Observer.Observe('expr-editable', Format(Card.FxExprF.Editable()));
        Observer.Observe('expr-enabled', Format(Card.FxExprF.Enabled()));
        Observer.Observe('expr-visible', Format(Card.FxExprF.Visible()));
        Observer.Observe('expr-value', Card.FxExprF.Value());
        Observer.Observe('plain-editable', Format(Card.PlainF.Editable()));
        Observer.Observe('hidden-reachable', Format(FixedTryHiddenValue(Card)));
        Observer.Observe('visexpr-reachable', Format(FixedTryVisExprValue(Card)));
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure FixedExpressionTrue()
    begin
        FixedRun(true, true, true);
    end;

    [Test]
    procedure FixedExpressionFalse()
    begin
        FixedRun(false, false, false);
    end;

    [Test]
    procedure FixedExpressionNotEditable()
    begin
        FixedRun(false, true, true);
    end;

    [Test]
    procedure FixedExpressionNotEnabled()
    begin
        FixedRun(true, false, true);
    end;

    [Test]
    procedure FixedExpressionNotVisible()
    begin
        FixedRun(true, true, false);
    end;

    [TryFunction]
    local procedure FixedTrySetFalse(var Card: TestPage "LT AB Fixed Props")
    begin
        Card.FxFalseF.SetValue('set-false');
    end;

    [TryFunction]
    local procedure FixedTrySetExpr(var Card: TestPage "LT AB Fixed Props")
    begin
        Card.FxExprF.SetValue('set-expr');
    end;

    [Test]
    procedure FixedInputOnEditableAndNonEditable()
    var
        Observer: Codeunit "Probe Observer";
        Flags: Codeunit "LT AB Flags";
        Stored: Record "LT AB Row";
        Card: TestPage "LT AB Fixed Props";
    begin
        FixedSeed();
        Flags.Set(false, true, true);
        Card.OpenEdit();
        Card.FxTrueF.SetValue('set-true');
        Observer.Observe('true-after-setvalue', Card.FxTrueF.Value());
        Observer.Observe('false-setvalue-ok', Format(FixedTrySetFalse(Card)));
        Observer.Observe('false-setvalue-error', GetLastErrorText());
        Observer.Observe('expr-setvalue-ok', Format(FixedTrySetExpr(Card)));
        Observer.Observe('expr-setvalue-error', GetLastErrorText());
        Observer.Observe('expr-value-after', Card.FxExprF.Value());
        Card.Close();
        Stored.Get(1);
        Observer.Observe('stored-name', Stored.Name);
        Observer.Finish();
    end;

    [Test]
    procedure FixedShowAsTreeAndFileUploadActionListAllRows()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AB Row";
        List: TestPage "LT AB Fixed Tree List";
        Names: Text;
        Count: Integer;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'One';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'Two';
        Row.Insert();
        Row.Id := 3;
        Row.Name := 'Three';
        Row.Insert();
        List.OpenView();
        if List.First() then
            repeat
                Count += 1;
                Names += List.IdF.Value() + '=' + List.NameF.Value() + ';';
            until not List.Next();
        Observer.Observe('row-count', Format(Count));
        Observer.Observe('rows', Names);
        Observer.Observe('tree-field', List.TreeF.Value());
        Observer.Observe('plain-field', List.PlainTreeF.Value());
        List.Close();
        Observer.Finish();
    end;

    // ---------------------------------------------------------------- Grid

    local procedure GridSeed()
    var
        Row: Record "LT AB Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'First';
        Row.Insert();
    end;

    [TryFunction]
    local procedure GridTryHiddenValue(var Card: TestPage "LT AB Grid Props")
    var
        Dummy: Text;
    begin
        Dummy := Card.GrHiddenF.Value();
    end;

    [TryFunction]
    local procedure GridTryVisExprValue(var Card: TestPage "LT AB Grid Props")
    var
        Dummy: Text;
    begin
        Dummy := Card.GrVisExprF.Value();
    end;

    local procedure GridRun(Ed: Boolean; En: Boolean; Vi: Boolean)
    var
        Observer: Codeunit "Probe Observer";
        Flags: Codeunit "LT AB Flags";
        Card: TestPage "LT AB Grid Props";
    begin
        GridSeed();
        Flags.Set(Ed, En, Vi);
        Card.OpenEdit();
        Observer.Observe('true-editable', Format(Card.GrTrueF.Editable()));
        Observer.Observe('true-enabled', Format(Card.GrTrueF.Enabled()));
        Observer.Observe('true-visible', Format(Card.GrTrueF.Visible()));
        Observer.Observe('true-value', Card.GrTrueF.Value());
        Observer.Observe('false-editable', Format(Card.GrFalseF.Editable()));
        Observer.Observe('false-enabled', Format(Card.GrFalseF.Enabled()));
        Observer.Observe('false-visible', Format(Card.GrFalseF.Visible()));
        Observer.Observe('false-value', Card.GrFalseF.Value());
        Observer.Observe('expr-editable', Format(Card.GrExprF.Editable()));
        Observer.Observe('expr-enabled', Format(Card.GrExprF.Enabled()));
        Observer.Observe('expr-visible', Format(Card.GrExprF.Visible()));
        Observer.Observe('expr-value', Card.GrExprF.Value());
        Observer.Observe('plain-editable', Format(Card.PlainF.Editable()));
        Observer.Observe('hidden-reachable', Format(GridTryHiddenValue(Card)));
        Observer.Observe('visexpr-reachable', Format(GridTryVisExprValue(Card)));
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure GridExpressionTrue()
    begin
        GridRun(true, true, true);
    end;

    [Test]
    procedure GridExpressionFalse()
    begin
        GridRun(false, false, false);
    end;

    [Test]
    procedure GridExpressionNotEditable()
    begin
        GridRun(false, true, true);
    end;

    [Test]
    procedure GridExpressionNotEnabled()
    begin
        GridRun(true, false, true);
    end;

    [Test]
    procedure GridExpressionNotVisible()
    begin
        GridRun(true, true, false);
    end;

    [TryFunction]
    local procedure GridTrySetFalse(var Card: TestPage "LT AB Grid Props")
    begin
        Card.GrFalseF.SetValue('set-false');
    end;

    [TryFunction]
    local procedure GridTrySetExpr(var Card: TestPage "LT AB Grid Props")
    begin
        Card.GrExprF.SetValue('set-expr');
    end;

    [Test]
    procedure GridInputOnEditableAndNonEditable()
    var
        Observer: Codeunit "Probe Observer";
        Flags: Codeunit "LT AB Flags";
        Stored: Record "LT AB Row";
        Card: TestPage "LT AB Grid Props";
    begin
        GridSeed();
        Flags.Set(false, true, true);
        Card.OpenEdit();
        Card.GrTrueF.SetValue('set-true');
        Observer.Observe('true-after-setvalue', Card.GrTrueF.Value());
        Observer.Observe('false-setvalue-ok', Format(GridTrySetFalse(Card)));
        Observer.Observe('false-setvalue-error', GetLastErrorText());
        Observer.Observe('expr-setvalue-ok', Format(GridTrySetExpr(Card)));
        Observer.Observe('expr-setvalue-error', GetLastErrorText());
        Observer.Observe('expr-value-after', Card.GrExprF.Value());
        Card.Close();
        Stored.Get(1);
        Observer.Observe('stored-name', Stored.Name);
        Observer.Finish();
    end;

    [Test]
    procedure GridShowAsTreeAndFileUploadActionListAllRows()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AB Row";
        List: TestPage "LT AB Grid Tree List";
        Names: Text;
        Count: Integer;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'One';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'Two';
        Row.Insert();
        Row.Id := 3;
        Row.Name := 'Three';
        Row.Insert();
        List.OpenView();
        if List.First() then
            repeat
                Count += 1;
                Names += List.IdF.Value() + '=' + List.NameF.Value() + ';';
            until not List.Next();
        Observer.Observe('row-count', Format(Count));
        Observer.Observe('rows', Names);
        Observer.Observe('tree-field', List.TreeF.Value());
        Observer.Observe('plain-field', List.PlainTreeF.Value());
        List.Close();
        Observer.Finish();
    end;

    // ---------------------------------------------------------------- Cue

    local procedure CueSeed()
    var
        Row: Record "LT AB Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'First';
        Row.Insert();
    end;

    [TryFunction]
    local procedure CueTryHiddenValue(var Card: TestPage "LT AB Cue Props")
    var
        Dummy: Text;
    begin
        Dummy := Card.CgHiddenF.Value();
    end;

    [TryFunction]
    local procedure CueTryVisExprValue(var Card: TestPage "LT AB Cue Props")
    var
        Dummy: Text;
    begin
        Dummy := Card.CgVisExprF.Value();
    end;

    local procedure CueRun(Ed: Boolean; En: Boolean; Vi: Boolean)
    var
        Observer: Codeunit "Probe Observer";
        Flags: Codeunit "LT AB Flags";
        Card: TestPage "LT AB Cue Props";
    begin
        CueSeed();
        Flags.Set(Ed, En, Vi);
        Card.OpenEdit();
        Observer.Observe('true-editable', Format(Card.CgTrueF.Editable()));
        Observer.Observe('true-enabled', Format(Card.CgTrueF.Enabled()));
        Observer.Observe('true-visible', Format(Card.CgTrueF.Visible()));
        Observer.Observe('true-value', Card.CgTrueF.Value());
        Observer.Observe('false-editable', Format(Card.CgFalseF.Editable()));
        Observer.Observe('false-enabled', Format(Card.CgFalseF.Enabled()));
        Observer.Observe('false-visible', Format(Card.CgFalseF.Visible()));
        Observer.Observe('false-value', Card.CgFalseF.Value());
        Observer.Observe('expr-editable', Format(Card.CgExprF.Editable()));
        Observer.Observe('expr-enabled', Format(Card.CgExprF.Enabled()));
        Observer.Observe('expr-visible', Format(Card.CgExprF.Visible()));
        Observer.Observe('expr-value', Card.CgExprF.Value());
        Observer.Observe('plain-editable', Format(Card.PlainF.Editable()));
        Observer.Observe('hidden-reachable', Format(CueTryHiddenValue(Card)));
        Observer.Observe('visexpr-reachable', Format(CueTryVisExprValue(Card)));
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure CueExpressionTrue()
    begin
        CueRun(true, true, true);
    end;

    [Test]
    procedure CueExpressionFalse()
    begin
        CueRun(false, false, false);
    end;

    [Test]
    procedure CueExpressionNotEditable()
    begin
        CueRun(false, true, true);
    end;

    [Test]
    procedure CueExpressionNotEnabled()
    begin
        CueRun(true, false, true);
    end;

    [Test]
    procedure CueExpressionNotVisible()
    begin
        CueRun(true, true, false);
    end;

    [TryFunction]
    local procedure CueTrySetFalse(var Card: TestPage "LT AB Cue Props")
    begin
        Card.CgFalseF.SetValue('set-false');
    end;

    [TryFunction]
    local procedure CueTrySetExpr(var Card: TestPage "LT AB Cue Props")
    begin
        Card.CgExprF.SetValue('set-expr');
    end;

    [Test]
    procedure CueInputOnEditableAndNonEditable()
    var
        Observer: Codeunit "Probe Observer";
        Flags: Codeunit "LT AB Flags";
        Stored: Record "LT AB Row";
        Card: TestPage "LT AB Cue Props";
    begin
        CueSeed();
        Flags.Set(false, true, true);
        Card.OpenEdit();
        Card.CgTrueF.SetValue('set-true');
        Observer.Observe('true-after-setvalue', Card.CgTrueF.Value());
        Observer.Observe('false-setvalue-ok', Format(CueTrySetFalse(Card)));
        Observer.Observe('false-setvalue-error', GetLastErrorText());
        Observer.Observe('expr-setvalue-ok', Format(CueTrySetExpr(Card)));
        Observer.Observe('expr-setvalue-error', GetLastErrorText());
        Observer.Observe('expr-value-after', Card.CgExprF.Value());
        Card.Close();
        Stored.Get(1);
        Observer.Observe('stored-name', Stored.Name);
        Observer.Finish();
    end;

    [Test]
    procedure CueShowAsTreeAndFileUploadActionListAllRows()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AB Row";
        List: TestPage "LT AB Cue Tree List";
        Names: Text;
        Count: Integer;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'One';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'Two';
        Row.Insert();
        Row.Id := 3;
        Row.Name := 'Three';
        Row.Insert();
        List.OpenView();
        if List.First() then
            repeat
                Count += 1;
                Names += List.IdF.Value() + '=' + List.NameF.Value() + ';';
            until not List.Next();
        Observer.Observe('row-count', Format(Count));
        Observer.Observe('rows', Names);
        Observer.Observe('tree-field', List.TreeF.Value());
        Observer.Observe('plain-field', List.PlainTreeF.Value());
        List.Close();
        Observer.Finish();
    end;

    // ---------------------------------------------------------------- PageEvt

    local procedure PageEvtSeed()
    var
        Row: Record "LT AB Row";
        Flags: Codeunit "LT AB Flags";
        Log: Codeunit "LT AB Log";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'One';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'Two';
        Row.Insert();
        Flags.SetVeto(false);
        Log.Reset();
    end;

    [Test]
    procedure PageEvtOpenAndCloseOrder()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        Rows: TestPage "LT AB Event Rows";
    begin
        PageEvtSeed();
        Rows.OpenView();
        Observer.Observe('after-open', Log.Dump());
        Log.Reset();
        Rows.Close();
        Observer.Observe('after-close', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure PageEvtNavigationRaisesAfterGetCurrRecord()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        Rows: TestPage "LT AB Event Rows";
    begin
        PageEvtSeed();
        Rows.OpenView();
        Log.Reset();
        Rows.Next();
        Observer.Observe('after-next', Log.Dump());
        Log.Reset();
        Rows.Previous();
        Observer.Observe('after-previous', Log.Dump());
        Rows.Close();
        Observer.Finish();
    end;

    [Test]
    procedure PageEvtNewRowThenInsert()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        Stored: Record "LT AB Row";
        Rows: TestPage "LT AB Event Rows";
    begin
        PageEvtSeed();
        Rows.OpenEdit();
        Log.Reset();
        Rows.New();
        Observer.Observe('after-new', Log.Dump());
        Log.Reset();
        Rows.IdF.SetValue(10);
        Observer.Observe('after-id', Log.Dump());
        Log.Reset();
        Rows.NameF.SetValue('Ten');
        Observer.Observe('after-name', Log.Dump());
        Log.Reset();
        Rows.Next();
        Observer.Observe('after-leave-row', Log.Dump());
        Rows.Close();
        Observer.Observe('stored-count', Format(Stored.Count()));
        Observer.Observe('stored-ten-exists', Format(Stored.Get(10)));
        Observer.Finish();
    end;

    [Test]
    procedure PageEvtModifyRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        Stored: Record "LT AB Row";
        Rows: TestPage "LT AB Event Rows";
    begin
        PageEvtSeed();
        Rows.OpenEdit();
        Log.Reset();
        Rows.NameF.SetValue('Changed');
        Observer.Observe('after-setvalue', Log.Dump());
        Log.Reset();
        Rows.Next();
        Observer.Observe('after-leave-row', Log.Dump());
        Rows.Close();
        Stored.Get(1);
        Observer.Observe('stored-name', Stored.Name);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure PageEvtTryNext(var Rows: TestPage "LT AB Event Rows")
    begin
        Rows.Next();
    end;

    [TryFunction]
    local procedure PageEvtTryClose(var Rows: TestPage "LT AB Event Rows")
    begin
        Rows.Close();
    end;

    [Test]
    procedure PageEvtModifyVetoedBySubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        Flags: Codeunit "LT AB Flags";
        Stored: Record "LT AB Row";
        Rows: TestPage "LT AB Event Rows";
    begin
        PageEvtSeed();
        Flags.SetVeto(true);
        Rows.OpenEdit();
        Log.Reset();
        Rows.NameF.SetValue('Vetoed');
        Observer.Observe('next-ok', Format(PageEvtTryNext(Rows)));
        Observer.Observe('next-error', GetLastErrorText());
        Observer.Observe('log', Log.Dump());
        Flags.SetVeto(false);
        Observer.Observe('close-ok', Format(PageEvtTryClose(Rows)));
        Stored.Get(1);
        Observer.Observe('stored-name', Stored.Name);
        Observer.Finish();
    end;

    [Test]
    procedure PageEvtInsertVetoedBySubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        Flags: Codeunit "LT AB Flags";
        Stored: Record "LT AB Row";
        Rows: TestPage "LT AB Event Rows";
    begin
        PageEvtSeed();
        Flags.SetVeto(true);
        Rows.OpenEdit();
        Rows.New();
        Rows.IdF.SetValue(20);
        Log.Reset();
        Rows.NameF.SetValue('Twenty');
        Observer.Observe('next-ok', Format(PageEvtTryNext(Rows)));
        Observer.Observe('next-error', GetLastErrorText());
        Observer.Observe('log', Log.Dump());
        Flags.SetVeto(false);
        Observer.Observe('close-ok', Format(PageEvtTryClose(Rows)));
        Observer.Observe('close-error', GetLastErrorText());
        Observer.Observe('stored-count', Format(Stored.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure PageEvtCloseVetoedBySubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        Flags: Codeunit "LT AB Flags";
        Rows: TestPage "LT AB Event Rows";
    begin
        PageEvtSeed();
        Flags.SetVeto(true);
        Rows.OpenView();
        Log.Reset();
        Observer.Observe('close-ok', Format(PageEvtTryClose(Rows)));
        Observer.Observe('close-error', GetLastErrorText());
        Observer.Observe('log', Log.Dump());
        Flags.SetVeto(false);
        Observer.Finish();
    end;

    // ---------------------------------------------------------------- ReqPage

    local procedure ReqPageSeed()
    var
        Row: Record "LT AB Row";
        Flags: Codeunit "LT AB Flags";
        Log: Codeunit "LT AB Log";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'One';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'Two';
        Row.Insert();
        Flags.SetVeto(false);
        Log.Reset();
        Commit();
    end;

    [Test]
    [HandlerFunctions('ReqPageOkHandler')]
    procedure ReqPageBaseReportOk()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
    begin
        ReqPageSeed();
        Report.Run(Report::"LT AB RP Report");
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ReqPageCancelHandler')]
    procedure ReqPageBaseReportCancel()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
    begin
        ReqPageSeed();
        Report.Run(Report::"LT AB RP Report");
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ReqPageOkHandler')]
    procedure ReqPageBaseReportQueryCloseVeto()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        Flags: Codeunit "LT AB Flags";
    begin
        ReqPageSeed();
        Flags.SetVeto(true);
        Report.Run(Report::"LT AB RP Report");
        Observer.Observe('log', Log.Dump());
        Flags.SetVeto(false);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ReqPagePlainOkHandler')]
    procedure ReqPagePlainReportOkWithExtensionTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
    begin
        ReqPageSeed();
        Report.Run(Report::"LT AB RP Plain Report");
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure ReqPageNoRequestPageHandler()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
    begin
        ReqPageSeed();
        asserterror Report.Run(Report::"LT AB RP Report");
        Observer.ObserveError('run-without-handler');
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure ReqPageOkHandler(var RequestPage: TestRequestPage "LT AB RP Report")
    var
        Log: Codeunit "LT AB Log";
    begin
        Log.Add('handler start');
        RequestPage.NameF.SetValue('typed');
        Log.Add('handler after SetValue');
        RequestPage.OK().Invoke();
        Log.Add('handler after OK');
    end;

    [RequestPageHandler]
    procedure ReqPageCancelHandler(var RequestPage: TestRequestPage "LT AB RP Report")
    var
        Log: Codeunit "LT AB Log";
    begin
        Log.Add('handler start');
        RequestPage.Cancel().Invoke();
        Log.Add('handler after Cancel');
    end;

    [RequestPageHandler]
    procedure ReqPagePlainOkHandler(var RequestPage: TestRequestPage "LT AB RP Plain Report")
    var
        Log: Codeunit "LT AB Log";
    begin
        Log.Add('handler start');
        RequestPage.OK().Invoke();
        Log.Add('handler after OK');
    end;

    // ---------------------------------------------------------------- ActionAddIn

    local procedure ActionAddInSeed()
    var
        Row: Record "LT AB Row";
        Flags: Codeunit "LT AB Flags";
        Log: Codeunit "LT AB Log";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'One';
        Row.Insert();
        Flags.SetVeto(false);
        Log.Reset();
    end;

    [Test]
    procedure ActionAddInBaseActionWithoutExtension()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        Card: TestPage "LT AB Action Card";
    begin
        ActionAddInSeed();
        Card.OpenEdit();
        Log.Reset();
        Card.ActBase.Invoke();
        Observer.Observe('log', Log.Dump());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure ActionAddInBeforeActionRunsBeforeOnAction()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        Card: TestPage "LT AB Action Card";
    begin
        ActionAddInSeed();
        Card.OpenEdit();
        Log.Reset();
        Card.Act.Invoke();
        Observer.Observe('log', Log.Dump());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure ActionAddInErrorInBeforeActionStopsOnAction()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        Flags: Codeunit "LT AB Flags";
        Card: TestPage "LT AB Action Card";
    begin
        ActionAddInSeed();
        Card.OpenEdit();
        Log.Reset();
        Flags.SetVeto(true);
        asserterror Card.Act.Invoke();
        Observer.ObserveError('invoke');
        Observer.Observe('log', Log.Dump());
        Flags.SetVeto(false);
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure ActionAddInControlAddInTriggersOnTestPage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        Card: TestPage "LT AB Action Card";
    begin
        ActionAddInSeed();
        Card.OpenEdit();
        Observer.Observe('after-open', Log.Dump());
        Card.NameF.SetValue('Typed');
        Observer.Observe('after-setvalue', Log.Dump());
        Card.Close();
        Observer.Observe('after-close', Log.Dump());
        Observer.Finish();
    end;

    // ---------------------------------------------------------------- Render

    local procedure RenderSeed()
    var
        Row: Record "LT AB Row";
        Log: Codeunit "LT AB Log";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'One';
        Row.Insert();
        Commit();
        Log.Reset();
    end;

    [Test]
    procedure RenderPlainExtensionSaveAsPdf()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        RenderSeed();
        TempBlob.CreateOutStream(OutStr);
        asserterror Report.SaveAs(Report::"LT AB Render Plain Report", '', ReportFormat::Pdf, OutStr);
        Observer.ObserveError('saveas-pdf');
        Observer.Observe('log', Log.Dump());
        Observer.Observe('has-output', Format(TempBlob.Length() > 0));
        Observer.Finish();
    end;

    [Test]
    procedure RenderSaveAsPdf()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        RenderSeed();
        TempBlob.CreateOutStream(OutStr);
        asserterror Report.SaveAs(Report::"LT AB Render Report", '', ReportFormat::Pdf, OutStr);
        Observer.ObserveError('saveas-pdf');
        Observer.Observe('log', Log.Dump());
        Observer.Observe('has-output', Format(TempBlob.Length() > 0));
        Observer.Finish();
    end;

    [Test]
    procedure RenderSaveAsWord()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        RenderSeed();
        TempBlob.CreateOutStream(OutStr);
        asserterror Report.SaveAs(Report::"LT AB Render Report", '', ReportFormat::Word, OutStr);
        Observer.ObserveError('saveas-word');
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure RenderSaveAsXml()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        RenderSeed();
        TempBlob.CreateOutStream(OutStr);
        asserterror Report.SaveAs(Report::"LT AB Render Report", '', ReportFormat::Xml, OutStr);
        Observer.ObserveError('saveas-xml');
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure RenderRunWithoutOutput()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
    begin
        RenderSeed();
        asserterror Report.Run(Report::"LT AB Render Report");
        Observer.ObserveError('run');
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;
}
