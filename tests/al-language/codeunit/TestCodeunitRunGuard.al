// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
// Scope: in-scope
// Fixtures used: none (self-contained erroring codeunit, ID 60216)
// Note: proves the runner honours BC's guarded/unguarded Codeunit.Run
// distinction — guarded (return value consumed) traps the inner error and
// returns false; unguarded (statement form) propagates the inner error.
// BC versions: 24+

codeunit 60217 "Test Codeunit Run Guard"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure GuardedRun_TrapsInnerError_ReturnsFalse()
    var
        Ok: Boolean;
    begin
        Initialize();
        // [WHEN] the boolean return value of Codeunit.Run is consumed (guarded)
        Ok := Codeunit.Run(Codeunit::"Run Guard Erroring");

        // [THEN] the inner error is trapped: Run returns false ...
        Assert.IsFalse(Ok, 'Guarded Codeunit.Run on an erroring OnRun must return false.');

        // [THEN] ... and the inner error text is readable via GetLastErrorText.
        Assert.ExpectedError('BOOM-FROM-ONRUN');
    end;

    [Test]
    procedure UnguardedRun_PropagatesInnerError()
    begin
        Initialize();
        // [WHEN] the return value is discarded (statement form, unguarded)
        // [THEN] the inner error propagates to the caller
        asserterror Codeunit.Run(Codeunit::"Run Guard Erroring");
        Assert.ExpectedError('BOOM-FROM-ONRUN');
    end;

    local procedure Initialize()
    begin
    end;
}
