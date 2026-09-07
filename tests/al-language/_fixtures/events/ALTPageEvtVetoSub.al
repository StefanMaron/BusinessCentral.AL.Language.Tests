codeunit 60635 "ALT Page Evt Veto Sub"
{
    // The NEGATIVE half: a manually bound subscriber that answers the event's AllowModify /
    // AllowInsert var parameter with false. Manual so it is inert for every other test in the
    // suite; only the veto tests bind it.
    SingleInstance = true;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Page, Page::"ALT Page Evt Rows", 'OnModifyRecordEvent', '', false, false)]
    local procedure VetoModify(var Rec: Record "ALT Page Evt Row"; var xRec: Record "ALT Page Evt Row"; var AllowModify: Boolean)
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        AllowModify := false;
        TrigLog.Init();
        TrigLog.TriggerName := 'VetoPageModifyEvt';
        TrigLog.OldValue := xRec."Value";
        TrigLog.NewValue := Rec."Value";
        TrigLog.Insert(true);
    end;

    [EventSubscriber(ObjectType::Page, Page::"ALT Page Evt Rows", 'OnInsertRecordEvent', '', false, false)]
    local procedure VetoInsert(var Rec: Record "ALT Page Evt Row"; BelowxRec: Boolean; var xRec: Record "ALT Page Evt Row"; var AllowInsert: Boolean)
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        AllowInsert := false;
        TrigLog.Init();
        TrigLog.TriggerName := 'VetoPageInsertEvt';
        TrigLog.NewValue := Rec."Value";
        TrigLog.Insert(true);
    end;
}
