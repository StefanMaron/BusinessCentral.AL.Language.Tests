// Subscribes to "ALT Subscribed Table" (60593) only. Its twin "ALT No Subscriber Table"
// (60590) deliberately has no subscriber at all -- see "Test No Subscriber Events" (60592).
codeunit 60591 "ALT Subscribed Table Sub"
{
    [EventSubscriber(ObjectType::Table, Database::"ALT Subscribed Table", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertSubscribed(var Rec: Record "ALT Subscribed Table"; RunTrigger: Boolean)
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.Init();
        TrigLog.TriggerName := 'SubscribedInsert';
        TrigLog.SourceEntryNo := Rec."Entry No.";
        TrigLog.NewIntegerValue := Rec.Value;
        TrigLog.Insert();
    end;
}
