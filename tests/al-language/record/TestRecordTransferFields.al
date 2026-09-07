// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-transferfields-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Base (60007)

codeunit 60064 "Test Record TransferFields"
{
    Subtype = Test;
    TestPermissions = Disabled;
    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Record_TransferFields_SameTable_CopiesAllFields()
    var
        Src: Record "ALT Universal";
        Dst: Record "ALT Universal";
    begin
        Initialize();
        // Src: Entry No=1, Integer Field=42, Text Field='hello'; Src.Insert()
        Src."Entry No." := 1;
        Src."Integer Field" := 42;
        Src."Text Field" := 'hello';
        Src.Insert();

        // Dst.TransferFields(Src)
        Dst.TransferFields(Src);

        // AreEqual(42, Dst."Integer Field")
        Assert.AreEqual(42, Dst."Integer Field", 'TransferFields must copy Integer Field with value 42');
        // Verify Text Field is also copied (proving the method returns non-default value)
        Assert.AreEqual('hello', Dst."Text Field", 'TransferFields must copy Text Field with value hello');
    end;

    [Test]
    procedure Record_TransferFields_InitPKTrue_CopiesPK()
    var
        Src: Record "ALT Universal";
        Dst: Record "ALT Universal";
    begin
        Initialize();
        // Src: Entry No=1; Dst.TransferFields(Src, true)
        Src."Entry No." := 1;
        Src."Integer Field" := 99;
        Src.Insert();

        Dst.TransferFields(Src, true);

        // AreEqual(1, Dst."Entry No.") — PK must be copied
        Assert.AreEqual(1, Dst."Entry No.", 'TransferFields(InitPK=true) must copy primary key Entry No.=1');
    end;

    [Test]
    procedure Record_TransferFields_InitPKFalse_SkipsPK()
    var
        Src: Record "ALT Universal";
        Dst: Record "ALT Universal";
    begin
        Initialize();
        // Src: Entry No=5; Dst."Entry No.":=0; Dst.TransferFields(Src, false)
        Src."Entry No." := 5;
        Src."Integer Field" := 77;
        Src.Insert();

        Dst."Entry No." := 0;
        Dst.TransferFields(Src, false);

        // AreEqual(0, Dst."Entry No.") — PK was not copied
        Assert.AreEqual(0, Dst."Entry No.", 'TransferFields(InitPK=false) must NOT copy primary key, Entry No. must remain 0');
        // Verify that non-PK fields ARE copied
        Assert.AreEqual(77, Dst."Integer Field", 'TransferFields(InitPK=false) must copy non-PK fields like Integer Field');
    end;

    [Test]
    procedure Record_TransferFields_DifferentTables_CopiesMatchingFieldsByNo()
    var
        Src: Record "ALT Universal";
        Dst: Record "ALT Base";
    begin
        Initialize();
        // ALT Universal field 1 = "Entry No." (Integer)
        // ALT Base field 1 = "Entry No." (Integer)
        // Set Src (ALT Universal) Entry No=7; call Base.TransferFields(Src, true) to include PK
        Src."Entry No." := 7;
        Src."Integer Field" := 123;
        Src.Insert();

        // TransferFields without SkipTypeMismatch will throw because field 2 differs
        // (Boolean Field vs Name field). So use SkipTypeMismatch=true.
        // InitPKFields=true so that field 1 (Entry No.) is also copied.
        Dst.TransferFields(Src, true, true);

        // Verify that field 1 was copied (matching by field number)
        Assert.AreEqual(7, Dst."Entry No.", 'TransferFields across tables must copy field 1 (Entry No.) by field number');
    end;

    [Test]
    procedure Record_TransferFields_SkipTypeMismatchTrue_IgnoresMismatch()
    var
        Src: Record "ALT Universal";
        Dst: Record "ALT Base";
    begin
        Initialize();
        // Use 3-argument overload: TransferFields(Src, true, true)
        // ALT Universal has a field 2 "Boolean Field" (Boolean)
        // ALT Base has field 2 "Name" (Text[50]) — type mismatch
        // With SkipTypeMismatch=true, the mismatch is skipped but matching types ARE copied.
        // InitPKFields=true so that field 1 (Entry No., Integer in both tables) is copied.
        Src."Entry No." := 10;
        Src."Boolean Field" := true;
        Src.Insert();

        // This must not throw even if field types differ
        Dst.TransferFields(Src, true, true);

        // Verify Entry No. was still copied (field 1 matches: both Integer)
        Assert.AreEqual(10, Dst."Entry No.", 'TransferFields with SkipTypeMismatch=true must still copy matching field numbers');
    end;

    [Test]
    procedure Record_TransferFields_SkipTypeMismatchFalse_ThrowsOnMismatch()
    var
        Src: Record "ALT Universal";
        Dst: Record "ALT Base";
    begin
        Initialize();
        // CLAIM: TransferFields(Src, false, false) throws a runtime error when field types differ
        // between source and destination tables.
        // ALT Universal field 2 = "Boolean Field" (Boolean)
        // ALT Base field 2 = "Name" (Text[50]) — type mismatch
        // With SkipTypeMismatch=false, the first field type mismatch causes an error;
        // the copy does NOT partially succeed.
        Src."Entry No." := 15;
        Src."Decimal Field" := 555.50;
        Src.Insert();

        // Must throw because field 2 types differ (Boolean vs Text[50])
        asserterror Dst.TransferFields(Src, false, false);
        Assert.ExpectedError('must have the same type');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
