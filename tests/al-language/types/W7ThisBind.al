// Batch 7 probes: BindSubscription(this) in a manual subscriber codeunit, and this passed by reference. Observe only.
codeunit 68562 "W7 This Publisher"
{
    procedure Raise(): Integer
    var
        Count: Integer;
    begin
        OnPing(Count);
        exit(Count);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPing(var Count: Integer)
    begin
    end;
}

codeunit 68563 "W7 This Subscriber"
{
    EventSubscriberInstance = Manual;

    var
        HitCount: Integer;
        TouchCount: Integer;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"W7 This Publisher", 'OnPing', '', false, false)]
    local procedure HandlePing(var Count: Integer)
    begin
        Count += 1;
        HitCount += 1;
    end;

    procedure BindSelf()
    begin
        BindSubscription(this);
    end;

    procedure UnbindSelf()
    begin
        UnbindSubscription(this);
    end;

    procedure PassSelfByValue(var Helper: Codeunit "W7 This Helper")
    begin
        Helper.TouchByValue(this);
    end;

    procedure Touch()
    begin
        TouchCount += 1;
    end;

    procedure Hits(): Integer
    begin
        exit(HitCount);
    end;

    procedure Touches(): Integer
    begin
        exit(TouchCount);
    end;
}

codeunit 68564 "W7 This Helper"
{
    procedure TouchByValue(Target: Codeunit "W7 This Subscriber")
    begin
        Target.Touch();
    end;
}

codeunit 68565 "W7 This Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure BindSubscription_OfThis_ThenRaise()
    var
        Observer: Codeunit "Probe Observer";
        Publisher: Codeunit "W7 This Publisher";
        Subscriber: Codeunit "W7 This Subscriber";
    begin
        Observer.Observe('raise before bind', Format(Publisher.Raise()));
        Subscriber.BindSelf();
        Observer.Observe('raise after BindSelf', Format(Publisher.Raise()));
        Observer.Observe('raise again', Format(Publisher.Raise()));
        Observer.Observe('hits', Format(Subscriber.Hits()));
        Subscriber.UnbindSelf();
        Observer.Observe('raise after UnbindSelf', Format(Publisher.Raise()));
        Observer.Observe('hits after unbind', Format(Subscriber.Hits()));
        Observer.Expect('raise before bind', '0');
        Observer.Expect('raise after BindSelf', '1');
        Observer.Expect('raise again', '1');
        Observer.Expect('hits', '2');
        Observer.Expect('raise after UnbindSelf', '0');
        Observer.Expect('hits after unbind', '2');
        Observer.Verify();
    end;

    [Test]
    procedure This_PassedByValueToAnotherCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "W7 This Helper";
        Subscriber: Codeunit "W7 This Subscriber";
    begin
        Subscriber.PassSelfByValue(Helper);
        Observer.Observe('touches after value parameter', Format(Subscriber.Touches()));
        Observer.Expect('touches after value parameter', '1');
        Observer.Verify();
    end;
}
