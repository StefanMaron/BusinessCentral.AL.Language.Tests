// @expect AL0501 | Eventsubscribers in test codeunits must use manual binding. Set the property EventSubscriberInstance to Manual.
// An event subscriber in a test codeunit (here a SingleInstance one) without EventSubscriberInstance = Manual is rejected at compile:
// the default StaticAutomatic binding is not allowed in a test codeunit (writer QI, probe for al-runtime-rs probes-needed row
// "A test codeunit with SingleInstance = true"). The Manual form compiles: tests/al-language/codeunit/QiSingleInstanceTestCodeunit.al.
codeunit 51960 "MNC QI Publisher 1960"
{
    [IntegrationEvent(false, false)]
    procedure OnPing()
    begin
    end;
}

codeunit 51961 "MNC QI Test 1960"
{
    Subtype = Test;
    SingleInstance = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MNC QI Publisher 1960", 'OnPing', '', false, false)]
    local procedure HandlePing()
    begin
    end;

    [Test]
    procedure T()
    begin
    end;
}
