// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/feature-management
// Scope: in-scope
// Fixtures used: none
//
// Pins the built-in "Feature Key" system table (2000000211): one row per feature the platform
// registers, served by a provider rather than stored as ordinary data. Base Application's
// Feature Management reads this table to choose between a feature's modern and legacy
// implementation, so what it answers is load-bearing for a large amount of Base App behavior.
//
// Deliberately asserts NO specific feature key and NO specific state. The row set is a
// hardcoded platform list that changes between BC versions, and this suite runs on eight of
// them; naming a key would pin one version. What is version-independent is the contract: the
// table answers rows, every row has an id, Get round-trips that id, an unknown id is not
// invented, and the read-only columns are enforced on Modify.
//
// That last test is the one that proves this is the real provider and not an ordinary rowset:
// a plain table would accept the write.

codeunit 60958 "Test Feature Key Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Record_FeatureKey_FindSet_AnswersRows()
    var
        FeatureKey: Record "Feature Key";
    begin
        Assert.IsTrue(FeatureKey.FindSet(), 'Feature Key must answer at least one row.');
        Assert.IsTrue(FeatureKey.Count() > 0, 'Feature Key must report a positive count.');
    end;

    [Test]
    procedure Record_FeatureKey_EveryRowHasAnIdThatGetRoundTrips()
    var
        FeatureKey: Record "Feature Key";
        Fetched: Record "Feature Key";
    begin
        // Rules out a provider answering N blank rows, and proves Get reaches the same rowset
        // FindSet walked rather than building a row of its own.
        Assert.IsTrue(FeatureKey.FindSet(), 'Feature Key must answer at least one row.');
        repeat
            Assert.AreNotEqual('', FeatureKey.ID, 'Every Feature Key row must carry a non-blank ID.');
            Assert.IsTrue(Fetched.Get(FeatureKey.ID), 'Get must find every ID that FindSet returned.');
            Assert.AreEqual(FeatureKey.ID, Fetched.ID, 'Get must return the row whose ID it was given.');
        until FeatureKey.Next() = 0;
    end;

    [Test]
    procedure Record_FeatureKey_GetOnAnUnknownId_ReturnsFalse()
    var
        FeatureKey: Record "Feature Key";
    begin
        // Negative control: a provider answering every Get with a row would pass everything
        // above and fail here.
        Assert.IsFalse(FeatureKey.Get('ThisFeatureDoesNotExist'),
            'Feature Key must not invent a row for an id no feature uses.');
    end;

    [Test]
    procedure Record_FeatureKey_ModifyingAReadOnlyColumn_RaisesNamingTheField()
    var
        FeatureKey: Record "Feature Key";
    begin
        // "Enabled" is the only writable column; every other one is read-only and the platform
        // rejects a change to it BY NAME. This is what distinguishes the real provider from an
        // ordinary table, which would accept the write.
        Assert.IsTrue(FeatureKey.FindSet(), 'Feature Key must answer at least one row.');
        FeatureKey.Description := 'changed by a test';
        asserterror FeatureKey.Modify();
        Assert.IsTrue(
            StrPos(GetLastErrorText(), FeatureKey.FieldCaption(Description)) > 0,
            'Modifying a read-only Feature Key column must raise an error naming that column, got: '
            + GetLastErrorText());
    end;
}
