codeunit 60634 "ALT Page Evt Manual Sub"
{
    // MANUALLY bound counterpart of ALT Page Evt Sub (60633): the same page platform trigger
    // event, reached only while a BindSubscription is in force. Proves the page-event path
    // honours manual binding the way the table-event path does
    // (ALTManualTableEventSubscriber.al).
    SingleInstance = true;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Page, Page::"ALT Page Evt Rows", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEvent(var Rec: Record "ALT Page Evt Row"; var xRec: Record "ALT Page Evt Row"; var AllowModify: Boolean)
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.Init();
        TrigLog.TriggerName := 'ManualPageModifyEvt';
        TrigLog.OldValue := xRec."Value";
        TrigLog.NewValue := Rec."Value";
        TrigLog.Insert(true);
    end;
}
