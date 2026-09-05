// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: CFM Line (60440), CFM Header (60441)
// BC versions: 27.5+
//
// The three CalcFormula methods the corpus does not yet pin. sum(), count(), lookup() and
// exist() each already have coverage (TestRecordFlowField, TestFlowFieldContracts,
// TestCalcFormulaSignFilters, TestCalcFormulaFlowFilters); min(), max() and average() have
// none at all, in any file.
//
// Each test below asserts a value that is simultaneously wrong for the obvious substitutes:
//
//   * the type default (0 / 0D)      -- D1's minimum Amount is -10, its dates are real dates
//   * the sum                        -- D1 sums to 125, and no min/max/average answer is 125
//   * the row count                  -- D1 has 4 lines, and no answer is 4
//   * "skip blank/zero source rows"  -- D4 is three zero rows plus one 10, so min is 0 and
//                                       the average is 2.5, not 10
//   * integer division               -- 125/4 = 31.25 and 21/4 = 5.25, neither an integer
//
// Seeded data, once, in Initialize():
//
//   Doc  Entry  Amount  Qty  Posting Date     sum   count  min   max  average
//   D1   1        40      3  2024-01-10
//   D1   2       -10      4  2024-02-10
//   D1   3        75      6  2024-03-10
//   D1   4        20      8  2024-04-10       125     4    -10    75   31.25
//   D2   9       999     99  2024-02-15       999     1    999   999     999
//   D3   (no lines)                             0     0      0     0       0
//   D4   5        10      1  2024-05-10
//   D4   6         0      0  2024-05-11
//   D4   7         0      0  2024-05-12
//   D4   8         0      0  2024-05-13        10     4      0    10     2.5
codeunit 60442 "CFM Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        CfmLine: Record "CFM Line";
        CfmHeader: Record "CFM Header";
    begin
        CfmLine.Reset();
        CfmLine.DeleteAll();
        CfmHeader.Reset();
        CfmHeader.DeleteAll();

        AddHeader('D1');
        AddHeader('D2');
        AddHeader('D3');
        AddHeader('D4');

        // D1: four lines, one per month, one of them negative. 40 - 10 + 75 + 20 = 125.
        AddLine(1, 'D1', 40, 3, 20240110D);
        AddLine(2, 'D1', -10, 4, 20240210D);
        AddLine(3, 'D1', 75, 6, 20240310D);
        AddLine(4, 'D1', 20, 8, 20240410D);

        // D2: a single line. min = max = average = the row's own value.
        AddLine(9, 'D2', 999, 99, 20240215D);

        // D3 deliberately has no lines at all.

        // D4: one non-zero line and three zero lines. min = 0 and average = 2.5 only if the
        // zero rows participate; an implementation that skips them answers 10 and 10.
        AddLine(5, 'D4', 10, 1, 20240510D);
        AddLine(6, 'D4', 0, 0, 20240511D);
        AddLine(7, 'D4', 0, 0, 20240512D);
        AddLine(8, 'D4', 0, 0, 20240513D);
    end;

    local procedure AddHeader(No: Code[20])
    var
        CfmHeader: Record "CFM Header";
    begin
        CfmHeader.Init();
        CfmHeader."No." := No;
        CfmHeader.Insert(false);
    end;

    local procedure AddLine(EntryNo: Integer; DocNo: Code[20]; Amt: Decimal; Qty: Integer; PostingDate: Date)
    var
        CfmLine: Record "CFM Line";
    begin
        CfmLine.Init();
        CfmLine."Entry No." := EntryNo;
        CfmLine."Doc No." := DocNo;
        CfmLine.Amount := Amt;
        CfmLine.Quantity := Qty;
        CfmLine."Posting Date" := PostingDate;
        CfmLine.Insert(false);
    end;

    [Test]
    procedure Record_CalcFields_Min_ReturnsSmallestSourceValue_IncludingNegatives()
    var
        CfmHeader: Record "CFM Header";
    begin
        // [GIVEN] D1's four Amounts are 40, -10, 75, 20.
        Initialize();
        CfmHeader.Get('D1');

        // [WHEN]
        CfmHeader.CalcFields("Min Amount", "Min Quantity", "Total Amount", "Line Count");

        // [THEN] The minimum is the NEGATIVE value. 0 is the type default and the answer a
        // running minimum seeded at zero gives; 125 is the sum; 4 is the row count.
        Assert.AreEqual(-10, CfmHeader."Min Amount",
            'min() must return the smallest Amount, including a negative one');
        Assert.AreNotEqual(CfmHeader."Total Amount", CfmHeader."Min Amount",
            'min() must not be the sum');

        // [THEN] The Integer source takes the same path.
        Assert.AreEqual(3, CfmHeader."Min Quantity",
            'min() over an Integer source must return the smallest Quantity');

        // [THEN] A single-row document: the minimum is that row's own value.
        CfmHeader.Get('D2');
        CfmHeader.CalcFields("Min Amount");
        Assert.AreEqual(999, CfmHeader."Min Amount",
            'min() over one matching row must return that row''s value');
    end;

    [Test]
    procedure Record_CalcFields_Max_ReturnsLargestSourceValue()
    var
        CfmHeader: Record "CFM Header";
    begin
        // [GIVEN] D1's four Amounts are 40, -10, 75, 20 and its Quantities 3, 4, 6, 8.
        Initialize();
        CfmHeader.Get('D1');

        // [WHEN]
        CfmHeader.CalcFields("Max Amount", "Max Quantity", "Min Amount", "Total Amount");

        // [THEN] 75 is neither the sum (125), the count (4), nor the minimum (-10).
        Assert.AreEqual(75, CfmHeader."Max Amount",
            'max() must return the largest Amount');
        Assert.AreEqual(8, CfmHeader."Max Quantity",
            'max() over an Integer source must return the largest Quantity');
        Assert.AreNotEqual(CfmHeader."Min Amount", CfmHeader."Max Amount",
            'min() and max() must not collapse onto the same value');
        Assert.AreNotEqual(CfmHeader."Total Amount", CfmHeader."Max Amount",
            'max() must not be the sum');

        // [THEN] D4 is one 10 and three zeros: the maximum is the only non-zero row.
        CfmHeader.Get('D4');
        CfmHeader.CalcFields("Max Amount");
        Assert.AreEqual(10, CfmHeader."Max Amount",
            'max() must ignore lower rows, not the row count');
    end;

    [Test]
    procedure Record_CalcFields_MinMax_ZeroValuedRowsParticipate()
    var
        CfmHeader: Record "CFM Header";
    begin
        // [GIVEN] D4 is a 10 plus three rows whose Amount and Quantity are 0.
        Initialize();
        CfmHeader.Get('D4');

        // [WHEN]
        CfmHeader.CalcFields("Min Amount", "Max Amount", "Min Quantity", "Max Quantity",
                             "Total Amount", "Line Count");

        // [THEN] The zero rows are rows like any other, so the minimum is 0 while the maximum
        // is 10. An implementation that treats a blank source value as "no value" answers 10
        // for BOTH -- which is exactly what this pair rules out.
        Assert.AreEqual(0, CfmHeader."Min Amount",
            'a zero-valued source row must participate in min()');
        Assert.AreEqual(10, CfmHeader."Max Amount",
            'max() must still see the single non-zero row');
        Assert.AreEqual(0, CfmHeader."Min Quantity",
            'a zero-valued Integer source row must participate in min()');
        Assert.AreEqual(1, CfmHeader."Max Quantity",
            'max() over the Integer source must return 1, the only non-zero Quantity');

        // [THEN] The baselines confirm all four rows really are in the aggregate set.
        Assert.AreEqual(10, CfmHeader."Total Amount", 'D4 must sum to 10');
        Assert.AreEqual(4, CfmHeader."Line Count", 'D4 must have four matching lines');
    end;

    [Test]
    procedure Record_CalcFields_Average_DividesByEveryMatchingRow()
    var
        CfmHeader: Record "CFM Header";
    begin
        // [GIVEN] D1: 125 over 4 rows.
        Initialize();
        CfmHeader.Get('D1');

        // [WHEN]
        CfmHeader.CalcFields("Average Amount", "Average Quantity", "Total Amount", "Line Count");

        // [THEN] 31.25 is not the sum, not the count, and not an integer -- so an
        // implementation that truncates, or that returns the sum, fails here.
        Assert.AreEqual(31.25, CfmHeader."Average Amount",
            'average() must be the sum divided by the matching row count, without truncating');

        // [THEN] An INTEGER source averaged into a Decimal FlowField: 21 / 4 = 5.25, not 5.
        Assert.AreEqual(5.25, CfmHeader."Average Quantity",
            'average() over an Integer source must not be integer division');

        // [THEN] D4: the denominator counts the three zero rows, so 10 / 4 = 2.5, not 10 / 1.
        CfmHeader.Get('D4');
        CfmHeader.CalcFields("Average Amount");
        Assert.AreEqual(2.5, CfmHeader."Average Amount",
            'average() must divide by every matching row, including zero-valued ones');

        // [THEN] One matching row averages to its own value.
        CfmHeader.Get('D2');
        CfmHeader.CalcFields("Average Amount");
        Assert.AreEqual(999, CfmHeader."Average Amount",
            'average() over one matching row must return that row''s value');
    end;

    [Test]
    procedure Record_CalcFields_MinMaxAverage_NoMatchingRows_ReturnZero()
    var
        CfmHeader: Record "CFM Header";
    begin
        // [GIVEN] D3 has no lines at all.
        Initialize();
        CfmHeader.Get('D3');

        // [WHEN] [THEN] CalcFields still succeeds -- an empty aggregate is not an error, and
        // average() in particular must not divide by zero.
        Assert.IsTrue(CfmHeader.CalcFields("Min Amount", "Max Amount", "Average Amount",
                                           "Min Quantity", "Max Quantity", "Line Count"),
            'CalcFields over an empty source set must succeed');

        Assert.AreEqual(0, CfmHeader."Min Amount", 'min() over no rows must be 0');
        Assert.AreEqual(0, CfmHeader."Max Amount", 'max() over no rows must be 0');
        Assert.AreEqual(0, CfmHeader."Average Amount", 'average() over no rows must be 0');
        Assert.AreEqual(0, CfmHeader."Min Quantity", 'min() over no Integer rows must be 0');
        Assert.AreEqual(0, CfmHeader."Max Quantity", 'max() over no Integer rows must be 0');
        Assert.AreEqual(0, CfmHeader."Line Count", 'D3 must have no matching lines');
    end;

    [Test]
    procedure Record_CalcFields_MinMax_DateSource_ReturnFirstAndLastDate()
    var
        CfmHeader: Record "CFM Header";
        EmptyDate: Date;
    begin
        // [GIVEN] D1's four lines are dated 10-01, 10-02, 10-03 and 10-04 of 2024.
        Initialize();
        CfmHeader.Get('D1');

        // [WHEN]
        CfmHeader.CalcFields("First Posting Date", "Last Posting Date");

        // [THEN] min()/max() over a Date source give the first and the last date, not the
        // empty date and not the same date twice.
        Assert.AreEqual(20240110D, CfmHeader."First Posting Date",
            'min() over a Date source must return the earliest Posting Date');
        Assert.AreEqual(20240410D, CfmHeader."Last Posting Date",
            'max() over a Date source must return the latest Posting Date');
        Assert.AreNotEqual(CfmHeader."First Posting Date", CfmHeader."Last Posting Date",
            'the earliest and the latest Posting Date must differ');

        // [THEN] With no matching rows both collapse to the empty date -- the Date type's
        // default, which is what an unmatched min()/max() has to fall back to.
        CfmHeader.Get('D3');
        CfmHeader.CalcFields("First Posting Date", "Last Posting Date");
        Assert.AreEqual(EmptyDate, CfmHeader."First Posting Date",
            'min() over no Date rows must be the empty date');
        Assert.AreEqual(EmptyDate, CfmHeader."Last Posting Date",
            'max() over no Date rows must be the empty date');
    end;

    [Test]
    procedure Record_CalcFields_MinMaxAverage_FlowFilterNarrowsTheAggregate()
    var
        CfmHeader: Record "CFM Header";
    begin
        // [GIVEN] D1: 40 in January, -10 in February, 75 in March, 20 in April.
        Initialize();
        CfmHeader.Get('D1');

        // [WHEN] The caller narrows the flow filter to January..February.
        CfmHeader.SetRange("Date Filter", 20240101D, 20240229D);
        CfmHeader.CalcFields("Period Min Amount", "Period Max Amount", "Period Average Amount",
                             "Total Amount");

        // [THEN] The maximum moves from 75 to 40 and the average from 31.25 to 15 -- so the
        // where-condition really is applied, and the average's DENOMINATOR moved from 4 to 2.
        Assert.AreEqual(-10, CfmHeader."Period Min Amount",
            'the January..February minimum is -10');
        Assert.AreEqual(40, CfmHeader."Period Max Amount",
            'the January..February maximum is 40, not the unfiltered 75');
        Assert.AreEqual(15, CfmHeader."Period Average Amount",
            'the January..February average is 30 / 2, not 125 / 4');

        // [THEN] A FlowField that does not name the flow filter is untouched by it.
        Assert.AreEqual(125, CfmHeader."Total Amount",
            'a flow filter must not affect a FlowField that does not reference it');

        // [WHEN] The window moves to March..April.
        CfmHeader.SetRange("Date Filter", 20240301D, 20240430D);
        CfmHeader.CalcFields("Period Min Amount", "Period Max Amount", "Period Average Amount");

        // [THEN] Now the MINIMUM moves instead -- the pair of windows shows both ends respond.
        Assert.AreEqual(20, CfmHeader."Period Min Amount",
            'the March..April minimum is 20, not the unfiltered -10');
        Assert.AreEqual(75, CfmHeader."Period Max Amount",
            'the March..April maximum is 75');
        Assert.AreEqual(47.5, CfmHeader."Period Average Amount",
            'the March..April average is 95 / 2');

        // [WHEN] The flow filter is cleared.
        CfmHeader.SetRange("Date Filter");
        CfmHeader.CalcFields("Period Min Amount", "Period Max Amount", "Period Average Amount");

        // [THEN] It widens back to every line -- the values track the filter, they are not cached.
        Assert.AreEqual(-10, CfmHeader."Period Min Amount",
            'clearing the flow filter must widen min() back to -10');
        Assert.AreEqual(75, CfmHeader."Period Max Amount",
            'clearing the flow filter must widen max() back to 75');
        Assert.AreEqual(31.25, CfmHeader."Period Average Amount",
            'clearing the flow filter must widen average() back to 125 / 4');

        // [WHEN] The window matches no line at all.
        CfmHeader.SetRange("Date Filter", 20990101D, 20991231D);
        CfmHeader.CalcFields("Period Min Amount", "Period Max Amount", "Period Average Amount");

        // [THEN] The exclusion direction: all three collapse to 0 rather than keeping the
        // previous answer.
        Assert.AreEqual(0, CfmHeader."Period Min Amount",
            'a flow filter matching no row must give a minimum of 0');
        Assert.AreEqual(0, CfmHeader."Period Max Amount",
            'a flow filter matching no row must give a maximum of 0');
        Assert.AreEqual(0, CfmHeader."Period Average Amount",
            'a flow filter matching no row must give an average of 0');
    end;

    [Test]
    procedure Record_SetAutoCalcFields_MinMaxAverage_CalculatedPerRecordOnNext()
    var
        CfmHeader: Record "CFM Header";
    begin
        // [GIVEN] Four headers, each with a different aggregate shape.
        Initialize();

        // [WHEN] min()/max()/average() are requested through the auto-calc path rather than an
        // explicit CalcFields call.
        CfmHeader.SetAutoCalcFields("Min Amount", "Max Amount", "Average Amount");
        CfmHeader.SetCurrentKey("No.");
        Assert.IsTrue(CfmHeader.FindSet(), 'the four seeded headers must be readable');

        // [THEN] D1 -- four rows, negative minimum, fractional average.
        Assert.AreEqual('D1', CfmHeader."No.", 'the first header by primary key must be D1');
        Assert.AreEqual(-10, CfmHeader."Min Amount", 'auto-calc must compute min() for D1');
        Assert.AreEqual(75, CfmHeader."Max Amount", 'auto-calc must compute max() for D1');
        Assert.AreEqual(31.25, CfmHeader."Average Amount", 'auto-calc must compute average() for D1');

        // [THEN] D2 -- one row: all three are that row's value. Proves the aggregate is
        // recomputed per record instead of being carried over from D1.
        Assert.AreEqual(1, CfmHeader.Next(), 'there must be a second header');
        Assert.AreEqual('D2', CfmHeader."No.", 'the second header by primary key must be D2');
        Assert.AreEqual(999, CfmHeader."Min Amount", 'auto-calc must recompute min() for D2');
        Assert.AreEqual(999, CfmHeader."Max Amount", 'auto-calc must recompute max() for D2');
        Assert.AreEqual(999, CfmHeader."Average Amount", 'auto-calc must recompute average() for D2');

        // [THEN] D3 -- no rows: back to 0, so a stale D2 value is ruled out.
        Assert.AreEqual(1, CfmHeader.Next(), 'there must be a third header');
        Assert.AreEqual('D3', CfmHeader."No.", 'the third header by primary key must be D3');
        Assert.AreEqual(0, CfmHeader."Min Amount", 'auto-calc must give 0 for the empty D3');
        Assert.AreEqual(0, CfmHeader."Max Amount", 'auto-calc must give 0 for the empty D3');
        Assert.AreEqual(0, CfmHeader."Average Amount", 'auto-calc must give 0 for the empty D3');

        // [THEN] D4 -- the zero-row document.
        Assert.AreEqual(1, CfmHeader.Next(), 'there must be a fourth header');
        Assert.AreEqual('D4', CfmHeader."No.", 'the fourth header by primary key must be D4');
        Assert.AreEqual(0, CfmHeader."Min Amount", 'auto-calc must compute min() = 0 for D4');
        Assert.AreEqual(10, CfmHeader."Max Amount", 'auto-calc must compute max() = 10 for D4');
        Assert.AreEqual(2.5, CfmHeader."Average Amount", 'auto-calc must compute average() = 2.5 for D4');
    end;

    [Test]
    procedure Record_TestField_OnCalculatedMaxFlowField_Mismatch_Throws()
    var
        CfmHeader: Record "CFM Header";
    begin
        // [GIVEN] D1's largest Quantity is 8.
        Initialize();
        CfmHeader.Get('D1');
        CfmHeader.CalcFields("Max Quantity");
        Assert.AreEqual(8, CfmHeader."Max Quantity", 'precondition: D1''s maximum Quantity is 8');

        // [WHEN] [THEN] TestField against the calculated value must NOT throw -- the aggregate
        // really did land in the record's field buffer.
        CfmHeader.TestField("Max Quantity", 8);

        // [WHEN] [THEN] ...and against any other value it must throw, naming the field and the
        // value that was expected.
        asserterror CfmHeader.TestField("Max Quantity", 99);
        Assert.ExpectedTestFieldError('Max Quantity', '99');
    end;
}
