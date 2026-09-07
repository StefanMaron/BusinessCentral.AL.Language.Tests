// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-permissions
// Scope: in-scope
// Fixtures used: none — codeunit "Permissions Mock" (131006) ships in Microsoft's
//   "Permissions Mock" test-toolkit app, which the BC test tier publishes on first boot.
//
// Note: "Permissions Mock" is the platform-supported way a test lowers its own effective
//   permissions. Start()/Stop() are not bookkeeping inside the AL codeunit — Start()
//   constructs the .NET type Microsoft.Dynamics.Nav.Runtime.PermissionTestHelper, whose
//   constructor reaches into the platform's own test-execution state
//   (NavTestExecution.SetEffectiveTestPermissions), and Stop() disposes it, which clears
//   that state again. So IsStarted() flipping is an observable statement about the
//   platform accepting those two calls, not about a Boolean field.
//
//   The mock is SingleInstance, and the BC test framework already has it started when a
//   test method begins — measured on BC 28.4.53241.0, IsStarted() reads true on entry to
//   the first test that asks. These tests therefore never assert the entry state; they
//   assert the transition in both directions and restore whatever they found.
// BC versions: 24+

codeunit 60291 "Test Permissions Mock Lifecyc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure StartThenStopFlipsIsStartedInBothDirections()
    var
        PermissionsMock: Codeunit "Permissions Mock";
        WasStarted: Boolean;
    begin
        // [GIVEN] Whatever state the test framework left the SingleInstance mock in.
        WasStarted := PermissionsMock.IsStarted();

        // [WHEN] The mock is started.
        PermissionsMock.Start();

        // [THEN] It reports itself started. Start() constructs PermissionTestHelper, so a
        // platform that cannot hand that type its test-execution state fails here rather
        // than answering a default.
        Assert.IsTrue(PermissionsMock.IsStarted(), 'IsStarted must be true after Start.');

        // [WHEN] It is stopped again.
        PermissionsMock.Stop();

        // [THEN] It reports itself stopped. This is the direction that makes the assertion
        // above mean something: a mock that answered true unconditionally would fail here.
        Assert.IsFalse(PermissionsMock.IsStarted(), 'IsStarted must be false after Stop.');

        if WasStarted then
            PermissionsMock.Start();
    end;

    [Test]
    procedure ClearAssignmentsIsAcceptedWhileStarted()
    var
        PermissionsMock: Codeunit "Permissions Mock";
        WasStarted: Boolean;
    begin
        // [GIVEN] A started mock.
        WasStarted := PermissionsMock.IsStarted();
        PermissionsMock.Start();

        // [WHEN] Every already-assigned permission set is cleared.
        // [THEN] The platform accepts it. ClearAssignments() forwards to
        // PermissionTestHelper.Clear(), which writes the effective-permission set back to
        // the platform a second time — a distinct entry into the same platform path that
        // Start() took, and the one a test takes between two lowered-permission phases.
        PermissionsMock.ClearAssignments();

        // [THEN] And clearing does not stop the mock.
        Assert.IsTrue(PermissionsMock.IsStarted(), 'ClearAssignments must not stop the mock.');

        PermissionsMock.Stop();
        Assert.IsFalse(PermissionsMock.IsStarted(), 'IsStarted must be false after Stop.');

        if WasStarted then
            PermissionsMock.Start();
    end;

    [Test]
    procedure AssignIsIgnoredWhileTheMockIsStopped()
    var
        PermissionsMock: Codeunit "Permissions Mock";
        WasStarted: Boolean;
    begin
        // The negative direction for the two tests above, and it is what stops them
        // passing for the wrong reason: the mock's entry points are guarded on Started,
        // so a stopped mock must ignore an assignment instead of reaching the platform.
        // 'ALT NO SUCH SET' is not a permission set any published app declares — a mock
        // that ignored its own Started flag would look it up and fail.
        WasStarted := PermissionsMock.IsStarted();
        PermissionsMock.Stop();
        Assert.IsFalse(PermissionsMock.IsStarted(), 'The mock must be stopped for this test.');

        PermissionsMock.Assign('ALT NO SUCH SET');

        // [THEN] Still stopped, and nothing raised.
        Assert.IsFalse(PermissionsMock.IsStarted(), 'Assign must not start a stopped mock.');

        if WasStarted then
            PermissionsMock.Start();
    end;
}
