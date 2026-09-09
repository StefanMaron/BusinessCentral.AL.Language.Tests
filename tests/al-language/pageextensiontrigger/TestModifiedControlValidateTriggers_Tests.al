// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-extension-object
// Scope: in-scope
// Fixtures used: MCV Row (60510), MCV Card (60511), MCV Card Ext (60512), MCV Other Ext (60513), Assert (60021)
//
// What a pageextension's `modify(Control)` validation triggers do when the extended page is
// driven as a TestPage.
//
// The claim under test is an ORDER: OnBeforeValidate, then the base control's own
// OnValidate, then OnAfterValidate. Each trigger appends its own tag to Rec.Trace, so the
// assertion is on one concrete string and cannot be satisfied by a run that fired the right
// triggers in the wrong order, nor by one that fired only some of them.
//
// Scoped to the SUCCESS path on purpose. What an Error() inside OnBeforeValidate leaves in
// the page's buffer is a separate claim about BC and is not asserted here -- see the note
// below the third arm.
//
// The OnAssistEdit arms pin the third control-acting modify() trigger, and the base-page form
// of the same trigger. Both were entirely unstated: BC's ITestField.AssistEdit returns void,
// so "the trigger ran" and "nothing happened" are the same observable unless the trigger
// leaves a trace behind, which is why every assist-edit arm asserts on Rec.Trace.

codeunit 60514 "MCV Validate Trigger Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "MCV Row";
    begin
        Row.DeleteAll();
    end;

    // The whole claim, in one value: before, base, after — in that order, each exactly once.
    //
    // Reading the trace back through the page's own Trace control rather than from the table
    // keeps the assertion about what the page committed, and an implementation that ran no
    // extension trigger at all answers 'page;' here, which is what this suite's absence
    // allowed to ship.
    [Test]
    procedure ModifiedControlBeforeAndAfterValidateWrapTheBaseControlsOwnOnValidate()
    var
        Card: TestPage "MCV Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(1);
        Card.Name.SetValue('value');

        Assert.AreEqual('before;page;after;', Card.Trace.Value(),
          'a modify() block''s OnBeforeValidate must run before the base control''s OnValidate and its OnAfterValidate after it');

        Card.Close();
    end;

    // Negative on ORDER specifically: the base control's own OnValidate is not replaced by
    // the extension's triggers, and it runs BETWEEN them rather than before or after both.
    // Without this arm an implementation appending 'before;after;page;' passes nothing here
    // that the arm above would not already have caught, but stating it separately is what
    // makes the middle position an asserted property rather than an incidental one.
    [Test]
    procedure TheBaseControlsOwnOnValidateStillRunsAndRunsBetweenTheTwo()
    var
        Card: TestPage "MCV Card";
        Trace: Text;
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(2);
        Card.Name.SetValue('value');
        Trace := Card.Trace.Value();
        Card.Close();

        Assert.AreEqual(1, StrPos(Trace, 'before;'),
          'OnBeforeValidate must be the first trigger to append');
        Assert.AreEqual(StrPos(Trace, 'before;') + StrLen('before;'), StrPos(Trace, 'page;'),
          'the base control''s OnValidate must append immediately after OnBeforeValidate');
        Assert.AreEqual(StrPos(Trace, 'page;') + StrLen('page;'), StrPos(Trace, 'after;'),
          'OnAfterValidate must append immediately after the base control''s OnValidate');
    end;

    // NOT COVERED HERE: what an Error() raised inside OnBeforeValidate leaves behind.
    //
    // An arm asserting that was in this suite when it was first opened, and real BC failed it
    // on all eight cloud legs, unanimously and deterministically -- Expected:<before;>,
    // Actual:<>. So the platform DISCARDS the in-memory Rec mutation the before-trigger made
    // when the enclosing SetValue raises, rather than leaving the partial write visible on
    // the still-open page. That is a claim about BC's page-write buffer, not about modify()
    // dispatch, and the arms above already pin the dispatch half on their own.
    //
    // It is left out rather than weakened: an assertion adjusted until the runner passes it
    // stops being evidence about BC. Tracked separately so it can be stated as its own claim,
    // measured on its own.

    // Negative: a modify() block targeting a DIFFERENT control is not raised for this one.
    // "MCV Other Ext" (60513) modifies Other, never Name, so validating Name must produce
    // none of its tags — an implementation raising every modify() trigger on the page fails
    // here while passing every arm above.
    [Test]
    procedure AModifyBlockOnAnotherControlIsNotRaisedForThisOne()
    var
        Card: TestPage "MCV Card";
        Trace: Text;
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(4);
        Card.Name.SetValue('value');
        Trace := Card.Trace.Value();
        Card.Close();

        Assert.AreEqual(0, StrPos(Trace, 'otherbefore;'),
          'the modify() block on the Other control must not be raised when Name is validated');
        Assert.AreEqual(0, StrPos(Trace, 'otherafter;'),
          'the modify() block on the Other control must not be raised when Name is validated');
    end;

    // Positive complement of the arm above: validating Other DOES raise its own extension's
    // triggers, around its own base OnValidate. Without this, "not raised for Name" would be
    // satisfied by an implementation that never raises that block at all.
    [Test]
    procedure TheOtherControlsOwnModifyBlockWrapsItsOwnBaseTrigger()
    var
        Card: TestPage "MCV Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(5);
        Card.Other.SetValue('value');

        Assert.AreEqual('otherbefore;otherpage;otherafter;', Card.Trace.Value(),
          'the Other control''s own modify() block must wrap the Other control''s own OnValidate');

        Card.Close();
    end;

    // Positive: a modify() block's OnDrillDown runs. Its absence has a LOUD answer on real
    // BC -- TestPage DrillDown() on a control with no trigger raises "The NavDrilldownAction
    // method is not supported." -- so this arm distinguishes "the extension's trigger ran"
    // from "nothing ran and the platform refused", which a silent no-op could not.
    [Test]
    procedure AModifyBlocksOnDrillDownRunsForTheModifiedControl()
    var
        Card: TestPage "MCV Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(7);
        Card.Extra.DrillDown();

        Assert.AreEqual('extdrill;', Card.Trace.Value(),
          'a modify() block''s OnDrillDown must run for the control it modifies');

        Card.Close();
    end;

    // Positive: a modify() block's OnLookup runs. Same argument as the drilldown arm -- a
    // control with no OnLookup trigger falls back to its TableRelation, so "the trigger ran"
    // and "nothing ran" are distinguishable observables here rather than both being silence.
    [Test]
    procedure AModifyBlocksOnLookupRunsForTheModifiedControl()
    var
        Card: TestPage "MCV Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(8);
        Card.Extra.Lookup();

        Assert.AreEqual('extlookup;', Card.Trace.Value(),
          'a modify() block''s OnLookup must run for the control it modifies');

        Card.Close();
    end;

    // Positive: a BASE-page control's own OnAssistEdit runs when the TestPage drives
    // AssistEdit(). Nothing in the corpus stated that it runs at all, and the observable is
    // silence either way -- BC's ITestField.AssistEdit returns void and an implementation
    // that does nothing is indistinguishable from one that dispatched, except through the
    // trigger's own effect. Hence the trace tag rather than a return value.
    [Test]
    procedure ABaseControlsOwnOnAssistEditRuns()
    var
        Card: TestPage "MCV Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(9);
        Card.Name.AssistEdit();

        Assert.AreEqual('baseassist;', Card.Trace.Value(),
          'a control''s own OnAssistEdit must run when the TestPage calls AssistEdit()');

        Card.Close();
    end;

    // Positive: a modify() block's OnAssistEdit runs for the control it modifies. Extra
    // declares no OnAssistEdit on the base page, so the extension's block is the only
    // possible source of this tag -- which is what makes this arm about the EXTENSION route
    // rather than a second reading of the arm above.
    [Test]
    procedure AModifyBlocksOnAssistEditRunsForTheModifiedControl()
    var
        Card: TestPage "MCV Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(10);
        Card.Extra.AssistEdit();

        Assert.AreEqual('extassist;', Card.Trace.Value(),
          'a modify() block''s OnAssistEdit must run for the control it modifies');

        Card.Close();
    end;

    // Negative on TARGETING: assist-editing Name must not raise the extension's block on
    // Extra, and assist-editing Extra must not raise Name's own trigger. An implementation
    // that raises every OnAssistEdit it can find on the page passes both arms above and
    // fails here.
    [Test]
    procedure OnAssistEditIsRaisedOnlyForTheControlItWasCalledOn()
    var
        Card: TestPage "MCV Card";
        AfterName: Text;
        AfterExtra: Text;
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(11);
        Card.Name.AssistEdit();
        AfterName := Card.Trace.Value();
        Card.Extra.AssistEdit();
        AfterExtra := Card.Trace.Value();
        Card.Close();

        Assert.AreEqual(0, StrPos(AfterName, 'extassist;'),
          'assist-editing Name must not raise the modify() block on Extra');
        Assert.AreEqual('baseassist;extassist;', AfterExtra,
          'each AssistEdit() must raise exactly its own control''s trigger, in call order');
    end;

    // Positive: OnAssistEdit runs once per call, not once per page. An implementation that
    // latches after the first dispatch, or raises at page open, fails here and passes the
    // arms above.
    [Test]
    procedure OnAssistEditRunsOncePerCall()
    var
        Card: TestPage "MCV Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(12);
        Card.Name.AssistEdit();
        Card.Name.AssistEdit();

        Assert.AreEqual('baseassist;baseassist;', Card.Trace.Value(),
          'each AssistEdit() call must run the trigger again');

        Card.Close();
    end;

    // Positive: the triggers run once per validate, not once per page. A second write to the
    // same control appends a second complete sequence — an implementation raising them once
    // at page open, or latching after the first write, fails here and passes arm one.
    [Test]
    procedure TheSequenceRunsOncePerValidateNotOncePerPage()
    var
        Card: TestPage "MCV Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Id.SetValue(6);
        Card.Name.SetValue('first');
        Card.Name.SetValue('second');

        Assert.AreEqual('before;page;after;before;page;after;', Card.Trace.Value(),
          'each SetValue must run the full before/base/after sequence, so two writes produce two sequences');

        Card.Close();
    end;
}
