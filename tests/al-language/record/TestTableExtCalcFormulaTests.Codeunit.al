// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: TXC Cust Stats Ext (60798), TXC ILE Ext (60799),
//                TXC Parent (60809), TXC Line (60819)
//
// A CalcFormula that names a field a TABLEEXTENSION added, rather than one the extended table
// declares itself. Three positions, one per test, plus three controls:
//
//   parent side  -- where("Posting Date" = field("TXC Date Filter")), the FlowFilter added by
//                   the same extension that declares the FlowField;
//   source field -- sum("TXC Line"."TXC Ext Weight" ...), added by a second
//                   tableextension to the target table;
//   target arm   -- where("TXC Ext Weight" = const(7.5)) on that same added field.
//
// Every number below is a total that a DROPPED where-arm cannot produce: the seeded rows give
// 390 unfiltered, 140 for January, 100 for January plus one item, and 3 for the quantity at
// one weight against 8 for both. A formula that silently ignores a condition it could not
// resolve answers with the wider number and fails here.
//
// The rows live in tables this app declares, so the suite needs no permission on any Business
// Central table and no seeded company data: Initialize() empties both fixture tables outright.
// The extension fields are the subject; the tables underneath them are only the vehicle, and
// an extension over an app's own table exercises the same resolution path (the corpus already
// relies on that shape in "ALT Keyed Ext", "ALT Universal Validated Ext" and
// "ALT Triggered Order Ext").
codeunit 60823 "TXC Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        C1Lbl: Label 'TXC-C1', Locked = true;
        C2Lbl: Label 'TXC-C2', Locked = true;
        I1Lbl: Label 'TXC-I1', Locked = true;
        I2Lbl: Label 'TXC-I2', Locked = true;

    local procedure Initialize()
    begin
        Cleanup();

        AddParent(C1Lbl);
        AddParent(C2Lbl);

        // C1: 100 + 40 in January, 250 in February -- 390 in total, 140 in January, and 100
        // for January restricted to item I1.
        AddLine(1, C1Lbl, I1Lbl, 20260101D, 100, 0, 0);
        AddLine(2, C1Lbl, I2Lbl, 20260101D, 40, 0, 0);
        AddLine(3, C1Lbl, I1Lbl, 20260201D, 250, 0, 0);
        // A second parent, so a dropped "Source No." arm cannot pass either.
        AddLine(4, C2Lbl, I1Lbl, 20260101D, 999, 0, 0);

        // C1: weights 7.5 and 2.5 (10 in total), quantities 3 and 5 (8 in total).
        AddLine(5, C1Lbl, I1Lbl, 20260101D, 0, 7.5, 3);
        AddLine(6, C1Lbl, I1Lbl, 20260201D, 0, 2.5, 5);
        AddLine(7, C2Lbl, I1Lbl, 20260101D, 0, 99, 7);
    end;

    local procedure Cleanup()
    var
        TXCParent: Record "TXC Parent";
        TXCLine: Record "TXC Line";
    begin
        TXCParent.DeleteAll(false);
        TXCLine.DeleteAll(false);
    end;

    local procedure AddParent(No: Code[20])
    var
        TXCParent: Record "TXC Parent";
    begin
        TXCParent.Init();
        TXCParent."No." := No;
        TXCParent.Insert(false);
    end;

    local procedure AddLine(EntryNo: Integer; SourceNo: Code[20]; ItemNo: Code[20]; PostingDate: Date; Amt: Decimal; Weight: Decimal; Qty: Decimal)
    var
        TXCLine: Record "TXC Line";
    begin
        TXCLine.Init();
        TXCLine."Entry No." := EntryNo;
        TXCLine."Source No." := SourceNo;
        TXCLine."Item No." := ItemNo;
        TXCLine."Posting Date" := PostingDate;
        TXCLine."Sales Amount" := Amt;
        TXCLine."TXC Ext Weight" := Weight;
        TXCLine.Quantity := Qty;
        TXCLine.Insert(false);
    end;

    [Test]
    procedure Record_CalcFields_ExtensionFlowFieldWithoutFlowFilter_ScopesToItsOwnParentRow()
    var
        TXCParent: Record "TXC Parent";
    begin
        // [GIVEN] Two parents with lines, 390 of them C1's.
        Initialize();
        TXCParent.Get(C1Lbl);

        // [WHEN] The FlowField carries the plain field("No.") arm only.
        TXCParent.CalcFields("TXC Sales Amount Total");

        // [THEN] C1's own rows, and not C2's 999.
        Assert.AreEqual(390, TXCParent."TXC Sales Amount Total",
            'a tableextension FlowField must sum only the rows its field("No.") arm links');

        Cleanup();
    end;

    [Test]
    procedure Record_CalcFields_WhereArmOnAnExtensionFlowFilter_NarrowsTheSum()
    var
        TXCParent: Record "TXC Parent";
    begin
        // [GIVEN] 390 across two months for C1.
        Initialize();
        TXCParent.Get(C1Lbl);

        // [WHEN] The caller narrows the flow filter the SAME EXTENSION added.
        TXCParent.SetRange("TXC Date Filter", 20260101D, 20260101D);
        TXCParent.CalcFields("TXC Sales Amount");

        // [THEN] Only the January rows. 390 is the number a dropped arm gives; 0 is the
        // number an equality against a blank date gives.
        Assert.AreEqual(140, TXCParent."TXC Sales Amount",
            'field("TXC Date Filter") must apply the caller''s range to "Posting Date"');

        // [WHEN] The filter is cleared again.
        TXCParent.SetRange("TXC Date Filter");
        TXCParent.CalcFields("TXC Sales Amount");

        // [THEN] The aggregate widens back, so the narrowing above was the filter's doing.
        Assert.AreEqual(390, TXCParent."TXC Sales Amount",
            'clearing an extension flow filter must widen the aggregate back to the total');

        Cleanup();
    end;

    [Test]
    procedure Record_CalcFields_TwoExtensionFlowFilters_BothNarrowTheSum()
    var
        TXCParent: Record "TXC Parent";
    begin
        // [GIVEN] January holds 100 on item I1 and 40 on item I2.
        Initialize();
        TXCParent.Get(C1Lbl);

        // [WHEN] Both extension flow filters are set.
        TXCParent.SetRange("TXC Date Filter", 20260101D, 20260101D);
        TXCParent.SetRange("TXC Item Filter", I1Lbl);
        TXCParent.CalcFields("TXC Sales By Item");

        // [THEN] 100 -- 140 would mean the item arm was dropped, 390 would mean both were.
        Assert.AreEqual(100, TXCParent."TXC Sales By Item",
            'two extension flow filters in one formula must both narrow the aggregate');

        Cleanup();
    end;

    [Test]
    procedure Record_CalcFields_SumOverAnExtensionFieldOnTheTargetTable_Aggregates()
    var
        TXCParent: Record "TXC Parent";
    begin
        // [GIVEN] C1's two weighted lines weigh 7.5 and 2.5; C2's weighs 99.
        Initialize();
        TXCParent.Get(C1Lbl);

        // [WHEN] The formula sums a field a SECOND tableextension added to the target table.
        TXCParent.CalcFields("TXC Weight");

        // [THEN] 10, not 109 and not 0.
        Assert.AreEqual(10, TXCParent."TXC Weight",
            'sum() over a tableextension field on the target table must aggregate it');

        Cleanup();
    end;

    [Test]
    procedure Record_CalcFields_WhereArmOverAnExtensionFieldOnTheTargetTable_Narrows()
    var
        TXCParent: Record "TXC Parent";
    begin
        // [GIVEN] Quantities 3 (weight 7.5) and 5 (weight 2.5) for C1.
        Initialize();
        TXCParent.Get(C1Lbl);

        // [WHEN] A const() where-arm names the extension field on the target table.
        TXCParent.CalcFields("TXC Qty Heavy");

        // [THEN] 3. 8 is what a dropped arm gives.
        Assert.AreEqual(3, TXCParent."TXC Qty Heavy",
            'a where-arm over a tableextension field on the target table must narrow the sum');

        Cleanup();
    end;

    [Test]
    procedure Record_CalcFields_WhereArmOnABaseTableFlowFilter_NarrowsTheSum()
    var
        TXCParent: Record "TXC Parent";
    begin
        // The control for the parent side: the same formula shape with the EXTENDED TABLE's
        // OWN "Base Date Filter" in place of the extension one.
        Initialize();
        TXCParent.Get(C1Lbl);

        TXCParent.SetRange("Base Date Filter", 20260101D, 20260101D);
        TXCParent.CalcFields("TXC Sales Base Filter");

        Assert.AreEqual(140, TXCParent."TXC Sales Base Filter",
            'field("Base Date Filter") -- the extended table''s own flow filter -- must narrow the sum');

        Cleanup();
    end;

    [Test]
    procedure Record_CalcSumsAndSetRange_OnATableExtensionField_ReadTheStoredValues()
    var
        TXCLine: Record "TXC Line";
    begin
        // The control for the target side: the added field is stored, filterable and
        // summable on its own, so a failure above is about resolving it FROM A FORMULA.
        Initialize();

        TXCLine.SetRange("Source No.", C1Lbl);
        TXCLine.CalcSums("TXC Ext Weight");
        Assert.AreEqual(10, TXCLine."TXC Ext Weight",
            'CalcSums over a tableextension field must add its stored values');

        TXCLine.Reset();
        TXCLine.SetRange("Source No.", C1Lbl);
        TXCLine.SetRange("TXC Ext Weight", 7.5);
        Assert.AreEqual(1, TXCLine.Count(),
            'SetRange on a tableextension field must filter on its stored value');

        Cleanup();
    end;
}
