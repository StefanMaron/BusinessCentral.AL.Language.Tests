// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runobject-property
// Scope: in-scope
// Fixtures used: TPARO Row (60450), TPARO Card Target (60451), TPARO Dialog Target (60452),
//                TPARO Host (60453), TPARO Log (60454), Assert (60021)
//
// Pins what happens when a test invokes a page action whose effect is RunObject rather than
// an OnAction trigger.
//
// The corpus already pins the trigger half (TestPageActionInvoke_Tests) and the two page
// dispatch halves reached from AL (TestPageRunHandler_Tests for Page.Run, TestPageModalHandler
// for Page.RunModal). Nothing yet says what an ACTION's RunObject does, and it is not the same
// question: no AL runs at all, so the platform alone decides whether a page opens, which page,
// on which record, and which handler answers it. Microsoft's own code depends on the answer --
// Base Application 26.0 deprecated several `Statistics` actions with the note "the new action
// uses RunObject and does not run the action trigger", and the tests that drive them changed
// handler kind at the same time.
//
// Four claims, each with a negative a plausible wrong implementation fails:
//   1. The target opens and reaches a [PageHandler] -- so an implementation that quietly did
//      nothing (the shape that fails one step later, complaining about a missing effect) is
//      caught here instead.
//   2. RunPageOnRec = true hands the target the HOST's current row. Every assertion uses the
//      SECOND row, so an implementation that opened the target unpositioned reads 'Alpha'.
//   3. The handler KIND follows the target's PageType, not the action: an ordinary Card target
//      is answered by [PageHandler], a StandardDialog target by [ModalPageHandler]. Asserting
//      only one of the two would let "always modal" or "always non-modal" pass.
//   4. With no handler declared the invoke is refused with BC's own unhandled-UI error, and
//      an actionref pointing at a RunObject action behaves exactly like the action itself.

codeunit 60455 "TPARO Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "TPARO Row";
        Log: Record "TPARO Log";
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

    // Positive, claim 1 + 2: invoking a RunObject action opens the target page, the target is
    // answered by the [PageHandler] declared for it, and RunPageOnRec = true positions it on
    // the host's CURRENT row. 'Bravo' is the second row, so an implementation that opened the
    // target without the host's record would report 'Alpha' here.
    [Test]
    [HandlerFunctions('CardTargetPageHandler')]
    procedure RunObjectActionOpensTheTargetOnTheHostsCurrentRow()
    var
        Log: Record "TPARO Log";
        Host: TestPage "TPARO Host";
    begin
        Initialize();

        Host.OpenEdit();
        Host.First();
        Host.Next();
        Host.RunCardOnRec.Invoke();
        Host.Close();

        Assert.IsTrue(Log.Get('CARD'), 'the RunObject action must have opened its target page');
        Assert.AreEqual('Bravo', Log.Detail,
            'RunPageOnRec = true must open the target on the host page''s current row');
    end;

    // Positive, claim 3: the same host, a target that differs from the first ONLY in PageType.
    // A StandardDialog is shown as a dialog, so it is a [ModalPageHandler] that answers it --
    // not the [PageHandler] kind the Card target above needs. Declaring only the modal handler
    // here is what makes the claim testable: if the platform opened it non-modally the test
    // fails with an unhandled-UI error rather than passing quietly.
    [Test]
    [HandlerFunctions('DialogTargetModalHandler')]
    procedure RunObjectActionToAStandardDialogTargetIsAnsweredByTheModalHandler()
    var
        Log: Record "TPARO Log";
        Host: TestPage "TPARO Host";
    begin
        Initialize();

        Host.OpenEdit();
        Host.First();
        Host.Next();
        Host.RunDialogOnRec.Invoke();
        Host.Close();

        Assert.IsTrue(Log.Get('DIALOG'),
            'a StandardDialog RunObject target must be answered by the [ModalPageHandler]');
        Assert.AreEqual('Bravo', Log.Detail,
            'RunPageOnRec = true must open the dialog target on the host page''s current row');
    end;

    // Positive, claim 4: an actionref is a delegating reference, so promoting a RunObject
    // action must invoke the same RunObject -- not "declares no trigger". An implementation
    // that resolved RunObject only for the action's own id would pass the first test and fail
    // this one.
    [Test]
    [HandlerFunctions('CardTargetPageHandler')]
    procedure ActionrefToARunObjectActionOpensTheSameTarget()
    var
        Log: Record "TPARO Log";
        Host: TestPage "TPARO Host";
    begin
        Initialize();

        Host.OpenEdit();
        Host.First();
        Host.Next();
        Host.RunCardOnRec_Promoted.Invoke();
        Host.Close();

        Assert.IsTrue(Log.Get('CARD'),
            'invoking the promoted actionref must open the target its action names');
        Assert.AreEqual('Bravo', Log.Detail,
            'the actionref must carry the same RunPageOnRec behaviour as its target action');
    end;

    // Negative, claim 4: no [HandlerFunctions] at all. Opening a page unattended must be
    // refused with BC's own unhandled-UI error. An implementation that opened the target and
    // carried on would pass every positive above and fail only here.
    [Test]
    procedure RunObjectActionWithoutAHandlerIsRefused()
    var
        Log: Record "TPARO Log";
        Host: TestPage "TPARO Host";
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

    // Negative, claim 1: an action that DOES declare an OnAction trigger must still run its
    // trigger and must not open anything. Without this, an implementation that resolved every
    // action to "open something" would pass the positives and silently break every ordinary
    // action on the same page.
    [Test]
    procedure AnActionWithATriggerStillRunsItsTriggerAndOpensNothing()
    var
        Log: Record "TPARO Log";
        Host: TestPage "TPARO Host";
    begin
        Initialize();

        Host.OpenEdit();
        Host.First();
        Host.Next();
        Host.HasTrigger.Invoke();
        Host.Close();

        Assert.IsTrue(Log.Get('TRIGGER'), 'an action with an OnAction trigger must run it');
        Assert.AreEqual('B', Log.Detail,
            'the trigger must have run against the host page''s current row');
        Assert.IsFalse(Log.Get('CARD'),
            'an action with a trigger must not open any RunObject target');
    end;

    // CONTROL, and the arm that decides how to read every failure above. It reaches the SAME
    // [PageHandler], writes the SAME Log row and asserts the SAME value, but opens the target
    // with a plain AL Page.Run instead of through an action. If this passes and the action arms
    // fail, the handler declaration, the [HandlerFunctions] binding and the Log table are all
    // proven good and the difference is the ACTION route alone. If this fails too, the failures
    // above say nothing about RunObject at all.
    [Test]
    [HandlerFunctions('CardTargetPageHandler')]
    procedure ControlPageRunReachesTheSameHandler()
    var
        Row: Record "TPARO Row";
        Log: Record "TPARO Log";
    begin
        Initialize();

        Row.Get('B');
        Page.Run(Page::"TPARO Card Target", Row);

        Assert.IsTrue(Log.Get('CARD'), 'a plain Page.Run must reach the [PageHandler]');
        Assert.AreEqual('Bravo', Log.Detail,
            'the [PageHandler] must be handed the record Page.Run was given');
    end;

    // Microsoft's own shape is a DOCUMENT/Card host with the action inside a group under
    // area(Navigation). These two arms vary the host PageType and the action's container
    // independently, so one run says which construction (if any) opens the target.
    [Test]
    [HandlerFunctions('CardTargetPageHandler')]
    procedure RunObjectFromACardHostProcessingArea()
    var
        Row: Record "TPARO Row";
        Log: Record "TPARO Log";
        Host: TestPage "TPARO Card Host";
    begin
        Initialize();

        Row.Get('B');
        Host.OpenEdit();
        Host.GotoRecord(Row);
        Host.RunCardFromProcessing.Invoke();
        Host.Close();

        Assert.IsTrue(Log.Get('CARD'),
            'a RunObject action on a Card host, in area(Processing), must open its target');
        Assert.AreEqual('Bravo', Log.Detail,
            'RunPageOnRec = true must open the target on the host page''s current row');
    end;

    [Test]
    [HandlerFunctions('CardTargetPageHandler')]
    procedure RunObjectFromACardHostNavigationGroup()
    var
        Row: Record "TPARO Row";
        Log: Record "TPARO Log";
        Host: TestPage "TPARO Card Host";
    begin
        Initialize();

        Row.Get('B');
        Host.OpenEdit();
        Host.GotoRecord(Row);
        Host.RunCardFromNavigationGroup.Invoke();
        Host.Close();

        Assert.IsTrue(Log.Get('CARD'),
            'a RunObject action in a group under area(Navigation) -- Microsoft''s own shape -- must open its target');
        Assert.AreEqual('Bravo', Log.Detail,
            'RunPageOnRec = true must open the target on the host page''s current row');
    end;

    [PageHandler]
    procedure CardTargetPageHandler(var Target: TestPage "TPARO Card Target")
    var
        Log: Record "TPARO Log";
    begin
        Log.Init();
        Log.Entry := 'CARD';
        Log.Detail := CopyStr(Target.Descr.Value(), 1, MaxStrLen(Log.Detail));
        if not Log.Insert() then
            Log.Modify();
    end;

    [ModalPageHandler]
    procedure DialogTargetModalHandler(var Target: TestPage "TPARO Dialog Target")
    var
        Log: Record "TPARO Log";
    begin
        Log.Init();
        Log.Entry := 'DIALOG';
        Log.Detail := CopyStr(Target.Descr.Value(), 1, MaxStrLen(Log.Detail));
        if not Log.Insert() then
            Log.Modify();
    end;
}
