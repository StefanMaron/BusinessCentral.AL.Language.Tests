// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects in BcImplicitAreaObjects.al
// Corpus issue 659 item 3 (from al-runtime-rs #252): a page extension may add to area(FactBoxes) when the base card declares only
// area(Content), and the test page opens. These tests read what the added parts show. An area name that does not exist is
// must-not-compile case 1270.

codeunit 80972 "BC Implicit Areas"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure FactBoxes_NotDeclared_OpenView_Closes()
    var
        Card: TestPage "BC Implicit FB Card";
    begin
        // The repro of al-runtime-rs #252.
        Card.OpenView();
        Card.Close();
    end;

    [Test]
    procedure FactBoxes_NotDeclared_PartsShowLinkedRow()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "BC Implicit FB Card";
    begin
        Card.OpenView();
        Card.GoToKey(5);
        Observer.Observe('card number', Card.Number.Value());
        Observer.Observe('part number', Card.BCPart.PartNumber.Value());
        Observer.Observe('part visible', Format(Card.BCPart.Visible()));
        Observer.Observe('part editable', Format(Card.BCPart.Editable()));
        Observer.Observe('part next', Format(Card.BCPart.Next()));
        Observer.Observe('after part number', Card.BCPartAfter.PartNumber.Value());
        Observer.Observe('after part visible', Format(Card.BCPartAfter.Visible()));
        Card.GoToKey(7);
        Observer.Observe('card number 7', Card.Number.Value());
        Observer.Observe('part number 7', Card.BCPart.PartNumber.Value());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure NoLayout_ExtensionAddsContentAndFactBox()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "BC No Layout Card";
    begin
        Card.OpenView();
        Card.GoToKey(3);
        Observer.Observe('number', Card.BCNumber.Value());
        Observer.Observe('number visible', Format(Card.BCNumber.Visible()));
        Observer.Observe('part number', Card.BCNoLayoutPart.PartNumber.Value());
        Observer.Observe('part visible', Format(Card.BCNoLayoutPart.Visible()));
        Card.Close();
        Observer.Finish();
    end;
}
