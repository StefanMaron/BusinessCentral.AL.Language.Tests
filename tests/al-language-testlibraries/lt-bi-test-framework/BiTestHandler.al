// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testhandlercontext/testhandlercontext-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 81580 - 81587
// Corpus issues 627 items 14-19, 626 item 10, 629 item 16 (BC 29 test framework): a test codeunit that names a test handler
// (codeunit property TestHandlers, an enum value of the system enum TestHandler that implements ITestHandler) and a data-driven
// test ([TestDataSource] naming a codeunit that implements ITestDataSource; the test procedure takes an Interface ITestContext).
// Observed: which ITestHandler callbacks run, in which order, and what TestHandlerContext.CodeunitId, CodeunitName,
// ProcedureName, TestCaseName and (in the After callbacks) Success return in each; the effect of Skip(Reason) called in
// OnBeforeTestProcedureRun; the rows (test cases) that reach the data-driven test; and DataSourceContext.CodeunitId inside
// ListTestCases and GetTestCase. The types are declared by the BC 29 System app (namespaces System.Testability and System.Test).
// Probe: observed values.
// BC versions: 29
#if BC29PLUS

interface "LT BI TF Case Data"
{
    procedure CaseText(): Text;
}

codeunit 81580 "LT BI TF Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

codeunit 81581 "LT BI TF Case" implements ITestContext, "LT BI TF Case Data"
{
    var
        Value: Text;

    procedure SetText(NewValue: Text)
    begin
        Value := NewValue;
    end;

    procedure CaseText(): Text
    begin
        exit(Value);
    end;
}

codeunit 81582 "LT BI TF Source" implements ITestDataSource
{
    procedure ListTestCases(DataSetIdentifier: Text; context: DataSourceContext): List of [Text]
    var
        Log: Codeunit "LT BI TF Log";
        Cases: List of [Text];
    begin
        Log.Add('list(set=' + DataSetIdentifier + ',cu=' + Format(context.CodeunitId()) + ')');
        Cases.Add('alpha');
        Cases.Add('beta');
        exit(Cases);
    end;

    procedure GetTestCase(DataSetIdentifier: Text; TestCaseIndex: Integer; TestCaseIdentifier: Text; context: DataSourceContext): Interface ITestContext
    var
        Log: Codeunit "LT BI TF Log";
        TestCase: Codeunit "LT BI TF Case";
    begin
        Log.Add('get(set=' + DataSetIdentifier + ',index=' + Format(TestCaseIndex) + ',id=' + TestCaseIdentifier + ',cu=' + Format(context.CodeunitId()) + ')');
        TestCase.SetText(TestCaseIdentifier + '#' + Format(TestCaseIndex));
        exit(TestCase);
    end;
}

codeunit 81583 "LT BI TF Handler" implements ITestHandler
{
    procedure OnBeforeTestCodeunitRun(Context: TestHandlerContext)
    begin
        LogCall('beforeCodeunit', Context, false);
    end;

    procedure OnAfterTestCodeunitRun(Context: TestHandlerContext)
    begin
        LogCall('afterCodeunit', Context, true);
    end;

    procedure OnBeforeTestProcedureRun(Context: TestHandlerContext)
    begin
        LogCall('beforeProc', Context, false);
        if Context.ProcedureName() = 'BiTf_B_SkipMe' then
            Context.Skip('LT BI skip reason');
    end;

    procedure OnAfterTestProcedureRun(Context: TestHandlerContext)
    begin
        LogCall('afterProc', Context, true);
    end;

    procedure OnBeforeTestCaseRun(Context: TestHandlerContext)
    begin
        LogCall('beforeCase', Context, false);
    end;

    procedure OnAfterTestCaseRun(Context: TestHandlerContext)
    begin
        LogCall('afterCase', Context, true);
    end;

    local procedure LogCall(Callback: Text; Context: TestHandlerContext; WithSuccess: Boolean)
    var
        Log: Codeunit "LT BI TF Log";
        Entry: Text;
    begin
        Entry := Callback + '(cu=' + Format(Context.CodeunitId()) + ',name=' + Context.CodeunitName() + ',proc=' + Context.ProcedureName() + ',case=' + Context.TestCaseName();
        if WithSuccess then
            Entry += ',success=' + Format(Context.Success());
        Log.Add(Entry + ')');
    end;
}

enumextension 81584 "LT BI TF Handler" extends TestHandler
{
    value(81584; "LT BI TF Handler")
    {
        Implementation = ITestHandler = "LT BI TF Handler";
    }
}

codeunit 81585 "LT BI TF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHandlers = "LT BI TF Handler";

    [Test]
    procedure BiTf_A_Plain()
    var
        Log: Codeunit "LT BI TF Log";
    begin
        Log.Add('body A');
    end;

    [Test]
    procedure BiTf_B_SkipMe()
    var
        Log: Codeunit "LT BI TF Log";
    begin
        Log.Add('body B');
    end;

    [TestDataSource(81582, 'Set1')]
    procedure BiTf_C_Cases(Context: Interface ITestContext)
    var
        Log: Codeunit "LT BI TF Log";
        CaseData: Interface "LT BI TF Case Data";
    begin
        CaseData := Context as "LT BI TF Case Data";
        Log.Add('body C ' + CaseData.CaseText());
    end;

    // Runs last in this codeunit: everything logged so far, from the first callback on.
    [Test]
    procedure BiTf_D_Observe()
    var
        Log: Codeunit "LT BI TF Log";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;
}

// A second test codeunit without test handlers, run after 81585: the callbacks logged after BiTf_D_Observe
// (its OnAfterTestProcedureRun and the codeunit's OnAfterTestCodeunitRun), if the SingleInstance log survives.
codeunit 81586 "LT BI TF Tests After"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure BiTf_E_ObserveAfter()
    var
        Log: Codeunit "LT BI TF Log";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;
}
#endif
