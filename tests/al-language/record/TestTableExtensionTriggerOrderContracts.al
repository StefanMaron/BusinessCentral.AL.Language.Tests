// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-triggers
// Scope: in-scope
// Fixtures used: ALT Triggered (60002) and its table extension "ALT Triggered Order Ext" (60024),
//                ALT Trigger Log (60003), the fixture subscribers that log the table events and the
//                Global Triggers events, ALTFixtureCleanup (60019), shared Assert (60021)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins the complete order of table events, table triggers, table extension triggers and Global
// Triggers events for each write, with and without RunTrigger: the extension's triggers run only
// when RunTrigger is true (Insert, Modify, Delete and DeleteAll), the Global Triggers events
// (OnDatabase...) run for every write, and Rename logs OnGlobalRename as well.
// BC versions: 27.5

codeunit 68212 "Probe Table Ext Trigger Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    var
        ALTTriggered: Record "ALT Triggered";
    begin
        Cleanup.Initialize();
        ALTTriggered.DeleteAll(false);
        TakeNames();
    end;

    local procedure TakeNames(): Text
    var
        TriggerLog: Record "ALT Trigger Log";
        Result: Text;
    begin
        TriggerLog.SetCurrentKey("Entry No.");
        if TriggerLog.FindSet() then
            repeat
                Result += TriggerLog.TriggerName + ',';
            until TriggerLog.Next() = 0;
        TriggerLog.DeleteAll();
        exit(Result);
    end;

    [Test]
    procedure Insert_WithAndWithoutRunTrigger()
    var
        ALTTriggered: Record "ALT Triggered";
    begin
        Initialize();

        ALTTriggered.Init();
        ALTTriggered."Entry No." := 1;
        ALTTriggered.Insert(false);
        Assert.AreEqual('TABLEONBEFOREINSERT,ONDATABASEINSERT,TABLEONAFTERINSERT,', TakeNames(), 'Insert(false)');

        ALTTriggered.Init();
        ALTTriggered."Entry No." := 2;
        ALTTriggered.Insert(true);
        Assert.AreEqual('TABLEONBEFOREINSERT,TABLEEXTONBEFOREINSERT,ONINSERT,TABLEEXTONINSERT,ONDATABASEINSERT,TABLEEXTONAFTERINSERT,TABLEONAFTERINSERT,', TakeNames(), 'Insert(true)');
    end;

    [Test]
    procedure Modify_WithAndWithoutRunTrigger()
    var
        ALTTriggered: Record "ALT Triggered";
    begin
        Initialize();
        ALTTriggered.Init();
        ALTTriggered."Entry No." := 1;
        ALTTriggered.Insert(false);
        TakeNames();

        ALTTriggered.Value := 5;
        ALTTriggered.Modify(true);
        Assert.AreEqual('TABLEONBEFOREMODIFY,TABLEEXTONBEFOREMODIFY,ONMODIFY,TABLEEXTONMODIFY,ONDATABASEMODIFY,TABLEEXTONAFTERMODIFY,TABLEONAFTERMODIFY,', TakeNames(), 'Modify(true)');

        ALTTriggered.Value := 6;
        ALTTriggered.Modify(false);
        Assert.AreEqual('TABLEONBEFOREMODIFY,ONDATABASEMODIFY,TABLEONAFTERMODIFY,', TakeNames(), 'Modify(false)');
    end;

    [Test]
    procedure Rename_AlwaysRunsTheTriggers_AndTheGlobalRenameEvent()
    var
        ALTTriggered: Record "ALT Triggered";
    begin
        Initialize();
        ALTTriggered.Init();
        ALTTriggered."Entry No." := 1;
        ALTTriggered.Insert(false);
        TakeNames();

        ALTTriggered.Rename(2);

        Assert.AreEqual('TABLEONBEFORERENAME,TABLEEXTONBEFORERENAME,ONRENAME,TABLEEXTONRENAME,ONGLOBALRENAME,ONDATABASERENAME,TABLEEXTONAFTERRENAME,TABLEONAFTERRENAME,', TakeNames(), 'Rename');
    end;

    [Test]
    procedure Delete_And_DeleteAll_WithAndWithoutRunTrigger()
    var
        ALTTriggered: Record "ALT Triggered";
        Rows: Record "ALT Triggered";
    begin
        Initialize();
        ALTTriggered.Init();
        ALTTriggered."Entry No." := 1;
        ALTTriggered.Insert(false);
        TakeNames();

        ALTTriggered.Delete(false);
        Assert.AreEqual('TABLEONBEFOREDELETE,ONDATABASEDELETE,TABLEONAFTERDELETE,', TakeNames(), 'Delete(false)');

        ALTTriggered.Init();
        ALTTriggered."Entry No." := 2;
        ALTTriggered.Insert(false);
        ALTTriggered."Entry No." := 3;
        ALTTriggered.Insert(false);
        TakeNames();
        Rows.DeleteAll(false);
        Assert.AreEqual('TABLEONBEFOREDELETE,ONDATABASEDELETE,TABLEONAFTERDELETE,TABLEONBEFOREDELETE,ONDATABASEDELETE,TABLEONAFTERDELETE,', TakeNames(), 'DeleteAll(false): events per row, no extension triggers');

        ALTTriggered."Entry No." := 4;
        ALTTriggered.Insert(false);
        TakeNames();
        Rows.DeleteAll(true);
        Assert.AreEqual('TABLEONBEFOREDELETE,TABLEEXTONBEFOREDELETE,ONDELETE,TABLEEXTONDELETE,ONDATABASEDELETE,TABLEEXTONAFTERDELETE,TABLEONAFTERDELETE,', TakeNames(), 'DeleteAll(true)');
    end;

    [Test]
    procedure Validate_BaseFieldAndExtensionField_Order()
    var
        ALTTriggered: Record "ALT Triggered";
    begin
        Initialize();
        ALTTriggered.Init();
        ALTTriggered."Entry No." := 1;

        ALTTriggered.Validate("Watched Field", 'w');
        Assert.AreEqual('TABLEONBEFOREVALIDATE,TABLEEXTONBEFOREVALIDATE,ONVALIDATE,TABLEEXTONAFTERVALIDATE,TABLEONAFTERVALIDATE,', TakeNames(), 'base field');

        ALTTriggered.Validate("Ext Validated", 'e');
        Assert.AreEqual('TABLEEXTFIELDONVALIDATE,', TakeNames(), 'extension field: only its own trigger');
    end;
}
