// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-commit-method
// Scope: in-scope (reads a platform virtual table served from permission-set metadata)
// Fixtures used: ALT Universal, ALT Keyed; writes one Tenant Permission Set, its Tenant
//   Permission rows and the Company rows 'ALT PERMVER CO' / 'ALT PERMVER CO2', removed by
//   Initialize()
// BC versions: 27.5+
//
// "Test Metadata Expanded Perm" (67945) pins that a grant inserted AFTER a set's permissions
// were composed is not seen by the next read of that set in the same transaction: the
// platform keeps the last composed set, keyed on a setup version the insert does not move.
// This codeunit pins when that composition is recomputed:
//   - after Commit(), on the same Record variable and on a fresh one;
//   - not before it, even on a fresh Record variable (the memo is not per variable);
//   - after an asserterror rolls back a grant the composition had included;
//   - across a test-method boundary, where the earlier test's transaction ended;
//   - after a guarded Codeunit.Run whose codeunit composed the set and then failed, and after
//     one that inserted a grant and succeeded (the run codeunits 67948 and 67949 below).
//   - after a Company insert, rename or delete in the same transaction, before any Commit
//     (the platform recomputes on a write to the Company table, not only at transaction end);
//     not after a Company insert that answers false because the name is taken, nor after an
//     insert into a temporary Company record; but after a delete that finds no row.
// The two TestBoundary tests are declared in the order they run: the second reads the same
// set the first composed, so a memo that outlived the boundary answers the first test's count.
// That is why the second one does not Commit before its first read, and every other test does.
codeunit 67947 "Test Perm Setup Version"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        RoleTok: Label 'ALT PERMVER TENANT', Locked = true;
        CompanyTok: Label 'ALT PERMVER CO', Locked = true;
        RenamedCompanyTok: Label 'ALT PERMVER CO2', Locked = true;

    [Test]
    procedure ExpandedPermission_Commit_SameVariableSeesTheLaterGrant()
    // CLAIM: after Commit(), the Record variable that composed the set with one grant answers
    // the grant inserted after that composition.
    var
        ExpandedPermission: Record "Expanded Permission";
    begin
        InitializeAndCommit();
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
        InitializeAndCommit();
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
        InitializeAndCommit();
        InsertTenantSet();
        InsertTenantGrant(Database::"ALT Keyed");

        FilterOnTenantSet(ExpandedPermission);
        Assert.AreEqual(1, ExpandedPermission.Count(), 'the set is composed with its one grant');

        InsertTenantGrant(Database::"ALT Universal");

        FilterOnTenantSet(FreshExpandedPermission);
        Assert.AreEqual(1, FreshExpandedPermission.Count(), 'without Commit a fresh variable answers the composed set');
    end;

    [Test]
    procedure ExpandedPermission_AssertErrorRollback_ReReadDropsTheRolledBackGrant()
    // CLAIM: a set composed with a grant that an asserterror then rolls back is recomputed on
    // the next read -- it answers the one committed grant, not the two it was composed with.
    var
        ExpandedPermission: Record "Expanded Permission";
    begin
        Initialize();
        InsertTenantSet();
        InsertTenantGrant(Database::"ALT Keyed");
        Commit();

        InsertTenantGrant(Database::"ALT Universal");
        FilterOnTenantSet(ExpandedPermission);
        Assert.AreEqual(2, ExpandedPermission.Count(), 'the set is composed with the committed and the pending grant');

        asserterror Error('roll back the pending grant');

        Assert.AreEqual(1, ExpandedPermission.Count(), 'after the rollback the set answers only the committed grant');
    end;

    [Test]
    procedure ExpandedPermission_TestBoundary_A_ComposesOneGrant()
    // CLAIM (first half): composes the tenant set with one grant and leaves it composed.
    var
        ExpandedPermission: Record "Expanded Permission";
    begin
        InitializeAndCommit();
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

    [Test]
    procedure ExpandedPermission_FailedGuardedRun_ReReadDropsTheRolledBackGrant()
    // CLAIM: a guarded Codeunit.Run whose codeunit inserts a grant, composes the set with it and
    // then raises an error is rolled back, and the next read of the set outside the run answers
    // only the committed grant -- not the two the failed run composed.
    var
        ExpandedPermission: Record "Expanded Permission";
        Ok: Boolean;
    begin
        Initialize();
        InsertTenantSet();
        InsertTenantGrant(Database::"ALT Keyed");
        Commit();

        Ok := Codeunit.Run(Codeunit::"ALT PermVer Failing Run");

        Assert.IsFalse(Ok, 'the run codeunit raised an error');
        Assert.AreEqual('ALT PermVer run composed 2', GetLastErrorText(), 'inside the run the set was composed with both grants');
        FilterOnTenantSet(ExpandedPermission);
        Assert.AreEqual(1, ExpandedPermission.Count(), 'after the failed run the set answers only the committed grant');
    end;

    [Test]
    procedure ExpandedPermission_SucceededGuardedRun_SameVariableSeesTheRunsGrant()
    // CLAIM: a set composed with one grant before a guarded Codeunit.Run that inserts a second
    // grant and succeeds answers both grants on the next read of the same Record variable.
    var
        ExpandedPermission: Record "Expanded Permission";
        Ok: Boolean;
    begin
        Initialize();
        InsertTenantSet();
        InsertTenantGrant(Database::"ALT Keyed");
        Commit();

        FilterOnTenantSet(ExpandedPermission);
        Assert.AreEqual(1, ExpandedPermission.Count(), 'the set is composed with its one grant');

        Ok := Codeunit.Run(Codeunit::"ALT PermVer Granting Run");

        Assert.IsTrue(Ok, 'the run codeunit succeeded');
        Assert.AreEqual(2, ExpandedPermission.Count(), 'after the successful run the same variable sees both grants');
    end;

    [Test]
    procedure ExpandedPermission_CompanyInsert_SameTransactionSeesTheLaterGrant()
    // CLAIM: inserting a Company after a grant that followed the composition makes the next
    // read of the set, in the same transaction, answer that grant.
    var
        ExpandedPermission: Record "Expanded Permission";
    begin
        InitializeAndCommit();
        InsertTenantSet();
        InsertTenantGrant(Database::"ALT Keyed");

        FilterOnTenantSet(ExpandedPermission);
        Assert.AreEqual(1, ExpandedPermission.Count(), 'the set is composed with its one grant');

        InsertTenantGrant(Database::"ALT Universal");
        InsertCompany(CompanyTok);

        Assert.AreEqual(2, ExpandedPermission.Count(), 'after the Company insert the set answers both grants');
        RemoveCompanies();
    end;

    [Test]
    procedure ExpandedPermission_CompanyRename_SameTransactionSeesTheLaterGrant()
    // CLAIM: renaming a Company after a grant that followed the composition makes the next
    // read of the set, in the same transaction, answer that grant.
    var
        ExpandedPermission: Record "Expanded Permission";
        Company: Record Company;
    begin
        Initialize();
        InsertCompany(CompanyTok);
        Commit();
        InsertTenantSet();
        InsertTenantGrant(Database::"ALT Keyed");

        FilterOnTenantSet(ExpandedPermission);
        Assert.AreEqual(1, ExpandedPermission.Count(), 'the set is composed with its one grant');

        InsertTenantGrant(Database::"ALT Universal");
        Company.Get(CompanyTok);
        Company.Rename(RenamedCompanyTok);

        Assert.AreEqual(2, ExpandedPermission.Count(), 'after the Company rename the set answers both grants');
        RemoveCompanies();
    end;

    [Test]
    procedure ExpandedPermission_CompanyDelete_SameTransactionSeesTheLaterGrant()
    // CLAIM: deleting a Company after a grant that followed the composition makes the next
    // read of the set, in the same transaction, answer that grant.
    var
        ExpandedPermission: Record "Expanded Permission";
        Company: Record Company;
    begin
        Initialize();
        InsertCompany(CompanyTok);
        Commit();
        InsertTenantSet();
        InsertTenantGrant(Database::"ALT Keyed");

        FilterOnTenantSet(ExpandedPermission);
        Assert.AreEqual(1, ExpandedPermission.Count(), 'the set is composed with its one grant');

        InsertTenantGrant(Database::"ALT Universal");
        Company.Get(CompanyTok);
        Company.Delete();

        Assert.AreEqual(2, ExpandedPermission.Count(), 'after the Company delete the set answers both grants');
    end;

    [Test]
    procedure ExpandedPermission_CompanyInsertThatDoesNotLand_AnswersTheComposedSet()
    // CLAIM: a Company insert that answers false because the name is taken does not recompose
    // the set -- the next read still answers the composition from before the later grant.
    var
        ExpandedPermission: Record "Expanded Permission";
        Company: Record Company;
    begin
        Initialize();
        InsertCompany(CompanyTok);
        Commit();
        InsertTenantSet();
        InsertTenantGrant(Database::"ALT Keyed");

        FilterOnTenantSet(ExpandedPermission);
        Assert.AreEqual(1, ExpandedPermission.Count(), 'the set is composed with its one grant');

        InsertTenantGrant(Database::"ALT Universal");
        Company.Init();
        Company.Name := CompanyTok;
        Assert.IsFalse(Company.Insert(), 'a company under that name already exists');

        Assert.AreEqual(1, ExpandedPermission.Count(), 'an insert that did not land leaves the composed set');
        RemoveCompanies();
    end;

    [Test]
    procedure ExpandedPermission_CompanyDeleteThatDoesNotLand_SameTransactionSeesTheLaterGrant()
    // CLAIM: a Company delete of a name no company has -- Delete() answers false -- still
    // recomposes the set: the platform's Company delete arm runs before the row is looked up.
    var
        ExpandedPermission: Record "Expanded Permission";
        Company: Record Company;
    begin
        InitializeAndCommit();
        InsertTenantSet();
        InsertTenantGrant(Database::"ALT Keyed");

        FilterOnTenantSet(ExpandedPermission);
        Assert.AreEqual(1, ExpandedPermission.Count(), 'the set is composed with its one grant');

        InsertTenantGrant(Database::"ALT Universal");
        Company.Name := CompanyTok;
        Assert.IsFalse(Company.Delete(), 'no company has that name');

        Assert.AreEqual(2, ExpandedPermission.Count(), 'after the Company delete that found no row the set answers both grants');
    end;

    [Test]
    procedure ExpandedPermission_TemporaryCompanyInsert_AnswersTheComposedSet()
    // CLAIM: inserting into a temporary Company record writes no Company row, so the set is
    // not recomposed -- the next read answers the composition from before the later grant.
    var
        ExpandedPermission: Record "Expanded Permission";
        TempCompany: Record Company temporary;
    begin
        InitializeAndCommit();
        InsertTenantSet();
        InsertTenantGrant(Database::"ALT Keyed");

        FilterOnTenantSet(ExpandedPermission);
        Assert.AreEqual(1, ExpandedPermission.Count(), 'the set is composed with its one grant');

        InsertTenantGrant(Database::"ALT Universal");
        TempCompany.Init();
        TempCompany.Name := CompanyTok;
        TempCompany.Insert();

        Assert.AreEqual(1, ExpandedPermission.Count(), 'a temporary Company insert leaves the composed set');
    end;

    local procedure InsertCompany(Name: Text[30])
    var
        Company: Record Company;
    begin
        Company.Init();
        Company.Name := Name;
        Company.Insert();
    end;

    local procedure RemoveCompanies()
    var
        Company: Record Company;
    begin
        if Company.Get(CompanyTok) then
            Company.Delete();
        if Company.Get(RenamedCompanyTok) then
            Company.Delete();
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

    local procedure InitializeAndCommit()
    begin
        // The composition a previous test made after its last transaction end still answers
        // this test's first read until a transaction ends: without this Commit, the Commit test
        // below read 2 where it had inserted one grant, on every cloud leg of corpus run
        // 36673250565. Ending the transaction here makes this test's first read its own.
        Initialize();
        Commit();
    end;

    local procedure Initialize()
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        TenantPermission: Record "Tenant Permission";
    begin
        // The rows this codeunit writes are the tenant set, its grants and the Company rows; a
        // test that commits leaves them behind, so each test removes them first.
        TenantPermission.SetRange("Role ID", RoleTok);
        TenantPermission.DeleteAll();
        TenantPermissionSet.SetRange("Role ID", RoleTok);
        TenantPermissionSet.DeleteAll();
        RemoveCompanies();
    end;
}

codeunit 67948 "ALT PermVer Failing Run"
{
    // Run by 67947: inserts the second grant, composes the set with it, then fails, so the
    // guarded Codeunit.Run rolls the grant back. The error text carries the composed count.
    trigger OnRun()
    var
        TenantPermission: Record "Tenant Permission";
        ExpandedPermission: Record "Expanded Permission";
        NullGuid: Guid;
    begin
        TenantPermission."App ID" := NullGuid;
        TenantPermission."Role ID" := 'ALT PERMVER TENANT';
        TenantPermission."Object Type" := TenantPermission."Object Type"::"Table Data";
        TenantPermission."Object ID" := Database::"ALT Universal";
        TenantPermission.Insert();

        ExpandedPermission.SetRange("App ID", NullGuid);
        ExpandedPermission.SetRange("Role ID", 'ALT PERMVER TENANT');
        Error('ALT PermVer run composed %1', ExpandedPermission.Count());
    end;
}

codeunit 67949 "ALT PermVer Granting Run"
{
    // Run by 67947: inserts the second grant and succeeds, so the guarded Codeunit.Run commits it.
    trigger OnRun()
    var
        TenantPermission: Record "Tenant Permission";
        NullGuid: Guid;
    begin
        TenantPermission."App ID" := NullGuid;
        TenantPermission."Role ID" := 'ALT PERMVER TENANT';
        TenantPermission."Object Type" := TenantPermission."Object Type"::"Table Data";
        TenantPermission."Object ID" := Database::"ALT Universal";
        TenantPermission.Insert();
    end;
}
