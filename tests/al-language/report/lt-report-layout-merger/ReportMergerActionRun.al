// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT RptMrg Capture (70831), LT RptMrg Helper (70835), report 70883 of ReportMergerFixtures.al (UseRequestPage = false)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// variable's Run and RunModal for a report with a Custom default layout and no request page. Every call is inside a TryFunction (a service tier without a client may refuse the run:
// the outcome, the start of the error text and the call count are observed). The reports write nothing to the database.
// Risky: Report.Run / RunModal of a report that renders a Custom layout; the whole file is one unit.
// BC versions: 29 (the final facts get added later)

codeunit 70839 "LT RptMrg Action Run"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryRunStatic()
    begin
        Report.Run(Report::"LT RptMrg Report");
    end;

    [TryFunction]
    local procedure TryRunModalStatic()
    begin
        Report.RunModal(Report::"LT RptMrg Report");
    end;

    [TryFunction]
    local procedure TryRunInstance()
    var
        Rep: Report "LT RptMrg Report";
    begin
        Rep.Run();
    end;

    [TryFunction]
    local procedure TryRunModalInstance()
    var
        Rep: Report "LT RptMrg Report";
    begin
        Rep.RunModal();
    end;

    local procedure Show(var Observer: Codeunit "Probe Observer"; Completed: Boolean; var Cap: Codeunit "LT RptMrg Capture")
    begin
        Observer.Observe('try completed', Format(Completed));
        Observer.Observe('error', CopyStr(GetLastErrorText(), 1, 200));
        Observer.Observe('calls', Format(Cap.CallCount()));
        Observer.Observe('action', Cap.Item('action', 1));
        Observer.Observe('ordinal', Cap.Item('ordinal', 1));
        Observer.Observe('object id', Cap.Item('id', 1));
        Observer.Observe('payload keys', Cap.Item('payload keys', 1));
    end;

    [Test]
    procedure Run_Static_ReportAction()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RptMrg Helper";
        Cap: Codeunit "LT RptMrg Capture";
        Completed: Boolean;
    begin
        Helper.SeedRows(1);
        ClearLastError();
        BindSubscription(Cap);
        Completed := TryRunStatic();
        UnbindSubscription(Cap);
        Show(Observer, Completed, Cap);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('calls', '1');
        Observer.Expect('action', 'Print');
        Observer.Expect('ordinal', '4');
        Observer.Expect('object id', '70883');
        Observer.Expect('payload keys', 'filterviews,version,objectname,objectid,documenttype,invokedby,invokeddatetime,companyname,printername,duplex,color,defaultcopies,papertray,intent,layoutmodel,layoutname,layoutmimetype,layoutapplicationid,reportrunid');
        Observer.Verify();
    end;

    [Test]
    procedure RunModal_Static_ReportAction()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RptMrg Helper";
        Cap: Codeunit "LT RptMrg Capture";
        Completed: Boolean;
    begin
        Helper.SeedRows(1);
        ClearLastError();
        BindSubscription(Cap);
        Completed := TryRunModalStatic();
        UnbindSubscription(Cap);
        Show(Observer, Completed, Cap);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('calls', '1');
        Observer.Expect('action', 'Print');
        Observer.Expect('ordinal', '4');
        Observer.Expect('object id', '70883');
        Observer.Expect('payload keys', 'filterviews,version,objectname,objectid,documenttype,invokedby,invokeddatetime,companyname,printername,duplex,color,defaultcopies,papertray,intent,layoutmodel,layoutname,layoutmimetype,layoutapplicationid,reportrunid');
        Observer.Verify();
    end;

    [Test]
    procedure Run_ReportVariable_ReportAction()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RptMrg Helper";
        Cap: Codeunit "LT RptMrg Capture";
        Completed: Boolean;
    begin
        Helper.SeedRows(1);
        ClearLastError();
        BindSubscription(Cap);
        Completed := TryRunInstance();
        UnbindSubscription(Cap);
        Show(Observer, Completed, Cap);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('calls', '1');
        Observer.Expect('action', 'Print');
        Observer.Expect('ordinal', '4');
        Observer.Expect('object id', '70883');
        Observer.Expect('payload keys', 'filterviews,version,objectname,objectid,documenttype,invokedby,invokeddatetime,companyname,printername,duplex,color,defaultcopies,papertray,intent,layoutmodel,layoutname,layoutmimetype,layoutapplicationid,reportrunid');
        Observer.Verify();
    end;

    [Test]
    procedure RunModal_ReportVariable_ReportAction()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RptMrg Helper";
        Cap: Codeunit "LT RptMrg Capture";
        Completed: Boolean;
    begin
        Helper.SeedRows(1);
        ClearLastError();
        BindSubscription(Cap);
        Completed := TryRunModalInstance();
        UnbindSubscription(Cap);
        Show(Observer, Completed, Cap);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('calls', '1');
        Observer.Expect('action', 'Print');
        Observer.Expect('ordinal', '4');
        Observer.Expect('object id', '70883');
        Observer.Expect('payload keys', 'filterviews,version,objectname,objectid,documenttype,invokedby,invokeddatetime,companyname,printername,duplex,color,defaultcopies,papertray,intent,layoutmodel,layoutname,layoutmimetype,layoutapplicationid,reportrunid');
        Observer.Verify();
    end;
}
