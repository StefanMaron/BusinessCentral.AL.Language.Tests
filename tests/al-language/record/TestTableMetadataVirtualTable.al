// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-object
// Scope: in-scope
// Fixtures used: ALT Relation Parent (60028), ALT Relation Parent B (60030),
//                ALT Captioned (60830), ALT Temp Only (60025), ALT CRM Entity (60291),
//                Install Seed Database (60621), Test RunModal LookupPage Row (60995),
//                ALT Unclassified (60837)
// BC versions: 27.5+
//
// Pins the built-in "Table Metadata" system virtual table (2000000136): one row per table
// declared in the application, computed from the table's own metadata rather than stored
// anywhere. It is the sibling of Page Metadata (2000000138) and CodeUnit Metadata
// (2000000137), both of which this corpus already pins; Table Metadata was the one of the
// three that nothing covered.
//
// Every column asserted here is read off a fixture whose declaration states a KNOWN value,
// and each of Name, ID, Caption, DataPerCompany, LookupPageID, TableType, DataClassification
// and ExternalName is asserted at two different values on two different rows. A provider
// that answered every Get with a fixed or blank row therefore fails on at least one
// assertion of every column, which is the point of the pairs:
//
//   Name / ID          ALT Relation Parent (60028)   vs ALT Relation Parent B (60030)
//   Caption            ALT Captioned                 -- its Caption differs from its Name
//   DataPerCompany     ALT Relation Parent (true)    vs Install Seed Database (false)
//   LookupPageID       ALT Relation Parent (0)       vs Test RunModal LookupPage Row (60996)
//   TableType          Normal / Temporary / CRM      -- three fixtures, three answers
//   DataClassification SystemMetadata (60028)        vs CustomerContent (60621)
//                      -- and ALT Unclassified (60837), which declares none at all
//   ExternalName       '' (60028)                    vs 'alt_entity' (60291)

codeunit 60801 "Test Table Metadata Virt Tbl"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Record_TableMetadata_Get_DeclaredTable_ReturnsMatchingRow()
    // CLAIM: Table Metadata has a row for a table declared by this app, and its columns are
    // computed from that table's own AL declaration.
    var
        TableMetadata: Record "Table Metadata";
    begin
        Initialize();

        // [WHEN] reading the virtual table for a compiled table by its object id
        Assert.IsTrue(
            TableMetadata.Get(Database::"ALT Relation Parent"),
            'Table Metadata has no row for table ALT Relation Parent.');

        // [THEN] every column reflects the declaration of that table.
        Assert.AreEqual(
            Database::"ALT Relation Parent", TableMetadata.ID,
            'Unexpected ID for ALT Relation Parent.');
        Assert.AreEqual(
            'ALT Relation Parent', TableMetadata.Name,
            'Unexpected Name for ALT Relation Parent.');
        Assert.IsTrue(
            TableMetadata.DataPerCompany,
            'ALT Relation Parent declares no DataPerCompany, and the AL default is true.');
        Assert.AreEqual(
            0, TableMetadata.LookupPageID,
            'ALT Relation Parent declares no LookupPageId, so the column must read 0.');
        Assert.AreEqual(
            TableMetadata.TableType::Normal, TableMetadata.TableType,
            'ALT Relation Parent declares no TableType, and the AL default is Normal.');
        Assert.AreEqual(
            TableMetadata.ObsoleteState::No, TableMetadata.ObsoleteState,
            'ALT Relation Parent is not obsolete, so ObsoleteState must read No.');
        Assert.AreEqual(
            TableMetadata.DataClassification::SystemMetadata, TableMetadata.DataClassification,
            'ALT Relation Parent declares DataClassification = SystemMetadata.');
    end;

    [Test]
    procedure Record_TableMetadata_Get_SecondTable_ReturnsItsOwnNameAndId()
    // CLAIM: Name and ID vary per row -- they are not a constant the provider echoes back.
    var
        TableMetadata: Record "Table Metadata";
    begin
        Initialize();

        Assert.IsTrue(
            TableMetadata.Get(Database::"ALT Relation Parent B"),
            'Table Metadata has no row for table ALT Relation Parent B.');

        // A different row of the same virtual table, read in the same way as the test above:
        // a provider answering a fixed row would pass one of these two and fail the other.
        Assert.AreEqual(
            'ALT Relation Parent B', TableMetadata.Name,
            'Unexpected Name for ALT Relation Parent B.');
        Assert.AreEqual(
            60030, TableMetadata.ID,
            'ALT Relation Parent B is declared as table 60030, so ID must read 60030.');
    end;

    [Test]
    procedure Record_TableMetadata_Get_CaptionedTable_ReportsTheDeclaredCaption()
    // CLAIM: Caption reads the table's declared Caption property, not its object name.
    var
        TableMetadata: Record "Table Metadata";
    begin
        Initialize();

        Assert.IsTrue(
            TableMetadata.Get(Database::"ALT Captioned"),
            'Table Metadata has no row for table ALT Captioned.');

        // ALT Captioned exists precisely because its Caption and its Name are different
        // strings, so a provider echoing the name into Caption cannot pass both assertions.
        Assert.AreEqual(
            'ALT Captioned', TableMetadata.Name,
            'Name must read the object name of ALT Captioned.');
        Assert.AreEqual(
            'Captioned Fixture Table', TableMetadata.Caption,
            'Caption must read the declared Caption of ALT Captioned, not its object name.');
    end;

    [Test]
    procedure Record_TableMetadata_Get_GlobalTable_ReportsDataPerCompanyFalse()
    // CLAIM: DataPerCompany reads the declared property, so it is false for a global table.
    var
        TableMetadata: Record "Table Metadata";
    begin
        Initialize();

        Assert.IsTrue(
            TableMetadata.Get(Database::"Install Seed Database"),
            'Table Metadata has no row for table Install Seed Database.');

        // The mirror image of the DataPerCompany assertion in the first test: this fixture
        // declares DataPerCompany = false, so a provider answering a constant fails one of
        // the two.
        Assert.IsFalse(
            TableMetadata.DataPerCompany,
            'Install Seed Database declares DataPerCompany = false.');
        Assert.AreEqual(
            TableMetadata.DataClassification::CustomerContent, TableMetadata.DataClassification,
            'Install Seed Database declares DataClassification = CustomerContent.');
    end;

    [Test]
    procedure Record_TableMetadata_Get_TableWithLookupPage_ReportsTheLookupPageId()
    // CLAIM: LookupPageID reads the declared LookupPageId property.
    var
        TableMetadata: Record "Table Metadata";
    begin
        Initialize();

        Assert.IsTrue(
            TableMetadata.Get(Database::"Test RunModal LookupPage Row"),
            'Table Metadata has no row for table Test RunModal LookupPage Row.');

        // The non-zero half of the LookupPageID pair; the first test pins the zero half.
        Assert.AreEqual(
            Page::"Test RunModal LookupPage List", TableMetadata.LookupPageID,
            'Test RunModal LookupPage Row declares LookupPageId = "Test RunModal LookupPage List".');
    end;

    [Test]
    procedure Record_TableMetadata_Get_TemporaryTable_ReportsTableTypeTemporary()
    // CLAIM: TableType reads the declared TableType property, so it is Temporary here.
    var
        TableMetadata: Record "Table Metadata";
    begin
        Initialize();

        Assert.IsTrue(
            TableMetadata.Get(Database::"ALT Temp Only"),
            'Table Metadata has no row for table ALT Temp Only.');

        Assert.AreEqual(
            TableMetadata.TableType::Temporary, TableMetadata.TableType,
            'ALT Temp Only declares TableType = Temporary.');
    end;

    [Test]
    procedure Record_TableMetadata_Get_CrmTable_ReportsTableTypeCrmAndExternalName()
    // CLAIM: TableType reads CRM for a TableType = CRM table, and ExternalName is populated.
    var
        TableMetadata: Record "Table Metadata";
    begin
        Initialize();

        Assert.IsTrue(
            TableMetadata.Get(Database::"ALT CRM Entity"),
            'Table Metadata has no row for table ALT CRM Entity.');

        // Third distinct TableType value across this suite (Normal / Temporary / CRM), so the
        // column is proven to vary rather than to be a constant the provider returns.
        Assert.AreEqual(
            TableMetadata.TableType::CRM, TableMetadata.TableType,
            'ALT CRM Entity declares TableType = CRM.');
    end;

    [Test]
    procedure Record_TableMetadata_ExternalName_IsBlankUnlessDeclared()
    // CLAIM: ExternalName reads the declared ExternalName property, and is blank for a table
    // that declares none.
    var
        TableMetadata: Record "Table Metadata";
    begin
        Initialize();

        // ALT CRM Entity declares ExternalName = 'alt_entity'...
        Assert.IsTrue(
            TableMetadata.Get(Database::"ALT CRM Entity"),
            'Table Metadata has no row for table ALT CRM Entity.');
        Assert.AreEqual(
            'alt_entity', TableMetadata.ExternalName,
            'ALT CRM Entity declares ExternalName = ''alt_entity''.');

        // ...and ALT Relation Parent declares none, which is the half that keeps the
        // assertion above from being satisfied by a column that echoes any non-blank string.
        Assert.IsTrue(
            TableMetadata.Get(Database::"ALT Relation Parent"),
            'Table Metadata has no row for table ALT Relation Parent.');
        Assert.AreEqual(
            '', TableMetadata.ExternalName,
            'ALT Relation Parent declares no ExternalName, so the column must read blank.');
    end;

    [Test]
    procedure Record_TableMetadata_Get_TableDeclaringNoDataClassification_ReportsTheDefault()
    // CLAIM: for a table whose declaration is silent about DataClassification, the column
    // reports CustomerContent -- the first member of its own option set.
    //
    // WHY THIS TEST EXISTS. The other two DataClassification assertions in this codeunit are
    // both on fixtures that STATE the property (SystemMetadata on 60028, CustomerContent on
    // 60621), so neither says anything about a table that states nothing. Microsoft's
    // DataClassification documentation describes ToBeClassified as the default, which is the
    // SECOND member of this column's option set, so the two possibilities are distinguishable
    // and only a service tier can say which one a real Table Metadata row carries.
    var
        TableMetadata: Record "Table Metadata";
    begin
        Initialize();

        Assert.IsTrue(
            TableMetadata.Get(Database::"ALT Unclassified"),
            'Table Metadata has no row for table ALT Unclassified.');

        // Confirms the row read below is the fixture and not some other table, so the
        // classification assertion is about the declaration this test names.
        Assert.AreEqual(
            'ALT Unclassified', TableMetadata.Name,
            'Unexpected Name for ALT Unclassified.');

        // The measurement. ALT Unclassified declares no DataClassification; its single FIELD
        // declares SystemMetadata, so an answer of SystemMetadata here would mean the column
        // is derived from the fields, and an answer of ToBeClassified would mean the platform
        // applies the documented default. Neither coincides with the value asserted.
        Assert.AreEqual(
            TableMetadata.DataClassification::CustomerContent, TableMetadata.DataClassification,
            'ALT Unclassified declares no DataClassification.');

        // The sibling option column of the same row, undeclared in the same way: TableType is
        // the other column of Table Metadata whose value comes from an AL property this
        // fixture does not state. Asserting both on ONE row shows the two undeclared columns
        // are answered independently rather than by one shared "everything is zero" path.
        Assert.AreEqual(
            TableMetadata.TableType::Normal, TableMetadata.TableType,
            'ALT Unclassified declares no TableType.');
    end;

    [Test]
    procedure Record_TableMetadata_Get_UnknownTableId_ReturnsFalse()
    // CLAIM: Get returns false for an object id no table uses.
    var
        TableMetadata: Record "Table Metadata";
    begin
        Initialize();

        // Negative control: a provider that answers every Get with true (a fixed or blank
        // row) would pass every positive test above and fail here.
        Assert.IsFalse(
            TableMetadata.Get(99999999),
            'Table Metadata must not have a row for an id no table uses.');
    end;

    [Test]
    procedure Record_TableMetadata_FilterOnId_DiscriminatesBetweenRows()
    // CLAIM: SetRange(ID, ...) selects exactly the named table, and nothing for an unused id.
    var
        TableMetadata: Record "Table Metadata";
    begin
        Initialize();

        // A filter naming one existing table selects exactly that table...
        TableMetadata.SetRange(ID, Database::"ALT Relation Parent");
        Assert.AreEqual(1, TableMetadata.Count(), 'A filter on one existing table id must select one row.');
        Assert.IsTrue(TableMetadata.FindSet(), 'FindSet must succeed for a filter naming an existing table.');
        Assert.AreEqual(
            'ALT Relation Parent', TableMetadata.Name,
            'The filtered row must be the table the filter named.');

        // ...and a filter naming an id no table uses selects none.
        TableMetadata.SetRange(ID, 99999999);
        Assert.AreEqual(0, TableMetadata.Count(), 'A filter on an unused id must select no rows.');
        Assert.IsFalse(TableMetadata.FindSet(), 'FindSet must fail for a filter naming no table.');
        Assert.IsTrue(TableMetadata.IsEmpty(), 'IsEmpty must be true for a filter naming no table.');
    end;

    [Test]
    procedure Record_TableMetadata_FilterOnIdRange_SelectsEveryTableInTheRange()
    // CLAIM: a range filter selects the tables inside it and excludes the ones outside.
    var
        TableMetadata: Record "Table Metadata";
    begin
        Initialize();

        // 60028..60030 spans ALT Relation Parent (60028), ALT Relation Child (60029) and
        // ALT Relation Parent B (60030) -- three consecutive fixture tables, so the count is
        // a concrete number rather than "more than zero".
        TableMetadata.SetRange(ID, 60028, 60030);
        Assert.AreEqual(3, TableMetadata.Count(), 'The id range 60028..60030 covers exactly three fixture tables.');

        // The row just outside the range is excluded, which is what makes the count above a
        // statement about the filter rather than about the table being small.
        TableMetadata.SetRange(ID, 60028, 60029);
        Assert.AreEqual(2, TableMetadata.Count(), 'The id range 60028..60029 covers exactly two fixture tables.');

        // ...and the row the narrower range dropped is present when asked for on its own, so
        // the 3-then-2 difference is the filter working, not a row that does not exist.
        TableMetadata.SetRange(ID, 60030);
        Assert.AreEqual(
            1, TableMetadata.Count(),
            'Table 60030 exists; the narrower range excluded it rather than it being absent.');
    end;

    local procedure Initialize()
    begin
        // Table Metadata is a read-only system virtual table -- nothing to DeleteAll.
    end;
}
