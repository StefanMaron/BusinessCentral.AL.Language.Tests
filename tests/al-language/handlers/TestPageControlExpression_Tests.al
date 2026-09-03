// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-visible-method
// Scope: in-scope
// Fixtures used: TPCE Row (60257), TPCE Card (60258), Assert (60021)
//
// Visible, Editable and Enabled on a page control take an AL client expression, not only a
// variable name, and TestPage.<field>.Visible() / .Editable() / .Enabled() must report what that
// expression currently evaluates to. Each test below flips the inputs and reads the property in
// both states, so none of them can pass against an implementation that answers a constant.
//
// The shapes covered are the ones the AL compiler allows in a client expression: a page global,
// `not` over one, `and` / `or` over two, `not` over a parenthesized group, a source-table field
// reference, `not` over one, and a comparison. A procedure call is not among them — the compiler
// rejects it with AL0322.
//
// PlainGlobal is the baseline. It is the only shape whose property text is a single identifier,
// and it is asserted in both states alongside NotGlobal so that a change which taught the platform
// the harder shapes at the cost of the simple one would fail here.

codeunit 60259 "TPCE Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "TPCE Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'ROW1';
        Row.Value := 'Some Value';
        Row.Flag := false;
        Row.Insert();
    end;

    // Baseline. A property bound to a bare page global reports that global's value, both ways.
    [Test]
    procedure PlainGlobal_ReportsTheGlobalsValue()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize();

        Card.OpenEdit();
        Assert.IsFalse(Card.PlainGlobal.Visible(), 'Visible = HideIt must be false while HideIt is false');

        Card.ToggleHide.SetValue(true);
        Assert.IsTrue(Card.PlainGlobal.Visible(), 'Visible = HideIt must be true once HideIt is true');
        Card.Close();
    end;

    // `not` over a page global is the inverse of the baseline, in both states.
    [Test]
    procedure NotGlobal_ReportsTheNegatedGlobal()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize();

        Card.OpenEdit();
        Assert.IsTrue(Card.NotGlobal.Visible(), 'Visible = not HideIt must be true while HideIt is false');

        Card.ToggleHide.SetValue(true);
        Assert.IsFalse(Card.NotGlobal.Visible(), 'Visible = not HideIt must be false once HideIt is true');
        Card.Close();
    end;

    // `and` needs both operands. Three of the four input combinations are false, and the test
    // reads two of them plus the true one, so an implementation that returned either operand
    // alone, or a constant, fails.
    [Test]
    procedure AndGlobals_RequireBothOperands()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize();

        Card.OpenEdit();
        Assert.IsFalse(Card.AndGlobals.Visible(), 'HideIt and LockIt must be false while both are false');

        Card.ToggleHide.SetValue(true);
        Assert.IsFalse(Card.AndGlobals.Visible(), 'HideIt and LockIt must be false while only HideIt is true');

        Card.ToggleLock.SetValue(true);
        Assert.IsTrue(Card.AndGlobals.Visible(), 'HideIt and LockIt must be true once both are true');
        Card.Close();
    end;

    // `or` needs one operand. Same three input combinations, opposite answers, which is what
    // separates a real evaluation from one that treats every binary operator the same.
    [Test]
    procedure OrGlobals_NeedOnlyOneOperand()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize();

        Card.OpenEdit();
        Assert.IsFalse(Card.OrGlobals.Visible(), 'HideIt or LockIt must be false while both are false');

        Card.ToggleHide.SetValue(true);
        Assert.IsTrue(Card.OrGlobals.Visible(), 'HideIt or LockIt must be true once HideIt is true');
        Card.Close();
    end;

    // `not` applied to a parenthesized group, not to the first operand. With HideIt true and
    // LockIt false, `not (HideIt or LockIt)` is false while `(not HideIt) or LockIt` would be
    // false too, so the test also reads the both-false state where the two disagree: `not (false
    // or false)` is true.
    [Test]
    procedure NotParenthesized_NegatesTheWholeGroup()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize();

        Card.OpenEdit();
        Assert.IsTrue(Card.NotParenthesized.Visible(), 'not (HideIt or LockIt) must be true while both are false');

        Card.ToggleLock.SetValue(true);
        Assert.IsFalse(Card.NotParenthesized.Visible(), 'not (HideIt or LockIt) must be false once LockIt is true');
        Card.Close();
    end;

    // A source-table field reference, not a page global. The control has no variable behind it;
    // the expression reads Rec.
    [Test]
    procedure RecFieldRef_ReadsTheSourceRecordsField()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize();

        Card.OpenEdit();
        Assert.IsFalse(Card.RecFieldRef.Visible(), 'Visible = Rec.Flag must be false while Flag is false');

        Card.ToggleFlag.SetValue(true);
        Assert.IsTrue(Card.RecFieldRef.Visible(), 'Visible = Rec.Flag must be true once Flag is true');
        Card.Close();
    end;

    // `not` over a field reference. Read alongside RecFieldRef in the same states, so an
    // implementation that resolved the field but dropped the `not` fails exactly here.
    [Test]
    procedure NotRecFieldRef_NegatesTheSourceRecordsField()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize();

        Card.OpenEdit();
        Assert.IsTrue(Card.NotRecFieldRef.Visible(), 'Visible = not Rec.Flag must be true while Flag is false');

        Card.ToggleFlag.SetValue(true);
        Assert.IsFalse(Card.NotRecFieldRef.Visible(), 'Visible = not Rec.Flag must be false once Flag is true');
        Card.Close();
    end;

    // A comparison against a literal. Initialize() gives Value a non-empty string, so the control
    // starts visible; blanking Value through the page makes it false.
    [Test]
    procedure Comparison_EvaluatesAgainstTheLiteral()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize();

        Card.OpenEdit();
        Assert.IsTrue(Card.Comparison.Visible(), 'Visible = Rec.Value <> '''' must be true while Value is ''Some Value''');

        Card.NotGlobal.SetValue('');
        Assert.IsFalse(Card.Comparison.Visible(), 'Visible = Rec.Value <> '''' must be false once Value is blank');
        Card.Close();
    end;

    // The same grammar governs Editable, not only Visible.
    [Test]
    procedure NotGlobal_GovernsEditable()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize();

        Card.OpenEdit();
        Assert.IsTrue(Card.NotEditable.Editable(), 'Editable = not LockIt must be true while LockIt is false');

        Card.ToggleLock.SetValue(true);
        Assert.IsFalse(Card.NotEditable.Editable(), 'Editable = not LockIt must be false once LockIt is true');
        Card.Close();
    end;

    // And Enabled.
    [Test]
    procedure NotGlobal_GovernsEnabled()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize();

        Card.OpenEdit();
        Assert.IsTrue(Card.NotEnabled.Enabled(), 'Enabled = not LockIt must be true while LockIt is false');

        Card.ToggleLock.SetValue(true);
        Assert.IsFalse(Card.NotEnabled.Enabled(), 'Enabled = not LockIt must be false once LockIt is true');
        Card.Close();
    end;
}
