// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-editable-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT AB Row" (77000), codeunit "LT AB Flags" (77001), page "LT AB Fixed Props" (77012), page "LT AB Fixed Tree List" (77015), ABGroupFixtures.al
// Probe: written against a BC service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 27 to 29 (CI matrix)
// Facts: Editable, Enabled and Visible of a fixed (true, false, an expression) as a TestPage sees them on the field inside; input on a non-editable field;
// ShowAsTree and FileUploadAction on a fixed (compile, and a TestPage still lists every row).
// The other repeater-only properties are refused on a fixed: must-not-compile cases in 0920 to 0946.

codeunit 77013 "LT AB Fixed Props Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT AB Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'First';
        Row.Insert();
    end;

    local procedure Run(Ed: Boolean; En: Boolean; Vi: Boolean)
    var
        Observer: Codeunit "Probe Observer";
        Flags: Codeunit "LT AB Flags";
        Card: TestPage "LT AB Fixed Props";
    begin
        Seed();
        Flags.Set(Ed, En, Vi);
        Card.OpenEdit();
        Observer.Observe('true-editable', Format(Card.FxTrueF.Editable()));
        Observer.Observe('true-enabled', Format(Card.FxTrueF.Enabled()));
        Observer.Observe('true-visible', Format(Card.FxTrueF.Visible()));
        Observer.Observe('false-editable', Format(Card.FxFalseF.Editable()));
        Observer.Observe('false-enabled', Format(Card.FxFalseF.Enabled()));
        Observer.Observe('false-visible', Format(Card.FxFalseF.Visible()));
        Observer.Observe('expr-editable', Format(Card.FxExprF.Editable()));
        Observer.Observe('expr-enabled', Format(Card.FxExprF.Enabled()));
        Observer.Observe('expr-visible', Format(Card.FxExprF.Visible()));
        Observer.Observe('plain-editable', Format(Card.PlainF.Editable()));
        Observer.Observe('plain-enabled', Format(Card.PlainF.Enabled()));
        Observer.Observe('plain-visible', Format(Card.PlainF.Visible()));
        Observer.Observe('true-value', Card.FxTrueF.Value());
        Observer.Observe('false-value', Card.FxFalseF.Value());
        Observer.Observe('expr-value', Card.FxExprF.Value());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure ExpressionTrue()
    begin
        Run(true, true, true);
    end;

    [Test]
    procedure ExpressionFalse()
    begin
        Run(false, false, false);
    end;

    [Test]
    procedure ExpressionNotEditable()
    begin
        Run(false, true, true);
    end;

    [Test]
    procedure ExpressionNotEnabled()
    begin
        Run(true, false, true);
    end;

    [Test]
    procedure ExpressionNotVisible()
    begin
        Run(true, true, false);
    end;

    [Test]
    procedure InputOnEditableAndNonEditable()
    var
        Observer: Codeunit "Probe Observer";
        Flags: Codeunit "LT AB Flags";
        Stored: Record "LT AB Row";
        Card: TestPage "LT AB Fixed Props";
    begin
        Seed();
        Flags.Set(false, true, true);
        Card.OpenEdit();
        Card.FxTrueF.SetValue('set-true');
        Observer.Observe('true-after-setvalue', Card.FxTrueF.Value());
        asserterror Card.FxFalseF.SetValue('set-false');
        Observer.ObserveError('false-setvalue');
        asserterror Card.FxExprF.SetValue('set-expr');
        Observer.ObserveError('expr-not-editable-setvalue');
        Observer.Observe('expr-value-after', Card.FxExprF.Value());
        Card.Close();
        Stored.Get(1);
        Observer.Observe('stored-name', Stored.Name);
        Observer.Finish();
    end;

    [Test]
    procedure ShowAsTreeAndFileUploadActionListAllRows()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AB Row";
        List: TestPage "LT AB Fixed Tree List";
        Names: Text;
        Count: Integer;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'One';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'Two';
        Row.Insert();
        Row.Id := 3;
        Row.Name := 'Three';
        Row.Insert();
        List.OpenView();
        if List.First() then
            repeat
                Count += 1;
                Names += List.IdF.Value() + '=' + List.NameF.Value() + ';';
            until not List.Next();
        Observer.Observe('row-count', Format(Count));
        Observer.Observe('rows', Names);
        Observer.Observe('tree-field', List.TreeF.Value());
        Observer.Observe('plain-field', List.PlainTreeF.Value());
        Observer.Observe('plain-action-visible', Format(List.PlainAct.Visible()));
        List.Close();
        Observer.Finish();
    end;
}
