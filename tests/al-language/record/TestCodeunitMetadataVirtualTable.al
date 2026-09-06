// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: ALT Codeunit Meta Probe (60963), ALT Universal (60000), SIS Cache (60608),
//                ALT Install Probe (60838)
//
// Pins the built-in "CodeUnit Metadata" system virtual table (2000000137): one row per
// codeunit declared in the application, computed from the codeunit's own metadata rather
// than stored anywhere. It is the sibling of Table Metadata (2000000136) and Page Metadata
// (2000000138), pinned in TestTableMetadataVirtualTable.al and
// TestPageMetadataVirtualTable.al respectively.
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
    procedure Record_CodeunitMetadata_Get_InstallCodeunit_ReportsSubtypeNormal()
    var
        InstallCodeunit: Record "CodeUnit Metadata";
        TestCodeunit: Record "CodeUnit Metadata";
        InstallSubtypeOrdinal: Integer;
        TestSubtypeOrdinal: Integer;
    begin
        Initialize();

        // AL accepts five codeunit subtypes. This column's OptionMembers name four of them --
        // Normal,Test,TestRunner,Upgrade -- and Install is the fifth. ALT Install Probe
        // declares Install, so this reads the one subtype the column has no member for; every
        // other codeunit in this suite declares one of the four.
        //
        // [WHEN] reading the row of a codeunit whose declared Subtype the column does not name
        Assert.IsTrue(
            InstallCodeunit.Get(Codeunit::"ALT Install Probe"),
            'CodeUnit Metadata has no row for codeunit ALT Install Probe.');

        // [THEN] the row exists -- an Install codeunit is enumerated like any other -- and the
        // column reports Normal, ordinal 0. Install does not reach this column at all: it is
        // neither carried through as an ordinal past the members the column names, nor clamped
        // to the last of them.
        InstallSubtypeOrdinal := InstallCodeunit.Subtype;
        Assert.AreEqual(
            0, InstallSubtypeOrdinal,
            'A codeunit declaring Subtype = Install must report ordinal 0 in the SubType column.');
        Assert.AreEqual(
            InstallCodeunit.Subtype::Normal, InstallCodeunit.Subtype,
            'A codeunit declaring Subtype = Install must report Subtype::Normal.');

        // [AND] the column is not simply always Normal. Read in the same run, a codeunit that
        // declares Subtype = Test reports Test, ordinal 1 -- so the answer above is what this
        // column reports for Install specifically, not what it reports for every codeunit.
        Assert.IsTrue(
            TestCodeunit.Get(Codeunit::"Test Codeunit Metadata Virt T"),
            'CodeUnit Metadata has no row for the test codeunit itself.');
        TestSubtypeOrdinal := TestCodeunit.Subtype;
        Assert.AreEqual(
            1, TestSubtypeOrdinal,
            'A codeunit declaring Subtype = Test must report ordinal 1 in the SubType column.');
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
