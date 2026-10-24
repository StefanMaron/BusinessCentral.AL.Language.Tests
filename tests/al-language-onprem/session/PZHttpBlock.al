// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-testhttprequestpolicy-property
// Scope: in-scope (OnPrem app: the [HttpClientHandler] attribute is Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61298
// Probe: written against a real BC 29.0 service tier (29.0.54011.55816). BC 27.5 and 28.5: Windows service tiers (Windows check 2026-10-22).
//
// TestHttpRequestPolicy = BlockOutboundRequests: a request with no handler raises "Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to
// 'BlockOutboundRequests'. Please ensure that an HTTP client handler is configured." (code TestCodeunitUnhandledHttpRequest); with a handler the request is answered.
// BC versions: 27-29 (the handler answers on Windows 27.5 and 28.5 too)
codeunit 61298 "PZ Http Block"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        MockCalls: Integer;

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
        // BC 27.5 and 28.5 on Windows call the handler too (Windows check 2026-10-22, al-runner issue 5777).
        Observer.Expect('handled', 'Yes |');
        Observer.Verify();
    end;

    // ---- The shape of al-runner issue 5777: a mock handler that counts its calls, answers 200 with a body and returns false (the mock is used),
    // a handler that returns true (the request goes out, which BlockOutboundRequests refuses), and a GET that reads the status and the body.

    [HttpClientHandler]
    procedure MockHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        MockCalls += 1;
        Response.HttpStatusCode(200);
        Response.Content.WriteFrom('{"ok":true}');
        exit(false);
    end;

    [HttpClientHandler]
    procedure PassOnHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        MockCalls += 1;
        exit(true);
    end;

    local procedure GetStatusAndBody(Url: Text; var Status: Integer; var Body: Text): Boolean
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
    begin
        if not Client.Get(Url, Response) then
            exit(false);
        Status := Response.HttpStatusCode();
        Response.Content.ReadAs(Body);
        exit(true);
    end;

    [TryFunction]
    local procedure TryGetStatusAndBody(Url: Text; var Ok: Boolean; var Status: Integer; var Body: Text)
    begin
        Ok := GetStatusAndBody(Url, Status, Body);
    end;

    [Test]
    [HandlerFunctions('MockHandler')]
    procedure RS_MockHandler_ReturnsFalse_GivesTheMock()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
        Status: Integer;
        Body: Text;
    begin
        MockCalls := 0;
        ClearLastError();
        Observer.Observe('try', Format(TryGetStatusAndBody('https://api.example.com/v1/items?id=7', Ok, Status, Body)));
        Observer.Observe('result', StrSubstNo('%1|%2|%3|%4', Ok, Status, Body, MockCalls));
        Observer.Observe('error', GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PassOnHandler')]
    procedure RS_PassOnHandler_ReturnsTrue_UnderBlockOutboundRequests()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
        Status: Integer;
        Body: Text;
    begin
        MockCalls := 0;
        ClearLastError();
        Observer.Observe('try', Format(TryGetStatusAndBody('https://api.example.com/v1/items?id=7', Ok, Status, Body)));
        Observer.Observe('result', StrSubstNo('%1|%2|%3|%4', Ok, Status, Body, MockCalls));
        Observer.Observe('error', GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Finish();
    end;
}
