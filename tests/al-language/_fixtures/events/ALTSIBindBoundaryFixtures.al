codeunit 67690 "ALT SI Bind Publisher"
{
    // Publisher used only by the SingleInstance binding-boundary pair (67693/67694), so a
    // binding either of them leaves open cannot reach any other test.

    [IntegrationEvent(false, false)]
    procedure OnProbe(var SingleInstanceHit: Boolean; var PlainHit: Boolean; var HeldHit: Boolean)
    begin
    end;

    procedure Raise(var SingleInstanceHit: Boolean; var PlainHit: Boolean; var HeldHit: Boolean)
    begin
        SingleInstanceHit := false;
        PlainHit := false;
        HeldHit := false;
        OnProbe(SingleInstanceHit, PlainHit, HeldHit);
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
    local procedure OnProbeSingleInstance(var SingleInstanceHit: Boolean; var PlainHit: Boolean; var HeldHit: Boolean)
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
    local procedure OnProbePlain(var SingleInstanceHit: Boolean; var PlainHit: Boolean; var HeldHit: Boolean)
    begin
        PlainHit := true;
    end;
}

codeunit 67695 "ALT SI Held Binder"
{
    // SingleInstance codeunit that binds an ORDINARY manual subscriber held in its own global,
    // the shape of Base Application's "API - Upd. Ref. Fields Binder" (5153), which binds 5152
    // once at login. The subscriber instance is referenced by this codeunit, not by any test.
    // Declared by 67693 only (check-singleinstance-fixture-owners.py).
    SingleInstance = true;

    var
        HeldSub: Codeunit "ALT SI Held Subscriber";

    procedure BindHeld(): Boolean
    begin
        exit(BindSubscription(HeldSub));
    end;
}

codeunit 67696 "ALT SI Held Subscriber"
{
    // Ordinary manual-binding subscriber, bound only through 67695's global.
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ALT SI Bind Publisher", 'OnProbe', '', false, false)]
    local procedure OnProbeHeld(var SingleInstanceHit: Boolean; var PlainHit: Boolean; var HeldHit: Boolean)
    begin
        HeldHit := true;
    end;
}
