// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpage-drilldown-method
// Scope: in-scope
// Fixtures used: Test Page DrillDown Row (60950), Test Page DrillDown List (60951), Assert (60021)
//
// Pins TestPage.<field>.DrillDown() to the control's own OnDrillDown trigger — the field-level
// counterpart of TestPageActionInvoke_Tests, which pins the same contract for actions.
//
// The negatives carry the weight, same reasoning as the action suite: a DrillDown() that is a
// literal no-op fails nothing at the call site — the test only trips one step later on the
// missing side effect, pointing at the wrong place. So one test proves the trigger runs at
// all, one proves it runs against the page's current row, one proves an Error raised inside
// OnDrillDown is not swallowed, one proves DrillDown() on one control does not run a
// DIFFERENT control's OnDrillDown even though both are bound to the same source field, and one
// records what DrillDown() does on a control with no OnDrillDown trigger declared at all.

codeunit 60952 "Test Page DrillDown Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "Test Page DrillDown Row";
    begin
        Row.DeleteAll();
    end;

    local procedure SeedRows()
    var
        Row: Record "Test Page DrillDown Row";
    begin
        Row.Init();
        Row."No." := 'A';
        Row.Descr := 'Alpha';
        Row.Insert();

        Row.Init();
        Row."No." := 'B';
        Row.Descr := 'Bravo';
        Row.Insert();
    end;

    // Positive: the trigger runs at all.
    [Test]
    procedure FieldDrillDownRunsTheOnDrillDownTrigger()
    var
        Row: Record "Test Page DrillDown Row";
        DrillList: TestPage "Test Page DrillDown List";
    begin
        Initialize();
        SeedRows();

        DrillList.OpenView();
        DrillList.First();
        DrillList.StampCol.DrillDown();
        DrillList.Close();

        Assert.IsTrue(Row.Get('DRILL'), 'DrillDown() must have run the control''s OnDrillDown trigger');
    end;

    // Positive: the trigger runs in the PAGE's context — it reads Rec, and must see the row
    // the page is positioned on, exactly like TestPageActionInvoke's row-context check.
    [Test]
    procedure FieldDrillDownRunsAgainstThePagesCurrentRow()
    var
        Row: Record "Test Page DrillDown Row";
        DrillList: TestPage "Test Page DrillDown List";
    begin
        Initialize();
        SeedRows();

        DrillList.OpenView();
        DrillList.First();
        DrillList.Next();
        DrillList.StampCol.DrillDown();
        DrillList.Close();

        Assert.IsTrue(Row.Get('DRILL'), 'the trigger must have run');
        Assert.AreEqual('B', Row.Descr,
            'the trigger''s OnDrillDown must have seen the row the page is positioned on');
    end;

    // Negative: an Error raised inside OnDrillDown must reach the test. Swallowing it would
    // make a genuinely failing drilldown look like a passing one.
    [Test]
    procedure FieldDrillDownPropagatesAnErrorRaisedInsideOnDrillDown()
    var
        DrillList: TestPage "Test Page DrillDown List";
    begin
        Initialize();
        SeedRows();

        DrillList.OpenView();
        DrillList.First();
        asserterror DrillList.FailCol.DrillDown();
        Assert.ExpectedError('Test Page DrillDown control refused deliberately');
    end;

    // Negative: two controls bound to the SAME source field (Descr) declare DIFFERENT
    // OnDrillDown triggers. Drilling down on one must not run the other's — a dispatch that
    // matched by source field rather than by control would pass every test above while
    // running the wrong trigger.
    [Test]
    procedure FieldDrillDownRunsOnlyTheInvokedControlsTrigger()
    var
        Row: Record "Test Page DrillDown Row";
        DrillList: TestPage "Test Page DrillDown List";
    begin
        Initialize();
        SeedRows();

        DrillList.OpenView();
        DrillList.First();
        DrillList.StampCol.DrillDown();
        DrillList.Close();

        Assert.IsTrue(Row.Get('DRILL'), 'the invoked control''s trigger must have run');
        Assert.IsFalse(Row.Get('OTHER'),
            'drilling down on StampCol must not have run OtherCol''s OnDrillDown trigger');
    end;

    // A control with no OnDrillDown trigger at all. Recorded rather than assumed — see the
    // control case above (FailCol) and the trigger case (StampCol) for what DOES happen when
    // a trigger exists; this is what happens when one is entirely absent.
    [Test]
    procedure FieldDrillDownWithNoTriggerDoesNothingAndDoesNotThrow()
    var
        Row: Record "Test Page DrillDown Row";
        DrillList: TestPage "Test Page DrillDown List";
    begin
        Initialize();
        SeedRows();

        DrillList.OpenView();
        DrillList.First();
        DrillList.PlainCol.DrillDown();
        DrillList.Close();

        Assert.IsFalse(Row.Get('DRILL'), 'a control with no OnDrillDown trigger must not run a different control''s trigger');
        Assert.IsFalse(Row.Get('OTHER'), 'a control with no OnDrillDown trigger must not run a different control''s trigger');
    end;
}
