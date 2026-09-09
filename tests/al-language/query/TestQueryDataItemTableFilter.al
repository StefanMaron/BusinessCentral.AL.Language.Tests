// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-dataitemtablefilter-property
//   dev-itpro/developer/methods-auto/query/query-data-type
// Scope: in-scope
// Fixtures used: QDTF Row (60497), QDTF Open Rows (60500), QDTF Two Field Filter (60501);
//   shared Assert (60021)
//
// A query dataitem's DataItemTableFilter property is a STATIC filter on the dataitem's own
// TABLE rows, applied before anything is projected. It differs from a column's ColumnFilter
// property in what it is keyed by: ColumnFilter names a QUERY COLUMN of the same query, so the
// filtered field must be projected; DataItemTableFilter names a TABLE FIELD of the dataitem's
// source table and needs no column at all. Both fixture queries here exploit that — neither
// projects the Status field they filter on.
//
// What each test pins:
//   - a single const(...) condition selects only matching rows, and the query's own columns
//     still project normally;
//   - two conditions on DIFFERENT fields both apply (an implicit AND), including the
//     filter(...) form with a comparison operator;
//   - a runtime SetRange on a projected column COMBINES with the static table filter rather
//     than replacing it — the opposite of ColumnFilter, where a runtime filter on the same
//     column replaces the static one (TestQueryColumnFilter.al pins that).
codeunit 60503 "QDTF Table Filter Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "QDTF Row";
    begin
        Row.DeleteAll();
    end;

    local procedure InsertRow(RowCode: Code[20]; Status: Option Open,Closed,Held; Amount: Decimal)
    var
        Row: Record "QDTF Row";
    begin
        Row.Init();
        Row.Code := RowCode;
        Row.Status := Status;
        Row.Amount := Amount;
        Row.Insert();
    end;

    local procedure SeedThreeStatuses()
    var
        Row: Record "QDTF Row";
    begin
        Initialize();
        // Deliberately inserted so that the row a dropped filter would return FIRST (by primary
        // key) is a CLOSED one: a query that ignored the filter answers 'A-CLOSED' first, not
        // the expected 'B-OPEN'.
        InsertRow('A-CLOSED', Row.Status::Closed, 500);
        InsertRow('B-OPEN', Row.Status::Open, 150);
        InsertRow('C-HELD', Row.Status::Held, 500);
        InsertRow('D-OPEN', Row.Status::Open, 50);
    end;

    [Test]
    procedure DataItemTableFilterConstSelectsOnlyMatchingRows()
    var
        Q: Query "QDTF Open Rows";
        Seen: Integer;
        First: Code[20];
        Last: Code[20];
    begin
        // [SCENARIO] A dataitem whose DataItemTableFilter is `Status = const(Open)` returns only
        // the Open rows, on a field the query does not project.
        SeedThreeStatuses();

        Q.Open();
        while Q.Read() do begin
            Seen += 1;
            if Seen = 1 then
                First := Q.RowCode;
            Last := Q.RowCode;
        end;
        Q.Close();

        Assert.AreEqual(2, Seen, 'rows returned when the dataitem filters Status = const(Open)');
        Assert.AreEqual('B-OPEN', First, 'first row (OrderBy ascending RowCode)');
        Assert.AreEqual('D-OPEN', Last, 'last row');
    end;

    [Test]
    procedure DataItemTableFilterDoesNotSuppressOtherColumns()
    var
        Q: Query "QDTF Open Rows";
        Total: Decimal;
    begin
        // [SCENARIO] Filtering on an unprojected field leaves the projected columns intact —
        // the filter selects rows, it does not blank or drop columns.
        SeedThreeStatuses();

        Q.Open();
        while Q.Read() do
            Total += Q.RowAmount;
        Q.Close();

        // 150 + 50 from the two Open rows; the Closed and Held rows contribute 500 each and
        // must not be counted.
        Assert.AreEqual(200.0, Total, 'summed Amount over the rows the static filter admits');
    end;

    [Test]
    procedure DataItemTableFilterCombinesTwoConditionsOnDifferentFields()
    var
        Q: Query "QDTF Two Field Filter";
        Seen: Integer;
        Only: Code[20];
    begin
        // [SCENARIO] `Status = const(Open), Amount = filter(> 100)` applies BOTH conditions.
        // Of the two Open rows only B-OPEN (150) clears the Amount filter; D-OPEN (50) does not.
        // Honouring only the first condition returns 2 rows, only the second returns 3.
        SeedThreeStatuses();

        Q.Open();
        while Q.Read() do begin
            Seen += 1;
            Only := Q.RowCode;
        end;
        Q.Close();

        Assert.AreEqual(1, Seen, 'rows satisfying BOTH Status = const(Open) and Amount = filter(> 100)');
        Assert.AreEqual('B-OPEN', Only, 'the one row satisfying both conditions');
    end;

    [Test]
    procedure DataItemTableFilterStillExcludesARowARuntimeFilterSelects()
    var
        Q: Query "QDTF Open Rows";
        Seen: Integer;
    begin
        // [SCENARIO] A runtime SetRange on a projected column NARROWS the static table filter
        // rather than replacing it. 'A-CLOSED' satisfies the runtime filter and not the static
        // one, so a query that let the runtime filter replace the static one would return it.
        SeedThreeStatuses();

        Q.SetRange(RowCode, 'A-CLOSED');
        Q.Open();
        while Q.Read() do
            Seen += 1;
        Q.Close();

        Assert.AreEqual(0, Seen, 'rows returned for a runtime filter selecting a row the static table filter excludes');
    end;

    [Test]
    procedure DataItemTableFilterAdmitsARowBothFiltersSelect()
    var
        Q: Query "QDTF Open Rows";
        Seen: Integer;
        Only: Code[20];
    begin
        // [SCENARIO] The positive companion to the previous test, so the pair cannot both be
        // satisfied by a query that simply returns nothing: a row satisfying BOTH the runtime
        // filter and the static table filter is returned.
        SeedThreeStatuses();

        Q.SetRange(RowCode, 'B-OPEN');
        Q.Open();
        while Q.Read() do begin
            Seen += 1;
            Only := Q.RowCode;
        end;
        Q.Close();

        Assert.AreEqual(1, Seen, 'rows satisfying both the runtime filter and the static table filter');
        Assert.AreEqual('B-OPEN', Only, 'the surviving row');
    end;

    [Test]
    procedure DataItemTableFilterReturnsNoRowsWhenNothingMatches()
    var
        Row: Record "QDTF Row";
        Q: Query "QDTF Open Rows";
        Seen: Integer;
    begin
        // [SCENARIO] Negative direction: with no Open row at all the query is empty — the
        // filter genuinely excludes, rather than falling back to returning everything.
        Initialize();
        InsertRow('A-CLOSED', Row.Status::Closed, 500);
        InsertRow('C-HELD', Row.Status::Held, 500);

        Q.Open();
        while Q.Read() do
            Seen += 1;
        Q.Close();

        Assert.AreEqual(0, Seen, 'rows returned when no row satisfies the static table filter');
    end;
}
