// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-profile-object
// Scope: in-scope
// Fixtures used: ALT AllProfile Row (profile, no numeric ID), ALT Profile SameApp
//                (profile, no numeric ID), ALT Profile RC SameApp (60904)
//
// CLAIM: the "All Profile" system table (2000000178) answers with one row per profile
// declared by every published app, carrying that profile's declared Caption,
// ProfileDescription, RoleCenter page and Enabled/Promoted flags plus the declaring app's
// id and name -- and it is writable for tenant-owned profiles only.
//
// The rows are asserted against THIS app's own profile fixtures, not against Base
// Application demo content, so the expected values are declared a few files away in
// ALTProfileAllProfileRow.Profile.al and cannot drift with a demo dataset.
codeunit 60907 "Test All Profile Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        RowFixtureProfileIdTok: Label 'ALT AllProfile Row', Locked = true;
        LegacyDescriptionProfileIdTok: Label 'ALT Profile SameApp', Locked = true;

    [Test]
    procedure AllProfile_ThisAppsDeclaredProfile_IsPresentWithItsDeclaredMetadata()
    // CLAIM: the profile this app declares is a row of "All Profile", and every column the
    // profile object declares comes back verbatim -- caption, description, the RoleCenter
    // resolved to its page id, Enabled and Promoted -- under the declaring app's id and name.
    var
        AllProfile: Record "All Profile";
        ThisModule: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);

        AllProfile.Get(AllProfile.Scope::Tenant, ThisModule.Id(), RowFixtureProfileIdTok);

        Assert.AreEqual(
            'ALT AllProfile Row Fixture', AllProfile.Caption,
            'Caption must be the profile''s declared Caption');
        Assert.AreEqual(
            'Row fixture for the All Profile system table.', AllProfile.Description,
            'Description must be the profile''s declared ProfileDescription');
        Assert.AreEqual(
            Page::"ALT Profile RC SameApp", AllProfile."Role Center ID",
            'Role Center ID must be the page id of the profile''s declared RoleCenter');
        Assert.IsTrue(AllProfile.Enabled, 'The profile declares Enabled = true');
        Assert.IsTrue(AllProfile.Promoted, 'The profile declares Promoted = true');
        Assert.AreEqual(ThisModule.Name(), AllProfile."App Name", 'App Name must be the declaring app''s name');
    end;

    [Test]
    procedure AllProfile_ProfileDeclaringLegacyDescription_HasEmptyDescription()
    // CLAIM: Description and ProfileDescription are two different AL properties on a profile
    // object, and only ProfileDescription reaches "All Profile".Description. ALT Profile
    // SameApp declares Description = 'Coverage fixture: ...' and its row's Description is
    // empty, while ALT AllProfile Row's ProfileDescription comes through (test above).
    var
        AllProfile: Record "All Profile";
        ThisModule: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);

        AllProfile.Get(AllProfile.Scope::Tenant, ThisModule.Id(), LegacyDescriptionProfileIdTok);

        Assert.AreEqual(
            'ALT Profile SameApp', AllProfile.Caption,
            'The row is the right one: its Caption is the profile''s declared Caption');
        Assert.AreEqual(
            '', AllProfile.Description,
            'A profile declaring only Description (not ProfileDescription) has an empty row Description');
    end;

    [Test]
    procedure AllProfile_ScopeSystem_IsEmpty()
    // CLAIM: System-scope profiles are deprecated -- every row of "All Profile" is Tenant
    // scope, including the ones an installed app declares.
    var
        AllProfile: Record "All Profile";
    begin
        AllProfile.SetRange(Scope, AllProfile.Scope::System);
        Assert.RecordIsEmpty(AllProfile);

        AllProfile.Reset();
        AllProfile.SetRange(Scope, AllProfile.Scope::Tenant);
        Assert.RecordIsNotEmpty(AllProfile);
    end;

    [Test]
    procedure AllProfile_GetOnUndeclaredProfileId_Fails()
    // CLAIM: Get() on a profile no published app declares does not silently succeed.
    var
        AllProfile: Record "All Profile";
        ThisModule: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);
        Assert.IsFalse(
            AllProfile.Get(AllProfile.Scope::Tenant, ThisModule.Id(), 'ALT NO SUCH PROFILE'),
            'Get() must return false for a profile no app declares');
    end;

    [Test]
    procedure AllProfile_DeleteAppOwnedProfile_RaisesCannotDeleteFromInstalledApplication()
    // CLAIM: a profile owned by an installed app cannot be deleted through "All Profile" --
    // the platform refuses with a specific message naming the profile.
    var
        AllProfile: Record "All Profile";
        ThisModule: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);
        AllProfile.Get(AllProfile.Scope::Tenant, ThisModule.Id(), RowFixtureProfileIdTok);

        asserterror AllProfile.Delete();

        // The message names the profile by its stored "Profile ID" -- read it off the record
        // rather than restating the literal, so this asserts the platform's message and not
        // this test's idea of how a Code field stores the name.
        Assert.ExpectedError(
            StrSubstNo('Cannot delete ''%1'' profile from an Installed Application.', AllProfile."Profile ID"));
    end;

    [Test]
    procedure AllProfile_TenantOwnedProfile_CanBeInsertedReadBackAndDeleted()
    // CLAIM: "All Profile" is writable for a tenant-owned profile (App ID = the empty GUID).
    // The inserted row reads back with the values it was given, and Delete() removes it.
    //
    // The profile is deliberately left DISABLED: an enabled tenant profile is a role-centre
    // candidate, and creating one makes the platform re-resolve the session's default role
    // centre through Azure AD -- which a test container has no directory for. The claim under
    // test is the write round-trip, not role-centre selection.
    var
        AllProfile: Record "All Profile";
        ReadBack: Record "All Profile";
        EmptyGuid: Guid;
        ProfileIdTok: Label 'ALT TENANT PROFILE', Locked = true;
    begin
        if AllProfile.Get(AllProfile.Scope::Tenant, EmptyGuid, ProfileIdTok) then
            AllProfile.Delete();

        Clear(AllProfile);
        AllProfile.Init();
        AllProfile.Scope := AllProfile.Scope::Tenant;
        AllProfile."Profile ID" := ProfileIdTok;
        AllProfile.Description := 'Tenant-owned coverage profile.';
        AllProfile."Role Center ID" := Page::"ALT Profile RC SameApp";
        AllProfile.Enabled := false;
        AllProfile.Insert();

        Assert.IsTrue(
            ReadBack.Get(ReadBack.Scope::Tenant, EmptyGuid, ProfileIdTok),
            'A tenant-owned profile must be readable back after Insert');
        Assert.AreEqual('Tenant-owned coverage profile.', ReadBack.Description, 'Description must round-trip');
        Assert.AreEqual(
            Page::"ALT Profile RC SameApp", ReadBack."Role Center ID", 'Role Center ID must round-trip');
        Assert.AreEqual(EmptyGuid, ReadBack."App ID", 'A tenant-owned profile carries the empty App ID');
        Assert.IsFalse(ReadBack.Enabled, 'Enabled must round-trip');

        ReadBack.Delete();

        Clear(ReadBack);
        Assert.IsFalse(
            ReadBack.Get(ReadBack.Scope::Tenant, EmptyGuid, ProfileIdTok),
            'The tenant-owned profile must be gone after Delete');
    end;
}
