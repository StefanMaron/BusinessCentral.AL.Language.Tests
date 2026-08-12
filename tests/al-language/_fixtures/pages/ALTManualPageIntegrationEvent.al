// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-publisher-subscriber
// Scope: fixture page used by TestManualObjectIntegrationEvent.al
//
// Sibling of "ALT Manual TableEvent Pub" (60976), which proves a manually-declared
// [IntegrationEvent] published from a TABLE's own code dispatches to its subscriber. This
// page declares and raises an equivalent manual event from its own code, so the same claim
// can be proven for a PAGE-published event.
page 60977 "ALT Manual PageEvent Pub"
{
    PageType = Card;
    SourceTable = "ALT Universal";
    Caption = 'ALT Manual PageEvent Pub';

    layout
    {
        area(Content)
        {
            field("Entry No."; Rec."Entry No.")
            {
                ApplicationArea = All;
            }
        }
    }

    procedure RaiseManualPageEvent(SourceEntryNo: Integer)
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        // Marker proving the page's own code ran and reached the raise statement,
        // independent of whether the event dispatch that follows actually fires a subscriber.
        TrigLog.Init();
        TrigLog.TriggerName := 'ManualPagePubRan';
        TrigLog.SourceEntryNo := SourceEntryNo;
        TrigLog.Insert();

        OnAfterManualPageEventPub(SourceEntryNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterManualPageEventPub(SourceEntryNo: Integer)
    begin
    end;
}
