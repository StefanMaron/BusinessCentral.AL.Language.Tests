// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-visible-method
// Scope: in-scope
// Fixtures used: TP Field Visible Row (60964), TP Field Visible Card (60959), Assert (60021)
//
// TestPage.<field>.Visible() must combine the control's OWN Visible with the Visible of EVERY
// group that wraps it, all the way up to the content area — not just its own declared value and
// not just its immediate parent's.
//
// FieldInNestedGroup is the case that tells apart "walks one level up" from "walks the whole
// chain": it sits inside InnerGroup, which declares no Visible of its own, wrapped by OuterGroup,
// which does. A fix that only consulted the immediate parent (InnerGroup, always Visible) would
// pass every other test here and still report FieldInNestedGroup visible while OuterGroup is
// hidden.

codeunit 60961 "Test Page Field Visible Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "TP Field Visible Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'ROW1';
        Row.Value := 'Some Value';
        Row.Insert();
    end;

    // Positive/baseline: a control that is not inside any group at all is unaffected by this
    // whole mechanism, and must stay visible.
    [Test]
    procedure FieldNotInAnyGroup_IsVisible()
    var
        Card: TestPage "TP Field Visible Card";
    begin
        Initialize();

        Card.OpenEdit();
        Assert.IsTrue(Card.RecValue.Visible(), 'a field outside any group must be visible by default');
        Card.Close();
    end;

    // Negative: the enclosing group's Visible is the literal `false` — the field declares no
    // Visible of its own, so this is purely the group's doing.
    [Test]
    procedure FieldInGroupWithLiteralFalseVisible_IsHidden()
    var
        Card: TestPage "TP Field Visible Card";
    begin
        Initialize();

        Card.OpenEdit();
        Assert.IsFalse(Card.FieldInStaticHiddenGroup.Visible(),
            'a field inside a group with Visible = false must be hidden even though the field itself declares no Visible');
        Card.Close();
    end;

    // Negative: the enclosing group's Visible is a page-variable expression currently false.
    [Test]
    procedure FieldInGroupWithFalseDynamicExpression_IsHidden()
    var
        Card: TestPage "TP Field Visible Card";
    begin
        Initialize();

        Card.OpenEdit();
        // ShowDynamic defaults to false, so DynamicGroup starts hidden.
        Assert.IsFalse(Card.FieldInDynamicGroup.Visible(),
            'a field inside a group whose Visible expression is currently false must be hidden');
        Card.Close();
    end;

    // Positive: flipping the SAME page-variable expression to true must flip the field visible
    // too — proves the group's Visible is evaluated live, not cached from OnOpenPage.
    [Test]
    procedure FieldInGroupWithTrueDynamicExpression_IsVisible()
    var
        Card: TestPage "TP Field Visible Card";
    begin
        Initialize();

        Card.OpenEdit();
        Card.ToggleDynamic.SetValue(true);
        Assert.IsTrue(Card.FieldInDynamicGroup.Visible(),
            'a field inside a group whose Visible expression is now true must be visible');
        Card.Close();
    end;

    // Negative: the control's OWN Visible = false must still win even while the enclosing group
    // is visible — group visibility only ADDS a hiding condition, it never overrides a control
    // that hides itself.
    [Test]
    procedure FieldsOwnFalseVisibleWinsEvenInsideAVisibleGroup()
    var
        Card: TestPage "TP Field Visible Card";
    begin
        Initialize();

        Card.OpenEdit();
        Card.ToggleDynamic.SetValue(true);
        Assert.IsTrue(Card.FieldInDynamicGroup.Visible(), 'sanity: the group must actually be visible now');
        Assert.IsFalse(Card.OwnHiddenFieldInVisibleGroup.Visible(),
            'a control''s own Visible = false must still hide it even though the enclosing group is visible');
        Card.Close();
    end;

    // Negative, and the load-bearing case: FieldInNestedGroup sits inside InnerGroup (declares
    // no Visible), which sits inside OuterGroup (Visible = ShowOuter, false by default). Only
    // walking the FULL ancestor chain — not just the immediate parent InnerGroup — reports this
    // field hidden.
    [Test]
    procedure FieldInNestedGroupIsHiddenWhenTheOuterGroupIsHidden()
    var
        Card: TestPage "TP Field Visible Card";
    begin
        Initialize();

        Card.OpenEdit();
        // ShowOuter defaults to false, so OuterGroup starts hidden; InnerGroup itself declares
        // no Visible at all.
        Assert.IsFalse(Card.FieldInNestedGroup.Visible(),
            'a field two groups deep must be hidden when the OUTER group is hidden, even though the immediate parent group declares no Visible of its own');
        Card.Close();
    end;

    // Positive counterpart: once the outer group becomes visible, the nested field follows.
    [Test]
    procedure FieldInNestedGroupIsVisibleWhenTheOuterGroupIsVisible()
    var
        Card: TestPage "TP Field Visible Card";
    begin
        Initialize();

        Card.OpenEdit();
        Card.ToggleOuter.SetValue(true);
        Assert.IsTrue(Card.FieldInNestedGroup.Visible(),
            'a field two groups deep must become visible once the outer group does, even though the immediate parent group declares no Visible of its own');
        Card.Close();
    end;
}
