// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-bindsubscription-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Universal (60000), ALT Trigger Log (60003), ALT Manual Table Event Sub (60034),
//   ALT Table Event Subscriber (60016)
// BC versions: 27.5+
//
// Contract tests for EventSubscriberInstance = Manual on a TABLE-event subscriber.
// The codeunit-event half of the same contract is pinned in "Test Event Manual Binding"
// (60240); this file mirrors those contracts onto a table trigger event
// (ALT Universal OnAfterInsertEvent), which BC dispatches through a different mechanism
// (the table's NavEventScope) than a codeunit event publisher.
//
// The claim under test: a Manual subscriber to a table event fires ONLY while an instance
// is bound via BindSubscription, the event is dispatched to the BOUND INSTANCE (its
// instance state is visible to the binder), and UnbindSubscription stops delivery.

codeunit 60241 "Test Table Event Manual Bind"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Contract 1: Unbound Manual Table Subscriber Never Fires ────────────────────────

    [Test]
    procedure ManualTableSub_NotBound_DoesNotFire()
    var
        Universal: Record "ALT Universal";
        TrigLog: Record "ALT Trigger Log";
        ManualSub: Codeunit "ALT Manual Table Event Sub";
    begin
        Initialize();

        InsertUniversal(Universal, 1, 100);

        TrigLog.SetRange(TriggerName, 'ManualTableAfterInsert');
        Assert.AreEqual(0, TrigLog.Count(), 'An unbound manual table-event subscriber must not fire at all');
        Assert.AreEqual(0, ManualSub.GetFireCount(), 'Unbound manual table-event subscriber instance must never have fired');
    end;

    // ── Contract 2: Bound Instance Receives The Table Event, With Instance State ───────

    [Test]
    procedure ManualTableSub_Bound_FiresOnBoundInstance()
    var
        Universal: Record "ALT Universal";
        TrigLog: Record "ALT Trigger Log";
        ManualSub: Codeunit "ALT Manual Table Event Sub";
    begin
        Initialize();

        Assert.IsTrue(BindSubscription(ManualSub), 'BindSubscription on an unbound manual subscriber must return true');
        InsertUniversal(Universal, 2, 200);

        Assert.AreEqual(1, ManualSub.GetFireCount(), 'The bound instance itself must have received exactly one fire');
        Assert.AreEqual(2, ManualSub.GetLastEntryNo(), 'The bound instance must have seen the inserted Entry No.');

        TrigLog.SetRange(TriggerName, 'ManualTableAfterInsert');
        Assert.AreEqual(1, TrigLog.Count(), 'The table event must have been delivered exactly once');
        TrigLog.FindFirst();
        Assert.AreEqual(2, TrigLog.NewEntryNo, 'The subscriber must receive the inserted key');
        Assert.AreEqual(200, TrigLog.NewIntegerValue, 'The subscriber must receive the inserted field values');

        UnbindSubscription(ManualSub);
    end;

    // ── Contract 3: Unbind Stops Delivery, Instance State Freezes ─────────────────────

    [Test]
    procedure ManualTableSub_Unbind_StopsFiring()
    var
        Universal: Record "ALT Universal";
        TrigLog: Record "ALT Trigger Log";
        ManualSub: Codeunit "ALT Manual Table Event Sub";
    begin
        Initialize();

        BindSubscription(ManualSub);
        InsertUniversal(Universal, 3, 300);
        Assert.IsTrue(UnbindSubscription(ManualSub), 'UnbindSubscription on a bound instance must return true');

        InsertUniversal(Universal, 4, 400);

        Assert.AreEqual(1, ManualSub.GetFireCount(), 'Fire count must stay at 1 after unbind');
        Assert.AreEqual(3, ManualSub.GetLastEntryNo(), 'Last seen Entry No. must still be the pre-unbind value');

        TrigLog.SetRange(TriggerName, 'ManualTableAfterInsert');
        Assert.AreEqual(1, TrigLog.Count(), 'After unbind the manual table-event subscriber must no longer receive events');
    end;

    // ── Contract 4: Binding The Same Instance Twice Returns False ─────────────────────

    [Test]
    procedure BindSubscription_AlreadyBoundTableSub_ReturnsFalse()
    var
        ManualSub: Codeunit "ALT Manual Table Event Sub";
        SecondBind: Boolean;
    begin
        Initialize();

        BindSubscription(ManualSub);
        SecondBind := BindSubscription(ManualSub);
        Assert.AreEqual(false, SecondBind, 'Second BindSubscription on the same already-bound instance must return false, not raise an error');

        UnbindSubscription(ManualSub);
    end;

    // ── Contract 5: BindSubscription On A Static Table Subscriber Returns False ───────

    [Test]
    procedure BindSubscription_StaticTableSubscriber_ReturnsFalse()
    var
        StaticSub: Codeunit "ALT Table Event Subscriber";
        BindResult: Boolean;
    begin
        Initialize();

        BindResult := BindSubscription(StaticSub);
        Assert.AreEqual(false, BindResult, 'BindSubscription on a table-event subscriber without EventSubscriberInstance = Manual must return false, not raise an error');
    end;

    // ── Contract 6: UnbindSubscription On A Never-Bound Manual Instance Returns True ──

    [Test]
    procedure UnbindSubscription_NeverBoundTableSub_ReturnsTrue()
    var
        ManualSub: Codeunit "ALT Manual Table Event Sub";
        UnbindResult: Boolean;
    begin
        Initialize();

        UnbindResult := UnbindSubscription(ManualSub);
        Assert.AreEqual(true, UnbindResult, 'UnbindSubscription on a never-bound MANUAL instance returns true (container-verified BC behavior)');
    end;

    // ── Contract 7: Each Bound Instance Of The Same Codeunit Fires Once ───────────────

    [Test]
    procedure ManualTableSub_TwoBoundInstances_EachFiresOnce()
    var
        Universal: Record "ALT Universal";
        TrigLog: Record "ALT Trigger Log";
        ManualSub1: Codeunit "ALT Manual Table Event Sub";
        ManualSub2: Codeunit "ALT Manual Table Event Sub";
    begin
        Initialize();

        Assert.IsTrue(BindSubscription(ManualSub1), 'Bind of first instance must succeed');
        Assert.IsTrue(BindSubscription(ManualSub2), 'Bind of second instance must succeed');

        InsertUniversal(Universal, 5, 500);

        Assert.AreEqual(1, ManualSub1.GetFireCount(), 'First bound instance must fire exactly once');
        Assert.AreEqual(5, ManualSub1.GetLastEntryNo(), 'First bound instance must have seen the inserted Entry No.');
        Assert.AreEqual(1, ManualSub2.GetFireCount(), 'Second bound instance must fire exactly once');
        Assert.AreEqual(5, ManualSub2.GetLastEntryNo(), 'Second bound instance must have seen the inserted Entry No.');

        TrigLog.SetRange(TriggerName, 'ManualTableAfterInsert');
        Assert.AreEqual(2, TrigLog.Count(), 'One delivery per bound instance');

        UnbindSubscription(ManualSub1);
        UnbindSubscription(ManualSub2);
    end;

    local procedure InsertUniversal(var Universal: Record "ALT Universal"; EntryNo: Integer; IntegerValue: Integer)
    begin
        Universal.Init();
        Universal."Entry No." := EntryNo;
        Universal."Integer Field" := IntegerValue;
        Universal.Insert(true);
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
