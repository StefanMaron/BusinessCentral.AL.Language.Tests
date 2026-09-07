// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: none (the built-in Integer virtual table, system object 2000000026)
//
// Pins the built-in Integer system virtual table: one row per value of Number.
// `dataitem(Name; Integer)` with a DataItemTableView filter is a standard idiom for a
// synthetic report/loop dataset, so a Record Integer that returns zero rows, or that
// answers every Find as true regardless of filter, silently changes program behavior
// without raising anything. The negative tests below carry as much weight as the
// positive ones: a provider that answers every Find with true, or that ignores the
// filter and returns a fixed row, would satisfy the positive cases on their own.
//
// The last three tests pin HOW FAR the table reaches, in both directions, and that an
// open-ended filter is answered rather than refused. Every other test here sits within a
// few rows of zero, so a provider that materialised a small window around zero would pass
// all of them; these say that Number 250000 and Number -250000 are ordinary rows, and that
// `SetFilter(Number, '>=1')` — the shape a report loop driver uses — yields rows rather
// than an error.

codeunit 60368 "Test Integer Virtual Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Record_Integer_ConstFilter_YieldsExactlyTheRequestedRow()
    var
        IntRec: Record Integer;
    begin
        Initialize();

        // [GIVEN] the shape `dataitem(OneRow; Integer) DataItemTableView = sorting(Number) where(Number = const(1))` uses
        IntRec.SetRange(Number, 1);

        // [WHEN] finding the first row for that filter
        Assert.IsTrue(IntRec.FindFirst(), 'Record Integer with Number = 1 was not found — the Integer virtual table has no rows.');

        // [THEN] exactly the requested row comes back
        Assert.AreEqual(1, IntRec.Number, 'Expected Number = 1');
        Assert.AreEqual(1, IntRec.Count(), 'Expected exactly 1 row for Number = const(1)');
    end;

    [Test]
    procedure Record_Integer_RangeFilter_YieldsEveryValueInOrder()
    var
        IntRec: Record Integer;
        Expected: Integer;
        Seen: Integer;
    begin
        Initialize();

        // [GIVEN] a range filter
        IntRec.SetRange(Number, 5, 9);

        // [THEN] the provider honours the range and returns ascending Number, rather than
        // repeating one row — a fixed-row provider fails the ordering check.
        Assert.AreEqual(5, IntRec.Count(), 'Expected 5 rows for Number in [5..9]');

        Expected := 5;
        if IntRec.FindSet() then
            repeat
                Assert.AreEqual(Expected, IntRec.Number, StrSubstNo('Expected Number %1 at position %2', Expected, Seen + 1));
                Expected += 1;
                Seen += 1;
            until IntRec.Next() = 0;

        Assert.AreEqual(5, Seen, 'Expected to iterate 5 rows');
    end;

    [Test]
    procedure Record_Integer_ZeroAndNegativeNumbers_AreRealRows()
    var
        IntRec: Record Integer;
    begin
        Initialize();

        // Real BC's Integer table spans the signed range, so 0 and negatives exist.
        // A provider seeded with only 1..N would pass the two tests above and fail here.
        IntRec.SetRange(Number, 0);
        Assert.IsTrue(IntRec.FindFirst(), 'Record Integer with Number = 0 was not found — 0 is a real row in BC.');
        Assert.AreEqual(0, IntRec.Number, 'Expected Number = 0');

        IntRec.Reset();
        IntRec.SetRange(Number, -3, -1);
        Assert.AreEqual(3, IntRec.Count(), 'Expected 3 rows for Number in [-3..-1]');
    end;

    [Test]
    procedure Record_Integer_EmptyRange_FindsNothing()
    var
        IntRec: Record Integer;
    begin
        Initialize();

        // Negative control: a provider that answers true unconditionally fails here.
        IntRec.SetRange(Number, 10, 4); // inverted — matches nothing
        Assert.IsFalse(IntRec.FindFirst(), 'Record Integer returned a row for the empty range [10..4].');
        Assert.IsTrue(IntRec.IsEmpty(), 'Expected IsEmpty() = true for the empty range [10..4].');
        Assert.AreEqual(0, IntRec.Count(), 'Expected 0 rows for the empty range [10..4]');
    end;

    [Test]
    procedure Record_Integer_RangeFarAboveAnySeededWindow_YieldsTheWholeRange()
    var
        IntRec: Record Integer;
    begin
        Initialize();

        // The rows here sit far above where a provider that merely seeds "enough for a report
        // loop" would stop. Number 250000 is an ordinary row on the service tier, so a Get for
        // it succeeds and a closed range ending there is counted in full.
        //
        // The count is asserted as well as the endpoint because those two fail differently: a
        // provider seeded to 100000 answers Count() with a plausible short number while
        // Get(250000) answers false outright, and only one of the two looks wrong on its own.
        Assert.IsTrue(IntRec.Get(250000), 'Record Integer has no row for Number = 250000.');
        Assert.AreEqual(250000, IntRec.Number, 'Expected Get(250000) to return Number 250000.');

        IntRec.Reset();
        IntRec.SetRange(Number, 249000, 250000);
        Assert.AreEqual(1001, IntRec.Count(), 'Expected 1001 rows for Number in [249000..250000].');
        Assert.IsFalse(IntRec.IsEmpty(), 'Number in [249000..250000] must not be empty.');
        Assert.IsTrue(IntRec.FindFirst(), 'Record Integer found no row for Number in [249000..250000].');
        Assert.AreEqual(249000, IntRec.Number, 'Expected the range to start at 249000.');
    end;

    [Test]
    procedure Record_Integer_RangeFarBelowZero_YieldsTheWholeRange()
    var
        IntRec: Record Integer;
    begin
        Initialize();

        // The same question at the other end. A provider that treats 0 as its floor, or that
        // seeds only a small negative margin, passes the -3..-1 test above and fails here.
        Assert.IsTrue(IntRec.Get(-250000), 'Record Integer has no row for Number = -250000.');
        Assert.AreEqual(-250000, IntRec.Number, 'Expected Get(-250000) to return Number -250000.');

        IntRec.Reset();
        IntRec.SetRange(Number, -250000, -249000);
        Assert.AreEqual(1001, IntRec.Count(), 'Expected 1001 rows for Number in [-250000..-249000].');
    end;

    [Test]
    procedure Record_Integer_HalfOpenFilter_IsAnsweredRatherThanRefused()
    var
        IntRec: Record Integer;
        Seen: Integer;
    begin
        Initialize();

        // `dataitem(N; Integer)` with no upper bound is a standard idiom — a loop driver whose
        // real limit is MaxIteration or an explicit exit, not the filter. So an open-ended
        // filter must be ANSWERED, not refused, and its first row must be the closed end.
        //
        // Only the first few rows are walked: this pins where the range starts and that it
        // continues, without asserting a total the service tier computes from a bound this test
        // deliberately does not name.
        IntRec.SetFilter(Number, '>=1');
        Assert.IsTrue(IntRec.FindSet(), 'An open-ended Integer filter returned no rows.');
        Assert.AreEqual(1, IntRec.Number, 'Expected the open-ended range to start at 1.');

        repeat
            Seen += 1;
        until (IntRec.Next() = 0) or (Seen >= 5);
        Assert.AreEqual(5, Seen, 'Expected an open-ended Integer filter to keep yielding rows.');

        // The mirror shape: open at the LOW end, closed at the high one. FindLast must land on
        // the closed bound.
        IntRec.Reset();
        IntRec.SetFilter(Number, '..7');
        Assert.IsTrue(IntRec.FindLast(), 'A low-open Integer filter returned no rows.');
        Assert.AreEqual(7, IntRec.Number, 'Expected the low-open range to end at 7.');
    end;

    local procedure Initialize()
    begin
        // Record Integer is a read-only system virtual table — nothing to DeleteAll.
    end;
}
