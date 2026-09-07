// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runobject-property
// Scope: in-scope
// Fixtures used: TPAROK Row (60550), TPAROK Log (60551), TPAROK Probe (60552),
//                TPAROK Host (60553), TPAROK Report (60554), TPAROK Silent Report (60555),
//                TPAROK Runner (60556), TPAROK XmlPort (60557), TPAROK Query (60558),
//                Assert (60021)
//
// What a page action's RunObject does when it names something that is NOT a page.
//
// RunObject accepts five kinds. The corpus pins the page kind twice already -- codeunit 60455
// for the handler case and codeunit 60285 for the no-handler case. This codeunit is the other
// four: Report, Codeunit, XmlPort and Query. They are not variations on the page case. BC's
// action builder (ActionBuilder.CreateRunObject, Microsoft.Dynamics.Nav.Client.Builder.dll)
// switches on ActionDefinition.RunObjectType and produces a DIFFERENT action object for each:
//
//     Page      -> CreateNavOpenTaskPageAction(...)
//     Codeunit  -> new InvokeCodeUnitAction(actionDef.TargetID)
//     Report    -> new RunReportAction(actionDef.TargetID)
//     XMLport   -> new RunXmlPortAction(actionDef.TargetID)
//     Query     -> CreateNavOpenTaskPageAction(..., DataSourceType.Query)
//
// That is read from Microsoft's shipped IL and is why the four kinds are four questions rather
// than one. What the IL does NOT settle is what each of those action objects does in a TEST
// session, where there is no client to render anything and handler binding decides what an
// unattended UI event becomes. That is what this codeunit measures, and only a service tier can
// answer it.
//
// THE OPEN QUESTIONS, one per kind, taken from AL Runner issue 2943:
//
//   * Report   -- does the action open the report's REQUEST PAGE (reaching a
//                 [RequestPageHandler]) or run the report body directly? And does
//                 UseRequestPage = false change the answer?
//   * Codeunit -- does Codeunit.Run happen at all, and which record is it given? Does
//                 RunPageOnRec mean anything for a codeunit target?
//   * XmlPort  -- does it run, and is a request page involved?
//   * Query    -- what is "opening a query" in a test session at all?
//
// HOW THE ARMS ARE BUILT, and why they look the way they do.
//
// Every arm is an honest experiment rather than a restatement of an expectation, because when
// this file was written NONE of the four answers was known. Two consequences shape the code:
//
//   1. Where the outcome could legitimately be either "it runs" or "it is refused", the arm
//      states the observable it found and asserts THAT -- with a message naming what a
//      different outcome would have meant. An arm that guessed would have had to be rewritten
//      after the first CI run anyway, and the rewrite is where a wrong guess quietly becomes an
//      assertion nobody re-checked.
//   2. Where an arm invokes inside asserterror, it reads the SingleInstance probe rather than
//      the log table. A refusal discards the uncommitted rows of the transaction it unwinds --
//      measured on all eight cloud legs while building codeunit 60285 -- so a missing log row
//      on such an arm is missing whether the target ran or not. The probe is memory; no
//      rollback reaches it. Arm PROBE proves the probe really is set when a target does run,
//      without which every negative here would be unfalsifiable.
//
// Written by agent stma-auto-32, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue 2943.

codeunit 60559 "TPAROK Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        RequestPageHandlerRan: Boolean;

    local procedure Initialize()
    var
        Row: Record "TPAROK Row";
        Log: Record "TPAROK Log";
        Probe: Codeunit "TPAROK Probe";
    begin
        Row.DeleteAll();
        Log.DeleteAll();
        Probe.Reset();
        RequestPageHandlerRan := false;

        Row.Init();
        Row."No." := 'A';
        Row.Descr := 'Alpha';
        Row.Insert();

        Row.Init();
        Row."No." := 'B';
        Row.Descr := 'Bravo';
        Row.Insert();
    end;

    // PROBE CONTROL. Without this arm every negative below is unfalsifiable: a probe nobody
    // ever sets reports exactly what "the target never ran" reports. This proves each of the
    // three recordable targets really does mark the probe, and really does write its log row,
    // when it is run by an ordinary AL call with nothing to do with an action.
    //
    // It is deliberately the only arm that reaches the targets without a host page, so a
    // failure here means the FIXTURES are broken rather than that RunObject is.
    [Test]
    [HandlerFunctions('ConfirmingRequestPageHandler')]
    procedure ProbeControlEachTargetRecordsItsOwnExecution()
    var
        Row: Record "TPAROK Row";
        Log: Record "TPAROK Log";
        Probe: Codeunit "TPAROK Probe";
        SilentReport: Report "TPAROK Silent Report";
        TheReport: Report "TPAROK Report";
        TheXmlPort: XmlPort "TPAROK XmlPort";
        TempBlob: Codeunit "Temp Blob";
        Outbound: OutStream;
    begin
        Initialize();
        Commit();

        // The codeunit, handed a specific row, so the "which record" assertions later have a
        // known-good comparison.
        Row.Get('B');
        Codeunit.Run(Codeunit::"TPAROK Runner", Row);
        Assert.IsTrue(Probe.GetCodeunitRan(), 'the codeunit target must record its own OnRun when it really runs');
        Assert.AreEqual('Bravo', Probe.GetCodeunitRecSeen(),
            'the codeunit target must record the record it was handed, otherwise the RunObject arms cannot tell which record BC gave it');
        Assert.IsTrue(Log.Get('CODEUNIT'), 'the codeunit target must write its log row when it really runs');

        // The silent report: no request page, so nothing has to be bound for it to run.
        Probe.Reset();
        Clear(SilentReport);
        SilentReport.Run();
        Assert.IsTrue(Probe.GetReportRan(), 'the silent report must record its own OnPreReport when it really runs');
        Assert.AreEqual(2, Probe.GetReportRowCount(),
            'the silent report must iterate both seeded rows, otherwise a row count elsewhere means nothing');

        // The report WITH a request page, confirmed by a bound handler. This also establishes
        // that the request-page probe fires, which is what the report RunObject arms read to
        // tell "opened the request page" from "ran the body directly".
        Probe.Reset();
        Clear(TheReport);
        TheReport.Run();
        Assert.IsTrue(RequestPageHandlerRan, 'the bound [RequestPageHandler] must run when the report is run by AL');
        Assert.IsTrue(Probe.GetRequestPageOpened(), 'the report''s request page must record its own OnOpenPage when it really opens');
        Assert.IsTrue(Probe.GetReportRan(), 'a confirmed request page must let the report body run');
        Assert.AreEqual(2, Probe.GetReportRowCount(), 'the confirmed report must iterate both seeded rows');

        // The xmlport, exported into a temp blob so nothing waits on a file. Direction =
        // Export with UseRequestPage = false, so no handler is needed and nothing negotiates.
        Probe.Reset();
        Clear(TheXmlPort);
        TempBlob.CreateOutStream(Outbound);
        TheXmlPort.SetDestination(Outbound);
        TheXmlPort.Export();
        Assert.IsTrue(Probe.GetXmlPortRan(),
            'the xmlport target must record its own OnPreXmlPort when it really runs, otherwise the RunObject arm''s negative is unfalsifiable');
        Assert.IsTrue(Log.Get('XMLPORT'), 'the xmlport target must write its log row when it really runs');
    end;

    // REPORT, the kind that is 1,037 of the 1,210 non-page RunObject targets in Base
    // Application 28.1 -- so whatever this arm measures is the practical whole of the question.
    //
    // A [RequestPageHandler] is bound. That is the arrangement that tells the two candidate
    // answers apart, because both leave the body executed:
    //
    //   * If the action opens the REQUEST PAGE, the handler runs, the request-page probe is
    //     set, and the body then runs because the handler confirms.
    //   * If the action runs the report DIRECTLY, the body runs with the request-page probe
    //     unset and the handler never called.
    //
    // The invoke is NOT wrapped in asserterror: if BC refuses a report RunObject in a test
    // session, this arm fails on the invoke line, which is the correct and loud outcome for a
    // measurement whose answer was not known in advance.
    [Test]
    [HandlerFunctions('ConfirmingRequestPageHandler')]
    procedure RunObjectNamingAReportRunsIt()
    var
        Probe: Codeunit "TPAROK Probe";
        Host: TestPage "TPAROK Host";
    begin
        Initialize();
        Commit();

        Host.OpenEdit();
        Host.First();
        Host.RunTheReport.Invoke();

        Assert.IsTrue(Probe.GetReportRan(),
            'a RunObject action naming a report must run that report''s body: OnPreReport never fired');
        Assert.AreEqual(2, Probe.GetReportRowCount(),
            'the report run from the action must iterate both seeded rows');
        Assert.IsTrue(Probe.GetRequestPageOpened(),
            'the report''s request page must open on the RunObject route, as it does when AL calls Report.Run');
        Assert.IsTrue(RequestPageHandlerRan,
            'the request page opened by a RunObject action must be routed to the bound [RequestPageHandler]');
    end;

    // REPORT with UseRequestPage = false, which the issue calls out as possibly different. No
    // handler is bound and none can be: there is no request page to hand to one. If the action
    // route insisted on a request page regardless of the property, this arm would fail rather
    // than pass quietly.
    [Test]
    procedure RunObjectNamingAReportWithNoRequestPageRunsItWithNoHandlerBound()
    var
        Probe: Codeunit "TPAROK Probe";
        Host: TestPage "TPAROK Host";
    begin
        Initialize();
        Commit();

        Host.OpenEdit();
        Host.First();
        Host.RunTheSilentReport.Invoke();

        Assert.IsTrue(Probe.GetReportRan(),
            'a RunObject action naming a UseRequestPage = false report must still run it');
        Assert.AreEqual(2, Probe.GetReportRowCount(),
            'the silent report run from the action must iterate both seeded rows');
        Assert.IsFalse(Probe.GetRequestPageOpened(),
            'a report declared UseRequestPage = false must not open a request page on the RunObject route either');
    end;

    // CONTROL for both report arms: the SAME report target, same host, same invoke, reached by
    // an OnAction trigger calling Report.Run instead of by a RunObject declaration. If this
    // behaves differently from RunObjectNamingAReportRunsIt, the DECLARATION is what differs;
    // if it behaves the same, the RunObject route is the ordinary report route.
    [Test]
    [HandlerFunctions('ConfirmingRequestPageHandler')]
    procedure ControlTriggerActionRunningTheSameReportBehavesTheSameWay()
    var
        Probe: Codeunit "TPAROK Probe";
        Host: TestPage "TPAROK Host";
    begin
        Initialize();
        Commit();

        Host.OpenEdit();
        Host.First();
        Host.RunTheReportViaTrigger.Invoke();

        Assert.IsTrue(Probe.GetReportRan(), 'the control''s Report.Run must run the report body');
        Assert.AreEqual(2, Probe.GetReportRowCount(), 'the control must iterate both seeded rows');
        Assert.IsTrue(Probe.GetRequestPageOpened(), 'the control''s Report.Run must open the request page');
        Assert.IsTrue(RequestPageHandlerRan, 'the control''s request page must reach the bound handler');
    end;

    // CODEUNIT, 155 of the non-page targets. Two questions in one arm: does it run at all, and
    // which record does its OnRun see? The host is parked on the SECOND row, so a codeunit
    // handed the host's current record reports 'Bravo' and one handed a fresh, unpositioned
    // record reports the empty string -- two outcomes this arm can tell apart.
    //
    // This action does NOT declare RunPageOnRec; the next arm is the same target WITH it, which
    // is how the issue's "does RunPageOnRec mean anything for a codeunit" question gets an
    // answer rather than an opinion.
    [Test]
    procedure RunObjectNamingACodeunitRunsIt()
    var
        Probe: Codeunit "TPAROK Probe";
        Host: TestPage "TPAROK Host";
    begin
        Initialize();
        Commit();

        Host.OpenEdit();
        Host.First();
        Host.Next();
        Host.RunTheCodeunit.Invoke();

        Assert.IsTrue(Probe.GetCodeunitRan(),
            'a RunObject action naming a codeunit must run it: OnRun never fired');
        Assert.AreEqual('', Probe.GetCodeunitRecSeen(),
            'without RunPageOnRec, the codeunit target must NOT be handed the host page''s current row');
    end;

    // CODEUNIT with RunPageOnRec = true. Same target, same host, same row; the declaration is
    // the only difference from the arm above, so the pair isolates what RunPageOnRec does on a
    // non-page target. The host is on the second row, so 'Bravo' means the host's record was
    // passed and '' means it was not.
    [Test]
    procedure RunObjectNamingACodeunitWithRunPageOnRecIsHandedTheHostsRow()
    var
        Probe: Codeunit "TPAROK Probe";
        Host: TestPage "TPAROK Host";
    begin
        Initialize();
        Commit();

        Host.OpenEdit();
        Host.First();
        Host.Next();
        Host.RunTheCodeunitOnRec.Invoke();

        Assert.IsTrue(Probe.GetCodeunitRan(),
            'a RunObject action naming a codeunit with RunPageOnRec must run it');
        Assert.AreEqual('Bravo', Probe.GetCodeunitRecSeen(),
            'RunPageOnRec on a codeunit target must hand the codeunit the host page''s current row');
    end;

    // XMLPORT, 7 of the non-page targets. Direction = Export, UseRequestPage = false, so
    // nothing waits on a stream a test session cannot supply. The only claim is whether
    // OnPreXmlPort fires.
    [Test]
    procedure RunObjectNamingAnXmlPortRunsIt()
    var
        Probe: Codeunit "TPAROK Probe";
        Host: TestPage "TPAROK Host";
    begin
        Initialize();
        Commit();

        Host.OpenEdit();
        Host.First();
        Host.RunTheXmlPort.Invoke();

        Assert.IsTrue(Probe.GetXmlPortRan(),
            'a RunObject action naming an xmlport must run it: OnPreXmlPort never fired');
    end;

    // QUERY, 11 of the non-page targets, and the kind with no AL surface of its own: a query
    // has no trigger, so nothing inside it can record that it ran. BC's builder routes a query
    // target through the same CreateNavOpenTaskPageAction as a page, with DataSourceType.Query
    // -- so what is opened is a generated page over the query, not the query object.
    //
    // The claim is therefore only what AL can observe: invoking it completes, with no handler
    // bound, exactly as the page kind does (codeunit 60285 arm 1). The name says so, because
    // that IS the whole claim and a stronger-sounding assertion here would be unfalsifiable.
    [Test]
    procedure RunObjectNamingAQueryWithNoHandler_NoThrow()
    var
        Host: TestPage "TPAROK Host";
    begin
        Initialize();
        Commit();

        Host.OpenEdit();
        Host.First();
        Host.RunTheQuery.Invoke();
    end;

    [RequestPageHandler]
    procedure ConfirmingRequestPageHandler(var RequestPage: TestRequestPage "TPAROK Report")
    begin
        RequestPageHandlerRan := true;
        RequestPage.OK().Invoke();
    end;
}
