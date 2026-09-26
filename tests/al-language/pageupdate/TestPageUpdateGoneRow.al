// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope (Cloud-compatible) -- every member is driven from a [Test] with no client
// Fixtures used: ALT Page Update Gone Row (67300), ALT Page Update Gone Card (67300),
//   ALT Page Update Gone Trace (67301); shared Assert (60021)
// BC versions: 27.0+
//
/// <summary>
/// CLAIM: what the refresh CurrPage.Update(false) asks for raises when the page's current row
/// is not in the table.
///
///   1. A row the page's own action deleted before calling CurrPage.Update(false), with another
///      row still stored, and with none left.
///   2. A row deleted by the test while the page showed it, followed by an action calling
///      CurrPage.Update(false).
///   3. A new row on a DelayedInsert page whose field OnValidate calls CurrPage.Update(false):
///      the call does not save, so the row the refresh would re-read is still unsaved. Once
///      with the key set, once without.
///   4. Controls: the same two CurrPage.Update(false) routes on a stored row.
/// </summary>
codeunit 67300 "ALT Page Update Gone Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Trace: Codeunit "ALT Page Update Gone Trace";

    local procedure Seed(WithNeighbour: Boolean)
    var
        Row: Record "ALT Page Update Gone Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Code := 'A';
        Row.Name := 'Alpha';
        Row.Insert();
        if WithNeighbour then begin
            Row.Init();
            Row.Code := 'B';
            Row.Name := 'Beta';
            Row.Insert();
        end;
    end;

    [Test]
    procedure DeletedByAction_WithNeighbour_Refresh()
    var
        Card: TestPage "ALT Page Update Gone Card";
    begin
        Seed(true);
        Card.OpenEdit();
        Card.GoToKey('A');
        Trace.Reset();

        Card.DeleteAndUpdate.Invoke();

        Assert.AreEqual('AGR:B;AGCR:B;', Trace.AfterActionEnd(),
            'refresh after deleting the current row; full trace: ' + Trace.Get() + ' shows: ' + Card.CodeField.Value());
        Assert.AreEqual('B', Card.CodeField.Value(), 'row shown after the refresh; full trace: ' + Trace.Get());
        Card.Close();
    end;

    [Test]
    procedure DeletedByAction_LastRow_Refresh()
    var
        Card: TestPage "ALT Page Update Gone Card";
    begin
        Seed(false);
        Card.OpenEdit();
        Card.GoToKey('A');
        Trace.Reset();

        Card.DeleteAndUpdate.Invoke();

        Assert.AreEqual('', Trace.AfterActionEnd(),
            'refresh after deleting the only row; full trace: ' + Trace.Get() + ' shows: ' + Card.CodeField.Value());
        Assert.AreEqual('', Card.CodeField.Value(), 'row shown after the refresh; full trace: ' + Trace.Get());
        Card.Close();
    end;

    [Test]
    procedure DeletedUnderneath_ThenUpdateAction_Refresh()
    var
        Row: Record "ALT Page Update Gone Row";
        Card: TestPage "ALT Page Update Gone Card";
    begin
        Seed(true);
        Card.OpenEdit();
        Card.GoToKey('A');
        Row.Get('A');
        Row.Delete();
        Trace.Reset();

        Card.UpdateOnly.Invoke();

        Assert.AreEqual('AGR:B;AGCR:B;', Trace.AfterActionEnd(),
            'refresh after the shown row was deleted underneath; full trace: ' + Trace.Get() + ' shows: ' + Card.CodeField.Value());
        Assert.AreEqual('B', Card.CodeField.Value(), 'row shown after the refresh; full trace: ' + Trace.Get());
        Card.Close();
    end;

    [Test]
    procedure StoredRow_UpdateAction_Refresh()
    var
        Card: TestPage "ALT Page Update Gone Card";
    begin
        Seed(true);
        Card.OpenEdit();
        Card.GoToKey('A');
        Trace.Reset();

        Card.UpdateOnly.Invoke();

        Assert.AreEqual('AGR:A;AGCR:A;', Trace.AfterActionEnd(),
            'control: refresh of a stored row; full trace: ' + Trace.Get());
        Card.Close();
    end;

    [Test]
    procedure UnsavedKeyedRow_OnValidateUpdateFalse_Trace()
    var
        Row: Record "ALT Page Update Gone Row";
        Card: TestPage "ALT Page Update Gone Card";
    begin
        Row.DeleteAll();
        Card.OpenNew();
        Card.CodeField.SetValue('K');
        Trace.Reset();

        Card.NameField.SetValue('Kappa');

        Assert.AreEqual('Validate;', Trace.Get(), 'OnValidate CurrPage.Update(false) on an unsaved DelayedInsert row');
        Assert.IsFalse(Row.Get('K'), 'CurrPage.Update(false) must not save the DelayedInsert row');
        Card.Close();
    end;

    [Test]
    procedure UnsavedBlankRow_OnValidateUpdateFalse_Trace()
    var
        Row: Record "ALT Page Update Gone Row";
        Card: TestPage "ALT Page Update Gone Card";
    begin
        Row.DeleteAll();
        Card.OpenNew();
        Trace.Reset();

        Card.NameField.SetValue('Blank');

        Assert.AreEqual('Validate;', Trace.Get(), 'OnValidate CurrPage.Update(false) on an unsaved DelayedInsert row with no key');
        Assert.IsTrue(Row.IsEmpty(), 'CurrPage.Update(false) must not save the DelayedInsert row');
        Card.Close();
    end;

    [Test]
    procedure StoredRow_OnValidateUpdateFalse_Trace()
    var
        Card: TestPage "ALT Page Update Gone Card";
    begin
        Seed(true);
        Card.OpenEdit();
        Card.GoToKey('A');
        Trace.Reset();

        Card.NameField.SetValue('Alpha 2');

        Assert.AreEqual('Validate;AGR:A;AGCR:A;', Trace.Get(), 'control: OnValidate CurrPage.Update(false) on a stored row');
        Card.Close();
    end;
}
