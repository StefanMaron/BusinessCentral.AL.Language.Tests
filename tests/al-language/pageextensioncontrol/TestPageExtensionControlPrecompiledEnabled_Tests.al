// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Assert (60021) -- and Base Application page "Item Card" with its pageextension
//                99000750 "Mfg. Item Card", both of which ship PRECOMPILED in Base Application.
//
// CLAIM: a control that a precompiled pageextension adds to a precompiled page answers the
// Enabled property the EXTENSION declares, not the AL default of true. Base Application's
// "Mfg. Item Card" adds "Overhead Rate" to "Item Card" with Enabled = IsInventoriable, a global
// of the pageextension, so the control is disabled for an item that is not inventoriable
// (Type = Service) and enabled for one that is (Type = Inventory).
//
// Each arm creates its own item, so neither depends on what the company already holds.
//
// Written by agent stma-auto2-14, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4749.

codeunit 67402 "PXCE Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure EnableBasicAreas() Previous: Text
    begin
        Previous := ApplicationArea();
        ApplicationArea('#Basic,#Suite');
    end;

    local procedure CreateItem(No: Code[20]; ItemType: Enum "Item Type")
    var
        Item: Record Item;
    begin
        if Item.Get(No) then
            Item.Delete();
        Item.Init();
        Item."No." := No;
        Item.Type := ItemType;
        Item.Insert();
    end;

    local procedure OverheadRateEnabled(No: Code[20]) Enabled: Boolean
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        Item.Get(No);
        ItemCard.OpenView();
        ItemCard.GoToRecord(Item);
        Enabled := ItemCard."Overhead Rate".Enabled();
        ItemCard.Close();
    end;

    [Test]
    procedure PrecompiledPageExtControl_ServiceItem_OverheadRateIsDisabled()
    var
        Enabled: Boolean;
        PreviousAreas: Text;
    begin
        PreviousAreas := EnableBasicAreas();
        CreateItem('PXCE-SERVICE', "Item Type"::Service);
        Enabled := OverheadRateEnabled('PXCE-SERVICE');
        ApplicationArea(PreviousAreas);

        Assert.IsFalse(Enabled, '"Overhead Rate" (Enabled = IsInventoriable, declared by pageextension "Mfg. Item Card") must be disabled for a Service item.');
    end;

    [Test]
    procedure PrecompiledPageExtControl_InventoryItem_OverheadRateIsEnabled()
    var
        Enabled: Boolean;
        PreviousAreas: Text;
    begin
        PreviousAreas := EnableBasicAreas();
        CreateItem('PXCE-INVENTORY', "Item Type"::Inventory);
        Enabled := OverheadRateEnabled('PXCE-INVENTORY');
        ApplicationArea(PreviousAreas);

        Assert.IsTrue(Enabled, '"Overhead Rate" (Enabled = IsInventoriable, declared by pageextension "Mfg. Item Card") must be enabled for an Inventory item.');
    end;
}
