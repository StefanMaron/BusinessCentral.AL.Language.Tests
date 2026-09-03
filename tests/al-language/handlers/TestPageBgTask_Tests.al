// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-enqueuebackgroundtask-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-runpagebackgroundtask-method
// Scope: in-scope
// Fixtures used: Test Page BgTask Row (60790), Test Page BgTask Worker (60791),
//                Test Page BgTask Card (60792), Assert (60021)
//
// Page background tasks run a worker codeunit outside the AL statement that triggered them
// and report back through Page.SetBackgroundTaskResult() / a page's OnPageBackgroundTaskCompleted
// (or OnPageBackgroundTaskError) trigger. Under a TestPage, BC's own test framework runs the
// worker SYNCHRONOUSLY: by the time OpenView()/GoToRecord() returns, the task has already
// completed and its trigger has already fired -- there is no separate "wait for background work"
// step the AL author has to perform.

codeunit 60793 "Test Page BgTask Tests"
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

    local procedure SeedRow(No: Code[20]; Name: Text[50]; Handle: Boolean)
    var
        Row: Record "Test Page BgTask Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Name := Name;
        Row.Handle := Handle;
        Row.Insert();
    end;

    // Positive: CurrPage.EnqueueBackgroundTask, fired from OnAfterGetCurrRecord on the FIRST
    // row a TestPage opens onto, must have already completed -- and its OnPageBackgroundTaskCompleted
    // trigger must have already run -- by the time OpenView() returns.
    [Test]
    procedure EnqueueBackgroundTask_CompletesBeforeOpenViewReturns()
    var
        Card: TestPage "Test Page BgTask Card";
    begin
        Initialize();
        SeedRow('BGT-1', 'Alpha', false);
        SeedRow('BGT-2', 'Bravo', false);

        Card.OpenView();
        Assert.AreEqual('BG:BGT-1', Card.CountTextCtl.Value(), 'background task for the first row must have completed before OpenView returns');
        Card.Close();
    end;

    // Positive: the same, but for a row reached via GoToRecord after the page is already open --
    // proves this is not an artifact of the very first OnAfterGetCurrRecord only.
    [Test]
    procedure EnqueueBackgroundTask_CompletesBeforeGoToRecordReturns()
    var
        Row: Record "Test Page BgTask Row";
        Card: TestPage "Test Page BgTask Card";
    begin
        Initialize();
        SeedRow('BGT-1', 'Alpha', false);
        SeedRow('BGT-2', 'Bravo', false);
        Row.Get('BGT-2');

        Card.OpenView();
        Assert.IsTrue(Card.GoToRecord(Row), 'GoToRecord must find the seeded row BGT-2');
        Assert.AreEqual('BG:BGT-2', Card.CountTextCtl.Value(), 'background task for the GoToRecord-reached row must have completed before GoToRecord returns');
        Card.Close();
    end;

    // Positive: TestPage.RunPageBackgroundTask(CodeunitId, Parameters, RunCompletionTriggers)
    // must return the worker's own result dictionary, independent of whatever
    // OnAfterGetCurrRecord already enqueued for the current row.
    [Test]
    procedure RunPageBackgroundTask_ReturnsWorkerResult()
    var
        Card: TestPage "Test Page BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        CountValue: Text;
    begin
        Initialize();
        SeedRow('BGT-1', 'Alpha', false);

        Card.OpenView();
        Params.Add('No', 'RPT-1');
        Results := Card.RunPageBackgroundTask(Codeunit::"Test Page BgTask Worker", Params, false);
        Card.Close();

        Assert.IsTrue(Results.Get('Count', CountValue), 'RunPageBackgroundTask must return the worker''s Results dictionary');
        Assert.AreEqual('BG:RPT-1', CountValue, 'RunPageBackgroundTask must return the worker''s own computed value');
    end;

    // Positive: a worker Error() reaches the page's OnPageBackgroundTaskError trigger with the
    // error's own text, and setting IsHandled := true suppresses the exception -- GoToRecord
    // must complete normally rather than raise it.
    [Test]
    procedure EnqueueBackgroundTask_HandledErrorDoesNotPropagate()
    var
        Row: Record "Test Page BgTask Row";
        Card: TestPage "Test Page BgTask Card";
    begin
        Initialize();
        SeedRow('BGT-1', 'Alpha', false);
        SeedRow('FAIL-H', 'Handled failure', true);
        Row.Get('FAIL-H');

        Card.OpenView();
        Assert.IsTrue(Card.GoToRecord(Row), 'GoToRecord must find the seeded row FAIL-H even though its background task errors');
        Assert.AreEqual('Test Page BgTask Worker deliberately failed for FAIL-H', Card.LastErrorTextCtl.Value(), 'OnPageBackgroundTaskError must receive the worker''s own error text');
        Card.Close();
    end;

    // Negative: the same worker error, but OnPageBackgroundTaskError leaves IsHandled false
    // (its default) -- the exception must propagate out of GoToRecord rather than be swallowed.
    [Test]
    procedure EnqueueBackgroundTask_UnhandledErrorPropagates()
    var
        Row: Record "Test Page BgTask Row";
        Card: TestPage "Test Page BgTask Card";
    begin
        Initialize();
        SeedRow('BGT-1', 'Alpha', false);
        SeedRow('FAIL-U', 'Unhandled failure', false);
        Row.Get('FAIL-U');

        Card.OpenView();
        asserterror Card.GoToRecord(Row);
        Assert.ExpectedError('Test Page BgTask Worker deliberately failed for FAIL-U');
        Card.Close();
    end;
}
