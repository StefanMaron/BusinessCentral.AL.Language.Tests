// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-object
// Scope: in-scope, but ONLY for a Target = OnPrem app - see the header note below
// Fixtures used: Assert (60021), from the AL Language Coverage Tests app
// BC versions: 27.0+
//
// WHY THIS FILE IS IN THE ONPREM APP AND NOT THE CLOUD ONE
//   Microsoft declares "Object Metadata" (2000000071) Scope = OnPrem in System.app. An AL
//   object in a Target = Cloud app cannot name the record type at all - the compiler rejects
//   it with AL0296 - and the RecordRef way round is refused at runtime too, by
//   NavRecordRef.CheckIsOpenAllowed, because 2000000071 is in SystemTables.InternalTables.
//   Corpus PR #153 measured exactly that on all 8 BC legs of run 33968379281.
//
//   Both refusals are decided by the CALLING APP'S COMPILATION TARGET, and by nothing else.
//   NavRecordRef.IsOpenAllowed reads, in full:
//
//       private bool IsOpenAllowed(CompilationTarget compilationTarget, int tableId)
//       {
//           if (!compilationTarget.IsOnPremTarget())
//               return IsSystemTableAllowedForRecordRefUsage(tableId);
//           return true;
//       }
//
//   so the InternalTables membership test is never even reached for an OnPrem target. That is
//   the whole reason this app exists: the table is not unreachable, it is unreachable FROM
//   CLOUD, and one app with a different target is all that is needed to adjudicate it.
//
// WHAT THIS TABLE HOLDS, AND WHY THAT IS WORTH PINNING
//   Not "one row per compiled object" - that role moved to "Application Object Metadata"
//   long ago. Microsoft's own DbMigration
//   CleanupObjectMetadataFromNonApplicationDatabaseTables reduces it to
//
//       DELETE FROM [dbo].[Object Metadata]
//       WHERE [Object Type] <> 1 OR [Object ID] NOT IN (<SystemTables.ApplicationDatabaseTables>)
//
//   and the publish-side insert in InPlacePublisher.UpsertIntoMetadataStorageImpl selects
//   System.app's own table objects intersected with that same list. Both are Microsoft code
//   rather than a service-tier measurement, which is what these tests supply.

codeunit 61200 "Test Object Metadata Sys Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure ObjectMetadata_Find_ApplicationDatabaseTableId_ReturnsARow()
    // CLAIM: the table carries a row for ids Microsoft lists as application-database tables,
    // spread across the range so a provider answering only a contiguous block fails here.
    begin
        Initialize();

        AssertHasRow(2000000071, 'Object Metadata, the table itself');
        AssertHasRow(2000000212, 'Installed Application');
        AssertHasRow(2000000400, 'the highest id on Microsoft''s list');
    end;

    [Test]
    procedure ObjectMetadata_Find_VirtualTableId_ReturnsNoRow()
    // CLAIM: virtual system tables have no SQL schema in the application database, so they get
    // no Object Metadata row. Without this the test above would also pass against a provider
    // that emitted every system table id it could name.
    begin
        Initialize();

        AssertHasNoRow(2000000026, 'Integer, a virtual system table');
        AssertHasNoRow(2000000038, 'AllObj, a virtual system table');
    end;

    [Test]
    procedure ObjectMetadata_Find_ApplicationTableId_ReturnsNoRow()
    // CLAIM: an ordinary application table is not a system table and gets no row.
    begin
        Initialize();

        AssertHasNoRow(18, 'Customer, an ordinary application table');
    end;

    [Test]
    procedure ObjectMetadata_Count_EveryRow_CarriesObjectTypeTable()
    // CLAIM: the retained set is Object Type = Table and nothing else, so filtering on Table
    // cannot change the count. This is the half of Microsoft's DELETE predicate that does not
    // depend on which ids are on the list.
    var
        ObjectMetadata: Record "Object Metadata";
        TableRows: Integer;
    begin
        Initialize();

        ObjectMetadata.SetRange("Object Type", ObjectMetadata."Object Type"::Table);
        TableRows := ObjectMetadata.Count();

        Assert.IsTrue(TableRows > 0, 'Object Metadata must not be empty for Object Type = Table.');
        Assert.AreEqual(TableRows, CountAllRows(), 'Every Object Metadata row must carry Object Type = Table.');
    end;

    [Test]
    procedure ObjectMetadata_Count_IsMicrosoftsApplicationDatabaseTableListCount()
    // CLAIM: every id on SystemTables.ApplicationDatabaseTables gets a row - all 43 of them on
    // BC 27 and 28, including the 11 declared ObsoleteState = Removed and the 5 declared
    // Pending, which are full table objects with real field definitions rather than tombstones.
    //
    // The insert predicate bounds the set from above and Microsoft's DELETE bounds it from
    // below, but neither establishes the equality, so this is the assertion a service tier is
    // needed for.
    var
        ObjectMetadata: Record "Object Metadata";
    begin
        Initialize();

        ObjectMetadata.SetRange("Object Type", ObjectMetadata."Object Type"::Table);
        Assert.AreEqual(
            43, ObjectMetadata.Count(),
            'Object Metadata must carry one row per id on Microsoft''s application-database table list.');
    end;

    [Test]
    procedure ObjectMetadata_Find_ObsoletePendingId_ReturnsARow()
    // CLAIM: ObsoleteState = Pending does not keep an id off the list. 2000000001 ("Object")
    // is Pending and is on it.
    begin
        Initialize();

        AssertHasRow(2000000001, 'Object, declared ObsoleteState = Pending');
    end;

    [Test]
    procedure ObjectMetadata_Find_ObsoleteRemovedId_ReturnsARow()
    // CLAIM: ObsoleteState = Removed does not either. 2000000151 ("NAV App Object Metadata")
    // is Removed, yet still a full table object with real field definitions in System.app, so
    // it reaches the publisher's output like any other.
    begin
        Initialize();

        AssertHasRow(2000000151, 'NAV App Object Metadata, declared ObsoleteState = Removed');
    end;

    [Test]
    procedure ObjectMetadata_FindLast_ObjectTypeTable_LandsOnHighestListedId()
    // CLAIM: the clustered key is (Object Type, Object ID, Emit Version), so FindLast under a
    // Table filter lands on the highest application-database table id. 2000000400 is that id
    // on every supported BC version.
    var
        ObjectMetadata: Record "Object Metadata";
    begin
        Initialize();

        ObjectMetadata.SetRange("Object Type", ObjectMetadata."Object Type"::Table);
        Assert.IsTrue(ObjectMetadata.FindLast(), 'FindLast over Object Type = Table must succeed.');
        Assert.AreEqual(2000000400, ObjectMetadata."Object ID", 'FindLast must land on the highest listed id.');
    end;

    [Test]
    procedure ObjectMetadata_EmitVersion_EveryRow_CarriesTheBuildsEmitVersion()
    // CLAIM: "Emit Version" is the third primary-key field and carries the build's own emit
    // version, which is <major><3-digit build counter> - so 27000..29999 across BC 27.0-28.4,
    // and uniform within one published system app. The range is deliberately narrow enough to
    // fail a chosen constant: 0, 1 and 42 are all outside it.
    var
        ObjectMetadata: Record "Object Metadata";
        FirstEmitVersion: Integer;
    begin
        Initialize();

        ObjectMetadata.SetRange("Object Type", ObjectMetadata."Object Type"::Table);
        Assert.IsTrue(ObjectMetadata.FindFirst(), 'Object Metadata must not be empty.');
        FirstEmitVersion := ObjectMetadata."Emit Version";

        Assert.IsTrue(
            FirstEmitVersion >= 27000,
            StrSubstNo('Emit Version %1 is below every supported build''s emit version.', FirstEmitVersion));
        Assert.IsTrue(
            FirstEmitVersion < 30000,
            StrSubstNo('Emit Version %1 is above every supported build''s emit version.', FirstEmitVersion));

        ObjectMetadata.SetFilter("Emit Version", '<>%1', FirstEmitVersion);
        Assert.IsTrue(ObjectMetadata.IsEmpty(), 'Every row must carry the one emit version the published system app has.');
    end;

    [Test]
    procedure ObjectMetadata_CalcFields_Metadata_HasAPayload()
    // CLAIM: on a real service tier the compiled-metadata BLOB carries the output of
    // publishing the system app into the application database, so it is not empty.
    //
    // This is the assertion that turns "the payload columns are a divergence for anything
    // without an application database behind it" from a reading of Microsoft's publish code
    // into a measured fact about a tier.
    var
        ObjectMetadata: Record "Object Metadata";
    begin
        Initialize();

        ObjectMetadata.SetRange("Object Type", ObjectMetadata."Object Type"::Table);
        ObjectMetadata.SetRange("Object ID", 2000000071);
        Assert.IsTrue(ObjectMetadata.FindFirst(), 'Object Metadata must have a row for its own table id.');

        ObjectMetadata.CalcFields(Metadata);
        Assert.IsTrue(ObjectMetadata.Metadata.HasValue(), 'The Metadata BLOB must carry a payload on a real tier.');
    end;

    local procedure AssertHasRow(ObjectId: Integer; Why: Text)
    var
        ObjectMetadata: Record "Object Metadata";
    begin
        ObjectMetadata.SetRange("Object Type", ObjectMetadata."Object Type"::Table);
        ObjectMetadata.SetRange("Object ID", ObjectId);
        Assert.IsFalse(
            ObjectMetadata.IsEmpty(),
            StrSubstNo('Object Metadata must have a row for %1 (%2).', ObjectId, Why));
    end;

    local procedure AssertHasNoRow(ObjectId: Integer; Why: Text)
    var
        ObjectMetadata: Record "Object Metadata";
    begin
        ObjectMetadata.SetRange("Object ID", ObjectId);
        Assert.IsTrue(
            ObjectMetadata.IsEmpty(),
            StrSubstNo('Object Metadata must have no row for %1 (%2).', ObjectId, Why));
    end;

    local procedure CountAllRows(): Integer
    var
        ObjectMetadata: Record "Object Metadata";
    begin
        exit(ObjectMetadata.Count());
    end;

    local procedure Initialize()
    begin
        // "Object Metadata" is a read-only application-database system table written by
        // publishing, not by test code -- nothing to DeleteAll.
    end;
}
