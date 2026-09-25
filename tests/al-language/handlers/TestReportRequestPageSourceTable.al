// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetable-property
// Scope: in-scope
// Fixtures used: none — Base Application report 742 "VAT Report Request Page" and table 740
//                "VAT Report Header"
//
// A request page that declares SourceTable gets a Rec bound to that table when the report
// opens it — also when the report ships precompiled in Base Application rather than compiled
// from this app's source.
//
// Report 742's request page declares SourceTable = "VAT Report Header", and its OnOpenPage runs
//     Rec.CopyFilters("VAT Report Header");
//     Rec.FindFirst();
//     ...
//     OnAfterSetPeriodIsEditable(Rec, PeriodIsEditable);
// so the integration event hands out the row OnOpenPage found. A subscriber records it.
//
// Two claims:
//   1. With two headers and a filter on the second, OnOpenPage finds the SECOND one: its Rec is a
//      VAT Report Header carrying the filters the report's data item was run with.
//   2. With a filter no header matches, Rec.FindFirst() raises the ordinary "no record within the
//      filter" error, which reaches the test through Report.RunModal, and the event never fires.
codeunit 60926 "RPST Probe"
{
    SingleInstance = true;

    var
        SeenNo: Code[20];
        Calls: Integer;

    procedure Reset()
    begin
        SeenNo := '';
        Calls := 0;
    end;

    procedure GetSeenNo(): Code[20]
    begin
        exit(SeenNo);
    end;

    procedure GetCalls(): Integer
    begin
        exit(Calls);
    end;

    [EventSubscriber(ObjectType::Report, Report::"VAT Report Request Page", 'OnAfterSetPeriodIsEditable', '', false, false)]
    local procedure RecordRequestPageRec(VATReportHeader: Record "VAT Report Header"; var PeriodIsEditable: Boolean)
    begin
        Calls += 1;
        SeenNo := VATReportHeader."No.";
    end;
}

codeunit 60928 "Rpt RequestPage SourceTable"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Probe: Codeunit "RPST Probe";
        HandlerCalls: Integer;

    [Test]
    [HandlerFunctions('CancelVATReportRequestPage')]
    procedure RequestPageRec_OnOpenPage_FindsTheFilteredSourceTableRow()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        Probe.Reset();
        HandlerCalls := 0;
        InsertHeader('RPST-A');
        InsertHeader('RPST-B');
        Commit();

        VATReportHeader.SetRange("No.", 'RPST-B');
        Report.RunModal(Report::"VAT Report Request Page", true, false, VATReportHeader);

        Assert.AreEqual(1, Probe.GetCalls(), 'OnOpenPage should reach OnAfterSetPeriodIsEditable once');
        Assert.AreEqual('RPST-B', Probe.GetSeenNo(), 'the request page Rec should be the filtered VAT Report Header');
        Assert.AreEqual(1, HandlerCalls, 'the [RequestPageHandler] should run once');
    end;

    [Test]
    [HandlerFunctions('CancelVATReportRequestPage')]
    procedure RequestPageRec_OnOpenPage_FindFirstOnAnEmptyFilterRaises()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        Probe.Reset();
        HandlerCalls := 0;
        InsertHeader('RPST-C');
        Commit();

        VATReportHeader.SetRange("No.", 'RPST-NONE');
        asserterror Report.RunModal(Report::"VAT Report Request Page", true, false, VATReportHeader);

        Assert.ExpectedError('There is no VAT Report Header within the filter.');
        Assert.AreEqual(0, Probe.GetCalls(), 'OnOpenPage stops at Rec.FindFirst, before the event');
    end;

    local procedure InsertHeader(No: Code[20])
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        VATReportHeader.Init();
        VATReportHeader."No." := No;
        VATReportHeader.Insert();
    end;

    [RequestPageHandler]
    procedure CancelVATReportRequestPage(var RequestPage: TestRequestPage "VAT Report Request Page")
    begin
        HandlerCalls += 1;
        RequestPage.Cancel().Invoke();
    end;
}
