// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT P87 Helper (codeunit 74228)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a header added twice (same value, different value, different case), GetValues count, Keys count
// BC versions: 29 (27 and 28 by CI)

codeunit 74224 "LT P87 Header Twice"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT P87 Helper";

    local procedure Twice(Kind: Integer; N: Text; V1: Text; V2: Text): Text
    var
        H: HttpHeaders;
        Res: Text;
    begin
        Helper.GetH(Kind, H);
        Res := 'a1=' + Helper.DoAdd(H, N, V1);
        Res += ';a2=' + Helper.DoAdd(H, N, V2);
        Res += ';get=' + Helper.DoGet(H, N);
        Res += ';keys=' + Helper.Keys(H);
        Res += ';raw=' + Helper.DoRaw(H, N, V1);
        Res += ';get2=' + Helper.DoGet(H, N);
        Res += ';rm=' + Helper.DoRemove(H, N);
        Res += ';has=' + Helper.DoContains(H, N);
        exit(Res);
    end;

    [Test]
    procedure Twice_RequestHeaders_Custom()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('customSame', Twice(1, 'X-Custom', 'a', 'a'));
        Observer.Observe('customDiff', Twice(1, 'X-Custom', 'a', 'b'));
        Observer.Observe('customCase', Twice(1, 'X-Custom', 'a', 'A'));
        Observer.Observe('customEmpty', Twice(1, 'X-Custom', '', ''));
        Observer.Observe('customComma', Twice(1, 'X-Custom', 'a,b', 'c'));
        Observer.Finish();
    end;

    [Test]
    procedure Twice_RequestHeaders_Known_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('accept', Twice(1, 'Accept', 'text/html', 'application/json'));
        Observer.Observe('acceptSame', Twice(1, 'Accept', 'text/html', 'text/html'));
        Observer.Observe('cache', Twice(1, 'Cache-Control', 'no-cache', 'no-store'));
        Observer.Observe('acceptEnc', Twice(1, 'Accept-Encoding', 'gzip', 'deflate'));
        Observer.Observe('ifMatch', Twice(1, 'If-Match', '"a"', '"b"'));
        Observer.Observe('ifNoneMatch', Twice(1, 'If-None-Match', '"a"', '"b"'));
        Observer.Finish();
    end;

    [Test]
    procedure Twice_RequestHeaders_Known_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('range', Twice(1, 'Range', 'bytes=0-9', 'bytes=10-19'));
        Observer.Observe('userAgent', Twice(1, 'User-Agent', 'A/1', 'B/2'));
        Observer.Observe('auth', Twice(1, 'Authorization', 'Bearer a', 'Bearer b'));
        Observer.Observe('host', Twice(1, 'Host', 'a.example', 'b.example'));
        Observer.Observe('connection', Twice(1, 'Connection', 'close', 'keep-alive'));
        Observer.Observe('transferEnc', Twice(1, 'Transfer-Encoding', 'chunked', 'gzip'));
        Observer.Finish();
    end;

    [Test]
    procedure Twice_RequestHeaders_Known_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('expires', Twice(1, 'Expires', 'Tue, 15 Nov 1994 08:12:31 GMT', 'Tue, 15 Nov 1994 08:12:32 GMT'));
        Observer.Finish();
    end;

    [Test]
    procedure Twice_ContentHeaders_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('type', Twice(3, 'Content-Type', 'text/plain', 'text/html'));
        Observer.Observe('typeSame', Twice(3, 'Content-Type', 'text/plain', 'text/plain'));
        Observer.Observe('encoding', Twice(3, 'Content-Encoding', 'gzip', 'deflate'));
        Observer.Observe('language', Twice(3, 'Content-Language', 'en', 'de'));
        Observer.Observe('disposition', Twice(3, 'Content-Disposition', 'inline', 'attachment'));
        Observer.Observe('length', Twice(3, 'Content-Length', '5', '6'));
        Observer.Finish();
    end;

    [Test]
    procedure Twice_ContentHeaders_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('expires', Twice(3, 'Expires', 'Tue, 15 Nov 1994 08:12:31 GMT', 'Tue, 15 Nov 1994 08:12:32 GMT'));
        Observer.Observe('lastModified', Twice(3, 'Last-Modified', 'Tue, 15 Nov 1994 08:12:31 GMT', 'Tue, 15 Nov 1994 08:12:32 GMT'));
        Observer.Observe('custom', Twice(3, 'X-Custom', 'a', 'b'));
        Observer.Finish();
    end;

    [Test]
    procedure Twice_ResponseHeaders()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('custom', Twice(4, 'X-Custom', 'a', 'b'));
        Observer.Observe('customSame', Twice(4, 'X-Custom', 'a', 'a'));
        Observer.Observe('cache', Twice(4, 'Cache-Control', 'no-cache', 'no-store'));
        Observer.Observe('connection', Twice(4, 'Connection', 'close', 'keep-alive'));
        Observer.Observe('type', Twice(4, 'Content-Type', 'text/plain', 'text/html'));
        Observer.Observe('expires', Twice(4, 'Expires', 'Tue, 15 Nov 1994 08:12:31 GMT', 'Tue, 15 Nov 1994 08:12:32 GMT'));
        Observer.Finish();
    end;

    [Test]
    procedure NameCaseAndKeys()
    var
        Observer: Codeunit "Probe Observer";
        H: HttpHeaders;
    begin
        Helper.GetH(1, H);
        Observer.Observe('add1', Helper.DoAdd(H, 'X-Custom', 'a'));
        Observer.Observe('add2', Helper.DoAdd(H, 'x-custom', 'b'));
        Observer.Observe('add3', Helper.DoAdd(H, 'X-CUSTOM', 'c'));
        Observer.Observe('keys', Helper.Keys(H));
        Observer.Observe('get', Helper.DoGet(H, 'X-Custom'));
        Observer.Observe('addAccept', Helper.DoAdd(H, 'accept', 'text/html'));
        Observer.Observe('addAccept2', Helper.DoAdd(H, 'ACCEPT', 'text/plain'));
        Observer.Observe('keys2', Helper.Keys(H));
        Observer.Observe('getAccept', Helper.DoGet(H, 'Accept'));
        Observer.Observe('rm', Helper.DoRemove(H, 'x-CUSTOM'));
        Observer.Observe('keys3', Helper.Keys(H));
        Observer.Finish();
    end;
}
