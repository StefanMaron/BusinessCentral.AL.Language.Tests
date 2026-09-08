// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALTFixtureCleanup (60019), shared Assert (60021),
//                ALT Run Tx Inserter (60253), ALT Run Tx Dirty Inserter (60255),
//                ALT Run Tx None Inserter (60879), ALT Run Tx None Dirty Inserter (60880)
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
// Only Test01 and Test11 clear the fixture, and they do so WITHOUT a Commit: they carry no
// TransactionModel attribute, so the platform commits their work at the boundary. A Commit
// inside any of the AutoRollback tests would be refused outright ("Tests cannot call the
// Commit function if TransactionModel property is set to AutoRollback"), and a Commit
// anywhere after Test01 would close the very transaction the next test is here to ask about.
//
// Test07 onwards ask the same boundary question for TransactionModel::None, which the
// platform handles BEFORE the method body instead of after it: every active transaction is
// ended on the way in, and the body therefore runs with no transaction at all. Three
// consequences, one test each — the body starts with no write transaction and may make a
// guarded Codeunit.Run (Test08), a write from the body itself is refused outright with "A
// transaction must be started before changes can be made to the database." (Test09), and a
// codeunit the test RUNS may write anyway, because Codeunit.Run begins a transaction of its
// own (Test10).
//
// Measured on a real BC 28.4.53241.0 service tier, all eleven green.
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

    [Test]
    procedure WriteTxBoundary_Test07_DefaultModelWriteBeforeANoneTest()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        // The set-up for Test08: an uncommitted write, so a write transaction is open when
        // this test method ends.
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 60878003;
        ALTUniversal."Text Field" := 'boundary-probe-3';
        ALTUniversal.Insert();

        Assert.IsTrue(Database.IsInWriteTransaction(),
            'An uncommitted Insert must leave a write transaction open inside the test that made it.');
    end;

    [Test]
    [TransactionModel(TransactionModel::None)]
    procedure WriteTxBoundary_Test08_NoneTestStartsWithNoTransaction()
    var
        ALTUniversal: Record "ALT Universal";
        Ok: Boolean;
    begin
        // TransactionModel::None is handled BEFORE the method body rather than after it, so
        // the platform has already ended every active transaction by the time this line runs.
        Assert.IsFalse(Database.IsInWriteTransaction(),
            'A TransactionModel::None test must not start inside a write transaction.');

        // Ending the transaction is not discarding the rows: the previous test ran under the
        // default model, so its write was committed at the boundary.
        Assert.IsTrue(ALTUniversal.Get(60878003),
            'The previous default-model test''s row must still be visible.');

        Assert.AreEqual(0, MarkerCount(9879),
            'The marker row the guarded run below writes must not exist before it runs.');

        Ok := Codeunit.Run(Codeunit::"ALT Run Tx None Inserter");

        Assert.IsTrue(Ok, 'A guarded Codeunit.Run must be allowed at the start of a None test.');
        Assert.AreEqual(1, MarkerCount(9879),
            'The guarded Codeunit.Run must actually have run the codeunit.');
    end;

    [Test]
    [TransactionModel(TransactionModel::None)]
    procedure WriteTxBoundary_Test09_NoneTestCannotWriteDirectly()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        // The other side of "no transaction is active": a write from the test body itself has
        // no transaction to join, and the platform refuses it outright. The error is trappable
        // and leaves no write transaction behind.
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 60878004;
        ALTUniversal."Text Field" := 'never-written';
        asserterror ALTUniversal.Insert();

        Assert.ExpectedError('A transaction must be started before changes can be made to the database.');

        Assert.IsFalse(Database.IsInWriteTransaction(),
            'A refused write must not leave a write transaction open.');
        Assert.AreEqual(0, MarkerCount(60878004),
            'The refused Insert must not have written a row.');
    end;

    [Test]
    [TransactionModel(TransactionModel::None)]
    procedure WriteTxBoundary_Test10_ARunCodeunitMayWriteUnderNone()
    begin
        // Codeunit.Run begins a transaction of its own — the statement form joins one it
        // begins, the guarded form opens an isolated transaction world — so the write refused
        // in Test09 is allowed inside a codeunit this test RUNS.
        Assert.AreEqual(0, MarkerCount(9880),
            'The marker row the run below writes must not exist before it runs.');

        Codeunit.Run(Codeunit::"ALT Run Tx None Dirty Inserter");

        Assert.AreEqual(1, MarkerCount(9880),
            'A codeunit run from a None test must be able to write.');
        Assert.IsFalse(Database.IsInWriteTransaction(),
            'The transaction Codeunit.Run began ends with the run, so the None test body is left with none.');
    end;

    [Test]
    procedure WriteTxBoundary_Test11_ClearsTheFixtureAgain()
    begin
        // Leaves nothing behind for the codeunits that share these fixture tables. No
        // TransactionModel attribute, so the platform commits this at the boundary.
        Cleanup.Initialize();

        Assert.AreEqual(0, MarkerCount(9879), 'The fixture must be empty again.');
        Assert.AreEqual(0, MarkerCount(9880), 'The fixture must be empty again.');
    end;
}
