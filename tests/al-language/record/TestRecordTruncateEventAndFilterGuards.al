// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-truncate-method
// Scope: in-scope
// Fixtures used: "ALT Truncate Guard Row" (table 60515), "ALT Truncate Flow Row" (table 60516),
//                "ALT Truncate Delete Sub" (codeunit 60517), "ALT Universal" (table 60000)
// BC versions: 24+

/// <summary>
/// Record.Truncate() is refused when the table has an OnBeforeDelete/OnAfterDelete
/// subscriber, and when a filter is set on a FlowField.
///
/// BC's NavRecord.ValidateTruncateSupport runs seven guards in order. Two of them are
/// measured here:
///
///   * NCLMetaTable.IsEventSubscribed(OnBeforeDeleteEvent | OnAfterDeleteEvent, appGroup)
///     raises Lang.TruncateWithEvent.
///   * FlowFieldsHelper.AnyFiltersOnFlowFields(...) raises Lang.TruncateFilterOnFlowField.
///
/// The ORDER is load-bearing and is why each test below has its own fixture: guards fire in
/// sequence and BC reports only the FIRST that holds, so a table that tripped an earlier
/// guard would make a later guard's test pass without that guard ever running. Every
/// assertion is on the MESSAGE rather than on the bare fact that something threw, for the
/// same reason.
///
/// Each refusal is paired with a negative control that differs in exactly one thing — no
/// subscriber, or no filter on the FlowField — because a tier or runner that refused
/// Truncate() unconditionally would otherwise pass the positive arms.
///
/// Deliberately NOT asserted after a refusal: that the seeded row survives. `asserterror`
/// unwinds the write transaction the test method opened, so the seeding Insert is rolled back
/// too and Count() reads 0 — measured on all eight cloud legs, which reported
/// `Expected:<1> Actual:<0>` while the message assertions above them passed. That count
/// measures BC's test-isolation rollback, not the guard, and an arm asserting it would fail
/// for a reason that has nothing to do with Truncate().
/// </summary>
codeunit 60518 "Test Record Truncate Guards"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        TruncateWithEventErr: Label 'Truncate is not supported when the OnBeforeDelete and/or OnAfterDelete event is subscribed. Please remove the events subscriptions or use DeleteAll.', Locked = true;
        TruncateFlowFilterErr: Label 'Truncate does not support filters on FlowFields.', Locked = true;

    [Test]
    procedure Truncate_TableWithDeleteEventSubscriber_IsRefused()
    // CLAIM: a table carrying an OnBeforeDeleteEvent subscription cannot be truncated, and
    // the refusal names the event subscription. "ALT Truncate Delete Sub" (codeunit 60517)
    // subscribes to this table's OnBeforeDeleteEvent and does nothing else; the table has no
    // FlowField and no Media field, so no other guard can produce this message.
    var
        GuardRow: Record "ALT Truncate Guard Row";
    begin
        Initialize();
        SeedGuardRow();

        ClearLastError();

        asserterror GuardRow.Truncate();

        Assert.AreEqual(
            TruncateWithEventErr,
            GetLastErrorText(),
            'Truncate() on a table with an OnBeforeDeleteEvent subscriber must raise the event refusal');
    end;

    [Test]
    procedure Truncate_TableWithoutDeleteEventSubscriber_Succeeds()
    // CLAIM: the negative control for the test above. "ALT Universal" has no
    // OnBeforeDelete/OnAfterDelete subscriber anywhere in this corpus, and is otherwise the
    // same kind of table — normal, non-temporary, no Media field, no FlowField. Without this
    // arm, an implementation that refused every Truncate() would pass the positive test.
    var
        Universal: Record "ALT Universal";
    begin
        Initialize();

        Universal."Entry No." := 1;
        Universal."Integer Field" := 10;
        Universal.Insert();

        ClearLastError();

        Universal.Truncate();

        Assert.AreEqual('', GetLastErrorText(), 'Truncate() on an unsubscribed table must not raise');
        Assert.IsTrue(Universal.IsEmpty(), 'Truncate() on an unsubscribed table must empty it');
    end;

    [Test]
    procedure Truncate_WithFilterOnAFlowField_IsRefused()
    // CLAIM: a filter set on a FlowField makes Truncate() raise the FlowField refusal.
    // "ALT Truncate Flow Row"."Total Amount" is a FlowField; the table has no delete
    // subscriber, so the earlier event guard cannot fire and mask this one.
    var
        FlowRow: Record "ALT Truncate Flow Row";
    begin
        Initialize();
        SeedFlowRow();

        ClearLastError();

        FlowRow.SetRange("Total Amount", 0, 100);
        asserterror FlowRow.Truncate();

        Assert.AreEqual(
            TruncateFlowFilterErr,
            GetLastErrorText(),
            'Truncate() with a filter on a FlowField must raise the FlowField refusal');
    end;

    [Test]
    procedure Truncate_WithFilterOnANormalField_Succeeds()
    // CLAIM: the negative control for the test above, and the sharper of the two — it holds
    // the SAME table and a filter of the same shape fixed, varying only WHICH field carries
    // it. A guard keyed on "any filter at all" rather than on a filter over a FlowField
    // would refuse here too, and this is the only arm that separates those two readings.
    var
        FlowRow: Record "ALT Truncate Flow Row";
    begin
        Initialize();
        SeedFlowRow();

        ClearLastError();

        FlowRow.SetRange("Link Code", 'LINK-1');
        FlowRow.Truncate();

        Assert.AreEqual('', GetLastErrorText(), 'Truncate() filtered on a normal field must not raise');

        FlowRow.Reset();
        Assert.IsTrue(FlowRow.IsEmpty(), 'Truncate() filtered on a normal field must empty the table');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    local procedure SeedGuardRow()
    var
        GuardRow: Record "ALT Truncate Guard Row";
    begin
        GuardRow."Entry No." := 1;
        GuardRow."Amount Field" := 25;
        GuardRow.Insert();
    end;

    local procedure SeedFlowRow()
    var
        FlowRow: Record "ALT Truncate Flow Row";
    begin
        FlowRow."Entry No." := 1;
        FlowRow."Link Code" := 'LINK-1';
        FlowRow.Insert();
    end;
}
