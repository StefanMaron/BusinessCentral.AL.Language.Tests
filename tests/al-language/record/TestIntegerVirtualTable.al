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

    local procedure Initialize()
    begin
        // Record Integer is a read-only system virtual table — nothing to DeleteAll.
    end;
}
