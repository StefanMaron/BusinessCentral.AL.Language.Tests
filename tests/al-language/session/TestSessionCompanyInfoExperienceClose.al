// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-app-area
// Fixtures used: none — this drives Base Application page 1 "Company Information" and
// System Application table 9178 "Experience Tier Setup" in the company the tests run in.
//
// Page 1 reads the company's experience tier ONCE, in OnOpenPage, into a page global. Its
// OnClosePage hands that captured value back to codeunit 9179's SaveExperienceTierCurrentCompany.
// So a tier that is changed underneath an open page makes the close carry a value the setup no
// longer agrees with, and the save refuses it with a plain error rather than writing it.
//
// Both directions are asserted: a page opened and closed with the tier left alone closes
// normally, and a page whose tier was flipped underneath it refuses the close by name.
//
// The open half is a claim in its own right and is asserted separately. Page 1's OnOpenPage
// runs codeunit 1392 "Monitor Sensitive Field", which asks the platform for the current user's
// effective permissions on an object — so "the page opened at all" pins that the permission
// question is answerable during a page open, not merely that a TestPage variable exists.
//
// That same permission question is asserted for its VALUE too, through codeunit 9852's own
// public entry point. A test session runs as SUPER, so its effective permission on a table is
// Yes in all five of Read/Insert/Modify/Delete/Execute — and asserting the five values, rather
// than only that the call returns, is what distinguishes "the platform answered" from "the
// platform answered correctly".

codeunit 60702 "Test Session Comp Info Close"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        UnsupportedExperienceErr: Label 'The selected experience is not supported.';

    local procedure SetTier(Basic: Boolean; Essential: Boolean; Custom: Boolean)
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
    begin
        if ExperienceTierSetup.Get(CompanyName()) then
            ExperienceTierSetup.Delete();
        ExperienceTierSetup.Init();
        ExperienceTierSetup."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(ExperienceTierSetup."Company Name"));
        ExperienceTierSetup.Basic := Basic;
        ExperienceTierSetup.Essential := Essential;
        ExperienceTierSetup.Custom := Custom;
        ExperienceTierSetup.Insert();
    end;

    [Test]
    procedure EffectivePermissions_SuperSession_HoldsAllFiveOnATable()
    var
        Perm: Record Permission;
        EffectivePermissionsMgt: Codeunit "Effective Permissions Mgt.";
        Ordinal: Integer;
    begin
        // The platform call page 1's OnOpenPage reaches, asked directly so its ANSWER is the
        // assertion rather than a side effect. "Table Data" on table 79 is the same object
        // shape codeunit 1392 asks about.
        EffectivePermissionsMgt.PopulatePermissionRecordWithEffectivePermissionsForObject(
          Perm, UserSecurityId(), CopyStr(CompanyName(), 1, 50),
          Perm."Object Type"::"Table Data", DATABASE::"Company Information");

        Ordinal := Perm."Read Permission";
        Assert.AreEqual(
          1, Ordinal,
          'A SUPER test session has direct Read on Company Information (Permission option Yes = 1).');
        Ordinal := Perm."Insert Permission";
        Assert.AreEqual(
          1, Ordinal,
          'A SUPER test session has direct Insert on Company Information (Permission option Yes = 1).');
        Ordinal := Perm."Modify Permission";
        Assert.AreEqual(
          1, Ordinal,
          'A SUPER test session has direct Modify on Company Information (Permission option Yes = 1).');
        Ordinal := Perm."Delete Permission";
        Assert.AreEqual(
          1, Ordinal,
          'A SUPER test session has direct Delete on Company Information (Permission option Yes = 1).');
        Ordinal := Perm."Execute Permission";
        Assert.AreEqual(
          1, Ordinal,
          'A SUPER test session has direct Execute on Company Information (Permission option Yes = 1).');
    end;

    [Test]
    procedure CompanyInformation_OpenEdit_OpensAndExposesItsSource()
    var
        CompanyInformation: Record "Company Information";
        CompanyInformationPage: TestPage "Company Information";
    begin
        // A value, not a "did not throw": the page must be showing the company's own row.
        if not CompanyInformation.Get() then begin
            CompanyInformation.Init();
            CompanyInformation.Insert();
        end;
        CompanyInformation.Name := 'Experience Close Fixture';
        CompanyInformation.Modify();

        CompanyInformationPage.OpenEdit();

        Assert.AreEqual(
          'Experience Close Fixture', CompanyInformationPage.Name.Value(),
          'Page 1 shows the Company Information row it is sourced on.');

        CompanyInformationPage.Close();
    end;

    [Test]
    procedure CompanyInformation_Close_TierUnchanged_ClosesWithoutError()
    var
        CompanyInformationPage: TestPage "Company Information";
        AppAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        TierAfter: Text;
    begin
        // The positive direction. Nothing is changed underneath the page, so the value its
        // OnClosePage carries still matches the setup and the save is accepted.
        SetTier(false, true, false);

        CompanyInformationPage.OpenEdit();
        CompanyInformationPage.Close();

        AppAreaMgmtFacade.GetExperienceTierCurrentCompany(TierAfter);
        Assert.AreEqual(
          'Essential', TierAfter,
          'Closing the page without touching the tier leaves the Essential tier selected.');
    end;

    [Test]
    procedure CompanyInformation_Close_TierChangedUnderneath_RaisesUnsupportedExperience()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        CompanyInformationPage: TestPage "Company Information";
    begin
        // Custom is the tier the page captures in OnOpenPage.
        SetTier(false, false, true);

        CompanyInformationPage.OpenEdit();

        // Flipped underneath the open page: the setup now says Basic, but the page is still
        // holding Custom and will hand Custom back on close.
        ExperienceTierSetup.Get(CompanyName());
        ExperienceTierSetup.Basic := true;
        ExperienceTierSetup.Custom := false;
        ExperienceTierSetup.Modify();

        asserterror CompanyInformationPage.Close();

        Assert.ExpectedError(UnsupportedExperienceErr);
    end;
}
