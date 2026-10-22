// @expect AL0280 | The event 'NoSuchEvent' is not found in the target 'Codeunit "MNC Pub"'
// An event subscriber for an event the publisher does not have.
codeunit 50000 "MNC Pub"
{
}

codeunit 50001 "MNC Sub"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MNC Pub", 'NoSuchEvent', '', false, false)]
    local procedure H()
    begin
    end;
}
