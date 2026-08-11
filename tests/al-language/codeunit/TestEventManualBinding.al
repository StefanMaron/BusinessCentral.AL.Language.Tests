// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-bindsubscription-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Event Publisher (60014), ALT Event Subscriber (60015), ALT Manual Event Sub (60033)
// BC versions: 27.5+
//
// Contract tests for EventSubscriberInstance = Manual: a manual subscriber codeunit
// receives events ONLY while an instance is bound via BindSubscription, the event is
// dispatched to the BOUND INSTANCE (its instance state is visible to the binder), and
// UnbindSubscription stops delivery. All assertions verified against a real BC 28.3
// service tier before submission.

codeunit 60240 "Test Event Manual Binding"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Contract 1: Unbound Manual Subscriber Never Fires ──────────────────────────────

    [Test]
    procedure ManualSubscriber_NotBound_DoesNotFire()
    var
        Publisher: Codeunit "ALT Event Publisher";
        ManualSub: Codeunit "ALT Manual Event Sub";
        Handled: Boolean;
    begin
        Initialize();
        Handled := Publisher.TriggerBeforeAndReturnHandled(1);
        Assert.IsFalse(Handled, 'Unbound manual subscriber must not receive the event: Handled must stay false');
        Assert.AreEqual(0, ManualSub.GetFireCount(), 'Unbound manual subscriber instance must never have fired');
    end;

    // ── Contract 2: Bound Instance Receives The Event, With Instance State ─────────────

    [Test]
    procedure ManualSubscriber_Bound_FiresOnBoundInstance()
    var
        Publisher: Codeunit "ALT Event Publisher";
        ManualSub: Codeunit "ALT Manual Event Sub";
        Handled: Boolean;
    begin
        Initialize();
        Assert.IsTrue(BindSubscription(ManualSub), 'BindSubscription on an unbound manual subscriber must return true');
        Handled := Publisher.TriggerBeforeAndReturnHandled(2);
        Assert.IsTrue(Handled, 'Bound manual subscriber must receive the event and set Handled');
        Assert.AreEqual(1, ManualSub.GetFireCount(), 'The bound instance itself must have received exactly one fire');
        Assert.AreEqual(2, ManualSub.GetLastEntryNo(), 'The bound instance must have seen the published EntryNo');
        UnbindSubscription(ManualSub);
    end;

    // ── Contract 3: Unbind Stops Delivery, Instance State Freezes ──────────────────────

    [Test]
    procedure ManualSubscriber_Unbind_StopsFiring()
    var
        Publisher: Codeunit "ALT Event Publisher";
        ManualSub: Codeunit "ALT Manual Event Sub";
        Handled: Boolean;
    begin
        Initialize();
        BindSubscription(ManualSub);
        Publisher.TriggerBeforeAndReturnHandled(3);
        Assert.IsTrue(UnbindSubscription(ManualSub), 'UnbindSubscription on a bound instance must return true');
        Handled := Publisher.TriggerBeforeAndReturnHandled(4);
        Assert.IsFalse(Handled, 'After unbind the manual subscriber must no longer receive events');
        Assert.AreEqual(1, ManualSub.GetFireCount(), 'Fire count must stay at 1 after unbind');
        Assert.AreEqual(3, ManualSub.GetLastEntryNo(), 'Last seen EntryNo must still be the pre-unbind value');
    end;

    // ── Contract 4: Binding The Same Instance Twice Returns False ──────────────────────

    [Test]
    procedure BindSubscription_AlreadyBoundInstance_ReturnsFalse()
    var
        ManualSub: Codeunit "ALT Manual Event Sub";
        SecondBind: Boolean;
    begin
        Initialize();
        BindSubscription(ManualSub);
        SecondBind := BindSubscription(ManualSub);
        Assert.AreEqual(false, SecondBind, 'Second BindSubscription on the same already-bound instance must return false, not raise an error');
        UnbindSubscription(ManualSub);
    end;

    // ── Contract 5: BindSubscription On A Static Subscriber Returns False ──────────────

    [Test]
    procedure BindSubscription_StaticSubscriber_ReturnsFalse()
    var
        StaticSub: Codeunit "ALT Event Subscriber";
        BindResult: Boolean;
    begin
        Initialize();
        BindResult := BindSubscription(StaticSub);
        Assert.AreEqual(false, BindResult, 'BindSubscription on a codeunit without EventSubscriberInstance = Manual must return false, not raise an error');
    end;

    // ── Contract 6: UnbindSubscription On A Never-Bound Manual Instance Returns True ───

    [Test]
    procedure UnbindSubscription_NeverBoundManualInstance_ReturnsTrue()
    var
        ManualSub: Codeunit "ALT Manual Event Sub";
        UnbindResult: Boolean;
    begin
        Initialize();
        UnbindResult := UnbindSubscription(ManualSub);
        Assert.AreEqual(true, UnbindResult, 'UnbindSubscription on a never-bound MANUAL instance returns true (container-verified BC behavior)');
    end;

    // ── Contract 7: Each Bound Instance Of The Same Codeunit Fires Once ────────────────

    [Test]
    procedure ManualSubscriber_TwoBoundInstances_EachFiresOnce()
    var
        Publisher: Codeunit "ALT Event Publisher";
        ManualSub1: Codeunit "ALT Manual Event Sub";
        ManualSub2: Codeunit "ALT Manual Event Sub";
    begin
        Initialize();
        Assert.IsTrue(BindSubscription(ManualSub1), 'Bind of first instance must succeed');
        Assert.IsTrue(BindSubscription(ManualSub2), 'Bind of second instance must succeed');
        Publisher.TriggerBeforeAndReturnHandled(5);
        Assert.AreEqual(1, ManualSub1.GetFireCount(), 'First bound instance must fire exactly once');
        Assert.AreEqual(1, ManualSub2.GetFireCount(), 'Second bound instance must fire exactly once');
        UnbindSubscription(ManualSub1);
        UnbindSubscription(ManualSub2);
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
