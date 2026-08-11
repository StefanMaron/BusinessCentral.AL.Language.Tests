// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: ALT List Page (60016), ALT Universal (60000)
//
// Pins the built-in "Page Control Field" system virtual table (2000000192): one row per
// field control declared on a page, computed from the page's own metadata rather than
// stored anywhere — including controls declared Visible = false, which is what
// personalization-availability checks read. A provider that returns an empty result set
// for this table fails silently (FindFirst simply returns false, no error), so a test
// asserting a control is *absent* would pass against a broken provider just as easily as
// a correct one — see BusinessCentral.AL.Runner issue #1779. Enabled/Editable/Visible are
// TEXT columns carrying the resolved property expression, not Boolean, which is why they
// round-trip through Evaluate() rather than a direct comparison.

codeunit 60921 "Test Page Control Field Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Record_PageControlField_VisibleControl_ResolvesTableFieldAndVisibleTrue()
    var
        PageControlField: Record "Page Control Field";
        IsVisible: Boolean;
    begin
        Initialize();

        // [GIVEN] "Entry No." is a plain field control on ALT List Page with no Visible
        // property declared (AL's default is Visible = true).
        PageControlField.SetRange(PageNo, Page::"ALT List Page");
        PageControlField.SetRange(ControlName, 'Entry No.');
        Assert.IsTrue(PageControlField.FindFirst(), 'Page Control Field has no row for control "Entry No." of ALT List Page.');

        // [THEN] the control resolves to the real source table/field, not a default/blank row.
        Assert.AreEqual(Database::"ALT Universal", PageControlField.TableNo, 'Unexpected TableNo for control "Entry No.".');
        Assert.AreEqual(1, PageControlField.FieldNo, 'Unexpected FieldNo for control "Entry No." (expected the "Entry No." field, id 1).');

        Assert.IsTrue(Evaluate(IsVisible, PageControlField.Visible), 'Visible column is not an evaluable Boolean expression.');
        Assert.IsTrue(IsVisible, 'A control with no declared Visible property must default to visible.');
    end;

    [Test]
    procedure Record_PageControlField_HiddenControl_VisibleIsFalse()
    var
        PageControlField: Record "Page Control Field";
        IsVisible: Boolean;
    begin
        Initialize();

        // [GIVEN] "Name Field" is declared Visible = false on ALT List Page.
        PageControlField.SetRange(PageNo, Page::"ALT List Page");
        PageControlField.SetRange(ControlName, 'Name Field');
        Assert.IsTrue(PageControlField.FindFirst(), 'Page Control Field has no row for control "Name Field" of ALT List Page.');

        Assert.AreEqual(Database::"ALT Universal", PageControlField.TableNo, 'Unexpected TableNo for control "Name Field".');
        Assert.AreEqual(18, PageControlField.FieldNo, 'Unexpected FieldNo for control "Name Field" (expected the "Name Field" field, id 18).');

        // [THEN] the declared Visible = false must round-trip as an evaluable false, not be
        // silently dropped or reported as the visible default.
        Assert.IsTrue(Evaluate(IsVisible, PageControlField.Visible), 'Visible column is not an evaluable Boolean expression.');
        Assert.IsFalse(IsVisible, 'Control "Name Field" declares Visible = false; the virtual table must report that, not the visible default.');
    end;

    [Test]
    procedure Record_PageControlField_UnknownPage_FindsNothing()
    var
        PageControlField: Record "Page Control Field";
    begin
        Initialize();

        // Negative control: an empty/broken provider would also pass this on its own — it
        // only proves something when read together with the positive tests above, which
        // demonstrate the table actually carries rows for a page that HAS controls.
        PageControlField.SetRange(PageNo, 99999999);
        Assert.IsFalse(PageControlField.FindFirst(), 'Page Control Field must not have rows for a page id no page uses.');
        Assert.IsTrue(PageControlField.IsEmpty(), 'Page Control Field must be empty for a page id no page uses.');
    end;

    local procedure Initialize()
    begin
        // Page Control Field is a read-only system virtual table — nothing to DeleteAll.
    end;
}
