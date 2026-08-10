// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/
//   dev-itpro/developer/methods-auto/httpclient/httpclient-data-type
// Scope: in-scope (Cloud-compatible)
// Fixtures used: none
// BC versions: 27.5+
//
// CLAIM: outbound HTTP is allowed from AL in BC Cloud. HttpClient.Get does not throw
// for a reachable endpoint -- it was previously assumed (wrongly) to be out-of-scope
// and tested as a throwing call; the real Cloud sandbox lets it through.
//
// The first outbound call to a host in a session raises the platform's own
// connection-approval prompt (StrMenu: Allow Always/Allow Once/Block Always/Block
// Once) -- observed on BC 27.5, not on BC 28.3 (already pre-approved there). A
// [StrMenuHandler] answers it; without one, the call surfaces as "Unhandled UI"
// instead of exercising HttpClient at all.

codeunit 60874 "Test HttpClient"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;

    [Test]
    [HandlerFunctions('AllowOnceHandler')]
    procedure HttpClient_Get_ValidUrl_ReturnsSuccessResponse()
    var
        Client: HttpClient;
        Resp: HttpResponseMessage;
    begin
        Client.Get('http://example.com', Resp);

        Assert.IsTrue(Resp.IsSuccessStatusCode(), 'HttpClient.Get must succeed against a reachable URL in Cloud');
    end;

    [StrMenuHandler]
    procedure AllowOnceHandler(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Choice := 2; // "Allow Once" -- the outbound-connection approval prompt
    end;
}
