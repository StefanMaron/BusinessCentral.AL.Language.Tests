// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: CFM Line (60440), CFM Header (60441)
// BC versions: 27.5+
//
// BC has a rule that a FlowField and the source field its CalcFormula aggregates must have
// the SAME type. "CFM Tests".Record_CalcFields_Average_FlowFieldTypeDiffersFromSource_Throws
// pins one instance of it -- an average() of an Integer source into a Decimal FlowField. This
// file generalises that single observation into the rule itself, because one instance leaves
// several readings open:
//
//   * that it is average()-specific          -- excluded here by pinning sum() as well
//   * that only widening is refused          -- excluded by pinning Decimal -> Integer
//   * that Decimal vs Integer is the issue   -- excluded by pinning Duration -> Decimal
//                                               and Integer -> BigInteger
//   * that CalcFields refuses lazily, field  -- excluded by pinning that a valid FlowField
//     by field                                  named alongside an invalid one is not
//                                               calculated either
//
// The refusal is a RUNTIME one. For sum() and average() the AL compiler does not check that
// the FlowField and its source share a type: every "Bad ..." field below compiles with no
// diagnostic and publishes, and the error appears only when the field is calculated.
//
// WHY ONLY sum()/average() IS PINNED HERE. BC's runtime validator raises five refusals in
// total, and the other four have no AL spelling at all -- the AL compiler enforces the
// identical rules statically, so no .al file can produce metadata that reaches them:
//
//   count() into a non-Integer FlowField           -> AL0202 at compile time
//   sum()/average() over a non-numeric source      -> AL0203 at compile time
//   exist() into a non-Boolean FlowField           -> AL0201 at compile time
//   min()/max()/lookup() with mismatched types     -> AL0427 at compile time
//
// Twenty-two spellings of those four were tried against alc (Duration, Option, Boolean,
// Code, Text, DateTime, BigInteger and Date targets and sources); every one was rejected
// before it could publish. They are therefore unreachable from a test, not merely unpinned.
//
// Seeded data:
//
//   Doc  Entry  Amount  Qty  Posting Date   Elapsed
//   D1   1        40      3  2024-01-10       1 hour
//   D1   2       -10      4  2024-02-10       2 hours
//   D1   3        75      6  2024-03-10       3 hours
//   D1   4        20      8  2024-04-10       4 hours
//   D3   (no lines)
codeunit 60443 "CFM Validation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // One hour, in milliseconds. Duration literals are not an AL thing, so the Duration
    // source values are built from this.
    procedure OneHour(): Duration
    begin
        exit(60 * 60 * 1000);
    end;

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
        AddHeader('D3');

        // D1: four real rows, so no refusal below can be an empty-source-set short circuit.
        // Amounts sum to 125, quantities to 21, Elapsed to 10 hours.
        AddLine(1, 'D1', 40, 3, 20240110D, 1 * OneHour());
        AddLine(2, 'D1', -10, 4, 20240210D, 2 * OneHour());
        AddLine(3, 'D1', 75, 6, 20240310D, 3 * OneHour());
        AddLine(4, 'D1', 20, 8, 20240410D, 4 * OneHour());

        // D3 deliberately has no lines.
    end;

    local procedure AddHeader(No: Code[20])
    var
        CfmHeader: Record "CFM Header";
    begin
        CfmHeader.Init();
        CfmHeader."No." := No;
        CfmHeader.Insert(false);
    end;

    local procedure AddLine(EntryNo: Integer; DocNo: Code[20]; Amt: Decimal; Qty: Integer; PostingDate: Date; El: Duration)
    var
        CfmLine: Record "CFM Line";
    begin
        CfmLine.Init();
        CfmLine."Entry No." := EntryNo;
        CfmLine."Doc No." := DocNo;
        CfmLine.Amount := Amt;
        CfmLine.Quantity := Qty;
        CfmLine."Posting Date" := PostingDate;
        CfmLine.Elapsed := El;
        CfmLine.Insert(false);
    end;

    [Test]
    procedure Record_CalcFields_Sum_FlowFieldTypeDiffersFromSource_Throws()
    var
        CfmHeader: Record "CFM Header";
        ErrorText: Text;
    begin
        // [GIVEN] "Bad Sum Qty Decimal" is a DECIMAL FlowField summing the INTEGER
        // "CFM Line".Quantity. The corpus already pins the average() version of this shape;
        // sum() is a different CalculationMethod, so it is pinned on its own.
        Initialize();
        CfmHeader.Get('D1');

        // [GIVEN] The precondition that makes this about the TYPES: a correctly typed sum()
        // over the same rows calculates, and gives 125.
        CfmHeader.CalcFields("Total Amount");
        Assert.AreEqual(125, CfmHeader."Total Amount",
            'precondition: sum() into a correctly typed FlowField must calculate');

        // [WHEN]
        asserterror CfmHeader.CalcFields("Bad Sum Qty Decimal");

        // [THEN] BC refuses, naming both fields, both tables and both types.
        ErrorText := GetLastErrorText();
        Assert.ExpectedError('The following fields must have the same type');
        Assert.ExpectedMessage('Field: Bad Sum Qty Decimal <-- Quantity', ErrorText);
        Assert.ExpectedMessage('Table: CFM Header <-- CFM Line', ErrorText);
        Assert.ExpectedMessage('Type: Decimal <-- Integer', ErrorText);
    end;

    [Test]
    procedure Record_CalcFields_SumAndAverage_NarrowingTypeMismatch_Throws()
    var
        CfmHeader: Record "CFM Header";
        ErrorText: Text;
    begin
        // [GIVEN] The already-pinned instance widens (Integer source, Decimal FlowField).
        // These two narrow: a DECIMAL source into an INTEGER FlowField. If BC only objected
        // to a FlowField that cannot hold its source's values, narrowing is the direction
        // that would be refused and widening the one that would be allowed -- so pinning
        // both directions is what shows the rule is about type IDENTITY.
        Initialize();
        CfmHeader.Get('D1');

        // [GIVEN] Precondition: both methods calculate over this source when correctly typed.
        CfmHeader.CalcFields("Total Amount", "Average Amount");
        Assert.AreEqual(125, CfmHeader."Total Amount", 'precondition: sum() must calculate');
        Assert.AreEqual(31.25, CfmHeader."Average Amount", 'precondition: average() must calculate');

        // [WHEN] [THEN] sum() narrowing.
        asserterror CfmHeader.CalcFields("Bad Sum Amount Int");
        ErrorText := GetLastErrorText();
        Assert.ExpectedError('The following fields must have the same type');
        Assert.ExpectedMessage('Field: Bad Sum Amount Int <-- Amount', ErrorText);
        Assert.ExpectedMessage('Type: Integer <-- Decimal', ErrorText);

        // [WHEN] [THEN] average() narrowing, asserted separately so an implementation that
        // checks only one of the two methods cannot pass.
        asserterror CfmHeader.CalcFields("Bad Avg Amount Int");
        ErrorText := GetLastErrorText();
        Assert.ExpectedError('The following fields must have the same type');
        Assert.ExpectedMessage('Field: Bad Avg Amount Int <-- Amount', ErrorText);
        Assert.ExpectedMessage('Type: Integer <-- Decimal', ErrorText);
    end;

    [Test]
    procedure Record_CalcFields_Average_DurationSourceIntoDecimal_Throws()
    var
        CfmHeader: Record "CFM Header";
        ErrorText: Text;
        TenHours: Duration;
    begin
        // [GIVEN] Duration is one of the four types BC will sum and average, so a Duration
        // source cannot be refused for being non-numeric. "Bad Avg Elapsed Decimal" averages
        // it into a Decimal, which leaves the type difference as the only thing wrong.
        Initialize();
        CfmHeader.Get('D1');

        // [GIVEN] Precondition: the same Duration source, aggregated into a Duration
        // FlowField, calculates -- and to ten hours, not zero and not the row count.
        CfmHeader.CalcFields("Total Elapsed");
        TenHours := 10 * OneHour();
        Assert.AreEqual(TenHours, CfmHeader."Total Elapsed",
            'precondition: sum() over a Duration source must calculate into a Duration FlowField');

        // [WHEN]
        asserterror CfmHeader.CalcFields("Bad Avg Elapsed Decimal");

        // [THEN]
        ErrorText := GetLastErrorText();
        Assert.ExpectedError('The following fields must have the same type');
        Assert.ExpectedMessage('Field: Bad Avg Elapsed Decimal <-- Elapsed', ErrorText);
        Assert.ExpectedMessage('Type: Decimal <-- Duration', ErrorText);
    end;

    [Test]
    procedure Record_CalcFields_Sum_IntegerSourceIntoBigInteger_Throws()
    var
        CfmHeader: Record "CFM Header";
        ErrorText: Text;
    begin
        // [GIVEN] "Bad Sum Qty BigInt" sums the INTEGER "CFM Line".Quantity into a
        // BIGINTEGER FlowField. Both are integer types and a BigInteger can hold every
        // Integer, so nothing can be lost -- this is the case that shows "the same type"
        // means the type itself, not a type that is merely compatible.
        Initialize();
        CfmHeader.Get('D1');

        // [GIVEN] Precondition: a BigInteger FlowField is not refused as such -- count()
        // into an Integer over the same rows calculates and gives 4.
        CfmHeader.CalcFields("Line Count");
        Assert.AreEqual(4, CfmHeader."Line Count", 'precondition: count() must calculate');

        // [WHEN]
        asserterror CfmHeader.CalcFields("Bad Sum Qty BigInt");

        // [THEN]
        ErrorText := GetLastErrorText();
        Assert.ExpectedError('The following fields must have the same type');
        Assert.ExpectedMessage('Field: Bad Sum Qty BigInt <-- Quantity', ErrorText);
        Assert.ExpectedMessage('Type: BigInteger <-- Integer', ErrorText);
    end;

    [Test]
    procedure Record_CalcFields_InvalidFlowFieldAlongsideValidOne_CalculatesNeither()
    var
        CfmHeader: Record "CFM Header";
    begin
        // [GIVEN] D1, where the legal "Total Amount" is 125 and "Line Count" is 4.
        Initialize();
        CfmHeader.Get('D1');

        // [WHEN] One CalcFields call names two VALID FlowFields and an INVALID one.
        asserterror CfmHeader.CalcFields("Total Amount", "Line Count", "Bad Sum Qty Decimal");

        // [THEN] The call is refused.
        Assert.ExpectedError('The following fields must have the same type');

        // [THEN] And neither valid field was left calculated. The record variable is NOT
        // re-read here -- re-reading would reset every FlowField to 0 and make this vacuous
        // -- so these read the same buffer the refused call was handed. BC validates every
        // FlowField in the call before it aggregates any of them, so a refused CalcFields
        // writes NOTHING, not even the part that would have succeeded on its own.
        Assert.AreEqual(0, CfmHeader."Total Amount",
            'a refused CalcFields must not leave the valid sum() calculated');
        Assert.AreEqual(0, CfmHeader."Line Count",
            'a refused CalcFields must not leave the valid count() calculated');

        // [THEN] The control: named without the invalid field, those same two calculate to
        // 125 and 4 -- so the zeros above are the refusal and not a broken fixture.
        //
        // The seed is laid down again first. asserterror rolls back the write transaction,
        // which takes the four D1 lines with it, so a control run against the post-error
        // database would read 0 for a reason that has nothing to do with the refusal. (The
        // rollback does NOT weaken the two assertions above: it discards database rows, not
        // the record variable's FlowField buffer, so a BC that had aggregated "Total Amount"
        // before throwing would still be holding 125 there.)
        Initialize();
        CfmHeader.Get('D1');
        CfmHeader.CalcFields("Total Amount", "Line Count");
        Assert.AreEqual(125, CfmHeader."Total Amount",
            'the valid sum() must calculate when not named alongside an invalid FlowField');
        Assert.AreEqual(4, CfmHeader."Line Count",
            'the valid count() must calculate when not named alongside an invalid FlowField');
    end;
}
