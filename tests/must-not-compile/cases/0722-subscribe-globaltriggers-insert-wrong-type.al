// @expect AL0284 | The type of the parameter 'RecRef' on the event subscriber 'Ins' does not match the expected type 'RecordRef'.
// A subscriber to Global Triggers.OnGlobalInsert declares its parameter as Integer instead of RecordRef.
codeunit 50000 "MNC Sub"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalInsert', '', false, false)]
    local procedure Ins(RecRef: Integer)
    begin
    end;
}
