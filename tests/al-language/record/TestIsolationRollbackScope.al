// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: in-scope
// Fixtures used: ALT Base (60007); shared Assert (60021)
//
// Settles when the platform rolls the database back under TestIsolation = Codeunit,
// which is what the standard test runner "Test Runner - Isol. Codeunit" (130450)
// declares. Two readings exist and they disagree:
//
//   - Microsoft's TestIsolation documentation says changes are rolled back after each
//     test CODEUNIT. Under that reading the row Test01 writes is still there in Test02.
//   - A differential measurement against a BC 28 container reported the database being
//     rolled back between individual tests inside one codeunit. Under that reading the
//     row is gone.
//
// The two tests below are declaration-ordered and share a codeunit. Test01 writes a
// uniquely-keyed row and deliberately does not Commit. Test02 does not reset anything
// and asks only whether that specific row survived — keyed on its own primary key, so
// rows any other codeunit left in this table cannot change the answer.
//
// Test02 asserts the row is GONE (the per-test reading). If the platform actually rolls
// back per codeunit, this test fails with "Expected: <False>. Actual: <True>" and that
// failure is the answer — invert the assertion and this comment.
codeunit 60897 "Test Isolation Rollback Scope"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        ProbeEntryNoLbl: Label '60897001', Locked = true;

    [Test]
    procedure Test01_WritesARowWithoutCommitting()
    var
        Base: Record "ALT Base";
    begin
        Base."Entry No." := 60897001;
        Base."Name" := 'isolation-rollback-probe';
        Base.Insert();

        Assert.IsTrue(Base.Get(60897001), 'The probe row must exist inside the test that wrote it.');
    end;

    [Test]
    procedure Test02_ReportsWhetherThatRowSurvived()
    var
        Base: Record "ALT Base";
    begin
        Assert.IsFalse(
            Base.Get(60897001),
            'Under TestIsolation = Codeunit the platform rolls the database back before every test, ' +
            'so the row written by the previous test in this same codeunit must not be visible here.');
    end;
}
