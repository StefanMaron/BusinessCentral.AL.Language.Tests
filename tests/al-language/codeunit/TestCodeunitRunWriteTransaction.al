// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALTFixtureCleanup (60019), ALT Run Tx Inserter (60253),
//                ALT Run Tx Dirty Inserter (60255)
// Note: pins the write-transaction scoping rule around Codeunit.Run. Whether the
// Boolean return value is consumed is what decides it: the guarded form needs its own
// isolated transaction, so BC refuses it while the caller still has an uncommitted
// write pending; the statement form just joins the caller's transaction and is allowed.
// The last two tests pin the other half of that rule: the isolated transaction the
// guarded form opens is the RUN codeunit's own, so writes it leaves uncommitted belong
// to that transaction and end with it — they do not leave the CALLER holding an open
// write transaction afterwards.
// BC versions: 24+

codeunit 60254 "Test Codeunit Run Write Tx"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        // Cleanup deletes rows, which itself opens a write transaction. Close it so each
        // test below starts from a known state and controls its own pending write.
        Commit();
    end;

    local procedure InsertPendingRow()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 1;
        ALTUniversal.Insert();
    end;

    local procedure MarkerRowCount(): Integer
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Reset();
        ALTUniversal.SetRange("Entry No.", 9253);
        exit(ALTUniversal.Count());
    end;

    local procedure DirtyMarkerRowCount(): Integer
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Reset();
        ALTUniversal.SetRange("Entry No.", 9255);
        exit(ALTUniversal.Count());
    end;

    [Test]
    procedure GuardedRun_WithUncommittedWrite_IsRefused_AndCodeunitNeverRuns()
    var
        Ok: Boolean;
    begin
        Initialize();

        // [GIVEN] an uncommitted write, so the session holds an open write transaction
        InsertPendingRow();

        // [WHEN] Codeunit.Run is called in the guarded form (return value consumed)
        asserterror Ok := Codeunit.Run(Codeunit::"ALT Run Tx Inserter");

        // [THEN] the platform refuses the call outright — this is NOT the guarded form
        //        trapping an inner error and returning false; the error reaches the caller.
        //        BC keeps the AL-visible text generic here; the detail naming Codeunit.Run
        //        goes to the admin/telemetry channel, not to GetLastErrorText.
        Assert.ExpectedError('the transaction is stopped');
        Assert.IsFalse(Ok, 'A refused Codeunit.Run must not assign a result.');

        // [THEN] the codeunit never ran, so the marker row it commits does not exist.
        //        The marker is committed by the codeunit itself, so a count of 0 here means
        //        "never ran", not "written and then rolled back".
        Assert.AreEqual(0, MarkerRowCount(),
            'The refused codeunit must never have run, so its committed marker row must not exist.');
    end;

    [Test]
    procedure UnguardedRun_WithUncommittedWrite_IsAllowed_AndCodeunitRuns()
    begin
        Initialize();

        // [GIVEN] the same uncommitted write, so the same write transaction is open
        InsertPendingRow();

        // [WHEN] Codeunit.Run is called in the statement form (return value discarded)
        Codeunit.Run(Codeunit::"ALT Run Tx Inserter");

        // [THEN] the call is allowed and the codeunit ran
        Assert.AreEqual(1, MarkerRowCount(),
            'Statement-form Codeunit.Run is allowed in a write transaction and must run the codeunit.');
    end;

    [Test]
    procedure GuardedRun_AfterCommit_IsAllowed_AndCodeunitRuns()
    var
        Ok: Boolean;
    begin
        Initialize();

        // [GIVEN] a write that IS committed, so no write transaction is open
        InsertPendingRow();
        Commit();

        // [WHEN] Codeunit.Run is called in the guarded form
        Ok := Codeunit.Run(Codeunit::"ALT Run Tx Inserter");

        // [THEN] the call is allowed, returns true, and the codeunit ran
        Assert.IsTrue(Ok, 'Guarded Codeunit.Run must succeed once Commit() has closed the write transaction.');
        Assert.AreEqual(1, MarkerRowCount(),
            'Guarded Codeunit.Run after Commit() must actually run the codeunit.');
    end;

    [Test]
    procedure GuardedRun_LeavingUncommittedWrite_DoesNotBlockTheNextGuardedRun()
    var
        FirstOk: Boolean;
        SecondOk: Boolean;
        ThirdOk: Boolean;
    begin
        Initialize();

        // [GIVEN] no pending write in the caller, so the first guarded call is allowed
        // [WHEN] a guarded Codeunit.Run runs a codeunit that writes and does NOT commit
        FirstOk := Codeunit.Run(Codeunit::"ALT Run Tx Dirty Inserter");
        Assert.IsTrue(FirstOk, 'The first guarded Codeunit.Run must succeed.');
        Assert.AreEqual(1, DirtyMarkerRowCount(),
            'The run codeunit must have written its row.');

        // [THEN] a SECOND guarded Codeunit.Run is still allowed: the uncommitted write
        //        belongs to the transaction the first guarded call opened and ended, not
        //        to the caller, so the caller holds no open write transaction here.
        SecondOk := Codeunit.Run(Codeunit::"ALT Run Tx Inserter");
        Assert.IsTrue(SecondOk,
            'A guarded Codeunit.Run must still be allowed after an earlier guarded run left an uncommitted write.');
        Assert.AreEqual(1, MarkerRowCount(),
            'The second guarded Codeunit.Run must actually have run the codeunit.');

        // [THEN] the guard itself is intact: a write made by the CALLER, uncommitted,
        //        still refuses the next guarded call.
        InsertPendingRow();
        asserterror ThirdOk := Codeunit.Run(Codeunit::"ALT Run Tx Inserter");
        Assert.ExpectedError('the transaction is stopped');
        Assert.IsFalse(ThirdOk, 'A refused Codeunit.Run must not assign a result.');
    end;

    [Test]
    procedure GuardedRun_LeavingUncommittedWrite_CommitsItWithTheRunsOwnTransaction()
    var
        Ok: Boolean;
    begin
        Initialize();

        // [GIVEN] a guarded Codeunit.Run whose codeunit writes a row and does not commit it
        Ok := Codeunit.Run(Codeunit::"ALT Run Tx Dirty Inserter");
        Assert.IsTrue(Ok, 'The guarded Codeunit.Run must succeed.');

        // [WHEN] a later, unrelated error in the CALLER rolls the caller's work back
        asserterror Error('rollback trigger');
        Assert.ExpectedError('rollback trigger');

        // [THEN] the row survives: the guarded run's transaction was committed when the
        //        run returned successfully, so the caller's rollback cannot reach it.
        Assert.AreEqual(1, DirtyMarkerRowCount(),
            'A successful guarded Codeunit.Run commits its own transaction, so its row must survive a later rollback in the caller.');
    end;
}
