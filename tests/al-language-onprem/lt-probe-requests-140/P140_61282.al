// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-httpclient-mock-outbound-calls
// Scope: in-scope (OnPrem app: [HttpClientHandler] and TestHttpRequestMessage are Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61282
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
//  Only this machine is addressed: http://localhost:9/ and http://127.0.0.1:9/ (the host resolves, nothing listens on port 9: the connection is refused). No external traffic.
// BC versions: 29 (27, 28 not measured)
codeunit 61282 "LT P140 Block No Handler"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        Calls: Integer;
        SeenText: Text;
        LastOk: Boolean;

    local procedure Describe(Ok: Boolean; var Resp: HttpResponseMessage): Text
    var
        Body: Text;
    begin
        Resp.Content.ReadAs(Body);
        exit('ok=' + Format(Ok) + ' status=' + Format(Resp.HttpStatusCode) + ' reason=[' + Resp.ReasonPhrase + '] body=[' + Body + '] success=' + Format(Resp.IsSuccessStatusCode) + ' blocked=' + Format(Resp.IsBlockedByEnvironment));
    end;

    [TryFunction]
    local procedure TryGet(Url: Text; var Resp: HttpResponseMessage)
    var
        Client: HttpClient;
    begin
        LastOk := Client.Get(Url, Resp);
    end;

    [TryFunction]
    local procedure TrySend(Method: Text; Url: Text; var Resp: HttpResponseMessage)
    var
        Client: HttpClient;
        Req: HttpRequestMessage;
        Content: HttpContent;
    begin
        Req.Method := Method;
        Req.SetRequestUri(Url);
        if Method = 'POST' then begin
            Content.WriteFrom('payload');
            Req.Content := Content;
        end;
        LastOk := Client.Send(Req, Resp);
    end;

    local procedure ObserveOutcome(var Observer: Codeunit "Probe Observer"; Name: Text; Tried: Boolean; var Resp: HttpResponseMessage)
    begin
        Observer.Observe(Name + '_tryfunction', Format(Tried));
        if Tried then
            Observer.Observe(Name + '_response', Describe(LastOk, Resp))
        else
            Observer.Observe(Name + '_error', GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Observe(Name + '_lasterror_after', GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Observe(Name + '_handler_calls', Format(Calls));
        Observer.Observe(Name + '_handler_saw', SeenText);
        Calls := 0;
        SeenText := '';
        ClearLastError();
    end;

    [Test]
    procedure P140_NoHandler_Localhost_And_Loopback()
    var
        Resp: HttpResponseMessage;
        Tried: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Tried := TryGet('http://localhost:9/p140', Resp);
        ObserveOutcome(Observer, 'get_localhost', Tried, Resp);
        Tried := TrySend('POST', 'http://127.0.0.1:9/p140?a=1', Resp);
        ObserveOutcome(Observer, 'post_loopback', Tried, Resp);
        Observer.Expect('get_localhost_tryfunction', 'No');
        Observer.Expect('get_localhost_error', 'Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.|TestCodeunitUnhandledHttpRequest');
        Observer.Expect('get_localhost_lasterror_after', 'Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.|TestCodeunitUnhandledHttpRequest');
        Observer.Expect('get_localhost_handler_calls', '0');
        Observer.Expect('get_localhost_handler_saw', '');
        Observer.Expect('post_loopback_tryfunction', 'No');
        Observer.Expect('post_loopback_error', 'Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.|TestCodeunitUnhandledHttpRequest');
        Observer.Expect('post_loopback_lasterror_after', 'Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.|TestCodeunitUnhandledHttpRequest');
        Observer.Expect('post_loopback_handler_calls', '0');
        Observer.Expect('post_loopback_handler_saw', '');
        Observer.Verify();
    end;
}
