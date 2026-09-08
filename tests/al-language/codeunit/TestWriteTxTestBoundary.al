// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALTFixtureCleanup (60019), shared Assert (60021),
//                ALT Run Tx Inserter (60253), ALT Run Tx Dirty Inserter (60255)
//
// Asks whether a write transaction survives a TEST-METHOD boundary. "Test Codeunit Run
// Write Tx" (60254) pins the write-transaction rule around Codeunit.Run WITHIN one test
// method — the guarded form is refused while the caller holds an uncommitted write, the
// statement form is not. Every one of its tests starts with a Commit-carrying Initialize,
// so none of them says what happens when the uncommitted write was made by the PREVIOUS
// test method in the same codeunit.
//
// "Test Isolation Rollback Scope" (60897) answers the neighbouring question about ROWS —
// under TestIsolation = Codeunit an uncommitted row written by one test is still visible to
// the next — and that is deliberately not the same question. A row surviving says nothing
// about whether the session still holds an open write transaction, and the guard on a
// guarded Codeunit.Run reads the transaction, not the row. Both answers hold at once: the
// row survives AND the transaction is gone, which Test06 asserts together.
//
// The tests below are declaration-ordered and share a codeunit, the same way 60897's are.
// Only Test01 clears the fixture, and it does so WITHOUT a Commit: it carries no
// TransactionModel attribute, so the platform commits its work at the boundary. A Commit
// inside any of the AutoRollback tests would be refused outright ("Tests cannot call the
// Commit function if TransactionModel property is set to AutoRollback"), and a Commit
// anywhere after Test01 would close the very transaction the next test is here to ask about.
//
// Measured on a real BC 28.4.53241.0 service tier, all six green.
// BC versions: 24+

codeunit 60878 "Test Write Tx Test Boundary"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure MarkerCount(EntryNo: Integer): Integer
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Reset();
        ALTUniversal.SetRange("Entry No.", EntryNo);
        exit(ALTUniversal.Count());
    end;

    [Test]
    procedure WriteTxBoundary_Test01_ClearsTheFixture()
    begin
        Cleanup.Initialize();

        Assert.AreEqual(0, MarkerCount(9255),
            'The marker row the guarded run below writes must not exist before it runs.');
        Assert.AreEqual(0, MarkerCount(9253),
            'The marker row the second guarded run writes must not exist before it runs.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WriteTxBoundary_Test02_AutoRollbackTestWritesWithoutCommitting()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 60878001;
        ALTUniversal."Text Field" := 'boundary-probe';
        ALTUniversal.Insert();

        Assert.IsTrue(Database.IsInWriteTransaction(),
            'An uncommitted Insert must leave a write transaction open inside the test that made it.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WriteTxBoundary_Test03_NextTestStartsWithNoWriteTransaction()
    begin
        // This test writes nothing of its own, so anything reported here was inherited from
        // the test above, whose Insert was never committed.
        Assert.IsFalse(Database.IsInWriteTransaction(),
            'A test method must not start inside the write transaction the previous test left open.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WriteTxBoundary_Test04_GuardedCodeunitRunIsAllowed()
    var
        Ok: Boolean;
    begin
        // The observable that matters. A guarded Codeunit.Run needs its own transaction
        // world, which the platform refuses to open while the caller holds an uncommitted
        // write — 60254's first test pins that refusal. Two tests back left exactly such a
        // write behind, so if a write transaction could survive the boundary this call would
        // be refused rather than run.
        Assert.IsFalse(Database.IsInWriteTransaction(),
            'No write transaction may be pending at the start of this test.');

        // The run codeunit does not Commit: an AutoRollback test refuses a Commit anywhere
        // beneath it, including inside a codeunit it runs.
        Ok := Codeunit.Run(Codeunit::"ALT Run Tx Dirty Inserter");

        Assert.IsTrue(Ok, 'A guarded Codeunit.Run must be allowed here and must succeed.');
        Assert.AreEqual(1, MarkerCount(9255),
            'The guarded Codeunit.Run must actually have run the codeunit.');
    end;

    [Test]
    procedure WriteTxBoundary_Test05_DefaultModelTestWritesWithoutCommitting()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        // No TransactionModel attribute: the platform commits this test's work at the
        // boundary instead of rolling it back. Either way the transaction ends there.
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 60878002;
        ALTUniversal."Text Field" := 'boundary-probe-2';
        ALTUniversal.Insert();

        Assert.IsTrue(Database.IsInWriteTransaction(),
            'An uncommitted Insert must leave a write transaction open inside the test that made it.');
    end;

    [Test]
    procedure WriteTxBoundary_Test06_GuardedRunIsAllowedAfterADefaultModelWrite()
    var
        ALTUniversal: Record "ALT Universal";
        Ok: Boolean;
    begin
        Assert.IsFalse(Database.IsInWriteTransaction(),
            'A default-model test''s write is committed at the boundary, so no write transaction may be pending here.');

        Ok := Codeunit.Run(Codeunit::"ALT Run Tx Inserter");

        Assert.IsTrue(Ok,
            'A guarded Codeunit.Run must be allowed after a default-model test wrote without committing.');
        Assert.AreEqual(1, MarkerCount(9253),
            'The guarded Codeunit.Run must actually have run the codeunit.');

        // The other direction of the same boundary, and the reason this is not a restatement
        // of 60897: ending the transaction by committing is not the same as discarding the
        // rows. The row is here AND no transaction is open.
        Assert.IsTrue(ALTUniversal.Get(60878002),
            'The previous test''s row must still be visible: the platform committed it at the boundary.');
    end;
}
