// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: Test SIC Single (60597), Assert (60021)
//
// Isolation lock: proves a SingleInstance codeunit's instance state is reset at
// the per-test boundary, so state set by one test codeunit does NOT leak into a
// fresh test codeunit. This lives in a SEPARATE test codeunit from
// "Test Codeunit SingleInstance" on purpose: per-test state must be reset before
// EVERY test codeunit, regardless of run order — a naive cache-forever
// implementation would fail this test whenever the other codeunit runs first.

codeunit 60600 "Test Codeunit SIC Leak"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    trigger OnRun()
    begin
    end;

    local procedure Initialize()
    begin
    end;

    [Test]
    procedure TestCodeunit_SingleInstance_DoesNotLeakAcrossTests()
    var
        S: Codeunit "Test SIC Single";
    begin
        Initialize();

        Assert.AreEqual(0, S.GetValue(),
            'SingleInstance codeunit state must not leak from a previous test codeunit — expected the untouched default');
    end;
}
