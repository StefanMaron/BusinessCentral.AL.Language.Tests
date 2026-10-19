// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects in CeObjects.al (84340 to 84359); Base Application pages 30 "Item Card" and
//   302 "Customer Entry Statistics"
// Corpus issue 667 (part B), writer CE: ClearAll in a base page and the globals of a page extension (microsoft/AL issue 6499),
// Visible of an extension action from a variable set in the extension's OnOpenPage (issue 4684), Editable of a base field
// modified to an expression over a FlowField of Rec (issue 6720).
// Probe: written against a local BC 29.0 service tier; every literal below is what that tier produced; 27.5 and 28.5 by the CI matrix.
// Facts (BC 29.0): ClearAll() in the base page's OnAfterGetRecord clears the globals of a page extension, for a base page of the same
// app and for page 302 of the Base Application (the extension's flag set in its OnOpenPage reads false in every OnAfterGetRecord).
// An extension action with Visible = <variable set true in the extension's OnOpenPage> is visible on the TestPage; one whose
// variable is never set is not. Opening the Item Card with the issue 6720 extension fails: "The identifier 'Stockkeeping Unit
// Exists' could not be found." (code Expression:Argument), with and without a stockkeeping unit.

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
        Observer.Expect('open', 'base AGR before ClearAll flag=Yes;base AGR after ClearAll flag=No;ext AGR flag=No;');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_InBaseAppPage_ExtensionGlobal()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT CE Log";
        Cust: Record Customer;
        Stat: TestPage "Customer Entry Statistics";
        Trace: Text;
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
        // How often the TestPage reads the record (7 times on BC 29.0) is not asserted: only the order and the flag.
        Trace := Log.Take();
        Observer.Observe('open_start', CopyStr(Trace, 1, StrLen('ext OnOpenPage;ext AGR flag=No;')));
        Observer.Observe('flag_yes_in_any_ext_AGR', Format(StrPos(Trace, 'flag=Yes') > 0));
        Observer.Expect('open|ok', 'Yes');
        Observer.Expect('open_start', 'ext OnOpenPage;ext AGR flag=No;');
        Observer.Expect('flag_yes_in_any_ext_AGR', 'No');
        Observer.Verify();
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
        Observer.Expect('base_act', 'Yes');
        Observer.Expect('ext_act', 'Yes');
        Observer.Expect('ext_act_never_set', 'No');
        Observer.Verify();
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
        Observer.Expect('no_sku|open', 'No');
        Observer.Expect('no_sku|text', 'The identifier ''Stockkeeping Unit Exists'' could not be found.');
        Observer.Expect('no_sku|code', 'Expression:Argument');
        Observer.Expect('with_sku|open', 'No');
        Observer.Expect('with_sku|text', 'The identifier ''Stockkeeping Unit Exists'' could not be found.');
        Observer.Expect('with_sku|code', 'Expression:Argument');
        Observer.Verify();
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
