// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Trigger Log (60003)
// Runtime: 16.1, Target: Cloud
// Focus: BC-specific system field and table management contracts

codeunit 60172 "Test BC System Field Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── BC System Audit Fields ───────────────────────────────────────────────

    [Test]
    procedure SystemCreatedBy_AfterInsert_IsNonNullGuid()
    var
        Rec: Record "ALT Universal";
        NullGuid: Guid;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec.Get(1);
        Assert.IsFalse(IsNullGuid(Rec.SystemCreatedBy), 'SystemCreatedBy must be set to a non-null user GUID on insert');
    end;

    [Test]
    procedure SystemModifiedBy_AfterInsert_IsNonNullGuid()
    var
        Rec: Record "ALT Universal";
        NullGuid: Guid;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec.Get(1);
        Assert.IsFalse(IsNullGuid(Rec.SystemModifiedBy), 'SystemModifiedBy must be set to a non-null user GUID on insert');
    end;

    [Test]
    procedure SystemCreatedBy_AfterModify_SameAsInsert()
    var
        Rec: Record "ALT Universal";
        CreatedBy: Guid;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec.Get(1);
        CreatedBy := Rec.SystemCreatedBy;
        Rec."Integer Field" := 99;
        Rec.Modify();
        Rec.Get(1);
        Assert.AreEqual(Format(CreatedBy), Format(Rec.SystemCreatedBy), 'SystemCreatedBy must NOT change on Modify — it records the creator');
    end;

    [Test]
    procedure SystemModifiedBy_AfterModify_StillNonNull()
    var
        Rec: Record "ALT Universal";
        NullGuid: Guid;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec.Get(1);
        Rec."Integer Field" := 42;
        Rec.Modify();
        Rec.Get(1);
        Assert.IsFalse(IsNullGuid(Rec.SystemModifiedBy), 'SystemModifiedBy must remain non-null after Modify');
    end;

    [Test]
    procedure SystemCreatedAt_IsLessOrEqualToModifiedAt()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec.Get(1);
        Rec."Integer Field" := 1;
        Rec.Modify();
        Rec.Get(1);
        Assert.IsTrue(Rec.SystemCreatedAt <= Rec.SystemModifiedAt, 'SystemCreatedAt must be <= SystemModifiedAt after modification');
    end;

    [Test]
    procedure SystemModifiedAt_Updates_OnEachModify()
    var
        Rec: Record "ALT Universal";
        FirstModified: DateTime;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec.Get(1);
        FirstModified := Rec.SystemModifiedAt;
        Rec."Integer Field" := 50;
        Rec.Modify();
        Rec.Get(1);
        Assert.IsTrue(Rec.SystemModifiedAt >= FirstModified, 'SystemModifiedAt after Modify must be >= previous value');
    end;

    // ── Truncate() vs DeleteAll() AutoIncrement Behavior ──────────────────────

    [Test]
    procedure DeleteAll_AutoIncrement_ContinuesFromPrevMax()
    var
        TL: Record "ALT Trigger Log";
        FirstId: Integer;
        SecondId: Integer;
    begin
        Initialize();
        TL.Init();
        TL.TriggerName := 'T1';
        TL.Insert();
        Commit();
        TL.FindFirst();
        FirstId := TL."Entry No.";
        TL.DeleteAll(false);
        Commit();
        TL."Entry No." := 0;
        TL.TriggerName := 'T2';
        TL.Insert();
        Commit();
        TL.FindFirst();
        SecondId := TL."Entry No.";
        Assert.IsTrue(SecondId > FirstId, 'After DeleteAll, AutoIncrement must continue from previous max, NOT reset to 1');
    end;

    [Test]
    procedure Truncate_AllRecords_Deleted()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec.Insert();
        Rec.Truncate();
        Assert.AreEqual(0, Rec.Count(), 'After Truncate(), all records must be deleted');
    end;

    [Test]
    procedure Truncate_ReturnsTrue_OnSuccess()
    var
        Rec: Record "ALT Universal";
        Result: Boolean;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Result := Rec.Truncate(false);
        Assert.IsTrue(Result, 'Truncate() must return true on successful execution');
    end;

    [Test]
    procedure Truncate_EmptyTable_DoesNotThrow()
    var
        Rec: Record "ALT Universal";
        Result: Boolean;
    begin
        Initialize();
        Result := Rec.Truncate(false);
        Assert.IsTrue(true, 'Truncate() on empty table must not throw');
    end;

    // ── Temporary Table Isolation Contracts ───────────────────────────────────

    [Test]
    procedure TempTable_TwoVariables_IsolatedData()
    var
        Temp1: Record "ALT Universal" temporary;
        Temp2: Record "ALT Universal" temporary;
    begin
        Initialize();
        Temp1."Entry No." := 1;
        Temp1.Insert();
        Assert.AreEqual(1, Temp1.Count(), 'Temp1 must have 1 record');
        Assert.AreEqual(0, Temp2.Count(), 'Temp2 must have 0 records — isolated from Temp1');
    end;

    [Test]
    procedure TempTable_SharedViaAssignment_SameData()
    var
        Temp1: Record "ALT Universal" temporary;
        Temp2: Record "ALT Universal" temporary;
    begin
        Initialize();
        Temp1."Entry No." := 1;
        Temp1.Insert();
        Temp2.Copy(Temp1, true);
        Assert.AreEqual(Temp1.Count(), Temp2.Count(), 'After Copy(ShareTable=true) on temp records, both must see same count');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
