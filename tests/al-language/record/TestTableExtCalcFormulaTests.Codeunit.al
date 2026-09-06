// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: TXC Cust Stats Ext (60821), TXC ILE Ext (60822), Customer (18),
//                Value Entry (5802), Item Ledger Entry (32)
//
// A CalcFormula that names a field a TABLEEXTENSION added, rather than one the extended table
// declares itself. Three positions, one per test, plus three controls:
//
//   parent side  -- where("Posting Date" = field("TXC Date Filter")), the FlowFilter added by
//                   the same extension that declares the FlowField;
//   source field -- sum("Item Ledger Entry"."TXC Ext Weight" ...), added by a second
//                   tableextension to the target table;
//   target arm   -- where("TXC Ext Weight" = const(7.5)) on that same added field.
//
// Every number below is a total that a DROPPED where-arm cannot produce: the seeded rows give
// 390 unfiltered, 140 for January, 100 for January plus one item, and 3 for the quantity at
// one weight against 8 for both. A formula that silently ignores a condition it could not
// resolve answers with the wider number and fails here.
//
// The rows live in Base Application tables, so Initialize() removes only rows this codeunit
// created (its own two customer numbers) and every test removes them again on the way out --
// the suite runs against a CRONUS company that already holds ledger data.
codeunit 60823 "TXC Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        C1Lbl: Label 'TXC-C1', Locked = true;
        C2Lbl: Label 'TXC-C2', Locked = true;
        I1Lbl: Label 'TXC-I1', Locked = true;
        I2Lbl: Label 'TXC-I2', Locked = true;

    local procedure Initialize()
    var
        ValueEntry: Record "Value Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        VeNo: Integer;
        IleNo: Integer;
    begin
        Cleanup();

        AddCustomer(C1Lbl);
        AddCustomer(C2Lbl);

        // Append past whatever the company already holds: both tables are keyed on "Entry No."
        // and CRONUS ships rows in them.
        ValueEntry.Reset();
        if ValueEntry.FindLast() then
            VeNo := ValueEntry."Entry No.";
        ItemLedgerEntry.Reset();
        if ItemLedgerEntry.FindLast() then
            IleNo := ItemLedgerEntry."Entry No.";

        // C1: 100 + 40 in January, 250 in February -- 390 in total, 140 in January, and 100
        // for January restricted to item I1.
        AddValueEntry(VeNo + 1, C1Lbl, I1Lbl, 20260101D, 100);
        AddValueEntry(VeNo + 2, C1Lbl, I2Lbl, 20260101D, 40);
        AddValueEntry(VeNo + 3, C1Lbl, I1Lbl, 20260201D, 250);
        // A second customer, so a dropped "Source No." arm cannot pass either.
        AddValueEntry(VeNo + 4, C2Lbl, I1Lbl, 20260101D, 999);

        // C1: weights 7.5 and 2.5 (10 in total), quantities 3 and 5 (8 in total).
        AddItemLedgerEntry(IleNo + 1, C1Lbl, I1Lbl, 20260101D, 7.5, 3);
        AddItemLedgerEntry(IleNo + 2, C1Lbl, I1Lbl, 20260201D, 2.5, 5);
        AddItemLedgerEntry(IleNo + 3, C2Lbl, I1Lbl, 20260101D, 99, 7);
    end;

    local procedure Cleanup()
    var
        Customer: Record Customer;
        ValueEntry: Record "Value Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        Customer.SetFilter("No.", '%1|%2', C1Lbl, C2Lbl);
        Customer.DeleteAll(false);
        ValueEntry.SetFilter("Source No.", '%1|%2', C1Lbl, C2Lbl);
        ValueEntry.DeleteAll(false);
        ItemLedgerEntry.SetFilter("Source No.", '%1|%2', C1Lbl, C2Lbl);
        ItemLedgerEntry.DeleteAll(false);
    end;

    local procedure AddCustomer(No: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Init();
        Customer."No." := No;
        Customer.Insert(false);
    end;

    local procedure AddValueEntry(EntryNo: Integer; SourceNo: Code[20]; ItemNo: Code[20]; PostingDate: Date; Amt: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.Init();
        ValueEntry."Entry No." := EntryNo;
        ValueEntry."Source No." := SourceNo;
        ValueEntry."Item No." := ItemNo;
        ValueEntry."Posting Date" := PostingDate;
        ValueEntry."Sales Amount (Actual)" := Amt;
        ValueEntry.Insert(false);
    end;

    local procedure AddItemLedgerEntry(EntryNo: Integer; SourceNo: Code[20]; ItemNo: Code[20]; PostingDate: Date; Weight: Decimal; Qty: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := EntryNo;
        ItemLedgerEntry."Source No." := SourceNo;
        ItemLedgerEntry."Item No." := ItemNo;
        ItemLedgerEntry."Posting Date" := PostingDate;
        ItemLedgerEntry."TXC Ext Weight" := Weight;
        ItemLedgerEntry.Quantity := Qty;
        ItemLedgerEntry.Insert(false);
    end;

    [Test]
    procedure Record_CalcFields_ExtensionFlowFieldWithoutFlowFilter_ScopesToItsOwnParentRow()
    var
        Customer: Record Customer;
    begin
        // [GIVEN] Two customers with value entries, 390 of them C1's.
        Initialize();
        Customer.Get(C1Lbl);

        // [WHEN] The FlowField carries the plain field("No.") arm only.
        Customer.CalcFields("TXC Sales Amount Total");

        // [THEN] C1's own rows, and not C2's 999.
        Assert.AreEqual(390, Customer."TXC Sales Amount Total",
            'a tableextension FlowField must sum only the rows its field("No.") arm links');

        Cleanup();
    end;

    [Test]
    procedure Record_CalcFields_WhereArmOnAnExtensionFlowFilter_NarrowsTheSum()
    var
        Customer: Record Customer;
    begin
        // [GIVEN] 390 across two months for C1.
        Initialize();
        Customer.Get(C1Lbl);

        // [WHEN] The caller narrows the flow filter the SAME EXTENSION added.
        Customer.SetRange("TXC Date Filter", 20260101D, 20260101D);
        Customer.CalcFields("TXC Sales Amount");

        // [THEN] Only the January rows. 390 is the number a dropped arm gives; 0 is the
        // number an equality against a blank date gives.
        Assert.AreEqual(140, Customer."TXC Sales Amount",
            'field("TXC Date Filter") must apply the caller''s range to "Posting Date"');

        // [WHEN] The filter is cleared again.
        Customer.SetRange("TXC Date Filter");
        Customer.CalcFields("TXC Sales Amount");

        // [THEN] The aggregate widens back, so the narrowing above was the filter's doing.
        Assert.AreEqual(390, Customer."TXC Sales Amount",
            'clearing an extension flow filter must widen the aggregate back to the total');

        Cleanup();
    end;

    [Test]
    procedure Record_CalcFields_TwoExtensionFlowFilters_BothNarrowTheSum()
    var
        Customer: Record Customer;
    begin
        // [GIVEN] January holds 100 on item I1 and 40 on item I2.
        Initialize();
        Customer.Get(C1Lbl);

        // [WHEN] Both extension flow filters are set.
        Customer.SetRange("TXC Date Filter", 20260101D, 20260101D);
        Customer.SetRange("TXC Item Filter", I1Lbl);
        Customer.CalcFields("TXC Sales By Item");

        // [THEN] 100 -- 140 would mean the item arm was dropped, 390 would mean both were.
        Assert.AreEqual(100, Customer."TXC Sales By Item",
            'two extension flow filters in one formula must both narrow the aggregate');

        Cleanup();
    end;

    [Test]
    procedure Record_CalcFields_SumOverAnExtensionFieldOnTheTargetTable_Aggregates()
    var
        Customer: Record Customer;
    begin
        // [GIVEN] C1's two ledger entries weigh 7.5 and 2.5; C2's weighs 99.
        Initialize();
        Customer.Get(C1Lbl);

        // [WHEN] The formula sums a field a SECOND tableextension added to the target table.
        Customer.CalcFields("TXC Weight");

        // [THEN] 10, not 109 and not 0.
        Assert.AreEqual(10, Customer."TXC Weight",
            'sum() over a tableextension field on the target table must aggregate it');

        Cleanup();
    end;

    [Test]
    procedure Record_CalcFields_WhereArmOverAnExtensionFieldOnTheTargetTable_Narrows()
    var
        Customer: Record Customer;
    begin
        // [GIVEN] Quantities 3 (weight 7.5) and 5 (weight 2.5) for C1.
        Initialize();
        Customer.Get(C1Lbl);

        // [WHEN] A const() where-arm names the extension field on the target table.
        Customer.CalcFields("TXC Qty Heavy");

        // [THEN] 3. 8 is what a dropped arm gives.
        Assert.AreEqual(3, Customer."TXC Qty Heavy",
            'a where-arm over a tableextension field on the target table must narrow the sum');

        Cleanup();
    end;

    [Test]
    procedure Record_CalcFields_WhereArmOnABaseTableFlowFilter_NarrowsTheSum()
    var
        Customer: Record Customer;
    begin
        // The control for the parent side: the same formula shape with Customer's OWN
        // "Date Filter" in place of the extension one.
        Initialize();
        Customer.Get(C1Lbl);

        Customer.SetRange("Date Filter", 20260101D, 20260101D);
        Customer.CalcFields("TXC Sales Base Filter");

        Assert.AreEqual(140, Customer."TXC Sales Base Filter",
            'field("Date Filter") -- the extended table''s own flow filter -- must narrow the sum');

        Cleanup();
    end;

    [Test]
    procedure Record_CalcSumsAndSetRange_OnATableExtensionField_ReadTheStoredValues()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // The control for the target side: the added field is stored, filterable and
        // summable on its own, so a failure above is about resolving it FROM A FORMULA.
        Initialize();

        ItemLedgerEntry.SetRange("Source No.", C1Lbl);
        ItemLedgerEntry.CalcSums("TXC Ext Weight");
        Assert.AreEqual(10, ItemLedgerEntry."TXC Ext Weight",
            'CalcSums over a tableextension field must add its stored values');

        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Source No.", C1Lbl);
        ItemLedgerEntry.SetRange("TXC Ext Weight", 7.5);
        Assert.AreEqual(1, ItemLedgerEntry.Count(),
            'SetRange on a tableextension field must filter on its stored value');

        Cleanup();
    end;
}
