// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-httpclient-mock-outbound-calls
// Scope: in-scope (OnPrem app: the [HttpClientHandler] attribute and TestHttpRequestMessage / TestHttpResponseMessage are Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; own codeunit 98550
// Probe: observe probe; every literal asserted below is what the corpus CI service tiers produced.
// Facts: the Request.Path an [HttpClientHandler] sees for HttpClient.SetBaseAddress('https://example.invalid/api/v1/') followed by Get of 'orders',
// '/orders', '../x' and '?q=1', and for Get without a base address of 'a/b', 'a.b' and '?q=1'; a handler that sets only status 404 (reason phrase,
// IsSuccessStatusCode, the Boolean of Get); a handler that raises an error (what the caller sees); a handler that answers true (fall through to the
// real network) for a host that resolves but refuses the connection (http://localhost:1): the Boolean, the status code and GetLastErrorText.
// On BC 27 and 28 a request is not given to the handler (PZHttpHandler.al): those legs pin what the caller sees there.
// BC versions: 27, 28, 29 (corpus CI)

codeunit 98550 "LT AY Http Handler"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = AllowOutboundFromHandler;

    var
        Seen: Text;
        Calls: Integer;

    [HttpClientHandler]
    procedure PathHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        Params: Dictionary of [Text, Text];
        ParamName: Text;
    begin
        Calls += 1;
        Seen += '[' + Request.Path + ']';
        Params := Request.QueryParameters;
        foreach ParamName in Params.Keys() do
            Seen += ParamName + '=' + Params.Get(ParamName) + '&';
        Response.HttpStatusCode := 200;
        exit(false);
    end;

    [HttpClientHandler]
    procedure NotFoundHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Calls += 1;
        Response.HttpStatusCode := 404;
        exit(false);
    end;

    [HttpClientHandler]
    procedure ErrorHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Calls += 1;
        Error('handler failed');
    end;

    [HttpClientHandler]
    procedure FallThroughHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Calls += 1;
        Response.HttpStatusCode := 202;
        exit(true);
    end;

    [TryFunction]
    local procedure TryGet(var Client: HttpClient; Url: Text; var Resp: HttpResponseMessage; var Ret: Boolean)
    begin
        Ret := Client.Get(Url, Resp);
    end;

    local procedure Path(var Observer: Codeunit "Probe Observer"; var Client: HttpClient; ObsKey: Text; Url: Text)
    var
        Resp: HttpResponseMessage;
        Ret: Boolean;
    begin
        Seen := '';
        ClearLastError();
        if TryGet(Client, Url, Resp, Ret) then
            Observer.Observe(ObsKey, Format(Ret) + ' ' + Seen)
        else
            Observer.Observe(ObsKey, 'E[' + CopyStr(GetLastErrorText(), 1, 70) + '|' + GetLastErrorCode() + '] ' + Seen);
    end;

    local procedure Outcome(var Observer: Codeunit "Probe Observer"; Url: Text)
    var
        Client: HttpClient;
        Resp: HttpResponseMessage;
        Ret: Boolean;
    begin
        Calls := 0;
        ClearLastError();
        if TryGet(Client, Url, Resp, Ret) then
            Observer.Observe('result', 'ret=' + Format(Ret) + ' status=' + Format(Resp.HttpStatusCode) + ' reason=[' + Resp.ReasonPhrase + '] success=' + Format(Resp.IsSuccessStatusCode) + ' blocked=' + Format(Resp.IsBlockedByEnvironment))
        else
            Observer.Observe('result', 'error status=' + Format(Resp.HttpStatusCode));
        Observer.Observe('last_error', GetLastErrorText());
        Observer.Observe('last_code', GetLastErrorCode());
        Observer.Observe('calls', Format(Calls));
    end;

    [Test]
    [HandlerFunctions('PathHandler')]
    procedure BaseAddress_RelativePaths_1()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
    begin
        Client.SetBaseAddress('https://example.invalid/api/v1/');
        Path(Observer, Client, 'plain', 'orders');
        Path(Observer, Client, 'rooted', '/orders');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PathHandler')]
    procedure BaseAddress_RelativePaths_2()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
    begin
        Client.SetBaseAddress('https://example.invalid/api/v1/');
        Path(Observer, Client, 'parent', '../x');
        Path(Observer, Client, 'query', '?q=1');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PathHandler')]
    procedure NoBaseAddress_RelativePaths_1()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
    begin
        Path(Observer, Client, 'a_slash_b', 'a/b');
        Path(Observer, Client, 'a_dot_b', 'a.b');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PathHandler')]
    procedure NoBaseAddress_RelativePaths_2()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
    begin
        Path(Observer, Client, 'query', '?q=1');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('NotFoundHandler')]
    procedure Handler_OnlyStatus404()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, 'https://example.invalid/missing');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ErrorHandler')]
    procedure Handler_RaisesError()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, 'https://example.invalid/boom');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('FallThroughHandler')]
    procedure Handler_FallThrough_ConnectionRefused()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, 'http://localhost:1/x');
        Observer.Finish();
    end;
}
