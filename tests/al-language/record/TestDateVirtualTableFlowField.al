// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: table 60778 "DVT Flow Row"
//
// Pins what a FlowField answers when its CalcFormula source is a COMPUTED system virtual table:
// Date (2000000007) and Integer (2000000026). Neither stores a row — the platform computes them
// per request — so these are the shape that asks whether CalcFields can aggregate over a source
// with no stored rows at all, and whether the range the formula names is the range the platform
// walks.
//
// The interesting range is one that is OPEN at one end, because the platform substitutes its own
// bound for the open end: for Date that is the first or last period start of the period type
// (0001-01-03 and 9999-12-31 for Date periods), for Integer it is the clamp at ±1,000,000,000.
// A source that answered a FlowField from some bounded subset of those tables would satisfy an
// in-range arm and quietly return a smaller number here, which is why each open-ended arm
// asserts the exact count AND both edges of the range the aggregate covered.
//
// The counts are arithmetic on fixed calendar dates, not values that drift: 0001-01-03 through
// 1850-01-01 is 675,332 days, and 2026-01-16 through 9999-12-31 is 2,912,428.
//
// The range is carried by a FlowFilter set from AL with DMY2Date rather than written as a date
// literal inside the CalcFormula, so no arm depends on how the session's culture parses a date
// string.
codeunit 60779 "Test Date Virtual Table FF"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure FlowField_CountOverDate_ClosedRange_CountsExactlyThatRange()
    var
        Row: Record "DVT Flow Row";
    begin
        // [GIVEN] a row whose Date FlowFilter names one calendar week
        Initialize(Row, 1);
        Row.SetRange("Date Filter", DMY2Date(19, 1, 2026), DMY2Date(25, 1, 2026));

        // [WHEN] the count/min/max FlowFields over the Date table are calculated
        Row.CalcFields("Days In Date Filter", "Earliest Day In Filter", "Latest Day In Filter");

        // [THEN] the aggregate covers exactly the seven days named, and nothing outside them
        Assert.AreEqual(7, Row."Days In Date Filter", 'count(Date) over one calendar week');
        Assert.AreEqual(DMY2Date(19, 1, 2026), Row."Earliest Day In Filter", 'min("Period Start") over one calendar week');
        Assert.AreEqual(DMY2Date(25, 1, 2026), Row."Latest Day In Filter", 'max("Period Start") over one calendar week');
    end;

    [Test]
    procedure FlowField_CountOverDate_RangeOpenAtTheLowEnd_ReachesTheFirstPeriodStart()
    var
        Row: Record "DVT Flow Row";
    begin
        // [GIVEN] a Date FlowFilter closed at its HIGH end only
        Initialize(Row, 2);
        Row.SetFilter("Date Filter", '..%1', DMY2Date(1, 1, 1850));

        // [WHEN] the aggregate is calculated
        Row.CalcFields("Days In Date Filter", "Earliest Day In Filter", "Latest Day In Filter");

        // [THEN] the open end runs back to the platform's first Date period start, 0001-01-03,
        // so the aggregate covers every day from there to the closed end: 675,332 of them.
        Assert.AreEqual(675332, Row."Days In Date Filter", 'count(Date) over a range open at its low end');
        Assert.AreEqual(DMY2Date(3, 1, 1), Row."Earliest Day In Filter", 'min("Period Start") over a range open at its low end');
        Assert.AreEqual(DMY2Date(1, 1, 1850), Row."Latest Day In Filter", 'max("Period Start") over a range open at its low end');
    end;

    [Test]
    procedure FlowField_CountOverDate_RangeOpenAtTheHighEnd_ReachesTheLastPeriodStart()
    var
        Row: Record "DVT Flow Row";
    begin
        // The mirror image, and the arm that a source bounded above would fail while passing the
        // one above: the open end runs forward to the platform's last Date period start.
        Initialize(Row, 3);
        Row.SetFilter("Date Filter", '%1..', DMY2Date(16, 1, 2026));

        Row.CalcFields("Days In Date Filter", "Earliest Day In Filter", "Latest Day In Filter");

        Assert.AreEqual(2912428, Row."Days In Date Filter", 'count(Date) over a range open at its high end');
        Assert.AreEqual(DMY2Date(16, 1, 2026), Row."Earliest Day In Filter", 'min("Period Start") over a range open at its high end');
        Assert.AreEqual(DMY2Date(31, 12, 9999), Row."Latest Day In Filter", 'max("Period Start") over a range open at its high end');
    end;

    [Test]
    procedure FlowField_ExistOverDate_AnswersPerPeriodTypeNotPerDay()
    var
        Row: Record "DVT Flow Row";
    begin
        // The negative arm the count tests cannot give: a formula that answered "yes" for every
        // range would satisfy the positive half of this and fail the second.
        //
        // Week periods start on Monday, and 19 January 2026 is a Monday. So the same table,
        // filtered on period type Week, has a row starting inside 19-25 January 2026 and no row
        // starting inside 20-24 January 2026 — while the Date-type rows for both ranges exist.
        Initialize(Row, 4);
        Row.SetRange("Date Filter", DMY2Date(19, 1, 2026), DMY2Date(25, 1, 2026));
        Row.CalcFields("Any Week In Filter", "Days In Date Filter");
        Assert.IsTrue(Row."Any Week In Filter", 'exist(Date, Week) over a range containing a Monday');
        Assert.AreEqual(7, Row."Days In Date Filter", 'count(Date, Date) over the same range');

        Row.SetRange("Date Filter", DMY2Date(20, 1, 2026), DMY2Date(24, 1, 2026));
        Row.CalcFields("Any Week In Filter", "Days In Date Filter");
        Assert.IsFalse(Row."Any Week In Filter", 'exist(Date, Week) over a range containing no Monday');
        Assert.AreEqual(5, Row."Days In Date Filter", 'count(Date, Date) over the same range');
    end;

    [Test]
    procedure FlowField_CountOverInteger_RangeOpenAtTheHighEnd_StopsAtThePlatformClamp()
    var
        Row: Record "DVT Flow Row";
    begin
        // The Integer table is the other computed virtual table, and its open end is substituted
        // with a clamp rather than a calendar bound. 999,999,990.. therefore covers exactly the
        // eleven values up to 1,000,000,000 — a number that says where the clamp is, which no
        // arm over a closed range can.
        Initialize(Row, 5);
        Row.SetFilter("Number Filter", '%1..', 999999990);
        Row.CalcFields("Integers In Filter");
        Assert.AreEqual(11, Row."Integers In Filter", 'count(Integer) over a range open at its high end');

        // The control: a closed range inside the clamp counts exactly itself.
        Row.SetRange("Number Filter", 1, 10);
        Row.CalcFields("Integers In Filter");
        Assert.AreEqual(10, Row."Integers In Filter", 'count(Integer) over a closed range');
    end;

    [Test]
    procedure TableRelation_ToDate_AcceptsAPeriodStartCenturiesFromToday()
    var
        Row: Record "DVT Flow Row";
    begin
        // The same question through a TableRelation instead of a CalcFormula: validating a field
        // related to Date."Period Start" makes the platform look the period up, and 1 January
        // 1200 is a real Date period start however far it is from today.
        Initialize(Row, 6);
        Row.Validate("Related Period", DMY2Date(1, 1, 1200));
        Assert.AreEqual(DMY2Date(1, 1, 1200), Row."Related Period", 'a TableRelation to Date accepted a period start in 1200');

        // The negative: no Week period starts on Tuesday 20 January 2026, but the relation names
        // period type Date, so the same day IS a valid Date period start. A relation resolved
        // against the wrong period type would reject it.
        Row.Validate("Related Period", DMY2Date(20, 1, 2026));
        Assert.AreEqual(DMY2Date(20, 1, 2026), Row."Related Period", 'a TableRelation to Date accepted a Tuesday');
    end;

    local procedure Initialize(var Row: Record "DVT Flow Row"; EntryNo: Integer)
    begin
        Row.Reset();
        Row.DeleteAll();
        Row.Init();
        Row."Entry No." := EntryNo;
        Row.Insert();
    end;
}
