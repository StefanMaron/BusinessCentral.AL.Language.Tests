// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope (Cloud-compatible) -- every member is driven from a [Test] with no client
// Fixtures used: ALT Page Update Gone Row (67300), ALT Page Update Gone Card (67300),
//   ALT Page Update Gone List (67301), ALT Page Update Gone Trace (67301); shared Assert (60021)
// BC versions: 27.0+
//
/// <summary>
/// CLAIM: what the refresh CurrPage.Update(false) asks for does when the page's current row is
/// not in the table.
///
///   1. A Card whose current row was deleted -- by its own action, or by the test underneath it
///      -- closes when an action's CurrPage.Update(false) refreshes it: the TestPage is no longer
///      open afterwards. Control: deleting the row without CurrPage.Update leaves it open.
///   2. The same shape on a List page.
///   3. A new row on a DelayedInsert page whose field OnValidate calls CurrPage.Update(false):
///      the call does not save, and the refresh raises neither OnAfterGetRecord nor
///      OnAfterGetCurrRecord for the unsaved row. Once with the key set, once without.
///   4. Controls: the same two CurrPage.Update(false) routes on a stored row refresh it.
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
    procedure Card_DeletedByAction_WithNeighbour_UpdateClosesThePage()
    var
        Card: TestPage "ALT Page Update Gone Card";
        Recorded: Text;
    begin
        Seed(true);
        Card.OpenEdit();
        Card.GoToKey('A');
        Trace.Reset();

        Card.DeleteAndUpdate.Invoke();
        Recorded := Trace.Get();

        asserterror Card.CodeField.Value();
        Assert.ExpectedError('The TestPage is not open.');
        Assert.AreEqual('ActionBegin;ActionEnd;', Recorded, 'triggers raised around the refresh of a deleted row');
    end;

    [Test]
    procedure Card_DeletedByAction_LastRow_UpdateClosesThePage()
    var
        Card: TestPage "ALT Page Update Gone Card";
        Recorded: Text;
    begin
        Seed(false);
        Card.OpenEdit();
        Card.GoToKey('A');
        Trace.Reset();

        Card.DeleteAndUpdate.Invoke();
        Recorded := Trace.Get();

        asserterror Card.CodeField.Value();
        Assert.ExpectedError('The TestPage is not open.');
        Assert.AreEqual('ActionBegin;ActionEnd;', Recorded, 'triggers raised around the refresh of the deleted only row');
    end;

    [Test]
    procedure Card_DeletedUnderneath_UpdateActionClosesThePage()
    var
        Row: Record "ALT Page Update Gone Row";
        Card: TestPage "ALT Page Update Gone Card";
        Recorded: Text;
    begin
        Seed(true);
        Card.OpenEdit();
        Card.GoToKey('A');
        Row.Get('A');
        Row.Delete();
        Trace.Reset();

        Card.UpdateOnly.Invoke();
        Recorded := Trace.Get();

        asserterror Card.CodeField.Value();
        Assert.ExpectedError('The TestPage is not open.');
        Assert.AreEqual('ActionBegin;ActionEnd;', Recorded, 'triggers raised around the refresh of a row deleted underneath');
    end;

    [Test]
    procedure Card_DeletedByAction_NoUpdate_PageStaysOpen()
    var
        Card: TestPage "ALT Page Update Gone Card";
        Recorded: Text;
        Shown: Text;
    begin
        Seed(true);
        Card.OpenEdit();
        Card.GoToKey('A');
        Trace.Reset();

        Card.DeleteOnly.Invoke();
        Recorded := Trace.Get();
        Shown := Card.CodeField.Value();

        Assert.AreEqual('ActionBegin;ActionEnd;', Recorded, 'control: deleting without CurrPage.Update; shows ' + Shown);
        Assert.AreEqual('A', Shown, 'control: the row shown after deleting without CurrPage.Update; trace ' + Recorded);
        Card.Close();
    end;

    [Test]
    procedure List_DeletedByAction_WithNeighbour_Refresh()
    var
        List: TestPage "ALT Page Update Gone List";
        Recorded: Text;
        Shown: Text;
    begin
        Seed(true);
        List.OpenEdit();
        List.GoToKey('A');
        Trace.Reset();

        List.DeleteAndUpdate.Invoke();
        Recorded := Trace.Get();
        Shown := List.CodeField.Value();

        Assert.AreEqual('ActionBegin;ActionEnd;AGR:B;AGCR:B;', Recorded, 'list: refresh after deleting the current row; shows ' + Shown);
        Assert.AreEqual('B', Shown, 'list: the row shown after the refresh; trace ' + Recorded);
        List.Close();
    end;

    [Test]
    procedure Card_StoredRow_UpdateAction_RefreshesTheRow()
    var
        Card: TestPage "ALT Page Update Gone Card";
        After: Text;
    begin
        Seed(true);
        Card.OpenEdit();
        Card.GoToKey('A');
        Trace.Reset();

        Card.UpdateOnly.Invoke();
        After := Trace.AfterActionEnd();

        // BC raises OnAfterGetRecord more than once around an action (AGR:A;AGR:A;AGCR:A on the
        // first run of this suite); the count of OnAfterGetCurrRecord and the row are the claim.
        Assert.AreEqual('AGCR:A;', CopyStr(After, StrLen(After) - StrLen('AGCR:A;') + 1),
            'control: the refresh of a stored row ends with its OnAfterGetCurrRecord; trace ' + Trace.Get());
        Assert.AreNotEqual(0, StrPos(After, 'AGR:A;'), 'control: OnAfterGetRecord runs for the stored row; trace ' + Trace.Get());
        Assert.AreEqual('A', Card.CodeField.Value(), 'control: the page stays on the stored row');
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
