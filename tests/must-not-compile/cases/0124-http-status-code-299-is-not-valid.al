// @expect AL0883 | The value '299' is not a valid HTTP status code.
// @target OnPrem
// A TestHttpResponseMessage status code is checked at compile time: 299 is not an HTTP status code.
codeunit 50990 "MNC Http Status 299"
{
    Subtype = Test;

    [HttpClientHandler]
    procedure Handler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.HttpStatusCode := 299;
    end;
}
