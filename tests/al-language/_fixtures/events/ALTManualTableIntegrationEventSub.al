codeunit 60946 "ALT ManualTableEvt Ctrl Sub"
{
    // Three subscribers, one per publisher kind, distinguished only by which raises the
    // event — used by TestManualTableIntegrationEvent.al to prove that a manually-declared
    // [IntegrationEvent] raised from inside a TABLE's own trigger code dispatches to its
    // subscriber exactly like the implicit table-trigger event and the codeunit-published
    // event already do.

    [EventSubscriber(ObjectType::Table, Database::"ALT Manual TableEvent Pub", 'OnAfterManualTableEventPubDelete', '', false, false)]
    local procedure OnManualTableIntegrationEvent(var Rec: Record "ALT Manual TableEvent Pub")
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.Init();
        TrigLog.TriggerName := 'ManualIntegrationEventFired';
        TrigLog.SourceEntryNo := Rec."Entry No.";
        TrigLog.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"ALT Manual TableEvent Pub", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnImplicitDeleteEvent(var Rec: Record "ALT Manual TableEvent Pub"; RunTrigger: Boolean)
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.Init();
        TrigLog.TriggerName := 'ImplicitDeleteEventFired';
        TrigLog.SourceEntryNo := Rec."Entry No.";
        TrigLog.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ALT Event Publisher", 'OnBeforeAction', '', false, false)]
    local procedure OnCodeunitIntegrationEvent(EntryNo: Integer; var Handled: Boolean)
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.Init();
        TrigLog.TriggerName := 'CodeunitEventFired';
        TrigLog.SourceEntryNo := EntryNo;
        TrigLog.Insert();
    end;
}
