// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-publisher-subscriber
// Scope: fixture query used by TestManualObjectIntegrationEvent.al
//
// Sibling of "ALT Manual TableEvent Pub" (60976). This query declares and raises a
// manually-declared [IntegrationEvent] from its own code, so the same "manual publisher
// fires its subscriber" claim can be proven for a QUERY-published event.
query 60981 "ALT Manual QueryEvent Pub"
{
    QueryType = Normal;

    elements
    {
        dataitem(ALTUniversal; "ALT Universal")
        {
            column(EntryNo; "Entry No.")
            {
            }
        }
    }

    procedure RaiseManualQueryEvent(SourceEntryNo: Integer)
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        // Marker proving the query's own code ran and reached the raise statement,
        // independent of whether the event dispatch that follows actually fires a subscriber.
        TrigLog.Init();
        TrigLog.TriggerName := 'ManualQueryPubRan';
        TrigLog.SourceEntryNo := SourceEntryNo;
        TrigLog.Insert();

        OnAfterManualQueryEventPub(SourceEntryNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterManualQueryEventPub(SourceEntryNo: Integer)
    begin
    end;
}
