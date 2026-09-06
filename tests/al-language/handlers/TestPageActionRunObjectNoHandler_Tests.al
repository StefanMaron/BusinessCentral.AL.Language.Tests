// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runobject-property
// Scope: in-scope
// Fixtures used: TPARONH Row (60280), TPARONH Card Target (60281),
//                TPARONH Logging Target (60282), TPARONH Host (60283), TPARONH Log (60284),
//                Assert (60021)
//
// What a page action's RunObject does when the test binds NO handler at all.
//
// Every other route BC offers for opening a page is refused when nothing is bound to answer
// it. The corpus pins two of them, and both pass on all eight BC versions this corpus runs:
// TestPageRunHandler_Tests.NonModalPageRunWithoutAHandlerIsRefused calls Page.Run straight
// from the test, and TestPageModalHandler_Tests.ModalPageWithoutAHandlerIsRefused invokes a
// page ACTION whose OnAction trigger calls Page.RunModal. Controls 2 and 3 below repeat both
// shapes on this codeunit's own fixtures, and they pass here too.
//
// The RunObject route does not behave that way. Measured on BC 27.0, 27.3, 27.5, 28.0, 28.1,
// 28.2, 28.3 and 28.4, identically on every one:
//
//   * Invoking the action raises nothing AL can see. An asserterror around the invoke fails
//     with "An error was expected inside an ASSERTERROR statement".
//   * The target page opens anyway. It runs its own OnOpenPage trigger, with nobody bound to
//     answer it.
//
// So the invoke is not dropped and the page is not refused. The page really opens; AL is
// simply never told. That is what arm 1 records, and it is the opposite of what this file
// asserted when it was first written.
//
// ---------------------------------------------------------------------------------------
// THE MECHANISM
//
// Read out of Microsoft's shipped assemblies -- Microsoft.Dynamics.Nav.Ncl.dll and
// Microsoft.Dynamics.Nav.Types.dll from BC 27.5. Nothing below is inferred from documentation
// or from a name; it is what Microsoft's own IL says, and it can be re-read there.
//
// One method decides whether an unattended page is refused. NavTestExecution.FindHandler:
//
//     private MethodInfo FindHandler(NavHandlerType handlerType,
//                                    NavApplicationObjectBase appObject,
//                                    bool throwIfNotFound = true,
//                                    string handlerDescription = null)
//     {
//         MethodInfo methodInfo = FindHandler(ha => ha.HandlerType == handlerType, appObject);
//         if (methodInfo == null && throwIfNotFound
//             && executingTestRunner != null && executingTestMethod != null)
//             throw new NavNCLMissingUIHandlerException(...);
//         return methodInfo;
//     }
//
// Both places that look a page handler up call the TWO-argument form, so both take the
// throwIfNotFound = true default, and both remaining guards hold for every test in this corpus
// -- a test method is executing, under a test runner:
//
//     NavTestExecution.TestHandleForm  -- its only caller in Ncl.dll is NavForm.RunAsync
//                                        (compiled as NavForm.<RunAsync>d__19), which is what
//                                        AL's own Page.Run / Page.RunModal await.
//     NavTestExecution.ShowForm       -- Ncl.dll contains NO caller for it; it is reached from
//                                        the client-callback layer above Ncl.
//
// Each of the two has a "no handler found" branch of its own, and NEITHER can be reached while
// a test is running, because the FindHandler call above it has already thrown:
//
//     TestHandleForm:  if (methodInfo == null) return false;
//     ShowForm:        if (methodInfo == null)
//                          throw NavTestPageInvokedWithoutHandlerException.Create(...);
//
// The two exception types are not interchangeable, and that is where the routes part
// (hierarchy verified in Microsoft.Dynamics.Nav.Types.dll):
//
//     NavNCLMissingUIHandlerException
//         -> NavNCLException -> NavException -> NavBaseException
//     NavTestPageInvokedWithoutHandlerException
//         -> NavTestBaseException -> NavNCLException -> NavException -> NavBaseException
//
// Only the second is a NavTestBaseException. A NavBaseException that is not a
// NavTestBaseException is handled by the form-showing path as an ordinary UI error -- shown,
// with the form force-closed -- instead of being rethrown into AL. The type Microsoft actually
// throws here is therefore the one AL cannot see.
//
// Why that matters on one route and not the other, and why the page still opens:
//
//   * Page.Run / Page.RunModal (controls 2 and 3): FindHandler throws from TestHandleForm
//     while NavForm.RunAsync is still on AL's own call stack, so the error surfaces to AL as
//     an ordinary runtime error -- "Unhandled UI". TestHandleForm also calls
//     Company.RegisterForm(form) only AFTER the handler lookup has succeeded, so on this route
//     a handler-less form is never registered and never opens. Nothing runs its OnOpenPage.
//     That is exactly what controls 2 and 3 measure.
//
//   * The RunObject action: Ncl.dll has no code that runs an action's RunObject at all -- its
//     only RunObject members are metadata and permission helpers -- so the target is opened by
//     the client-services layer above it. ShowForm, the handler lookup on that side, opens with
//     Company.GetRegisteredForm(handle): the form already EXISTS and is already REGISTERED
//     before any handler is looked for. So the page has been built and its OnOpenPage has
//     already run by the time BC discovers nobody is bound, and the throw then happens off
//     AL's call stack. Both halves of the measurement follow: the OnOpenPage row is there, and
//     AL sees nothing.
//
// This looks like a defect in Microsoft's code rather than a decision. Microsoft wrote
// NavTestPageInvokedWithoutHandlerException -- a NavTestBaseException, the kind that WOULD
// have reached AL -- for precisely this case, and their own throwIfNotFound = true default
// preempts it with a type that does not, leaving that throw statement unreachable. That
// reading explains the measurement; it is NOT what this codeunit asserts. What it asserts is
// only what eight service tiers did.
//
// Provenance, so a later reader can check this without its authors: the mechanism above is
// read from Microsoft's shipped IL and can be re-read from any BC 27.x or 28.x install. Every
// runtime number is from this corpus's CI, which runs a Linux BC image. That image is patched,
// so a stock Windows service tier could in principle differ -- but the exception hierarchy and
// the throwIfNotFound default are Microsoft's own, unpatched, and they predict what was
// measured.
// ---------------------------------------------------------------------------------------
//
// The five arms are one experiment, and the controls are what make arm 1 mean anything:
//
//   1. RunObjectActionWithoutAHandlerOpensItsTargetUnattended -- the answer, and the only arm
//      with a positive observable. It invokes the RunObject action aimed at the target that
//      records its own OnOpenPage, with nothing bound. The invoke is deliberately NOT wrapped
//      in asserterror: the claim is that nothing is raised, so a refusal fails the test on the
//      invoke line itself. The host is left on its SECOND row, so an open that did not carry
//      the host's record would report 'Alpha' instead of 'Bravo'.
//   2. ControlPageRunOnTheSameTargetWithoutAHandlerIsRefused -- the same target page, opened by
//      a plain AL Page.Run with no host page in the picture at all. It IS refused, which rules
//      out the target page and the fixture set. Passes.
//   3. ControlTriggerActionOpeningTheSameTargetWithoutAHandlerIsRefused -- same host, same
//      invoke, same target, same row; the action's effect is an OnAction trigger calling
//      Page.Run instead of a RunObject property. Rules out the action-invoke path. Passes.
//      With 2 and 3 passing, the RunObject DECLARATION is the only thing left that differs.
//   4. RunObjectActionOnTheControlsTargetWithoutAHandler_NoThrow -- the same action 2 and 3
//      mirror, aimed at the CLEAN Card target rather than the logging one, so the comparison
//      has a RunObject side on exactly the page those two controls refuse. Its whole claim is
//      that the statement completes, which is why its name says so: the clean target records
//      nothing by design, so there is nothing further here to assert.
//   5. ProbeControlTheLoggingTargetRecordsItsOwnOpening -- proves the probe arm 1 rests on.
//      With a handler bound, the logging target really does write its OPENED row and the test
//      really can read it, so the row arm 1 finds means the page opened rather than that the
//      probe writes that row regardless. Passes.
//
// Held out of the eight-test RunObject suite (TestPageActionRunObject_Tests, codeunit 60455)
// while this question was open, so that suite could merge; it stays silent on the no-handler
// case and points here. Tracked as AL Runner issue 2975, which was filed when the RunObject
// route appeared to open nothing at all on this tier. That premise no longer holds: codeunit
// 60455 is green on all eight versions, so the route does open its target and does reach a
// bound [PageHandler] -- and this codeunit settles the remaining arm, which is that it opens
// the target with no handler bound too.
//
// Written by an agent (impl-1 built the experiment; impl-5 settled it and rewrote this note).

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

    // THE ANSWER. No [HandlerFunctions] at all, on an action whose effect is declared with
    // RunObject. Every other route BC offers refuses this; the RunObject route does not. The
    // invoke is NOT wrapped in asserterror -- the claim is that nothing is raised, so if BC
    // refused it the way controls 2 and 3 below are refused, this test fails on the invoke
    // line with an unhandled 'Unhandled UI' error rather than passing quietly.
    //
    // The target then reports its own opening: the host is parked on the SECOND row, so an
    // implementation that opened the target without the host's record reads 'Alpha' here, and
    // one that did not open it at all finds no row at all. Arm 5 proves the probe works.
    [Test]
    procedure RunObjectActionWithoutAHandlerOpensItsTargetUnattended()
    var
        Log: Record "TPARONH Log";
        Host: TestPage "TPARONH Host";
    begin
        Initialize();
        Commit();

        Host.OpenEdit();
        Host.First();
        Host.Next();
        Host.RunLoggingCardOnRec.Invoke();

        Assert.IsTrue(Log.Get('OPENED'),
            'a RunObject action invoked with no handler bound still opens its target page');
        Assert.AreEqual('Bravo', Log.Detail,
            'the unattended target opens on the host page''s current row, as RunPageOnRec = true');
    end;

    // CONTROL 1, passes. The very page the action above names, opened by a plain AL Page.Run
    // with no handler bound and no host page in the picture at all. It IS refused, which rules
    // out the target page, the fixture set and the absence of handlers as explanations for arm
    // 1. If this ever fails, arm 1 says nothing about RunObject and the comparison has to be
    // rebuilt.
    //
    // The asserterror IS the whole assertion, deliberately. The Card Target is kept free of an
    // OnOpenPage on purpose (see the objects file), so it writes nothing whether it opens or
    // not, and there is no post-invoke observable this arm could read. A log assertion here
    // would be unfalsifiable, which is why there is none.
    [Test]
    procedure ControlPageRunOnTheSameTargetWithoutAHandlerIsRefused()
    var
        Row: Record "TPARONH Row";
    begin
        Initialize();
        Commit();

        Row.Get('B');
        asserterror Page.Run(Page::"TPARONH Card Target", Row);
        Assert.ExpectedError('Unhandled UI');
    end;

    // CONTROL 2, passes, and the one that narrows the difference to the declaration. Same host
    // page, same invoke, same target, same row, same absent handler -- the action's effect is
    // an OnAction trigger calling Page.Run instead of a RunObject property. It IS refused, so
    // the action-invoke path is not what differs, and neither is the target: the RunObject
    // declaration is.
    //
    // As with control 1, the asserterror is the whole assertion: this arm opens the same clean
    // Card Target, which records nothing either way.
    [Test]
    procedure ControlTriggerActionOpeningTheSameTargetWithoutAHandlerIsRefused()
    var
        Host: TestPage "TPARONH Host";
    begin
        Initialize();
        Commit();

        Host.OpenEdit();
        Host.First();
        asserterror Host.RunCardViaTrigger.Invoke();
        Assert.ExpectedError('Unhandled UI');
    end;

    // The RunObject side of the comparison the two controls above set up: the SAME target page
    // they open, reached the one way that is not refused. Arm 1 had to switch to the logging
    // target to observe the opening, so without this arm nothing exercises RunObject against
    // the exact page controls 1 and 2 refuse.
    //
    // The whole claim is that the statement completes -- hence the name. The Card target is
    // deliberately kept clean, with no OnOpenPage of its own, so that the two refusal controls
    // cannot be disturbed by a write happening before BC refuses; that leaves nothing further
    // for this arm to assert. If BC refused this invoke the way it refuses controls 1 and 2,
    // the unhandled error would fail the test here.
    [Test]
    procedure RunObjectActionOnTheControlsTargetWithoutAHandler_NoThrow()
    var
        Host: TestPage "TPARONH Host";
    begin
        Initialize();
        Commit();

        Host.OpenEdit();
        Host.First();
        Host.RunCardOnRec.Invoke();
    end;

    // PROBE CONTROL, passes, and without it arm 1 could pass for the wrong reason. It proves
    // the OnOpenPage row IS written and IS visible to the test when the page really does open,
    // so the 'OPENED' row arm 1 finds means the page opened rather than that the probe writes
    // that row regardless.
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
