// @expect AL0161 | 'GetRoleCenterBannerPartID' is inaccessible due to its protection level
// An app subscribes to GetRoleCenterBannerPartID of the platform codeunit "System Action Triggers"; the event is declared an InternalEvent.
codeunit 50000 "MNC Banner Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetRoleCenterBannerPartID', '', false, false)]
    local procedure GetRoleCenterBannerPartID(var PartID: Integer)
    begin
        PartID := 1;
    end;
}
