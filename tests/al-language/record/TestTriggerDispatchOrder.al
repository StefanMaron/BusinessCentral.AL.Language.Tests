// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-types
// Scope: in-scope
// Fixtures used: ALT Triggered (60002), ALT Trigger Log (60003), ALT Table Event Subscriber (60016), ALT Triggered Order Ext (60024)

codeunit 60210 "Test Trigger Dispatch Order"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure TriggerOrder_Validate_FieldPipeline_IsStable()
    var
        Triggered: Record "ALT Triggered";
    begin
        Initialize();
        Triggered."Entry No." := 101;
        Triggered.Insert(false);

        ClearLog();

        Triggered.Get(101);
        Triggered.Validate("Watched Field", 'Validated');

        Assert.AreEqual(
            'TableOnBeforeValidate,TableExtOnBeforeValidate,OnValidate,TableExtOnAfterValidate,TableOnAfterValidate',
            GetTriggerOrder(),
            'Validate must keep the expected order across table subscribers, tableextension field triggers, and the table field trigger');
    end;

    [Test]
    procedure TriggerOrder_Insert_RecordPipeline_IsStable()
    var
        Triggered: Record "ALT Triggered";
    begin
        Initialize();
        Triggered."Entry No." := 102;
        Triggered.Value := 12;
        Triggered."Watched Field" := 'Insert';

        Triggered.Insert(true);

        Assert.AreEqual(
            'TableOnBeforeInsert,TableExtOnBeforeInsert,OnInsert,TableExtOnInsert,TableExtOnAfterInsert,TableOnAfterInsert',
            GetTriggerOrder(),
            'Insert must keep the expected order across table subscribers, tableextension triggers, and after-events');
    end;

    [Test]
    procedure TriggerOrder_Modify_RecordPipeline_IsStable()
    var
        Triggered: Record "ALT Triggered";
    begin
        Initialize();
        Triggered."Entry No." := 103;
        Triggered.Value := 1;
        Triggered."Watched Field" := 'BeforeModify';
        Triggered.Insert(false);

        ClearLog();

        Triggered.Get(103);
        Triggered.Value := 99;
        Triggered."Watched Field" := 'AfterModify';
        Triggered.Modify(true);

        Assert.AreEqual(
            'TableOnBeforeModify,TableExtOnBeforeModify,OnModify,TableExtOnModify,TableExtOnAfterModify,TableOnAfterModify',
            GetTriggerOrder(),
            'Modify must keep the expected order across table subscribers, tableextension triggers, and after-events');
    end;

    [Test]
    procedure TriggerOrder_Delete_RecordPipeline_IsStable()
    var
        Triggered: Record "ALT Triggered";
    begin
        Initialize();
        Triggered."Entry No." := 104;
        Triggered.Value := 4;
        Triggered."Watched Field" := 'Delete';
        Triggered.Insert(false);

        ClearLog();

        Triggered.Get(104);
        Triggered.Delete(true);

        Assert.AreEqual(
            'TableOnBeforeDelete,TableExtOnBeforeDelete,OnDelete,TableExtOnDelete,TableExtOnAfterDelete,TableOnAfterDelete',
            GetTriggerOrder(),
            'Delete must keep the expected order across table subscribers, tableextension triggers, and after-events');
    end;

    [Test]
    procedure TriggerOrder_Rename_RecordPipeline_IsStable()
    var
        Triggered: Record "ALT Triggered";
    begin
        Initialize();
        Triggered."Entry No." := 105;
        Triggered.Value := 5;
        Triggered."Watched Field" := 'Rename';
        Triggered.Insert(false);

        ClearLog();

        Triggered.Get(105);
        Triggered.Rename(205);

        Assert.AreEqual(
            'TableOnBeforeRename,TableExtOnBeforeRename,OnRename,TableExtOnRename,TableExtOnAfterRename,TableOnAfterRename',
            GetTriggerOrder(),
            'Rename must keep the expected order across table subscribers, tableextension triggers, and after-events');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    local procedure ClearLog()
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.DeleteAll(false);
    end;

    local procedure GetTriggerOrder(): Text
    var
        TrigLog: Record "ALT Trigger Log";
        OrderText: Text;
    begin
        if not TrigLog.FindSet() then
            exit('');

        repeat
            if OrderText <> '' then
                OrderText += ',';
            OrderText += TrigLog.TriggerName;
        until TrigLog.Next() = 0;

        exit(OrderText);
    end;
}
