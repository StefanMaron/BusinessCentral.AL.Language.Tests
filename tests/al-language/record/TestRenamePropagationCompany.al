// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-rename-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Company Ref (67958, declared here); writes the Company rows
//   'ALT RENCASC CO' / 'ALT RENCASC CO2'
// BC versions: 27.5+
//
// CLAIM UNDER TEST: renaming a Company record re-keys a field that holds a TableRelation to the
// Company table, in a table that holds data per company. Company is not per company; its rename
// walks every company (NavRecord.UpdateReferencingTableOnRenameAsync reads the Company rows and
// runs the update once per company), and the update opens the referencing table in each of them.
// A row whose field names some OTHER company is the control: the rename must not touch it.
//
// The company is created in a codeunit of its own, as in TestPermissionSetupVersionCompany.al:
// creating a company creates all of its tables, which takes minutes on the Linux tier.

table 67958 "ALT Company Ref"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Company Ref"; Text[30])
        {
            DataClassification = SystemMetadata;
            TableRelation = Company.Name;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}

codeunit 67959 "Test Company Rename Cascade"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        CompanyTok: Label 'ALT RENCASC CO', Locked = true;
        RenamedCompanyTok: Label 'ALT RENCASC CO2', Locked = true;
        OtherCompanyTok: Label 'ALT RENCASC OTHER', Locked = true;

    [Test]
    procedure Company_Rename_ReKeysTheReferencingRowAndLeavesTheOthers()
    // CLAIM: Company.Rename re-keys a TableRelation = Company.Name field in a per-company table,
    // and leaves a row naming a different company as it was.
    var
        Company: Record Company;
        Referencing: Record "ALT Company Ref";
        Other: Record "ALT Company Ref";
    begin
        Initialize();
        Company.Init();
        Company.Name := CompanyTok;
        Company.Insert();
        Referencing."Entry No." := 1;
        Referencing."Company Ref" := CompanyTok;
        Referencing.Insert();
        Other."Entry No." := 2;
        Other."Company Ref" := OtherCompanyTok;
        Other.Insert();
        Commit();

        Company.Get(CompanyTok);
        Company.Rename(RenamedCompanyTok);

        Assert.IsFalse(Company.Get(CompanyTok), 'the old company name is gone');
        Assert.IsTrue(Company.Get(RenamedCompanyTok), 'the renamed company exists');
        Referencing.Get(1);
        Assert.AreEqual(RenamedCompanyTok, Referencing."Company Ref", 'the field that named the company follows its rename');
        Other.Get(2);
        Assert.AreEqual(OtherCompanyTok, Other."Company Ref", 'a field naming another company is not touched');

        Cleanup();
    end;

    local procedure Initialize()
    begin
        Cleanup();
    end;

    local procedure Cleanup()
    var
        Company: Record Company;
        Referencing: Record "ALT Company Ref";
    begin
        Referencing.DeleteAll();
        if Company.Get(CompanyTok) then
            Company.Delete();
        if Company.Get(RenamedCompanyTok) then
            Company.Delete();
        Commit();
    end;
}
