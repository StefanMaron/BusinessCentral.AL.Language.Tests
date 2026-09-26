// Worker codeunit for TestPageBgTaskTx_Tests.al. Reports, from inside a page background
// task, what the worker's own session sees of the CALLER's transaction:
//   Count      -- rows of "Test Page BgTask Row" visible to the worker
//   InWriteTx  -- Database.IsInWriteTransaction() inside the worker ('true' / 'false')
//   GuardedRun -- 'true' / 'false' from a guarded Codeunit.Run (return value consumed),
//                 the form the platform refuses while a write transaction is open.
// This is the shape the Base Application's "Check Gen. Jnl. Line. Backgr." (9081) uses.

codeunit 67200 "Test Page BgTask TxWorker"
{
    trigger OnRun()
    var
        Row: Record "Test Page BgTask Row";
        Results: Dictionary of [Text, Text];
    begin
        Results.Add('Count', Format(Row.Count()));
        Results.Add('InWriteTx', BoolText(Database.IsInWriteTransaction()));
        Results.Add('GuardedRun', BoolText(Codeunit.Run(Codeunit::"Test Page BgTask TxNoop")));
        Page.SetBackgroundTaskResult(Results);
    end;

    local procedure BoolText(Value: Boolean): Text
    begin
        if Value then
            exit('true');
        exit('false');
    end;
}
