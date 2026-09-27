// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-applicationarea-method
// Scope: in-scope
// Fixtures used: Assert (60021)
//
// CLAIM: the session's application areas are put back after every [Test] method, to the value
// they had when the test codeunit started. A test that calls ApplicationArea(...) sees its own
// value for the rest of that test; the next test in the same codeunit sees the codeunit's
// starting value again. What a test codeunit's OnRun trigger sets is still in place during the
// FIRST test method, and is gone from the second one on.
//
// Every assertion compares against a value read in this codeunit, never against a literal
// baseline, because the session a harness opens starts with different areas on different
// builds (an empty string, i.e. every area, on some; an experience tier without #Service on
// others).
//
// Platform source: Microsoft.Dynamics.Nav.Runtime.NavTestCodeunit.DoRunAsync (identical on
// BC 27.0 and 28.4) reads activeSession.ApplicationAreas once, before OnRun, and assigns it
// back after each test method and again when the codeunit ends.
//
// Written by agent stma-auto2-12, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#3575.

codeunit 67550 "Test AppArea Test Boundary"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        AreasAtFirstTest: Text;
        FirstTestRan: Boolean;

    [Test]
    procedure A_AreasSetInATest_AreVisibleForTheRestOfThatTest()
    begin
        AreasAtFirstTest := ApplicationArea();
        FirstTestRan := true;

        ApplicationArea('#Basic,#ALRBoundaryProbe');

        Assert.AreEqual('#Basic,#ALRBoundaryProbe', ApplicationArea(),
          'the areas a test sets must read back for the rest of that test');
    end;

    [Test]
    procedure B_NextTest_SeesTheAreasTheCodeunitStartedWith()
    begin
        Assert.IsTrue(FirstTestRan, 'the previous test must have run first, on this codeunit instance');
        Assert.AreEqual(AreasAtFirstTest, ApplicationArea(),
          'the areas the previous test set must be put back before the next test starts');
        Assert.AreEqual(0, StrPos(ApplicationArea(), '#ALRBoundaryProbe'),
          'the previous test''s area must not be visible to the next test');
    end;
}

codeunit 67551 "Test AppArea OnRun Boundary"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        AreasBeforeOnRun: Text;
        OnRunRan: Boolean;

    trigger OnRun()
    begin
        AreasBeforeOnRun := ApplicationArea();
        OnRunRan := true;
        ApplicationArea('#Basic,#ALROnRunProbe');
    end;

    [Test]
    procedure A_FirstTest_StillSeesTheAreasOnRunSet()
    begin
        Assert.IsTrue(OnRunRan, 'the codeunit''s OnRun trigger must have run before the first test');
        Assert.AreEqual('#Basic,#ALROnRunProbe', ApplicationArea(),
          'what OnRun set is in place during the first test method');
    end;

    [Test]
    procedure B_SecondTest_SeesTheAreasFromBeforeOnRun()
    begin
        Assert.AreEqual(AreasBeforeOnRun, ApplicationArea(),
          'after the first test method the areas return to what they were before OnRun');
        Assert.AreEqual(0, StrPos(ApplicationArea(), '#ALROnRunProbe'),
          'the area OnRun set must not be visible to the second test');
    end;
}
