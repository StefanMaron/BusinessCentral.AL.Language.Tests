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

codeunit 72885 "LT CallDepth Direct"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Depth_PlainProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Worker: Codeunit "LT CallDepth Worker";
    begin
        Worker.Reset();
        asserterror Worker.Direct();
        Observer.ObserveError('direct');
        Observer.Observe('directDepth', Format(Worker.GetCounter()));
        Observer.Expect('direct|text', 'There is insufficient memory to execute this function. This can be caused by recursive function calls. Contact your system administrator.');
        Observer.Expect('direct|code', 'StackOverflow');
        Observer.Expect('directDepth', '998');
        Observer.Verify();
    end;

    [Test]
    procedure Depth_ThroughAnEvent()
    var
        Observer: Codeunit "Probe Observer";
        Worker: Codeunit "LT CallDepth Worker";
    begin
        Worker.Reset();
        asserterror Worker.ViaEvent();
        Observer.ObserveError('viaEvent');
        Observer.Observe('viaEventDepth', Format(Worker.GetCounter()));
        Observer.Expect('viaEvent|text', 'Excessive recursion has been detected in event subscriber function HandleDeeper for event None that is raised in CodeUnit 72884.');
        Observer.Expect('viaEvent|code', 'RecursiveEventCall:StackOverflow');
        Observer.Expect('viaEventDepth', '333');
        Observer.Verify();
    end;
}
