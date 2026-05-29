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
            'TABLEONBEFOREVALIDATE,TABLEEXTONBEFOREVALIDATE,ONVALIDATE,TABLEEXTONAFTERVALIDATE,TABLEONAFTERVALIDATE',
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
            'TABLEONBEFOREINSERT,TABLEEXTONBEFOREINSERT,ONINSERT,TABLEEXTONINSERT,ONDATABASEINSERT,TABLEEXTONAFTERINSERT,TABLEONAFTERINSERT',
            GetTriggerOrder(),
            'Insert must keep the expected order across table subscribers, tableextension triggers, and database after-events');
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
            'TABLEONBEFOREMODIFY,TABLEEXTONBEFOREMODIFY,ONMODIFY,TABLEEXTONMODIFY,ONDATABASEMODIFY,TABLEEXTONAFTERMODIFY,TABLEONAFTERMODIFY',
            GetTriggerOrder(),
            'Modify must keep the expected order across table subscribers, tableextension triggers, and database after-events');
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
            'TABLEONBEFOREDELETE,TABLEEXTONBEFOREDELETE,ONDELETE,TABLEEXTONDELETE,ONDATABASEDELETE,TABLEEXTONAFTERDELETE,TABLEONAFTERDELETE',
            GetTriggerOrder(),
            'Delete must keep the expected order across table subscribers, tableextension triggers, and database after-events');
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
            'TABLEONBEFORERENAME,TABLEEXTONBEFORERENAME,ONRENAME,TABLEEXTONRENAME,ONGLOBALRENAME,ONDATABASERENAME,TABLEEXTONAFTERRENAME,TABLEONAFTERRENAME',
            GetTriggerOrder(),
            'Rename must keep the expected order across table subscribers, tableextension triggers, and after-events');
    end;

    [Test]
    procedure TriggerOrder_GlobalTriggerDispatch_MatchesObservedRuntime()
    var
        Triggered: Record "ALT Triggered";
    begin
        Initialize();

        Triggered."Entry No." := 106;
        Triggered.Value := 6;
        Triggered."Watched Field" := 'InsertGlobal';
        Triggered.Insert(true);
        AssertDoesNotContainTrigger('ONGLOBALINSERT', 'Insert must not publish OnGlobalInsert in BC 27.5 or 28.1');
        AssertContainsTrigger('ONDATABASEINSERT', 'Insert must publish OnDatabaseInsert when database triggers are enabled');

        ClearLog();

        Triggered.Get(106);
        Triggered.Value := 7;
        Triggered."Watched Field" := 'ModifyGlobal';
        Triggered.Modify(true);
        AssertDoesNotContainTrigger('ONGLOBALMODIFY', 'Modify must not publish OnGlobalModify in BC 27.5 or 28.1');
        AssertContainsTrigger('ONDATABASEMODIFY', 'Modify must publish OnDatabaseModify when database triggers are enabled');

        ClearLog();

        Triggered.Get(106);
        Triggered.Delete(true);
        AssertDoesNotContainTrigger('ONGLOBALDELETE', 'Delete must not publish OnGlobalDelete in BC 27.5 or 28.1');
        AssertContainsTrigger('ONDATABASEDELETE', 'Delete must publish OnDatabaseDelete when database triggers are enabled');

        ClearLog();

        Triggered."Entry No." := 107;
        Triggered.Value := 8;
        Triggered."Watched Field" := 'RenameGlobal';
        Triggered.Insert(false);
        ClearLog();

        Triggered.Get(107);
        Triggered.Rename(207);
        AssertContainsTrigger('ONGLOBALRENAME', 'Rename must publish OnGlobalRename when global triggers are enabled');
        AssertContainsTrigger('ONDATABASERENAME', 'Rename must publish OnDatabaseRename when database triggers are enabled');
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

    local procedure AssertContainsTrigger(TriggerName: Code[30]; FailureMessage: Text)
    begin
        Assert.AreNotEqual(0, StrPos(GetTriggerOrder(), TriggerName), FailureMessage);
    end;

    local procedure AssertDoesNotContainTrigger(TriggerName: Code[30]; FailureMessage: Text)
    begin
        Assert.AreEqual(0, StrPos(GetTriggerOrder(), TriggerName), FailureMessage);
    end;
}
