// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: ALT Event Subscriber (codeunit 60015) subscribing three events on
//                ALT Event Publisher (codeunit 60014); ALT Table Event Subscriber
//                (codeunit 60016) subscribing ten events on ALT Triggered (table 60002);
//                ALT No Subscriber Table (60590), which is deliberately subscriber-free;
//                ALT Event Publisher (60014) as a codeunit that PUBLISHES but never subscribes
// BC versions: 27.0+
//
// Pins the built-in "Event Subscription" (2000000140) system virtual table: one row per active
// event subscription, keyed on (Subscriber Codeunit ID, Subscriber Function), computed from the
// platform's own subscription registry rather than stored in any company's database.
//
// Nothing in this corpus read the table at all before this codeunit, so what BC answers for it
// was unmeasured. It is not an incidental gap: the table is the only AL-visible window onto
// which subscriptions the platform actually registered, and Microsoft's own tooling reads it to
// report what an extension wired up.
//
// EVERY TEST HERE IS DESIGNED TO DISCRIMINATE, not merely to pass. A provider that answered a
// fixed row set, or that ignored its filters, would pass a test that only asserted "some rows
// exist" -- so each claim below is paired with an arm whose expected answer is DIFFERENT:
//
//   * EventSubscription_Filter_SubscriberCodeunit_... asserts codeunit 60015 HAS rows and, in
//     the same test, that ALT Event Publisher (60014) -- which publishes three events and
//     subscribes to none -- has NONE. A table answering every row to every filter fails the
//     second half; one answering nothing fails the first. Publisher and subscriber sit in the
//     same fixture pair, so "it is a codeunit in this app" cannot be what separates them.
//
//   * EventSubscription_Filter_PublisherObject_... asserts the publisher-side filter separates
//     ALT Triggered (60002), which has ten table-event subscribers, from ALT No Subscriber
//     Table (60590), which has none anywhere in the app -- and whose own fixture header says so
//     and asks that it stay that way. Both are tables in this app of similar shape, so only the
//     subscription registry distinguishes them.
//
//   * EventSubscription_Get_ByPrimaryKey_... asserts the declared primary key
//     (Subscriber Codeunit ID, Subscriber Function) actually keys the table, by Get()ing one
//     known subscriber method BY NAME and checking the row describes that method rather than
//     some other row of the same codeunit. Codeunit 60015 has three subscriber functions with
//     three different published functions, so a provider keyed on the codeunit alone -- or one
//     returning its first row -- fails.
//
//   * EventSubscription_Row_DescribesTheSubscription_... reads the non-key columns for one row
//     whose every value is fixed by the fixture's own source: the published function name, the
//     publisher object type and id, and the event type. Asserting the columns rather than just
//     the row's existence is what would catch a provider that finds the right subscription and
//     projects it wrongly.
//
// The Active column is asserted true for a statically-bound subscriber. "Number of Calls" is
// deliberately NOT asserted against a number: it counts invocations since the service tier
// started, so it is a property of the run rather than of the subscription, and pinning it would
// make this codeunit order-dependent.

codeunit 60955 "Test Event Subscription VT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure EventSubscription_Filter_SubscriberCodeunit_SeparatesSubscriberFromPublisher()
    // CLAIM: filtering on "Subscriber Codeunit ID" returns the rows of the codeunit that
    // SUBSCRIBES, and none for a codeunit that only publishes.
    var
        EventSubscription: Record "Event Subscription";
        SubscriberRows: Integer;
        PublisherRows: Integer;
    begin
        EventSubscription.Reset();
        EventSubscription.SetRange("Subscriber Codeunit ID", Codeunit::"ALT Event Subscriber");
        SubscriberRows := EventSubscription.Count();

        EventSubscription.Reset();
        EventSubscription.SetRange("Subscriber Codeunit ID", Codeunit::"ALT Event Publisher");
        PublisherRows := EventSubscription.Count();

        Assert.AreEqual(
            3, SubscriberRows,
            'ALT Event Subscriber declares three [EventSubscriber] methods, so Event Subscription must hold three rows for it.');
        Assert.AreEqual(
            0, PublisherRows,
            'ALT Event Publisher subscribes to nothing, so Event Subscription must hold no rows for it.');
    end;

    [Test]
    procedure EventSubscription_Filter_PublisherObject_SeparatesWatchedTableFromUnwatched()
    // CLAIM: filtering on "Publisher Object ID" returns the subscriptions ON that publisher, and
    // none for a table nothing subscribes to.
    var
        EventSubscription: Record "Event Subscription";
        WatchedRows: Integer;
        UnwatchedRows: Integer;
    begin
        EventSubscription.Reset();
        EventSubscription.SetRange("Publisher Object Type", EventSubscription."Publisher Object Type"::Table);
        EventSubscription.SetRange("Publisher Object ID", Database::"ALT Triggered");
        WatchedRows := EventSubscription.Count();

        EventSubscription.Reset();
        EventSubscription.SetRange("Publisher Object Type", EventSubscription."Publisher Object Type"::Table);
        EventSubscription.SetRange("Publisher Object ID", Database::"ALT No Subscriber Table");
        UnwatchedRows := EventSubscription.Count();

        Assert.IsTrue(
            WatchedRows > 0,
            'ALT Triggered has ten table-event subscribers, so Event Subscription must hold rows naming it as publisher.');
        Assert.AreEqual(
            0, UnwatchedRows,
            'ALT No Subscriber Table has no subscriber anywhere in this app, so Event Subscription must hold no rows naming it as publisher.');
    end;

    [Test]
    procedure EventSubscription_Get_ByPrimaryKey_ReturnsThatSubscriberFunctionsRow()
    // CLAIM: (Subscriber Codeunit ID, Subscriber Function) is the primary key, so Get() with a
    // named function returns THAT function's row rather than another row of the same codeunit.
    var
        EventSubscription: Record "Event Subscription";
    begin
        Assert.IsTrue(
            EventSubscription.Get(Codeunit::"ALT Event Subscriber", 'OnAfterActionHandler'),
            'Event Subscription has no row for ALT Event Subscriber.OnAfterActionHandler.');

        Assert.AreEqual(
            'OnAfterActionHandler', EventSubscription."Subscriber Function",
            'The row fetched by primary key must report the function that was asked for.');
        Assert.AreEqual(
            'OnAfterAction', EventSubscription."Published Function",
            'OnAfterActionHandler subscribes to ALT Event Publisher.OnAfterAction.');

        Assert.IsTrue(
            EventSubscription.Get(Codeunit::"ALT Event Subscriber", 'OnInternalStepHandler'),
            'Event Subscription has no row for ALT Event Subscriber.OnInternalStepHandler.');
        Assert.AreEqual(
            'OnInternalStep', EventSubscription."Published Function",
            'The second key value must select a DIFFERENT row of the same codeunit, not the first one again.');
    end;

    [Test]
    procedure EventSubscription_Get_UnknownSubscriberFunction_ReturnsFalse()
    // CLAIM: the negative direction -- a function name nothing declares has no row.
    var
        EventSubscription: Record "Event Subscription";
    begin
        Assert.IsFalse(
            EventSubscription.Get(Codeunit::"ALT Event Subscriber", 'ThisHandlerDoesNotExist'),
            'Event Subscription must not answer a row for a subscriber function that does not exist.');
    end;

    [Test]
    procedure EventSubscription_Row_DescribesTheSubscription()
    // CLAIM: the non-key columns describe the subscription the row is for -- publisher object
    // type and id, event type, and Active for a statically bound subscriber.
    var
        EventSubscription: Record "Event Subscription";
    begin
        Assert.IsTrue(
            EventSubscription.Get(Codeunit::"ALT Event Subscriber", 'OnBeforeActionHandler'),
            'Event Subscription has no row for ALT Event Subscriber.OnBeforeActionHandler.');

        Assert.AreEqual(
            EventSubscription."Publisher Object Type"::Codeunit, EventSubscription."Publisher Object Type",
            'OnBeforeActionHandler subscribes to an event published by a CODEUNIT.');
        Assert.AreEqual(
            Codeunit::"ALT Event Publisher", EventSubscription."Publisher Object ID",
            'OnBeforeActionHandler subscribes to an event published by ALT Event Publisher.');
        Assert.AreEqual(
            'OnBeforeAction', EventSubscription."Published Function",
            'OnBeforeActionHandler subscribes to OnBeforeAction.');
        Assert.AreEqual(
            EventSubscription."Event Type"::Integration, EventSubscription."Event Type",
            'ALT Event Publisher.OnBeforeAction is declared [IntegrationEvent].');
        Assert.IsTrue(
            EventSubscription.Active,
            'A statically bound subscriber that resolved must report Active.');
    end;

    [Test]
    procedure EventSubscription_TableEventRow_ReportsTablePublisher()
    // CLAIM: a TABLE-published trigger event is described with Publisher Object Type::Table and
    // the table's id -- the other half of the option column asserted above, so neither value can
    // be a constant.
    var
        EventSubscription: Record "Event Subscription";
    begin
        Assert.IsTrue(
            EventSubscription.Get(Codeunit::"ALT Table Event Subscriber", 'OnAfterInsertTriggered'),
            'Event Subscription has no row for ALT Table Event Subscriber.OnAfterInsertTriggered.');

        Assert.AreEqual(
            EventSubscription."Publisher Object Type"::Table, EventSubscription."Publisher Object Type",
            'OnAfterInsertTriggered subscribes to an event published by a TABLE.');
        Assert.AreEqual(
            Database::"ALT Triggered", EventSubscription."Publisher Object ID",
            'OnAfterInsertTriggered subscribes to an event published by ALT Triggered.');
        Assert.AreEqual(
            Codeunit::"ALT Table Event Subscriber", EventSubscription."Subscriber Codeunit ID",
            'The row must report the codeunit that declares the subscriber.');
    end;

    [Test]
    procedure EventSubscription_Walk_ReturnsRowsForMoreThanOneSubscriberCodeunit()
    // CLAIM: an unfiltered walk is not a single codeunit's rows -- the table spans every
    // registered subscription, so both fixture subscriber codeunits appear in one pass.
    var
        EventSubscription: Record "Event Subscription";
        SawEventSubscriber: Boolean;
        SawTableEventSubscriber: Boolean;
    begin
        EventSubscription.Reset();
        Assert.IsTrue(
            EventSubscription.FindSet(),
            'Event Subscription must not be empty: this app alone registers subscribers in two codeunits.');

        repeat
            if EventSubscription."Subscriber Codeunit ID" = Codeunit::"ALT Event Subscriber" then
                SawEventSubscriber := true;
            if EventSubscription."Subscriber Codeunit ID" = Codeunit::"ALT Table Event Subscriber" then
                SawTableEventSubscriber := true;
        until EventSubscription.Next() = 0;

        Assert.IsTrue(SawEventSubscriber, 'An unfiltered walk must reach ALT Event Subscriber''s rows.');
        Assert.IsTrue(SawTableEventSubscriber, 'An unfiltered walk must reach ALT Table Event Subscriber''s rows.');
    end;
}
