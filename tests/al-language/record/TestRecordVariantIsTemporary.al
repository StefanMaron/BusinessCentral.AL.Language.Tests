// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-istemporary-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Universal (60000)
// BC versions: 27.0+
//
// CLAIM UNDER TEST: for a typed Record target, IsTemporary follows the VARIABLE's declaration, not
// the source: boxing a record into a Variant and unboxing it keeps the temporary flag the TARGET
// variable was declared with — a temporary-declared target stays temporary, a non-temporary-declared
// target stays persistent, whatever the source was. A RecordRef has no such declaration, so it takes
// the flag from the Variant: GetTable from a Variant that holds a temporary record yields a
// TEMPORARY RecordRef.
//
// Verified on native BC 27.0: GetTable from a Variant that holds a temporary record yields a
// TEMPORARY RecordRef. The non-temp-target arm remains as asserted (a non-temporary-declared
// target stays persistent through the round trip).
//
// Passing the Variant BY VALUE into a procedure adds nothing: the callee's GetTable still yields a
// temporary RecordRef. The contrast is a temporary RECORD passed by value into a non-temporary
// parameter, which is not temporary in the callee because the parameter's declaration wins.

codeunit 60299 "Test RecVariant IsTemporary"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Temp_Via_Variant_To_TempVar_StaysTemporary()
    // CLAIM: temporary source -> Variant -> temporary-declared target is still temporary.
    var
        TempSrc: Record "ALT Universal" temporary;
        TempDst: Record "ALT Universal" temporary;
        V: Variant;
    begin
        Initialize();
        TempSrc."Entry No." := 1;
        TempSrc.Insert();

        V := TempSrc;
        TempDst := V;

        Assert.IsTrue(TempDst.IsTemporary(), 'a temporary-declared target must stay temporary after the Variant round trip');
    end;

    [Test]
    procedure Temp_Via_Variant_To_NonTempVar_IsNotTemporary()
    // CLAIM: temporary source -> Variant -> non-temporary-declared target is NOT temporary.
    var
        TempSrc: Record "ALT Universal" temporary;
        NonTempDst: Record "ALT Universal";
        V: Variant;
    begin
        Initialize();
        TempSrc."Entry No." := 1;
        TempSrc.Insert();

        V := TempSrc;
        NonTempDst := V;

        Assert.IsFalse(NonTempDst.IsTemporary(), 'a non-temporary-declared target must NOT become temporary through a Variant — the declaration wins');
    end;

    [Test]
    procedure Temp_Via_Variant_GetTable_RecordRefIsTemporary()
    // CLAIM: GetTable from a Variant holding a temporary record yields a TEMPORARY RecordRef —
    //        the temporary flag is carried inside the Variant. Verified on native BC 27.0.
    var
        TempSrc: Record "ALT Universal" temporary;
        RecRef: RecordRef;
        V: Variant;
    begin
        Initialize();
        TempSrc."Entry No." := 1;
        TempSrc.Insert();

        V := TempSrc;
        RecRef.GetTable(V);

        Assert.IsTrue(RecRef.IsTemporary(), 'GetTable(Variant) carries the temporary flag — the RecordRef IS temporary');
        RecRef.Close();
    end;

    [Test]
    procedure NonTemp_Via_Variant_To_TempVar_StaysTemporary()
    // CLAIM: a non-temporary source -> Variant -> temporary-declared target is still temporary.
    var
        NonTempSrc: Record "ALT Universal";
        TempDst: Record "ALT Universal" temporary;
        V: Variant;
    begin
        Initialize();
        NonTempSrc."Entry No." := 1;

        V := NonTempSrc;
        TempDst := V;

        Assert.IsTrue(TempDst.IsTemporary(), 'a temporary-declared target must stay temporary even when the source was persistent');
    end;

    [Test]
    procedure Temp_PassedAsVariantByValue_GetTable_IsTemporary()
    // CLAIM: passing the Variant by value into a procedure does NOT strip the temporary flag the
    //        Variant carries — GetTable inside the callee still yields a temporary RecordRef.
    var
        TempSrc: Record "ALT Universal" temporary;
        V: Variant;
    begin
        Initialize();
        TempSrc."Entry No." := 1;
        TempSrc.Insert();
        V := TempSrc;

        Assert.IsTrue(IsTemporaryViaGetTable(V), 'a Variant passed by value keeps the temporary flag — GetTable in the callee yields a temporary RecordRef');
    end;

    [Test]
    procedure Temp_PassedAsRecordByValue_NonTempParam_IsNotTemporary()
    // CLAIM (contrast): a temporary record passed by value into a NON-temporary-declared parameter
    //        is not temporary in the callee — the parameter's declaration wins. This is the
    //        record-level loss the Variant form above is compared against.
    var
        TempSrc: Record "ALT Universal" temporary;
    begin
        Initialize();
        TempSrc."Entry No." := 1;
        TempSrc.Insert();

        Assert.IsFalse(IsTemporaryOfRecordParam(TempSrc), 'a temp record passed by value into a non-temp parameter is not temporary in the callee');
    end;

    local procedure IsTemporaryViaGetTable(V: Variant): Boolean
    var
        RecRef: RecordRef;
        Result: Boolean;
    begin
        RecRef.GetTable(V);
        Result := RecRef.IsTemporary();
        RecRef.Close();
        exit(Result);
    end;

    local procedure IsTemporaryOfRecordParam(Rec: Record "ALT Universal"): Boolean
    begin
        exit(Rec.IsTemporary());
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
