// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-permissions
// Scope: in-scope, but ONLY for a Target = OnPrem app - the call is a DotNet interop call
// Fixtures used: Assert (60021), from the AL Language Coverage Tests app
// BC versions: 27.0+
//
// WHY THIS FILE IS IN THE ONPREM APP
//   NavUserAccountHelper is a .NET type in Microsoft.Dynamics.Nav.NavUserAccount, reachable from
//   AL only through a DotNet variable, and a Target = Cloud app cannot declare one (AL0296).
//   System Application declares the alias this file uses; Base Application's page 9033
//   "Invite External Accountant" is the one Microsoft caller.
//
// WHAT IS BEING ASKED
//   NavUserAccountHelper.IsUserSuperInAllCompanies() reads the session's permission cache,
//   NavUserPermissions.IsSuperForAllCompanies. That getter answers false while effective test
//   permissions are in use, true for a NAV admin user, and otherwise whether the user holds an
//   Access Control row assigning SUPER (System scope, no app) with a BLANK company name - the
//   all-companies assignment. A test tier's user is SUPER, so on a test with test permissions
//   disabled the answer is a non-default true, and it must agree with the Access Control table.

codeunit 61203 "Test User Super All Companies"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure IsUserSuperInAllCompanies_TrueForTheTestTierUser()
    var
        NavUserAccountHelper: DotNet NavUserAccountHelper;
    begin
        // [WHEN] The session's own user is asked about, with test permissions disabled.
        // [THEN] It is SUPER in all companies. The default a broken answer would give is false.
        Assert.IsTrue(NavUserAccountHelper.IsUserSuperInAllCompanies(),
            'The test tier user must be SUPER in all companies.');
    end;

    [Test]
    procedure IsUserSuperInAllCompanies_AgreesWithTheAllCompaniesSuperRow()
    var
        AccessControl: Record "Access Control";
        NavUserAccountHelper: DotNet NavUserAccountHelper;
    begin
        // [GIVEN] The session user's all-companies SUPER assignment, read from Access Control.
        AccessControl.SetRange("User Security ID", UserSecurityId());
        AccessControl.SetRange("Role ID", 'SUPER');
        AccessControl.SetRange("Company Name", '');
        AccessControl.SetRange(Scope, AccessControl.Scope::System);

        // [THEN] The helper and the table are two views of one fact.
        Assert.AreEqual(not AccessControl.IsEmpty(), NavUserAccountHelper.IsUserSuperInAllCompanies(),
            'IsUserSuperInAllCompanies must agree with the all-companies SUPER Access Control row.');
    end;
    [Test]
    procedure IsUserSuperInAllCompanies_FalseWhileEffectiveTestPermissionsAreInUse()
    var
        PermissionsMock: Codeunit "Permissions Mock";
        NavUserAccountHelper: DotNet NavUserAccountHelper;
        WasStarted: Boolean;
        SuperWhileLowered: Boolean;
        SuperAfterStop: Boolean;
    begin
        // [GIVEN] The same SUPER user, with an effective permission set assigned through the
        // platform's own test hook.
        WasStarted := PermissionsMock.IsStarted();
        PermissionsMock.Start();
        PermissionsMock.SetExactPermissionSet('ALTPERMISSIONSET');

        // [WHEN] The helper is asked while those permissions are in effect, and again after.
        SuperWhileLowered := NavUserAccountHelper.IsUserSuperInAllCompanies();
        PermissionsMock.Stop();
        SuperAfterStop := NavUserAccountHelper.IsUserSuperInAllCompanies();
        if WasStarted then
            PermissionsMock.Start();

        // [THEN] Lowered test permissions win over the SUPER assignment, and stopping the mock
        // gives the assignment back. The second assertion is what stops the first passing for a
        // helper that answers false unconditionally.
        Assert.IsFalse(SuperWhileLowered, 'Effective test permissions must make the user not SUPER in all companies.');
        Assert.IsTrue(SuperAfterStop, 'Stopping the mock must restore the all-companies SUPER answer.');
    end;
}
