// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/datasourcecontext/datasourcecontext-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT BI TF Case (81581), interface "LT BI TF Case Data" (BiTestHandler.al)
// Corpus issue 626 item 9: DataSourceContext.AppId() inside a data source handler (ListTestCases and GetTestCase of a codeunit
// that implements ITestDataSource). Outside a handler the call ends the test session (tests/al-language/lt-ac/ACContexts.al),
// so this test codeunit has the highest id of the test framework probes and runs after them.
// Probe: observed values.
// BC versions: 29
#if BC29PLUS

codeunit 81588 "LT BI TF AppId Source" implements ITestDataSource
{
    procedure ListTestCases(DataSetIdentifier: Text; context: DataSourceContext): List of [Text]
    var
        Cases: List of [Text];
    begin
        Cases.Add('list app=' + Format(context.AppId()));
        exit(Cases);
    end;

    procedure GetTestCase(DataSetIdentifier: Text; TestCaseIndex: Integer; TestCaseIdentifier: Text; context: DataSourceContext): Interface ITestContext
    var
        TestCase: Codeunit "LT BI TF Case";
    begin
        TestCase.SetText(TestCaseIdentifier + ';get app=' + Format(context.AppId()) + ';own app=' + OwnAppId());
        exit(TestCase);
    end;

    local procedure OwnAppId(): Text
    var
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        exit(Format(Info.Id()));
    end;
}

codeunit 81589 "LT BI TF AppId Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TestDataSource(81588, 'AppIdSet')]
    procedure BiTf_AppId_Case(Context: Interface ITestContext)
    var
        Observer: Codeunit "Probe Observer";
        CaseData: Interface "LT BI TF Case Data";
    begin
        CaseData := Context as "LT BI TF Case Data";
        Observer.Observe('case', CaseData.CaseText());
        Observer.Finish();
    end;
}
#endif
