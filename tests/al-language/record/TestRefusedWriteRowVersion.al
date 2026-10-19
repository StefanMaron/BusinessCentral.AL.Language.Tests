// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALTFixtureCleanup (60019)
// A write the database refuses must not hand the record a rowversion. SystemRowVersion is the
// AL-visible face of the row's SQL rowversion (the value NavRecord.HasBeenInserted reads), so a
// refused Insert/Modify leaves it at 0 on a record that was never inserted, and leaves the
// stored row's value untouched. The positive arms pin that a successful Insert does hand the
// inserting record its rowversion, without a re-read.

codeunit 60247 "Test Refused Write RowVersion"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        NoRowVersion: BigInteger;

    [Test]
    procedure SuccessfulInsert_GivesInsertingRecordARowVersion()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec.Init();
        Rec."Entry No." := 1;
        Assert.AreEqual(NoRowVersion, Rec.SystemRowVersion, 'an initialised record carries no rowversion');
        Assert.IsTrue(Rec.Insert(), 'Insert of a new key must succeed');
        Assert.AreNotEqual(NoRowVersion, Rec.SystemRowVersion, 'the inserting record must carry the new row''s rowversion');
    end;

    [Test]
    procedure RefusedInsert_LeavesRecordWithoutRowVersion()
    var
        Existing: Record "ALT Universal";
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Existing.Init();
        Existing."Entry No." := 1;
        Existing.Insert();

        Rec.Init();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 7;
        Assert.IsFalse(Rec.Insert(), 'Insert of a duplicate key must be refused');
        Assert.AreEqual(NoRowVersion, Rec.SystemRowVersion, 'a refused Insert must not hand the record a rowversion');
    end;

    [Test]
    procedure RefusedInsert_LeavesStoredRowUntouched()
    var
        Existing: Record "ALT Universal";
        Rec: Record "ALT Universal";
        Stored: Record "ALT Universal";
        Before: BigInteger;
    begin
        Initialize();
        Existing.Init();
        Existing."Entry No." := 1;
        Existing."Integer Field" := 3;
        Existing.Insert();
        Stored.Get(1);
        Before := Stored.SystemRowVersion;
        Assert.AreNotEqual(NoRowVersion, Before, 'the inserted row must carry a rowversion');

        Rec.Init();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 7;
        Assert.IsFalse(Rec.Insert(), 'Insert of a duplicate key must be refused');

        Stored.Get(1);
        Assert.AreEqual(Before, Stored.SystemRowVersion, 'a refused Insert must not change the stored row''s rowversion');
        Assert.AreEqual(3, Stored."Integer Field", 'a refused Insert must not change the stored row');
    end;

    [Test]
    procedure RefusedInsert_ThenInsertOfFreeKey_Succeeds()
    var
        Existing: Record "ALT Universal";
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Existing.Init();
        Existing."Entry No." := 1;
        Existing.Insert();

        Rec.Init();
        Rec."Entry No." := 1;
        Assert.IsFalse(Rec.Insert(), 'Insert of a duplicate key must be refused');
        Rec."Entry No." := 2;
        Assert.IsTrue(Rec.Insert(), 'the same record must insert under a free key');
        Assert.AreNotEqual(NoRowVersion, Rec.SystemRowVersion, 'the second, successful Insert must hand the record a rowversion');
    end;

    [Test]
    procedure RefusedModify_LeavesRecordWithoutRowVersion()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec.Init();
        Rec."Entry No." := 5;
        Assert.IsFalse(Rec.Modify(), 'Modify of a key that does not exist must be refused');
        Assert.AreEqual(NoRowVersion, Rec.SystemRowVersion, 'a refused Modify must not hand the record a rowversion');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        ClearLastError();
    end;
}
