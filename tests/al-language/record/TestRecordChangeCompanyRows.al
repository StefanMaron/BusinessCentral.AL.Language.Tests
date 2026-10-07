// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-changecompany-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Universal (60000); writes the Company row 'ALT CHGCO ROWS' and its own ALT Universal rows
// BC versions: 27.0+
//
// CLAIM UNDER TEST: Record.ChangeCompany(<name>) to a company that has a row in the Company table
// answers true for the test user, and the record then reads and writes THAT company's own rows,
// separate from the session company's rows of the same table. A per-company table holds one set of
// rows per company, so the same primary key can exist in both.
//
// Each arm that creates a company is a codeunit of its own: creating a company creates all of its
// tables, which takes minutes on the Linux tier, and the test harness stops a codeunit after ten
// minutes (see TestPermissionSetupVersionCompany.al). 69972 holds the shared steps.
//   69970  the rows of the two companies are apart; a table that is not per company is shared;
//          a TableRelation is validated against the record's own company
//   69971  the answer follows the Company table
//   69973  an error rolls back the uncommitted writes in the other company, and only those
//   69974  a FlowField on a record in the other company counts that company's rows
//   69975  RecordRef.ChangeCompany reads and writes the other company's rows

table 69970 "ALT ChgCo Tenant"
{
    // A table that is NOT per company: ChangeCompany has no company to move it to.
    DataPerCompany = false;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 69971 "ALT ChgCo Rel"
{
    // A per-company table whose field is related to another per-company table.
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { DataClassification = SystemMetadata; }
        field(2; "Universal No."; Integer)
        {
            DataClassification = SystemMetadata;
            TableRelation = "ALT Universal"."Entry No.";
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

codeunit 69970 "Test ChangeCompany Rows"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Lib: Codeunit "ALT ChangeCompany Lib";

    [Test]
    procedure ChangeCompany_ToInsertedCompany_ReadsAndWritesThatCompanysOwnRows()
    // CLAIM: after ChangeCompany to a company the test inserted, a record answers true, starts on an
    // empty table, keeps its own row under the same primary key as the session company's row, and a
    // Modify or DeleteAll through it leaves the session company's row alone. Changing back to the
    // session company shows the session company's row again.
    var
        Home: Record "ALT Universal";
        Other: Record "ALT Universal";
        Back: Record "ALT Universal";
        Tenant: Record "ALT ChgCo Tenant";
        TenantOther: Record "ALT ChgCo Tenant";
        Rel: Record "ALT ChgCo Rel";
    begin
        Lib.Cleanup();
        Tenant.DeleteAll();
        Home.Init();
        Home."Entry No." := 1;
        Home."Integer Field" := 11;
        Home.Insert();
        Lib.InsertCompany();

        Assert.IsTrue(Other.ChangeCompany(Lib.CompanyNameUnderTest()), 'ChangeCompany to the inserted company');
        Assert.AreEqual(Lib.CompanyNameUnderTest(), Other.CurrentCompany(), 'the record now reports the other company');
        Assert.AreEqual(0, Other.Count(), 'the inserted company starts with no rows of its own');

        Other.Init();
        Other."Entry No." := 1;
        Other."Integer Field" := 22;
        Other.Insert();
        Assert.AreEqual(1, Other.Count(), 'the other company holds the one row inserted through the record');
        Other.Get(1);
        Assert.AreEqual(22, Other."Integer Field", 'the other company reads its own row');

        Home.Get(1);
        Assert.AreEqual(11, Home."Integer Field", 'the session company still reads its own row under the same key');
        Assert.AreEqual(1, Home.Count(), 'the session company holds exactly its own row');

        Other."Integer Field" := 33;
        Other.Modify();
        Home.Get(1);
        Assert.AreEqual(11, Home."Integer Field", 'a Modify in the other company leaves the session row alone');

        Other.DeleteAll();
        Assert.AreEqual(0, Other.Count(), 'the other company is empty again');
        Assert.AreEqual(1, Home.Count(), 'a DeleteAll in the other company leaves the session row');

        Assert.IsTrue(Back.ChangeCompany(CompanyName()), 'ChangeCompany back to the session company');
        Assert.AreEqual(1, Back.Count(), 'the session company shows its own row');
        Back.Get(1);
        Assert.AreEqual(11, Back."Integer Field", 'and its value');

        // A table that is not per company has one set of rows, whichever company a record names.
        Tenant."Entry No." := 7;
        Tenant.Insert();
        Assert.IsTrue(TenantOther.ChangeCompany(Lib.CompanyNameUnderTest()), 'ChangeCompany on a table that is not per company');
        Assert.AreEqual(1, TenantOther.Count(), 'the row of a table that is not per company is seen from the other company');
        Assert.IsTrue(TenantOther.Get(7), 'and found by its key');

        // A TableRelation is validated against the rows of the company the record is on: the
        // session company holds Entry No. 1 and the other company, emptied above, does not.
        Assert.IsTrue(Rel.ChangeCompany(Lib.CompanyNameUnderTest()), 'ChangeCompany for the related record');
        Rel."Entry No." := 1;
        asserterror Rel.Validate("Universal No.", 1);
        Assert.ExpectedError('cannot be found in the related table');
        Other.Init();
        Other."Entry No." := 1;
        Other.Insert();
        Rel.Validate("Universal No.", 1);
        Assert.AreEqual(1, Rel."Universal No.", 'the relation is found once the other company holds the row');

        Tenant.DeleteAll();
        Lib.Cleanup();
    end;
}

codeunit 69971 "Test ChangeCompany Deleted"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Lib: Codeunit "ALT ChangeCompany Lib";

    [Test]
    procedure ChangeCompany_ToCompanyThatNoLongerExists_AnswersFalse()
    // CLAIM: ChangeCompany answers true for a company while its Company row exists and false once
    // the row has been deleted, so the answer follows the Company table and is not a name cached
    // from the first call.
    var
        Rec: Record "ALT Universal";
        Later: Record "ALT Universal";
    begin
        Lib.Cleanup();
        Lib.InsertCompany();
        Assert.IsTrue(Rec.ChangeCompany(Lib.CompanyNameUnderTest()), 'ChangeCompany while the company exists');

        Lib.DeleteCompany();
        Assert.IsFalse(Later.ChangeCompany(Lib.CompanyNameUnderTest()), 'ChangeCompany after the company is deleted');
    end;
}

codeunit 69973 "Test ChangeCompany Rollback"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Lib: Codeunit "ALT ChangeCompany Lib";

    [Test]
    procedure ChangeCompany_ErrorRollsBackAnUncommittedWriteInTheOtherCompany()
    // CLAIM: an error rolls the other company's rows back to the last Commit, like the session
    // company's: the first write into the company, made before any Commit, is undone; and once a
    // row is committed it stays while the row written after it is gone.
    var
        Other: Record "ALT Universal";
    begin
        Lib.Cleanup();
        Lib.InsertCompany();
        Assert.IsTrue(Other.ChangeCompany(Lib.CompanyNameUnderTest()), 'ChangeCompany to the inserted company');

        Other.Init();
        Other."Entry No." := 4;
        Other."Integer Field" := 40;
        Other.Insert();
        Assert.AreEqual(1, Other.Count(), 'the first write into the company is there before the error');
        asserterror Error('roll back the first write');
        Assert.AreEqual(0, Other.Count(), 'the first write into the company is rolled back');

        Other.Init();
        Other."Entry No." := 5;
        Other."Integer Field" := 50;
        Other.Insert();
        Commit();

        Other.Init();
        Other."Entry No." := 6;
        Other."Integer Field" := 60;
        Other.Insert();
        Assert.AreEqual(2, Other.Count(), 'both rows are there before the error');

        asserterror Error('roll back');

        Assert.AreEqual(1, Other.Count(), 'only the committed row survives the rollback');
        Assert.IsTrue(Other.Get(5), 'the committed row');
        Assert.IsFalse(Other.Get(6), 'the row written after the Commit is gone');

        Other.DeleteAll();
        Commit();
        Lib.Cleanup();
    end;
}

codeunit 69974 "Test ChangeCompany FlowField"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Lib: Codeunit "ALT ChangeCompany Lib";

    [Test]
    procedure ChangeCompany_FlowFieldOnARecordInTheOtherCompany_CountsThatCompanysRows()
    // CLAIM: a FlowField is calculated over the rows of the company its record is on. The parent
    // has the same key in both companies; each company has its own children.
    var
        HomeParent: Record "ALT Parent";
        HomeChild: Record "ALT Child";
        OtherParent: Record "ALT Parent";
        OtherChild: Record "ALT Child";
    begin
        Lib.CleanupParents();
        HomeParent."Entry No." := 1;
        HomeParent.Insert();
        HomeChild."Entry No." := 1;
        HomeChild."Parent Entry No." := 1;
        HomeChild.Amount := 3;
        HomeChild.Insert();
        Lib.InsertCompany();

        Assert.IsTrue(OtherParent.ChangeCompany(Lib.CompanyNameUnderTest()), 'ChangeCompany for the parent');
        Assert.IsTrue(OtherChild.ChangeCompany(Lib.CompanyNameUnderTest()), 'ChangeCompany for the children');
        OtherParent."Entry No." := 1;
        OtherParent.Insert();
        OtherChild."Entry No." := 1;
        OtherChild."Parent Entry No." := 1;
        OtherChild.Amount := 10;
        OtherChild.Insert();
        OtherChild."Entry No." := 2;
        OtherChild.Amount := 20;
        OtherChild.Insert();

        OtherParent.Get(1);
        OtherParent.CalcFields("Child Count", "Child Amount");
        Assert.AreEqual(2, OtherParent."Child Count", 'the other company counts its own two children');
        Assert.AreEqual(30, OtherParent."Child Amount", 'and sums their amounts');

        HomeParent.Get(1);
        HomeParent.CalcFields("Child Count", "Child Amount");
        Assert.AreEqual(1, HomeParent."Child Count", 'the session company counts its one child');
        Assert.AreEqual(3, HomeParent."Child Amount", 'and sums its amount');

        Lib.CleanupParents();
    end;
}

codeunit 69975 "Test ChangeCompany RecordRef"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Lib: Codeunit "ALT ChangeCompany Lib";

    [Test]
    procedure RecordRef_ChangeCompany_ReadsAndWritesTheOtherCompanysRows()
    // CLAIM: RecordRef.ChangeCompany moves the reference to the other company's rows the way
    // Record.ChangeCompany does.
    var
        Home: Record "ALT Universal";
        RecRef: RecordRef;
    begin
        Lib.Cleanup();
        Home."Entry No." := 1;
        Home."Integer Field" := 11;
        Home.Insert();
        Lib.InsertCompany();

        RecRef.Open(Database::"ALT Universal");
        Assert.IsTrue(RecRef.ChangeCompany(Lib.CompanyNameUnderTest()), 'ChangeCompany on the reference');
        Assert.AreEqual(0, RecRef.Count(), 'the other company starts empty');

        RecRef.Init();
        RecRef.Field(Home.FieldNo("Entry No.")).Value := 1;
        RecRef.Field(Home.FieldNo("Integer Field")).Value := 77;
        RecRef.Insert();
        Assert.AreEqual(1, RecRef.Count(), 'the other company holds the one row inserted through the reference');
        RecRef.Close();

        Home.Get(1);
        Assert.AreEqual(11, Home."Integer Field", 'the session company keeps its own row');
        Assert.AreEqual(1, Home.Count(), 'and only that row');

        Lib.Cleanup();
    end;
}

codeunit 69972 "ALT ChangeCompany Lib"
{
    // The shared steps of 69970, 69971 and 69973 to 69975.
    var
        CompanyTok: Label 'ALT CHGCO ROWS', Locked = true;

    procedure CompanyNameUnderTest(): Text[30]
    begin
        exit(CompanyTok);
    end;

    procedure InsertCompany()
    var
        Company: Record Company;
    begin
        Company.Init();
        Company.Name := CompanyTok;
        Company.Insert();
        Commit();
    end;

    procedure DeleteCompany()
    var
        Company: Record Company;
    begin
        if Company.Get(CompanyTok) then
            Company.Delete();
        Commit();
    end;

    procedure Cleanup()
    var
        Home: Record "ALT Universal";
    begin
        Home.DeleteAll();
        DeleteCompany();
    end;

    procedure CleanupParents()
    var
        Parent: Record "ALT Parent";
        Child: Record "ALT Child";
    begin
        Parent.DeleteAll();
        Child.DeleteAll();
        DeleteCompany();
    end;
}
