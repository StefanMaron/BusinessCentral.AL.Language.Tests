// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runobject-property
// Scope: in-scope
// Fixtures used: TPARONH Row (60280), TPARONH Card Target (60281),
//                TPARONH Logging Target (60282), TPARONH Host (60283), TPARONH Log (60284),
//                Assert (60021)
//
// OPEN QUESTION. At least one arm of this codeunit is expected to be RED on every leg, and
// that is the point of it. Do not merge it to make the red go away, and do not rewrite the
// first test to assert what BC was observed to do -- that would turn an unanswered question
// into a claim about BC that no service tier has confirmed.
//
// A test that opens a page with no handler bound is refused: BC raises its own unhandled-UI
// error rather than letting a page open with nobody to answer it. The corpus already pins that
// on both routes it covers -- TestPageRunHandler_Tests.NonModalPageRunWithoutAHandlerIsRefused
// calls Page.Run straight from the test, and TestPageModalHandler_Tests
// .ModalPageWithoutAHandlerIsRefused invokes a page ACTION whose OnAction trigger calls
// Page.RunModal. Both pass on all eight BC versions this corpus runs.
//
// The same omission on a RunObject action raises NOTHING. Invoking an action whose effect is
// declared as RunObject, with no [HandlerFunctions] at all, completes quietly and the
// asserterror reports that no error was raised. Measured on BC 27.0, 27.3, 27.5, 28.0, 28.1,
// 28.2, 28.3 and 28.4, and on two different Linux BC images: the image rebuild that turned the
// rest of the RunObject suite (TestPageActionRunObject_Tests, codeunit 60455) from red to green
// left this arm red, with the AL byte-identical across both runs.
//
// Nobody has found the mechanism. `TestHandleForm` returning false rather than raising is a
// named guess that has never been measured, and a stock Windows service tier is what would
// settle it -- every measurement so far is from the Linux BC image this corpus runs on, which
// is patched.
//
// The five arms are one experiment, and the controls are what make the red arm mean anything:
//
//   1. RunObjectActionWithoutAHandlerIsRefused           -- the question. Measured RED.
//   2. ControlPageRunOnTheSameTargetWithoutAHandler...   -- same target page, no host page at
//      all. Rules out the target and the fixture set. Expected green.
//   3. ControlTriggerActionOpeningTheSameTarget...       -- same host, same invoke, same target,
//      same row; the action's effect is an OnAction trigger calling Page.Run instead of a
//      RunObject property. Rules out the action-invoke path. Expected green. With 2 and 3
//      green, the RunObject DECLARATION is the only thing left that differs.
//   4. RunObjectActionWithoutAHandlerMustNotOpenItsTarget -- outcome unknown, and the thing the
//      first arm cannot report: whether the target opened. A handler cannot answer that for an
//      invoke with nothing bound, so the target page records its own OnOpenPage instead.
//   5. ProbeControlTheLoggingTargetRecordsItsOwnOpening  -- proves that probe works, so a
//      missing 'OPENED' row in 4 means the page did not open rather than that nothing observes
//      it. Expected green.
//
// Held out of the eight-test RunObject suite so that suite's seven measured tests could merge.
// That suite is deliberately silent on this question. Tracked as AL Runner issue 2975.
//
// Written by an agent (impl-1).

codeunit 60285 "TPARONH Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "TPARONH Row";
        Log: Record "TPARONH Log";
    begin
        Row.DeleteAll();
        Log.DeleteAll();

        Row.Init();
        Row."No." := 'A';
        Row.Descr := 'Alpha';
        Row.Insert();

        Row.Init();
        Row."No." := 'B';
        Row.Descr := 'Bravo';
        Row.Insert();
    end;

    // THE OPEN QUESTION. No [HandlerFunctions] at all. Opening a page unattended is refused on
    // every other route BC offers, so this asserts the same of the action route. Measured: it
    // is not refused. Whether BC really opens the target unattended here, silently drops the
    // invoke, or refuses it in a way this shape cannot observe, is unsettled.
    [Test]
    procedure RunObjectActionWithoutAHandlerIsRefused()
    var
        Log: Record "TPARONH Log";
        Host: TestPage "TPARONH Host";
    begin
        Initialize();
        // asserterror rolls back to the last commit; without this it also undoes Initialize().
        Commit();

        Host.OpenEdit();
        Host.First();
        asserterror Host.RunCardOnRec.Invoke();
        Assert.ExpectedError('Unhandled UI');

        Assert.IsFalse(Log.Get('CARD'), 'a refused action must not have reached any handler');
    end;

    // CONTROL 1, expected to PASS. The very page the action above names, opened by a plain AL
    // Page.Run with no handler bound and no host page in the picture at all. If this is refused
    // and the arm above is not, the target page, the fixture set and the absence of handlers
    // are all ruled out. If this ever FAILS, the arm above says nothing about RunObject and the
    // whole comparison has to be rebuilt.
    [Test]
    procedure ControlPageRunOnTheSameTargetWithoutAHandlerIsRefused()
    var
        Row: Record "TPARONH Row";
        Log: Record "TPARONH Log";
    begin
        Initialize();
        Commit();

        Row.Get('B');
        asserterror Page.Run(Page::"TPARONH Card Target", Row);
        Assert.ExpectedError('Unhandled UI');

        Assert.IsFalse(Log.Get('CARD'), 'a refused page must not have reached any handler');
    end;

    // CONTROL 2, expected to PASS, and the one that narrows the question to the declaration.
    // Same host page, same invoke, same target, same row, same absent handler -- the action's
    // effect is an OnAction trigger calling Page.Run instead of a RunObject property. If this
    // is refused and the arm above is not, then the action-invoke path is not what differs,
    // and neither is the target: the RunObject declaration is.
    [Test]
    procedure ControlTriggerActionOpeningTheSameTargetWithoutAHandlerIsRefused()
    var
        Log: Record "TPARONH Log";
        Host: TestPage "TPARONH Host";
    begin
        Initialize();
        Commit();

        Host.OpenEdit();
        Host.First();
        asserterror Host.RunCardViaTrigger.Invoke();
        Assert.ExpectedError('Unhandled UI');

        Assert.IsFalse(Log.Get('CARD'), 'a refused action must not have reached any handler');
    end;

    // DIAGNOSTIC, outcome not known in advance -- this is what the next reader most wants and
    // what no run so far has answered. The arm at the top says only that nothing was RAISED;
    // it cannot say whether the target opened, because a handler is what would observe that
    // and a handler only runs when it is bound. This target records its own OnOpenPage, so the
    // page itself reports. The claim is the same one every other route in the corpus honours:
    // a page must not open with nobody to answer it.
    [Test]
    procedure RunObjectActionWithoutAHandlerMustNotOpenItsTarget()
    var
        Log: Record "TPARONH Log";
        Host: TestPage "TPARONH Host";
    begin
        Initialize();
        Commit();

        Host.OpenEdit();
        Host.First();
        Host.RunLoggingCardOnRec.Invoke();

        Assert.IsFalse(Log.Get('OPENED'),
            'an action invoked with no handler bound must not open its target page unattended');
    end;

    // PROBE CONTROL, expected to PASS, and without it the diagnostic above could pass for the
    // wrong reason. It proves the OnOpenPage record IS written and IS visible to the test when
    // the page really does open -- so an 'OPENED' row missing above means the page did not
    // open, not that the probe is broken.
    [Test]
    [HandlerFunctions('LoggingTargetPageHandler')]
    procedure ProbeControlTheLoggingTargetRecordsItsOwnOpening()
    var
        Row: Record "TPARONH Row";
        Log: Record "TPARONH Log";
    begin
        Initialize();

        Row.Get('B');
        Page.Run(Page::"TPARONH Logging Target", Row);

        Assert.IsTrue(Log.Get('OPENED'),
            'the logging target must record its own OnOpenPage when it really opens');
        Assert.AreEqual('Bravo', Log.Detail,
            'the logging target must have opened on the record it was handed');
    end;

    [PageHandler]
    procedure LoggingTargetPageHandler(var Target: TestPage "TPARONH Logging Target")
    begin
        Target.Close();
    end;
}
