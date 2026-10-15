// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-testhttprequestpolicy-property
// Scope: in-scope (OnPrem app: the [HttpClientHandler] attribute is Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61298
// Probe: written against a real BC 29.0 service tier (29.0.54011.55816). Other BC versions were not measured.
//
// TestHttpRequestPolicy = BlockOutboundRequests: a request with no handler raises "Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to
// 'BlockOutboundRequests'. Please ensure that an HTTP client handler is configured." (code TestCodeunitUnhandledHttpRequest); with a handler the request is answered.
// BC versions: 29.0
codeunit 61298 "PZ Http Block"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    [TryFunction]
    local procedure TryGet(Url: Text)
    var
        Client: HttpClient;
        Resp: HttpResponseMessage;
    begin
        if not Client.Get(Url, Resp) then
            Error('get returned false');
    end;

    [HttpClientHandler]
    procedure Handler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.HttpStatusCode := 202;
    end;

    [Test]
    procedure NoHandler_UnderBlockOutboundRequests()
    var
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Ok := TryGet('https://example.invalid/blocked');
        Observer.Observe('no_handler', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('no_handler', 'No Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.|TestCodeunitUnhandledHttpRequest');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('Handler')]
    procedure Handler_UnderBlockOutboundRequests_StillAnswers()
    var
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Ok := TryGet('https://example.invalid/handled');
        Observer.Observe('handled', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
#if BC29PLUS
        Observer.Expect('handled', 'Yes |');
#else
        Observer.Expect('handled', 'No Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.|TestCodeunitUnhandledHttpRequest');
#endif
        Observer.Verify();
    end;
}
