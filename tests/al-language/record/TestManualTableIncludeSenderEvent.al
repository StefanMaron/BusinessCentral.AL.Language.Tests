// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-publisher-subscriber
// Scope: in-scope
// Fixtures used: ALT IncludeSender Table Pub (60966), ALT IncludeSender Cu Pub (60967),
//                 ALT IncludeSender Event Sub (60968)
//
// Coverage for [IntegrationEvent(true, false)] — IncludeSender=true — declared on a TABLE.
// IncludeSender=true means the event takes NO explicit parameters; the publishing object
// instance itself is what subscribers receive as "Sender". Every existing
// [IntegrationEvent]/[BusinessEvent] fixture in this corpus (table, codeunit, page, report,
// query, xmlport) uses IncludeSender=false, so this is new ground for ALL publisher kinds —
// the codeunit case is included here purely as a differential control, isolating whether a
// result is specific to the TABLE publisher or a general IncludeSender problem.

codeunit 60969 "Test Table IncludeSender Evt"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure TableIncludeSenderEvent_SubscriberReceivesUsableSenderRecord()
    var
        Pub: Record "ALT IncludeSender Table Pub";
    begin
        // [GIVEN] a table declaring [IntegrationEvent(true, false)]
        Initialize();

        // [WHEN] the table raises its IncludeSender=true event
        Pub.RaiseOnDiscoverEntries();

        // [THEN] the subscriber's Sender parameter was a working, non-null record handle for
        // THIS table — Insert()/Get() only succeed through a genuine Sender; a null Sender
        // raises a runtime error before any row could be written
        Assert.IsTrue(Pub.Get('FROM-TABLE-SENDER'),
            'the table-declared IncludeSender=true event''s subscriber must receive a usable Sender record, not null');
    end;

    [Test]
    procedure TableIncludeSenderEvent_NothingElseInserted_Control()
    var
        Pub: Record "ALT IncludeSender Table Pub";
    begin
        // [GIVEN] the same table
        Initialize();

        // [WHEN] the event is raised
        Pub.RaiseOnDiscoverEntries();

        // [THEN] dispatch inserted exactly the one entry the subscriber named — nothing else
        Pub.SetFilter("Code", '<>%1', 'FROM-TABLE-SENDER');
        Assert.IsTrue(Pub.IsEmpty(), 'dispatch must not insert any entry the subscriber did not name');
    end;

    [Test]
    procedure CodeunitIncludeSenderEvent_SubscriberReceivesUsableSenderCodeunit_Control()
    var
        CuPub: Codeunit "ALT IncludeSender Cu Pub";
        Pub: Record "ALT IncludeSender Table Pub";
    begin
        // [GIVEN] a CODEUNIT declaring the same [IntegrationEvent(true, false)] shape
        Initialize();

        // [WHEN] the codeunit raises its IncludeSender=true event
        CuPub.RaiseOnDiscoverFromCodeunit();

        // [THEN] the subscriber's Sender parameter was a working codeunit handle — calling
        // Ping() through it and observing the result proves it, not just that something
        // non-null arrived
        Assert.IsTrue(Pub.Get('FROM-CU-SENDER'),
            'the codeunit-declared IncludeSender=true event''s subscriber must receive a usable Sender codeunit');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
