// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/properties/devenv-testhttprequestpolicy-property
// Scope: in-scope (OnPrem app: the [HttpClientHandler] attribute and TestHttpRequestMessage / TestHttpResponseMessage are Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; own codeunits 98700 and 98701
// Probe: observe probe (writer PY, 2026-10-20); every literal asserted below is what the corpus CI service tiers produced.
// Facts: an [HttpClientHandler] under the default policy (no TestHttpRequestPolicy property, codeunit 98700) and under AllowAllOutboundRequests
// (codeunit 98701): a request with no handler, a handler answering false (mocked response) and true (real request to http://localhost:1, which
// refuses the connection), with and without a StrMenuHandler bound (Allow Once = 2, Block Once = 4; Allow Always and Block Always are not used
// because they would store a setting for later tests), and a failed call whose result is not used. AyHttpHandler.al pins AllowOutboundFromHandler,
// PZHttpBlock.al BlockOutboundRequests.
// BC versions: 27, 28, 29 (corpus CI)

codeunit 98700 "LT PY Http Default Policy"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Calls: Integer;
        Mode: Text;
        MenuChoice: Integer;
        MenuCalls: Integer;
        MenuSeen: Text;

    [HttpClientHandler]
    procedure ModeHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Calls += 1;
        if Mode = 'true' then
            exit(true);
        Response.HttpStatusCode := 201;
        Response.ReasonPhrase := 'Mocked';
        exit(false);
    end;

    [StrMenuHandler]
    procedure MenuHandler(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        MenuCalls += 1;
        MenuSeen := Options + '|' + Instruction;
        Choice := MenuChoice;
    end;

    [TryFunction]
    local procedure TryGet(Url: Text; var Resp: HttpResponseMessage; var Ret: Boolean)
    var
        Client: HttpClient;
    begin
        Ret := Client.Get(Url, Resp);
    end;

    [TryFunction]
    local procedure TryGetStatement(Url: Text; var Resp: HttpResponseMessage)
    var
        Client: HttpClient;
    begin
        Client.Get(Url, Resp);
    end;

    local procedure Describe(var Resp: HttpResponseMessage): Text
    begin
        exit('status=' + Format(Resp.HttpStatusCode) + ' reason=[' + Resp.ReasonPhrase + '] success=' + Format(Resp.IsSuccessStatusCode) + ' blocked=' + Format(Resp.IsBlockedByEnvironment));
    end;

    local procedure Outcome(var Observer: Codeunit "Probe Observer"; NewMode: Text; Choice: Integer; Url: Text)
    var
        Resp: HttpResponseMessage;
        Ret: Boolean;
    begin
        Mode := NewMode;
        MenuChoice := Choice;
        Calls := 0;
        MenuCalls := 0;
        MenuSeen := '';
        ClearLastError();
        if TryGet(Url, Resp, Ret) then
            Observer.Observe('result', 'ret=' + Format(Ret) + ' ' + Describe(Resp))
        else
            Observer.Observe('result', 'error ' + Describe(Resp));
        Observer.Observe('last_error', GetLastErrorText());
        Observer.Observe('last_code', GetLastErrorCode());
        Observer.Observe('calls', Format(Calls) + ' menu=' + Format(MenuCalls) + ' ' + MenuSeen);
    end;

    [Test]
    procedure NoHandler_ConnectionRefused()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, '', 0, 'http://localhost:1/x');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MenuHandler')]
    procedure NoHandler_StrMenuAllowOnce_ConnectionRefused()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, '', 2, 'http://localhost:1/x');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure Handler_AnswersFalse_Mocked()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, 'false', 0, 'https://example.invalid/mocked');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure Handler_AnswersTrue_NoStrMenu()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, 'true', 0, 'http://localhost:1/x');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ModeHandler,MenuHandler')]
    procedure Handler_AnswersTrue_StrMenuAllowOnce()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, 'true', 2, 'http://localhost:1/x');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ModeHandler,MenuHandler')]
    procedure Handler_AnswersTrue_StrMenuBlockOnce()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, 'true', 4, 'http://localhost:1/x');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ModeHandler,MenuHandler')]
    procedure Handler_UnusedResult_BlockOnce()
    var
        Observer: Codeunit "Probe Observer";
        Resp: HttpResponseMessage;
    begin
        Mode := 'true';
        MenuChoice := 4;
        ClearLastError();
        Observer.Observe('statement', Format(TryGetStatement('http://localhost:1/x', Resp)) + ' [' + GetLastErrorText() + '|' + GetLastErrorCode() + '] ' + Describe(Resp) + ' calls=' + Format(Calls) + ' menu=' + Format(MenuCalls));
        Observer.Finish();
    end;
}

codeunit 98701 "LT PY Http Allow All"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = AllowAllOutboundRequests;

    var
        Calls: Integer;
        Mode: Text;
        MenuChoice: Integer;
        MenuCalls: Integer;
        MenuSeen: Text;

    [HttpClientHandler]
    procedure ModeHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Calls += 1;
        if Mode = 'true' then
            exit(true);
        Response.HttpStatusCode := 201;
        Response.ReasonPhrase := 'Mocked';
        exit(false);
    end;

    [StrMenuHandler]
    procedure MenuHandler(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        MenuCalls += 1;
        MenuSeen := Options + '|' + Instruction;
        Choice := MenuChoice;
    end;

    [TryFunction]
    local procedure TryGet(Url: Text; var Resp: HttpResponseMessage; var Ret: Boolean)
    var
        Client: HttpClient;
    begin
        Ret := Client.Get(Url, Resp);
    end;

    [TryFunction]
    local procedure TryGetStatement(Url: Text; var Resp: HttpResponseMessage)
    var
        Client: HttpClient;
    begin
        Client.Get(Url, Resp);
    end;

    local procedure Describe(var Resp: HttpResponseMessage): Text
    begin
        exit('status=' + Format(Resp.HttpStatusCode) + ' reason=[' + Resp.ReasonPhrase + '] success=' + Format(Resp.IsSuccessStatusCode) + ' blocked=' + Format(Resp.IsBlockedByEnvironment));
    end;

    local procedure Outcome(var Observer: Codeunit "Probe Observer"; NewMode: Text; Choice: Integer; Url: Text)
    var
        Resp: HttpResponseMessage;
        Ret: Boolean;
    begin
        Mode := NewMode;
        MenuChoice := Choice;
        Calls := 0;
        MenuCalls := 0;
        MenuSeen := '';
        ClearLastError();
        if TryGet(Url, Resp, Ret) then
            Observer.Observe('result', 'ret=' + Format(Ret) + ' ' + Describe(Resp))
        else
            Observer.Observe('result', 'error ' + Describe(Resp));
        Observer.Observe('last_error', GetLastErrorText());
        Observer.Observe('last_code', GetLastErrorCode());
        Observer.Observe('calls', Format(Calls) + ' menu=' + Format(MenuCalls) + ' ' + MenuSeen);
    end;

    [Test]
    procedure NoHandler_ConnectionRefused()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, '', 0, 'http://localhost:1/x');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MenuHandler')]
    procedure NoHandler_StrMenuAllowOnce_ConnectionRefused()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, '', 2, 'http://localhost:1/x');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure Handler_AnswersFalse_Mocked()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, 'false', 0, 'https://example.invalid/mocked');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure Handler_AnswersTrue_NoStrMenu()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, 'true', 0, 'http://localhost:1/x');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ModeHandler,MenuHandler')]
    procedure Handler_AnswersTrue_StrMenuAllowOnce()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, 'true', 2, 'http://localhost:1/x');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ModeHandler,MenuHandler')]
    procedure Handler_AnswersTrue_StrMenuBlockOnce()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, 'true', 4, 'http://localhost:1/x');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ModeHandler,MenuHandler')]
    procedure Handler_UnusedResult_BlockOnce()
    var
        Observer: Codeunit "Probe Observer";
        Resp: HttpResponseMessage;
    begin
        Mode := 'true';
        MenuChoice := 4;
        ClearLastError();
        Observer.Observe('statement', Format(TryGetStatement('http://localhost:1/x', Resp)) + ' [' + GetLastErrorText() + '|' + GetLastErrorCode() + '] ' + Describe(Resp) + ' calls=' + Format(Calls) + ' menu=' + Format(MenuCalls));
        Observer.Finish();
    end;
}
