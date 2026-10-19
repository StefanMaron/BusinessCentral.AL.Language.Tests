codeunit 67372 "ALT SI Manual Event Sub"
{
    // SingleInstance + manual-binding subscriber: every variable of this codeunit resolves to the
    // one per-company instance, so a binding made through a callee's local outlives the callee.
    // Used only by codeunit 67370, which unbinds it before asserting.
    SingleInstance = true;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ALT Event Publisher", 'OnBeforeAction', '', false, false)]
    local procedure OnBeforeActionSingleInstanceHandler(EntryNo: Integer; var Handled: Boolean)
    begin
        Handled := true;
    end;
}
