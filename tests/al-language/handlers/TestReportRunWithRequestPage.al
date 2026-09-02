// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-run-method
// Scope: in-scope
// Fixtures used: Test Rpt RunReqPage Row (60541), Test Rpt RunReqPage Log (60542),
//                Test Rpt RunReqPage Report (60543), Test Rpt RunReqPage Dataset (60544)
//
// Report.Run() on a report INSTANCE, under test, and the request page it opens on the way.
//
// TestReportRunRequestPage.al already pins Report.RunRequestPage — the explicit,
// parameters-capturing entry point. This file pins the far more common shape: a test that
// never mentions the request page at all, declares a [RequestPageHandler] and calls
// Report.Run(). The request page is still opened, the handler is still what closes it, and
// how it closes decides whether the report body runs at all.
//
// Three claims, each separable from the others:
//
//   1. Run() opens the request page and routes it to the declared handler, and a data-item
//      filter the handler sets narrows the rows the report then iterates. A runner that
//      skipped the request page entirely would still iterate — every row — so the row count
//      after a one-row filter is what separates "dispatched" from "ignored".
//   2. A handler that CANCELS stops the report: the page still opened, the handler still
//      ran, and the body executed zero times. No error is raised — cancelling a request
//      page is an ordinary outcome, not a failure.
//   3. A handler that confirms with plain OK on a report that is NOT ProcessingOnly is
//      REJECTED by BC. OK carries no report intent (no preview, no print, no save), and a
//      report with a layout has nothing to do with a bare confirmation, so BC raises rather
//      than guessing. Pinned because it is the boundary of claim 1: OK is only meaningful
//      for a processing-only report.
//
// [RequestPageHandler] bodies run in a read-only negotiation context (real BC raises
// "A transaction must be started before changes can be made to the database" for a write
// attempted inside one), so proof that a handler ran is carried on codeunit globals; only
// the report's own OnOpenPage trigger, which runs in the report's execution scope, writes
// to the log table.

codeunit 60933 "Test Report Run RequestPage"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HandlerRan: Boolean;
        HandlerCancelled: Boolean;
        HandlerConfirmedPlainOK: Boolean;

    local procedure Initialize()
    var
        Row: Record "Test Rpt RunReqPage Row";
        LogRec: Record "Test Rpt RunReqPage Log";
    begin
        LogRec.DeleteAll();
        Row.DeleteAll();
        Row.Init();
        Row."Entry No." := 1;
        Row.Name := 'first';
        Row.Insert();
        Row.Init();
        Row."Entry No." := 2;
        Row.Name := 'second';
        Row.Insert();
        HandlerRan := false;
        HandlerCancelled := false;
        HandlerConfirmedPlainOK := false;
        // Report.Run opens its own execution/UI scope, same as RunModal — real BC refuses to
        // do that while this transaction still has the writes above pending.
        Commit();
    end;

    [Test]
    [HandlerFunctions('RunConfirmingRequestPageHandler')]
    procedure Report_Run_OpensTheRequestPageAndAppliesTheHandlersFilter()
    var
        Probe: Report "Test Rpt RunReqPage Report";
        LogRec: Record "Test Rpt RunReqPage Log";
    begin
        Initialize();
        Clear(Probe);

        Probe.Run();

        if LogRec.MarkerCount('rp-open') <> 1 then
            Error('Report.Run() did not open the request page: expected exactly 1 rp-open log row, got %1.',
                LogRec.MarkerCount('rp-open'));
        if not HandlerRan then
            Error('Report.Run() opened the request page but never routed it to the declared [RequestPageHandler].');
        // Two rows are seeded; the handler filtered the data item down to "Entry No." = 1.
        // A report that ran without the handler's filter processes 2, a report that never
        // ran processes 0 — so only 1 proves both dispatch and filter application.
        if Probe.RowsProcessed() <> 1 then
            Error('Expected exactly 1 row after the handler filtered the data item to "Entry No." = 1, got %1.',
                Probe.RowsProcessed());
    end;

    [Test]
    [HandlerFunctions('RunCancellingRequestPageHandler')]
    procedure Report_Run_CancelledRequestPageRunsNothingAndRaisesNoError()
    var
        Probe: Report "Test Rpt RunReqPage Report";
        LogRec: Record "Test Rpt RunReqPage Log";
    begin
        Initialize();
        Clear(Probe);

        // No asserterror: a cancelled request page is a normal outcome of Run(), not a failure.
        Probe.Run();

        if LogRec.MarkerCount('rp-open') <> 1 then
            Error('The request page never opened, so "cancelled" cannot be told apart from "never ran": expected 1 rp-open log row, got %1.',
                LogRec.MarkerCount('rp-open'));
        if not HandlerCancelled then
            Error('The cancelling [RequestPageHandler] never ran.');
        if Probe.RowsProcessed() <> 0 then
            Error('A cancelled request page must leave the report body unexecuted, but %1 row(s) were processed.',
                Probe.RowsProcessed());
    end;

    [Test]
    [HandlerFunctions('RunPlainOKRequestPageHandler')]
    procedure Report_Run_PlainOKOnANonProcessingOnlyReportIsRejected()
    var
        Probe: Report "Test Rpt RunReqPage Dataset";
    begin
        // "Test Rpt RunReqPage Dataset" has a rendering layout and is NOT ProcessingOnly.
        // Closing its request page with a bare OK asks for no output at all, which BC
        // refuses rather than picking one.
        Initialize();
        Clear(Probe);

        asserterror Probe.Run();

        if not HandlerConfirmedPlainOK then
            Error('The [RequestPageHandler] never ran, so the error did not come from the OK it invoked: %1', GetLastErrorText());
        if StrPos(GetLastErrorText(), 'FormResult may only be OK') = 0 then
            Error('Expected BC to reject a plain OK on a non-ProcessingOnly report, got: %1', GetLastErrorText());
    end;

    [RequestPageHandler]
    procedure RunConfirmingRequestPageHandler(var RequestPage: TestRequestPage "Test Rpt RunReqPage Report")
    begin
        HandlerRan := true;
        // Stands in for the user narrowing the report before confirming.
        RequestPage.Rows.SetFilter("Entry No.", '1');
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure RunCancellingRequestPageHandler(var RequestPage: TestRequestPage "Test Rpt RunReqPage Report")
    begin
        HandlerCancelled := true;
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure RunPlainOKRequestPageHandler(var RequestPage: TestRequestPage "Test Rpt RunReqPage Dataset")
    begin
        HandlerConfirmedPlainOK := true;
        RequestPage.OK().Invoke();
    end;
}
