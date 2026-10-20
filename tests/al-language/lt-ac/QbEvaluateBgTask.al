// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); page LT CN BgTask Card (84898, session/lt-cn-session-leads/CnIsolatedStorageLeads.al);
//   own codeunits 86394, 86396 - 86398
// Probe: writer QB, corpus issue #626 items 11, 12 and 15 (the Evaluate part): Evaluate into HttpRequestType, PageStyle and
//   PageBackgroundTaskErrorLevel, by member name, by number and for an invalid name and ordinal. Called in the test session, Evaluate
//   ends the test session on the Linux containers (ACHttpRequestType.al, ACPageStyle.al, types/lt-page-style/PageStyle.al), so here it
//   runs in the worker of a page background task (TestPage.RunPageBackgroundTask), which is a session of its own.
// BC versions: 27, 28, 29

codeunit 86394 "LT QB Eval BgTask Worker"
{
    trigger OnRun()
    var
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        TypeName: Text;
        Input: Text;
        Http: HttpRequestType;
        Style: PageStyle;
        Level: PageBackgroundTaskErrorLevel;
        Ok: Boolean;
    begin
        Params := Page.GetBackgroundParameters();
        Params.Get('Type', TypeName);
        Params.Get('Input', Input);
        case TypeName of
            'HttpRequestType':
                begin
                    Ok := Evaluate(Http, Input);
                    Results.Add('Ret', Format(Ok, 0, 9));
                    Results.Add('Value', Format(Http));
                    Results.Add('Ordinal', Format(Http, 0, 2));
                end;
            'PageStyle':
                begin
                    Ok := Evaluate(Style, Input);
                    Results.Add('Ret', Format(Ok, 0, 9));
                    Results.Add('Value', Format(Style));
                    Results.Add('Ordinal', Format(Style, 0, 2));
                end;
            'PageBackgroundTaskErrorLevel':
                begin
                    Ok := Evaluate(Level, Input);
                    Results.Add('Ret', Format(Ok, 0, 9));
                    Results.Add('Value', Format(Level));
                    Results.Add('Ordinal', Format(Level, 0, 2));
                end;
        end;
        if not Ok then
            Results.Add('LastError', GetLastErrorText());
        Page.SetBackgroundTaskResult(Results);
    end;
}

codeunit 86396 "LT QB Eval HttpRequestType"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure QB_Evaluate_HttpRequestType_InBgTask()
    var
        Observer: Codeunit "Probe Observer";
        Input: Text;
    begin
        foreach Input in 'Get,Post,Put,Patch,Delete,get,0,4,Foo,99, '.Split(',') do
            Observer.Observe(Input, Run('HttpRequestType', Input));
        Observer.Finish();
    end;

    local procedure Run(TypeName: Text; Input: Text): Text
    var
        Card: TestPage "LT CN BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        K: Text;
        Result: Text;
    begin
        Params.Add('Type', TypeName);
        Params.Add('Input', Input);
        Card.OpenView();
        ClearLastError();
        if TryRun(Card, Params, Results) then begin
            foreach K in Results.Keys() do
                Result += K + '=' + Results.Get(K) + ';';
        end else
            Result := 'error: ' + GetLastErrorText() + ' | ' + GetLastErrorCode();
        Card.Close();
        exit(Result);
    end;

    [TryFunction]
    local procedure TryRun(var Card: TestPage "LT CN BgTask Card"; Params: Dictionary of [Text, Text]; var Results: Dictionary of [Text, Text])
    begin
        Results := Card.RunPageBackgroundTask(Codeunit::"LT QB Eval BgTask Worker", Params, false);
    end;
}

codeunit 86397 "LT QB Eval PageStyle"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure QB_Evaluate_PageStyle_InBgTask()
    var
        Observer: Codeunit "Probe Observer";
        Input: Text;
    begin
        foreach Input in 'Standard,StandardAccent,Strong,StrongAccent,Attention,AttentionAccent,Favorable,Unfavorable,Ambiguous,Subordinate,strong,0,9,Foo,99, '.Split(',') do
            Observer.Observe(Input, Run('PageStyle', Input));
        Observer.Finish();
    end;

    local procedure Run(TypeName: Text; Input: Text): Text
    var
        Card: TestPage "LT CN BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        K: Text;
        Result: Text;
    begin
        Params.Add('Type', TypeName);
        Params.Add('Input', Input);
        Card.OpenView();
        ClearLastError();
        if TryRun(Card, Params, Results) then begin
            foreach K in Results.Keys() do
                Result += K + '=' + Results.Get(K) + ';';
        end else
            Result := 'error: ' + GetLastErrorText() + ' | ' + GetLastErrorCode();
        Card.Close();
        exit(Result);
    end;

    [TryFunction]
    local procedure TryRun(var Card: TestPage "LT CN BgTask Card"; Params: Dictionary of [Text, Text]; var Results: Dictionary of [Text, Text])
    begin
        Results := Card.RunPageBackgroundTask(Codeunit::"LT QB Eval BgTask Worker", Params, false);
    end;
}

codeunit 86398 "LT QB Eval PbtErrorLevel"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure QB_Evaluate_PageBackgroundTaskErrorLevel_InBgTask()
    var
        Observer: Codeunit "Probe Observer";
        Input: Text;
    begin
        foreach Input in 'Ignore,Warning,Error,warning,0,2,Foo,99, '.Split(',') do
            Observer.Observe(Input, Run('PageBackgroundTaskErrorLevel', Input));
        Observer.Finish();
    end;

    local procedure Run(TypeName: Text; Input: Text): Text
    var
        Card: TestPage "LT CN BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        K: Text;
        Result: Text;
    begin
        Params.Add('Type', TypeName);
        Params.Add('Input', Input);
        Card.OpenView();
        ClearLastError();
        if TryRun(Card, Params, Results) then begin
            foreach K in Results.Keys() do
                Result += K + '=' + Results.Get(K) + ';';
        end else
            Result := 'error: ' + GetLastErrorText() + ' | ' + GetLastErrorCode();
        Card.Close();
        exit(Result);
    end;

    [TryFunction]
    local procedure TryRun(var Card: TestPage "LT CN BgTask Card"; Params: Dictionary of [Text, Text]; var Results: Dictionary of [Text, Text])
    begin
        Results := Card.RunPageBackgroundTask(Codeunit::"LT QB Eval BgTask Worker", Params, false);
    end;
}
