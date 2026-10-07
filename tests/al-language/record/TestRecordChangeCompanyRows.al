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
    begin
        Lib.Cleanup();
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

codeunit 69972 "ALT ChangeCompany Lib"
{
    // The shared steps of 69970 and 69971.
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
}
