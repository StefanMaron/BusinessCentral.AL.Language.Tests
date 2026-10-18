// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-report-handlers
// Scope: in-scope
// Fixtures used: report 73841/73842/73843, table 73806 and log codeunit 73840 of lt-report-requestpage (RptRequestPage.al, RptFixtures.al); Probe Observer (69160). Log 73840 is Taken at the start of each test.
// Probe: al-runtime-rs corpus topic 206 items 9 and 11 (corpus issue 632): [ReportHandler] functions for a report run from a test (Run, RunModal, Execute, SaveAs,
//   RunRequestPage, a handler of another report, ReportHandler and RequestPageHandler on the same test), and SetFilter(Field, '') on a data item filter of a TestRequestPage.
// Object ids 78200, 78201.

codeunit 78200 "LT AE Report Handler"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        L: Codeunit "LT RpT Request Log";

    local procedure Seed()
    var
        Row: Record "LT RpT Row";
        I: Integer;
    begin
        Row.DeleteAll();
        L.Take();
        for I := 1 to 4 do begin
            Row.Id := I;
            Row.Grp := 1;
            Row.Insert();
        end;
        Commit();
    end;

    [Test]
    [HandlerFunctions('PlainHandler')]
    procedure Run_StaticCall()
    begin
        Seed();
        Report.Run(Report::"LT RpT Request");
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;

    [ReportHandler]
    procedure PlainHandler(var R: Report "LT RpT Request")
    begin
        L.Add('handler');
    end;

    [Test]
    [HandlerFunctions('PlainHandler')]
    procedure Run_VariableRun()
    var
        Rpt: Report "LT RpT Request";
    begin
        Seed();
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PlainHandler')]
    procedure Run_VariableRunModal()
    var
        Rpt: Report "LT RpT Request";
    begin
        Seed();
        Rpt.RunModal();
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PlainHandler')]
    procedure Run_UseRequestPageFalse()
    var
        Rpt: Report "LT RpT Request";
    begin
        Seed();
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PlainHandler')]
    procedure Run_UseRequestPageTrue()
    var
        Rpt: Report "LT RpT Request";
    begin
        Seed();
        Rpt.UseRequestPage(true);
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PlainHandler')]
    procedure Run_Twice_HandlerCalledTwice()
    begin
        Seed();
        Report.Run(Report::"LT RpT Request");
        Report.Run(Report::"LT RpT Request");
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PlainHandler')]
    procedure Execute_WithReportHandler()
    begin
        Seed();
        asserterror Report.Execute(Report::"LT RpT Request", '');
        Observer.ObserveError('execute');
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PlainHandler')]
    procedure SaveAs_WithReportHandler()
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Ok: Boolean;
    begin
        Seed();
        TempBlob.CreateOutStream(OutS);
        asserterror Ok := Report.SaveAs(Report::"LT RpT Request", '', ReportFormat::Xml, OutS);
        Observer.ObserveError('saveas');
        Observer.Observe('log', L.Take());
        Observer.Observe('length', Format(TempBlob.Length()));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PlainHandler')]
    procedure RunRequestPage_WithReportHandler()
    var
        Params: Text;
    begin
        Seed();
        asserterror Params := Report.RunRequestPage(Report::"LT RpT Request");
        Observer.ObserveError('runrequestpage');
        Observer.Observe('params', Params);
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('OtherHandler')]
    procedure Run_HandlerOfAnotherReport()
    begin
        Seed();
        asserterror Report.Run(Report::"LT RpT Request");
        Observer.ObserveError('run');
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;

    [ReportHandler]
    procedure OtherHandler(var R: Report "LT RpT Request Other")
    begin
        L.Add('other handler');
    end;

    [Test]
    [HandlerFunctions('PlainHandler')]
    procedure Run_AnotherReportWithoutHandler()
    begin
        Seed();
        asserterror Report.Run(Report::"LT RpT Request Other");
        Observer.ObserveError('run');
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PlainHandler,RequestPageOkHandler')]
    procedure Run_ReportHandlerAndRequestPageHandler()
    begin
        Seed();
        Report.Run(Report::"LT RpT Request");
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure RequestPageOkHandler(var RP: TestRequestPage "LT RpT Request")
    begin
        L.Add('request page handler');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('PlainHandler')]
    procedure Run_ReportHandlerAndDeclaredNoRequestPage()
    var
        Rpt: Report "LT RpT Request Skipped";
    begin
        Seed();
        asserterror Rpt.Run();
        Observer.ObserveError('run');
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('SkippedReportHandler')]
    procedure Run_HandlerOnReportWithUseRequestPageFalse()
    var
        Rpt: Report "LT RpT Request Skipped";
    begin
        Seed();
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;

    [ReportHandler]
    procedure SkippedReportHandler(var R: Report "LT RpT Request Skipped")
    begin
        L.Add('skipped handler');
    end;

    [Test]
    [HandlerFunctions('SetFilterHandler')]
    procedure TestRequestPage_SetFilterEmpty_ClearsFilter()
    begin
        Seed();
        Report.Run(Report::"LT RpT Request");
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure SetFilterHandler(var RP: TestRequestPage "LT RpT Request")
    begin
        L.Add('start=[' + RP.Row.GetFilter(Id) + ']');
        RP.Row.SetFilter(Id, '2..3');
        L.Add('range=[' + RP.Row.GetFilter(Id) + ']');
        RP.Row.SetFilter(Id, '');
        L.Add('cleared=[' + RP.Row.GetFilter(Id) + ']');
        RP.Row.SetFilter(Id, '1|4');
        L.Add('or=[' + RP.Row.GetFilter(Id) + ']');
        RP.Row.SetFilter(Id, '');
        L.Add('cleared again=[' + RP.Row.GetFilter(Id) + ']');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('SetFilterOnlyEmptyHandler')]
    procedure TestRequestPage_SetFilterEmpty_OnUntouchedFilter()
    begin
        Seed();
        Report.Run(Report::"LT RpT Request");
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure SetFilterOnlyEmptyHandler(var RP: TestRequestPage "LT RpT Request")
    begin
        RP.Row.SetFilter(Id, '');
        L.Add('empty=[' + RP.Row.GetFilter(Id) + ']');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('SetFilterTextHandler')]
    procedure TestRequestPage_SetFilterEmpty_ThenReportRows()
    begin
        Seed();
        Report.Run(Report::"LT RpT Request");
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure SetFilterTextHandler(var RP: TestRequestPage "LT RpT Request")
    begin
        RP.Row.SetFilter(Id, '2..3');
        RP.Row.SetFilter(Id, '');
        RP.OK().Invoke();
    end;
}
