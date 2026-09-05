// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
//   dev-itpro/developer/devenv-table-triggers (OnBeforeInsertEvent)
// Scope: in-scope
// Fixtures used: none — the publisher is System Application table
//   "Retention Policy Setup" (3901) and the subscriber is Microsoft's own
//   "Retention Policy Setup" codeunit, which subscribes to that table's
//   OnBeforeInsertEvent and refuses a table that is not on the retention-policy
//   allowed list.
// Note: the TABLE-event counterpart of TestCodeunitAsyncSubscriberError.al. An
//   [EventSubscriber] declared in an already-compiled app is emitted by BC as an
//   async state machine, so an Error() it raises surfaces on the returned task
//   rather than propagating out of the invocation. A platform that discards that
//   task lets the refused Insert go through and reports nothing — the write the
//   subscriber existed to refuse happens anyway.
// BC versions: 24+

codeunit 60490 "Test Tbl Evt Async Sub Error"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TableEventSubscriberInAnotherApp_ErrorReachesTheCaller()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
    begin
        // [GIVEN] A Retention Policy Setup naming a table that is not on the
        // retention-policy allowed list. Table 60007 "ALT Base" belongs to this
        // test app and is never added to that list, on any BC version.
        RetentionPolicySetup."Table Id" := Database::"ALT Base";

        // [WHEN] It is inserted, firing the OnBeforeInsertEvent subscriber that
        // lives in the System Application.
        asserterror RetentionPolicySetup.Insert(true);

        // [THEN] That subscriber's error reaches this caller.
        Assert.ExpectedError('is not in the list of allowed tables');

        // [THEN] And the row was refused, not written.
        Assert.IsFalse(
            RetentionPolicySetup.Get(Database::"ALT Base"),
            'The refused Retention Policy Setup row must not have been inserted.');
    end;

    [Test]
    procedure TableEventSubscriberInAnotherApp_TemporaryInsertIsNotRefused()
    var
        TempRetentionPolicySetup: Record "Retention Policy Setup" temporary;
    begin
        // Positive control. The same subscriber returns early for a temporary
        // record, so the identical Insert must SUCCEED — without this, a platform
        // that made every table-event dispatch throw would pass the test above.
        TempRetentionPolicySetup."Table Id" := Database::"ALT Base";
        TempRetentionPolicySetup.Insert(true);

        Assert.AreEqual(
            1, TempRetentionPolicySetup.Count(),
            'A temporary Retention Policy Setup row must insert; the subscriber exempts temporary records.');
        Assert.IsTrue(
            TempRetentionPolicySetup.Get(Database::"ALT Base"),
            'The temporary row must be readable back by its primary key.');
    end;
}
