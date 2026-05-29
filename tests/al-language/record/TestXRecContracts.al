// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-overview
// Scope: in-scope
// Fixtures used: ALT Triggered (60002), ALT Trigger Log (60003)
//
// xRec can only be read from inside table triggers.
// The shared ALT Triggered fixture logs both Rec and xRec snapshots so the tests
// can assert the runtime contract directly, including the code-path quirks where
// xRec mirrors Rec instead of exposing a stored before-image.

codeunit 60179 "Test xRec Contracts"
{
    Subtype = Test;
    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure OnInsert_xRec_MirrorsRecValues_WhenCalledFromCode()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 7;
        Triggered.Value := 42;
        Triggered."Watched Field" := 'NewText';

        Triggered.Insert(true);

        FindTriggerLog(TrigLog, 'OnInsert');
        Assert.AreEqual(7, TrigLog."OldEntryNo", 'OnInsert xRec must mirror Rec key when Insert(true) is called from code');
        Assert.AreEqual(7, TrigLog."NewEntryNo", 'OnInsert Rec must expose the inserted key value');
        Assert.AreEqual(42, TrigLog."OldIntegerValue", 'OnInsert xRec must mirror Rec integer value when Insert(true) is called from code');
        Assert.AreEqual(42, TrigLog."NewIntegerValue", 'OnInsert Rec must expose the inserted integer value');
        Assert.AreEqual('NewText', TrigLog."OldValue", 'OnInsert xRec must mirror Rec text value when Insert(true) is called from code');
        Assert.AreEqual('NewText', TrigLog."NewValue", 'OnInsert Rec must expose the inserted text value');
    end;

    [Test]
    procedure OnModify_xRec_MirrorsRecValues_WhenCalledFromCode()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered.Value := 5;
        Triggered.Insert(false);

        Triggered.Get(1);
        Triggered.Value := 9;
        Triggered.Modify(true);

        FindTriggerLog(TrigLog, 'OnModify');
        Assert.AreEqual(1, TrigLog."OldEntryNo", 'OnModify xRec must keep the current key');
        Assert.AreEqual(1, TrigLog."NewEntryNo", 'OnModify Rec must keep the current key');
        Assert.AreEqual(9, TrigLog."OldIntegerValue", 'OnModify xRec must mirror the new integer value when Modify(true) is called from code');
        Assert.AreEqual(9, TrigLog."NewIntegerValue", 'OnModify Rec must expose the new integer value');
    end;

    [Test]
    procedure OnDelete_xRec_ReflectsPreDeleteRecord()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 3;
        Triggered.Value := 11;
        Triggered.Insert(false);

        Triggered.Get(3);
        Triggered.Delete(true);

        FindTriggerLog(TrigLog, 'OnDelete');
        Assert.AreEqual(3, TrigLog."OldEntryNo", 'OnDelete xRec must keep the deleted key');
        Assert.AreEqual(3, TrigLog."NewEntryNo", 'OnDelete Rec must still expose the deleted key inside the trigger');
        Assert.AreEqual(11, TrigLog."OldIntegerValue", 'OnDelete xRec must expose the deleted integer value');
        Assert.AreEqual(11, TrigLog."NewIntegerValue", 'OnDelete Rec must still expose the deleted integer value inside the trigger');
    end;

    [Test]
    procedure OnRename_xRec_ReflectsPreRenameKey()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered.Value := 77;
        Triggered.Insert(false);

        Triggered.Get(1);
        Triggered.Rename(99);

        FindTriggerLog(TrigLog, 'OnRename');
        Assert.AreEqual(1, TrigLog."OldEntryNo", 'OnRename xRec must keep the original key');
        Assert.AreEqual(99, TrigLog."NewEntryNo", 'OnRename Rec must expose the new key');
        Assert.AreEqual(77, TrigLog."OldIntegerValue", 'OnRename xRec must keep the original field values');
        Assert.AreEqual(77, TrigLog."NewIntegerValue", 'OnRename Rec must keep the same field values while the key changes');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    local procedure FindTriggerLog(var TrigLog: Record "ALT Trigger Log"; TriggerName: Code[30])
    begin
        TrigLog.SetRange("TriggerName", TriggerName);
        Assert.IsTrue(TrigLog.FindFirst(), StrSubstNo('%1 trigger must fire', TriggerName));
    end;
}
