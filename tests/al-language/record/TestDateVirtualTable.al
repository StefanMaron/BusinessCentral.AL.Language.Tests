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

    [Test]
    procedure Record_Date_RangeOpenAtTheLowEnd_ReachesBackToTheFirstPeriodStart()
    var
        DateRec: Record Date;
    begin
        Initialize();

        // A "Period Start" filter closed at its HIGH end only. The platform runs the open end
        // back to its own first period start for the period type - 3 January of year 1 for
        // Date - so the range is every day from there to 1 January 1850. A provider that
        // answers from a bounded set of precomputed rows returns nothing here, or returns a
        // first row that is wherever its own rows happen to begin.
        DateRec.SetRange("Period Type", DateRec."Period Type"::Date);
        DateRec.SetFilter("Period Start", '..%1', DMY2Date(1, 1, 1850));

        Assert.AreEqual(675332, DateRec.Count(), 'Expected every Date period from the first one up to 1 January 1850.');
        Assert.IsTrue(DateRec.FindFirst(), 'Record Date returned no row for a range open at its low end.');
        Assert.AreEqual(DMY2Date(3, 1, 1), DateRec."Period Start", 'The first Date period starts on 3 January of year 1.');
        Assert.IsTrue(DateRec.FindLast(), 'Record Date returned no last row for a range open at its low end.');
        Assert.AreEqual(DMY2Date(1, 1, 1850), DateRec."Period Start", 'The range ends on its closed bound, 1 January 1850.');
    end;

    [Test]
    procedure Record_Date_TwoClosedRanges_SelectTheirUnionNotTheirEnvelope()
    var
        DateRec: Record Date;
        I: Integer;
    begin
        Initialize();

        // A filter expression may name several ranges separated by `|`, and the rows it
        // selects are their UNION. The envelope of these two ranges spans 36 days; the union
        // is 15, so a provider that reads only the outermost bounds fails on the count and on
        // the row that follows the first range's end.
        DateRec.SetRange("Period Type", DateRec."Period Type"::Date);
        DateRec.SetFilter("Period Start", '%1..%2|%3..%4',
            DMY2Date(1, 1, 2000), DMY2Date(10, 1, 2000), DMY2Date(1, 2, 2000), DMY2Date(5, 2, 2000));

        Assert.AreEqual(15, DateRec.Count(), 'Expected 10 days in January plus 5 in February, not the 36 days they span.');
        Assert.IsTrue(DateRec.FindSet(), 'Record Date returned no rows for a two-range filter.');
        Assert.AreEqual(DMY2Date(1, 1, 2000), DateRec."Period Start", 'Expected the first range to start on 1 January 2000.');

        // Next is asserted step by step rather than driven from a loop condition, because AL
        // does not short-circuit `and`.
        for I := 1 to 9 do
            Assert.AreEqual(1, DateRec.Next(), 'Expected the first range to yield 10 consecutive days.');
        Assert.AreEqual(DMY2Date(10, 1, 2000), DateRec."Period Start", 'Expected the first range to end on 10 January 2000.');

        // The row after the first range's end is the second range's low bound, not 11 January.
        Assert.AreEqual(1, DateRec.Next(), 'Expected a row after the first range ended - the second range was dropped.');
        Assert.AreEqual(DMY2Date(1, 2, 2000), DateRec."Period Start", 'Expected the row after 10 January to be 1 February, the second range''s low bound.');
    end;

    [Test]
    procedure Record_Date_ClosedRangePlusRangeOpenAtTheHighEnd_SelectsBoth()
    var
        DateRec: Record Date;
        I: Integer;
    begin
        Initialize();

        // The same union rule with one of the two ranges open at its high end. The platform
        // runs that end out to its own last period start, 31 December 9999, so the answer is
        // the 10 days of the closed range plus every day from 1 January 2300 on. The outermost
        // closed bounds of the whole filter are 1 and 10 January 2000, both far from where the
        // rows actually end, so a provider that reads the envelope drops the second range
        // whole and answers 10.
        DateRec.SetRange("Period Type", DateRec."Period Type"::Date);
        DateRec.SetFilter("Period Start", '%1..%2|%3..',
            DMY2Date(1, 1, 2000), DMY2Date(10, 1, 2000), DMY2Date(1, 1, 2300));

        Assert.AreEqual(2812377, DateRec.Count(), 'Expected the union of a 10-day range and a range running to the last Date period.');
        Assert.IsTrue(DateRec.FindFirst(), 'Record Date returned no rows for a closed range plus an open-ended one.');
        Assert.AreEqual(DMY2Date(1, 1, 2000), DateRec."Period Start", 'Expected the first row to be the closed range''s low bound.');
        Assert.IsTrue(DateRec.FindLast(), 'Record Date returned no last row for a range open at its high end.');
        Assert.AreEqual(DMY2Date(31, 12, 9999), DateRec."Period Start", 'The last Date period starts on 31 December 9999.');

        // The row after the closed range's end is the open-ended range's low bound.
        Assert.IsTrue(DateRec.FindSet(), 'Record Date returned no rows to walk.');
        for I := 1 to 9 do
            Assert.AreEqual(1, DateRec.Next(), 'Expected the closed range to yield 10 consecutive days.');
        Assert.AreEqual(DMY2Date(10, 1, 2000), DateRec."Period Start", 'Expected the closed range to end on 10 January 2000.');
        Assert.AreEqual(1, DateRec.Next(), 'Expected a row after the closed range ended - the open-ended range was dropped.');
        Assert.AreEqual(DMY2Date(1, 1, 2300), DateRec."Period Start", 'Expected the row after 10 January 2000 to be 1 January 2300.');
    end;

    [Test]
    procedure Record_Date_LastPeriodStart_PerPeriodType_IsTheLastPeriodThatFitsInTheYear9999()
    var
        DateRec: Record Date;
    begin
        Initialize();

        // The high end of the table. The platform computes periods rather than storing them, so
        // the last row for each period type is decided by arithmetic, and that arithmetic runs
        // out at 31 December 9999 - the last date the platform can represent. What each period
        // type answers there is not the same date, because a period whose END would fall past
        // 9999-12-31 is not a period the table can carry.
        //
        // The negative direction matters as much as the positive one: a provider that ran its
        // loop one period too far would answer a row here whose "Period End" had wrapped, and a
        // provider that stopped one period short would answer the period before.

        // Date: every day is a period, so the last one is the last representable day itself.
        DateRec.SetRange("Period Type", DateRec."Period Type"::Date);
        Assert.IsTrue(DateRec.FindLast(), 'Record Date returned no last row for period type Date.');
        Assert.AreEqual(DMY2Date(31, 12, 9999), DateRec."Period Start", 'The last Date period starts on 31 December 9999.');
        Assert.AreEqual(ClosingDate(DMY2Date(31, 12, 9999)), DateRec."Period End", 'The last Date period ends on the day it starts.');

        // Week: weeks start on Monday. 27 December 9999 is a Monday, but its week would end on
        // 2 January of year 10000, so the last week the table carries is the one before it.
        DateRec.Reset();
        DateRec.SetRange("Period Type", DateRec."Period Type"::Week);
        Assert.IsTrue(DateRec.FindLast(), 'Record Date returned no last row for period type Week.');
        Assert.AreEqual(DMY2Date(20, 12, 9999), DateRec."Period Start", 'The last Week period starts on Monday 20 December 9999.');
        Assert.AreEqual(ClosingDate(DMY2Date(26, 12, 9999)), DateRec."Period End", 'The last Week period ends on Sunday 26 December 9999.');

        // Month, Quarter, Year: the last period of each that ends on or before 31 December 9999.
        DateRec.Reset();
        DateRec.SetRange("Period Type", DateRec."Period Type"::Month);
        Assert.IsTrue(DateRec.FindLast(), 'Record Date returned no last row for period type Month.');
        Assert.AreEqual(DMY2Date(1, 12, 9999), DateRec."Period Start", 'The last Month period starts on 1 December 9999.');
        Assert.AreEqual(ClosingDate(DMY2Date(31, 12, 9999)), DateRec."Period End", 'The last Month period ends on 31 December 9999.');

        DateRec.Reset();
        DateRec.SetRange("Period Type", DateRec."Period Type"::Quarter);
        Assert.IsTrue(DateRec.FindLast(), 'Record Date returned no last row for period type Quarter.');
        Assert.AreEqual(DMY2Date(1, 10, 9999), DateRec."Period Start", 'The last Quarter period starts on 1 October 9999.');
        Assert.AreEqual(ClosingDate(DMY2Date(31, 12, 9999)), DateRec."Period End", 'The last Quarter period ends on 31 December 9999.');

        DateRec.Reset();
        DateRec.SetRange("Period Type", DateRec."Period Type"::Year);
        Assert.IsTrue(DateRec.FindLast(), 'Record Date returned no last row for period type Year.');
        Assert.AreEqual(DMY2Date(1, 1, 9999), DateRec."Period Start", 'The last Year period starts on 1 January 9999.');
        Assert.AreEqual(ClosingDate(DMY2Date(31, 12, 9999)), DateRec."Period End", 'The last Year period ends on 31 December 9999.');
    end;

    [Test]
    procedure Record_Date_FirstPeriodStart_PerPeriodType_IsTheFirstPeriodThatFitsInYearOne()
    var
        DateRec: Record Date;
    begin
        Initialize();

        // The low end, the mirror of the test above. Year 1 does not begin the table for every
        // period type: a period whose start would fall before 1 January of year 1 cannot be
        // represented, so each type begins at the first period that fits whole.
        //
        // Record_Date_RangeOpenAtTheLowEnd_ReachesBackToTheFirstPeriodStart already pins the
        // Date type's first row through a filter; this reaches the same row through FindFirst
        // and adds the four period types that test does not cover.

        DateRec.SetRange("Period Type", DateRec."Period Type"::Date);
        Assert.IsTrue(DateRec.FindFirst(), 'Record Date returned no first row for period type Date.');
        Assert.AreEqual(DMY2Date(3, 1, 1), DateRec."Period Start", 'The first Date period starts on 3 January of year 1.');

        DateRec.Reset();
        DateRec.SetRange("Period Type", DateRec."Period Type"::Week);
        Assert.IsTrue(DateRec.FindFirst(), 'Record Date returned no first row for period type Week.');
        Assert.AreEqual(DMY2Date(8, 1, 1), DateRec."Period Start", 'The first Week period starts on Monday 8 January of year 1.');
        Assert.AreEqual(ClosingDate(DMY2Date(14, 1, 1)), DateRec."Period End", 'The first Week period ends on Sunday 14 January of year 1.');

        DateRec.Reset();
        DateRec.SetRange("Period Type", DateRec."Period Type"::Month);
        Assert.IsTrue(DateRec.FindFirst(), 'Record Date returned no first row for period type Month.');
        Assert.AreEqual(DMY2Date(1, 2, 1), DateRec."Period Start", 'The first Month period starts on 1 February of year 1.');

        DateRec.Reset();
        DateRec.SetRange("Period Type", DateRec."Period Type"::Quarter);
        Assert.IsTrue(DateRec.FindFirst(), 'Record Date returned no first row for period type Quarter.');
        Assert.AreEqual(DMY2Date(1, 4, 1), DateRec."Period Start", 'The first Quarter period starts on 1 April of year 1.');

        DateRec.Reset();
        DateRec.SetRange("Period Type", DateRec."Period Type"::Year);
        Assert.IsTrue(DateRec.FindFirst(), 'Record Date returned no first row for period type Year.');
        Assert.AreEqual(DMY2Date(1, 1, 2), DateRec."Period Start", 'The first Year period starts on 1 January of year 2.');
    end;

    [Test]
    procedure Record_Date_KeyedGetAtBothRepresentableBoundaries_AnswersTheRow()
    var
        DateRec: Record Date;
    begin
        Initialize();

        // A keyed Get - not a filtered read - at each end of the table. This is the shape that
        // reaches the platform's primary-key path, and the boundary is where a provider that
        // computes "the period before" or "the period after" to locate a row runs its own
        // arithmetic off the end of the representable range.
        //
        // Both ends must answer the row itself, with the period's own end date.
        DateRec.Get(DateRec."Period Type"::Date, DMY2Date(3, 1, 1));
        Assert.AreEqual(ClosingDate(DMY2Date(3, 1, 1)), DateRec."Period End", 'Get at the first Date period returned a different period.');

        Clear(DateRec);
        DateRec.Get(DateRec."Period Type"::Date, DMY2Date(31, 12, 9999));
        Assert.AreEqual(ClosingDate(DMY2Date(31, 12, 9999)), DateRec."Period End", 'Get at the last Date period returned a different period.');

        Clear(DateRec);
        DateRec.Get(DateRec."Period Type"::Year, DMY2Date(1, 1, 9999));
        Assert.AreEqual(ClosingDate(DMY2Date(31, 12, 9999)), DateRec."Period End", 'Get at the last Year period returned a different period.');

        // The negatives, one period past each edge. 2 January of year 1 precedes the first Date
        // period, and 1 January of year 1 precedes the first Year period; neither is a period
        // start, so each must raise rather than hand back a blank row or an invented one.
        Clear(DateRec);
        asserterror DateRec.Get(DateRec."Period Type"::Date, DMY2Date(2, 1, 1));
        Assert.ExpectedErrorCannotFind(Database::Date);

        Clear(DateRec);
        asserterror DateRec.Get(DateRec."Period Type"::Year, DMY2Date(1, 1, 1));
        Assert.ExpectedErrorCannotFind(Database::Date);
    end;

    local procedure Initialize()
    begin
        // Record Date is a read-only computed system virtual table — nothing to clean up.
    end;
}
