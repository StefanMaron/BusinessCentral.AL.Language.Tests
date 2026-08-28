// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/numbersequence/numbersequence-data-type
// Scope: in-scope (Cloud-compatible)
// Fixtures used: Assert (60021), ALTFixtureCleanup (60019)
// BC versions: 27.5+

codeunit 60996 "Test Number Sequence"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        SequenceNameLbl: Label 'ALT-NumberSequence-60996', Locked = true;

    [Test]
    procedure NumberSequence_Next_DefaultScopeHonorsSeedAndIncrement()
    // CLAIM: the default company-specific sequence starts at its seed and advances by its increment.
    begin
        Initialize();

        NumberSequence.Insert(SequenceNameLbl, 5, 2);

        Assert.AreEqual(5, NumberSequence.Next(SequenceNameLbl),
            'The first value from a default-scope sequence must equal its seed.');
        Assert.AreEqual(7, NumberSequence.Next(SequenceNameLbl),
            'The second value from a default-scope sequence must apply its increment.');

        CleanupSequences();
    end;

    [Test]
    procedure NumberSequence_Next_GlobalScopeHonorsSeedAndIncrement()
    // CLAIM: a non-company-specific sequence starts at its seed and advances by its increment.
    begin
        Initialize();

        NumberSequence.Insert(SequenceNameLbl, 10, 3, false);

        Assert.AreEqual(10, NumberSequence.Next(SequenceNameLbl, false),
            'The first value from a global sequence must equal its seed.');
        Assert.AreEqual(13, NumberSequence.Next(SequenceNameLbl, false),
            'The second value from a global sequence must apply its increment.');

        CleanupSequences();
    end;

    [Test]
    procedure NumberSequence_Exists_CompanyScopesAreIndependent()
    // CLAIM: company-specific and global sequences with the same name keep independent state.
    begin
        Initialize();

        NumberSequence.Insert(SequenceNameLbl, 1, 1, true);
        NumberSequence.Insert(SequenceNameLbl, 100, 10, false);

        Assert.IsTrue(NumberSequence.Exists(SequenceNameLbl, true),
            'Exists must find the company-specific sequence.');
        Assert.IsTrue(NumberSequence.Exists(SequenceNameLbl, false),
            'Exists must find the global sequence.');
        Assert.AreEqual(1, NumberSequence.Next(SequenceNameLbl, true),
            'The company-specific sequence must retain its own seed.');
        Assert.AreEqual(100, NumberSequence.Next(SequenceNameLbl, false),
            'The global sequence must retain its own seed.');

        CleanupSequences();
    end;

    [Test]
    procedure NumberSequence_Current_AfterInsertReturnsSeed()
    // CLAIM: Current returns the configured seed before the first allocation.
    begin
        Initialize();

        NumberSequence.Insert(SequenceNameLbl, 10, 3, false);

        Assert.AreEqual(10, NumberSequence.Current(SequenceNameLbl, false),
            'Current must expose the configured seed before the first allocation.');

        CleanupSequences();
    end;

    [Test]
    procedure NumberSequence_Restart_SetsNextValueAndPreservesIncrement()
    // CLAIM: Restart replaces the next value without changing the sequence increment.
    begin
        Initialize();
        NumberSequence.Insert(SequenceNameLbl, 10, 3, false);
        Assert.AreEqual(10, NumberSequence.Next(SequenceNameLbl, false),
            'The sequence must allocate its original seed before Restart.');

        NumberSequence.Restart(SequenceNameLbl, 50, false);

        Assert.AreEqual(50, NumberSequence.Next(SequenceNameLbl, false),
            'The first value after Restart must equal the new seed.');
        Assert.AreEqual(53, NumberSequence.Next(SequenceNameLbl, false),
            'Restart must preserve the configured increment.');

        CleanupSequences();
    end;

    [Test]
    procedure NumberSequence_Delete_RemovesSequence()
    // CLAIM: Delete removes the selected sequence.
    begin
        Initialize();
        NumberSequence.Insert(SequenceNameLbl, 1, 1, false);
        Assert.IsTrue(NumberSequence.Exists(SequenceNameLbl, false),
            'The sequence must exist before Delete.');

        NumberSequence.Delete(SequenceNameLbl, false);

        Assert.IsFalse(NumberSequence.Exists(SequenceNameLbl, false),
            'Exists must return false after Delete.');
    end;

    [Test]
    procedure NumberSequence_Range_ReservesRequestedValues()
    // CLAIM: Range returns the first reserved value and advances by count times the increment.
    var
        RangeStart: BigInteger;
    begin
        Initialize();
        NumberSequence.Insert(SequenceNameLbl, 10, 3, false);

        RangeStart := NumberSequence.Range(SequenceNameLbl, 4, false);

        Assert.AreEqual(10, RangeStart,
            'Range must return the first reserved value.');
        Assert.AreEqual(19, NumberSequence.Current(SequenceNameLbl, false),
            'Range must reserve exactly four values using the configured increment.');
        Assert.AreEqual(22, NumberSequence.Next(SequenceNameLbl, false),
            'The next allocation must follow the reserved range.');

        CleanupSequences();
    end;

    [Test]
    procedure NumberSequence_Range_ByRefReportsIncrement()
    // CLAIM: the ByRef Range overload returns the sequence increment with the reserved range.
    var
        Increment: BigInteger;
        RangeStart: BigInteger;
    begin
        Initialize();
        NumberSequence.Insert(SequenceNameLbl, 10, 3, false);

        RangeStart := NumberSequence.Range(SequenceNameLbl, 4, Increment, false);

        Assert.AreEqual(10, RangeStart,
            'The ByRef Range overload must return the first reserved value.');
        Assert.AreEqual(3, Increment,
            'The ByRef Range overload must report the configured increment.');
        Assert.AreEqual(19, NumberSequence.Current(SequenceNameLbl, false),
            'The ByRef Range overload must reserve the requested values.');

        CleanupSequences();
    end;

    [Test]
    procedure NumberSequence_Insert_DuplicateNameThrowsAndKeepsOriginal()
    // CLAIM: inserting an existing sequence throws and does not replace its configuration.
    begin
        Initialize();
        NumberSequence.Insert(SequenceNameLbl, 1, 1, false);

        asserterror NumberSequence.Insert(SequenceNameLbl, 100, 10, false);

        Assert.AreNotEqual('', GetLastErrorText(),
            'Inserting a duplicate sequence must raise an error.');
        Assert.AreEqual(1, NumberSequence.Next(SequenceNameLbl, false),
            'A failed duplicate Insert must leave the original sequence unchanged.');

        CleanupSequences();
    end;

    [Test]
    procedure NumberSequence_Next_MissingSequenceThrowsWithoutCreatingIt()
    // CLAIM: requesting the next value of a missing sequence throws and does not create it.
    var
        Value: BigInteger;
    begin
        Initialize();

        asserterror Value := NumberSequence.Next(SequenceNameLbl, false);

        Assert.AreNotEqual('', GetLastErrorText(),
            'Next on a missing sequence must raise an error.');
        Assert.IsFalse(NumberSequence.Exists(SequenceNameLbl, false),
            'A failed Next call must not create the missing sequence.');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        CleanupSequences();
        ClearLastError();
    end;

    local procedure CleanupSequences()
    begin
        DeleteIfExists(true);
        DeleteIfExists(false);
    end;

    local procedure DeleteIfExists(CompanySpecific: Boolean)
    begin
        if NumberSequence.Exists(SequenceNameLbl, CompanySpecific) then
            NumberSequence.Delete(SequenceNameLbl, CompanySpecific);
    end;
}
