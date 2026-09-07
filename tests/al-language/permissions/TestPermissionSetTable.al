// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissionset-object
// Scope: in-scope (reads a platform table whose rows are computed from metadata; no fixtures written)
// BC versions: 27.0-28.4
// Fixtures used: ALT Agg Perm Set (permissionset 60930), ALTPermissionSet (permissionset 60022),
//                ALT NonAssignable (permissionset 60023)
//
// The legacy "Permission Set" table (2000000004) is not a stored table on a modern
// service tier. Whenever the platform composes permission sets from extensions --
// the default -- the tier serves 2000000004 from permission-set METADATA, one row
// per assignable permission set the installed apps declare. Microsoft's own test
// libraries depend on it: "Permissions Mock" (codeunit 131006) does
// `PermissionSet.Get(RoleID)` on this table for every named set, so
// "Library - Lower Permissions" (codeunit 132217) and its ~60 SetXxx entry points
// all fail if it answers nothing.
//
// These tests pin what the table answers, and how it relates to its two siblings:
//   - it lists the permission sets installed apps declare, keyed on Role ID alone,
//   - "Name" is the set's Caption, with the Role ID substituted when there is none,
//   - walking it lists only ASSIGNABLE sets -- which is what separates it from
//     "Metadata Permission Set" (2000000250), a strict superset -- while a
//     primary-key Get() resolves a non-assignable set anyway,
//   - and every row it lists is also a System-scope row of
//     "Aggregate Permission Set" (2000000167), with the two counts equal.
//
// The table is ObsoleteState = Pending on every version in range (its stated reason
// is a scope change, not removal), so each reference is wrapped in the AL0432 pragma.
codeunit 60294 "Test Permission Set Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        SuperRoleTok: Label 'SUPER', Locked = true;

    [Test]
    procedure PermissionSet_ListsThePlatformSuperRole()
    // CLAIM: the table answers, and it answers for the role every user-creating code
    // path needs. SUPER is reachable by Role ID alone -- 2000000004's primary key is
    // the Role ID, with no App ID column -- and its Name is the platform's own caption.
    // "Hash" is a column of the stored table that the metadata-served rows leave blank.
    var
#pragma warning disable AL0432
        PermissionSet: Record "Permission Set";
#pragma warning restore AL0432
    begin
        Initialize();
        Assert.IsTrue(PermissionSet.Get(SuperRoleTok), 'SUPER is listed in the Permission Set table');
        Assert.AreEqual(SuperRoleTok, PermissionSet."Role ID", 'Role ID of the fetched row');
        Assert.AreEqual('This role has all permissions.', PermissionSet.Name, 'Name is the permission set Caption');
        Assert.AreEqual('', PermissionSet.Hash, 'a metadata-served row carries no Hash');
    end;

    [Test]
    procedure PermissionSet_ListsEveryInstalledAppsAssignableSets()
    // CLAIM: the table is the full inventory of assignable sets, not a handful of
    // platform roles. A Base Application + System Application install declares
    // hundreds; a floor well above the roles these tests name by hand rules out an
    // implementation that only knows the rows some other test asked for.
    var
#pragma warning disable AL0432
        PermissionSet: Record "Permission Set";
#pragma warning restore AL0432
    begin
        Initialize();
        Assert.IsTrue(PermissionSet.Count() > 50, 'a Base Application install declares far more than 50 assignable permission sets');
    end;

    [Test]
    procedure PermissionSet_AppDeclaredRole_IsListedWithItsCaption()
    // CLAIM: a set an app declares is listed under its own Role ID, and its Name is
    // the declared Caption -- two different strings, not one repeated. D365 BASIC is
    // Base Application's, ALT Agg Perm Set is this suite's own.
    var
#pragma warning disable AL0432
        PermissionSet: Record "Permission Set";
#pragma warning restore AL0432
    begin
        Initialize();
        Assert.IsTrue(PermissionSet.Get('D365 BASIC'), 'Base Application declares the D365 BASIC permission set');
        Assert.AreEqual('Dynamics 365 Basic access', PermissionSet.Name, 'Name is the declared Caption');

        Clear(PermissionSet);
        Assert.IsTrue(PermissionSet.Get('ALT Agg Perm Set'), 'this app declares ALT Agg Perm Set and the table lists it');
        Assert.AreEqual('ALT Agg Perm Set Fixture', PermissionSet.Name,
            'a permission set declaring a Caption is listed with that Caption, its own casing untouched');
    end;

    [Test]
    procedure PermissionSet_CaptionlessRole_NameFallsBackToTheUpperCaseRoleId()
    // CLAIM: a permission set that declares no Caption is listed with its ROLE ID
    // substituted for Name -- the upper-case Code value, not the object's declared
    // mixed-case name. ALTPermissionSet (60022) declares no Caption and its object
    // name is mixed case, so the two answers are distinguishable: an implementation
    // returning the declared name answers 'ALTPermissionSet'.
    var
#pragma warning disable AL0432
        PermissionSet: Record "Permission Set";
#pragma warning restore AL0432
    begin
        Initialize();
        Assert.IsTrue(PermissionSet.Get('ALTPermissionSet'), 'this app declares ALTPermissionSet and the table lists it');
        Assert.AreEqual('ALTPERMISSIONSET', PermissionSet.Name,
            'a Caption-less permission set is listed with its upper-case Role ID as Name');
        Assert.AreEqual('ALTPERMISSIONSET', PermissionSet."Role ID", 'and the Role ID column is that same Code value');
    end;

    [Test]
    procedure PermissionSet_UnknownRole_IsNotInventedAndGetRaisesRecordNotFound()
    // CLAIM: an undeclared role id is not invented. The conditional Get answers false
    // and the unqualified Get raises BC's own record-not-found error naming this table
    // -- the error "Permissions Mock".Assign surfaces when a role is unknown.
    var
#pragma warning disable AL0432
        PermissionSet: Record "Permission Set";
#pragma warning restore AL0432
    begin
        Initialize();
        Assert.IsFalse(PermissionSet.Get('ALT NO SUCH ROLE'), 'an undeclared role id is not listed');

        asserterror PermissionSet.Get('ALT NO SUCH ROLE');
#pragma warning disable AL0432
        Assert.ExpectedErrorCannotFind(Database::"Permission Set");
#pragma warning restore AL0432
    end;

    [Test]
    procedure PermissionSet_WalkSkipsNonAssignableSets_ThoughGetStillFindsThem()
    // CLAIM, and it is two claims because real BC answers the two access paths
    // DIFFERENTLY for the same row. ALT NonAssignable (60023) declares
    // Assignable = false:
    //   - WALKING the table does not list it. That path enumerates the permission-set
    //     metadata and applies an assignable filter, which is what makes this table a
    //     strict subset of "Metadata Permission Set".
    //   - a primary-key Get() DOES find it. That path resolves the Role ID directly
    //     and never consults Assignable at all.
    // Measured on real BC 28.4. The walk is deliberately a full FindSet loop and not
    // SetRange("Role ID", ...) + FindFirst: a single-value filter on the primary key
    // is served by the SAME key lookup Get() uses, so it finds the row too and would
    // not distinguish the two paths.
    var
#pragma warning disable AL0432
        PermissionSet: Record "Permission Set";
#pragma warning restore AL0432
        MetadataPermissionSet: Record "Metadata Permission Set";
        WalkedNonAssignable: Boolean;
        WalkedAssignable: Boolean;
    begin
        Initialize();
        MetadataPermissionSet.SetRange("Role ID", 'ALT NonAssignable');
        Assert.IsTrue(MetadataPermissionSet.FindFirst(), 'Metadata Permission Set lists a non-assignable set');
        Assert.IsFalse(MetadataPermissionSet.Assignable, 'and the fixture really is non-assignable');

        Assert.IsTrue(PermissionSet.FindSet(), 'the table lists at least one permission set');
        repeat
            if PermissionSet."Role ID" = 'ALT NONASSIGNABLE' then
                WalkedNonAssignable := true;
            if PermissionSet."Role ID" = 'ALT AGG PERM SET' then
                WalkedAssignable := true;
        until PermissionSet.Next() = 0;

        Assert.IsFalse(WalkedNonAssignable, 'walking Permission Set does not list a non-assignable set');
        Assert.IsTrue(WalkedAssignable,
            'the same walk DOES list an assignable set this app declares, so the omission above is about Assignable and not about this app');

        PermissionSet.Reset();
        Assert.IsTrue(PermissionSet.Get('ALT NonAssignable'),
            'a primary-key Get() resolves a non-assignable set even though the walk skips it');
        Assert.AreEqual('ALT NonAssignable Fixture', PermissionSet.Name, 'and the row it returns carries the declared Caption');
    end;

    [Test]
    procedure PermissionSet_IsAStrictSubsetOfMetadataPermissionSet()
    // CLAIM: the counts stand in the relation the Assignable filter implies -- every
    // listed set is declared, and strictly fewer are listed than declared. The strict
    // inequality is what rules out the two tables being served from one another.
    var
#pragma warning disable AL0432
        PermissionSet: Record "Permission Set";
#pragma warning restore AL0432
        MetadataPermissionSet: Record "Metadata Permission Set";
    begin
        Initialize();
        Assert.IsTrue(PermissionSet.Count() < MetadataPermissionSet.Count(),
            'fewer sets are assignable than are declared');
    end;

    [Test]
    procedure PermissionSet_MatchesTheSystemScopeOfAggregatePermissionSet()
    // CLAIM: 2000000004 and the System scope of "Aggregate Permission Set"
    // (2000000167) are two views of one inventory, so their row counts are equal.
    // Measured on real BC: both answer the same number, with the Tenant scope empty
    // in a stock installation. A tier where one answers and the other does not is
    // the defect this pins (StefanMaron/BusinessCentral.AL.Runner#3344, where
    // 2000000167 answered 170 rows and 2000000004 answered none).
    var
#pragma warning disable AL0432
        PermissionSet: Record "Permission Set";
#pragma warning restore AL0432
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        Initialize();
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::System);
        Assert.AreEqual(PermissionSet.Count(), AggregatePermissionSet.Count(),
            'the Permission Set table and the System scope of Aggregate Permission Set list the same sets');
    end;

    [Test]
    procedure PermissionSet_EveryListedRoleIsAlsoAnAggregateSystemScopeRow()
    // CLAIM: the equality above is not a coincidence of counts -- every single Role ID
    // this table lists is reachable as a System-scope Aggregate Permission Set row.
    // Two tables of the same size listing different sets would pass the count test and
    // fail this one.
    var
#pragma warning disable AL0432
        PermissionSet: Record "Permission Set";
#pragma warning restore AL0432
        AggregatePermissionSet: Record "Aggregate Permission Set";
        Missing: Integer;
        FirstMissing: Text;
    begin
        Initialize();
        Assert.IsTrue(PermissionSet.FindSet(), 'the table lists at least one permission set');
        repeat
            AggregatePermissionSet.Reset();
            AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::System);
            AggregatePermissionSet.SetRange("Role ID", PermissionSet."Role ID");
            if not AggregatePermissionSet.FindFirst() then begin
                Missing += 1;
                if FirstMissing = '' then
                    FirstMissing := PermissionSet."Role ID";
            end;
        until PermissionSet.Next() = 0;

        Assert.AreEqual(0, Missing, StrSubstNo('permission sets missing from the System scope of Aggregate Permission Set, first: %1', FirstMissing));
    end;

    local procedure Initialize()
    begin
        // Nothing this codeunit touches is writable -- on a modern tier 2000000004 is
        // served from permission-set metadata -- but the shared cleanup keeps the
        // codeunit's entry point identical to every other suite in this repo.
        Cleanup.Initialize();
    end;
}
