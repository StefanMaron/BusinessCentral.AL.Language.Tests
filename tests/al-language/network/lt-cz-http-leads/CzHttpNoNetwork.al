// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpclient/httpclient-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 85600
// Leads: corpus issue #671 (Http Content codeunit Create(SecretText); DefaultRequestHeaders reference kept across UseServerCertificateValidation).
// No request leaves the machine (TestHttpRequestPolicy = BlockOutboundRequests).
codeunit 85600 "LT CZ Http No Network"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    local procedure Sec(Value: Text) Result: SecretText
    begin
        Result := Value;
    end;

    local procedure DescribeContent(Content: HttpContent): Text
    var
        Headers: HttpHeaders;
        Values: List of [Text];
        Body: Text;
        CT: Text;
        SecretBody: SecretText;
    begin
        if Content.IsSecretContent() then begin
            Content.ReadAs(SecretBody);
            Body := '<secret empty=' + Format(SecretBody.IsEmpty()) + '>';
        end else
            Content.ReadAs(Body);
        Content.GetHeaders(Headers);
        if Headers.GetValues('Content-Type', Values) then
            CT := Values.Get(1);
        exit('body=[' + Body + '] type=[' + CT + '] secret=' + Format(Content.IsSecretContent()));
    end;

    [TryFunction]
    local procedure TryCreateSecret(Value: SecretText; var Result: Text)
    var
        HttpContent: Codeunit "Http Content";
    begin
        Result := DescribeContent(HttpContent.Create(Value).GetHttpContent());
    end;

    [TryFunction]
    local procedure TryCreateSecretWithType(Value: SecretText; ContentType: Text; var Result: Text)
    var
        HttpContent: Codeunit "Http Content";
    begin
        Result := DescribeContent(HttpContent.Create(Value, ContentType).GetHttpContent());
    end;

    [Test]
    procedure HttpContentCodeunit_CreateFromSecretText()
    var
        Observer: Codeunit "Probe Observer";
        HttpContent: Codeunit "Http Content";
        Result: Text;
    begin
        Observer.Observe('secret_ok', Format(TryCreateSecret(Sec('test'), Result)));
        Observer.Observe('secret_result', Result);
        Observer.ObserveError('secret_err');
        Result := '';
        Observer.Observe('secret_type_ok', Format(TryCreateSecretWithType(Sec('test'), 'application/json', Result)));
        Observer.Observe('secret_type_result', Result);
        Observer.ObserveError('secret_type_err');
        Result := '';
        Observer.Observe('secret_type_empty_ok', Format(TryCreateSecretWithType(Sec('test'), '', Result)));
        Observer.Observe('secret_type_empty_result', Result);
        Observer.ObserveError('secret_type_empty_err');
        Observer.Observe('text', DescribeContent(HttpContent.Create('test').GetHttpContent()));
        Observer.Finish();
    end;

    [Test]
    procedure DefaultRequestHeaders_ReferenceKept_AcrossUseServerCertificateValidation()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Headers: HttpHeaders;
        Other: HttpHeaders;
    begin
        Headers := Client.DefaultRequestHeaders();
        Client.UseServerCertificateValidation(false);
        Headers.Add('X-Test', '1');
        Observer.Observe('client_sees_after_false', Format(Client.DefaultRequestHeaders().Contains('X-Test')));
        Observer.Observe('ref_sees', Format(Headers.Contains('X-Test')));
        Other := Client.DefaultRequestHeaders();
        Client.UseServerCertificateValidation(true);
        Other.Add('X-Two', '2');
        Observer.Observe('client_sees_after_true', Format(Client.DefaultRequestHeaders().Contains('X-Two')));
        Observer.Observe('client_keeps_first', Format(Client.DefaultRequestHeaders().Contains('X-Test')));
        Observer.Observe('keys', Format(Client.DefaultRequestHeaders().Keys().Count()));
        Observer.Finish();
    end;

    [Test]
    procedure DefaultRequestHeaders_Reference_ValidationTrueOnFreshClient()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Headers: HttpHeaders;
    begin
        Headers := Client.DefaultRequestHeaders();
        Client.UseServerCertificateValidation(true);
        Headers.Add('X-Test', '1');
        Observer.Observe('client_sees_after_true', Format(Client.DefaultRequestHeaders().Contains('X-Test')));
        Headers := Client.DefaultRequestHeaders();
        Client.UseServerCertificateValidation(false);
        Client.UseServerCertificateValidation(false);
        Headers.Add('X-Again', '1');
        Observer.Observe('client_sees_after_false_twice', Format(Client.DefaultRequestHeaders().Contains('X-Again')));
        Client.DefaultRequestHeaders().Add('X-Direct', '1');
        Observer.Observe('direct_add_after_false', Format(Client.DefaultRequestHeaders().Contains('X-Direct')));
        Observer.Finish();
    end;
}
