// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-types
// Scope: in-scope
// Fixtures used: ALT Triggered (60002), ALT Trigger Log (60003), ALT Table Event Subscriber (60016)

codeunit 60208 "Test Table Event Dispatch"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure TableEvent_OnAfterValidate_FieldSubscriber_Fires()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered.Insert(false);

        Triggered.Get(1);
        Triggered.Validate("Watched Field", 'ValidatedValue');

        FindLog(TrigLog, 'TableOnAfterValidate');
        Assert.AreEqual(1, TrigLog."SourceEntryNo", 'OnAfterValidateEvent subscriber must receive the validated record');
        Assert.AreEqual('ValidatedValue', TrigLog."NewValue", 'OnAfterValidateEvent subscriber must see the post-validate field value');
    end;

    [Test]
    procedure TableEvent_OnAfterInsert_Subscriber_Fires()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 2;
        Triggered.Value := 20;
        Triggered."Watched Field" := 'InsertedValue';

        Triggered.Insert(true);

        FindLog(TrigLog, 'TableOnAfterInsert');
        Assert.AreEqual(2, TrigLog."NewEntryNo", 'OnAfterInsertEvent subscriber must receive the inserted key');
        Assert.AreEqual(20, TrigLog."NewIntegerValue", 'OnAfterInsertEvent subscriber must receive the inserted integer value');
        Assert.AreEqual('InsertedValue', TrigLog."NewValue", 'OnAfterInsertEvent subscriber must receive the inserted text value');
    end;

    [Test]
    procedure TableEvent_OnAfterModify_Subscriber_Fires()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 3;
        Triggered.Value := 1;
        Triggered.Insert(false);

        Triggered.Get(3);
        Triggered.Value := 30;
        Triggered."Watched Field" := 'ModifiedValue';
        Triggered.Modify(true);

        FindLog(TrigLog, 'TableOnAfterModify');
        Assert.AreEqual(3, TrigLog."NewEntryNo", 'OnAfterModifyEvent subscriber must receive the modified key');
        Assert.AreEqual(30, TrigLog."NewIntegerValue", 'OnAfterModifyEvent subscriber must receive the modified integer value');
        Assert.AreEqual('ModifiedValue', TrigLog."NewValue", 'OnAfterModifyEvent subscriber must receive the modified text value');
    end;

    [Test]
    procedure TableEvent_OnAfterDelete_Subscriber_Fires()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 4;
        Triggered.Value := 40;
        Triggered."Watched Field" := 'DeletedValue';
        Triggered.Insert(false);

        Triggered.Get(4);
        Triggered.Delete(true);

        FindLog(TrigLog, 'TableOnAfterDelete');
        Assert.AreEqual(4, TrigLog."NewEntryNo", 'OnAfterDeleteEvent subscriber must receive the deleted key');
        Assert.AreEqual(40, TrigLog."NewIntegerValue", 'OnAfterDeleteEvent subscriber must receive the deleted integer value');
        Assert.AreEqual('DeletedValue', TrigLog."NewValue", 'OnAfterDeleteEvent subscriber must receive the deleted text value');
    end;

    [Test]
    procedure TableEvent_OnAfterRename_Subscriber_FiresWithOldAndNewKeys()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 5;
        Triggered.Value := 50;
        Triggered.Insert(false);

        Triggered.Get(5);
        Triggered.Rename(55);

        FindLog(TrigLog, 'TableOnAfterRename');
        Assert.AreEqual(5, TrigLog."OldEntryNo", 'OnAfterRenameEvent subscriber must receive the original key');
        Assert.AreEqual(55, TrigLog."NewEntryNo", 'OnAfterRenameEvent subscriber must receive the renamed key');
        Assert.AreEqual(50, TrigLog."OldIntegerValue", 'OnAfterRenameEvent subscriber must preserve the pre-rename field values');
        Assert.AreEqual(50, TrigLog."NewIntegerValue", 'OnAfterRenameEvent subscriber must preserve the post-rename field values');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    local procedure FindLog(var TrigLog: Record "ALT Trigger Log"; TriggerName: Code[30])
    begin
        TrigLog.SetRange("TriggerName", TriggerName);
        Assert.IsTrue(TrigLog.FindFirst(), StrSubstNo('%1 subscriber must fire', TriggerName));
    end;
}
