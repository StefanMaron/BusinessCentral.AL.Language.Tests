// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-object
// Scope: in-scope
// Fixtures used: ALT Control Defaults Page (60425), ALT Universal (60000), ALT Status (60009)
//
// Two things the "Page Control Field" (2000000192) virtual table answers that no other
// codeunit pins, and that two plausible provider implementations disagree about.
//
// 1. Enabled, Editable and Visible are three separate TEXT columns, each carrying the
//    declared property expression of the control. A page's metadata omits a property that
//    is at its default, so what the table reports for an UNDECLARED property is supplied by
//    the platform, and there is no reason all three must supply the same thing. Codeunit
//    60921 pins Visible for an undeclared control ('true'); nothing pins Enabled or
//    Editable. These tests state what the platform actually answers for each.
//
//    It does NOT answer alike: Enabled and Visible report 'true', Editable reports 'True'.
//    The casing is not cosmetic — it is two different mechanisms showing through. Enabled
//    and Visible come from the deserializer's own default for the property, and Editable is
//    resolved afterwards, against the bound field, by the platform's property-defaulting
//    pass. Measured on all eight cloud legs of run 34329910568.
//
// 2. OptionString for a control bound to an Enum-typed field. Codeunit 60426 pins it for a
//    control bound to "Option Field", declared `Option` with inline OptionMembers. AL's
//    `Enum "X"` is a different declared type, so whether an Enum-bound control reports the
//    enum's members or an empty string is a separate question, and this is the first test
//    to ask it.
//
// The Enabled/Editable/Visible columns are Text, not Boolean, so the tests compare them as
// text where the point is what the platform SUPPLIES (including whether it supplies
// anything at all), and round-trip through Evaluate() only where the point is the declared
// Boolean value.

codeunit 60424 "Test Page Control Fld Defaults"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Record_PageControlField_UndeclaredVisible_IsTrue()
    var
        PageControlField: Record "Page Control Field";
    begin
        // [GIVEN] "BareControl" declares neither Editable, Enabled nor Visible.
        FindBareControl(PageControlField);

        // [THEN] Visible reports the default 'true'. This repeats codeunit 60921's claim on
        // a different page on purpose: it is the control against which the Enabled and
        // Editable answers below are read, so all three come from one page and one row set.
        Assert.AreEqual('true', PageControlField.Visible, 'Visible for a control declaring no Visible property.');
    end;

    [Test]
    procedure Record_PageControlField_UndeclaredEnabled_IsTrue()
    var
        PageControlField: Record "Page Control Field";
    begin
        // [GIVEN] the same control, declaring no Enabled property.
        FindBareControl(PageControlField);

        // [THEN] Enabled reports the default 'true', like Visible.
        Assert.AreEqual('true', PageControlField.Enabled, 'Enabled for a control declaring no Enabled property.');
    end;

    [Test]
    procedure Record_PageControlField_UndeclaredEditable_IsTrueCapitalized()
    var
        PageControlField: Record "Page Control Field";
    begin
        // [GIVEN] the same control, declaring no Editable property. It is bound to
        // "Entry No.", which declares no Editable either.

        FindBareControl(PageControlField);

        // [THEN] Editable reports 'True' — CAPITALIZED, unlike the 'true' that Enabled and
        // Visible report above. That difference in spelling is the finding, and it is why
        // this test asserts a literal rather than round-tripping through Evaluate(): the
        // three columns are filled by two different mechanisms, and only the casing shows it.
        //
        // Measured on a real service tier, not reasoned about. This test was first written
        // asserting '' — the reading of the platform assemblies described in the PR that
        // introduced it — and every one of the eight cloud legs answered 'True' instead
        // (run 34329910568: Expected:<> Actual:<True>, identically on 27.0, 27.3, 27.5,
        // 28.0, 28.1, 28.2, 28.3 and 28.4). The assertion below is the tier's answer.
        Assert.AreEqual('True', PageControlField.Editable, 'Editable for a control declaring no Editable property. Enabled and Visible report a lower-case ''true'' for the undeclared case; Editable reports a capitalized ''True'', so the three columns must not be filled from one shared default.');
    end;

    [Test]
    procedure Record_PageControlField_DeclaredEditableFalse_RoundTripsAsFalse()
    var
        PageControlField: Record "Page Control Field";
        IsEditable: Boolean;
    begin
        // Negative direction for the test above: an Editable that IS declared must be
        // reported, so an empty answer there cannot be dismissed as the column never
        // carrying anything.
        PageControlField.SetRange(PageNo, Page::"ALT Control Defaults Page");
        PageControlField.SetRange(ControlName, 'DeclaredEditableFalse');
        Assert.IsTrue(PageControlField.FindFirst(), 'Page Control Field has no row for control "DeclaredEditableFalse".');

        Assert.IsTrue(Evaluate(IsEditable, PageControlField.Editable), 'Editable column is not an evaluable Boolean expression for a control that declares Editable = false.');
        Assert.IsFalse(IsEditable, 'Control "DeclaredEditableFalse" declares Editable = false; the table must report that.');
    end;

    [Test]
    procedure Record_PageControlField_DeclaredEnabledFalse_RoundTripsAsFalse()
    var
        PageControlField: Record "Page Control Field";
        IsEnabled: Boolean;
    begin
        // Same negative direction for Enabled.
        PageControlField.SetRange(PageNo, Page::"ALT Control Defaults Page");
        PageControlField.SetRange(ControlName, 'DeclaredEnabledFalse');
        Assert.IsTrue(PageControlField.FindFirst(), 'Page Control Field has no row for control "DeclaredEnabledFalse".');

        Assert.IsTrue(Evaluate(IsEnabled, PageControlField.Enabled), 'Enabled column is not an evaluable Boolean expression for a control that declares Enabled = false.');
        Assert.IsFalse(IsEnabled, 'Control "DeclaredEnabledFalse" declares Enabled = false; the table must report that.');
    end;

    [Test]
    procedure Record_PageControlField_EnumBoundControl_OptionStringIsTheEnumsMembers()
    var
        PageControlField: Record "Page Control Field";
        Members: List of [Text];
    begin
        // [GIVEN] "EnumBoundControl" is bound to "Status Field", declared
        // `Enum "ALT Status"` — an Enum-typed field, not an Option-typed one. "ALT Status"
        // declares five values: " ", Draft, Active, Closed, Archived.
        PageControlField.SetRange(PageNo, Page::"ALT Control Defaults Page");
        PageControlField.SetRange(ControlName, 'EnumBoundControl');
        Assert.IsTrue(PageControlField.FindFirst(), 'Page Control Field has no row for control "EnumBoundControl".');

        Assert.AreEqual(15, PageControlField.FieldNo, 'Unexpected FieldNo for "EnumBoundControl" (expected "Status Field", id 15).');

        // [THEN] OptionString carries the ENUM''s members. Asserted per member rather than
        // as one literal so the test does not pin how the blank first value is spelled, and
        // the member COUNT is what separates this from "Option Field"''s four members —
        // an implementation that answered the wrong field''s members would pass a
        // non-emptiness check.
        Assert.AreNotEqual('', PageControlField.OptionString, 'OptionString for a control bound to an Enum-typed field. An Enum field is declared with a different AL type than an Option field, so this is the column that says whether the table treats the two alike.');
        Members := PageControlField.OptionString.Split(',');
        Assert.AreEqual(5, Members.Count(), 'OptionString must state the five values of enum "ALT Status" for the Enum-bound control.');
        Assert.AreEqual('Draft', Members.Get(2), 'Unexpected second member of enum "ALT Status" in OptionString.');
        Assert.AreEqual('Active', Members.Get(3), 'Unexpected third member of enum "ALT Status" in OptionString.');
        Assert.AreEqual('Closed', Members.Get(4), 'Unexpected fourth member of enum "ALT Status" in OptionString.');
        Assert.AreEqual('Archived', Members.Get(5), 'Unexpected fifth member of enum "ALT Status" in OptionString.');
    end;

    [Test]
    procedure Record_PageControlField_IntegerBoundControl_OptionStringIsEmpty()
    var
        PageControlField: Record "Page Control Field";
    begin
        // Negative direction for the test above: OptionString is not filled for every
        // control, so a non-empty answer there means something.
        FindBareControl(PageControlField);
        Assert.AreEqual(1, PageControlField.FieldNo, 'Unexpected FieldNo for "BareControl" (expected "Entry No.", id 1).');
        Assert.AreEqual('', PageControlField.OptionString, 'OptionString must be empty for a control bound to an Integer field.');
    end;

    local procedure FindBareControl(var PageControlField: Record "Page Control Field")
    begin
        PageControlField.Reset();
        PageControlField.SetRange(PageNo, Page::"ALT Control Defaults Page");
        PageControlField.SetRange(ControlName, 'BareControl');
        Assert.IsTrue(PageControlField.FindFirst(), 'Page Control Field has no row for control "BareControl".');
    end;
}
