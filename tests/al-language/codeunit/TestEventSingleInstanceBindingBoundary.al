// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-bindsubscription-method
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT SI Bind Publisher (67690), ALT SI Bind Survivor (67691),
//   ALT Plain Bind Contrast (67692)
// BC versions: 27.5+
//
// Does a manual binding on a SingleInstance subscriber survive a TEST-CODEUNIT boundary?
// (AL Runner issue #4799.)
//
// TestEventManualBindingCrossCodeunit (60244/60245) pins that an ordinary subscriber's
// binding does not reach the next test codeunit. TestManualBindByValue (67370) pins that a
// manual binding ends when the last reference to the instance goes away, and that a
// SingleInstance instance outlives the local that bound it. This pair asks the combination:
// the binding is session state (Session.EventBindings), removed by UnbindSubscription or by
// the subscriber instance being disposed; a SingleInstance instance is held by the company
// scope, which a test-codeunit boundary does not dispose (see TestCodeunitSICLeak, 60600).
//
// 67693 binds both subscribers and leaves them bound; 67694 raises the event. The plain
// subscriber, held in 67693's global, is the contrast: it must be gone, so a runtime that
// simply kept every binding cannot pass.
//
// Run order: 67693 before 67694, the ascending codeunit-id order 60244/60245 rely on.
// Runner: Test Runner - Isol. Codeunit (130450), TestIsolation = Codeunit.

codeunit 67693 "Test SI Bind Boundary Setup"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        PlainSub: Codeunit "ALT Plain Bind Contrast";

    [Test]
    procedure BindsASingleInstanceAndAPlainSubscriberAndLeavesBothBound()
    var
        Publisher: Codeunit "ALT SI Bind Publisher";
        SingleInstanceSub: Codeunit "ALT SI Bind Survivor";
        SingleInstanceHit: Boolean;
        PlainHit: Boolean;
    begin
        Assert.IsTrue(BindSubscription(SingleInstanceSub), 'BindSubscription on the SingleInstance subscriber must return true');
        Assert.IsTrue(BindSubscription(PlainSub), 'BindSubscription on the plain subscriber must return true');

        Publisher.Raise(SingleInstanceHit, PlainHit);

        Assert.IsTrue(SingleInstanceHit, 'The bound SingleInstance subscriber must fire in the codeunit that bound it');
        Assert.IsTrue(PlainHit, 'The bound plain subscriber must fire in the codeunit that bound it');
        // Deliberately no UnbindSubscription: 67694 reads what crossed the boundary.
    end;
}

codeunit 67694 "Test SI Bind Boundary Check"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure SingleInstanceBindingCrossesTheCodeunitBoundary_PlainOneDoesNot()
    var
        Publisher: Codeunit "ALT SI Bind Publisher";
        SingleInstanceHit: Boolean;
        PlainHit: Boolean;
    begin
        Publisher.Raise(SingleInstanceHit, PlainHit);

        Assert.IsFalse(PlainHit, 'An ordinary subscriber bound by the previous test codeunit must not fire here');
        Assert.IsTrue(SingleInstanceHit, 'A SingleInstance subscriber bound by the previous test codeunit must still fire here: its instance is not released at the boundary, so neither is its binding');
    end;
}
