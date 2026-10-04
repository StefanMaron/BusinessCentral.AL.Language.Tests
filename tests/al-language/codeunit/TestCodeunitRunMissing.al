// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
// Scope: in-scope
// Fixtures used: ALTFixtureCleanup (60019), self-contained erroring codeunit (Run Guard Erroring)
//
// CLAIM OF THIS CODEUNIT: Codeunit.Run on a codeunit id that no installed app declares.
// (PROBE: what BC does, statement form and guarded form, is measured by the CI run.)

codeunit 69901 "Test Codeunit Run Missing"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure CodeunitRun_MissingId_BareAsserterror_IsCaught()
    begin
        Initialize();

        asserterror Codeunit.Run(99990);

        Assert.AreNotEqual('', GetLastErrorText(), 'asserterror must have caught an error from Codeunit.Run of a missing codeunit');
    end;

    [Test]
    procedure CodeunitRun_MissingId_ErrorText()
    begin
        Initialize();

        asserterror Codeunit.Run(99990);

        Assert.AreEqual('PROBE', GetLastErrorText(), 'PROBE: the error text BC raises');
    end;

    [Test]
    procedure CodeunitRun_MissingId_Guarded_Probe()
    var
        Ok: Boolean;
    begin
        Initialize();

        Ok := Codeunit.Run(99990);

        Assert.AreEqual('PROBE', Format(Ok) + '|' + GetLastErrorText(), 'PROBE: guarded run of a missing codeunit');
    end;

    [Test]
    procedure CodeunitRun_ExistingCodeunit_StillRuns()
    var
        Ok: Boolean;
    begin
        Initialize();

        Ok := Codeunit.Run(Codeunit::"Run Guard Erroring");

        Assert.IsFalse(Ok, 'a declared erroring codeunit still returns false when guarded');
        Assert.ExpectedError('BOOM-FROM-ONRUN');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
