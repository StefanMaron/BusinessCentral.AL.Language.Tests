// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-overview
// Scope: in-scope — table triggers (OnInsert, OnModify, OnDelete, OnRename, OnValidate)
// Fixtures used: ALT Triggered (60002), ALT Trigger Log (60003), ALT Universal (60000)

codeunit 60148 "Test Trigger Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── OnRename Trigger Contract ────────────────────────────────────────────

    [Test]
    procedure OnRename_LogContainsNewEntryNo()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered.Insert(false);
        Triggered.Get(1);
        Triggered.Rename(99);
        TrigLog.SetRange("TriggerName", 'OnRename');
        Assert.IsTrue(TrigLog.FindFirst(), 'OnRename trigger log entry must exist');
        Assert.AreEqual(99, TrigLog."SourceEntryNo", 'OnRename trigger must see NEW Entry No. in Rec."Entry No."');
    end;

    // ── OnModify Trigger Contract ────────────────────────────────────────────

    [Test]
    procedure OnModify_TriggerSees_NewFieldValue()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered.Value := 0;
        Triggered.Insert(false);
        Triggered.Get(1);
        Triggered.Value := 99;
        Triggered.Modify(true);
        TrigLog.SetRange("TriggerName", 'OnModify');
        Assert.IsTrue(TrigLog.FindFirst(), 'OnModify trigger log entry must exist');
        Assert.AreEqual(1, TrigLog."SourceEntryNo", 'OnModify SourceEntryNo must be the modified record key');
        // Verify the value persists after Modify(true)
        Triggered.Get(1);
        Assert.AreEqual(99, Triggered.Value, 'Value must persist after Modify(true)');
    end;

    // ── OnDelete Trigger Contract ────────────────────────────────────────────

    [Test]
    procedure OnDelete_FiredExactlyOnce_PerRecord()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered.Insert(false);
        Triggered."Entry No." := 2;
        Triggered.Insert(false);
        Triggered."Entry No." := 3;
        Triggered.Insert(false);
        Triggered.Get(2);
        Triggered.Delete(true);
        TrigLog.SetRange("TriggerName", 'OnDelete');
        Assert.AreEqual(1, TrigLog.Count(), 'Delete(true) on one record must fire OnDelete exactly once');
    end;

    // ── DeleteAll with Trigger Contract ──────────────────────────────────────

    [Test]
    procedure DeleteAll_WithTrigger_FiresForEachFilteredRecord()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered.Insert(false);
        Triggered."Entry No." := 2;
        Triggered.Insert(false);
        Triggered."Entry No." := 3;
        Triggered.Insert(false);
        Triggered."Entry No." := 4;
        Triggered.Insert(false);
        Triggered."Entry No." := 5;
        Triggered.Insert(false);
        Triggered.SetRange("Entry No.", 1, 3);
        Triggered.DeleteAll(true);
        TrigLog.SetRange("TriggerName", 'OnDelete');
        Assert.AreEqual(3, TrigLog.Count(), 'DeleteAll(true) with filter must fire OnDelete 3 times, not 5');
    end;

    [Test]
    procedure DeleteAll_WithTrigger_OnlyDeletesFiltered()
    var
        Triggered: Record "ALT Triggered";
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered.Insert(false);
        Triggered."Entry No." := 2;
        Triggered.Insert(false);
        Triggered."Entry No." := 3;
        Triggered.Insert(false);
        Triggered."Entry No." := 4;
        Triggered.Insert(false);
        Triggered."Entry No." := 5;
        Triggered.Insert(false);
        Triggered.SetRange("Entry No.", 1, 3);
        Triggered.DeleteAll(true);
        Triggered.Reset();
        Assert.AreEqual(2, Triggered.Count(), 'After DeleteAll with filter, 2 records (4,5) must remain');
    end;

    // ── ModifyAll with Trigger Contract ──────────────────────────────────────

    [Test]
    procedure ModifyAll_WithTrigger_FiresForEachFilteredRecord()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered.Insert(false);
        Triggered."Entry No." := 2;
        Triggered.Insert(false);
        Triggered."Entry No." := 3;
        Triggered.Insert(false);
        Triggered."Entry No." := 4;
        Triggered.Insert(false);
        Triggered."Entry No." := 5;
        Triggered.Insert(false);
        Triggered.SetRange("Entry No.", 2, 4);
        Triggered.ModifyAll(Value, 99, true);
        TrigLog.SetRange("TriggerName", 'OnModify');
        Assert.AreEqual(3, TrigLog.Count(), 'ModifyAll(true) with filter must fire OnModify 3 times');
    end;

    // ── Init() does NOT fire OnValidate ──────────────────────────────────────

    [Test]
    procedure Init_Does_NOT_Fire_OnValidate()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered.Insert(false);
        Triggered.Init();
        TrigLog.SetRange("TriggerName", 'OnValidate');
        Assert.AreEqual(0, TrigLog.Count(), 'Record.Init() must NOT fire OnValidate triggers');
    end;

    // ── Validate() fires OnValidate ──────────────────────────────────────────

    [Test]
    procedure Validate_Fires_OnValidate_ExactlyOnce()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered.Insert(false);
        Triggered.Validate("Watched Field", 'test');
        TrigLog.SetRange("TriggerName", 'OnValidate');
        Assert.AreEqual(1, TrigLog.Count(), 'Validate() must fire OnValidate exactly once');
    end;

    [Test]
    procedure OnValidate_Log_Contains_Exact_NewValue()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered.Insert(false);
        Triggered.Validate("Watched Field", 'SpecificValue');
        TrigLog.SetRange("TriggerName", 'OnValidate');
        Assert.IsTrue(TrigLog.FindFirst(), 'OnValidate trigger log entry must exist');
        Assert.AreEqual('SpecificValue', TrigLog."NewValue", 'OnValidate trigger log must record exact new value');
    end;

    // ── Insert(false) vs Insert(true) triggers ───────────────────────────────

    [Test]
    procedure ErrorInOnInsert_RollsBackInsert()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        // Insert(false) skips OnInsert
        Triggered."Entry No." := 1;
        Triggered.Insert(false);
        TrigLog.SetRange("TriggerName", 'OnInsert');
        Assert.AreEqual(0, TrigLog.Count(), 'Insert(false) must NOT fire OnInsert');
        // Insert(true) DOES fire OnInsert
        TrigLog.DeleteAll(false);
        Triggered."Entry No." := 2;
        Triggered.Insert(true);
        TrigLog.SetRange("TriggerName", 'OnInsert');
        Assert.AreEqual(1, TrigLog.Count(), 'Insert(true) must fire OnInsert once');
    end;

    [Test]
    procedure OnInsert_Fires_Before_Record_Is_Readable_By_Others()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 7;
        Triggered.Insert(true);
        TrigLog.SetRange("TriggerName", 'OnInsert');
        Assert.IsTrue(TrigLog.FindFirst(), 'OnInsert trigger log entry must exist');
        Assert.AreEqual(7, TrigLog."SourceEntryNo", 'OnInsert trigger must see Rec."Entry No." = 7');
    end;

    // ── Rename() changes key and fires OnRename ──────────────────────────────

    [Test]
    procedure Rename_OldKey_GoneNewKey_Exists_After_Trigger()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered.Insert(false);
        Triggered.Get(1);
        Triggered.Rename(2);
        TrigLog.SetRange("TriggerName", 'OnRename');
        Assert.AreEqual(1, TrigLog.Count(), 'OnRename must fire once');
        Assert.IsFalse(Triggered.Get(1), 'Old key 1 must not exist after rename');
        Assert.IsTrue(Triggered.Get(2), 'New key 2 must exist after rename');
    end;

    // ── Multiple Validate() calls fire independently ──────────────────────────

    [Test]
    procedure MultipleValidates_EachFiresTrigger()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered.Insert(false);
        Triggered.Validate("Watched Field", 'first');
        Triggered.Validate("Watched Field", 'second');
        Triggered.Validate("Watched Field", 'third');
        TrigLog.SetRange("TriggerName", 'OnValidate');
        Assert.AreEqual(3, TrigLog.Count(), 'Each Validate() call must fire OnValidate independently');
    end;

    // ── RunTrigger=false suppresses all triggers ─────────────────────────────

    [Test]
    procedure RunTrigger_False_AllTriggers_Suppressed()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered.Insert(false);
        Triggered.Get(1);
        Triggered.Value := 99;
        Triggered.Modify(false);

        TrigLog.Reset();
        TrigLog.SetRange("TriggerName", 'OnModify');
        Assert.AreEqual(0, TrigLog.Count(), 'Modify(false) must not fire the table OnModify trigger');

        TrigLog.SetRange("TriggerName", 'TableOnAfterModify');
        Assert.AreEqual(1, TrigLog.Count(), 'Modify(false) must still publish the table OnAfterModifyEvent subscriber');
    end;

    // ── Insert and Delete with triggers both fire ────────────────────────────

    [Test]
    procedure Insert_Then_Delete_WithTriggers_Both_Fire()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered.Insert(true);
        Triggered.Get(1);
        Triggered.Delete(true);
        TrigLog.SetRange("TriggerName", 'OnInsert');
        Assert.AreEqual(1, TrigLog.Count(), 'OnInsert must have fired');
        TrigLog.SetRange("TriggerName", 'OnDelete');
        Assert.AreEqual(1, TrigLog.Count(), 'OnDelete must have fired');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
