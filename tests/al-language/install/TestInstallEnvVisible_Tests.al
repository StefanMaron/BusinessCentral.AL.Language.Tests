// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
// Scope: in-scope
// Fixtures used: Install Env Observation (60588), Install Seeder (60618), Assert (60021)
//
// An app's Subtype=Install codeunit runs INSIDE an existing company, under a session whose
// permissions are already in place. Both facts are invisible from the install trigger's own
// return value, so the trigger records what it could see and these tests read it back.
//
// What is proved, per test:
//   * Company.Get(CompanyName()) answers TRUE from inside OnInstallAppPerCompany, and the row
//     it finds carries the company the trigger was running for - the company row is database
//     state that predates the app being installed.
//   * The same Get answers FALSE for a company that does not exist, so the assertion above is
//     about the key and not about Get answering true for anything.
//   * UserPermissions.IsSuper(UserSecurityId()) answers TRUE from inside the trigger - permission
//     assignments predate the install too.
//
// NOTE: deliberately no Initialize()/DeleteAll() - like the sibling install-trigger tests, these
// observe a row written before any test code ran, and clearing it would defeat the purpose.

codeunit 60589 "Test Install Env Visible"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        EnvCodeTok: Label 'ENV', Locked = true;

    trigger OnRun()
    begin
    end;

    [Test]
    procedure TestInstall_TriggerRecordedWhatItCouldSee()
    var
        Observation: Record "Install Env Observation";
    begin
        // PRECONDITION for the three tests below: without it they would all pass on a run whose
        // install trigger never fired.
        Assert.IsTrue(Observation.Get(EnvCodeTok),
          'OnInstallAppPerCompany must have written the ENV observation row');
        Assert.AreEqual(CompanyName(), Observation."Observed Company Name",
          'the install trigger ran for a different company than the one the tests run in');
    end;

    [Test]
    procedure TestInstall_CompanyRowExistsDuringInstall()
    var
        Observation: Record "Install Env Observation";
    begin
        Observation.Get(EnvCodeTok);
        Assert.IsTrue(Observation."Company Row Existed",
          'Company.Get(CompanyName()) must answer true from inside OnInstallAppPerCompany');
        Assert.AreEqual(CompanyName(), Observation."Company Row Name",
          'the Company row the install trigger found must be the company it was installing into');
    end;

    [Test]
    procedure TestInstall_CompanyGetConsultsTheKeyDuringInstall()
    var
        Observation: Record "Install Env Observation";
    begin
        // NEGATIVE CONTROL for the test above, recorded inside the same trigger.
        Observation.Get(EnvCodeTok);
        Assert.IsFalse(Observation."Other Company Row Existed",
          'Company.Get on a company that does not exist must answer false, even during install');
    end;

    [Test]
    procedure TestInstall_SessionUserIsSuperDuringInstall()
    var
        Observation: Record "Install Env Observation";
        UserPermissions: Codeunit "User Permissions";
    begin
        Observation.Get(EnvCodeTok);
        Assert.IsTrue(Observation."Session User Was Super",
          'UserPermissions.IsSuper(UserSecurityId()) must answer true from inside OnInstallAppPerCompany');
        // ...and the same answer still holds at test time, so the assertion above is about when
        // the grant existed and not about the session having changed since.
        Assert.IsTrue(UserPermissions.IsSuper(UserSecurityId()),
          'the session user must still be SUPER at test time');
    end;
}
