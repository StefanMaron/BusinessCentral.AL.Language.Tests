// @expect AL0241 | The signature of procedure 'Handler' does not match the signature required by attribute 'HttpClientHandler'. The expected signature is: Handler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage) IssueOriginalRequest: Boolean.
// @target OnPrem
// An HttpClientHandler procedure without parameters.
codeunit 59080 "MNC HttpHandlerSig 0984"
{
    Subtype = Test;

    [HttpClientHandler]
    procedure Handler()
    begin
    end;
}
