// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissionset-object
// Scope: in-scope (reads a platform virtual table; uses the shared ALTPermissionSet fixture)
// BC versions: 27.5+
//
// The sibling suite TestMetadataPermissionSet.al pins the "Metadata Permission Set"
// table's HEADER columns -- Role ID, Name, App ID, Assignable. Nothing upstream pins
// what a permission set actually GRANTS, which is a different table: "Permission"
// (2000000005), one row per permission the set declares.
//
// That gap matters because the two are populated from different places. A permission
// set's header can be listed correctly while its tabledata grants are missing entirely,
// and no existing assertion notices.
//
// These tests pin three things about a `tabledata` grant declared in AL source:
//   - the grant EXISTS as a row, keyed by (Role ID, Object Type, Object ID);
//   - Object Type is tabledata (0), NOT table (1) -- the two are adjacent ordinals
//     and reading one for the other is the easy mistake;
//   - the RIMD letters become the individual permission columns, so a set declaring
//     RIMD is distinguishable from one declaring a subset.
//
// The fixture is _fixtures/ALTPermissionSet.permissionset.al (permission set 60022),
// which declares `tabledata "ALT Universal" = RIMD` among others.
codeunit 60604 "Test Perm. Set Grants"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        FixtureRoleTok: Label 'ALTPermissionSet', Locked = true;

    [Test]
    procedure PermissionSet_DeclaredTableDataGrant_IsListedAsAPermissionRow()
    // CLAIM: a `tabledata` grant written in a permission set's AL source is readable
    // back as a row of the "Permission" table under that set's Role ID. A set whose
    // grants are dropped still lists its header, so only this read catches it.
    var
        Permission: Record Permission;
    begin
        Initialize();

        Permission.SetRange("Role ID", FixtureRoleTok);
        Permission.SetRange("Object Type", Permission."Object Type"::"Table Data");
        Assert.IsFalse(Permission.IsEmpty(), 'the fixture declares tabledata grants, so at least one Permission row must exist');

        // The fixture declares 17 tabledata grants and nothing else. Asserting the exact
        // count -- rather than ">= 1" -- is what makes a partially-populated answer fail.
        Assert.AreEqual(17, Permission.Count(), 'one Permission row per tabledata grant the fixture declares');
    end;

    [Test]
    procedure PermissionSet_TableDataGrant_CarriesTheReadWriteInsertDeleteMask()
    // CLAIM: `= RIMD` sets all four permission columns to Yes. A row that exists but
    // carries a default (blank/None) mask would pass the previous test and fail this
    // one, so the pair distinguishes "the row is there" from "the row is right".
    var
        Permission: Record Permission;
        AltUniversalTok: Label 'ALT Universal', Locked = true;
        AllObj: Record AllObjWithCaption;
    begin
        Initialize();

        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object Name", AltUniversalTok);
        Assert.IsTrue(AllObj.FindFirst(), 'the ALT Universal fixture table must exist to key the grant on');

        Permission.Get(FixtureRoleTok, Permission."Object Type"::"Table Data", AllObj."Object ID");

        Assert.AreEqual(Permission."Read Permission"::Yes, Permission."Read Permission", 'R of RIMD');
        Assert.AreEqual(Permission."Insert Permission"::Yes, Permission."Insert Permission", 'I of RIMD');
        Assert.AreEqual(Permission."Modify Permission"::Yes, Permission."Modify Permission", 'M of RIMD');
        Assert.AreEqual(Permission."Delete Permission"::Yes, Permission."Delete Permission", 'D of RIMD');
    end;

    [Test]
    procedure PermissionSet_TableDataGrant_IsNotFiledUnderObjectTypeTable()
    // CLAIM: `tabledata X` and `table X` are different Object Type ordinals, and a
    // tabledata grant is filed under the former. Reading one for the other is the
    // adjacent-ordinal mistake this pins against -- the fixture declares no bare
    // `table` permission at all, so that range must come back empty.
    var
        Permission: Record Permission;
    begin
        Initialize();

        Permission.SetRange("Role ID", FixtureRoleTok);
        Permission.SetRange("Object Type", Permission."Object Type"::Table);
        Assert.IsTrue(Permission.IsEmpty(), 'the fixture declares only tabledata grants, so Object Type::Table must yield no rows');
    end;

    local procedure Initialize()
    begin
        // Nothing this codeunit touches is writable -- the Permission table is served
        // from permission-set metadata -- but the shared cleanup keeps the codeunit's
        // entry point identical to every other suite in this repo.
        Cleanup.Initialize();
    end;
}
