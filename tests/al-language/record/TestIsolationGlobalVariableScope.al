// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: in-scope
// Fixtures used: shared Assert (60021)
//
// Companion to TestIsolationRollbackScope (60897), which pins the DATABASE half of
// TestIsolation = Codeunit. This one pins the other half: whether the codeunit's own
// AL global variables survive from one [Test] procedure to the next inside a single
// test codeunit.
//
// The two questions are independent. TestIsolation controls the database transaction
// scope; it says nothing about how long the test codeunit INSTANCE lives. A platform
// could roll the database back per codeunit while still constructing a fresh instance
// for every test, or share one instance across all of them. Only a real service tier
// can say which.
//
// It is worth pinning for the same reason as its companion: a consumer of this corpus
// changed behaviour on an unverified reading of how 130450 treats variable state, and
// no test anywhere held the answer. Assertions that only ever ran against that
// consumer cannot settle it — they report what the consumer already does.
//
// The two tests below are declaration-ordered and share a codeunit. Test01 raises a
// global Integer from its constructed default to 1. Test02 reads it and asserts the
// value survived. If the platform builds a fresh instance per test, Test02 fails with
// "Expected: 1  Actual: 0", which is the informative outcome either way.
codeunit 60898 "Test Isolation Global Var"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Counter: Integer;
        Marker: Text;

    [Test]
    procedure Test01_RaisesAGlobalFromItsDefault()
    begin
        Assert.AreEqual(0, Counter, 'A freshly constructed codeunit must start with the Integer default.');

        Counter := Counter + 1;
        Marker := 'global-variable-probe';

        Assert.AreEqual(1, Counter, 'The increment must be visible inside the test that made it.');
    end;

    [Test]
    procedure Test02_ReportsWhetherThatGlobalSurvived()
    begin
        Assert.AreEqual(
            1, Counter,
            'Under TestIsolation = Codeunit every [Test] in one codeunit runs on the SAME codeunit ' +
            'instance, so the global Integer raised by the previous test is still 1 here. A failure ' +
            'reading "Actual: 0" means the platform constructs a fresh instance per test instead.');

        Assert.AreEqual(
            'global-variable-probe', Marker,
            'A surviving instance must carry every global the previous test set, not only the Integer.');
    end;
}
