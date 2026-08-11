// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: CFF Line (60930), CFF Header (60931)
//
// The flow-filter family of CalcFormula where-conditions:
//
//   "Posting Date" = field("Date Filter")              -- the caller's filter, applied whole
//   "Posting Date" = field(upperlimit("Date Filter"))  -- only that filter's upper bound
//   "Account No."  = field(filter("Account Totaling")) -- the parent field's VALUE, read as a
//                                                         filter expression
//
// These are not field-to-field equality links: two of them read runtime FILTER state rather
// than a stored value, and the third reads a value but parses it as a filter. Every test below
// asserts both directions -- narrowing the filter must change the total, and clearing it must
// widen the total back -- so an implementation that ignores the condition, or that applies it
// as an equality against a blank, fails.
codeunit 60932 "CFF Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        CffLine: Record "CFF Line";
        CffHeader: Record "CFF Header";
    begin
        CffLine.Reset();
        CffLine.DeleteAll();
        CffHeader.Reset();
        CffHeader.DeleteAll();

        AddHeader('D1');
        AddHeader('D2');

        // D1: 100 in January, 20 in February, 3 in March -- 123 in total.
        AddLine(1, 'D1', 20240110D, 100, 'A1');
        AddLine(2, 'D1', 20240210D, 20, 'A2');
        AddLine(3, 'D1', 20240310D, 3, 'A1');

        // A second document. Never part of a D1 total unless a condition is dropped or a
        // totaling filter deliberately reaches it.
        AddLine(4, 'D2', 20240215D, 999, 'A1');
    end;

    local procedure AddHeader(No: Code[20])
    var
        CffHeader: Record "CFF Header";
    begin
        CffHeader.Init();
        CffHeader."No." := No;
        CffHeader.Insert(false);
    end;

    local procedure AddLine(EntryNo: Integer; DocNo: Code[20]; PostingDate: Date; Amt: Decimal; AccountNo: Code[20])
    var
        CffLine: Record "CFF Line";
    begin
        CffLine.Init();
        CffLine."Entry No." := EntryNo;
        CffLine."Doc No." := DocNo;
        CffLine."Posting Date" := PostingDate;
        CffLine.Amount := Amt;
        CffLine."Account No." := AccountNo;
        CffLine.Insert(false);
    end;

    local procedure SetTotaling(No: Code[20]; AccountTotaling: Text; DocTotaling: Text)
    var
        CffHeader: Record "CFF Header";
    begin
        CffHeader.Get(No);
        CffHeader."Account Totaling" := CopyStr(AccountTotaling, 1, MaxStrLen(CffHeader."Account Totaling"));
        CffHeader."Doc Totaling" := CopyStr(DocTotaling, 1, MaxStrLen(CffHeader."Doc Totaling"));
        CffHeader.Modify(false);
    end;

    [Test]
    procedure Record_CalcFields_FieldFlowFilter_AppliesTheCallersFilterToTheSourceRows()
    var
        CffHeader: Record "CFF Header";
    begin
        // [GIVEN] Three D1 lines, one per month, totalling 123.
        Initialize();
        CffHeader.Get('D1');

        // [WHEN] The caller narrows the flow filter to January.
        CffHeader.SetRange("Date Filter", 20240101D, 20240131D);
        CffHeader.CalcFields("Total Amount", "Period Amount", "Period Count");

        // [THEN] The unfiltered FlowField is untouched by the flow filter...
        Assert.AreEqual(123, CffHeader."Total Amount",
            'a flow filter must not affect a FlowField that does not reference it');

        // [THEN] ...and the one that references it sees only the January line. 123 is the
        // value a dropped condition gives; 0 is the value an equality against a blank date
        // gives.
        Assert.AreEqual(100, CffHeader."Period Amount",
            'field("Date Filter") must apply the caller''s range to "Posting Date"');
        Assert.AreEqual(1, CffHeader."Period Count",
            'the same flow filter must narrow a count() formula too');

        // [WHEN] The caller widens the flow filter to January..February.
        CffHeader.SetRange("Date Filter", 20240101D, 20240229D);
        CffHeader.CalcFields("Period Amount", "Period Count");

        // [THEN] The February line joins in, and D2's 999 still does not.
        Assert.AreEqual(120, CffHeader."Period Amount",
            'widening the flow filter must widen the aggregate to 100 + 20');
        Assert.AreEqual(2, CffHeader."Period Count",
            'widening the flow filter must raise the count to two lines');
    end;

    [Test]
    procedure Record_CalcFields_FieldFlowFilter_NoFilterSet_ImposesNoConstraint()
    var
        CffHeader: Record "CFF Header";
    begin
        // [GIVEN] No flow filter at all.
        Initialize();
        CffHeader.Get('D1');

        // [WHEN] [THEN] An unset flow filter is not "= blank date": it drops out entirely.
        CffHeader.CalcFields("Period Amount");
        Assert.AreEqual(123, CffHeader."Period Amount",
            'an unset flow filter must impose no constraint at all');

        // [WHEN] The filter is set and then cleared again.
        CffHeader.SetRange("Date Filter", 20240101D, 20240131D);
        CffHeader.CalcFields("Period Amount");
        Assert.AreEqual(100, CffHeader."Period Amount",
            'setting the flow filter must narrow the aggregate');

        CffHeader.SetRange("Date Filter");
        CffHeader.CalcFields("Period Amount");

        // [THEN] Clearing widens it back -- the value tracks the filter, it is not cached.
        Assert.AreEqual(123, CffHeader."Period Amount",
            'clearing the flow filter must widen the aggregate back to every line');
    end;

    [Test]
    procedure Record_CalcFields_FieldUpperLimit_AppliesOnlyTheUpperBoundOfTheFlowFilter()
    var
        CffHeader: Record "CFF Header";
    begin
        // [GIVEN] A flow filter covering February only.
        Initialize();
        CffHeader.Get('D1');
        CffHeader.SetRange("Date Filter", 20240201D, 20240229D);

        // [WHEN]
        CffHeader.CalcFields("Period Amount", "Balance at Date");

        // [THEN] field(...) applies the whole range: February's line only.
        Assert.AreEqual(20, CffHeader."Period Amount",
            'field("Date Filter") must apply both ends of the range');

        // [THEN] field(upperlimit(...)) applies only "..29-02-2024", so January is included
        // and March is not. This is the whole point of upperlimit: a running balance.
        Assert.AreEqual(120, CffHeader."Balance at Date",
            'field(upperlimit("Date Filter")) must keep rows before the range start');
        Assert.AreNotEqual(CffHeader."Period Amount", CffHeader."Balance at Date",
            'upperlimit() must not behave like the full range filter');

        // [WHEN] The flow filter is cleared.
        CffHeader.SetRange("Date Filter");
        CffHeader.CalcFields("Balance at Date");

        // [THEN] There is no upper bound left, so every line counts.
        Assert.AreEqual(123, CffHeader."Balance at Date",
            'an unset flow filter must leave upperlimit() unconstrained');
    end;

    [Test]
    procedure Record_CalcFields_FieldFilter_ReadsTheParentFieldValueAsAFilterExpression()
    var
        CffHeader: Record "CFF Header";
    begin
        // [GIVEN] D1's lines are on accounts A1 (100 and 3) and A2 (20).
        Initialize();

        // [WHEN] The totaling field names a single account.
        SetTotaling('D1', 'A1', '');
        CffHeader.Get('D1');
        CffHeader.CalcFields("Totaling Amount");

        // [THEN] Only that account's lines are summed.
        Assert.AreEqual(103, CffHeader."Totaling Amount",
            'field(filter("Account Totaling")) must filter "Account No." by the stored value');

        // [WHEN] The value is a filter EXPRESSION, not a single value.
        SetTotaling('D1', 'A1|A2', '');
        CffHeader.Get('D1');
        CffHeader.CalcFields("Totaling Amount");

        // [THEN] The alternation is honoured -- proof the value is parsed, not compared.
        Assert.AreEqual(123, CffHeader."Totaling Amount",
            'the stored value must be parsed as a filter expression, not matched as equality');

        // [WHEN] The value matches no line.
        SetTotaling('D1', 'A9', '');
        CffHeader.Get('D1');
        CffHeader.CalcFields("Totaling Amount");

        // [THEN] Nothing is aggregated -- the exclusion direction.
        Assert.AreEqual(0, CffHeader."Totaling Amount",
            'a totaling filter that matches no line must sum to zero');

        // [WHEN] The value is blank.
        SetTotaling('D1', '', '');
        CffHeader.Get('D1');
        CffHeader.CalcFields("Totaling Amount");

        // [THEN] A blank filter value imposes nothing, exactly like an unset flow filter.
        Assert.AreEqual(123, CffHeader."Totaling Amount",
            'a blank totaling value must impose no constraint');
    end;

    [Test]
    procedure Record_CalcFields_FieldFilter_OnASourceFieldAlreadyLinked_ReplacesTheLink()
    var
        CffHeader: Record "CFF Header";
    begin
        // [GIVEN] "Doc Totaling Amount" constrains "Doc No." twice: once by the parent link
        // and once by field(filter("Doc Totaling")).
        Initialize();

        // [WHEN] The totaling value is blank.
        SetTotaling('D1', '', '');
        CffHeader.Get('D1');
        CffHeader.CalcFields("Doc Totaling Amount");

        // [THEN] Only the parent link is left, so this is D1's own total.
        Assert.AreEqual(123, CffHeader."Doc Totaling Amount",
            'with no totaling value the plain field("No.") link must still apply');

        // [WHEN] The totaling value names a DIFFERENT document.
        SetTotaling('D1', '', 'D2');
        CffHeader.Get('D1');
        CffHeader.CalcFields("Doc Totaling Amount");

        // [THEN] The totaling filter takes over from the parent link on the same source
        // field -- D1 sums D2's line. ANDing the two would give 0 instead.
        Assert.AreEqual(999, CffHeader."Doc Totaling Amount",
            'a totaling filter must replace, not intersect, the link on the same source field');
    end;

    [Test]
    procedure Record_FindFirst_FlowFilterSet_DoesNotConstrainTheRecordItself()
    var
        CffHeader: Record "CFF Header";
    begin
        // [GIVEN] A flow filter no line can satisfy.
        Initialize();
        CffHeader.SetRange("Date Filter", 20990101D, 20991231D);

        // [WHEN] [THEN] The header itself is still readable: a FlowFilter field holds no data
        // and never filters its own table.
        Assert.IsTrue(CffHeader.FindFirst(),
            'a filter on a FlowFilter field must not exclude rows of its own table');
        Assert.AreEqual(2, CffHeader.Count(),
            'Count() must ignore the flow filter');

        // [THEN] ...while the FlowField that reads it sees nothing in that window.
        CffHeader.Get('D1');
        CffHeader.CalcFields("Total Amount", "Period Amount");
        Assert.AreEqual(123, CffHeader."Total Amount",
            'the unfiltered FlowField is unaffected');
        Assert.AreEqual(0, CffHeader."Period Amount",
            'a flow filter matching no source row must aggregate nothing');
    end;
}
