// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-rename-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: none -- every table is Base Application's own (Location 14, Item 27,
//   Item Journal Line 83, Item Ledger Entry 32, Item Analysis View 7152)
//
// CLAIM UNDER TEST: renaming a Base Application record propagates through the TableRelations
// Base Application itself declares on OTHER Base Application tables -- relations this app never
// compiled -- with the same rules "Test Rename Propagation" (60236) pins for this app's own
// fixtures: a Normal field with TableRelation = Location follows the rename, a Normal field with
// ValidateTableRelation = false does not, and a FlowFilter over Location (Item."Location Filter")
// neither blocks the rename nor stops CalcFields from finding the renamed rows.
//
// AL Runner issue: https://github.com/StefanMaron/BusinessCentral.AL.Runner/issues/4105

codeunit 60975 "Test Rename Prop BaseApp"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        OldLocationTok: Label 'ALTRN-OLD', Locked = true;
        NewLocationTok: Label 'ALTRN-NEW', Locked = true;
        ItemNoTok: Label 'ALT-RENAME-ITEM', Locked = true;
        JnlTemplateTok: Label 'ALTRN', Locked = true;

    // Item Journal Line."Location Code" carries a plain `TableRelation = Location`.
    [Test]
    procedure Rename_BaseAppLocation_ItemJournalLineLocationCodeFollows()
    var
        Location: Record Location;
        ItemJnlLine: Record "Item Journal Line";
    begin
        Initialize();
        CreateLocation(Location);

        ItemJnlLine."Journal Template Name" := JnlTemplateTok;
        ItemJnlLine."Journal Batch Name" := JnlTemplateTok;
        ItemJnlLine."Line No." := 10000;
        ItemJnlLine."Location Code" := OldLocationTok;
        ItemJnlLine.Insert(false);

        Location.Rename(NewLocationTok);

        ItemJnlLine.Get(JnlTemplateTok, JnlTemplateTok, 10000);
        Assert.AreEqual(NewLocationTok, ItemJnlLine."Location Code",
            'Item Journal Line."Location Code" (TableRelation = Location) must follow the Location rename');
        Assert.IsFalse(Location.Get(OldLocationTok), 'The old Location code must be gone after Rename');
        Assert.IsTrue(Location.Get(NewLocationTok), 'The new Location code must exist after Rename');
    end;

    // Item Analysis View."Location Filter" is a NORMAL Code[250] field with
    // `TableRelation = Location; ValidateTableRelation = false;` -- the control.
    [Test]
    procedure Rename_BaseAppLocation_UnvalidatedRelationDoesNotFollow()
    var
        Location: Record Location;
        ItemAnalysisView: Record "Item Analysis View";
    begin
        Initialize();
        CreateLocation(Location);

        ItemAnalysisView."Analysis Area" := ItemAnalysisView."Analysis Area"::Inventory;
        ItemAnalysisView.Code := JnlTemplateTok;
        ItemAnalysisView."Location Filter" := OldLocationTok;
        ItemAnalysisView.Insert(false);

        Location.Rename(NewLocationTok);

        ItemAnalysisView.Get(ItemAnalysisView."Analysis Area"::Inventory, JnlTemplateTok);
        Assert.AreEqual(OldLocationTok, ItemAnalysisView."Location Filter",
            'ValidateTableRelation = false on a Base Application field must suppress rename propagation');
    end;

    // Item Ledger Entry."Location Code" (TableRelation = Location) follows the rename, and
    // Item.Inventory -- sum over Item Ledger Entry where "Location Code" = field("Location Filter"),
    // a FlowFilter whose own TableRelation is Location -- then sums the row under the NEW code only.
    [Test]
    procedure Rename_BaseAppLocation_FlowFieldFilteredByNewCodeFindsRenamedRows()
    var
        Location: Record Location;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        EntryNo: Integer;
        Qty: Decimal;
    begin
        Initialize();
        CreateLocation(Location);

        Item."No." := ItemNoTok;
        Item.Insert(false);

        if ItemLedgerEntry.FindLast() then
            EntryNo := ItemLedgerEntry."Entry No.";
        Clear(ItemLedgerEntry);
        ItemLedgerEntry."Entry No." := EntryNo + 1;
        ItemLedgerEntry."Item No." := ItemNoTok;
        ItemLedgerEntry."Location Code" := OldLocationTok;
        Qty := 7;
        ItemLedgerEntry.Quantity := Qty;
        ItemLedgerEntry.Insert(false);

        Location.Rename(NewLocationTok);

        ItemLedgerEntry.Get(EntryNo + 1);
        Assert.AreEqual(NewLocationTok, ItemLedgerEntry."Location Code",
            'Item Ledger Entry."Location Code" (TableRelation = Location) must follow the Location rename');

        Item.Get(ItemNoTok);
        Item.SetRange("Location Filter", NewLocationTok);
        Item.CalcFields(Inventory);
        Assert.AreEqual(Qty, Item.Inventory, 'Inventory filtered by the NEW Location code must find the renamed entry');

        Item.SetRange("Location Filter", OldLocationTok);
        Item.CalcFields(Inventory);
        Qty := 0;
        Assert.AreEqual(Qty, Item.Inventory, 'Inventory filtered by the OLD Location code must find nothing after the rename');
    end;

    local procedure CreateLocation(var Location: Record Location)
    begin
        Location.Init();
        Location.Code := OldLocationTok;
        Location.Insert(false);
    end;

    local procedure Initialize()
    var
        Location: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemAnalysisView: Record "Item Analysis View";
    begin
        Location.SetFilter(Code, 'ALTRN-*');
        Location.DeleteAll(false);
        ItemJnlLine.SetRange("Journal Template Name", JnlTemplateTok);
        ItemJnlLine.DeleteAll(false);
        ItemLedgerEntry.SetRange("Item No.", ItemNoTok);
        ItemLedgerEntry.DeleteAll(false);
        Item.SetRange("No.", ItemNoTok);
        Item.DeleteAll(false);
        ItemAnalysisView.SetRange(Code, JnlTemplateTok);
        ItemAnalysisView.DeleteAll(false);
    end;
}
