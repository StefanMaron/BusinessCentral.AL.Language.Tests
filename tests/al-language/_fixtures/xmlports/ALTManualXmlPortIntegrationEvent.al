// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-publisher-subscriber
// Scope: fixture xmlport used by TestManualObjectIntegrationEvent.al
//
// Sibling of "ALT Manual TableEvent Pub" (60976). This xmlport declares and raises a
// manually-declared [IntegrationEvent] from its own code, so the same "manual publisher
// fires its subscriber" claim can be proven for an XMLPORT-published event.
xmlport 60982 "ALT Manual XmlPortEvent Pub"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Universal; "ALT Universal")
            {
                fieldelement(EntryNo; Universal."Entry No.")
                {
                }
            }
        }
    }

    procedure RaiseManualXmlPortEvent(SourceEntryNo: Integer)
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        // Marker proving the xmlport's own code ran and reached the raise statement,
        // independent of whether the event dispatch that follows actually fires a subscriber.
        TrigLog.Init();
        TrigLog.TriggerName := 'ManualXmlPortPubRan';
        TrigLog.SourceEntryNo := SourceEntryNo;
        TrigLog.Insert();

        OnAfterManualXmlPortEventPub(SourceEntryNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterManualXmlPortEventPub(SourceEntryNo: Integer)
    begin
    end;
}
