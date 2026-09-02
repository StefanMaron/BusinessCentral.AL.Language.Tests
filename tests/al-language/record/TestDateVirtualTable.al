// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: none (the built-in Date virtual table, system object 2000000007)
//
// Pins the built-in Date system virtual table: one computed row per period, for each of the
// five period types (Date, Week, Month, Quarter, Year). The primary key is
// ("Period Type", "Period Start"), and each row carries the period's end date, its number
// within the enclosing period, and its name.
//
// This table is how AL asks the platform "which day of the week is this", "which ISO week
// does this date fall in", and "when does this quarter end" without doing the arithmetic
// itself, so a Date table that returns no rows, or that ignores the filter and hands back a
// fixed row, changes program behavior without raising anything. The negative tests carry as
// much weight as the positive ones: a provider that answers every Find with true would
// satisfy the positive cases on its own.
//
// "Period End" is a closing date, so the expected values below are written as
// ClosingDate(...). Base Application code depends on that: it calls NormalDate() on the
// value whenever it wants the calendar day.
//
// The dates below are fixed literals, never Today or WorkDate, so the expected weekday,
// week number and period end are constants and the test does not drift with the clock.

codeunit 60983 "Test Date Virtual Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Record_Date_PeriodTypeDate_ExposesWeekdayNumberAndName()
    var
        DateRec: Record Date;
    begin
        Initialize();

        // [GIVEN] 19 January 2026 is a Monday
        DateRec.SetRange("Period Type", DateRec."Period Type"::Date);
        DateRec.SetRange("Period Start", DMY2Date(19, 1, 2026));

        // [WHEN] finding that row
        Assert.IsTrue(DateRec.FindFirst(), 'Record Date has no Date-type row for 19 January 2026.');

        // [THEN] a Date period is one day long, numbered Monday = 1 .. Sunday = 7, named for the weekday
        Assert.AreEqual(ClosingDate(DMY2Date(19, 1, 2026)), DateRec."Period End", 'A Date period ends on the day it starts, as a closing date.');
        Assert.AreEqual(1, DateRec."Period No.", 'Monday is day number 1.');
        Assert.AreEqual('Monday', DateRec."Period Name", 'A Date period is named for its weekday.');
        Assert.AreEqual(1, DateRec.Count(), 'Expected exactly one Date-type row for one date.');
    end;

    [Test]
    procedure Record_Date_PeriodTypeDate_SundayIsDayNumberSeven()
    var
        DateRec: Record Date;
    begin
        Initialize();

        // 25 January 2026 is a Sunday. This is the end of the numbering, and the one day
        // whose number is not its .NET DayOfWeek ordinal, so it is worth its own assertion.
        DateRec.SetRange("Period Type", DateRec."Period Type"::Date);
        DateRec.SetRange("Period Start", DMY2Date(25, 1, 2026));

        Assert.IsTrue(DateRec.FindFirst(), 'Record Date has no Date-type row for 25 January 2026.');
        Assert.AreEqual(7, DateRec."Period No.", 'Sunday is day number 7.');
        Assert.AreEqual('Sunday', DateRec."Period Name", 'A Date period is named for its weekday.');
    end;

    [Test]
    procedure Record_Date_PeriodTypeWeek_StartsOnMondayAndCarriesIsoWeekNumber()
    var
        DateRec: Record Date;
    begin
        Initialize();

        // [GIVEN] the week that starts Monday 19 January 2026
        DateRec.SetRange("Period Type", DateRec."Period Type"::Week);
        DateRec.SetRange("Period Start", DMY2Date(19, 1, 2026));

        Assert.IsTrue(DateRec.FindFirst(), 'Record Date has no Week-type row starting 19 January 2026.');

        // [THEN] the week runs Monday to Sunday and is numbered 4 (ISO week numbering)
        Assert.AreEqual(ClosingDate(DMY2Date(25, 1, 2026)), DateRec."Period End", 'A week ends on the Sunday, as a closing date.');
        Assert.AreEqual(4, DateRec."Period No.", '19 January 2026 falls in ISO week 4.');
        Assert.AreEqual('4', DateRec."Period Name", 'A week is named for its number.');
    end;

    [Test]
    procedure Record_Date_PeriodTypeWeek_NonMondayStart_FindsNothing()
    var
        DateRec: Record Date;
    begin
        Initialize();

        // Negative control. 20 January 2026 is a Tuesday, so no week starts on it. A provider
        // that materialises a row for every date regardless of period type fails here, and so
        // does one that answers Find unconditionally.
        DateRec.SetRange("Period Type", DateRec."Period Type"::Week);
        DateRec.SetRange("Period Start", DMY2Date(20, 1, 2026));

        Assert.IsFalse(DateRec.FindFirst(), 'Record Date returned a Week-type row starting on a Tuesday.');
        Assert.IsTrue(DateRec.IsEmpty(), 'Expected IsEmpty() = true for a Week starting on a Tuesday.');
        Assert.AreEqual(0, DateRec.Count(), 'Expected 0 Week-type rows starting on a Tuesday.');
    end;

    [Test]
    procedure Record_Date_PeriodTypeMonth_CarriesMonthNumberAndName()
    var
        DateRec: Record Date;
    begin
        Initialize();

        DateRec.SetRange("Period Type", DateRec."Period Type"::Month);
        DateRec.SetRange("Period Start", DMY2Date(1, 3, 2026));

        Assert.IsTrue(DateRec.FindFirst(), 'Record Date has no Month-type row for March 2026.');
        Assert.AreEqual(ClosingDate(DMY2Date(31, 3, 2026)), DateRec."Period End", 'March ends on the 31st, as a closing date.');
        Assert.AreEqual(3, DateRec."Period No.", 'March is month number 3.');
        Assert.AreEqual('March', DateRec."Period Name", 'A month is named for the month.');
    end;

    [Test]
    procedure Record_Date_PeriodTypeMonth_February2024_EndsOnTheLeapDay()
    var
        DateRec: Record Date;
    begin
        Initialize();

        // The month end is computed, not a fixed 28/30/31 table: 2024 is a leap year.
        DateRec.SetRange("Period Type", DateRec."Period Type"::Month);
        DateRec.SetRange("Period Start", DMY2Date(1, 2, 2024));

        Assert.IsTrue(DateRec.FindFirst(), 'Record Date has no Month-type row for February 2024.');
        Assert.AreEqual(ClosingDate(DMY2Date(29, 2, 2024)), DateRec."Period End", 'February 2024 ends on the 29th, as a closing date.');
    end;

    [Test]
    procedure Record_Date_PeriodTypeQuarter_CarriesQuarterNumber()
    var
        DateRec: Record Date;
    begin
        Initialize();

        DateRec.SetRange("Period Type", DateRec."Period Type"::Quarter);
        DateRec.SetRange("Period Start", DMY2Date(1, 4, 2026));

        Assert.IsTrue(DateRec.FindFirst(), 'Record Date has no Quarter-type row starting 1 April 2026.');
        Assert.AreEqual(ClosingDate(DMY2Date(30, 6, 2026)), DateRec."Period End", 'The second quarter ends on 30 June, as a closing date.');
        Assert.AreEqual(2, DateRec."Period No.", 'April starts the second quarter.');
        Assert.AreEqual('2', DateRec."Period Name", 'A quarter is named for its number.');
    end;

    [Test]
    procedure Record_Date_PeriodTypeYear_CarriesTheYearNumber()
    var
        DateRec: Record Date;
    begin
        Initialize();

        DateRec.SetRange("Period Type", DateRec."Period Type"::Year);
        DateRec.SetRange("Period Start", DMY2Date(1, 1, 2026));

        Assert.IsTrue(DateRec.FindFirst(), 'Record Date has no Year-type row for 2026.');
        Assert.AreEqual(ClosingDate(DMY2Date(31, 12, 2026)), DateRec."Period End", 'A year ends on 31 December, as a closing date.');
        Assert.AreEqual(2026, DateRec."Period No.", 'A year is numbered by the year itself.');
        Assert.AreEqual('2026', DateRec."Period Name", 'A year is named for its number.');
    end;

    [Test]
    procedure Record_Date_PeriodEnd_IsAClosingDate()
    var
        DateRec: Record Date;
    begin
        Initialize();

        // "Period End" is a closing date, not the plain last day of the period. Base Application
        // code relies on this: it wraps the value in NormalDate() whenever it wants the calendar
        // day (CalendarManagement, PeriodPageManagement, AvailableToPromise all do), and passes
        // it unwrapped into a date filter when it wants the period's closing entries included.
        // A provider that returned the plain date would satisfy every NormalDate() caller and
        // silently change which entries a period filter covers, so this gets its own test.
        DateRec.SetRange("Period Type", DateRec."Period Type"::Month);
        DateRec.SetRange("Period Start", DMY2Date(1, 3, 2026));
        Assert.IsTrue(DateRec.FindFirst(), 'Record Date has no Month-type row for March 2026.');

        Assert.AreNotEqual(DMY2Date(31, 3, 2026), DateRec."Period End", '"Period End" must not be the plain last day of the period.');
        Assert.AreEqual(DMY2Date(31, 3, 2026), NormalDate(DateRec."Period End"), 'NormalDate("Period End") must give the last day of the period.');
        Assert.AreEqual(DMY2Date(1, 3, 2026), DateRec."Period Start", '"Period Start", by contrast, is a plain date.');
        Assert.AreEqual(DMY2Date(1, 3, 2026), NormalDate(DateRec."Period Start"), 'NormalDate("Period Start") must leave the value alone.');
    end;

    [Test]
    procedure Record_Date_OpenEndedStartFilter_FindsTheNextMatchingWeekday()
    var
        DateRec: Record Date;
    begin
        Initialize();

        // The shape production AL uses to find the first weekday N on or after a date:
        // an open-ended "Period Start" filter plus a "Period No." range, then FindFirst.
        // This also proves the rows come back in ascending Period Start order.
        DateRec.SetRange("Period Type", DateRec."Period Type"::Date);
        DateRec.SetFilter("Period Start", '%1..', DMY2Date(16, 1, 2026)); // a Friday
        DateRec.SetRange("Period No.", 1); // Monday

        Assert.IsTrue(DateRec.FindFirst(), 'Record Date found no Monday on or after 16 January 2026.');
        Assert.AreEqual(DMY2Date(19, 1, 2026), DateRec."Period Start", 'The first Monday on or after Friday 16 January 2026 is 19 January.');
    end;

    [Test]
    procedure Record_Date_DateRangeFilter_YieldsEveryDayInOrder()
    var
        DateRec: Record Date;
        Expected: Date;
        Seen: Integer;
    begin
        Initialize();

        DateRec.SetRange("Period Type", DateRec."Period Type"::Date);
        DateRec.SetRange("Period Start", DMY2Date(19, 1, 2026), DMY2Date(25, 1, 2026));

        Assert.AreEqual(7, DateRec.Count(), 'Expected 7 Date-type rows for a seven-day range.');

        Expected := DMY2Date(19, 1, 2026);
        if DateRec.FindSet() then
            repeat
                Assert.AreEqual(Expected, DateRec."Period Start", StrSubstNo('Expected Period Start %1 at position %2', Expected, Seen + 1));
                Expected := Expected + 1;
                Seen += 1;
            until DateRec.Next() = 0;

        Assert.AreEqual(7, Seen, 'Expected to iterate 7 rows.');
    end;

    [Test]
    procedure Record_Date_InvertedRange_FindsNothing()
    var
        DateRec: Record Date;
    begin
        Initialize();

        // Negative control: an inverted range matches nothing, so a provider that ignores
        // the filter and returns a fixed row fails here.
        DateRec.SetRange("Period Type", DateRec."Period Type"::Date);
        DateRec.SetRange("Period Start", DMY2Date(25, 1, 2026), DMY2Date(19, 1, 2026));

        Assert.IsFalse(DateRec.FindFirst(), 'Record Date returned a row for an inverted range.');
        Assert.AreEqual(0, DateRec.Count(), 'Expected 0 rows for an inverted range.');
    end;

    [Test]
    procedure Record_Date_GetMissingPeriod_Raises()
    var
        DateRec: Record Date;
    begin
        Initialize();

        // A Get for a period that does not exist must raise, not hand back a blank row.
        // 20 January 2026 is a Tuesday, so there is no Week period starting on it.
        asserterror DateRec.Get(DateRec."Period Type"::Week, DMY2Date(20, 1, 2026));
        Assert.ExpectedErrorCannotFind(Database::Date);
    end;

    local procedure Initialize()
    begin
        // Record Date is a read-only computed system virtual table — nothing to clean up.
    end;
}
