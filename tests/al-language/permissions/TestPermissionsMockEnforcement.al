// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-permissions
// Scope: in-scope
// Fixtures used: ALTPermissionSet (60022), which grants tabledata "ALT Universal" = RIMD and
//   nothing on "ALT No Subscriber Table" (60590); both tables are plain fixtures.
// Note: TestPermissionsMockLifecycle (60291) pins that the platform ACCEPTS Start/Stop/Assign.
//   This suite pins that it ENFORCES what was assigned: once "Permissions Mock".Set narrows the
//   test's effective permission sets, a database write the sets do not grant is refused with the
//   platform's own permission error, and one they do grant goes through.
//
//   This is the shape Microsoft's plan-based E2E tests rely on (Library - E2E Plan Permissions
//   pushes a plan's permission sets through Library - Lower Permissions, which calls this mock,
//   then asserterrors a write and expects 'Sorry, the current permissions prevented the action').
//
//   No TestPermissions property on purpose: the Microsoft tests that use the mock declare none.
// BC versions: 24+

codeunit 60026 "Test Perm Mock Enforcement"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        PermissionErr: Label 'Sorry, the current permissions prevented the action', Locked = true;
        FixtureRoleTok: Label 'ALTPermissionSet', Locked = true;
        EntryNo: Integer;

    [Test]
    procedure MockedSet_WithoutTheGrant_RefusesInsert()
    // CLAIM: with the effective permission sets narrowed to one that grants nothing on the
    // table, Insert is refused by the platform permission check.
    var
        PermissionsMock: Codeunit "Permissions Mock";
        Row: Record "ALT No Subscriber Table";
        WasStarted: Boolean;
    begin
        Initialize();
        WasStarted := StartMock(PermissionsMock);

        PermissionsMock.Set(FixtureRoleTok);
        Row."Entry No." := EntryNo;
        Row.Value := 1;
        asserterror Row.Insert();
        Assert.ExpectedError(PermissionErr);

        RestoreMock(PermissionsMock, WasStarted);
    end;

    [Test]
    procedure MockedSet_WithTheGrant_AllowsInsert()
    // CLAIM: the same narrowed sets let through a write they DO grant, so the refusal above is
    // about the grant, not about the mock refusing every write.
    var
        PermissionsMock: Codeunit "Permissions Mock";
        Row: Record "ALT Universal";
        WasStarted: Boolean;
    begin
        Initialize();
        WasStarted := StartMock(PermissionsMock);

        PermissionsMock.Set(FixtureRoleTok);
        Row."Entry No." := EntryNo;
        Row."Integer Field" := 42;
        Row.Insert();

        Row.Reset();
        Assert.IsTrue(Row.Get(EntryNo), 'the granted insert must have written the row');
        Assert.AreEqual(42, Row."Integer Field", 'the granted insert must have written the value');

        RestoreMock(PermissionsMock, WasStarted);
        Row.Delete();
    end;

    [Test]
    procedure ClearedAssignments_TheSameInsertIsAllowed()
    // CLAIM: the refusal comes from the mocked sets, not from the table. With the assignments
    // cleared the effective sets are empty, the platform falls back to the user's own
    // permissions, and the insert refused in the first test succeeds.
    var
        PermissionsMock: Codeunit "Permissions Mock";
        Row: Record "ALT No Subscriber Table";
        WasStarted: Boolean;
    begin
        Initialize();
        WasStarted := StartMock(PermissionsMock);

        PermissionsMock.Set(FixtureRoleTok);
        PermissionsMock.ClearAssignments();
        Row."Entry No." := EntryNo;
        Row.Value := 2;
        Row.Insert();

        Row.Reset();
        Assert.IsTrue(Row.Get(EntryNo), 'with no mocked sets the insert must go through');
        Assert.AreEqual(2, Row.Value, 'with no mocked sets the insert must have written the value');

        RestoreMock(PermissionsMock, WasStarted);
        Row.Delete();
    end;

    local procedure Initialize()
    var
        NoSub: Record "ALT No Subscriber Table";
        Universal: Record "ALT Universal";
    begin
        EntryNo := 600261;
        if NoSub.Get(EntryNo) then
            NoSub.Delete();
        if Universal.Get(EntryNo) then
            Universal.Delete();
    end;

    local procedure StartMock(var PermissionsMock: Codeunit "Permissions Mock") WasStarted: Boolean
    begin
        WasStarted := PermissionsMock.IsStarted();
        if not WasStarted then
            PermissionsMock.Start();
    end;

    local procedure RestoreMock(var PermissionsMock: Codeunit "Permissions Mock"; WasStarted: Boolean)
    begin
        PermissionsMock.ClearAssignments();
        if not WasStarted then
            PermissionsMock.Stop();
    end;
}
