codeunit 60025 "ALT Global Trigger Sub"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetGlobalTableTriggerMask', '', false, false)]
    local procedure EnableGlobalTableTriggers(TableId: Integer; var TableTriggerMask: Integer)
    begin
        if TableId <> Database::"ALT Triggered" then
            exit;

        TableTriggerMask := 15;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalInsert', '', false, false)]
    local procedure OnGlobalInsert(RecRef: RecordRef)
    begin
        if RecRef.Number <> Database::"ALT Triggered" then
            exit;

        LogInsert(RecRef, 'OnGlobalInsert');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalModify', '', false, false)]
    local procedure OnGlobalModify(RecRef: RecordRef; xRecRef: RecordRef)
    begin
        if RecRef.Number <> Database::"ALT Triggered" then
            exit;

        LogModify(RecRef, xRecRef, 'OnGlobalModify');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalDelete', '', false, false)]
    local procedure OnGlobalDelete(RecRef: RecordRef)
    begin
        if RecRef.Number <> Database::"ALT Triggered" then
            exit;

        LogDelete(RecRef, 'OnGlobalDelete');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalRename', '', false, false)]
    local procedure OnGlobalRename(RecRef: RecordRef; xRecRef: RecordRef)
    begin
        if RecRef.Number <> Database::"ALT Triggered" then
            exit;

        LogModify(RecRef, xRecRef, 'OnGlobalRename');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetDatabaseTableTriggerSetup', '', false, false)]
    local procedure EnableDatabaseTableTriggers(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
        if TableId <> Database::"ALT Triggered" then
            exit;

        OnDatabaseInsert := true;
        OnDatabaseModify := true;
        OnDatabaseDelete := true;
        OnDatabaseRename := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseInsert', '', false, false)]
    local procedure OnDatabaseInsert(RecRef: RecordRef)
    begin
        if RecRef.Number <> Database::"ALT Triggered" then
            exit;

        LogInsert(RecRef, 'OnDatabaseInsert');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseModify', '', false, false)]
    local procedure OnDatabaseModify(RecRef: RecordRef)
    begin
        if RecRef.Number <> Database::"ALT Triggered" then
            exit;

        LogInsert(RecRef, 'OnDatabaseModify');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseDelete', '', false, false)]
    local procedure OnDatabaseDelete(RecRef: RecordRef)
    begin
        if RecRef.Number <> Database::"ALT Triggered" then
            exit;

        LogDelete(RecRef, 'OnDatabaseDelete');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseRename', '', false, false)]
    local procedure OnDatabaseRename(RecRef: RecordRef; xRecRef: RecordRef)
    begin
        if RecRef.Number <> Database::"ALT Triggered" then
            exit;

        LogModify(RecRef, xRecRef, 'OnDatabaseRename');
    end;

    local procedure LogInsert(RecRef: RecordRef; TriggerName: Code[30])
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        RecRef.SetTable(Triggered);
        TrigLog.Init();
        TrigLog.TriggerName := TriggerName;
        TrigLog.SourceEntryNo := Triggered."Entry No.";
        TrigLog.NewEntryNo := Triggered."Entry No.";
        TrigLog.NewIntegerValue := Triggered.Value;
        TrigLog.NewValue := Triggered."Watched Field";
        TrigLog.Insert();
    end;

    local procedure LogModify(RecRef: RecordRef; xRecRef: RecordRef; TriggerName: Code[30])
    var
        Triggered: Record "ALT Triggered";
        XTriggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        RecRef.SetTable(Triggered);
        xRecRef.SetTable(XTriggered);
        TrigLog.Init();
        TrigLog.TriggerName := TriggerName;
        TrigLog.SourceEntryNo := Triggered."Entry No.";
        TrigLog.OldEntryNo := XTriggered."Entry No.";
        TrigLog.NewEntryNo := Triggered."Entry No.";
        TrigLog.OldIntegerValue := XTriggered.Value;
        TrigLog.NewIntegerValue := Triggered.Value;
        TrigLog.OldValue := XTriggered."Watched Field";
        TrigLog.NewValue := Triggered."Watched Field";
        TrigLog.Insert();
    end;

    local procedure LogDelete(RecRef: RecordRef; TriggerName: Code[30])
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        RecRef.SetTable(Triggered);
        TrigLog.Init();
        TrigLog.TriggerName := TriggerName;
        TrigLog.SourceEntryNo := Triggered."Entry No.";
        TrigLog.NewEntryNo := Triggered."Entry No.";
        TrigLog.NewIntegerValue := Triggered.Value;
        TrigLog.NewValue := Triggered."Watched Field";
        TrigLog.Insert();
    end;
}
