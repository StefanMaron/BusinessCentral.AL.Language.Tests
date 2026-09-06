// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Trigger Log (60003) — has AutoIncrement=true on Entry No.
// Purpose: Documents non-temp AutoIncrement behavior discovered via CI failures.
//          AutoIncrement assigns Entry No. from a DB sequence; Init() does NOT reset keys.

codeunit 60201 "Test AutoIncrement Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── AutoIncrement assigns Entry No. on Insert ──────────────────────────────────

    [Test]
    procedure AutoIncrement_Insert_AssignsPositiveEntryNo()
    // CLAIM: Insert on a non-temp table with AutoIncrement=true assigns the next sequence
    //        value to Entry No. Setting Entry No.:=0 explicitly requests auto-assignment.
    var
        TL: Record "ALT Trigger Log";
    begin
        Initialize();
        TL."Entry No." := 0;
        TL.Insert();
        Assert.IsTrue(TL."Entry No." > 0, 'AutoIncrement must assign a positive Entry No. after Insert');
    end;

    // ── Init() does NOT clear the auto-assigned primary key ───────────────────────

    [Test]
    procedure AutoIncrement_Init_AfterInsert_PKSurvives()
    // CLAIM: Calling Init() on a record after AutoIncrement Insert does NOT reset Entry No.
    //        BC documentation: "Keys and timestamps are not initialized by Init."
    //        This means the assigned value from Insert persists through Init.
    var
        TL: Record "ALT Trigger Log";
        AssignedNo: Integer;
    begin
        Initialize();
        TL."Entry No." := 0;
        TL.Insert();
        AssignedNo := TL."Entry No.";
        Assert.IsTrue(AssignedNo > 0, 'Entry No. must be auto-assigned after Insert');

        TL.Init();

        Assert.AreEqual(AssignedNo, TL."Entry No.", 'Init() must NOT clear the auto-assigned Entry No. — key survives Init per BC docs');
    end;

    // ── Second Insert without PK reset throws duplicate key ───────────────────────

    [Test]
    procedure AutoIncrement_SecondInsert_WithoutPKReset_ThrowsDuplicateKey()
    // CLAIM: After Insert assigns Entry No. = N, calling Init() then Insert again
    //        WITHOUT setting Entry No.:=0 throws a duplicate key error.
    //        Init() keeps Entry No.=N, so the second Insert tries to insert the same key.
    var
        TL: Record "ALT Trigger Log";
    begin
        Initialize();
        TL."Entry No." := 0;
        TL.Insert();
        Assert.IsTrue(TL."Entry No." > 0, 'First Insert must assign Entry No.');

        TL.Init();
        // Entry No. is still the previously assigned value — NOT reset to 0

        asserterror TL.Insert();
        Assert.AreNotEqual('', GetLastErrorText(), 'Second Insert without Entry No.:=0 must throw duplicate key — key survived Init');
    end;

    // ── Setting Entry No.:=0 before second Insert requests a new sequence value ───

    [Test]
    procedure AutoIncrement_SecondInsert_WithPKReset_AssignsNewValue()
    // CLAIM: Explicitly setting Entry No.:=0 before a second Insert tells the AutoIncrement
    //        sequence to assign a new value. The result is a higher Entry No. than the first.
    var
        TL: Record "ALT Trigger Log";
        First: Integer;
        Second: Integer;
    begin
        Initialize();
        TL."Entry No." := 0;
        TL.Insert();
        First := TL."Entry No.";

        TL.Init();
        TL."Entry No." := 0;  // Explicitly request a new auto-assigned value
        TL.Insert();
        Second := TL."Entry No.";

        Assert.IsTrue(Second > First, 'Second Insert with Entry No.:=0 must receive a new (higher) auto-assigned value');
    end;

    // ── Truncate(true) resets the AutoIncrement counter ──────────────────────────

    [Test]
    procedure AutoIncrement_Truncate_ResetsSequenceToOne()
    // CLAIM: Calling Truncate(true) on a table with AutoIncrement=true deletes all rows
    //        AND resets the DB sequence. The next Insert after Truncate gets Entry No.=1.
    var
        TL: Record "ALT Trigger Log";
    begin
        Initialize();
        // Insert a record so Entry No. advances beyond 1
        TL."Entry No." := 0;
        TL.Insert();

        // Truncate with resetAutoIncrementCounter=true
        TL.Truncate(true);

        // Next Insert must get Entry No. = 1 (sequence reset)
        TL."Entry No." := 0;
        TL.Insert();
        Assert.AreEqual(1, TL."Entry No.", 'After Truncate(true), next AutoIncrement Insert must get Entry No.=1');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
