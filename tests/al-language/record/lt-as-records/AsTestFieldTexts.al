// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), AsFixtures.al (tables 79906, 79908, 79900, enum 79907, helper 79913)
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced (corpus issue 644, items 9, 10 and 11).
// Facts: the TestField error text for a Byte value of 10 and 200 against an Integer field, an Enum value with a caption, a Guid against a Code
//   field (item 9); ModifyAll on a primary key field whose caption differs from its name, with zero rows and with one row (item 10);
//   SetFilter on a Date field with a two-digit year from 29 to 50: the year read and GetFilter (item 11).
// BC versions: 27-29

codeunit 79926 "LT AS TestField Texts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT AS Helper";

    local procedure Seed(var Row: Record "LT AS TF Row")
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Num := 7;
        Row.Kind := Row.Kind::None;
        Row.Cd := 'ABC';
        Row.Insert();
    end;

    [Test]
    procedure Byte10()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS TF Row";
        B: Byte;
    begin
        Seed(Row);
        B := 10;
        asserterror Row.TestField(Num, B);
        Observer.Observe('byte10', Helper.LastError());
        Observer.Finish();
    end;

    [Test]
    procedure Byte200()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS TF Row";
        B: Byte;
    begin
        Seed(Row);
        B := 200;
        asserterror Row.TestField(Num, B);
        Observer.Observe('byte200', Helper.LastError());
        Observer.Finish();
    end;

    [Test]
    procedure Byte7Equal()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS TF Row";
        B: Byte;
    begin
        Seed(Row);
        B := 7;
        ClearLastError();
        if TryTestNum(Row, B) then
            Observer.Observe('byte7', 'ok')
        else
            Observer.Observe('byte7', Helper.LastError());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryTestNum(var Row: Record "LT AS TF Row"; B: Byte)
    begin
        Row.TestField(Num, B);
    end;

    [Test]
    procedure EnumWithCaption()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS TF Row";
    begin
        Seed(Row);
        asserterror Row.TestField(Kind, Row.Kind::Alpha);
        Observer.Observe('enum', Helper.LastError());
        Observer.Finish();
    end;

    [Test]
    procedure EnumBlankTestField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS TF Row";
    begin
        Seed(Row);
        asserterror Row.TestField(Kind);
        Observer.Observe('enum_blank', Helper.LastError());
        Observer.Finish();
    end;

    [Test]
    procedure GuidOnCode()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS TF Row";
        G: Guid;
    begin
        Seed(Row);
        Evaluate(G, '{11111111-2222-3333-4444-555555555555}');
        asserterror Row.TestField(Cd, G);
        Observer.Observe('guid', Helper.LastError());
        Observer.Finish();
    end;

    [Test]
    procedure GuidOnCodeSameText()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS TF Row";
        G: Guid;
    begin
        Seed(Row);
        Evaluate(G, '{11111111-2222-3333-4444-555555555555}');
        Row.Cd := Format(G);
        ClearLastError();
        if TryTestCd(Row, G) then
            Observer.Observe('guid_same', 'ok')
        else
            Observer.Observe('guid_same', Helper.LastError());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryTestCd(var Row: Record "LT AS TF Row"; G: Guid)
    begin
        Row.TestField(Cd, G);
    end;

    [Test]
    procedure ModifyAll_PK_ZeroRows()
    var
        Observer: Codeunit "Probe Observer";
        P: Record "LT AS Caption PK";
    begin
        P.DeleteAll();
        ClearLastError();
        if TryModifyAllKey(P) then
            Observer.Observe('zero', 'ok')
        else
            Observer.Observe('zero', Helper.LastError());
        Observer.Finish();
    end;

    [Test]
    procedure ModifyAll_PK_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        P: Record "LT AS Caption PK";
    begin
        P.DeleteAll();
        P."Key Code" := 'K1';
        P.Insert();
        asserterror P.ModifyAll("Key Code", 'K2');
        Observer.Observe('one', Helper.LastError());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryModifyAllKey(var P: Record "LT AS Caption PK")
    begin
        P.ModifyAll("Key Code", 'K2');
    end;

    local procedure DateFilter(Text: Text): Text
    var
        I: Record "LT AS Int Key";
    begin
        I.SetFilter(D, Text);
        exit(Format(Date2DMY(I.GetRangeMin(D), 3)) + '-' + Format(Date2DMY(I.GetRangeMax(D), 3)) + ' ' + I.GetFilter(D));
    end;

    [Test]
    procedure DateFilter_TwoDigitYear_29To39()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('y29', DateFilter('01/02/29'));
        Observer.Observe('y30', DateFilter('01/02/30'));
        Observer.Observe('y39', DateFilter('01/02/39'));
        Observer.Finish();
    end;

    [Test]
    procedure DateFilter_TwoDigitYear_40To50()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('y45', DateFilter('01/02/45'));
        Observer.Observe('y49', DateFilter('01/02/49'));
        Observer.Observe('y50', DateFilter('01/02/50'));
        Observer.Finish();
    end;

    [Test]
    procedure DateFilter_TwoDigitYear_Range()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('r39_49', DateFilter('01/02/39..12/30/49'));
        Observer.Observe('digits', DateFilter('010239'));
        Observer.Finish();
    end;
}
