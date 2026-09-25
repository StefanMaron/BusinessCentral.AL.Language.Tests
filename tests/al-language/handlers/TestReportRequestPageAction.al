// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-test-requestpage
// Scope: in-scope
// Fixtures used: Test Rpt RunReqPage Row (60541), Test Rpt RunReqPage Log (60542),
//                 Test Rpt ReqPage Action (60398)
//
// A [RequestPageHandler] can INVOKE an action the request page declares, and doing so runs that
// action's OnAction trigger against the report's own globals.
//
// The effect is read from inside the report BODY, not only inside the handler: a handler that
// invokes an action and sees nothing change proves nothing either way, while a body that logs
// the action's value proves the trigger ran on the report instance that then executed.
//
//   * run     -> the body reads the value the action's OnAction wrote, and a run counter of 1;
//   * control -> inside the handler, the control bound to the same global reads the action's
//                value after Invoke and the report's own value before it;
//   * repeat  -> two invocations run the trigger twice (the body sees both appends);
//   * error   -> an OnAction that raises an error surfaces that error to the handler, by text.

codeunit 60399 "Test Report ReqPage Action"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        // [RequestPageHandler] callbacks cannot record through the database mid-negotiation, and
        // share this codeunit's instance with the [Test] that declares them.
        ObservedBefore: Text[50];
        ObservedAfter: Text[50];
        HandlerRan: Boolean;

    local procedure Initialize()
    var
        Row: Record "Test Rpt RunReqPage Row";
        LogRec: Record "Test Rpt RunReqPage Log";
    begin
        LogRec.DeleteAll();
        Row.DeleteAll();
        Row.Init();
        Row."Entry No." := 1;
        Row.Name := 'only';
        Row.Insert();
        ObservedBefore := '';
        ObservedAfter := '';
        HandlerRan := false;
        // Report.Run opens its own execution/UI scope, which real BC refuses while writes are pending.
        Commit();
    end;

    [Test]
    [HandlerFunctions('StampHandler')]
    procedure RequestPageAction_Invoke_RunsOnActionOnTheReportsGlobals()
    var
        LogRec: Record "Test Rpt RunReqPage Log";
    begin
        Initialize();

        Report.Run(Report::"Test Rpt ReqPage Action");

        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
        Assert.AreEqual(1, LogRec.MarkerCount('body-text:set-by-action'),
            'the report body must read the value the invoked action''s OnAction wrote');
        Assert.AreEqual(0, LogRec.MarkerCount('body-text:from-report'),
            'the report body must not still read the value OnInitReport seeded');
        Assert.AreEqual(1, LogRec.MarkerCount('body-actions:1'),
            'OnAction must have run exactly once');
    end;

    [Test]
    [HandlerFunctions('StampAndReadHandler')]
    procedure RequestPageAction_Invoke_IsVisibleOnTheBoundControlInsideTheHandler()
    begin
        Initialize();

        Report.Run(Report::"Test Rpt ReqPage Action");

        Assert.AreEqual('from-report', ObservedBefore,
            'before Invoke the control must read the value OnInitReport seeded');
        Assert.AreEqual('set-by-action', ObservedAfter,
            'after Invoke the control must read the value the action wrote to the same global');
    end;

    [Test]
    [HandlerFunctions('AppendTwiceHandler')]
    procedure RequestPageAction_InvokedTwice_RunsOnActionTwice()
    var
        LogRec: Record "Test Rpt RunReqPage Log";
    begin
        Initialize();

        Report.Run(Report::"Test Rpt ReqPage Action");

        Assert.AreEqual(1, LogRec.MarkerCount('body-text:from-report+a+a'),
            'each Invoke must run OnAction again, appending once per call');
        Assert.AreEqual(1, LogRec.MarkerCount('body-actions:2'),
            'OnAction must have run exactly twice');
    end;

    [Test]
    [HandlerFunctions('RefuseHandler')]
    procedure RequestPageAction_OnActionError_SurfacesToTheHandler()
    var
        LogRec: Record "Test Rpt RunReqPage Log";
    begin
        Initialize();

        Report.Run(Report::"Test Rpt ReqPage Action");

        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
        // The handler cancelled after the refused action, so the body never ran.
        Assert.AreEqual(0, LogRec.MarkerCount('body-actions:0'), 'a cancelled request page must not run the report body');
        Assert.AreEqual(0, LogRec.MarkerCount('body-actions:1'), 'a cancelled request page must not run the report body');
    end;

    [RequestPageHandler]
    procedure StampHandler(var RequestPage: TestRequestPage "Test Rpt ReqPage Action")
    begin
        HandlerRan := true;
        RequestPage.StampText.Invoke();
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure StampAndReadHandler(var RequestPage: TestRequestPage "Test Rpt ReqPage Action")
    begin
        HandlerRan := true;
        ObservedBefore := CopyStr(RequestPage.EchoText.Value(), 1, 50);
        RequestPage.StampText.Invoke();
        ObservedAfter := CopyStr(RequestPage.EchoText.Value(), 1, 50);
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure AppendTwiceHandler(var RequestPage: TestRequestPage "Test Rpt ReqPage Action")
    begin
        HandlerRan := true;
        RequestPage.AppendText.Invoke();
        RequestPage.AppendText.Invoke();
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure RefuseHandler(var RequestPage: TestRequestPage "Test Rpt ReqPage Action")
    begin
        HandlerRan := true;
        asserterror RequestPage.RefuseAction.Invoke();
        Assert.ExpectedError('refused-by-request-page-action');
        RequestPage.Cancel().Invoke();
    end;
}
