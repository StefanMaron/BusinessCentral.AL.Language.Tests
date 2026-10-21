// @expect AL0501 | Eventsubscribers in test codeunits must use manual binding. Set the property EventSubscriberInstance to Manual.
// EventSubscriberInstance = StaticAutomatic written out on a test codeunit is rejected like the default (case 1960) (writer QI).
codeunit 51962 "MNC QI Publisher 1961"
{
    [IntegrationEvent(false, false)]
    procedure OnPing()
    begin
    end;
}

codeunit 51963 "MNC QI Test 1961"
{
    Subtype = Test;
    EventSubscriberInstance = StaticAutomatic;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MNC QI Publisher 1961", 'OnPing', '', false, false)]
    local procedure HandlePing()
    begin
    end;

    [Test]
    procedure T()
    begin
    end;
}
