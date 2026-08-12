codeunit 60985 "ALT ManualObjEvt Ctrl Sub"
{
    // One subscriber per NON-table, NON-codeunit publisher kind (Page/Report/Query/XmlPort),
    // proving that a manually-declared [IntegrationEvent] published from inside each of these
    // object kinds' own code dispatches to its subscriber — the sibling gap to the
    // manually-declared TABLE- and CODEUNIT-published events already covered by
    // ALTManualTableIntegrationEventSub.al / table 60976. Codeunit- and table-published manual
    // events are not repeated here.
    //
    // Each publisher is self-contained (declared and raised only by its own fixture object, and
    // only used by TestManualObjectIntegrationEvent.al), so subscribing to it here cannot leak
    // into unrelated tests' "ALT Trigger Log" assertions the way subscribing to the shared
    // "ALT Event Publisher" (60014) would.

    [EventSubscriber(ObjectType::Page, Page::"ALT Manual PageEvent Pub", 'OnAfterManualPageEventPub', '', false, false)]
    local procedure OnManualPageEvent(SourceEntryNo: Integer)
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.Init();
        TrigLog.TriggerName := 'ManualPageEventFired';
        TrigLog.SourceEntryNo := SourceEntryNo;
        TrigLog.Insert();
    end;

    [EventSubscriber(ObjectType::Report, Report::"ALT Manual ReportEvent Pub", 'OnAfterManualReportEventPub', '', false, false)]
    local procedure OnManualReportEvent(SourceEntryNo: Integer)
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.Init();
        TrigLog.TriggerName := 'ManualReportEventFired';
        TrigLog.SourceEntryNo := SourceEntryNo;
        TrigLog.Insert();
    end;

    [EventSubscriber(ObjectType::Query, Query::"ALT Manual QueryEvent Pub", 'OnAfterManualQueryEventPub', '', false, false)]
    local procedure OnManualQueryEvent(SourceEntryNo: Integer)
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.Init();
        TrigLog.TriggerName := 'ManualQueryEventFired';
        TrigLog.SourceEntryNo := SourceEntryNo;
        TrigLog.Insert();
    end;

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"ALT Manual XmlPortEvent Pub", 'OnAfterManualXmlPortEventPub', '', false, false)]
    local procedure OnManualXmlPortEvent(SourceEntryNo: Integer)
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.Init();
        TrigLog.TriggerName := 'ManualXmlPortEventFired';
        TrigLog.SourceEntryNo := SourceEntryNo;
        TrigLog.Insert();
    end;
}
