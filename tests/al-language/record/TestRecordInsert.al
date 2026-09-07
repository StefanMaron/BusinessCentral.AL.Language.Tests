// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert--method
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Triggered (60002), ALT Trigger Log (60003)

codeunit 60050 "Test Record Insert"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Record.Insert() ──────────────────────────────────────────────────────

    [Test]
    procedure Record_Insert_NewRecord_ReturnsTrue()
    var
        Rec: Record "ALT Universal";
        Result: Boolean;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Result := Rec.Insert();
        Assert.IsTrue(Result, 'Insert() must return true for a new record');
    end;

    [Test]
    procedure Record_Insert_DuplicateKey_ReturnsFalse()
    var
        Rec: Record "ALT Universal";
        Result: Boolean;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Clear(Rec);
        Rec."Entry No." := 1;
        Result := Rec.Insert();
        Assert.IsFalse(Result, 'Insert() must return false when the primary key already exists');
    end;

    [Test]
    procedure Record_Insert_EmptyTable_CountIsOne()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Assert.AreEqual(1, Rec.Count(), 'Count() must be 1 after one insert into an empty table');
    end;

    // ── Record.Insert(RunTrigger: Boolean) ───────────────────────────────────

    [Test]
    procedure Record_Insert_RunTriggerTrue_FiresOnInsert()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered.Insert(true);
        TrigLog.SetRange("TriggerName", 'OnInsert');
        Assert.AreEqual(1, TrigLog.Count(), 'OnInsert trigger must fire exactly once when RunTrigger=true');
    end;

    [Test]
    procedure Record_Insert_RunTriggerFalse_DoesNotFireOnInsert()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered.Insert(false);
        TrigLog.SetRange("TriggerName", 'OnInsert');
        Assert.AreEqual(0, TrigLog.Count(), 'OnInsert trigger must NOT fire when RunTrigger=false');
    end;

    // ── Record.Insert(RunTrigger: Boolean, InsertWithSystemId: Boolean) ──────

    [Test]
    procedure Record_Insert_InsertWithSystemId_PreservesGuid()
    var
        Rec: Record "ALT Universal";
        ExpectedId: Guid;
        Fetched: Record "ALT Universal";
    begin
        Initialize();
        ExpectedId := CreateGuid();
        Rec."Entry No." := 1;
        Rec.SystemId := ExpectedId;
        Rec.Insert(false, true);
        Fetched.GetBySystemId(ExpectedId);
        Assert.AreEqual(ExpectedId, Fetched.SystemId, 'SystemId must be preserved when InsertWithSystemId=true');
    end;

    [Test]
    procedure Record_Insert_InsertWithoutSystemId_GeneratesNonEmptyGuid()
    var
        Rec: Record "ALT Universal";
        EmptyGuid: Guid;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert(false, false);
        Assert.AreNotEqual(Format(EmptyGuid), Format(Rec.SystemId), 'SystemId must be auto-generated (non-empty) when InsertWithSystemId=false');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
