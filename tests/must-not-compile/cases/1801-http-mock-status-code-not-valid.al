// @expect AL0883 | The value '399' is not a valid HTTP status code.
// @expect AL0883 | The value '99' is not a valid HTTP status code.
// @expect AL0883 | The value '600' is not a valid HTTP status code.
// @expect AL0883 | The value '599' is not a valid HTTP status code.
// @expect AL0883 | The value '0' is not a valid HTTP status code.
// @target OnPrem
// A TestHttpResponseMessage status code is checked at compile time: 399 is in the redirect range but is not a known code, so it gets AL0883
// (not AL0884); 99, 600, 599 and 0 are not HTTP status codes either. 100 and 200 compile. Lead: corpus issue #671. The same on BC 27, 28 and 29.
codeunit 51801 "MNC Http Status Not Valid"
{
    Subtype = Test;

    [HttpClientHandler]
    procedure Handler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.HttpStatusCode := 399;
        Response.HttpStatusCode := 99;
        Response.HttpStatusCode := 600;
        Response.HttpStatusCode := 599;
        Response.HttpStatusCode := 0;
        Response.HttpStatusCode := 100;
        Response.HttpStatusCode := 200;
    end;
}
