// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/reportinstance-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects of CiReportFixtures.al (84580-84591)
// Probe: corpus issue 667 items 131, 133, 135, 136, 137, 138, 139, 143 (odd AL behavior leads, reports). Values observed on a local BC 29.0 tier, then on the CI legs.
// Facts: UI and report calls in OnPostReport (microsoft/AL#5938); Run/RunModal/Execute/SaveAs with an Excel layout picked by name (microsoft/AL#8067);
// the variable after Run, RunModal and Execute; variable Execute(Parameters) against Report.Execute(Id, Parameters) (microsoft/AL#5710);
// RunRequestPage of a report without a layout; Execute and Print with text that is not XML; Report.Run with a request page after a write (microsoft/AL#7944);
// SetTableView with a record of another table.
// BC versions: 27, 28, 29

codeunit 84592 "LT CI Report Run Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT CI Log";

    local procedure Start(Mode: Integer)
    begin
        L.Take();
        L.SetMode(Mode);
    end;

    local procedure Outcome(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean)
    begin
        Observer.Observe(Name, Format(Ok));
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' log', L.Take());
    end;

    [TryFunction]
    local procedure TryRunPostUi()
    begin
        Report.Run(Report::"LT CI PostUi Rpt");
    end;

    [TryFunction]
    local procedure TryRunId(ReportId: Integer)
    begin
        Report.Run(ReportId);
    end;

    [TryFunction]
    local procedure TryRunModalId(ReportId: Integer)
    begin
        Report.RunModal(ReportId);
    end;

    [TryFunction]
    local procedure TryExecuteId(ReportId: Integer; Parameters: Text)
    begin
        Report.Execute(ReportId, Parameters);
    end;

    [TryFunction]
    local procedure TryPrintId(ReportId: Integer; Parameters: Text)
    begin
        Report.Print(ReportId, Parameters, '');
    end;

    [TryFunction]
    local procedure TrySaveAsId(ReportId: Integer; Fmt: ReportFormat; var Result: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Result := Format(Report.SaveAs(ReportId, '', Fmt, OutS)) + ' length>0=' + Format(TempBlob.Length() > 0);
    end;

    [TryFunction]
    local procedure TryRequestPage(ReportId: Integer; var Parameters: Text)
    begin
        Parameters := Report.RunRequestPage(ReportId);
    end;

    // Item 131: Page.Run in OnPostReport, with a page handler.
    [Test]
    [HandlerFunctions('CardHandler')]
    procedure PostReport_PageRun_WithHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start(1);
        Outcome(Observer, 'run', TryRunPostUi());
        Observer.Finish();
    end;

    [Test]
    procedure PostReport_PageRun_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start(1);
        Outcome(Observer, 'run', TryRunPostUi());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardModalHandler')]
    procedure PostReport_PageRunModal_WithHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start(2);
        Outcome(Observer, 'run', TryRunPostUi());
        Observer.Finish();
    end;

    [Test]
    procedure PostReport_PageRunModal_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start(2);
        Outcome(Observer, 'run', TryRunPostUi());
        Observer.Finish();
    end;

    [Test]
    procedure PostReport_ReportRun_ReportRunModal_SaveAs()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start(3);
        Outcome(Observer, 'report run', TryRunPostUi());
        L.SetMode(4);
        Outcome(Observer, 'report runmodal', TryRunPostUi());
        L.SetMode(5);
        Outcome(Observer, 'report saveas', TryRunPostUi());
        Observer.Finish();
    end;

    [PageHandler]
    procedure CardHandler(var Card: TestPage "LT CI Row Card")
    begin
        L.Add('page handler');
    end;

    [ModalPageHandler]
    procedure CardModalHandler(var Card: TestPage "LT CI Row Card")
    begin
        L.Add('modal handler');
        Card.OK().Invoke();
    end;

    // Item 133: an Excel layout picked by name through Report Layout Selection, on a report whose default layout is Word.
    [Test]
    procedure ExcelLayoutByName_Run_RunModal_Execute_SaveAs()
    var
        Observer: Codeunit "Probe Observer";
        ReportLayoutSelection: Record "Report Layout Selection";
        Result: Text;
    begin
        Start(0);
        ReportLayoutSelection.SetTempLayoutSelectedName('LtCiLayoutsExcel');
        Outcome(Observer, 'run', TryRunId(Report::"LT CI Layouts Rpt"));
        ReportLayoutSelection.SetTempLayoutSelectedName('LtCiLayoutsExcel');
        Outcome(Observer, 'runmodal', TryRunModalId(Report::"LT CI Layouts Rpt"));
        ReportLayoutSelection.SetTempLayoutSelectedName('LtCiLayoutsExcel');
        Outcome(Observer, 'execute', TryExecuteId(Report::"LT CI Layouts Rpt", ''));
        ReportLayoutSelection.SetTempLayoutSelectedName('LtCiLayoutsExcel');
        Outcome(Observer, 'saveas excel', TrySaveAsId(Report::"LT CI Layouts Rpt", ReportFormat::Excel, Result));
        Observer.Observe('saveas excel result', Result);
        ReportLayoutSelection.SetTempLayoutSelectedName('LtCiLayoutsExcel');
        Result := '';
        Outcome(Observer, 'saveas pdf', TrySaveAsId(Report::"LT CI Layouts Rpt", ReportFormat::Pdf, Result));
        Observer.Observe('saveas pdf result', Result);
        Observer.Observe('selected after', ReportLayoutSelection.GetTempSelectedLayoutName());
        ReportLayoutSelection.ClearTempLayoutSelected();
        Observer.Finish();
    end;

    // Items 133 and 139: a report whose only layout is Excel.
    [Test]
    procedure ExcelOnly_Run_RunModal_Execute_Print_SaveAs()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        Start(0);
        Outcome(Observer, 'run', TryRunId(Report::"LT CI ExcelOnly Rpt"));
        Outcome(Observer, 'runmodal', TryRunModalId(Report::"LT CI ExcelOnly Rpt"));
        Outcome(Observer, 'execute', TryExecuteId(Report::"LT CI ExcelOnly Rpt", ''));
        Outcome(Observer, 'print', TryPrintId(Report::"LT CI ExcelOnly Rpt", ''));
        Outcome(Observer, 'saveas excel', TrySaveAsId(Report::"LT CI ExcelOnly Rpt", ReportFormat::Excel, Result));
        Observer.Observe('saveas excel result', Result);
        Result := '';
        Outcome(Observer, 'saveas word', TrySaveAsId(Report::"LT CI ExcelOnly Rpt", ReportFormat::Word, Result));
        Observer.Observe('saveas word result', Result);
        Observer.Finish();
    end;

    // Item 139: Execute and Print with parameters that are not XML.
    [Test]
    procedure Execute_Print_ParametersNotXml()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start(0);
        Outcome(Observer, 'execute', TryExecuteId(Report::"LT CI Plain Rpt", 'this is not xml'));
        Outcome(Observer, 'print', TryPrintId(Report::"LT CI Plain Rpt", 'this is not xml'));
        Outcome(Observer, 'execute unknown', TryExecuteId(71999, 'this is not xml'));
        Observer.Finish();
    end;

    // Item 138: RunRequestPage of a report that has no layout and UseRequestPage = false (no handler).
    [Test]
    procedure NoLayout_RunRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Start(0);
        Outcome(Observer, 'requestpage', TryRequestPage(Report::"LT CI NoLayout Rpt", Parameters));
        Observer.Observe('parameters', Parameters);
        Observer.Finish();
    end;

    // Item 136: the variable after RunModal, Run and Execute (globals set by a procedure and by the request page handler).
    [Test]
    procedure Variable_AfterRunModal_Run_Execute_NoRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        RunModalRpt: Report "LT CI Opt Rpt";
        RunRpt: Report "LT CI Opt Rpt";
        ExecuteRpt: Report "LT CI Opt Rpt";
    begin
        Start(0);
        RunModalRpt.SetOpt('o1');
        RunModalRpt.SetMarker('m1');
        RunModalRpt.UseRequestPage(false);
        RunModalRpt.RunModal();
        Observer.Observe('runmodal after', 'opt=[' + RunModalRpt.GetOpt() + '] marker=[' + RunModalRpt.GetMarker() + ']');
        Observer.Observe('runmodal log', L.Take());
        RunRpt.SetOpt('o2');
        RunRpt.SetMarker('m2');
        RunRpt.UseRequestPage(false);
        RunRpt.Run();
        Observer.Observe('run after', 'opt=[' + RunRpt.GetOpt() + '] marker=[' + RunRpt.GetMarker() + ']');
        Observer.Observe('run log', L.Take());
        ExecuteRpt.SetOpt('o3');
        ExecuteRpt.SetMarker('m3');
        ExecuteRpt.Execute('');
        Observer.Observe('execute after', 'opt=[' + ExecuteRpt.GetOpt() + '] marker=[' + ExecuteRpt.GetMarker() + ']');
        Observer.Observe('execute log', L.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('OptTypedHandler')]
    procedure Variable_AfterRunModal_WithRequestPageValue()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT CI Opt Rpt";
    begin
        Start(0);
        Rpt.SetMarker('m1');
        Rpt.RunModal();
        Observer.Observe('runmodal after', 'opt=[' + Rpt.GetOpt() + '] marker=[' + Rpt.GetMarker() + ']');
        Observer.Observe('runmodal log', L.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('OptTypedHandler')]
    procedure Variable_AfterRun_WithRequestPageValue()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT CI Opt Rpt";
    begin
        Start(0);
        Rpt.SetMarker('m1');
        Rpt.Run();
        Observer.Observe('run after', 'opt=[' + Rpt.GetOpt() + '] marker=[' + Rpt.GetMarker() + ']');
        Observer.Observe('run log', L.Take());
        Observer.Finish();
    end;

    // Item 137: parameters from RunRequestPage passed to Report.Execute(Id, Parameters) and to a variable's Execute(Parameters).
    [Test]
    [HandlerFunctions('OptTypedHandler')]
    procedure Execute_Parameters_StaticAndVariable()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT CI Opt Rpt";
        Preset: Report "LT CI Opt Rpt";
        Parameters: Text;
    begin
        Start(0);
        Parameters := Report.RunRequestPage(Report::"LT CI Opt Rpt");
        Observer.Observe('requestpage log', L.Take());
        Report.Execute(Report::"LT CI Opt Rpt", Parameters);
        Observer.Observe('static log', L.Take());
        Rpt.Execute(Parameters);
        Observer.Observe('variable log', L.Take());
        Observer.Observe('variable after', Rpt.GetOpt());
        Preset.SetOpt('preset');
        Preset.Execute(Parameters);
        Observer.Observe('preset log', L.Take());
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure OptTypedHandler(var RP: TestRequestPage "LT CI Opt Rpt")
    begin
        L.Add('handler opt=[' + RP.OptTextCtl.Value() + ']');
        RP.OptTextCtl.SetValue('typed');
        RP.OK().Invoke();
    end;

    // Item 143: Report.Run with and without a request page while the test has an uncommitted write.
    [Test]
    [HandlerFunctions('TxOkHandler')]
    procedure PendingWrite_ReportRun_WithRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CI Row";
    begin
        Start(0);
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.SetRange(Id, 1);
        Outcome(Observer, 'run', TryRunTx(true, Row));
        Observer.Finish();
    end;

    [Test]
    procedure PendingWrite_ReportRun_WithoutRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CI Row";
    begin
        Start(0);
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.SetRange(Id, 1);
        Outcome(Observer, 'run', TryRunTx(false, Row));
        Outcome(Observer, 'runmodal', TryRunModalTx(false, Row));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('TxOkHandler')]
    procedure PendingWrite_ReportRunModal_WithRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CI Row";
    begin
        Start(0);
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.SetRange(Id, 1);
        Outcome(Observer, 'runmodal', TryRunModalTx(true, Row));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryRunTx(RequestWindow: Boolean; var Row: Record "LT CI Row")
    begin
        Report.Run(Report::"LT CI Tx Rpt", RequestWindow, false, Row);
    end;

    [TryFunction]
    local procedure TryRunModalTx(RequestWindow: Boolean; var Row: Record "LT CI Row")
    begin
        Report.RunModal(Report::"LT CI Tx Rpt", RequestWindow, false, Row);
    end;

    [RequestPageHandler]
    procedure TxOkHandler(var RP: TestRequestPage "LT CI Tx Rpt")
    begin
        L.Add('tx handler');
        RP.OK().Invoke();
    end;

    // Item 135: SetTableView with a record of a table that is no data item of the report.
    [Test]
    procedure SetTableView_RecordOfAnotherTable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CI Row";
        Other: Record "Report Layout Selection";
        Rpt: Report "LT CI Tx Rpt";
    begin
        Start(0);
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Other.SetRange("Report ID", 1);
        Rpt.SetTableView(Other);
        Rpt.UseRequestPage(false);
        Outcome(Observer, 'run', TryRunVariable(Rpt));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryRunVariable(var Rpt: Report "LT CI Tx Rpt")
    begin
        Rpt.RunModal();
    end;
}
