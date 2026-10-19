// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects in CeObjects.al (84340 to 84359); Base Application pages 30 "Item Card" and
//   302 "Customer Entry Statistics"
// Corpus issue 667 (part B), writer CE: ClearAll in a base page and the globals of a page extension (microsoft/AL issue 6499),
// Visible of an extension action from a variable set in the extension's OnOpenPage (issue 4684), Editable of a base field
// modified to an expression over a FlowField of Rec (issue 6720).

codeunit 84363 "LT CE Page Ext Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedOne()
    var
        Row: Record "LT CE Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
    end;

    [Test]
    procedure ClearAll_InOwnBasePage_ExtensionGlobal()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT CE Log";
        Card: TestPage "LT CE ClearAll Card";
    begin
        SeedOne();
        Log.Take();
        Card.OpenView();
        Observer.Observe('open', Log.Take());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure ClearAll_InBaseAppPage_ExtensionGlobal()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT CE Log";
        Cust: Record Customer;
        Stat: TestPage "Customer Entry Statistics";
        Ok: Boolean;
    begin
        if not Cust.Get('LTCE-C1') then begin
            Cust.Init();
            Cust."No." := 'LTCE-C1';
            Cust.Name := 'LT CE customer';
            Cust.Insert();
        end;
        Commit();
        Log.Take();
        Ok := OpenStat(Stat, Cust);
        Observer.Observe('open|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('open');
        Observer.Observe('open', Log.Take());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure OpenStat(var Stat: TestPage "Customer Entry Statistics"; Cust: Record Customer)
    begin
        Stat.OpenView();
        Stat.GoToRecord(Cust);
    end;

    [Test]
    procedure ExtensionAction_VisibleFromVariableSetInOnOpenPage()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT CE Vis Card";
    begin
        SeedOne();
        Card.OpenView();
        Observer.Observe('base_act', Format(Card.BaseAct.Visible()));
        Observer.Observe('ext_act', Format(Card.ExtAct.Visible()));
        Observer.Observe('ext_act_never_set', Format(Card.ExtActNeverSet.Visible()));
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure ItemCard_ReplenishmentSystemEditableFromFlowField()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record Item;
        Sku: Record "Stockkeeping Unit";
    begin
        if not Item.Get('LTCE-ITEM1') then begin
            Item.Init();
            Item."No." := 'LTCE-ITEM1';
            Item.Description := 'LT CE item';
            Item.Insert();
        end;
        Sku.SetRange("Item No.", Item."No.");
        Sku.DeleteAll();
        Commit();
        ObserveItemCard(Observer, 'no_sku', Item);

        Sku.Init();
        Sku."Item No." := Item."No.";
        Sku."Location Code" := '';
        Sku."Variant Code" := '';
        Sku.Insert();
        Commit();
        ObserveItemCard(Observer, 'with_sku', Item);
        Observer.Finish();
    end;

    local procedure ObserveItemCard(var Observer: Codeunit "Probe Observer"; Name: Text; Item: Record Item)
    var
        Card: TestPage "Item Card";
        Ok: Boolean;
    begin
        Ok := OpenItemCard(Card, Item);
        Observer.Observe(Name + '|open', Format(Ok));
        if not Ok then begin
            Observer.ObserveError(Name);
            exit;
        end;
        Observer.Observe(Name + '|sku_exists', Card."Stockkeeping Unit Exists".Value());
        Observer.Observe(Name + '|editable', Format(Card."Replenishment System".Editable()));
        Observer.Observe(Name + '|mfg_editable', Format(Card."Manufacturing Policy".Editable()));
        Card.Close();
    end;

    [TryFunction]
    local procedure OpenItemCard(var Card: TestPage "Item Card"; Item: Record Item)
    begin
        Card.OpenEdit();
        Card.GoToRecord(Item);
    end;
}
