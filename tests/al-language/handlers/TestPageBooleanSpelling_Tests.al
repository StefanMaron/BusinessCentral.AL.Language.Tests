// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefield-value-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefield-assertequals-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefield-setvalue-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefield-asboolean-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: TPB Bool Row (60664), TPB Bool Card (60665), Assert (60021)
// BC versions: 27.5+
//
// How a Boolean travels through a TestPage control, in every direction AL can drive it.
//
// TestPageSubpagePartNewRecordInit.BooleanFieldControl_ReadsAsYesOrNo already pins the READ
// spelling for a Rec-bound control in a subpage part ('Yes' / 'No', measured on all eight BC
// legs). This suite covers what that one does not, and each piece is a separate round trip
// through BC rather than a restatement of the same one:
//
//   * the same read on a control bound to a page GLOBAL, which resolves through different
//     plumbing than a Rec-bound one;
//   * AssertEquals(<Boolean>), which does NOT compare against the control's text directly --
//     NavTestField.ALAssertEquals converts the expected Boolean through the field's own
//     ValueToString and then compares ORDINALLY against the control's value, so this pins that
//     the two agree. A reader would otherwise have to derive it;
//   * AsBoolean(), which reads the field's ObjectValue rather than its text, so it is a third
//     independent path;
//   * the WRITE direction -- SetValue(<Boolean>) and the two text spellings -- which nothing
//     upstream pins at all.
//
// Every claim is asserted for true AND false where the direction allows it, so a rule that
// happens to be right for one word cannot pass.

codeunit 60666 "TPB Bool Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        PKTok: Label 'ROW1', Locked = true;

    local procedure Initialize()
    var
        Row: Record "TPB Bool Row";
    begin
        Row.DeleteAll();
    end;

    local procedure Seed()
    var
        Row: Record "TPB Bool Row";
    begin
        Row.Init();
        Row.PK := PKTok;
        Row.Marker := 'SEEDED';
        Row.TrueFlag := true;
        Row.FalseFlag := false;
        Row.Insert();
    end;

    local procedure OpenSeeded(var Card: TestPage "TPB Bool Card")
    begin
        Card.OpenEdit();
        Card.GoToKey(PKTok);
        // Sanity: a Boolean control's two spellings are both short words, so "the page is on no
        // row" and "the control reads the other value" are easy to confuse without this.
        Assert.AreEqual('SEEDED', Card.RecMarker.Value(),
            'sanity: the page must be positioned on the seeded row before any Boolean read');
    end;

    // ── read ─────────────────────────────────────────────────────────────────

    [Test]
    procedure TestPageField_Value_RecBoundBoolean_ReadsYesOrNo()
    // CLAIM: a Rec-bound Boolean control reads 'Yes' when true and 'No' when false. Restated
    // here on a plain card page because the upstream pin for it lives on a subpage part, and a
    // part is not evidence about a host control.
    var
        Card: TestPage "TPB Bool Card";
    begin
        Initialize();
        Seed();

        OpenSeeded(Card);
        Assert.AreEqual('Yes', Card.RecTrue.Value(), 'a Rec-bound Boolean holding true must read as ''Yes''');
        Assert.AreEqual('No', Card.RecFalse.Value(), 'a Rec-bound Boolean holding false must read as ''No''');
        Card.Close();
    end;

    [Test]
    procedure TestPageField_Value_PageVariableBoundBoolean_ReadsYesOrNo()
    // CLAIM: the same spelling holds for a control bound to a page global, which the page seeds
    // in OnOpenPage. Different plumbing from the Rec-bound case, so not implied by it.
    var
        Card: TestPage "TPB Bool Card";
    begin
        Initialize();
        Seed();

        OpenSeeded(Card);
        Assert.AreEqual('Yes', Card.GlobalTrue.Value(), 'a page-variable Boolean holding true must read as ''Yes''');
        Assert.AreEqual('No', Card.GlobalFalse.Value(), 'a page-variable Boolean holding false must read as ''No''');
        Card.Close();
    end;

    [Test]
    procedure TestPageField_AsBoolean_ReadsTheStoredBoolean_NotItsSpelling()
    // CLAIM: AsBoolean() answers the Boolean itself. It reads the field's ObjectValue rather
    // than its text, so it must be unaffected by whatever the text spelling is.
    var
        Card: TestPage "TPB Bool Card";
    begin
        Initialize();
        Seed();

        OpenSeeded(Card);
        Assert.IsTrue(Card.RecTrue.AsBoolean(), 'AsBoolean() must answer true for a Boolean field holding true');
        Assert.IsFalse(Card.RecFalse.AsBoolean(), 'AsBoolean() must answer false for a Boolean field holding false');
        Card.Close();
    end;

    // ── AssertEquals ─────────────────────────────────────────────────────────

    [Test]
    procedure TestPageField_AssertEquals_Boolean_AgreesWithTheControlsOwnSpelling()
    // CLAIM: AssertEquals(<Boolean>) succeeds against a control holding that Boolean. Worth
    // pinning separately from the read: it converts the expected Boolean through the field's own
    // ValueToString and compares ordinally, so it passes only if that conversion agrees with the
    // spelling Value answers with. Asserting the read alone would leave that agreement implied.
    var
        Card: TestPage "TPB Bool Card";
    begin
        Initialize();
        Seed();

        OpenSeeded(Card);
        Card.RecTrue.AssertEquals(true);
        Card.RecFalse.AssertEquals(false);
        Card.Close();
    end;

    [Test]
    procedure TestPageField_AssertEquals_TheWordItReadsAs_Succeeds()
    // CLAIM, from the other side: AssertEquals also accepts the literal text the control reads
    // as. Together with the test above this pins that both overloads land on one spelling.
    var
        Card: TestPage "TPB Bool Card";
    begin
        Initialize();
        Seed();

        OpenSeeded(Card);
        Card.RecTrue.AssertEquals('Yes');
        Card.RecFalse.AssertEquals('No');
        Card.Close();
    end;

    // ── write ────────────────────────────────────────────────────────────────

    [Test]
    procedure TestPageField_SetValue_Boolean_RoundTripsThroughTheControlAndTheRow()
    // CLAIM: SetValue(<Boolean>) writes the Boolean, the control reads back the matching word,
    // and the value reaches the underlying row. Both directions, so "true always works" cannot
    // pass on its own.
    var
        Row: Record "TPB Bool Row";
        Card: TestPage "TPB Bool Card";
    begin
        Initialize();
        Seed();

        OpenSeeded(Card);
        Card.RecTrue.SetValue(false);
        Assert.AreEqual('No', Card.RecTrue.Value(), 'SetValue(false) must leave the control reading ''No''');
        Card.RecFalse.SetValue(true);
        Assert.AreEqual('Yes', Card.RecFalse.Value(), 'SetValue(true) must leave the control reading ''Yes''');
        Card.Close();

        Row.Get(PKTok);
        Assert.IsFalse(Row.TrueFlag, 'SetValue(false) must persist false to the row');
        Assert.IsTrue(Row.FalseFlag, 'SetValue(true) must persist true to the row');
    end;

    [Test]
    procedure TestPageField_SetValue_TheWordItReadsAs_IsAccepted()
    // CLAIM: the text spelling the control reads as is also accepted as a write.
    var
        Row: Record "TPB Bool Row";
        Card: TestPage "TPB Bool Card";
    begin
        Initialize();
        Seed();

        OpenSeeded(Card);
        Card.RecTrue.SetValue('No');
        Assert.AreEqual('No', Card.RecTrue.Value(), 'SetValue(''No'') must leave the control reading ''No''');
        Card.RecFalse.SetValue('Yes');
        Assert.AreEqual('Yes', Card.RecFalse.Value(), 'SetValue(''Yes'') must leave the control reading ''Yes''');
        Card.Close();

        Row.Get(PKTok);
        Assert.IsFalse(Row.TrueFlag, 'SetValue(''No'') must persist false to the row');
        Assert.IsTrue(Row.FalseFlag, 'SetValue(''Yes'') must persist true to the row');
    end;

    [Test]
    procedure TestPageField_SetValue_TrueFalseSpelling_IsAlsoAccepted()
    // CLAIM: 'True' / 'False' is accepted as a write too, even though the control never reads
    // back in that spelling.
    //
    // This is the one assertion in the suite I could not settle by reading BC — it is here to be
    // ANSWERED by a service tier rather than predicted. If it comes back red, the correct
    // outcome is to invert it to an asserterror pinning the refusal, not to drop it: either way
    // the corpus then states what BC does with the spelling AL's own Evaluate accepts.
    var
        Row: Record "TPB Bool Row";
        Card: TestPage "TPB Bool Card";
    begin
        Initialize();
        Seed();

        OpenSeeded(Card);
        Card.RecTrue.SetValue('False');
        Assert.AreEqual('No', Card.RecTrue.Value(), 'SetValue(''False'') must leave the control reading ''No''');
        Card.RecFalse.SetValue('True');
        Assert.AreEqual('Yes', Card.RecFalse.Value(), 'SetValue(''True'') must leave the control reading ''Yes''');
        Card.Close();

        Row.Get(PKTok);
        Assert.IsFalse(Row.TrueFlag, 'SetValue(''False'') must persist false to the row');
        Assert.IsTrue(Row.FalseFlag, 'SetValue(''True'') must persist true to the row');
    end;
}
