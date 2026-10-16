// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-print-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT RptMrg Capture (70831), LT RptMrg Helper (70835), report 70883 of ReportMergerFixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Custom layout: outcome inside a TryFunction (a service tier has no printer), the start of the error text, whether the merger is called and with which ReportAction.
// Risky: Report.Print (may not compile on the Cloud app, may need a printer); the whole file is one unit.
// BC versions: 29 (the final facts get added later)

// BC 27 raises an unexpected CLR NullReferenceException for Report.Run / RunModal / Print of this report (CI run 38975045264), so the test codeunit is compiled from BC 28 on.
#if BC28PLUS
codeunit 70840 "LT RptMrg Action Print"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryPrint()
    begin
        Report.Print(Report::"LT RptMrg Report", '');
    end;

    [Test]
    procedure Print_Static_ReportAction()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RptMrg Helper";
        Cap: Codeunit "LT RptMrg Capture";
        Completed: Boolean;
    begin
        Helper.SeedRows(1);
        ClearLastError();
        BindSubscription(Cap);
        Completed := TryPrint();
        UnbindSubscription(Cap);
        Observer.Observe('try completed', Format(Completed));
        Observer.Observe('error', CopyStr(GetLastErrorText(), 1, 200));
        Observer.Observe('calls', Format(Cap.CallCount()));
        Observer.Observe('action', Cap.Item('action', 1));
        Observer.Observe('ordinal', Cap.Item('ordinal', 1));
        Observer.Observe('object id', Cap.Item('id', 1));
        Observer.Observe('payload keys', Cap.Item('payload keys', 1));
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
#endif
