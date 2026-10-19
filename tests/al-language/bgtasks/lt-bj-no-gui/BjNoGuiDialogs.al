// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-guiallowed-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 81680, worker codeunit 81681, page 81682, log codeunit 81683, test codeunits 81684 and 81685
// Probe: corpus issue 635 item 6. Message and Confirm where the session has no client. A test cannot start such a session (StartSession is refused
//   under TestIsolation, see tests/al-language/session/TestStartSessionRecord.al; TaskScheduler.CanCreateTask is false in a test), so the probe runs
//   the calls in a page background task worker: what GuiAllowed answers there, what Message and Confirm (default true and false) do, and whether
//   the test's MessageHandler and ConfirmHandler see them. Both ways in: TestPage.RunPageBackgroundTask and CurrPage.EnqueueBackgroundTask.
// BC versions: 27, 28, 29

table 81680 "LT BJ NoGui Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 81681 "LT BJ NoGui Worker"
{
    trigger OnRun()
    var
        Results: Dictionary of [Text, Text];
        Answer: Boolean;
    begin
        Results.Add('gui', Format(GuiAllowed()));
        ClearLastError();
        if TryMessage() then
            Results.Add('message', 'returned')
        else
            Results.Add('message', 'error: ' + GetLastErrorText() + ' code=' + GetLastErrorCode());
        ClearLastError();
        if TryConfirm(true, Answer) then
            Results.Add('confirm default true', Format(Answer))
        else
            Results.Add('confirm default true', 'error: ' + GetLastErrorText() + ' code=' + GetLastErrorCode());
        ClearLastError();
        if TryConfirm(false, Answer) then
            Results.Add('confirm default false', Format(Answer))
        else
            Results.Add('confirm default false', 'error: ' + GetLastErrorText() + ' code=' + GetLastErrorCode());
        Page.SetBackgroundTaskResult(Results);
    end;

    [TryFunction]
    local procedure TryMessage()
    begin
        Message('LT BJ message from the worker');
    end;

    [TryFunction]
    local procedure TryConfirm(Default: Boolean; var Answer: Boolean)
    begin
        Answer := Confirm('LT BJ confirm from the worker', Default);
    end;
}

page 81682 "LT BJ NoGui Card"
{
    PageType = Card;
    SourceTable = "LT BJ NoGui Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(No; Rec."No.") { ApplicationArea = All; }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Params: Dictionary of [Text, Text];
        TaskId: Integer;
    begin
        if Rec."No." = 'ENQ' then
            CurrPage.EnqueueBackgroundTask(TaskId, Codeunit::"LT BJ NoGui Worker", Params, 10000, PageBackgroundTaskErrorLevel::Error);
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        NoGuiLog: Codeunit "LT BJ NoGui Log";
        ResultKey: Text;
    begin
        foreach ResultKey in Results.Keys() do
            NoGuiLog.Add(ResultKey + '=' + Results.Get(ResultKey));
    end;

    trigger OnPageBackgroundTaskError(TaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean)
    var
        NoGuiLog: Codeunit "LT BJ NoGui Log";
    begin
        NoGuiLog.Add('task error code=' + ErrorCode + ' text=' + ErrorText);
        IsHandled := true;
    end;
}

codeunit 81683 "LT BJ NoGui Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

codeunit 81684 "LT BJ NoGui Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        NoGuiLog: Codeunit "LT BJ NoGui Log";
        HandlerLog: Text;

    local procedure Seed(No: Code[10])
    var
        Row: Record "LT BJ NoGui Row";
    begin
        Row.DeleteAll();
        Row."No." := No;
        Row.Insert();
        Commit();
        NoGuiLog.Take();
    end;

    local procedure Dump(Results: Dictionary of [Text, Text]): Text
    var
        ResultKey: Text;
        Result: Text;
    begin
        foreach ResultKey in Results.Keys() do
            Result += ResultKey + '=' + Results.Get(ResultKey) + ';';
        exit(Result);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmYes')]
    procedure RunPageBackgroundTask_WithHandlers()
    var
        Pg: TestPage "LT BJ NoGui Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
    begin
        Seed('RUN');
        Observer.Observe('test session gui', Format(GuiAllowed()));
        Pg.OpenView();
        HandlerLog := '';
        Results := Pg.RunPageBackgroundTask(Codeunit::"LT BJ NoGui Worker", Params, false);
        Observer.Observe('results', Dump(Results));
        Observer.Observe('handlers', HandlerLog);
        Pg.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmYes')]
    procedure EnqueueBackgroundTask_WithHandlers()
    var
        Pg: TestPage "LT BJ NoGui Card";
    begin
        Seed('ENQ');
        HandlerLog := '';
        Pg.OpenView();
        Observer.Observe('completion log', NoGuiLog.Take());
        Observer.Observe('handlers', HandlerLog);
        Pg.Close();
        Observer.Finish();
    end;

    [MessageHandler]
    procedure MsgHandler(Msg: Text[1024])
    begin
        HandlerLog += 'message handler: ' + Msg + ';';
    end;

    [ConfirmHandler]
    procedure ConfirmYes(Question: Text[1024]; var Reply: Boolean)
    begin
        HandlerLog += 'confirm handler: ' + Question + ';';
        Reply := true;
    end;
}

codeunit 81685 "LT BJ NoGui Tests NoHandler"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        NoGuiLog: Codeunit "LT BJ NoGui Log";

    local procedure Dump(Results: Dictionary of [Text, Text]): Text
    var
        ResultKey: Text;
        Result: Text;
    begin
        foreach ResultKey in Results.Keys() do
            Result += ResultKey + '=' + Results.Get(ResultKey) + ';';
        exit(Result);
    end;

    [Test]
    procedure RunPageBackgroundTask_NoHandlers()
    var
        Row: Record "LT BJ NoGui Row";
        Pg: TestPage "LT BJ NoGui Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
    begin
        Row.DeleteAll();
        Row."No." := 'RUN';
        Row.Insert();
        Commit();
        NoGuiLog.Take();
        Pg.OpenView();
        Results := Pg.RunPageBackgroundTask(Codeunit::"LT BJ NoGui Worker", Params, false);
        Observer.Observe('results', Dump(Results));
        Pg.Close();
        Observer.Finish();
    end;
}
