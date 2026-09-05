// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-startsession-method
// Scope: in-scope
// Fixtures used: SS Passed Record (60393), SS Worker Result (60394),
//                SS Baseline Worker (60395), SS Record Worker (60396), Assert
//
// Pins two questions about StartSession(SessionId, ObjectId[, Company[, Record]]):
//
//   1. Does it dispatch from inside an ordinary [Test] codeunit at all? BC's own
//      ALStartSessionAsyncImpl refuses with NavTestStartSessionNotAllowedException when
//      "session.TestExecution != null && (!CommitTestCodeunits || !CommitTestFunctions)" --
//      whatever configures those two flags is not something this test controls directly, so
//      StartSession_Baseline_WorkerRuns is the control: if it fails, every claim below is
//      moot for reasons that have nothing to do with the record.
//
//   2. What does the record-carrying overload hand the worker? ALStartSessionAsyncImpl does
//      NOT read the row fresh from the database in the new session -- it clones the FIELD
//      VALUES off the caller's in-memory record variable (record.CloneRecord(newSession))
//      and hands the worker that clone. StartSession_WithRecord_WorkerSeesTheFieldValueAsOfTheCall
//      seeds a record with a value that is NEVER Insert()'d, so a worker that instead read
//      its own fresh Get() would find nothing and this must fail.
//
// StartSession's worker runs in a SEPARATE, BACKGROUND session
// (ALStartSessionAsyncImpl's own RunTask(...).LogOrFailOnException() is not awaited), so both
// tests poll for the worker's own write rather than assuming it has completed the instant
// StartSession returns.
codeunit 60397 "Test StartSession Record"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Result: Record "SS Worker Result";
    begin
        Result.DeleteAll();
    end;

    local procedure WaitForRow(var Result: Record "SS Worker Result"; Marker: Code[20]): Boolean
    var
        Attempt: Integer;
    begin
        for Attempt := 1 to 50 do begin
            if Result.Get(Marker) then
                exit(true);
            Sleep(100);
        end;
        exit(false);
    end;

    // Control: StartSession dispatches a worker with no record involved. If this fails,
    // the record-carrying test below cannot be read as saying anything about the record.
    [Test]
    procedure StartSession_Baseline_WorkerRuns()
    var
        Result: Record "SS Worker Result";
        SessionId: Integer;
    begin
        Initialize();

        Assert.IsTrue(StartSession(SessionId, Codeunit::"SS Baseline Worker"),
            'StartSession must report that it started the session.');
        Assert.IsTrue(SessionId > 0,
            StrSubstNo('BC guarantees a non-zero session id after StartSession; got %1.', SessionId));

        Assert.IsTrue(WaitForRow(Result, 'BASELINE'),
            'SS Baseline Worker''s OnRun must have run and written its marker row within the wait window.');
    end;

    // The question #2751 is about: does the worker see the field value the caller set on its
    // OWN in-memory record variable, even though that row was never Insert()'d and so does
    // not exist for a fresh Get() to find?
    [Test]
    procedure StartSession_WithRecord_WorkerSeesTheFieldValueAsOfTheCall()
    var
        Passed: Record "SS Passed Record";
        Result: Record "SS Worker Result";
        SessionId: Integer;
    begin
        Initialize();

        Passed.Init();
        Passed."No." := 'X';
        Passed."Value" := 'uncommitted-value';
        // Deliberately no Insert(): if the worker instead did a fresh Get() in its own
        // session, there would be nothing to find.

        Assert.IsTrue(StartSession(SessionId, Codeunit::"SS Record Worker", '', Passed),
            'StartSession must report that it started the session.');

        Assert.IsTrue(WaitForRow(Result, 'RECORD'),
            'SS Record Worker''s OnRun must have run within the wait window.');
        Assert.AreEqual('uncommitted-value', Result."Seen Value",
            'StartSession must hand the worker the field value on the CALLER''s record ' +
            'variable at the time of the call, not a fresh read of a row that was never ' +
            'inserted.');
    end;
}
