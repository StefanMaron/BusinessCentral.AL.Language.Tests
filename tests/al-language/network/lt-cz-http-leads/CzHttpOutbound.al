// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpclient/httpclient-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 85601
// Leads: corpus issue #671 (HTTP client, requests and responses). These tests make real outbound requests (no TestHttpRequestPolicy).
codeunit 85601 "LT CZ Http Outbound"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Prompts: Integer;

    [StrMenuHandler]
    procedure AllowOnceHandler(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Prompts += 1;
        Choice := 2; // "Allow Once" -- the outbound-connection approval prompt
    end;

    local procedure Sec(Value: Text) Result: SecretText
    begin
        Result := Value;
    end;

    local procedure Short(Value: Text): Text
    begin
        exit(CopyStr(Value, 1, 300));
    end;

    [TryFunction]
    local procedure TryGet(var Client: HttpClient; Url: Text; var Resp: HttpResponseMessage; var Ok: Boolean)
    begin
        Ok := Client.Get(Url, Resp);
    end;

    [TryFunction]
    local procedure TrySend(var Client: HttpClient; var Req: HttpRequestMessage; var Resp: HttpResponseMessage; var Ok: Boolean)
    begin
        Ok := Client.Send(Req, Resp);
    end;

    local procedure GetOutcome(var Client: HttpClient; Url: Text): Text
    var
        Resp: HttpResponseMessage;
        Ok: Boolean;
        Raised: Boolean;
        Err: Text;
    begin
        ClearLastError();
        Raised := not TryGet(Client, Url, Resp, Ok);
        Err := GetLastErrorText();
        exit('raised=' + Format(Raised) + ' ok=' + Format(Ok) + ' status=' + Format(Resp.HttpStatusCode) + ' blocked=' + Format(Resp.IsBlockedByEnvironment) + ' err=[' + Short(Err) + '] code=[' + GetLastErrorCode() + ']');
    end;

    local procedure SendOutcome(var Client: HttpClient; var Req: HttpRequestMessage): Text
    var
        Resp: HttpResponseMessage;
        Ok: Boolean;
        Raised: Boolean;
        Err: Text;
    begin
        ClearLastError();
        Raised := not TrySend(Client, Req, Resp, Ok);
        Err := GetLastErrorText();
        exit('raised=' + Format(Raised) + ' ok=' + Format(Ok) + ' status=' + Format(Resp.HttpStatusCode) + ' blocked=' + Format(Resp.IsBlockedByEnvironment) + ' err=[' + Short(Err) + '] code=[' + GetLastErrorCode() + ']');
    end;

    [Test]
    [HandlerFunctions('AllowOnceHandler')]
    procedure InternalAddresses()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
    begin
        Prompts := 0;
        Client.Timeout := 5000;
        Observer.Observe('loopback', GetOutcome(Client, 'http://127.0.0.1:1/'));
        Observer.Observe('localhost', GetOutcome(Client, 'http://localhost:1/'));
        Observer.Observe('loopback_other', GetOutcome(Client, 'http://127.10.20.30/'));
        Observer.Observe('ipv6_loopback', GetOutcome(Client, 'http://[::1]:1/'));
        Observer.Observe('ten', GetOutcome(Client, 'http://10.255.255.1/'));
        Observer.Observe('lan', GetOutcome(Client, 'http://192.168.255.1/'));
        Observer.Observe('lan172', GetOutcome(Client, 'http://172.16.255.1/'));
        Observer.Observe('imds', GetOutcome(Client, 'http://169.254.169.254/metadata/instance'));
        Observer.Observe('zero', GetOutcome(Client, 'http://0.0.0.0:1/'));
        Observer.Observe('prompts', Format(Prompts));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('AllowOnceHandler')]
    procedure CertificateValidation()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Loose: HttpClient;
    begin
        Prompts := 0;
        Observer.Observe('expired', GetOutcome(Client, 'https://expired.badssl.com/'));
        Observer.Observe('wrong_host', GetOutcome(Client, 'https://wrong.host.badssl.com/'));
        Observer.Observe('self_signed', GetOutcome(Client, 'https://self-signed.badssl.com/'));
        Observer.Observe('good', GetOutcome(Client, 'https://badssl.com/'));
        Loose.UseServerCertificateValidation(false);
        Observer.Observe('off_expired', GetOutcome(Loose, 'https://expired.badssl.com/'));
        Observer.Observe('off_wrong_host', GetOutcome(Loose, 'https://wrong.host.badssl.com/'));
        Observer.Observe('off_self_signed', GetOutcome(Loose, 'https://self-signed.badssl.com/'));
        Observer.Observe('prompts', Format(Prompts));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('AllowOnceHandler')]
    procedure GetAndDeleteWithBody()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Req: HttpRequestMessage;
        Req2: HttpRequestMessage;
        Req3: HttpRequestMessage;
        Content: HttpContent;
        Content2: HttpContent;
        Content3: HttpContent;
        Headers: HttpHeaders;
    begin
        Content.WriteFrom('{}');
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');
        Req.Method := 'GET';
        Req.SetRequestUri('https://example.com/');
        Req.Content := Content;
        Observer.Observe('get_body', SendOutcome(Client, Req));
        Content2.WriteFrom('{}');
        Req2.Method := 'DELETE';
        Req2.SetRequestUri('https://example.com/');
        Req2.Content := Content2;
        Observer.Observe('delete_body', SendOutcome(Client, Req2));
        Content3.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');
        Req3.Method := 'GET';
        Req3.SetRequestUri('https://example.com/');
        Req3.Content := Content3;
        Observer.Observe('get_headers_no_body', SendOutcome(Client, Req3));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('AllowOnceHandler')]
    procedure SameRequestMessageSentTwice()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Req: HttpRequestMessage;
    begin
        Req.Method := 'GET';
        Req.SetRequestUri('https://example.com/');
        Observer.Observe('first', SendOutcome(Client, Req));
        Observer.Observe('second_same_uri', SendOutcome(Client, Req));
        Req.SetRequestUri('https://example.com/other');
        Observer.Observe('third_new_uri', SendOutcome(Client, Req));
        Observer.Observe('uri_after', Req.GetRequestUri());
        Observer.Finish();
    end;

    local procedure GetInto(var Response: HttpResponseMessage): Boolean
    var
        Client: HttpClient;
    begin
        exit(Client.Get('https://example.com/', Response));
    end;

    [Test]
    [HandlerFunctions('AllowOnceHandler')]
    procedure ResponseFilledInCallee_ReadInCaller()
    var
        Observer: Codeunit "Probe Observer";
        Response: HttpResponseMessage;
        Body: Text;
    begin
        Observer.Observe('ok', Format(GetInto(Response)));
        Observer.Observe('status', Format(Response.HttpStatusCode));
        Response.Content.ReadAs(Body);
        Observer.Observe('has_body', Format(Body.Contains('Example Domain')));
        Body := '';
        Response.Content.ReadAs(Body);
        Observer.Observe('second_read_has_body', Format(Body.Contains('Example Domain')));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('AllowOnceHandler')]
    procedure EchoedRequestHeaders()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Headers: HttpHeaders;
        Resp: HttpResponseMessage;
        Body: Text;
    begin
        Headers := Client.DefaultRequestHeaders();
        Client.UseServerCertificateValidation(false);
        Headers.Add('X-Test', '1');
        Observer.Observe('ok', Format(Client.Get('https://httpbin.org/headers', Resp)));
        Observer.Observe('status', Format(Resp.HttpStatusCode));
        Resp.Content.ReadAs(Body);
        Observer.Observe('body', Short(Body));
        Observer.Observe('baggage', Format(Body.ToLower().Contains('"baggage"')));
        Observer.Observe('traceparent', Format(Body.ToLower().Contains('"traceparent"')));
        Observer.Observe('x_test', Format(Body.ToLower().Contains('"x-test": "1"')));
        Observer.Finish();
    end;

    local procedure EchoHasAuth(var Client: HttpClient; Url: Text): Text
    var
        Resp: HttpResponseMessage;
        Body: Text;
        Ok: Boolean;
    begin
        Ok := Client.Get(Url, Resp);
        Resp.Content.ReadAs(Body);
        exit('ok=' + Format(Ok) + ' status=' + Format(Resp.HttpStatusCode) + ' auth=' + Format(Body.Contains('"Authorization": "Bearer visible"')));
    end;

    [Test]
    [HandlerFunctions('AllowOnceHandler')]
    procedure Redirects()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
    begin
        Observer.Observe('http_github', GetOutcome(Client, 'http://github.com/'));
        Observer.Observe('httpbin_302', GetOutcome(Client, 'https://httpbin.org/redirect-to?url=https%3A%2F%2Fexample.com%2F&status_code=302'));
        Observer.Observe('httpbin_307', GetOutcome(Client, 'https://httpbin.org/redirect-to?url=https%3A%2F%2Fexample.com%2F&status_code=307'));
        Observer.Observe('httpbin_308', GetOutcome(Client, 'https://httpbin.org/redirect-to?url=https%3A%2F%2Fexample.com%2F&status_code=308'));
        Client.DefaultRequestHeaders().Add('Authorization', 'Bearer visible');
        Observer.Observe('auth_direct', EchoHasAuth(Client, 'https://httpbin.org/headers'));
        Observer.Observe('auth_after_302_same_host', EchoHasAuth(Client, 'https://httpbin.org/redirect-to?url=https%3A%2F%2Fhttpbin.org%2Fheaders&status_code=302'));
        Observer.Observe('auth_after_307_same_host', EchoHasAuth(Client, 'https://httpbin.org/redirect-to?url=https%3A%2F%2Fhttpbin.org%2Fheaders&status_code=307'));
        Observer.Observe('httpbin_301', GetOutcome(Client, 'https://httpbin.org/redirect-to?url=https%3A%2F%2Fexample.com%2F&status_code=301'));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('AllowOnceHandler')]
    procedure SecretDefaultHeader_AfterSend()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Req: HttpRequestMessage;
        Resp: HttpResponseMessage;
        H: HttpHeaders;
        Values: List of [Text];
        Secrets: List of [SecretText];
    begin
        Client.DefaultRequestHeaders().Add('Authorization', Sec('Bearer abc'));
        Observer.Observe('client_before_secret', Format(Client.DefaultRequestHeaders().ContainsSecret('Authorization')));
        Req.Method := 'GET';
        Req.SetRequestUri('https://example.com/');
        Observer.Observe('send', Format(Client.Send(Req, Resp)));
        Req.GetHeaders(H);
        Observer.Observe('req_contains', Format(H.Contains('Authorization')));
        Observer.Observe('req_contains_secret', Format(H.ContainsSecret('Authorization')));
        if H.GetValues('Authorization', Values) then
            Observer.Observe('req_values', Format(Values.Count()) + ' [' + Values.Get(1) + ']')
        else
            Observer.Observe('req_values', 'none');
        Observer.Observe('req_secret_values', Format(H.GetSecretValues('Authorization', Secrets)) + ' ' + Format(Secrets.Count()));
        Observer.Observe('client_after_secret', Format(Client.DefaultRequestHeaders().ContainsSecret('Authorization')));
        Observer.Observe('client_after_plain', Format(Client.DefaultRequestHeaders().Contains('Authorization')));
        Observer.Finish();
    end;
}
