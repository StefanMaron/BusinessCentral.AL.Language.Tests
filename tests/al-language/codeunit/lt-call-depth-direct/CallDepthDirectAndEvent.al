// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-types
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own codeunits 72884 and 72885
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the depth reached by unbounded recursion through a plain procedure and through a publisher/subscriber pair, the error text and code at the ceiling
// BC versions: 29 (27 and 28 by CI)

codeunit 72884 "LT CallDepth Worker"
{
    SingleInstance = true;

    var
        Counter: Integer;

    procedure Reset()
    begin
        Counter := 0;
    end;

    procedure GetCounter(): Integer
    begin
        exit(Counter);
    end;

    procedure Direct()
    begin
        Counter += 1;
        Direct();
    end;

    procedure ViaEvent()
    begin
        Counter += 1;
        OnDeeper();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeeper()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT CallDepth Worker", 'OnDeeper', '', false, false)]
    local procedure HandleDeeper()
    begin
        ViaEvent();
    end;
}

