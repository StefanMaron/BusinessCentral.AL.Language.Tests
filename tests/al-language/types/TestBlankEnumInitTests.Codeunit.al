// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/enum/enum-data-type
// Scope: in-scope
// Fixtures used: BEI Blank Logging (60890), BEI Mixed Level (60891), BEI Setup (60892),
//                BEI Mixed (60893), BEI Installer (60894)
//
// Migrated from AL Runner tests/runner-extras/blank-enum-initvalue (BeiTests.Codeunit.al).
// These assert plain AL enum semantics -- a blank-named InitValue member evaluating to
// ordinal 0, a named InitValue on a sparse enum resolving to its true ordinal, and Evaluate
// accepting the blank member while rejecting a non-member -- so a real service tier, not the
// runner, is what should confirm them.

// Issue #1674: enum value named " " with InitValue = " " — before the fix,
// every Insert of such a table threw NavNCLInvalidOptionStringException
// ('" "' is not an option. The existing options are:) from
// NCLMetaField.get_InitValue via MarkAllFieldsAsChanged, killing the bundle
// at the install trigger. These tests only being REACHED already proves the
// install-path Insert (BEI Installer) survived; the assertions then pin the
// concrete evaluated values so a silent default-0 fallback cannot pass the
// named-ordinal check.
codeunit 60895 "BEI Blank Enum Init Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure InstallInsertSucceededAndBlankEnumReadsBackAsOrdinalZero()
    var
        BeiSetup: Record "BEI Setup";
    begin
        // [THEN] The row the install trigger inserted (blank PK, exactly as in
        // the #1674 repro) exists — on main this codeunit never ran at all.
        Assert.IsTrue(BeiSetup.Get(''), 'the install-trigger-inserted row must exist');
        Assert.AreEqual(0, BeiSetup."Logging Type".AsInteger(),
            'InitValue = " " must initialize the enum field to the blank ordinal-0 value');
        Assert.IsTrue(BeiSetup."Logging Type" = BeiSetup."Logging Type"::" ",
            'the field must equal the blank-named enum value');
    end;

    [Test]
    procedure InTestInsertInitializesBlankEnumToOrdinalZero()
    var
        BeiSetup: Record "BEI Setup";
    begin
        // [WHEN] The same Init+Insert path runs inside a test.
        BeiSetup.Init();
        BeiSetup."Primary Key" := 'T1';
        BeiSetup.Insert(false);

        // [THEN] The row round-trips with the blank ordinal-0 value.
        BeiSetup.Get('T1');
        Assert.AreEqual(0, BeiSetup."Logging Type".AsInteger(),
            'inserted row must read back the blank ordinal-0 enum value');
    end;

    [Test]
    procedure NamedInitValueOnSparseEnumEvaluatesToTrueOrdinal()
    var
        BeiMixed: Record "BEI Mixed";
    begin
        // [WHEN] Init applies InitValue to every field.
        BeiMixed.Init();

        // [THEN] Blank InitValue -> 0; NAMED InitValue -> the enum's true sparse
        // ordinal 5 (a silent default-0 fallback fails here); Option-field blank
        // InitValue (the pre-fix healthy path) -> 0.
        Assert.AreEqual(0, BeiMixed."Blank Init".AsInteger(),
            'blank InitValue on a mixed enum must initialize to ordinal 0');
        Assert.AreEqual(5, BeiMixed."Named Init".AsInteger(),
            'InitValue = Verbose must evaluate to the sparse ordinal 5, not a default');
        Assert.AreEqual(0, BeiMixed."Option Blank",
            'blank InitValue on a classic Option field must stay at ordinal 0');

        // [THEN] The values survive Insert + Get.
        BeiMixed."Primary Key" := 'M1';
        BeiMixed.Insert(false);
        BeiMixed.Get('M1');
        Assert.AreEqual(5, BeiMixed."Named Init".AsInteger(),
            'the named-InitValue ordinal must round-trip through Insert');
    end;

    [Test]
    procedure EvaluateMatchesBlankMemberAndRejectsNonMember()
    var
        BeiSetup: Record "BEI Setup";
    begin
        // [THEN] The blank member name matches through the SAME evaluator path
        // (NavOptionEvaluator -> GetIndexFromCaption/GetIndexFromOption) that
        // InitValue uses...
        Evaluate(BeiSetup."Logging Type", ' ');
        Assert.AreEqual(0, BeiSetup."Logging Type".AsInteger(),
            'Evaluate('' '') must resolve to the blank ordinal-0 member');

        // [THEN] ...and a non-member is still rejected loudly, proving the
        // matcher is a real matcher and not an always-succeed default.
        asserterror Evaluate(BeiSetup."Logging Type", 'Bogus');
        Assert.ExpectedError('is not an option');
    end;
}
