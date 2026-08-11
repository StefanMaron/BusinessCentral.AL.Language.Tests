// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: CFV Line (60940), CFV Header (60941)
//
// A CalcFormula where-condition whose `field(...)` names a field that is ITSELF a FlowField:
//
//   CalcFormula = sum("CFV Line".Amount where("Doc No."    = field("No."),
//                                             "Ref Amount" = field("Total Amount")));
//
// "Total Amount" is a FlowField on the same table, so BC cannot read the condition's value out
// of the record buffer -- it calculates "Total Amount" first and filters the source rows on the
// result. Two consequences are asserted below and neither survives a buffer read:
//
//   * the dependent FlowField is correct even when the driver was never CalcFields'd on that
//     record instance (a buffer read yields 0, which selects no rows at all), and
//   * changing the source rows changes the driver, and therefore changes the dependent value --
//     the condition tracks the recalculated total, it is not pinned to a first reading.
//
// The seeded rows are chosen so that dropping the condition (123), dropping the parent link
// (1119) and reading a stale zero (0) each land on a DIFFERENT number from the correct 120.
//
// The last test covers the other half of that dispatch: a formula whose condition references
// the very FlowField being calculated is unresolvable, and BC raises its recursion error
// rather than descending until the stack is exhausted.
codeunit 60942 "CFV Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        CfvLine: Record "CFV Line";
        CfvHeader: Record "CFV Header";
    begin
        CfvLine.Reset();
        CfvLine.DeleteAll();
        CfvHeader.Reset();
        CfvHeader.DeleteAll();

        AddHeader('D1');
        AddHeader('D2');

        // D1 totals 123. Two of its lines carry a "Ref Amount" equal to that total, so the
        // dependent FlowFields see 100 + 20 = 120 over two rows.
        AddLine(1, 'D1', 100, 123);
        AddLine(2, 'D1', 20, 123);
        AddLine(3, 'D1', 3, 999);

        // D2 totals 1000, and only its second line matches that total. Its first line carries
        // D1's total instead: a dependent FlowField that recalculated the driver on the wrong
        // record would answer 999 here rather than 1.
        AddLine(4, 'D2', 999, 123);
        AddLine(5, 'D2', 1, 1000);
    end;

    local procedure AddHeader(No: Code[20])
    var
        CfvHeader: Record "CFV Header";
    begin
        CfvHeader.Init();
        CfvHeader."No." := No;
        CfvHeader.Insert(false);
    end;

    local procedure AddLine(EntryNo: Integer; DocNo: Code[20]; Amt: Decimal; RefAmt: Decimal)
    var
        CfvLine: Record "CFV Line";
    begin
        CfvLine.Init();
        CfvLine."Entry No." := EntryNo;
        CfvLine."Doc No." := DocNo;
        CfvLine.Amount := Amt;
        CfvLine."Ref Amount" := RefAmt;
        CfvLine.Insert(false);
    end;

    [Test]
    procedure Record_CalcFields_FieldOnAFlowField_FiltersOnTheCalculatedValue()
    var
        CfvHeader: Record "CFV Header";
    begin
        // [GIVEN] D1 totals 123, and two of its three lines carry "Ref Amount" = 123.
        Initialize();
        CfvHeader.Get('D1');

        // [WHEN] Driver and dependents are calculated together.
        CfvHeader.CalcFields("Total Amount", "Matched Amount", "Matched Count");

        // [THEN] The driver is the plain parent-link total...
        Assert.AreEqual(123, CfvHeader."Total Amount",
            'the driving FlowField must total every D1 line');

        // [THEN] ...and the dependent sums only the lines whose "Ref Amount" equals it.
        // 123 is the value a dropped condition gives, 1119 the value a dropped parent link
        // gives, and 0 the value a stale buffer read of "Total Amount" gives.
        Assert.AreEqual(120, CfvHeader."Matched Amount",
            'field("Total Amount") must filter "Ref Amount" on the calculated total');
        Assert.AreEqual(2, CfvHeader."Matched Count",
            'the same condition must narrow a count() formula to the two matching lines');
    end;

    [Test]
    procedure Record_CalcFields_FieldOnAFlowField_DriverNotCalculatedFirst_StillFilters()
    var
        CfvHeader: Record "CFV Header";
    begin
        // [GIVEN] A freshly read D1 whose "Total Amount" has never been calculated.
        Initialize();
        CfvHeader.Get('D1');
        Assert.AreEqual(0, CfvHeader."Total Amount",
            'an uncalculated FlowField reads as 0 before CalcFields');

        // [WHEN] Only the dependent FlowField is calculated.
        CfvHeader.CalcFields("Matched Amount");

        // [THEN] The condition still filters on 123, not on the uncalculated 0 -- which would
        // have matched no line and produced 0.
        Assert.AreEqual(120, CfvHeader."Matched Amount",
            'the referenced FlowField must be calculated to resolve the condition');
    end;

    [Test]
    procedure Record_CalcFields_FieldOnAFlowField_IsEvaluatedPerRecord()
    var
        CfvHeader: Record "CFV Header";
    begin
        // [GIVEN] D2 totals 1000, and its only matching line is worth 1.
        Initialize();
        CfvHeader.Get('D2');

        // [WHEN] The same pair of FlowFields is calculated on the second document.
        CfvHeader.CalcFields("Total Amount", "Matched Amount", "Matched Count");

        // [THEN] The condition uses D2's own total. 999 is the value D1's total would select
        // here, so the driver is not shared between records.
        Assert.AreEqual(1000, CfvHeader."Total Amount",
            'D2 must total its own lines');
        Assert.AreEqual(1, CfvHeader."Matched Amount",
            'the condition must filter on D2''s total, not on D1''s');
        Assert.AreEqual(1, CfvHeader."Matched Count",
            'exactly one D2 line carries "Ref Amount" = 1000');
    end;

    [Test]
    procedure Record_CalcFields_FieldOnAFlowField_ChangingTheDriverChangesTheDependent()
    var
        CfvHeader: Record "CFV Header";
    begin
        // [GIVEN] D1 currently totals 123 and matches 120 over two lines.
        Initialize();
        CfvHeader.Get('D1');
        CfvHeader.CalcFields("Matched Amount", "Matched Count");
        Assert.AreEqual(120, CfvHeader."Matched Amount",
            'the starting value must be the two lines carrying 123');

        // [WHEN] A line worth 7 is added, moving D1's total to 130 -- and that new line is the
        // only one carrying "Ref Amount" = 130.
        AddLine(6, 'D1', 7, 130);
        CfvHeader.CalcFields("Total Amount", "Matched Amount", "Matched Count");

        // [THEN] The driver moved...
        Assert.AreEqual(130, CfvHeader."Total Amount",
            'adding a line must raise the driving total to 130');

        // [THEN] ...and the dependent followed it onto a different set of lines entirely.
        // A value pinned to the earlier reading would still answer 120.
        Assert.AreEqual(7, CfvHeader."Matched Amount",
            'the condition must follow the recalculated total onto the new line');
        Assert.AreEqual(1, CfvHeader."Matched Count",
            'only the new line carries "Ref Amount" = 130');
    end;

    [Test]
    procedure Record_CalcFields_SelfReferencingFormula_RaisesTheRecursionError()
    var
        CfvHeader: Record "CFV Header";
    begin
        // [GIVEN] "Self Ref Amount" is a FlowField whose where-condition names itself.
        Initialize();
        CfvHeader.Get('D1');

        // [WHEN] [THEN] Calculating it cannot terminate, so BC refuses it outright rather
        // than recursing until the stack is exhausted.
        asserterror CfvHeader.CalcFields("Self Ref Amount");
        Assert.ExpectedError('This can be caused by recursive function calls');

        // [THEN] The refusal is specific to that one formula -- the other FlowFields still
        // calculate. Re-seeding first is not optional: the error rolled the write
        // transaction back past this test's own Initialize(), so the rows are whatever the
        // previous test committed until Initialize() runs again.
        Initialize();
        Clear(CfvHeader);
        CfvHeader.Get('D1');
        CfvHeader.CalcFields("Matched Amount");
        Assert.AreEqual(120, CfvHeader."Matched Amount",
            'a refused self-referencing formula must not disturb the other FlowFields');
    end;

    [Test]
    procedure Record_CalcFields_MutuallyReferencingFormulas_RaiseTheRecursionError()
    var
        CfvHeader: Record "CFV Header";
    begin
        // [GIVEN] "Cycle A" reads "Cycle B" and "Cycle B" reads "Cycle A". Neither names
        // itself, so the cycle is only visible once the resolution has recursed.
        Initialize();
        CfvHeader.Get('D1');

        // [WHEN] [THEN] The recursion is bounded and reported, not run until the stack dies.
        asserterror CfvHeader.CalcFields("Cycle A");
        Assert.ExpectedError('This can be caused by recursive function calls');

        // [THEN] Entering the cycle from its other end is refused the same way.
        Clear(CfvHeader);
        CfvHeader.Get('D1');
        asserterror CfvHeader.CalcFields("Cycle B");
        Assert.ExpectedError('This can be caused by recursive function calls');

        // [THEN] And the session survives it -- an unrelated FlowField still calculates.
        // Re-seed first: each error above rolled the write transaction back past this
        // test's own Initialize().
        Initialize();
        Clear(CfvHeader);
        CfvHeader.Get('D1');
        CfvHeader.CalcFields("Total Amount");
        Assert.AreEqual(123, CfvHeader."Total Amount",
            'a bounded recursion must leave the rest of the table calculable');
    end;
}
