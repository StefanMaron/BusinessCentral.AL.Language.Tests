// Fixtures for "LT CK Event Leads" (84712), corpus issue 669 item 4: SkipOnMissingPermission on a subscriber codeunit the
// effective permission sets do not grant Execute on. The set grants the publisher, the log and the test codeunit, not the subscribers.

permissionset 84709 "LT CK Ev Perm"
{
    Assignable = true;
    Permissions =
        tabledata "LT CK Ev Row" = RIMD,
        codeunit "LT CK Ev Pub" = X,
        codeunit "LT CK Ev Log" = X,
        codeunit "LT CK Event Leads" = X;
}

codeunit 84710 "LT CK Ev Perm Sub Strict"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT CK Ev Pub", 'OnPerm', '', false, false)]
    local procedure OnPerm(var X: Integer)
    begin
        X := X + 10;
    end;
}

codeunit 84711 "LT CK Ev Perm Sub Skip"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT CK Ev Pub", 'OnPerm', '', true, true)]
    local procedure OnPerm(var X: Integer)
    begin
        X := X + 100;
    end;
}
