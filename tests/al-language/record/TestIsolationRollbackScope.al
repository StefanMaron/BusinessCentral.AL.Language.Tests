// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: in-scope
// Fixtures used: ALT Base (60007); shared Assert (60021)
//
// Pins WHEN the platform rolls the database back under TestIsolation = Codeunit, which
// is what the standard test runner "Test Runner - Isol. Codeunit" (130450) declares.
//
// The answer, measured on BC 27.5 and 28.3: the rollback happens after each test
// CODEUNIT, not between the tests inside one. A row written by one test is still
// visible to the next test in the same codeunit, even with no Commit. This matches
// Microsoft's TestIsolation documentation.
//
// It is worth pinning because the opposite reading is easy to arrive at and expensive
// to act on. A differential measurement against a BC container reported per-test
// rollback and a consumer changed its default isolation behaviour on that basis; the
// first run of this test against a real service tier contradicted it. A measurement
// taken through a harness that invokes tests one at a time cannot distinguish
// "the platform rolled back" from "the harness started a new transaction".
//
// The two tests below are declaration-ordered and share a codeunit. Test01 writes a
// uniquely-keyed row and deliberately does not Commit. Test02 resets nothing and asks
// only whether that specific row survived — keyed on its own primary key, so rows any
// other codeunit leaves in this table cannot change the answer.
codeunit 60897 "Test Isolation Rollback Scope"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Test01_WritesARowWithoutCommitting()
    var
        Base: Record "ALT Base";
    begin
        if Base.Get(60897001) then
            Base.Delete();

        Base.Init();
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
        Assert.IsTrue(
            Base.Get(60897001),
            'Under TestIsolation = Codeunit the platform rolls the database back after each test ' +
            'CODEUNIT, not between the tests inside one, so the uncommitted row written by the ' +
            'previous test in this same codeunit is still visible here.');

        Assert.AreEqual(
            'isolation-rollback-probe', Base."Name",
            'The surviving row must carry the value the previous test wrote, not a partially rolled-back one.');

        Base.Delete();
    end;
}
