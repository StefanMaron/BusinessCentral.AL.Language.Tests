// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-method
// Scope: in-scope (reads a platform virtual table served from permission-set metadata)
// Fixtures used: ALT Universal, ALT Keyed; writes one Tenant Permission Set, its Tenant
//   Permission rows and the Company rows 'ALT PERMVER CO' / 'ALT PERMVER CO2'
// BC versions: 27.5+
//
// The Company-write arms of "Test Perm Setup Version" (67947): a write to the Company table
// recomposes an already composed permission set inside the same transaction, before any
// Commit. Each arm that creates a company is a codeunit of its own: creating a company
// creates all of its tables, which takes minutes on the Linux tier, and the test harness
// stops a codeunit after 10 minutes. 67955 holds the shared steps.

codeunit 67951 "Test PermVer Company Insert"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Lib: Codeunit "ALT PermVer Company Lib";

    [Test]
    procedure ExpandedPermission_CompanyInsert_SameTransactionSeesTheLaterGrant()
    // CLAIM: inserting a Company after a grant that followed the composition makes the next
    // read of the set, in the same transaction, answer that grant.
    var
        ExpandedPermission: Record "Expanded Permission";
    begin
        Lib.InitializeAndCommit();
        Lib.InsertTenantSet();
        Lib.InsertTenantGrant(Database::"ALT Keyed");

        Lib.FilterOnTenantSet(ExpandedPermission);
        Assert.AreEqual(1, ExpandedPermission.Count(), 'the set is composed with its one grant');

        Lib.InsertTenantGrant(Database::"ALT Universal");
        Lib.InsertCompany(Lib.PermVerCompanyName());

        Assert.AreEqual(2, ExpandedPermission.Count(), 'after the Company insert the set answers both grants');
        Lib.RemoveCompanies();
    end;
}

codeunit 67952 "Test PermVer Company Rename"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Lib: Codeunit "ALT PermVer Company Lib";

    [Test]
    procedure ExpandedPermission_CompanyRename_SameTransactionSeesTheLaterGrant()
    // CLAIM: renaming a Company after a grant that followed the composition makes the next
    // read of the set, in the same transaction, answer that grant.
    var
        ExpandedPermission: Record "Expanded Permission";
        Company: Record Company;
    begin
        Lib.Initialize();
        Lib.InsertCompany(Lib.PermVerCompanyName());
        Commit();
        Lib.InsertTenantSet();
        Lib.InsertTenantGrant(Database::"ALT Keyed");

        Lib.FilterOnTenantSet(ExpandedPermission);
        Assert.AreEqual(1, ExpandedPermission.Count(), 'the set is composed with its one grant');

        Lib.InsertTenantGrant(Database::"ALT Universal");
        Company.Get(Lib.PermVerCompanyName());
        Company.Rename(Lib.PermVerRenamedCompanyName());

        Assert.AreEqual(2, ExpandedPermission.Count(), 'after the Company rename the set answers both grants');
        Lib.RemoveCompanies();
    end;
}

codeunit 67953 "Test PermVer Company Delete"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Lib: Codeunit "ALT PermVer Company Lib";

    [Test]
    procedure ExpandedPermission_CompanyDelete_SameTransactionSeesTheLaterGrant()
    // CLAIM: deleting a Company after a grant that followed the composition makes the next
    // read of the set, in the same transaction, answer that grant.
    var
        ExpandedPermission: Record "Expanded Permission";
        Company: Record Company;
    begin
        Lib.Initialize();
        Lib.InsertCompany(Lib.PermVerCompanyName());
        Commit();
        Lib.InsertTenantSet();
        Lib.InsertTenantGrant(Database::"ALT Keyed");

        Lib.FilterOnTenantSet(ExpandedPermission);
        Assert.AreEqual(1, ExpandedPermission.Count(), 'the set is composed with its one grant');

        Lib.InsertTenantGrant(Database::"ALT Universal");
        Company.Get(Lib.PermVerCompanyName());
        Company.Delete();

        Assert.AreEqual(2, ExpandedPermission.Count(), 'after the Company delete the set answers both grants');
    end;
}

codeunit 67954 "Test PermVer Company Dup Ins"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Lib: Codeunit "ALT PermVer Company Lib";

    [Test]
    procedure ExpandedPermission_CompanyInsertThatDoesNotLand_AnswersTheComposedSet()
    // CLAIM: a Company insert that answers false because the name is taken does not recompose
    // the set -- the next read still answers the composition from before the later grant.
    var
        ExpandedPermission: Record "Expanded Permission";
        Company: Record Company;
    begin
        Lib.Initialize();
        Lib.InsertCompany(Lib.PermVerCompanyName());
        Commit();
        Lib.InsertTenantSet();
        Lib.InsertTenantGrant(Database::"ALT Keyed");

        Lib.FilterOnTenantSet(ExpandedPermission);
        Assert.AreEqual(1, ExpandedPermission.Count(), 'the set is composed with its one grant');

        Lib.InsertTenantGrant(Database::"ALT Universal");
        Company.Init();
        Company.Name := Lib.PermVerCompanyName();
        Assert.IsFalse(Company.Insert(), 'a company under that name already exists');

        Assert.AreEqual(1, ExpandedPermission.Count(), 'an insert that did not land leaves the composed set');
        Lib.RemoveCompanies();
    end;
}

codeunit 67955 "ALT PermVer Company Lib"
{
    // The shared steps of 67951..67954; the same tenant set and grants 67947 writes.
    var
        RoleTok: Label 'ALT PERMVER TENANT', Locked = true;
        CompanyTok: Label 'ALT PERMVER CO', Locked = true;
        RenamedCompanyTok: Label 'ALT PERMVER CO2', Locked = true;

    procedure PermVerCompanyName(): Text[30]
    begin
        exit(CompanyTok);
    end;

    procedure PermVerRenamedCompanyName(): Text[30]
    begin
        exit(RenamedCompanyTok);
    end;

    procedure InsertCompany(Name: Text[30])
    var
        Company: Record Company;
    begin
        Company.Init();
        Company.Name := Name;
        Company.Insert();
    end;

    procedure RemoveCompanies()
    var
        Company: Record Company;
    begin
        if Company.Get(CompanyTok) then
            Company.Delete();
        if Company.Get(RenamedCompanyTok) then
            Company.Delete();
    end;

    procedure FilterOnTenantSet(var ExpandedPermission: Record "Expanded Permission")
    var
        NullGuid: Guid;
    begin
        ExpandedPermission.SetRange("App ID", NullGuid);
        ExpandedPermission.SetRange("Role ID", RoleTok);
    end;

    procedure InsertTenantSet()
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        NullGuid: Guid;
    begin
        TenantPermissionSet."App ID" := NullGuid;
        TenantPermissionSet."Role ID" := RoleTok;
        TenantPermissionSet.Name := 'ALT PermVer Tenant';
        TenantPermissionSet.Insert();
    end;

    procedure InsertTenantGrant(TableId: Integer)
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

    procedure InitializeAndCommit()
    begin
        // As in 67947: the composition an earlier test left behind answers the first read until
        // a transaction ends, so the first read must follow a Commit to be this test's own.
        Initialize();
        Commit();
    end;

    procedure Initialize()
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        TenantPermission: Record "Tenant Permission";
    begin
        TenantPermission.SetRange("Role ID", RoleTok);
        TenantPermission.DeleteAll();
        TenantPermissionSet.SetRange("Role ID", RoleTok);
        TenantPermissionSet.DeleteAll();
        RemoveCompanies();
    end;
}
