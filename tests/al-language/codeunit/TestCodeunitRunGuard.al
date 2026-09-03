// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALTFixtureCleanup (60019),
//                self-contained erroring codeunits (60216, 60256)
// Note: proves the runner honours BC's guarded/unguarded Codeunit.Run
// distinction — guarded (return value consumed) traps the inner error and
// returns false; unguarded (statement form) propagates the inner error.
// Pinned for BOTH spellings of the same AL construct: the STATIC form
// (`Codeunit.Run(Codeunit::X)`) and the INSTANCE form (a codeunit variable's
// own `.Run()`), plus that a guarded run which writes and then errors rolls
// its own writes back — AlRunner#2334.
// BC versions: 24+

codeunit 60217 "Test Codeunit Run Guard"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

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

    [Test]
    procedure GuardedRun_InstanceForm_TrapsInnerError_ReturnsFalse()
    var
        RunGuard: Codeunit "Run Guard Erroring";
        Ok: Boolean;
    begin
        Initialize();
        // [WHEN] the boolean return value of a codeunit VARIABLE's own Run() is consumed
        //        (guarded, instance form — as opposed to the static Codeunit.Run(...) above)
        Ok := RunGuard.Run();

        // [THEN] the inner error is trapped exactly like the static form: Run returns false ...
        Assert.IsFalse(Ok, 'Guarded instance-form Run() on an erroring OnRun must return false.');

        // [THEN] ... and the inner error text is readable via GetLastErrorText.
        Assert.ExpectedError('BOOM-FROM-ONRUN');
    end;

    [Test]
    procedure UnguardedRun_InstanceForm_PropagatesInnerError()
    var
        RunGuard: Codeunit "Run Guard Erroring";
    begin
        Initialize();
        // [WHEN] the return value is discarded (statement form, unguarded, instance form)
        // [THEN] the inner error propagates to the caller
        asserterror RunGuard.Run();
        Assert.ExpectedError('BOOM-FROM-ONRUN');
    end;

    [Test]
    procedure GuardedRun_InstanceForm_WriteThenError_RollsBackInsertedRow()
    var
        ALTUniversal: Record "ALT Universal";
        RunGuard: Codeunit "ALT Run Tx Write Then Error";
        Ok: Boolean;
    begin
        Initialize();

        // [WHEN] a guarded (instance-form) Codeunit.Run inserts a row, uncommitted, then errors
        Ok := RunGuard.Run();

        // [THEN] the run is trapped and reports failure ...
        Assert.IsFalse(Ok, 'Guarded Run() on a write-then-error OnRun must return false.');
        Assert.ExpectedError('BOOM-FROM-WRITE-THEN-ERROR');

        // [THEN] ... and its own uncommitted write does not survive: BC's
        //        EndTransactionWorldAndTransaction(false) rolls the failed run's own
        //        transaction back, so the inserted row must not exist afterwards.
        ALTUniversal.Reset();
        ALTUniversal.SetRange("Entry No.", 9256);
        Assert.RecordIsEmpty(ALTUniversal);
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        // Cleanup deletes rows, which itself opens a write transaction. Close it so each
        // test below starts from a known state and controls its own pending write.
        Commit();
    end;
}
