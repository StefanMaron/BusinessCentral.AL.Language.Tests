table 60976 "ALT Manual TableEvent Pub"
{
    // Sibling of "ALT Triggered" (60002), which only exercises the IMPLICIT table trigger
    // events (OnAfterInsertEvent, OnAfterDeleteEvent, ...). This table additionally declares
    // and raises a MANUAL [IntegrationEvent] from inside its OnDelete trigger, so a test can
    // prove that subscribers to a manually-declared table-published event fire, distinct from
    // subscribers to the implicit trigger event that also fires on the same Delete() call.
    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        // Marker proving the trigger body itself ran and reached the raise statement,
        // independent of whether the event dispatch that follows actually fires a subscriber.
        TrigLog.Init();
        TrigLog.TriggerName := 'ManualTblPubOnDeleteRan';
        TrigLog.SourceEntryNo := Rec."Entry No.";
        TrigLog.Insert();

        OnAfterManualTableEventPubDelete(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterManualTableEventPubDelete(var Rec: Record "ALT Manual TableEvent Pub")
    begin
    end;
}
