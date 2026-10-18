// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 67604, pages 67604 and 67605, codeunit 67604
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// An asserterror around a call that does not raise gives the ASSERTERROR text; the observed value shows that case.
// Facts: TestPage SetValue of a text that is not an Option member (error code, text, Value() afterwards);
// AssertEquals of a number (Integer and Decimal, 10 or more, negative, 1000 or more) against a Text control;
// Editable() of a page field over a FlowField with Editable = false.
// BC versions: 27, 28, 29

table 67604 "LT N582 Page Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Opt; Option)
        {
            OptionMembers = Zero,One,Two;
        }
        field(3; Txt; Text[50]) { }
        field(4; Flow; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT N582 Page Row");
            Editable = false;
        }
        field(5; FlowDefault; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT N582 Page Row");
        }
        field(6; Plain; Integer)
        {
            Editable = false;
        }
        field(7; Dec; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 67604 "LT N582 Page Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "LT N582 Page Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(Opt; Rec.Opt) { }
            field(Txt; Rec.Txt) { }
            field(Flow; Rec.Flow) { }
            field(FlowDefault; Rec.FlowDefault) { }
            field(Plain; Rec.Plain) { }
            field(Dec; Rec.Dec) { }
        }
    }
}

page 67605 "LT N582 Page List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT N582 Page Row";

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Id; Rec.Id) { }
                field(Flow; Rec.Flow) { }
                field(FlowDefault; Rec.FlowDefault) { }
                field(Plain; Rec.Plain) { }
            }
        }
    }
}

codeunit 67604 "LT N582 Test Page Edges"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT N582 Page Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
    end;

    local procedure SetOpt(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        Pg: TestPage "LT N582 Page Card";
    begin
        Seed();
        Pg.OpenEdit();
        Pg.Opt.SetValue('One');
        asserterror Pg.Opt.SetValue(Txt);
        Observer.ObserveError(Name);
        Observer.Observe(Name + '|value', Pg.Opt.Value());
        Pg.Close();
    end;

    local procedure NumVsText(var Observer: Codeunit "Probe Observer"; Name: Text; Shown: Text; Expected: Variant)
    var
        Pg: TestPage "LT N582 Page Card";
    begin
        Seed();
        Pg.OpenEdit();
        Pg.Txt.SetValue(Shown);
        Observer.Observe(Name + '|shown', Pg.Txt.Value());
        asserterror Pg.Txt.AssertEquals(Expected);
        Observer.ObserveError(Name);
        Pg.Close();
    end;

    [Test]
    procedure N582_SetValue_OptionText_NotAMember()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetOpt(Observer, 'Nope', 'Nope');
        SetOpt(Observer, 'lower case member', 'two');
        SetOpt(Observer, 'empty', '');
        SetOpt(Observer, 'out of range number', '5');
        SetOpt(Observer, 'in range number', '2');
        SetOpt(Observer, 'member with blank', 'Two ');
        SetOpt(Observer, 'prefix of member', 'Tw');
        Observer.Finish();
    end;

    [Test]
    procedure N582_AssertEquals_NumberOnTextControl_Integer()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        I := 5;
        NumVsText(Observer, 'int 5 vs 5', '5', I);
        I := 10;
        NumVsText(Observer, 'int 10 vs 10', '10', I);
        I := 123;
        NumVsText(Observer, 'int 123 vs 123', '123', I);
        I := 12345;
        NumVsText(Observer, 'int 12345 vs 12345', '12345', I);
        I := 1234567;
        NumVsText(Observer, 'int 1234567 vs 1234567', '1234567', I);
        I := 1234567;
        NumVsText(Observer, 'int 1234567 vs grouped', '1,234,567', I);
        I := -5;
        NumVsText(Observer, 'int -5 vs -5', '-5', I);
        I := -10;
        NumVsText(Observer, 'int -10 vs -10', '-10', I);
        I := -1234;
        NumVsText(Observer, 'int -1234 vs -1234', '-1234', I);
        I := 0;
        NumVsText(Observer, 'int 0 vs 0', '0', I);
        I := 10;
        NumVsText(Observer, 'int 10 vs 11', '11', I);
        I := 10;
        NumVsText(Observer, 'int 10 vs text', 'ten', I);
        Observer.Finish();
    end;

    [Test]
    procedure N582_AssertEquals_NumberOnTextControl_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
    begin
        D := 5;
        NumVsText(Observer, 'dec 5 vs 5', '5', D);
        D := 10;
        NumVsText(Observer, 'dec 10 vs 10', '10', D);
        D := 1.5;
        NumVsText(Observer, 'dec 1.5 vs 1.5', '1.5', D);
        D := 999.99;
        NumVsText(Observer, 'dec 999.99 vs 999.99', '999.99', D);
        D := 1000;
        NumVsText(Observer, 'dec 1000 vs 1000', '1000', D);
        D := 1000;
        NumVsText(Observer, 'dec 1000 vs grouped', '1,000', D);
        D := 1234.5;
        NumVsText(Observer, 'dec 1234.5 vs 1234.5', '1234.5', D);
        D := 1234.5;
        NumVsText(Observer, 'dec 1234.5 vs grouped', '1,234.5', D);
        D := 1234567.89;
        NumVsText(Observer, 'dec 1234567.89 vs plain', '1234567.89', D);
        D := 1234567.89;
        NumVsText(Observer, 'dec 1234567.89 vs grouped', '1,234,567.89', D);
        D := -1000;
        NumVsText(Observer, 'dec -1000 vs -1000', '-1000', D);
        D := -1234.5;
        NumVsText(Observer, 'dec -1234.5 vs grouped', '-1,234.5', D);
        D := -0.5;
        NumVsText(Observer, 'dec -0.5 vs -0.5', '-0.5', D);
        D := 0;
        NumVsText(Observer, 'dec 0 vs 0', '0', D);
        D := 1000;
        NumVsText(Observer, 'dec 1000 vs 1001', '1001', D);
        Observer.Finish();
    end;

    [Test]
    procedure N582_Editable_FlowFieldNotEditable()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT N582 Page Card";
        List: TestPage "LT N582 Page List";
    begin
        Seed();
        Card.OpenEdit();
        Observer.Observe('card flow Editable=false', Format(Card.Flow.Editable()));
        Observer.Observe('card flow default', Format(Card.FlowDefault.Editable()));
        Observer.Observe('card plain Editable=false', Format(Card.Plain.Editable()));
        Observer.Observe('card id', Format(Card.Id.Editable()));
        Observer.Observe('card flow value', Card.Flow.Value());
        asserterror Card.Flow.SetValue(5);
        Observer.ObserveError('card flow SetValue');
        asserterror Card.FlowDefault.SetValue(5);
        Observer.ObserveError('card flow default SetValue');
        Card.Close();
        List.OpenEdit();
        Observer.Observe('list flow Editable=false', Format(List.Flow.Editable()));
        Observer.Observe('list flow default', Format(List.FlowDefault.Editable()));
        Observer.Observe('list plain Editable=false', Format(List.Plain.Editable()));
        List.Close();
        Card.OpenView();
        Observer.Observe('view card flow', Format(Card.Flow.Editable()));
        Observer.Observe('view card id', Format(Card.Id.Editable()));
        Card.Close();
        Observer.Finish();
    end;
}
