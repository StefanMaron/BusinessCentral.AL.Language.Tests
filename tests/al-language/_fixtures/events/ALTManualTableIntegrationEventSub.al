codeunit 60949 "ALT ManualTableEvt Ctrl Sub"
{
    // Three subscribers, one per publisher kind, distinguished only by which raises the
    // event — used by TestManualTableIntegrationEvent.al to prove that a manually-declared
    // [IntegrationEvent] raised from inside a TABLE's own trigger code dispatches to its
    // subscriber exactly like the implicit table-trigger event and the codeunit-published
    // event already do.
    //
    // The codeunit-control publisher is declared and raised HERE, self-contained, rather than
    // reusing the shared "ALT Event Publisher" (60014) fixture. Subscribing to that shared
    // publisher's events would also fire this subscriber whenever ANY OTHER test raises them
    // (e.g. TestCodeunitSubscriber's Subscriber_MultipleEvents_AllCaptured, which counts
    // *every* row in "ALT Trigger Log" with no filter) — inflating counts in tests that have
    // no idea this fixture exists. A dedicated event, never raised by anything but our own
    // test, cannot leak into unrelated tests' assertions.

    [IntegrationEvent(false, false)]
    local procedure OnControlCodeunitEvent(EntryNo: Integer)
    begin
    end;

    procedure RaiseControlCodeunitEvent(EntryNo: Integer)
    begin
        OnControlCodeunitEvent(EntryNo);
    end;

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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ALT ManualTableEvt Ctrl Sub", 'OnControlCodeunitEvent', '', false, false)]
    local procedure OnCodeunitIntegrationEvent(EntryNo: Integer)
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.Init();
        TrigLog.TriggerName := 'CodeunitEventFired';
        TrigLog.SourceEntryNo := EntryNo;
        TrigLog.Insert();
    end;
}
