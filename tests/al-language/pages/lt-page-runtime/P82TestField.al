// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P82 Card (71187), LT P82 Item (71184), LT P82 Log (71186) from P82Fixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TestField Value versus AsInteger / AsDecimal / AsBoolean / AsDate / AsDateTime, AssertEquals overloads and the start of its failure texts, SetValue overloads, Editable / Visible / Enabled / ShowMandatory / IsMandatory / HideValue of static and dynamic controls
// BC versions: 29 (27 and 28 by CI)

codeunit 71203 "LT P82 TestField"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Item: Record "LT P82 Item";
        Log: Codeunit "LT P82 Log";
    begin
        Item.DeleteAll();
        Log.Reset();
        Item."No." := 'T1';
        Item.Name := 'Typed';
        Item.Qty := 42;
        Item.Amount := 2.5;
        Item.Flag := true;
        Item.DateF := DMY2Date(15, 3, 2024);
        Item.DT := CreateDateTime(DMY2Date(15, 3, 2024), 102030T);
        Item.Insert();
        Item."No." := 'T2';
        Item.Name := '';
        Item.Qty := -7;
        Item.Amount := -0.125;
        Item.Flag := false;
        Item.DateF := 0D;
        Item.DT := 0DT;
        Item.Insert();
    end;

    [Test]
    procedure Value_And_As_OnFilledRow()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenView();
        Card.GoToKey('T1');
        Observer.Observe('qty-value', Card.QtyCtl.Value());
        Observer.Observe('qty-asinteger', Format(Card.QtyCtl.AsInteger()));
        Observer.Observe('qty-asdecimal', Format(Card.QtyCtl.AsDecimal()));
        Observer.Observe('amt-value', Card.AmtCtl.Value());
        Observer.Observe('amt-asdecimal', Format(Card.AmtCtl.AsDecimal()));
        Observer.Observe('flag-value', Card.FlagCtl.Value());
        Observer.Observe('flag-asboolean', Format(Card.FlagCtl.AsBoolean()));
        Observer.Observe('date-value', Card.DateCtl.Value());
        Observer.Observe('date-asdate', Format(Card.DateCtl.AsDate(), 0, 9));
        Observer.Observe('dt-value', Card.DtCtl.Value());
        Observer.Observe('dt-asdatetime', Format(Card.DtCtl.AsDateTime(), 0, 9));
        Observer.Observe('name-value', Card.NameCtl.Value());
        Observer.Observe('no-value', Card.NoCtl.Value());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Value_And_As_OnEmptyAndNegativeRow()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenView();
        Card.GoToKey('T2');
        Observer.Observe('qty-value', Card.QtyCtl.Value());
        Observer.Observe('qty-asinteger', Format(Card.QtyCtl.AsInteger()));
        Observer.Observe('amt-value', Card.AmtCtl.Value());
        Observer.Observe('amt-asdecimal', Format(Card.AmtCtl.AsDecimal(), 0, 9));
        Observer.Observe('flag-value', Card.FlagCtl.Value());
        Observer.Observe('flag-asboolean', Format(Card.FlagCtl.AsBoolean()));
        Observer.Observe('date-value', Card.DateCtl.Value());
        Observer.Observe('date-asdate', Format(Card.DateCtl.AsDate(), 0, 9));
        Observer.Observe('date-asdate-is-0D', Format(Card.DateCtl.AsDate() = 0D));
        Observer.Observe('dt-value', Card.DtCtl.Value());
        Observer.Observe('dt-asdatetime-is-0DT', Format(Card.DtCtl.AsDateTime() = 0DT));
        Observer.Observe('name-value-empty', Format(Card.NameCtl.Value() = ''));
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure AssertEquals_Passing_Overloads()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenView();
        Card.GoToKey('T1');
        Card.NameCtl.AssertEquals('Typed');
        Observer.Observe('text', 'ok');
        Card.QtyCtl.AssertEquals(42);
        Observer.Observe('integer', 'ok');
        Card.QtyCtl.AssertEquals('42');
        Observer.Observe('integer-as-text', 'ok');
        Card.AmtCtl.AssertEquals(2.5);
        Observer.Observe('decimal', 'ok');
        Card.FlagCtl.AssertEquals(true);
        Observer.Observe('boolean', 'ok');
        Card.DateCtl.AssertEquals(DMY2Date(15, 3, 2024));
        Observer.Observe('date', 'ok');
        Card.DtCtl.AssertEquals(CreateDateTime(DMY2Date(15, 3, 2024), 102030T));
        Observer.Observe('datetime', 'ok');
        asserterror Card.NameCtl.AssertEquals('typed');
        Observer.ObserveError('af152');
        Observer.Observe('text-case-differs', 'ok');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure AssertEquals_Failing_Texts()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenView();
        Card.GoToKey('T1');
        asserterror Card.NameCtl.AssertEquals('Other');
        Observer.ObserveError('text');
        asserterror Card.QtyCtl.AssertEquals(43);
        Observer.ObserveError('integer');
        asserterror Card.AmtCtl.AssertEquals(2.75);
        Observer.ObserveError('decimal');
        asserterror Card.FlagCtl.AssertEquals(false);
        Observer.ObserveError('boolean');
        asserterror Card.DateCtl.AssertEquals(DMY2Date(16, 3, 2024));
        Observer.ObserveError('date');
        Card.DtCtl.AssertEquals(CreateDateTime(DMY2Date(15, 3, 2024), 102031T));
        Observer.Observe('datetime', 'no error');
        asserterror Card.NameCtl.AssertEquals(5);
        Observer.ObserveError('text-vs-integer');
        asserterror Card.QtyCtl.AssertEquals('abc');
        Observer.ObserveError('integer-vs-text');
        asserterror Card.QtyCtl.AssertEquals(true);
        Observer.ObserveError('integer-vs-boolean');
        asserterror Card.NameCtl.AssertEquals('');
        Observer.ObserveError('text-vs-empty');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_Overloads()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P82 Item";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('T1');
        Card.NameCtl.SetValue('Text set');
        Observer.Observe('name', Card.NameCtl.Value());
        Card.QtyCtl.SetValue(7);
        Observer.Observe('qty-integer', Card.QtyCtl.Value());
        Card.QtyCtl.SetValue('8');
        Observer.Observe('qty-text', Card.QtyCtl.Value());
        Card.QtyCtl.SetValue(9.0);
        Observer.Observe('qty-decimal-integral', Card.QtyCtl.Value());
        Card.AmtCtl.SetValue(3.75);
        Observer.Observe('amt-decimal', Card.AmtCtl.Value());
        Card.AmtCtl.SetValue(4);
        Observer.Observe('amt-integer', Card.AmtCtl.Value());
        Card.FlagCtl.SetValue(false);
        Observer.Observe('flag-boolean', Card.FlagCtl.Value());
        Card.FlagCtl.SetValue('Yes');
        Observer.Observe('flag-text-yes', Card.FlagCtl.Value());
        Card.DateCtl.SetValue(DMY2Date(1, 2, 2025));
        Observer.Observe('date', Format(Card.DateCtl.AsDate(), 0, 9));
        Card.DtCtl.SetValue(CreateDateTime(DMY2Date(1, 2, 2025), 080910T));
        Observer.Observe('dt', Format(Card.DtCtl.AsDateTime(), 0, 9));
        Card.NameCtl.SetValue('');
        Observer.Observe('name-empty', Format(Card.NameCtl.Value() = ''));
        Card.Close();
        Item.Get('T1');
        Observer.Observe('stored-name', Item.Name);
        Observer.Observe('stored-qty', Format(Item.Qty));
        Observer.Observe('stored-amount', Format(Item.Amount));
        Observer.Observe('stored-flag', Format(Item.Flag));
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_Invalid()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('T1');
        asserterror Card.QtyCtl.SetValue('abc');
        Observer.ObserveError('qty-abc');
        asserterror Card.QtyCtl.SetValue(1.5);
        Observer.ObserveError('qty-1.5');
        asserterror Card.QtyCtl.SetValue('99999999999');
        Observer.ObserveError('qty-overflow');
        asserterror Card.AmtCtl.SetValue('x.y');
        Observer.ObserveError('amt-xy');
        asserterror Card.FlagCtl.SetValue('maybe');
        Observer.ObserveError('flag-maybe');
        asserterror Card.DateCtl.SetValue('not a date');
        Observer.ObserveError('date-text');
        asserterror Card.DtCtl.SetValue('not a datetime');
        Observer.ObserveError('dt-text');
        Card.NameCtl.SetValue('0123456789012345678901234567890123456789012345678901234567890');
        Observer.Observe('name-too-long', 'no error');
        asserterror Card.GrpCtl.SetValue('NOGROUP');
        Observer.ObserveError('grp-relation');
        Card.NoCtl.SetValue('012345678901234567890123');
        Observer.Observe('no-too-long', 'no error');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure ValidationErrors_AfterFailedSetValue()
    var
        Msg: Text;
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('T1');
        Observer.Observe('count-initial', Format(Card.ValidationErrorCount()));
        asserterror Card.QtyCtl.SetValue('abc');
        Observer.ObserveError('set-abc');
        Observer.Observe('count-after-failed-set', Format(Card.ValidationErrorCount()));
        Msg := Card.GetValidationError(1);
        Observer.Observe('get-error-1', 'no error');
        asserterror Msg := Card.GetValidationError(0);
        Observer.ObserveError('get-error-0');
        asserterror Msg := Card.GetValidationError(-1);
        Observer.ObserveError('get-error-minus-1');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Properties_DynamicVisible_And_ShowMandatory()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('T1');
        Observer.Observe('vis-before', Format(Card.VisDynCtl.Visible()));
        Card.ActVis.Invoke();
        Observer.Observe('vis-after-toggle', Format(Card.VisDynCtl.Visible()));
        Card.ActVis.Invoke();
        Observer.Observe('vis-after-second-toggle', Format(Card.VisDynCtl.Visible()));
        Observer.Observe('name-showmandatory', Format(Card.NameCtl.ShowMandatory()));
        Observer.Observe('no-showmandatory', Format(Card.NoCtl.ShowMandatory()));
        Observer.Observe('mand-before', Format(Card.MandDynCtl.ShowMandatory()));
        Card.ActMand.Invoke();
        Observer.Observe('mand-after-toggle', Format(Card.MandDynCtl.ShowMandatory()));
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Properties_HideValue_Dynamic()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('T1');
        Observer.Observe('hide-before', Format(Card.QtyCtl.HideValue()));
        Observer.Observe('value-before', Card.QtyCtl.Value());
        Card.ActHide.Invoke();
        Observer.Observe('hide-after-toggle', Format(Card.QtyCtl.HideValue()));
        Observer.Observe('value-after-toggle', Card.QtyCtl.Value());
        Observer.Observe('asinteger-after-toggle', Format(Card.QtyCtl.AsInteger()));
        Observer.Observe('amt-hide', Format(Card.AmtCtl.HideValue()));
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Properties_ViewMode_Editable()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenView();
        Card.GoToKey('T1');
        Observer.Observe('page-editable', Format(Card.Editable()));
        Observer.Observe('no-editable', Format(Card.NoCtl.Editable()));
        Observer.Observe('name-editable', Format(Card.NameCtl.Editable()));
        Observer.Observe('ro-editable', Format(Card.RoCtl.Editable()));
        Observer.Observe('name-enabled', Format(Card.NameCtl.Enabled()));
        Observer.Observe('name-visible', Format(Card.NameCtl.Visible()));
        Card.NameCtl.SetValue('view mode');
        Observer.Observe('setvalue-in-view', 'no error');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Caption_Of_Controls()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenView();
        Observer.Observe('no-caption', Card.NoCtl.Caption());
        Observer.Observe('name-caption', Card.NameCtl.Caption());
        Observer.Observe('qty-caption', Card.QtyCtl.Caption());
        Observer.Observe('date-caption', Card.DateCtl.Caption());
        Observer.Observe('ro-caption', Card.RoCtl.Caption());
        Card.Close();
        Observer.Finish();
    end;
}
