// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissionset-object
// Scope: in-scope (reads platform virtual tables; one fixture permission set)
// BC versions: 27.0-28.4
// Fixtures used: ALT Undecl Assign (permissionset 60024),
//                ALT NonAssignable (permissionset 60023), ALT Agg Perm Set (permissionset 60930)
//
// What a permission set that declares NO Assignable property resolves to.
//
// Every permission-set fixture in this suite STATES the property -- 60022 and 60930
// state true, 60023 states false -- so the undeclared case was never pinned, and it is
// the case that decides how a reader should default. It is not a hypothetical shape:
// three permission sets shipped in BC 28.1 declare no Assignable at all, namely Base
// Application 208 "D365 Basic - Edit" and 209 "D365 Basic - Read", and System
// Application 68 "System Execute - Basic".
//
// The suite deliberately asks the question through TWO independent observables, because
// either one alone could be explained without settling the property's value:
//   - "Metadata Permission Set" (2000000250) reports Assignable directly.
//   - "Permission Set" (2000000004) lists only ASSIGNABLE sets when WALKED, so whether
//     the set appears in that walk is a second, independent reading of the same fact.
// A test asserting only the first could be satisfied by a column that is simply always
// false; the walk is what ties the value to behaviour the platform acts on.
//
// 2000000004 is ObsoleteState = Pending on every version in range, so each reference is
// wrapped in the AL0432 pragma, exactly as TestPermissionSetTable.al does.
//
// The fixture's name is 17 characters on purpose: Role ID is Code[20] and a longer
// object name is TRUNCATED into it, which would make the Role ID lookups below depend
// on that truncation rather than on the property under test.
codeunit 60289 "Test PermSet Undecl Assign"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        UndeclaredRoleTok: Label 'ALT Undecl Assign', Locked = true;

    [Test]
    procedure MetadataPermissionSet_UndeclaredAssignable_IsListedAndCarriesAValue()
    // CLAIM: a permission set declaring no Assignable is still LISTED by
    // "Metadata Permission Set", which lists every declared set regardless of the
    // property. Asserted first so the value assertion below is known to be about a row
    // that exists, rather than passing because nothing was found.
    var
        MetadataPermissionSet: Record "Metadata Permission Set";
    begin
        Initialize();
        MetadataPermissionSet.SetRange("Role ID", UndeclaredRoleTok);
        Assert.IsTrue(MetadataPermissionSet.FindFirst(),
            'Metadata Permission Set lists a set that declares no Assignable');
        Assert.AreEqual('ALT Undecl Assign Fixture', MetadataPermissionSet.Name,
            'and the row carries the declared Caption, so this is the fixture and not a same-named row');
    end;

    [Test]
    procedure MetadataPermissionSet_UndeclaredAssignable_ResolvesToFalse()
    // CLAIM: the platform resolves an UNDECLARED Assignable to FALSE.
    //
    // The contrast row is what makes this a statement about the absent property rather
    // than about this app: 60930 "ALT Agg Perm Set" declares Assignable = true and is
    // read through the same table in the same test, so a tier answering false for
    // everything fails the second assertion.
    var
        MetadataPermissionSet: Record "Metadata Permission Set";
    begin
        Initialize();
        MetadataPermissionSet.SetRange("Role ID", UndeclaredRoleTok);
        Assert.IsTrue(MetadataPermissionSet.FindFirst(), 'the undeclared-Assignable fixture is listed');
        Assert.IsFalse(MetadataPermissionSet.Assignable,
            'a permission set declaring no Assignable is NOT assignable');

        MetadataPermissionSet.Reset();
        MetadataPermissionSet.SetRange("Role ID", 'ALT Agg Perm Set');
        Assert.IsTrue(MetadataPermissionSet.FindFirst(), 'the declared-true fixture is listed too');
        Assert.IsTrue(MetadataPermissionSet.Assignable,
            'and a set declaring Assignable = true still answers true, so the column is not simply always false');
    end;

    [Test]
    procedure PermissionSetWalk_SkipsAnUndeclaredAssignableSet()
    // CLAIM: the second, independent observable agrees. Walking "Permission Set"
    // (2000000004) applies the assignable filter, so a set that declares no Assignable
    // is absent from the walk for the same reason 60023's explicit false is -- which
    // ties the column value to behaviour the platform acts on.
    //
    // The walk is a full FindSet loop rather than SetRange("Role ID", ...) + FindFirst:
    // a single-value filter on the primary key is served by the SAME key lookup Get()
    // uses, which resolves a non-assignable row anyway and would not distinguish the
    // two paths. This mirrors TestPermissionSetTable.al's own note.
    var
#pragma warning disable AL0432
        PermissionSet: Record "Permission Set";
#pragma warning restore AL0432
        WalkedUndeclared: Boolean;
        WalkedAssignable: Boolean;
    begin
        Initialize();
        Assert.IsTrue(PermissionSet.FindSet(), 'the table lists at least one permission set');
        repeat
            if PermissionSet."Role ID" = 'ALT UNDECL ASSIGN' then
                WalkedUndeclared := true;
            if PermissionSet."Role ID" = 'ALT AGG PERM SET' then
                WalkedAssignable := true;
        until PermissionSet.Next() = 0;

        Assert.IsFalse(WalkedUndeclared,
            'walking Permission Set does not list a set that declares no Assignable');
        Assert.IsTrue(WalkedAssignable,
            'the same walk DOES list an assignable set this app declares, so the omission above is about Assignable and not about this app');
    end;

    local procedure Initialize()
    begin
        // Nothing this codeunit touches is writable -- both tables are served from
        // permission-set metadata -- but the shared cleanup keeps the codeunit's entry
        // point identical to every other suite in this repo.
        Cleanup.Initialize();
    end;
}
