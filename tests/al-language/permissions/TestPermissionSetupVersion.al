// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-commit-method
// Scope: in-scope (reads a platform virtual table served from permission-set metadata)
// Fixtures used: ALT Universal, ALT Keyed; writes one Tenant Permission Set and its Tenant
//   Permission rows, removed by Initialize()
// BC versions: 27.5+
//
// "Test Metadata Expanded Perm" (67945) pins that a grant inserted AFTER a set's permissions
// were composed is not seen by the next read of that set in the same transaction: the
// platform keeps the last composed set, keyed on a setup version the insert does not move.
// This codeunit pins when that composition is recomputed:
//   - after Commit(), on the same Record variable and on a fresh one;
//   - not before it, even on a fresh Record variable (the memo is not per variable);
//   - across a test-method boundary, where the earlier test's transaction ended.
// The two TestBoundary tests are declared in the order they run: the second reads the same
// set the first composed, so a memo that outlived the boundary answers the first test's count.
codeunit 67947 "Test Perm Setup Version"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        RoleTok: Label 'ALT PERMVER TENANT', Locked = true;

    [Test]
    procedure ExpandedPermission_Commit_SameVariableSeesTheLaterGrant()
    // CLAIM: after Commit(), the Record variable that composed the set with one grant answers
    // the grant inserted after that composition.
    var
        ExpandedPermission: Record "Expanded Permission";
    begin
        Initialize();
        InsertTenantSet();
        InsertTenantGrant(Database::"ALT Keyed");

        FilterOnTenantSet(ExpandedPermission);
        Assert.AreEqual(1, ExpandedPermission.Count(), 'the set is composed with its one grant');

        InsertTenantGrant(Database::"ALT Universal");
        Commit();

        Assert.AreEqual(2, ExpandedPermission.Count(), 'after Commit the same variable sees both grants');
    end;

    [Test]
    procedure ExpandedPermission_Commit_FreshVariableSeesTheLaterGrant()
    // CLAIM: after Commit(), a Record variable declared after the composition answers the
    // grant inserted after it.
    var
        ExpandedPermission: Record "Expanded Permission";
        FreshExpandedPermission: Record "Expanded Permission";
    begin
        Initialize();
        InsertTenantSet();
        InsertTenantGrant(Database::"ALT Keyed");

        FilterOnTenantSet(ExpandedPermission);
        Assert.AreEqual(1, ExpandedPermission.Count(), 'the set is composed with its one grant');

        InsertTenantGrant(Database::"ALT Universal");
        Commit();

        FilterOnTenantSet(FreshExpandedPermission);
        Assert.AreEqual(2, FreshExpandedPermission.Count(), 'after Commit a fresh variable sees both grants');
    end;

    [Test]
    procedure ExpandedPermission_NoCommit_FreshVariableAnswersTheComposedSet()
    // CLAIM: without a Commit(), a fresh Record variable is answered from the same composed
    // set as the first one -- the memo belongs to the platform, not to the variable.
    var
        ExpandedPermission: Record "Expanded Permission";
        FreshExpandedPermission: Record "Expanded Permission";
    begin
        Initialize();
        InsertTenantSet();
        InsertTenantGrant(Database::"ALT Keyed");

        FilterOnTenantSet(ExpandedPermission);
        Assert.AreEqual(1, ExpandedPermission.Count(), 'the set is composed with its one grant');

        InsertTenantGrant(Database::"ALT Universal");

        FilterOnTenantSet(FreshExpandedPermission);
        Assert.AreEqual(1, FreshExpandedPermission.Count(), 'without Commit a fresh variable answers the composed set');
    end;

    [Test]
    procedure ExpandedPermission_TestBoundary_A_ComposesOneGrant()
    // CLAIM (first half): composes the tenant set with one grant and leaves it composed.
    var
        ExpandedPermission: Record "Expanded Permission";
    begin
        Initialize();
        InsertTenantSet();
        InsertTenantGrant(Database::"ALT Keyed");

        FilterOnTenantSet(ExpandedPermission);
        Assert.AreEqual(1, ExpandedPermission.Count(), 'the set is composed with its one grant');
    end;

    [Test]
    procedure ExpandedPermission_TestBoundary_B_LaterTestSeesItsOwnGrants()
    // CLAIM (second half): a later test that recreates the set with two grants reads two --
    // the composition the previous test left behind does not answer for it.
    var
        ExpandedPermission: Record "Expanded Permission";
    begin
        Initialize();
        InsertTenantSet();
        InsertTenantGrant(Database::"ALT Keyed");
        InsertTenantGrant(Database::"ALT Universal");

        FilterOnTenantSet(ExpandedPermission);
        Assert.AreEqual(2, ExpandedPermission.Count(), 'a later test sees the grants it inserted');
    end;

    local procedure FilterOnTenantSet(var ExpandedPermission: Record "Expanded Permission")
    var
        NullGuid: Guid;
    begin
        ExpandedPermission.SetRange("App ID", NullGuid);
        ExpandedPermission.SetRange("Role ID", RoleTok);
    end;

    local procedure InsertTenantSet()
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        NullGuid: Guid;
    begin
        TenantPermissionSet."App ID" := NullGuid;
        TenantPermissionSet."Role ID" := RoleTok;
        TenantPermissionSet.Name := 'ALT PermVer Tenant';
        TenantPermissionSet.Insert();
    end;

    local procedure InsertTenantGrant(TableId: Integer)
    var
        TenantPermission: Record "Tenant Permission";
        NullGuid: Guid;
    begin
        TenantPermission."App ID" := NullGuid;
        TenantPermission."Role ID" := RoleTok;
        TenantPermission."Object Type" := TenantPermission."Object Type"::"Table Data";
        TenantPermission."Object ID" := TableId;
        TenantPermission.Insert();
    end;

    local procedure Initialize()
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        TenantPermission: Record "Tenant Permission";
    begin
        // The only rows this codeunit writes are the tenant set and its grants; a test that
        // commits leaves them behind, so each test removes them first.
        TenantPermission.SetRange("Role ID", RoleTok);
        TenantPermission.DeleteAll();
        TenantPermissionSet.SetRange("Role ID", RoleTok);
        TenantPermissionSet.DeleteAll();
    end;
}
