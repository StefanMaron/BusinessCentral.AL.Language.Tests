// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-publisher-subscriber
// Scope: fixture report used by TestManualObjectIntegrationEvent.al
//
// Sibling of "ALT Manual TableEvent Pub" (60976). This report declares and raises a
// manually-declared [IntegrationEvent] from its own dataitem trigger code, so the same
// "manual publisher fires its subscriber" claim can be proven for a REPORT-published event.
report 60978 "ALT Manual ReportEvent Pub"
{
    Caption = 'ALT Manual ReportEvent Pub';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(ALTUniversal; "ALT Universal")
        {
            trigger OnPreDataItem()
            var
                TrigLog: Record "ALT Trigger Log";
            begin
                // Marker proving the dataitem trigger body itself ran and reached the raise
                // statement, independent of whether the event dispatch that follows actually
                // fires a subscriber.
                TrigLog.Init();
                TrigLog.TriggerName := 'ManualReportPubRan';
                TrigLog.SourceEntryNo := SourceEntryNo;
                TrigLog.Insert();

                OnAfterManualReportEventPub(SourceEntryNo);
            end;
        }
    }

    var
        SourceEntryNo: Integer;

    procedure SetSourceEntryNo(EntryNo: Integer)
    begin
        SourceEntryNo := EntryNo;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterManualReportEventPub(SourceEntryNo: Integer)
    begin
    end;
}
