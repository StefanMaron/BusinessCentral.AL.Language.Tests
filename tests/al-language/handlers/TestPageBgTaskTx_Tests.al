// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-enqueuebackgroundtask-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-runpagebackgroundtask-method
// Scope: in-scope
// Fixtures used: Test Page BgTask Row (60790), Test Page BgTask Card (60792),
//                Test Page BgTask TxWorker (67200), Test Page BgTask TxNoop (67201),
//                Test Page BgTask Tx Card (67203), Assert (60021)
//
// A page background task's worker runs in a child session, not in the caller's transaction.
// These tests pin what that child session sees of a caller that has written rows and NOT
// committed them:
//   - the worker reads the caller's uncommitted rows (inserts and deletes alike);
//   - the worker is not itself in a write transaction, so a guarded Codeunit.Run -- refused
//     in the caller while its write is pending -- is allowed inside the worker;
//   - the caller's write transaction is still open after the task returns.
// Base Application's Journal Errors factbox ("Check Gen. Jnl. Line. Backgr.", 9081) depends
// on all three: it runs Gen. Jnl.-Check Line through a guarded Codeunit.Run over journal
// lines the test has not committed (BusinessCentral.AL.Runner#4679).

codeunit 67202 "Test Page BgTask Tx Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "Test Page BgTask Row";
    begin
        Row.DeleteAll();
    end;

    local procedure SeedRow(No: Code[20])
    var
        Row: Record "Test Page BgTask Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Insert();
    end;

    // Positive: rows the test inserted without committing are visible to the worker, and an
    // uncommitted delete is visible too -- the second run counts one fewer.
    [Test]
    procedure RunPageBackgroundTask_WorkerReadsCallersUncommittedRows()
    var
        Row: Record "Test Page BgTask Row";
        Card: TestPage "Test Page BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        Value: Text;
    begin
        Initialize();
        SeedRow('TX-1');
        SeedRow('TX-2');
        SeedRow('TX-3');
        Assert.IsTrue(Database.IsInWriteTransaction(), 'precondition: the seeded rows must still be uncommitted');

        Card.OpenView();
        Results := Card.RunPageBackgroundTask(Codeunit::"Test Page BgTask TxWorker", Params, true);
        Results.Get('Count', Value);
        Assert.AreEqual('3', Value, 'the worker must see the three rows the caller inserted without committing');

        Row.Get('TX-2');
        Row.Delete();
        Results := Card.RunPageBackgroundTask(Codeunit::"Test Page BgTask TxWorker", Params, true);
        Results.Get('Count', Value);
        Assert.AreEqual('2', Value, 'the worker must see the row the caller deleted without committing as gone');
        Card.Close();
    end;

    // The worker is outside the caller's write transaction: it reports none, and a guarded
    // Codeunit.Run inside it starts. The same guarded run in the caller, with the caller's
    // write still pending after the task returned, is refused.
    [Test]
    procedure RunPageBackgroundTask_WorkerIsOutsideCallersWriteTransaction()
    var
        Card: TestPage "Test Page BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        Value: Text;
        Ok: Boolean;
    begin
        Initialize();
        SeedRow('TX-1');
        Assert.IsTrue(Database.IsInWriteTransaction(), 'precondition: the seeded row must still be uncommitted');

        Card.OpenView();
        Results := Card.RunPageBackgroundTask(Codeunit::"Test Page BgTask TxWorker", Params, true);
        Card.Close();

        Results.Get('InWriteTx', Value);
        Assert.AreEqual('false', Value, 'the worker must not be in the caller''s write transaction');
        Results.Get('GuardedRun', Value);
        Assert.AreEqual('true', Value, 'a guarded Codeunit.Run inside the worker must be allowed to run');

        Assert.IsTrue(Database.IsInWriteTransaction(), 'the caller''s write transaction must still be open after the task');
        asserterror Ok := Codeunit.Run(Codeunit::"Test Page BgTask TxNoop");
        Assert.ExpectedError('the transaction is stopped');
    end;

    // The FactBox shape: CurrPage.EnqueueBackgroundTask from OnAfterGetCurrRecord, over rows
    // the test has not committed. The completion trigger must have run with the worker's
    // results -- not the error trigger.
    [Test]
    procedure EnqueueBackgroundTask_OverUncommittedRows_CompletesWithWorkerResults()
    var
        Card: TestPage "Test Page BgTask Tx Card";
    begin
        Initialize();
        SeedRow('TX-1');
        SeedRow('TX-2');
        Assert.IsTrue(Database.IsInWriteTransaction(), 'precondition: the seeded rows must still be uncommitted');

        Card.OpenView();
        Assert.AreEqual('', Card.ErrorCtl.Value(), 'the background task must not have raised an error');
        Assert.AreEqual('2', Card.CountCtl.Value(), 'the worker must see both uncommitted rows');
        Assert.AreEqual('false', Card.InWriteTxCtl.Value(), 'the worker must not be in the caller''s write transaction');
        Assert.AreEqual('true', Card.GuardedRunCtl.Value(), 'a guarded Codeunit.Run inside the worker must be allowed to run');
        Card.Close();
    end;
}
