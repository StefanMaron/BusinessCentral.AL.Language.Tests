// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-minvalue-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 71332, page 71333, test codeunit 71334
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TestPage SetValue on a Decimal control with MinValue 0.5 / MaxValue 2.5 (page variable and table field) for values just outside the bound that round to the bound or inside it.
// BC versions: 29 (27 and 28 by CI)
table 71332 "LT P158 Bounds Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Amt; Decimal)
        {
            MinValue = 0.5;
            MaxValue = 2.5;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 71333 "LT P158 Bounds Page"
{
    PageType = Card;
    SourceTable = "LT P158 Bounds Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Amt; Rec.Amt) { ApplicationArea = All; }
            field(DecVar; DecVar)
            {
                ApplicationArea = All;
                MinValue = 0.5;
                MaxValue = 2.5;
            }
        }
    }

    var
        DecVar: Decimal;
}

codeunit 71334 "LT P158 Bounds Edge"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySetVar(var P: TestPage "LT P158 Bounds Page"; V: Decimal)
    begin
        P.DecVar.SetValue(V);
    end;

    [TryFunction]
    local procedure TrySetField(var P: TestPage "LT P158 Bounds Page"; V: Decimal)
    begin
        P.Amt.SetValue(V);
    end;

    [Test]
    procedure PageVariable_JustAboveMax_DisplayedInsideTheBound()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT P158 Bounds Page";
    begin
        P.OpenNew();
        P.Id.SetValue(1);
        Observer.Observe('2.5 ok', Format(TrySetVar(P, 2.5)));
        Observer.Observe('2.5 value', P.DecVar.Value());
        Observer.Observe('2.5004 ok', Format(TrySetVar(P, 2.5004)));
        Observer.ObserveError('2.5004');
        Observer.Observe('2.5004 value', P.DecVar.Value());
        Observer.Observe('2.5049 ok', Format(TrySetVar(P, 2.5049)));
        Observer.ObserveError('2.5049');
        Observer.Observe('2.5051 ok', Format(TrySetVar(P, 2.5051)));
        Observer.ObserveError('2.5051');
        Observer.Observe('2.50000001 ok', Format(TrySetVar(P, 2.50000001)));
        Observer.ObserveError('2.50000001');
        Observer.Observe('value now', P.DecVar.Value());
        P.Close();
        Observer.Expect('2.5 ok', 'Yes');
        Observer.Expect('2.5 value', '2.50');
        Observer.Expect('2.5004 ok', 'Yes');
        Observer.Expect('2.5004|text', '');
        Observer.Expect('2.5004|code', '');
        Observer.Expect('2.5004 value', '2.50');
        Observer.Expect('2.5049 ok', 'Yes');
        Observer.Expect('2.5049|text', '');
        Observer.Expect('2.5049|code', '');
        Observer.Expect('2.5051 ok', 'No');
        Observer.Expect('2.5051|text', 'Validation error for Field: DecVar,  Message = ''The value must be less than or equal to 2.5. Value: 2.51.''');
        Observer.Expect('2.5051|code', 'TestValidation');
        Observer.Expect('2.50000001 ok', 'Yes');
        Observer.Expect('2.50000001|text', '');
        Observer.Expect('2.50000001|code', '');
        Observer.Expect('value now', '2.50');
        Observer.Verify();
    end;

    [Test]
    procedure TableField_JustOutsideTheBounds()
    var
        Observer: Codeunit "Probe Observer";
        Bounds: Record "LT P158 Bounds Table";
        P: TestPage "LT P158 Bounds Page";
    begin
        Bounds.DeleteAll();
        P.OpenNew();
        P.Id.SetValue(1);
        Observer.Observe('2.5 ok', Format(TrySetField(P, 2.5)));
        Observer.Observe('2.5004 ok', Format(TrySetField(P, 2.5004)));
        Observer.ObserveError('2.5004');
        Observer.Observe('2.505 ok', Format(TrySetField(P, 2.505)));
        Observer.ObserveError('2.505');
        Observer.Observe('0.4996 ok', Format(TrySetField(P, 0.4996)));
        Observer.ObserveError('0.4996');
        Observer.Observe('0.495 ok', Format(TrySetField(P, 0.495)));
        Observer.ObserveError('0.495');
        Observer.Observe('value now', P.Amt.Value());
        P.Close();
        Bounds.DeleteAll();
        Observer.Expect('2.5 ok', 'Yes');
        Observer.Expect('2.5004 ok', 'Yes');
        Observer.Expect('2.5004|text', '');
        Observer.Expect('2.5004|code', '');
        Observer.Expect('2.505 ok', 'No');
        Observer.Expect('2.505|text', 'Validation error for Field: Amt,  Message = ''The value must be less than or equal to 2.5. Value: 2.51. (Select Refresh to discard errors)''');
        Observer.Expect('2.505|code', 'TestValidation');
        Observer.Expect('0.4996 ok', 'Yes');
        Observer.Expect('0.4996|text', '');
        Observer.Expect('0.4996|code', '');
        Observer.Expect('0.495 ok', 'Yes');
        Observer.Expect('0.495|text', '');
        Observer.Expect('0.495|code', '');
        Observer.Expect('value now', '0.50');
        Observer.Verify();
    end;
}
