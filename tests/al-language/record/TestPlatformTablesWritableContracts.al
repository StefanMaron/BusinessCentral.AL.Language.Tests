// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained codeunit 69070
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins how some platform and system tables take writes from AL:
//  - a TEMPORARY record of "License Information", "Feature Key" and "Object Options" is an ordinary temporary table: Insert, Get, Modify,
//    Delete and Count work, and the persistent table is not touched ("Feature Key" keeps its row count);
//  - "Object Options" takes Insert and DeleteAll; "Privacy Notice" and "Chart" take Insert and Delete; "Tenant License State" takes Insert
//    but raises "It is not possible to delete any record in the Tenant License State table." (code DB:Ok) on DeleteAll.
//    (The tests only read the counts relative to the start, and roll back at the end.)
// BC versions: 27.5

codeunit 69070 "Probe Platform Tables Writable"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TemporaryPlatformTables_AreOrdinaryTemporaryTables()
    var
        TempLicense: Record "License Information" temporary;
        TempFeature: Record "Feature Key" temporary;
        TempOptions: Record "Object Options" temporary;
        RealFeature: Record "Feature Key";
        RealCount: Integer;
    begin
        RealCount := RealFeature.Count();

        TempLicense.Init();
        TempLicense.Text := 'x';
        TempLicense.Insert();
        Assert.AreEqual(1, TempLicense.Count(), 'License Information count');
        Assert.IsTrue(TempLicense.Get(0), 'License Information Get');

        TempFeature.ID := 'TEMPKEY';
        TempFeature.Insert();
        Assert.AreEqual(1, TempFeature.Count(), 'Feature Key count');
        Assert.IsTrue(TempFeature.Get('TEMPKEY'), 'Feature Key Get');
        TempFeature.Description := 'd';
        TempFeature.Modify();
        TempFeature.Delete();
        Assert.AreEqual(0, TempFeature.Count(), 'Feature Key after Delete');
        Assert.AreEqual(RealCount, RealFeature.Count(), 'the persistent Feature Key is untouched');

        TempOptions."Object Type" := TempOptions."Object Type"::Report;
        TempOptions."Object ID" := 1;
        TempOptions."Parameter Name" := 'p';
        TempOptions.Insert();
        Assert.AreEqual(1, TempOptions.Count(), 'Object Options count');
    end;

    [Test]
    procedure PersistentPlatformTables_TakeInsertAndDelete()
    var
        ObjectOptions: Record "Object Options";
        PrivacyNotice: Record "Privacy Notice";
        ChartRec: Record Chart;
        Before: Integer;
    begin
        Before := ObjectOptions.Count();
        ObjectOptions."Object Type" := ObjectOptions."Object Type"::Report;
        ObjectOptions."Object ID" := 99;
        ObjectOptions."Parameter Name" := 'p';
        ObjectOptions.Insert();
        Assert.AreEqual(Before + 1, ObjectOptions.Count(), 'Object Options insert');
        ObjectOptions.SetRange("Object ID", 99);
        ObjectOptions.DeleteAll();
        ObjectOptions.Reset();
        Assert.AreEqual(Before, ObjectOptions.Count(), 'Object Options delete');

        Before := PrivacyNotice.Count();
        PrivacyNotice.Init();
        PrivacyNotice.ID := 'PROBEPN';
        PrivacyNotice.Insert();
        Assert.AreEqual(Before + 1, PrivacyNotice.Count(), 'Privacy Notice insert');
        PrivacyNotice.Delete();
        Assert.AreEqual(Before, PrivacyNotice.Count(), 'Privacy Notice delete');

        Before := ChartRec.Count();
        ChartRec.Init();
        ChartRec.ID := 'PROBECH';
        ChartRec.Insert();
        Assert.AreEqual(Before + 1, ChartRec.Count(), 'Chart insert');
        ChartRec.Delete();
        Assert.AreEqual(Before, ChartRec.Count(), 'Chart delete');
    end;

    [Test]
    procedure TenantLicenseState_TakesInsert_ButNoDelete()
    var
        LicenseState: Record "Tenant License State";
        Before: Integer;
    begin
        Before := LicenseState.Count();
        LicenseState.Init();
        LicenseState."Start Date" := CurrentDateTime();
        LicenseState.State := LicenseState.State::Trial;
        LicenseState.Insert();
        Assert.AreEqual(Before + 1, LicenseState.Count(), 'insert');

        asserterror LicenseState.DeleteAll();
        Assert.AreEqual('It is not possible to delete any record in the Tenant License State table.', GetLastErrorText(), 'text');
        Assert.AreEqual('DB:Ok', GetLastErrorCode(), 'code');
    end;
}
