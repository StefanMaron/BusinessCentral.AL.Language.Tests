// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-object
// Scope: in-scope
// Fixtures used: none — the subject is a platform system table
//
// Pins what the built-in "Object Metadata" system table (2000000071) actually contains.
//
// WHY RecordRef AND NOT `Record "Object Metadata"`
//   The table declares `Scope = OnPrem` (System.app,
//   src/Application Database Tables/ObjectMetadata.Table.al), and this app targets Cloud, so
//   a direct `Record "Object Metadata"` variable does not compile here:
//     error AL0296: The application object or method 'Object Metadata' has scope 'OnPrem'
//                   and cannot be used for 'Cloud' development.
//   RecordRef.Open takes a table id at runtime and is not scope-checked at compile time, so it
//   is the only way this app can state anything about the table at all. Field numbers are used
//   for the same reason; they come from the declaration above:
//     3 = "Object Type" (Option, members "TableData","Table",,"Report",… so Table = 1)
//     6 = "Object ID"   (Integer)
//
// WHAT THE TABLE HOLDS, AND WHAT IT NO LONGER HOLDS
//   Its own AL summary says it plainly: "The [Object Metadata] table contains the metadata
//   information for system tables with a SQL schema. This table originally contained metadata
//   for all objects, but this role is now taken by [Application Object Metadata]. Later on, it
//   only contained the metadata for all system objects, before being now limited to
//   Application database tables."
//
//   So it is NOT an object inventory. Anything wanting one reads AllObj (2000000038) or
//   System Object (2000000029). The negative tests below are what separate the two readings:
//   a table holding one row per compiled object would pass a bare "is not empty" check and
//   fail every one of them.

codeunit 60991 "Test Object Metadata Sys Tbl"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        ObjectMetadataTableId: Integer;
        ObjectTypeFieldNo: Integer;
        ObjectIdFieldNo: Integer;
        ObjectTypeTable: Integer;
        LowestSystemObjectId: Integer;

    [Test]
    procedure Record_ObjectMetadata_FilteredToTable_FindLastReturnsASystemTableId()
    var
        RecRef: RecordRef;
        ObjectTypeRef: FieldRef;
        ObjectIdRef: FieldRef;
        LastObjectId: Integer;
    begin
        Initialize();

        // [GIVEN] Object Metadata filtered to Object Type = Table
        RecRef.Open(ObjectMetadataTableId);
        ObjectTypeRef := RecRef.Field(ObjectTypeFieldNo);
        ObjectTypeRef.SetRange(ObjectTypeTable);
        ObjectIdRef := RecRef.Field(ObjectIdFieldNo);

        // [WHEN] taking the last row of that filter
        Assert.IsTrue(
            RecRef.FindLast(),
            'Object Metadata must have at least one row with Object Type = Table.');
        LastObjectId := ObjectIdRef.Value();

        // [THEN] it is an application-database SYSTEM table, never an application object.
        Assert.IsTrue(
            LastObjectId >= LowestSystemObjectId,
            StrSubstNo(
              'FindLast over Object Type = Table returned Object ID %1, which is not a system table id (>= %2).',
              LastObjectId, LowestSystemObjectId));

        RecRef.Close();
    end;

    [Test]
    procedure Record_ObjectMetadata_HoldsOnlyObjectTypeTableRows()
    var
        RecRef: RecordRef;
        ObjectTypeRef: FieldRef;
    begin
        Initialize();

        // [GIVEN] the whole table
        RecRef.Open(ObjectMetadataTableId);
        Assert.IsTrue(RecRef.Count() > 0, 'Object Metadata must not be empty.');

        // [WHEN] excluding Object Type = Table
        ObjectTypeRef := RecRef.Field(ObjectTypeFieldNo);
        ObjectTypeRef.SetFilter('<>%1', ObjectTypeTable);

        // [THEN] nothing is left: every retained row is a Table row. A table still holding one
        // row per compiled object would have Codeunit, Page and Report rows here.
        Assert.AreEqual(
            0, RecRef.Count(),
            'Object Metadata must hold no row whose Object Type is anything other than Table.');
        Assert.IsTrue(
            RecRef.IsEmpty(),
            'Object Metadata must be empty once Object Type = Table is filtered out.');
        Assert.IsFalse(
            RecRef.FindFirst(),
            'FindFirst must fail once Object Type = Table is filtered out.');

        RecRef.Close();
    end;

    [Test]
    procedure Record_ObjectMetadata_HoldsNoApplicationObjectIds()
    var
        RecRef: RecordRef;
        ObjectIdRef: FieldRef;
    begin
        Initialize();

        // [GIVEN] the whole table, filtered to ids below the system range
        RecRef.Open(ObjectMetadataTableId);
        ObjectIdRef := RecRef.Field(ObjectIdFieldNo);
        ObjectIdRef.SetFilter('<%1', LowestSystemObjectId);

        // [THEN] no row: the table is limited to application-database SYSTEM tables.
        Assert.AreEqual(
            0, RecRef.Count(),
            StrSubstNo('Object Metadata must hold no row with an Object ID below %1.', LowestSystemObjectId));

        RecRef.Close();
    end;

    [Test]
    procedure Record_ObjectMetadata_FilterOnApplicationTableId_SelectsNoRows()
    var
        RecRef: RecordRef;
        ObjectIdRef: FieldRef;
    begin
        Initialize();

        // Negative control with a concrete id: table 18 (Customer) is a Base Application
        // table, not an application-database system table, so it has no row here — even
        // though it certainly has a row in AllObj.
        RecRef.Open(ObjectMetadataTableId);
        ObjectIdRef := RecRef.Field(ObjectIdFieldNo);
        ObjectIdRef.SetRange(18);

        Assert.AreEqual(0, RecRef.Count(), 'Object Metadata must hold no row for table 18 (Customer).');
        Assert.IsTrue(RecRef.IsEmpty(), 'Object Metadata must be empty when filtered to table 18 (Customer).');

        RecRef.Close();
    end;

    [Test]
    procedure Record_ObjectMetadata_FilterOnVirtualSystemTableId_SelectsNoRows()
    var
        RecRef: RecordRef;
        ObjectIdRef: FieldRef;
    begin
        Initialize();

        // Sharper negative than the one above: 2000000038 (AllObj) IS a system table, but a
        // VIRTUAL one — it has no SQL schema in the application database, so it is outside
        // what this table is documented to cover. This is what separates "system table" from
        // "application-database table" as the selection rule.
        RecRef.Open(ObjectMetadataTableId);
        ObjectIdRef := RecRef.Field(ObjectIdFieldNo);
        ObjectIdRef.SetRange(2000000038);

        Assert.AreEqual(
            0, RecRef.Count(),
            'Object Metadata must hold no row for the virtual system table 2000000038 (AllObj).');

        RecRef.Close();
    end;

    [Test]
    procedure Record_ObjectMetadata_FilterOnOwnTableId_SelectsItsOwnRow()
    var
        RecRef: RecordRef;
        ObjectTypeRef: FieldRef;
        ObjectIdRef: FieldRef;
    begin
        Initialize();

        // Positive control with a concrete id. Object Metadata is itself an
        // application-database table with a SQL schema, so it describes itself: exactly the
        // case the negatives above exclude. Together they prove the row set is selected by a
        // rule rather than being everything or nothing.
        RecRef.Open(ObjectMetadataTableId);
        ObjectIdRef := RecRef.Field(ObjectIdFieldNo);
        ObjectIdRef.SetRange(ObjectMetadataTableId);

        Assert.IsTrue(
            RecRef.FindFirst(),
            StrSubstNo('Object Metadata must hold a row for its own table id %1.', ObjectMetadataTableId));

        ObjectTypeRef := RecRef.Field(ObjectTypeFieldNo);
        Assert.AreEqual(
            ObjectTypeTable, ObjectTypeRef.Value(),
            'The row describing Object Metadata itself must carry Object Type = Table.');

        RecRef.Close();
    end;

    local procedure Initialize()
    begin
        // Object Metadata is written by publishing, never by AL — nothing to reset.
        ObjectMetadataTableId := 2000000071;
        ObjectTypeFieldNo := 3;
        ObjectIdFieldNo := 6;
        ObjectTypeTable := 1;          // "Object Type"::Table — ordinal 1 of the option string
        LowestSystemObjectId := 2000000001;
    end;
}
