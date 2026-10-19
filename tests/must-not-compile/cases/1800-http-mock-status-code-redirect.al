// @expect AL0884 | The value '300' is outside the allowed range for mocked HTTP status codes. Redirect (3**) status codes are not permitted.
// @expect AL0884 | The value '304' is outside the allowed range for mocked HTTP status codes. Redirect (3**) status codes are not permitted.
// @target OnPrem
// A TestHttpResponseMessage status code is checked at compile time: a redirect code (300, 304) is refused with AL0884, not AL0883.
// Lead: corpus issue #671 (mocked HTTP status codes AL0883 and AL0884). The same on BC 27, 28 and 29.
codeunit 51800 "MNC Http Status Redirect"
{
    Subtype = Test;

    [HttpClientHandler]
    procedure Handler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.HttpStatusCode := 300;
        Response.HttpStatusCode := 304;
    end;
}
