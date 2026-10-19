// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/reportinstance-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects of CiReportFixtures.al (84580-84591)
// Probe: corpus issue 667 items 131, 133, 135, 136, 137, 138, 139, 143 (odd AL behavior leads, reports). Every literal asserted below is what a local BC 29.0.54011.55816 tier produced; 27 and 28 are checked by the corpus CI legs.
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
        Observer.Expect('run', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'post begin;page OnOpenPage;page handler;post end;');
        Observer.Verify();
    end;

    [Test]
    procedure PostReport_PageRun_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start(1);
        Outcome(Observer, 'run', TryRunPostUi());
        Observer.Expect('run', 'No');
        Observer.Expect('run|text', 'Unhandled UI: Page 84582');
        Observer.Expect('run|code', 'MissingUIHandler');
        Observer.Expect('run log', 'post begin;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardModalHandler')]
    procedure PostReport_PageRunModal_WithHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start(2);
        Outcome(Observer, 'run', TryRunPostUi());
        Observer.Expect('run', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'post begin;page OnOpenPage;modal handler;runmodal=LookupCancel;post end;');
        Observer.Verify();
    end;

    [Test]
    procedure PostReport_PageRunModal_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start(2);
        Outcome(Observer, 'run', TryRunPostUi());
        Observer.Expect('run', 'No');
        Observer.Expect('run|text', 'Unhandled UI: ModalPage 84582');
        Observer.Expect('run|code', 'MissingUIHandler');
        Observer.Expect('run log', 'post begin;');
        Observer.Verify();
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
        Observer.Expect('report run', 'Yes');
        Observer.Expect('report run|text', '');
        Observer.Expect('report run|code', '');
        Observer.Expect('report run log', 'post begin;plain pre;post end;');
        Observer.Expect('report runmodal', 'Yes');
        Observer.Expect('report runmodal|text', '');
        Observer.Expect('report runmodal|code', '');
        Observer.Expect('report runmodal log', 'post begin;plain pre;post end;');
        Observer.Expect('report saveas', 'Yes');
        Observer.Expect('report saveas|text', '');
        Observer.Expect('report saveas|code', '');
        Observer.Expect('report saveas log', 'post begin;pre targetformat=Xml;post;saveas=Yes length>0=Yes;post end;');
        Observer.Verify();
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
        Observer.Expect('run', 'No');
        Observer.Expect('run|text', 'The current report operation is not supported for Excel Layout reports.');
        Observer.Expect('run|code', 'ReportUnsupportedOperation');
        Observer.Expect('run log', '');
        Observer.Expect('runmodal', 'No');
        Observer.Expect('runmodal|text', 'The current report operation is not supported for Excel Layout reports.');
        Observer.Expect('runmodal|code', 'ReportUnsupportedOperation');
        Observer.Expect('runmodal log', '');
        Observer.Expect('execute', 'No');
        Observer.Expect('execute|text', 'The current report operation is not supported for Excel Layout reports.');
        Observer.Expect('execute|code', 'ReportUnsupportedOperation');
        Observer.Expect('execute log', '');
        Observer.Expect('saveas excel', 'Yes');
        Observer.Expect('saveas excel|text', '');
        Observer.Expect('saveas excel|code', '');
        Observer.Expect('saveas excel log', 'pre targetformat=Excel;post pagenos=1,;');
        Observer.Expect('saveas excel result', 'Yes length>0=Yes');
        Observer.Expect('saveas pdf', 'Yes');
        Observer.Expect('saveas pdf|text', 'The Pdf output format is not supported by the current report layout format.');
        Observer.Expect('saveas pdf|code', 'ReportUnsupportedFormat');
        Observer.Expect('saveas pdf log', '');
        Observer.Expect('saveas pdf result', 'No length>0=No');
        Observer.Expect('selected after', '');
        Observer.Verify();
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
        Observer.Expect('run', 'No');
        Observer.Expect('run|text', 'The current report operation is not supported for Excel Layout reports.');
        Observer.Expect('run|code', 'ReportUnsupportedOperation');
        Observer.Expect('run log', '');
        Observer.Expect('runmodal', 'No');
        Observer.Expect('runmodal|text', 'The current report operation is not supported for Excel Layout reports.');
        Observer.Expect('runmodal|code', 'ReportUnsupportedOperation');
        Observer.Expect('runmodal log', '');
        Observer.Expect('execute', 'No');
        Observer.Expect('execute|text', 'The current report operation is not supported for Excel Layout reports.');
        Observer.Expect('execute|code', 'ReportUnsupportedOperation');
        Observer.Expect('execute log', '');
        Observer.Expect('print', 'No');
        Observer.Expect('print|text', 'The current report operation is not supported for Excel Layout reports.');
        Observer.Expect('print|code', 'ReportUnsupportedOperation');
        Observer.Expect('print log', '');
        Observer.Expect('saveas excel', 'Yes');
        Observer.Expect('saveas excel|text', '');
        Observer.Expect('saveas excel|code', '');
        Observer.Expect('saveas excel log', 'excel pre targetformat=Excel;');
        Observer.Expect('saveas excel result', 'Yes length>0=Yes');
        Observer.Expect('saveas word', 'Yes');
        Observer.Expect('saveas word|text', 'The Word output format is not supported by the current report layout format.');
        Observer.Expect('saveas word|code', 'ReportUnsupportedFormat');
        Observer.Expect('saveas word log', '');
        Observer.Expect('saveas word result', 'No length>0=No');
        Observer.Verify();
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
        Observer.Expect('execute', 'Yes');
        Observer.Expect('execute|text', '');
        Observer.Expect('execute|code', '');
        Observer.Expect('execute log', 'plain pre;');
        Observer.Expect('print', 'Yes');
        Observer.Expect('print|text', '');
        Observer.Expect('print|code', '');
        Observer.Expect('print log', 'plain pre;');
        Observer.Expect('execute unknown', 'No');
        Observer.Expect('execute unknown|text', 'You tried to invoke the Report object with the ID 71999 from the object LT CI Report Run Leads. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('execute unknown|code', 'AL:MetadataNotFound');
        Observer.Expect('execute unknown log', '');
        Observer.Verify();
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
        Observer.Expect('requestpage', 'No');
        Observer.Expect('requestpage|text', 'Unhandled UI: RequestPage 84583');
        Observer.Expect('requestpage|code', 'MissingUIHandler');
        Observer.Expect('requestpage log', '');
        Observer.Expect('parameters', '');
        Observer.Verify();
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
        Observer.Expect('runmodal after', 'opt=[o1] marker=[m1]');
        Observer.Expect('runmodal log', 'pre opt=[o1] marker=[m1];');
        Observer.Expect('run after', 'opt=[] marker=[]');
        Observer.Expect('run log', 'pre opt=[o2] marker=[m2];');
        Observer.Expect('execute after', 'opt=[o3] marker=[m3]');
        Observer.Expect('execute log', 'pre opt=[o3] marker=[m3];');
        Observer.Verify();
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
        Observer.Expect('runmodal after', 'opt=[typed] marker=[m1]');
        Observer.Expect('runmodal log', 'handler opt=[];pre opt=[typed] marker=[m1];');
        Observer.Verify();
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
        Observer.Expect('run after', 'opt=[] marker=[]');
        Observer.Expect('run log', 'handler opt=[];pre opt=[typed] marker=[m1];');
        Observer.Verify();
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
        Observer.Expect('requestpage log', 'handler opt=[];');
        Observer.Expect('static log', 'pre opt=[typed] marker=[];');
        Observer.Expect('variable log', 'pre opt=[typed] marker=[];');
        Observer.Expect('variable after', 'typed');
        Observer.Expect('preset log', 'pre opt=[typed] marker=[];');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure OptTypedHandler(var RP: TestRequestPage "LT CI Opt Rpt")
    begin
        L.Add('handler opt=[' + RP.OptTextCtl.Value() + ']');
        RP.OptTextCtl.SetValue('typed');
        RP.OK().Invoke();
    end;

    // Item 143: Report.Run with and without a request page while the test has an uncommitted write. With the request page the call fails before
    // the page opens: a request page handler is never called (the test runner then reports it as not executed), so these tests declare none.
    [Test]
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
        Observer.Expect('run', 'No');
        Observer.Expect('run|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('run|code', 'DB:Ok');
        Observer.Expect('run log', '');
        Observer.Verify();
    end;

    [Test]
    procedure PendingWrite_ReportRun_WithRequestPage_AssertError()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CI Row";
    begin
        Start(0);
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.SetRange(Id, 1);
        asserterror Report.Run(Report::"LT CI Tx Rpt", true, false, Row);
        Observer.ObserveError('run');
        Observer.Observe('run log', L.Take());
        Observer.Expect('run|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('run|code', 'DB:Ok');
        Observer.Expect('run log', '');
        Observer.Verify();
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
        Observer.Expect('run', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'pre filter=[1];row 1;');
        Observer.Expect('runmodal', 'Yes');
        Observer.Expect('runmodal|text', '');
        Observer.Expect('runmodal|code', '');
        Observer.Expect('runmodal log', 'pre filter=[1];row 1;');
        Observer.Verify();
    end;

    [Test]
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
        Observer.Expect('runmodal', 'No');
        Observer.Expect('runmodal|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('runmodal|code', 'DB:Ok');
        Observer.Expect('runmodal log', '');
        Observer.Verify();
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
        Other.SetRange("Report ID", 1);
        asserterror Rpt.SetTableView(Other);
        Observer.ObserveError('settableview');
        // The rows are inserted after asserterror, which rolls back the writes made before it.
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Rpt.UseRequestPage(false);
        Outcome(Observer, 'run', TryRunVariable(Rpt));
        Observer.Expect('settableview|text', 'The LT CI Tx Rpt report does not have a DataItem that uses the table (Table 9651 Report Layout Selection) specified in the function SetTableView.');
        Observer.Expect('settableview|code', 'ReportNoDataItem');
        Observer.Expect('run', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'pre filter=[];row 1;row 2;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRunVariable(var Rpt: Report "LT CI Tx Rpt")
    begin
        Rpt.RunModal();
    end;
}
