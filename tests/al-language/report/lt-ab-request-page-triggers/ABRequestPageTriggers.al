// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); reports 77070-77073 (ABRequestPageFixtures.al, ABRequestPageExt.al); table "LT AB Row" (77000), codeunit "LT AB Flags" (77001), codeunit "LT AB Log" (77050)
// Probe: written against a BC service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 27 to 29 (CI matrix)
// Facts: which request page triggers fire when a report runs with a request page handler (OK, Cancel, a veto in OnQueryClosePage), in which order against the
// base page, the extension and the report triggers; and what Report.Run does when no request page handler exists.

codeunit 77074 "LT AB RP Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
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
    [HandlerFunctions('OkHandler')]
    procedure BaseReportOk()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
    begin
        Seed();
        Report.Run(Report::"LT AB RP Report");
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CancelHandler')]
    procedure BaseReportCancel()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
    begin
        Seed();
        Report.Run(Report::"LT AB RP Report");
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure BaseReportQueryCloseVeto()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        Flags: Codeunit "LT AB Flags";
    begin
        Seed();
        Flags.SetVeto(true);
        Report.Run(Report::"LT AB RP Report");
        Observer.Observe('log', Log.Dump());
        Flags.SetVeto(false);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PlainOkHandler')]
    procedure PlainReportOkWithExtensionTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
    begin
        Seed();
        Report.Run(Report::"LT AB RP Plain Report");
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure NoRequestPageHandler()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
    begin
        Seed();
        asserterror Report.Run(Report::"LT AB RP Report");
        Observer.ObserveError('run-without-handler');
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure OkHandler(var RequestPage: TestRequestPage "LT AB RP Report")
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
    procedure CancelHandler(var RequestPage: TestRequestPage "LT AB RP Report")
    var
        Log: Codeunit "LT AB Log";
    begin
        Log.Add('handler start');
        RequestPage.Cancel().Invoke();
        Log.Add('handler after Cancel');
    end;

    [RequestPageHandler]
    procedure PlainOkHandler(var RequestPage: TestRequestPage "LT AB RP Plain Report")
    var
        Log: Codeunit "LT AB Log";
    begin
        Log.Add('handler start');
        RequestPage.OK().Invoke();
        Log.Add('handler after OK');
    end;
}
