// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissionset-object
// Scope: in-scope (reads two platform virtual tables served from permission-set metadata)
// Fixtures used: ALT ExpPerm Leaf (67945), ALT ExpPerm Comp (67946), ALT Universal, ALT Keyed,
//   ALT Composite; writes one Tenant Permission Set + Tenant Permission row, removed by Initialize()
// BC versions: 27.5+
//
// "Permission" (2000000005) is pinned by "Test Perm. Set Grants" (60604). Its two siblings
// are not pinned anywhere, and they answer different questions about the same set:
//   - "Metadata Permission" (2000000251): the grants a set DECLARES in its own source,
//     keyed by (App ID, Role ID, Object Type, Object ID), including non-assignable sets.
//   - "Expanded Permission" (2000000254): the grants a set has once its
//     IncludedPermissionSets are expanded -- the table the System Application reads.
// The fixture pair is a composite that declares "ALT Universal" = RIMD and includes a leaf
// granting "ALT Keyed" = R, so a table answering the other table's question, or answering
// nothing, fails a count or a Get below.
codeunit 67945 "Test Metadata Expanded Perm"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        CompRoleTok: Label 'ALT EXPPERM COMP', Locked = true;
        LeafRoleTok: Label 'ALT EXPPERM LEAF', Locked = true;
        TenantRoleTok: Label 'ALT EXPPERM TENANT', Locked = true;

    [Test]
    procedure MetadataPermission_IncludingSet_ListsOnlyItsOwnDeclaredGrant()
    // CLAIM: "Metadata Permission" lists the grants a set declares, NOT those it inherits
    // through IncludedPermissionSets -- one row for the composite, and none for the leaf's
    // table under the composite's Role ID.
    var
        MetadataPermission: Record "Metadata Permission";
    begin
        Initialize();

        MetadataPermission.SetRange("App ID", CurrentAppId());
        MetadataPermission.SetRange("Role ID", CompRoleTok);
        Assert.AreEqual(1, MetadataPermission.Count(), 'the composite declares exactly one grant of its own');

        MetadataPermission.SetRange("Object ID", Database::"ALT Keyed");
        Assert.IsTrue(MetadataPermission.IsEmpty(), 'the included set''s grant is not the composite''s declaration');
    end;

    [Test]
    procedure MetadataPermission_DeclaredGrant_CarriesTypeAndMask()
    // CLAIM: the declared `tabledata "ALT Universal" = RIMD` row is keyed under Object Type
    // Table Data, carries Yes in the four RIMD columns and blank Execute, and is an Include.
    var
        MetadataPermission: Record "Metadata Permission";
    begin
        Initialize();

        MetadataPermission.Get(CurrentAppId(), CompRoleTok, MetadataPermission."Object Type"::"Table Data", Database::"ALT Universal");

        Assert.AreEqual(MetadataPermission."Read Permission"::Yes, MetadataPermission."Read Permission", 'R of RIMD');
        Assert.AreEqual(MetadataPermission."Insert Permission"::Yes, MetadataPermission."Insert Permission", 'I of RIMD');
        Assert.AreEqual(MetadataPermission."Modify Permission"::Yes, MetadataPermission."Modify Permission", 'M of RIMD');
        Assert.AreEqual(MetadataPermission."Delete Permission"::Yes, MetadataPermission."Delete Permission", 'D of RIMD');
        Assert.AreEqual(MetadataPermission."Execute Permission"::" ", MetadataPermission."Execute Permission", 'RIMD grants no X');
        Assert.AreEqual(MetadataPermission.Type::Include, MetadataPermission.Type, 'a Permissions entry is an include');
    end;

    [Test]
    procedure MetadataPermission_NonAssignableSet_IsListedWithItsReadOnlyGrant()
    // CLAIM: a set declared Assignable = false still lists its grants, and a grant of R alone
    // sets Read and leaves Insert blank -- so a mask read as RIMD for every row fails here.
    var
        MetadataPermission: Record "Metadata Permission";
    begin
        Initialize();

        MetadataPermission.SetRange("App ID", CurrentAppId());
        MetadataPermission.SetRange("Role ID", LeafRoleTok);
        Assert.AreEqual(1, MetadataPermission.Count(), 'the leaf declares exactly one grant');

        MetadataPermission.FindFirst();
        Assert.AreEqual(Database::"ALT Keyed", MetadataPermission."Object ID", 'the leaf grants ALT Keyed');
        Assert.AreEqual(MetadataPermission."Read Permission"::Yes, MetadataPermission."Read Permission", 'R is granted');
        Assert.AreEqual(MetadataPermission."Insert Permission"::" ", MetadataPermission."Insert Permission", 'I is not granted');
    end;

    [Test]
    procedure MetadataPermission_UndeclaredObject_GetFailsWithCannotFind()
    // CLAIM: a (set, object) pair the set never declares is not a row -- Get raises the
    // platform's cannot-find error rather than answering a defaulted record.
    var
        MetadataPermission: Record "Metadata Permission";
    begin
        Initialize();

        asserterror MetadataPermission.Get(CurrentAppId(), CompRoleTok, MetadataPermission."Object Type"::"Table Data", Database::"ALT Keyed");
        Assert.ExpectedErrorCannotFind(Database::"Metadata Permission");
    end;

    [Test]
    procedure ExpandedPermission_IncludingSet_UnionsTheIncludedSetsGrant()
    // CLAIM: "Expanded Permission" lists the composite's own grant AND the one it inherits
    // from its included set -- two rows where "Metadata Permission" lists one.
    var
        ExpandedPermission: Record "Expanded Permission";
    begin
        Initialize();

        ExpandedPermission.SetRange("App ID", CurrentAppId());
        ExpandedPermission.SetRange("Role ID", CompRoleTok);
        Assert.AreEqual(2, ExpandedPermission.Count(), 'own grant plus the included set''s grant');

        ExpandedPermission.Get(CurrentAppId(), CompRoleTok, ExpandedPermission."Object Type"::"Table Data", Database::"ALT Keyed");
        Assert.AreEqual(ExpandedPermission."Read Permission"::Yes, ExpandedPermission."Read Permission", 'the inherited R');
        Assert.AreEqual(ExpandedPermission."Insert Permission"::" ", ExpandedPermission."Insert Permission", 'the leaf grants no I');
    end;

    [Test]
    procedure ExpandedPermission_OwnGrant_CarriesTheRimdMask()
    // CLAIM: the composite's own RIMD grant survives expansion with all four columns Yes.
    var
        ExpandedPermission: Record "Expanded Permission";
    begin
        Initialize();

        ExpandedPermission.Get(CurrentAppId(), CompRoleTok, ExpandedPermission."Object Type"::"Table Data", Database::"ALT Universal");

        Assert.AreEqual(ExpandedPermission."Read Permission"::Yes, ExpandedPermission."Read Permission", 'R of RIMD');
        Assert.AreEqual(ExpandedPermission."Insert Permission"::Yes, ExpandedPermission."Insert Permission", 'I of RIMD');
        Assert.AreEqual(ExpandedPermission."Modify Permission"::Yes, ExpandedPermission."Modify Permission", 'M of RIMD');
        Assert.AreEqual(ExpandedPermission."Delete Permission"::Yes, ExpandedPermission."Delete Permission", 'D of RIMD');
    end;

    [Test]
    procedure ExpandedPermission_NotGrantedObject_GetFailsWithCannotFind()
    // CLAIM: a table neither the composite nor its included set grants is not a row.
    var
        ExpandedPermission: Record "Expanded Permission";
    begin
        Initialize();

        asserterror ExpandedPermission.Get(CurrentAppId(), CompRoleTok, ExpandedPermission."Object Type"::"Table Data", Database::"ALT Composite");
        Assert.ExpectedErrorCannotFind(Database::"Expanded Permission");
    end;

    [Test]
    procedure ExpandedPermission_TenantPermissionSet_IsListedUnderTenantScope()
    // CLAIM: "Expanded Permission" also lists sets created at runtime in "Tenant Permission
    // Set", under Scope Tenant, with the grant written to "Tenant Permission" -- the metadata
    // sets above are Scope System. "Metadata Permission" lists metadata sets only.
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        TenantPermission: Record "Tenant Permission";
        ExpandedPermission: Record "Expanded Permission";
        MetadataPermission: Record "Metadata Permission";
        NullGuid: Guid;
    begin
        Initialize();

        TenantPermissionSet."App ID" := NullGuid;
        TenantPermissionSet."Role ID" := TenantRoleTok;
        TenantPermissionSet.Name := 'ALT ExpPerm Tenant';
        TenantPermissionSet.Insert();
        TenantPermission."App ID" := NullGuid;
        TenantPermission."Role ID" := TenantRoleTok;
        TenantPermission."Object Type" := TenantPermission."Object Type"::"Table Data";
        TenantPermission."Object ID" := Database::"ALT Keyed";
        // Every permission column's InitValue is Yes, so a read-only grant clears the other four.
        TenantPermission."Read Permission" := TenantPermission."Read Permission"::Yes;
        TenantPermission."Insert Permission" := TenantPermission."Insert Permission"::" ";
        TenantPermission."Modify Permission" := TenantPermission."Modify Permission"::" ";
        TenantPermission."Delete Permission" := TenantPermission."Delete Permission"::" ";
        TenantPermission."Execute Permission" := TenantPermission."Execute Permission"::" ";
        TenantPermission.Insert();

        ExpandedPermission.Get(NullGuid, TenantRoleTok, ExpandedPermission."Object Type"::"Table Data", Database::"ALT Keyed");
        Assert.AreEqual(ExpandedPermission.Scope::Tenant, ExpandedPermission.Scope, 'a tenant set is listed under Scope Tenant');
        Assert.AreEqual(ExpandedPermission."Read Permission"::Yes, ExpandedPermission."Read Permission", 'the tenant grant''s R');
        Assert.AreEqual(ExpandedPermission."Insert Permission"::" ", ExpandedPermission."Insert Permission", 'the tenant grant has no I');

        MetadataPermission.SetRange("Role ID", TenantRoleTok);
        Assert.IsTrue(MetadataPermission.IsEmpty(), 'Metadata Permission lists metadata sets only');
    end;

    [Test]
    procedure ExpandedPermission_MetadataSet_IsListedUnderSystemScope()
    // CLAIM: a set declared in an extension's source is Scope System in "Expanded Permission".
    var
        ExpandedPermission: Record "Expanded Permission";
    begin
        Initialize();

        ExpandedPermission.Get(CurrentAppId(), CompRoleTok, ExpandedPermission."Object Type"::"Table Data", Database::"ALT Universal");
        Assert.AreEqual(ExpandedPermission.Scope::System, ExpandedPermission.Scope, 'an extension-declared set is Scope System');
    end;

    [Test]
    procedure ExpandedPermission_OpenVariable_SeesATenantSetInsertedAfterItsFirstRead()
    // CLAIM: the table is computed per request, not per Record variable: a variable that
    // already read "no rows" for a role finds that role's grant once a tenant set for it is
    // inserted, on Get, Count and IsEmpty alike.
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        TenantPermission: Record "Tenant Permission";
        ExpandedPermission: Record "Expanded Permission";
        NullGuid: Guid;
    begin
        Initialize();

        ExpandedPermission.SetRange("App ID", NullGuid);
        ExpandedPermission.SetRange("Role ID", TenantRoleTok);
        Assert.IsTrue(ExpandedPermission.IsEmpty(), 'no tenant set exists yet');

        TenantPermissionSet."App ID" := NullGuid;
        TenantPermissionSet."Role ID" := TenantRoleTok;
        TenantPermissionSet.Name := 'ALT ExpPerm Tenant';
        TenantPermissionSet.Insert();
        TenantPermission."App ID" := NullGuid;
        TenantPermission."Role ID" := TenantRoleTok;
        TenantPermission."Object Type" := TenantPermission."Object Type"::"Table Data";
        TenantPermission."Object ID" := Database::"ALT Keyed";
        TenantPermission.Insert();

        Assert.IsFalse(ExpandedPermission.IsEmpty(), 'the same variable sees the new set');
        Assert.AreEqual(1, ExpandedPermission.Count(), 'the new set''s one grant');
        Assert.IsTrue(ExpandedPermission.Get(NullGuid, TenantRoleTok, ExpandedPermission."Object Type"::"Table Data", Database::"ALT Keyed"),
            'the same variable finds the new grant by key');
    end;

    local procedure CurrentAppId(): Guid
    var
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        exit(Info.Id);
    end;

    local procedure Initialize()
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        TenantPermission: Record "Tenant Permission";
    begin
        // Both virtual tables are read-only; the only rows this codeunit writes are the
        // tenant set and its grant, removed here so each test starts without them.
        TenantPermission.SetRange("Role ID", TenantRoleTok);
        TenantPermission.DeleteAll();
        TenantPermissionSet.SetRange("Role ID", TenantRoleTok);
        TenantPermissionSet.DeleteAll();
        Cleanup.Initialize();
    end;
}
