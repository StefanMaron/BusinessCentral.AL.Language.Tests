// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: ALT Codeunit Meta Probe (60963), ALT Universal (60000), SIS Cache (60608)
//
// Pins the built-in "CodeUnit Metadata" system virtual table (2000000137): one row per
// codeunit declared in the application, computed from the codeunit's own metadata rather
// than stored anywhere. It is the sibling of Table Metadata (2000000136) and Page Metadata
// (2000000138), which this suite already covers.
//
// Each column asserted below is read off a codeunit whose declaration states a known,
// non-default value, so a provider answering every Get with a fixed or blank row would fail
// here. The negative tests carry as much weight as the positive ones for the same reason.

codeunit 60962 "Test Codeunit Metadata Virt T"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Record_CodeunitMetadata_Get_DeclaredCodeunit_ReturnsMatchingRow()
    var
        CodeunitMetadata: Record "CodeUnit Metadata";
    begin
        Initialize();

        // [WHEN] reading the virtual table for a compiled codeunit by its object id
        Assert.IsTrue(
            CodeunitMetadata.Get(Codeunit::"ALT Codeunit Meta Probe"),
            'CodeUnit Metadata has no row for codeunit ALT Codeunit Meta Probe.');

        // [THEN] every column is computed from that codeunit's own AL declaration.
        Assert.AreEqual(
            'ALT Codeunit Meta Probe', CodeunitMetadata.Name,
            'Unexpected Name for ALT Codeunit Meta Probe.');
        Assert.AreEqual(
            Database::"ALT Universal", CodeunitMetadata.TableNo,
            'Unexpected TableNo for ALT Codeunit Meta Probe, which declares TableNo = "ALT Universal".');
        Assert.AreEqual(
            CodeunitMetadata.Subtype::Normal, CodeunitMetadata.Subtype,
            'Unexpected Subtype for ALT Codeunit Meta Probe, which declares no Subtype.');
        Assert.IsFalse(
            CodeunitMetadata.SingleInstance,
            'ALT Codeunit Meta Probe declares no SingleInstance, so the column must read false.');
    end;

    [Test]
    procedure Record_CodeunitMetadata_Get_SingleInstanceCodeunit_ReturnsTrueAndNoTableNo()
    var
        CodeunitMetadata: Record "CodeUnit Metadata";
    begin
        Initialize();

        // SIS Cache declares SingleInstance = true and no TableNo — the mirror image of the
        // probe above, so the two together prove both columns vary with the declaration
        // instead of being constants.
        Assert.IsTrue(
            CodeunitMetadata.Get(Codeunit::"SIS Cache"),
            'CodeUnit Metadata has no row for codeunit SIS Cache.');

        Assert.IsTrue(
            CodeunitMetadata.SingleInstance,
            'SIS Cache declares SingleInstance = true, so the column must read true.');
        Assert.AreEqual(
            0, CodeunitMetadata.TableNo,
            'SIS Cache declares no TableNo, so the column must read 0.');
    end;

    [Test]
    procedure Record_CodeunitMetadata_Get_TestCodeunit_ReportsSubtypeTest()
    var
        CodeunitMetadata: Record "CodeUnit Metadata";
    begin
        Initialize();

        // The codeunit running this assertion declares Subtype = Test, so its own row is the
        // one value of Subtype this suite can state without depending on another app.
        Assert.IsTrue(
            CodeunitMetadata.Get(Codeunit::"Test Codeunit Metadata Virt T"),
            'CodeUnit Metadata has no row for the test codeunit itself.');

        Assert.AreEqual(
            CodeunitMetadata.Subtype::Test, CodeunitMetadata.Subtype,
            'A codeunit declaring Subtype = Test must report Subtype::Test.');
    end;

    [Test]
    procedure Record_CodeunitMetadata_Get_UnknownCodeunitId_ReturnsFalse()
    var
        CodeunitMetadata: Record "CodeUnit Metadata";
    begin
        Initialize();

        // Negative control: a provider that answers every Get with true (a fixed or blank
        // row) would pass every positive test above and fail here.
        Assert.IsFalse(
            CodeunitMetadata.Get(99999999),
            'CodeUnit Metadata must not have a row for an id no codeunit uses.');
    end;

    [Test]
    procedure Record_CodeunitMetadata_FilterOnId_DiscriminatesBetweenRows()
    var
        CodeunitMetadata: Record "CodeUnit Metadata";
    begin
        Initialize();

        // A filter naming one existing codeunit selects exactly that codeunit...
        CodeunitMetadata.SetRange(ID, Codeunit::"ALT Codeunit Meta Probe");
        Assert.AreEqual(1, CodeunitMetadata.Count(), 'A filter on one existing codeunit id must select one row.');
        Assert.IsTrue(CodeunitMetadata.FindSet(), 'FindSet must succeed for a filter naming an existing codeunit.');
        Assert.AreEqual(
            'ALT Codeunit Meta Probe', CodeunitMetadata.Name,
            'The filtered row must be the codeunit the filter named.');

        // ...and a filter naming an id no codeunit uses selects none.
        CodeunitMetadata.SetRange(ID, 99999999);
        Assert.AreEqual(0, CodeunitMetadata.Count(), 'A filter on an unused id must select no rows.');
        Assert.IsFalse(CodeunitMetadata.FindSet(), 'FindSet must fail for a filter naming no codeunit.');
        Assert.IsTrue(CodeunitMetadata.IsEmpty(), 'IsEmpty must be true for a filter naming no codeunit.');
    end;

    local procedure Initialize()
    begin
        // CodeUnit Metadata is a read-only system virtual table — nothing to DeleteAll.
    end;
}
