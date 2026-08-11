// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-publisher-subscriber
// Scope: in-scope
// Fixtures used: ALT Manual TableEvent Pub (60976), ALT ManualTableEvt Ctrl Sub (60949),
//                 ALT Trigger Log (60003)
//
// Differential coverage for a manually-declared [IntegrationEvent] published from INSIDE a
// table object's own trigger code (as opposed to the implicit trigger events BC synthesizes
// for every table, and an [IntegrationEvent] published from a codeunit). All three publisher
// kinds fire on this table's Delete() call (implicit + manual) or independently (codeunit),
// and all three must reach their respective subscriber.

codeunit 60950 "Test Manual TableEvent"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure TableEvent_ManualIntegrationEvent_Subscriber_Fires()
    var
        Pub: Record "ALT Manual TableEvent Pub";
        TrigLog: Record "ALT Trigger Log";
    begin
        // [GIVEN] a row of the manual-event publisher table
        Initialize();
        Pub."Entry No." := 1;
        Pub.Insert(false);

        // [WHEN] the row is deleted, running OnDelete which raises the manual [IntegrationEvent]
        Pub.Get(1);
        Pub.Delete(true);

        // [THEN] the OnDelete trigger body itself ran, reaching the raise statement
        TrigLog.SetRange(TriggerName, 'ManualTblPubOnDeleteRan');
        TrigLog.SetRange(SourceEntryNo, 1);
        Assert.IsTrue(TrigLog.FindFirst(), 'control: the OnDelete trigger body did not run');

        // [THEN] the subscriber to the manually-declared table-published IntegrationEvent fired
        TrigLog.SetRange(TriggerName, 'ManualIntegrationEventFired');
        TrigLog.SetRange(SourceEntryNo, 1);
        Assert.IsTrue(TrigLog.FindFirst(), 'manually-declared table-published IntegrationEvent subscriber must fire');
    end;

    [Test]
    procedure TableEvent_OnAfterDeleteEvent_Subscriber_Fires_Control()
    var
        Pub: Record "ALT Manual TableEvent Pub";
        TrigLog: Record "ALT Trigger Log";
    begin
        // [GIVEN] a row of the same table
        Initialize();
        Pub."Entry No." := 2;
        Pub.Insert(false);

        // [WHEN] the row is deleted
        Pub.Get(2);
        Pub.Delete(true);

        // [THEN] the subscriber to the IMPLICIT OnAfterDeleteEvent fired (control case)
        TrigLog.SetRange(TriggerName, 'ImplicitDeleteEventFired');
        TrigLog.SetRange(SourceEntryNo, 2);
        Assert.IsTrue(TrigLog.FindFirst(), 'implicit OnAfterDeleteEvent subscriber must fire');
    end;

    [Test]
    procedure CodeunitEvent_ManualIntegrationEvent_Subscriber_Fires_Control()
    var
        CtrlSub: Codeunit "ALT ManualTableEvt Ctrl Sub";
        TrigLog: Record "ALT Trigger Log";
    begin
        // [GIVEN] nothing table-related — this publisher is a codeunit
        Initialize();

        // [WHEN] the codeunit raises its manually-declared [IntegrationEvent]
        CtrlSub.RaiseControlCodeunitEvent(3);

        // [THEN] the subscriber to the codeunit-published IntegrationEvent fired (control case)
        TrigLog.SetRange(TriggerName, 'CodeunitEventFired');
        TrigLog.SetRange(SourceEntryNo, 3);
        Assert.IsTrue(TrigLog.FindFirst(), 'codeunit-published IntegrationEvent subscriber must fire');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
