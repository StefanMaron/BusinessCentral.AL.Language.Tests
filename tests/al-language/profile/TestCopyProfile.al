// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/ui-customize-profiles
// Scope: in-scope
// Fixtures used: ALT Profile Copy Source (profile, no numeric ID), ALT Profile RC SameApp (60904)
//
// CLAIM: "Conf./Personalization Mgt".CopyProfile copies a profile into a new TENANT-OWNED
// "All Profile" row (App ID = the empty GUID) under the new Profile ID and Caption, carrying
// the source's Role Center and Enabled flag -- and it refuses, with Base Application's own
// "could not be copied" error, when the target Profile ID already exists.
//
// Base Application does the copy through the platform's designer call
// NavDesignerALFunctions.CopyProfile, so this is the platform's copy being measured, not AL.
codeunit 60908 "Test Copy Profile"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        SourceProfileIdTok: Label 'ALT Profile Copy Source', Locked = true;
        CopiedProfileIdTok: Label 'ALT COPIED PROFILE', Locked = true;
        CopiedCaptionTok: Label 'ALT Copied Profile Caption', Locked = true;
        CouldNotCopyErr: Label 'The profile could not be copied.', Locked = true;

    [Test]
    procedure CopyProfile_NewId_CreatesTenantOwnedProfileWithNewCaptionAndSourceRoleCenter()
    // CLAIM: the copy is a new row readable under (Tenant, empty App ID, new Profile ID); the
    // VAR record CopyProfile hands back is that row; and it carries the new caption plus the
    // source's Role Center ID and Enabled flag. One row is added, not zero and not two.
    var
        Source: Record "All Profile";
        Copied: Record "All Profile";
        ReadBack: Record "All Profile";
        Counter: Record "All Profile";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        ThisModule: ModuleInfo;
        EmptyGuid: Guid;
        CountBefore: Integer;
    begin
        DeleteCopyIfPresent();
        NavApp.GetCurrentModuleInfo(ThisModule);
        Source.Get(Source.Scope::Tenant, ThisModule.Id(), SourceProfileIdTok);
        CountBefore := Counter.Count();

        ConfPersonalizationMgt.CopyProfile(Source, CopiedProfileIdTok, CopiedCaptionTok, Copied);

        Assert.AreEqual(CountBefore + 1, Counter.Count(), 'CopyProfile must add exactly one All Profile row');
        Assert.IsTrue(
            ReadBack.Get(ReadBack.Scope::Tenant, EmptyGuid, CopiedProfileIdTok),
            'The copy must be readable as a tenant-owned profile under the new Profile ID');
        Assert.AreEqual(CopiedProfileIdTok, Copied."Profile ID", 'The VAR record must be the copied row');
        Assert.AreEqual(EmptyGuid, ReadBack."App ID", 'A copied profile is tenant-owned: its App ID is the empty GUID');
        Assert.AreEqual(CopiedCaptionTok, ReadBack.Caption, 'The copy must carry the caption passed to CopyProfile');
        Assert.AreEqual(
            Page::"ALT Profile RC SameApp", ReadBack."Role Center ID",
            'The copy must carry the source profile''s Role Center ID');
        Assert.AreEqual(Source.Enabled, ReadBack.Enabled, 'The copy must carry the source profile''s Enabled flag');

        ReadBack.Delete();
    end;

    [Test]
    procedure CopyProfile_TargetIdAlreadyExists_RaisesCouldNotCopy()
    // CLAIM: copying onto a Profile ID that already names a tenant profile does not overwrite
    // it and does not add a second row; Base Application raises its own error instead.
    var
        Source: Record "All Profile";
        Copied: Record "All Profile";
        SecondCopy: Record "All Profile";
        Counter: Record "All Profile";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        ThisModule: ModuleInfo;
        EmptyGuid: Guid;
        CountAfterFirstCopy: Integer;
    begin
        DeleteCopyIfPresent();
        NavApp.GetCurrentModuleInfo(ThisModule);
        Source.Get(Source.Scope::Tenant, ThisModule.Id(), SourceProfileIdTok);
        ConfPersonalizationMgt.CopyProfile(Source, CopiedProfileIdTok, CopiedCaptionTok, Copied);
        CountAfterFirstCopy := Counter.Count();

        asserterror ConfPersonalizationMgt.CopyProfile(Source, CopiedProfileIdTok, 'Second caption', SecondCopy);
        Assert.ExpectedError(CouldNotCopyErr);

        Assert.AreEqual(CountAfterFirstCopy, Counter.Count(), 'A refused copy must not add a row');
        Copied.Get(Copied.Scope::Tenant, EmptyGuid, CopiedProfileIdTok);
        Assert.AreEqual(CopiedCaptionTok, Copied.Caption, 'A refused copy must not overwrite the existing profile');

        Copied.Delete();
    end;

    local procedure DeleteCopyIfPresent()
    var
        AllProfile: Record "All Profile";
        EmptyGuid: Guid;
    begin
        if AllProfile.Get(AllProfile.Scope::Tenant, EmptyGuid, CopiedProfileIdTok) then
            AllProfile.Delete();
    end;
}
