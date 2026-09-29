codeunit 67690 "ALT SI Bind Publisher"
{
    // Publisher used only by the SingleInstance binding-boundary pair (67693/67694), so a
    // binding either of them leaves open cannot reach any other test.

    [IntegrationEvent(false, false)]
    procedure OnProbe(var SingleInstanceHit: Boolean; var PlainHit: Boolean)
    begin
    end;

    procedure Raise(var SingleInstanceHit: Boolean; var PlainHit: Boolean)
    begin
        SingleInstanceHit := false;
        PlainHit := false;
        OnProbe(SingleInstanceHit, PlainHit);
    end;
}

codeunit 67691 "ALT SI Bind Survivor"
{
    // SingleInstance + manual binding. The company scope holds the one instance
    // (NavCompany.SingleInstanceCodeunits), so no AL variable going out of scope releases it.
    // Declared by 67693 only (check-singleinstance-fixture-owners.py).
    SingleInstance = true;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ALT SI Bind Publisher", 'OnProbe', '', false, false)]
    local procedure OnProbeSingleInstance(var SingleInstanceHit: Boolean; var PlainHit: Boolean)
    begin
        SingleInstanceHit := true;
    end;
}

codeunit 67692 "ALT Plain Bind Contrast"
{
    // Ordinary manual-binding subscriber: the contrast case. Its instance lives only as long
    // as the variable holding it.
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ALT SI Bind Publisher", 'OnProbe', '', false, false)]
    local procedure OnProbePlain(var SingleInstanceHit: Boolean; var PlainHit: Boolean)
    begin
        PlainHit := true;
    end;
}
