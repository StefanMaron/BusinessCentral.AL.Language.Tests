// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-first-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Triggered (60002), ALT Trigger Log (60003), ALT Triggered Card Page (60028)
//
// CLAIM UNDER TEST: "Test xRec Contracts" (codeunit 60179) proves that xRec, read from a table
// trigger, behaves differently for CODE-driven writes depending on the trigger:
//   - OnModify, code-driven: xRec MIRRORS Rec (new values) -- no before-image.
//   - OnRename, code-driven: xRec correctly holds the PREVIOUS primary key.
// This codeunit asks the other half of the question: does a PAGE-driven write (TestPage field
// edit) behave the same way, or does xRec only carry a real before-image when the write goes
// through a page? See docs/handoff-2026-08-05-xrec-and-relation-propagation.md.

codeunit 60205 "Test xRec Page Contracts"
{
    Subtype = Test;
    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Record_Rename_FromPage_xRecHoldsPreviousKey()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
        CardPage: TestPage "ALT Triggered Card Page";
    begin
        Initialize();
        Triggered."Entry No." := 7;
        Triggered.Insert(false);

        CardPage.OpenEdit();
        CardPage.GoToKey(7);
        CardPage."Entry No.".SetValue(99);
        CardPage.Close();

        TrigLog.SetRange("TriggerName", 'OnRename');
        Assert.IsTrue(TrigLog.FindFirst(), 'OnRename trigger must fire when the PK field is edited on a page');
        Assert.AreEqual(7, TrigLog."OldEntryNo", 'PAGE-driven Rename: xRec must hold the PREVIOUS Entry No. (7) inside OnRename');
        Assert.AreEqual(99, TrigLog."NewEntryNo", 'PAGE-driven Rename: Rec must hold the NEW Entry No. (99) inside OnRename');
    end;

    [Test]
    procedure Record_Modify_FromPage_xRecHoldsPreviousValue()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
        CardPage: TestPage "ALT Triggered Card Page";
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered.Value := 5;
        Triggered.Insert(false);

        CardPage.OpenEdit();
        CardPage.GoToKey(1);
        CardPage."Value".SetValue(9);
        CardPage.Close();

        TrigLog.SetRange("TriggerName", 'OnModify');
        Assert.IsTrue(TrigLog.FindFirst(), 'OnModify trigger must fire when a field is edited on a page');
        Assert.AreEqual(9, TrigLog."NewIntegerValue", 'PAGE-driven Modify: Rec must hold the NEW value (9) inside OnModify');
        Assert.AreEqual(5, TrigLog."OldIntegerValue", 'PAGE-driven Modify: xRec must hold the PREVIOUS value (5), unlike the code-driven case (codeunit 60179) where xRec mirrors Rec');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
