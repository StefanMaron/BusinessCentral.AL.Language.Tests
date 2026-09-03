// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: none
//
// Pins the built-in "Time Zone" system virtual table (2000000164): one row per time zone the
// host reports, numbered 1..N, computed on demand rather than stored anywhere. It is the
// sibling of the Date (2000000007) and Integer (2000000026) virtual tables this suite already
// covers.
//
// EVERY ASSERTION IS ABOUT SHAPE, NEVER A SPECIFIC ZONE ID, and that is deliberate rather than
// weak. The platform builds these rows by enumerating the HOST operating system's installed
// time zones, so the ids are Windows ids on a Windows-hosted tier and IANA ids elsewhere, and
// "No." is a position in whichever list the host reports. A test naming "W. Europe Standard
// Time" would be asserting a property of the machine it happens to run on.
//
// What IS host-independent is the contract: the table answers rows, they are numbered from 1
// with no gaps, every row carries an id, Get agrees with FindSet, and a number past the end
// does not exist. The negative tests carry as much weight as the positive ones — a provider
// answering N blank rows would satisfy the count and the numbering and fail the id assertion.

codeunit 60960 "Test Time Zone Virtual Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Record_TimeZone_FindSet_AnswersRows()
    var
        TimeZone: Record "Time Zone";
    begin
        Assert.IsTrue(TimeZone.FindSet(), 'Time Zone must answer at least one row.');
        Assert.IsTrue(TimeZone.Count() > 1, 'A host installs more than one time zone.');
    end;

    [Test]
    procedure Record_TimeZone_NumbersStartAtOneAndIncrementWithNoGaps()
    var
        TimeZone: Record "Time Zone";
        Expected: Integer;
    begin
        // "No." is a sequence over the host's list. A provider that did not number its rows,
        // or numbered them from 0, fails here on any host.
        Expected := 0;
        Assert.IsTrue(TimeZone.FindSet(), 'Time Zone must answer at least one row.');
        repeat
            Expected += 1;
            Assert.AreEqual(Expected, TimeZone."No.", 'Time Zone "No." must run 1..N with no gaps.');
        until TimeZone.Next() = 0;
    end;

    [Test]
    procedure Record_TimeZone_EveryRowHasANonBlankId()
    var
        TimeZone: Record "Time Zone";
    begin
        // The negative control for N blank rows: the count and the numbering above would both
        // pass against those, and this would not.
        Assert.IsTrue(TimeZone.FindSet(), 'Time Zone must answer at least one row.');
        repeat
            Assert.AreNotEqual('', TimeZone.ID, 'Every Time Zone row must carry a non-blank ID.');
        until TimeZone.Next() = 0;
    end;

    [Test]
    procedure Record_TimeZone_GetOne_AgreesWithTheFirstRowOfFindSet()
    var
        ByGet: Record "Time Zone";
        ByFind: Record "Time Zone";
    begin
        // Get must return a real row of the same rowset, not a separately-built one.
        Assert.IsTrue(ByFind.FindSet(), 'Time Zone must answer at least one row.');
        Assert.IsTrue(ByGet.Get(1), 'Get(1) must find the first time zone.');
        Assert.AreEqual(ByFind.ID, ByGet.ID, 'Get(1) and the first FindSet row must be the same zone.');
        Assert.AreEqual(ByFind."Display Name", ByGet."Display Name",
            'Get(1) must carry the same Display Name as the first FindSet row.');
    end;

    [Test]
    procedure Record_TimeZone_GetOnANumberPastTheEnd_ReturnsFalse()
    var
        TimeZone: Record "Time Zone";
    begin
        // Negative control: a provider answering every Get with a row would pass everything
        // above and fail here.
        Assert.IsFalse(TimeZone.Get(999999), 'No host installs 999999 time zones.');
    end;

    [Test]
    procedure Record_TimeZone_FilterOnNumber_DiscriminatesBetweenRows()
    var
        TimeZone: Record "Time Zone";
    begin
        TimeZone.SetRange("No.", 1);
        Assert.AreEqual(1, TimeZone.Count(), 'A filter on one existing number must select one row.');

        TimeZone.SetRange("No.", 999999);
        Assert.AreEqual(0, TimeZone.Count(), 'A filter on an unused number must select no rows.');
        Assert.IsTrue(TimeZone.IsEmpty(), 'IsEmpty must be true for a filter naming no time zone.');
    end;
}
