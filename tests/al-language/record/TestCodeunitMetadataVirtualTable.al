// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: ALT Codeunit Meta Probe (60963), ALT Universal (60000), SIS Cache (60608),
//                ALT Install Probe (60838), ALT Quoted Install Probe (60828),
//                ALT Quoted Upgrade Probe (60829), ALT Inherent Perm Probe (60138),
//                ALT Inherent Ent Probe (60287), ALT Namespaced Probe (60288)
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

    [Test]
    procedure Record_CodeunitMetadata_Get_QuotedSubtypeInstall_ReportsSubtypeNormal()
    var
        QuotedInstall: Record "CodeUnit Metadata";
        BareInstall: Record "CodeUnit Metadata";
        QuotedOrdinal: Integer;
        BareOrdinal: Integer;
    begin
        Initialize();

        // AL lets a property value be written as a quoted identifier: ALT Quoted Install Probe
        // declares Subtype = "Install" where ALT Install Probe declares Subtype = Install. The
        // quotes are lexical, so the two declarations state the same subtype.
        //
        // [WHEN] reading the row of a codeunit whose Subtype is written as a quoted identifier
        Assert.IsTrue(
            QuotedInstall.Get(Codeunit::"ALT Quoted Install Probe"),
            'CodeUnit Metadata has no row for codeunit ALT Quoted Install Probe.');

        // [THEN] the column reports what it reports for the bare spelling -- Normal, ordinal 0.
        QuotedOrdinal := QuotedInstall.Subtype;
        Assert.AreEqual(
            0, QuotedOrdinal,
            'A codeunit declaring Subtype = "Install" must report ordinal 0 in the SubType column.');
        Assert.AreEqual(
            QuotedInstall.Subtype::Normal, QuotedInstall.Subtype,
            'A codeunit declaring Subtype = "Install" must report Subtype::Normal.');

        // [AND] the two spellings agree, read in the same run.
        Assert.IsTrue(
            BareInstall.Get(Codeunit::"ALT Install Probe"),
            'CodeUnit Metadata has no row for codeunit ALT Install Probe.');
        BareOrdinal := BareInstall.Subtype;
        Assert.AreEqual(
            BareOrdinal, QuotedOrdinal,
            'Quoting the Subtype identifier must not change what the SubType column reports.');
    end;

    [Test]
    procedure Record_CodeunitMetadata_Get_QuotedSubtypeUpgrade_ReportsSubtypeUpgrade()
    var
        QuotedUpgrade: Record "CodeUnit Metadata";
        QuotedInstall: Record "CodeUnit Metadata";
        UpgradeOrdinal: Integer;
    begin
        Initialize();

        // The companion fixture quotes Upgrade, which this column DOES name a member for. It
        // separates the quoting from the subtype: if quoting alone were what mattered, this
        // would answer the same as the Install probe above, and it must not.
        Assert.IsTrue(
            QuotedUpgrade.Get(Codeunit::"ALT Quoted Upgrade Probe"),
            'CodeUnit Metadata has no row for codeunit ALT Quoted Upgrade Probe.');

        UpgradeOrdinal := QuotedUpgrade.Subtype;
        Assert.AreEqual(
            3, UpgradeOrdinal,
            'A codeunit declaring Subtype = "Upgrade" must report ordinal 3 in the SubType column.');
        Assert.AreEqual(
            QuotedUpgrade.Subtype::Upgrade, QuotedUpgrade.Subtype,
            'A codeunit declaring Subtype = "Upgrade" must report Subtype::Upgrade.');

        // Negative control for the pair: the two quoted probes differ, so the column is not
        // answering "whatever a quoted Subtype means" with one fixed value.
        Assert.IsTrue(
            QuotedInstall.Get(Codeunit::"ALT Quoted Install Probe"),
            'CodeUnit Metadata has no row for codeunit ALT Quoted Install Probe.');
        Assert.AreNotEqual(
            QuotedInstall.Subtype, QuotedUpgrade.Subtype,
            'Two codeunits with different quoted Subtypes must not report the same SubType.');
    end;

    [Test]
    procedure Record_CodeunitMetadata_FindSet_EnumeratesEveryProbe_WhenAQuotedSubtypeIsPresent()
    var
        CodeunitMetadata: Record "CodeUnit Metadata";
        SeenIds: List of [Integer];
    begin
        Initialize();

        // Enumeration, not Get: the table must serve every row it knows about even though one
        // of the codeunits in the filtered set states a Subtype this column names no member for
        // AND writes it as a quoted identifier. A provider that stopped enumerating when it met
        // such a row would answer fewer than three here.
        CodeunitMetadata.SetFilter(
            ID, '%1|%2|%3',
            Codeunit::"ALT Quoted Install Probe",
            Codeunit::"ALT Quoted Upgrade Probe",
            Codeunit::"ALT Codeunit Meta Probe");

        Assert.AreEqual(
            3, CodeunitMetadata.Count(),
            'A filter naming three existing codeunits must select three rows.');
        Assert.IsTrue(CodeunitMetadata.FindSet(), 'FindSet must succeed for a filter naming existing codeunits.');
        repeat
            SeenIds.Add(CodeunitMetadata.ID);
        until CodeunitMetadata.Next() = 0;

        Assert.AreEqual(3, SeenIds.Count(), 'FindSet/Next must walk all three filtered rows.');
        Assert.IsTrue(
            SeenIds.Contains(Codeunit::"ALT Quoted Install Probe"),
            'The walk must include the codeunit declaring Subtype = "Install".');
        Assert.IsTrue(
            SeenIds.Contains(Codeunit::"ALT Quoted Upgrade Probe"),
            'The walk must include the codeunit declaring Subtype = "Upgrade".');
        Assert.IsTrue(
            SeenIds.Contains(Codeunit::"ALT Codeunit Meta Probe"),
            'The walk must include the plain codeunit filtered alongside the quoted ones.');
    end;

    [Test]
    procedure Record_CodeunitMetadata_Get_InherentPermissionsAndEntitlements_ReadIndependently()
    var
        PermProbe: Record "CodeUnit Metadata";
        EntProbe: Record "CodeUnit Metadata";
        Neither: Record "CodeUnit Metadata";
    begin
        Initialize();

        // On a codeunit AL accepts exactly one permission kind for these two properties: X
        // (Execute); anything else is AL0195. ALT Inherent Perm Probe declares
        // InherentPermissions = X and no entitlement; ALT Inherent Ent Probe declares
        // InherentEntitlements = X and no permission. Splitting them is what proves the two
        // columns are read independently rather than one being echoed into the other.
        Assert.IsTrue(
            PermProbe.Get(Codeunit::"ALT Inherent Perm Probe"),
            'CodeUnit Metadata has no row for codeunit ALT Inherent Perm Probe.');
        Assert.IsTrue(
            EntProbe.Get(Codeunit::"ALT Inherent Ent Probe"),
            'CodeUnit Metadata has no row for codeunit ALT Inherent Ent Probe.');
        Assert.IsTrue(
            Neither.Get(Codeunit::"ALT Codeunit Meta Probe"),
            'CodeUnit Metadata has no row for codeunit ALT Codeunit Meta Probe.');

        // [THEN] the declared property is spelled 'X' in the mask string...
        Assert.AreEqual(
            'X', PermProbe.InherentPermissions,
            'A codeunit declaring InherentPermissions = X must report InherentPermissions = ''X''.');
        Assert.AreEqual(
            'X', EntProbe.InherentEntitlements,
            'A codeunit declaring InherentEntitlements = X must report InherentEntitlements = ''X''.');

        // [AND] the property the codeunit did NOT declare stays empty on the same row, which is
        // what separates the two columns from each other.
        Assert.AreEqual(
            '', PermProbe.InherentEntitlements,
            'A codeunit declaring only InherentPermissions must report an empty InherentEntitlements.');
        Assert.AreEqual(
            '', EntProbe.InherentPermissions,
            'A codeunit declaring only InherentEntitlements must report an empty InherentPermissions.');

        // [AND] a codeunit declaring neither reports both empty -- the negative control that
        // stops 'X' from being what this table answers for every codeunit.
        Assert.AreEqual(
            '', Neither.InherentPermissions,
            'A codeunit declaring no InherentPermissions must report an empty InherentPermissions.');
        Assert.AreEqual(
            '', Neither.InherentEntitlements,
            'A codeunit declaring no InherentEntitlements must report an empty InherentEntitlements.');
    end;

    [Test]
    procedure Record_CodeunitMetadata_Get_ALNamespace_ReportsTheDeclaringFilesNamespace()
    var
        Namespaced: Record "CodeUnit Metadata";
        UnNamespaced: Record "CodeUnit Metadata";
    begin
        Initialize();

        // ALT Namespaced Probe is declared inside `namespace ALLanguage.Coverage.MetadataProbes;`
        // and is the only object in this application that is. ALT Codeunit Meta Probe sits in a
        // file with no namespace statement. Reading both is what makes this a claim about the
        // column: a column that reported the same string for every codeunit -- blank or
        // otherwise -- would fail one of the two assertions below.
        Assert.IsTrue(
            Namespaced.Get(Codeunit::"ALT Namespaced Probe"),
            'CodeUnit Metadata has no row for codeunit ALT Namespaced Probe.');
        Assert.IsTrue(
            UnNamespaced.Get(Codeunit::"ALT Codeunit Meta Probe"),
            'CodeUnit Metadata has no row for codeunit ALT Codeunit Meta Probe.');

        // [THEN] the namespaced codeunit reports its full dotted namespace -- not the last
        // segment, not the first, and not the codeunit's own name.
        Assert.AreEqual(
            'ALLanguage.Coverage.MetadataProbes', Namespaced."AL Namespace",
            'A codeunit declared inside a namespace must report that namespace in AL Namespace.');

        // [AND] a codeunit whose file states no namespace reports the empty string.
        Assert.AreEqual(
            '', UnNamespaced."AL Namespace",
            'A codeunit declared in a file with no namespace must report an empty AL Namespace.');

        // Negative control: the rows are not blank overall -- Name on each row carries that
        // codeunit's real name, so the values above are what this column answers rather than a
        // symptom of the provider handing back empty rows.
        Assert.AreEqual(
            'ALT Namespaced Probe', Namespaced.Name,
            'The namespaced row must be the codeunit that was asked for.');
        Assert.AreEqual(
            'ALT Codeunit Meta Probe', UnNamespaced.Name,
            'The un-namespaced row must be the codeunit that was asked for.');
    end;

    local procedure Initialize()
    begin
        // CodeUnit Metadata is a read-only system virtual table — nothing to DeleteAll.
    end;
}
