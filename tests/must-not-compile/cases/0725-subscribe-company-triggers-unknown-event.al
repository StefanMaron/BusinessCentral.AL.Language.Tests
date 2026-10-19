// @expect AL0280 | The event 'OnCompanyOpened' is not found in the target 'Codeunit System.Environment."Company Triggers"'
// A subscriber names an event that Company Triggers does not declare (OnCompanyOpened).
codeunit 50000 "MNC Sub"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpened', '', false, false)]
    local procedure OnOpened()
    begin
    end;
}
