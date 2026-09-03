// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: none
//
// Pins the built-in "Windows Language" system virtual table (2000000045): one row per culture
// the platform knows about, computed rather than stored. It is the sibling of the Date
// (2000000007), Integer (2000000026) and Page Metadata (2000000138) virtual tables this suite
// already covers.
//
// Asserts only the columns derived from the culture itself. Six further columns come from the
// license and four from installed translation resources; both depend on how the tier is
// licensed and provisioned rather than on the language, so a test naming them would be
// asserting a property of the installation. They are deliberately left out.
//
// "Primary Language ID" is asserted structurally — two English sublanguages must share one,
// and German must not share it — rather than as a number, because it is the id of the primary
// language's default culture and that is the relationship worth pinning.

codeunit 60957 "Test Windows Language Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Record_WindowsLanguage_Get_EnglishUnitedStates_ReturnsItsCultureColumns()
    var
        WindowsLanguage: Record "Windows Language";
    begin
        Assert.IsTrue(WindowsLanguage.Get(1033), 'Windows Language has no row for LCID 1033.');

        Assert.AreEqual('English (United States)', WindowsLanguage.Name, 'Unexpected Name for 1033.');
        Assert.AreEqual('en-US', WindowsLanguage."Language Tag", 'Unexpected Language Tag for 1033.');
        Assert.AreEqual('ENU', WindowsLanguage."Abbreviated Name", 'Unexpected Abbreviated Name for 1033.');
        // The OEM code page, not the ANSI one (1252 would be ANSI). This is the assertion that
        // settles which of the two the column reports.
        Assert.AreEqual('437', WindowsLanguage."Primary CodePage", 'Unexpected Primary CodePage for 1033.');
    end;

    [Test]
    procedure Record_WindowsLanguage_Get_GermanGermany_IsADifferentRow()
    var
        WindowsLanguage: Record "Windows Language";
    begin
        // A second row: a provider answering one fixed row would satisfy the test above.
        Assert.IsTrue(WindowsLanguage.Get(1031), 'Windows Language has no row for LCID 1031.');

        Assert.AreEqual('German (Germany)', WindowsLanguage.Name, 'Unexpected Name for 1031.');
        Assert.AreEqual('de-DE', WindowsLanguage."Language Tag", 'Unexpected Language Tag for 1031.');
        Assert.AreEqual('DEU', WindowsLanguage."Abbreviated Name", 'Unexpected Abbreviated Name for 1031.');
    end;

    [Test]
    procedure Record_WindowsLanguage_PrimaryLanguageId_GroupsSublanguagesTogether()
    var
        EnUs: Record "Windows Language";
        EnGb: Record "Windows Language";
        DeDe: Record "Windows Language";
    begin
        // Structural rather than a number: "Primary Language ID" is what makes two English
        // sublanguages one language, and that relationship is stable across BC versions in a
        // way a specific id may not be.
        Assert.IsTrue(EnUs.Get(1033), 'Windows Language has no row for LCID 1033.');
        Assert.IsTrue(EnGb.Get(2057), 'Windows Language has no row for LCID 2057.');
        Assert.IsTrue(DeDe.Get(1031), 'Windows Language has no row for LCID 1031.');

        Assert.AreEqual('English (United Kingdom)', EnGb.Name, 'Unexpected Name for 2057.');
        Assert.AreEqual(EnUs."Primary Language ID", EnGb."Primary Language ID",
            'en-US and en-GB must report the same Primary Language ID.');
        Assert.AreNotEqual(DeDe."Primary Language ID", EnUs."Primary Language ID",
            'German must not report the same Primary Language ID as English.');
    end;

    [Test]
    procedure Record_WindowsLanguage_GetOnAnUnusedLanguageId_ReturnsFalse()
    var
        WindowsLanguage: Record "Windows Language";
    begin
        // Negative control: a provider answering every Get with a row would pass everything
        // above and fail here.
        Assert.IsFalse(WindowsLanguage.Get(999999),
            'Windows Language must not have a row for an id no culture uses.');
    end;

    [Test]
    procedure Record_WindowsLanguage_FilterOnLanguageId_DiscriminatesBetweenRows()
    var
        WindowsLanguage: Record "Windows Language";
    begin
        WindowsLanguage.SetRange("Language ID", 1033);
        Assert.AreEqual(1, WindowsLanguage.Count(), 'A filter on one existing language id must select one row.');

        WindowsLanguage.SetRange("Language ID", 999999);
        Assert.AreEqual(0, WindowsLanguage.Count(), 'A filter on an unused language id must select no rows.');
        Assert.IsTrue(WindowsLanguage.IsEmpty(), 'IsEmpty must be true for a filter naming no language.');
    end;
}
