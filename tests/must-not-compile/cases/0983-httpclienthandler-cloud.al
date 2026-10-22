// @expect AL0296 | The application object or method 'HttpClientHandler' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// The HttpClientHandler attribute in a Cloud app (it has scope OnPrem).
codeunit 59075 "MNC HttpHandler 0983"
{
    Subtype = Test;

    [HttpClientHandler]
    procedure Handler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
    end;
}
