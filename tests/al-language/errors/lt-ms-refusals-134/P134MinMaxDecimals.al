// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-minvalue-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 74121, pages 74122 74123, test codeunit 74124 (P134)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TestPage SetValue on a Decimal control bound to a TABLE field with MinValue/MaxValue (and on a control with its own MinValue/MaxValue) with values that have more than two decimals, outside and inside the bounds: the error text (how the value is shown), the stored and displayed value afterwards
// BC versions: 29 (27 and 28 by CI)

table 74121 "LT P134 MinMax"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Dec; Decimal)
        {
            MinValue = 0;
            MaxValue = 100;
        }
        field(3; DecNeg; Decimal)
        {
            MinValue = -0.5;
            MaxValue = 2.5;
        }
        field(4; DecPl; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MinValue = 1;
            MaxValue = 10;
        }
        field(5; DecPl0; Decimal)
        {
            DecimalPlaces = 0 : 0;
            MinValue = 1;
            MaxValue = 10;
        }
        field(6; DecFree; Decimal) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 74122 "LT P134 MinMax Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "LT P134 MinMax";

    layout
    {
        area(Content)
        {
            group(G)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Dec; Rec.Dec) { ApplicationArea = All; }
                field(DecNeg; Rec.DecNeg) { ApplicationArea = All; }
                field(DecPl; Rec.DecPl) { ApplicationArea = All; }
                field(DecPl0; Rec.DecPl0) { ApplicationArea = All; }
            }
        }
    }
}

page 74123 "LT P134 MinMax Free Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "LT P134 MinMax";

    layout
    {
        area(Content)
        {
            group(G)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(DecFree; Rec.DecFree)
                {
                    ApplicationArea = All;
                    MinValue = 1;
                    MaxValue = 10;
                }
            }
        }
    }
}

codeunit 74124 "LT P134 MinMax Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(var Row: Record "LT P134 MinMax")
    begin
        Row.DeleteAll();
        Row.Init();
        Row."Code" := 'R1';
        Row.Dec := 50;
        Row.DecNeg := 1;
        Row.DecPl := 5;
        Row.DecPl0 := 5;
        Row.DecFree := 5;
        Row.Insert();
    end;

    [Test]
    procedure P134_TableField_Above_Max_ManyDecimals()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P134 MinMax";
        Card: TestPage "LT P134 MinMax Card";
    begin
        Seed(Row);
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Dec.SetValue(100.001);
        Observer.Observe('p100.001', 'no error');
        Card.Dec.SetValue(100.004);
        Observer.Observe('p100.004', 'no error');
        asserterror Card.Dec.SetValue(100.005);
        Observer.ObserveError('p100.005');
        asserterror Card.Dec.SetValue(100.456);
        Observer.ObserveError('p100.456');
        asserterror Card.Dec.SetValue(101.23456);
        Observer.ObserveError('p101.23456');
        asserterror Card.Dec.SetValue(100.1);
        Observer.ObserveError('p100.1');
        asserterror Card.Dec.SetValue(100.12);
        Observer.ObserveError('p100.12');
        asserterror Card.Dec.SetValue(99999999.999);
        Observer.ObserveError('big');
        Card.Close();
        Observer.Expect('p100.001', 'no error');
        Observer.Expect('p100.004', 'no error');
        Observer.Expect('p100.005|text', 'Validation error for Field: Dec,  Message = ''The value must be less than or equal to 100. Value: 100.01. (Select Refresh to discard errors)''');
        Observer.Expect('p100.005|code', 'TestValidation');
        Observer.Expect('p100.456|text', 'Validation error for Field: Dec,  Message = ''The value must be less than or equal to 100. Value: 100.46. (Select Refresh to discard errors)''');
        Observer.Expect('p100.456|code', 'TestValidation');
        Observer.Expect('p101.23456|text', 'Validation error for Field: Dec,  Message = ''The value must be less than or equal to 100. Value: 101.23. (Select Refresh to discard errors)''');
        Observer.Expect('p101.23456|code', 'TestValidation');
        Observer.Expect('p100.1|text', 'Validation error for Field: Dec,  Message = ''The value must be less than or equal to 100. Value: 100.10. (Select Refresh to discard errors)''');
        Observer.Expect('p100.1|code', 'TestValidation');
        Observer.Expect('p100.12|text', 'Validation error for Field: Dec,  Message = ''The value must be less than or equal to 100. Value: 100.12. (Select Refresh to discard errors)''');
        Observer.Expect('p100.12|code', 'TestValidation');
        Observer.Expect('big|text', 'Validation error for Field: Dec,  Message = ''The value must be less than or equal to 100. Value: 100000000.00. (Select Refresh to discard errors)''');
        Observer.Expect('big|code', 'TestValidation');
        Observer.Verify();
    end;

    [Test]
    procedure P134_TableField_Inside_ManyDecimals()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P134 MinMax";
        Card: TestPage "LT P134 MinMax Card";
    begin
        Seed(Row);
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Dec.SetValue(0.001);
        Observer.Observe('shown 0.001', Format(Card.Dec.Value));
        Card.Dec.SetValue(99.999);
        Observer.Observe('shown 99.999', Format(Card.Dec.Value));
        Card.Dec.SetValue(50.12345);
        Observer.Observe('shown 50.12345', Format(Card.Dec.Value));
        Card.Dec.SetValue(0.005);
        Observer.Observe('shown 0.005', Format(Card.Dec.Value));
        Card.Dec.SetValue(100);
        Observer.Observe('shown 100', Format(Card.Dec.Value));
        Card.Dec.SetValue(0);
        Observer.Observe('shown 0', Format(Card.Dec.Value));
        Card.Close();
        Row.Get('R1');
        Observer.Observe('stored', Format(Row.Dec));
        Observer.Expect('shown 0.001', '0.00');
        Observer.Expect('shown 99.999', '100.00');
        Observer.Expect('shown 50.12345', '50.12');
        Observer.Expect('shown 0.005', '0.01');
        Observer.Expect('shown 100', '100.00');
        Observer.Expect('shown 0', '0.00');
        Observer.Expect('stored', '0');
        Observer.Verify();
    end;
}
