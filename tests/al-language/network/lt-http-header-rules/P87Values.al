// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT P87 Helper (codeunit 74228)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: header values with line breaks, spaces, commas and quotes; a header added twice
// BC versions: 29 (27 and 28 by CI)

codeunit 74223 "LT P87 Header Values"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT P87 Helper";

    local procedure Line(Kind: Integer; N: Text; V: Text): Text
    var
        H: HttpHeaders;
        H2: HttpHeaders;
        Res: Text;
    begin
        Helper.GetH(Kind, H);
        Res := 'add=' + Helper.DoAdd(H, N, V);
        Res += ';get=' + Helper.DoGet(H, N);
        Helper.GetH(Kind, H2);
        Res += ';raw=' + Helper.DoRaw(H2, N, V);
        Res += ';get2=' + Helper.DoGet(H2, N);
        exit(Res);
    end;

    local procedure Special(var Observer: Codeunit "Probe Observer"; Kind: Integer; FromIdx: Integer; ToIdx: Integer)
    var
        Cr: Text[1];
        Lf: Text[1];
        Tab: Text[1];
        Idx: Integer;
    begin
        Cr[1] := 13;
        Lf[1] := 10;
        Tab[1] := 9;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('plain', Line(Kind, 'X-Custom', 'abc'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('lf', Line(Kind, 'X-Custom', 'a' + Lf + 'b'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('crlf', Line(Kind, 'X-Custom', 'a' + Cr + Lf + 'b'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('cr', Line(Kind, 'X-Custom', 'a' + Cr + 'b'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('crlfSpace', Line(Kind, 'X-Custom', 'a' + Cr + Lf + ' b'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('trailingLf', Line(Kind, 'X-Custom', 'a' + Lf));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('leadingSpaces', Line(Kind, 'X-Custom', '   lead'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('trailingSpaces', Line(Kind, 'X-Custom', 'trail   '));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('bothSpaces', Line(Kind, 'X-Custom', '  both  '));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('onlySpaces', Line(Kind, 'X-Custom', '   '));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('empty', Line(Kind, 'X-Custom', ''));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('tab', Line(Kind, 'X-Custom', 'a' + Tab + 'b'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('innerSpaces', Line(Kind, 'X-Custom', 'a   b'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('comma', Line(Kind, 'X-Custom', 'a,b'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('commaSpaces', Line(Kind, 'X-Custom', 'a, b ,c'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('quoted', Line(Kind, 'X-Custom', '"quoted"'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('quotedComma', Line(Kind, 'X-Custom', '"a,b"'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('unbalancedQuote', Line(Kind, 'X-Custom', '"abc'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('semicolon', Line(Kind, 'X-Custom', 'a;b=c'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('unicode', Line(Kind, 'X-Custom', 'äö€'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('colon', Line(Kind, 'X-Custom', 'a:b'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('digitZero', Line(Kind, 'X-Custom', 'a' + Format(0) + 'b'));
        Idx += 1;
    end;

    [Test]
    procedure SpecialValues_RequestHeaders_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Special(Observer, 1, 0, 5);
        Observer.Finish();
    end;

    [Test]
    procedure SpecialValues_RequestHeaders_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Special(Observer, 1, 6, 11);
        Observer.Finish();
    end;

    [Test]
    procedure SpecialValues_RequestHeaders_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Special(Observer, 1, 12, 17);
        Observer.Finish();
    end;

    [Test]
    procedure SpecialValues_RequestHeaders_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Special(Observer, 1, 18, 23);
        Observer.Finish();
    end;

    [Test]
    procedure SpecialValues_ContentHeaders_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Special(Observer, 3, 0, 5);
        Observer.Finish();
    end;

    [Test]
    procedure SpecialValues_ContentHeaders_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Special(Observer, 3, 6, 11);
        Observer.Finish();
    end;

    [Test]
    procedure SpecialValues_ContentHeaders_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Special(Observer, 3, 12, 17);
        Observer.Finish();
    end;

    [Test]
    procedure SpecialValues_ContentHeaders_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Special(Observer, 3, 18, 23);
        Observer.Finish();
    end;

    [Test]
    procedure SpecialValues_ResponseHeaders_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Special(Observer, 4, 0, 5);
        Observer.Finish();
    end;

    [Test]
    procedure SpecialValues_ResponseHeaders_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Special(Observer, 4, 6, 11);
        Observer.Finish();
    end;

    [Test]
    procedure SpecialValues_ResponseHeaders_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Special(Observer, 4, 12, 17);
        Observer.Finish();
    end;

    [Test]
    procedure SpecialValues_ResponseHeaders_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Special(Observer, 4, 18, 23);
        Observer.Finish();
    end;

    [Test]
    procedure KnownHeaderLists_Request_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('accept2', Line(1, 'Accept', 'text/html, application/json;q=0.9'));
        Observer.Observe('acceptComma', Line(1, 'Accept', 'text/html,application/json'));
        Observer.Observe('acceptStar', Line(1, 'Accept', '*/*'));
        Observer.Observe('acceptSpaces', Line(1, 'Accept', '  text/html  '));
        Observer.Observe('cache2', Line(1, 'Cache-Control', 'no-cache, no-store'));
        Observer.Observe('cacheMaxAge', Line(1, 'Cache-Control', 'max-age=60'));
        Observer.Finish();
    end;

    [Test]
    procedure KnownHeaderLists_Request_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('cacheBad', Line(1, 'Cache-Control', 'no cache'));
        Observer.Observe('acceptEnc2', Line(1, 'Accept-Encoding', 'gzip, deflate'));
        Observer.Observe('acceptEncQ', Line(1, 'Accept-Encoding', 'gzip;q=0.5'));
        Observer.Observe('ifMatch2', Line(1, 'If-Match', '"a", "b"'));
        Observer.Observe('ifMatchStar', Line(1, 'If-Match', '*'));
        Observer.Observe('ifMatchUnquoted', Line(1, 'If-Match', 'abc'));
        Observer.Finish();
    end;

    [Test]
    procedure KnownHeaderLists_Request_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('ifNoneMatchWeak', Line(1, 'If-None-Match', 'W/"abc"'));
        Observer.Observe('ua', Line(1, 'User-Agent', 'A/1 (comment) B/2'));
        Observer.Observe('uaBad', Line(1, 'User-Agent', '(((('));
        Observer.Observe('authBasic', Line(1, 'Authorization', 'Basic  abc'));
        Observer.Observe('authNoScheme', Line(1, 'Authorization', 'abc'));
        Observer.Observe('authBearerSpaces', Line(1, 'Authorization', '  Bearer abc  '));
        Observer.Finish();
    end;

    [Test]
    procedure KnownHeaderLists_Request_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('connection2', Line(1, 'Connection', 'close, keep-alive'));
        Observer.Observe('range', Line(1, 'Range', 'bytes=0-9, 20-29'));
        Observer.Observe('rangeBad', Line(1, 'Range', 'bytes'));
        Observer.Observe('hostPort', Line(1, 'Host', 'a.example:8080'));
        Observer.Observe('hostBad', Line(1, 'Host', 'a b'));
        Observer.Observe('te', Line(1, 'Transfer-Encoding', 'chunked'));
        Observer.Finish();
    end;

    [Test]
    procedure KnownHeaderLists_Content_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('type', Line(3, 'Content-Type', 'text/plain'));
        Observer.Observe('typeCharset', Line(3, 'Content-Type', 'text/plain; charset=utf-8'));
        Observer.Observe('typeNoSpace', Line(3, 'Content-Type', 'text/plain;charset=UTF-8'));
        Observer.Observe('typeUpper', Line(3, 'Content-Type', 'TEXT/PLAIN'));
        Observer.Observe('typeBoundary', Line(3, 'Content-Type', 'multipart/form-data; boundary="a b"'));
        Observer.Observe('typeNoSlash', Line(3, 'Content-Type', 'text'));
        Observer.Finish();
    end;

    [Test]
    procedure KnownHeaderLists_Content_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('typeSpaces', Line(3, 'Content-Type', '  text/plain  '));
        Observer.Observe('typeBadCharset', Line(3, 'Content-Type', 'text/plain; charset=nonsense'));
        Observer.Observe('typeTwo', Line(3, 'Content-Type', 'text/plain, text/html'));
        Observer.Observe('encoding2', Line(3, 'Content-Encoding', 'gzip, deflate'));
        Observer.Observe('encodingBad', Line(3, 'Content-Encoding', 'gzip deflate'));
        Observer.Observe('language2', Line(3, 'Content-Language', 'en, de'));
        Observer.Finish();
    end;

    [Test]
    procedure KnownHeaderLists_Content_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('languageBad', Line(3, 'Content-Language', 'en_US'));
        Observer.Observe('disp', Line(3, 'Content-Disposition', 'attachment; filename="a.txt"'));
        Observer.Observe('dispInline', Line(3, 'Content-Disposition', 'inline'));
        Observer.Observe('dispBad', Line(3, 'Content-Disposition', ';;'));
        Observer.Observe('expires', Line(3, 'Expires', 'Tue, 15 Nov 1994 08:12:31 GMT'));
        Observer.Observe('expiresBad', Line(3, 'Expires', 'tomorrow'));
        Observer.Finish();
    end;

    [Test]
    procedure KnownHeaderLists_Content_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('expiresZero', Line(3, 'Expires', '0'));
        Observer.Observe('lastMod', Line(3, 'Last-Modified', 'Tue, 15 Nov 1994 08:12:31 GMT'));
        Observer.Observe('lastModBad', Line(3, 'Last-Modified', '2020-01-01'));
        Observer.Observe('length', Line(3, 'Content-Length', '5'));
        Observer.Observe('lengthBad', Line(3, 'Content-Length', 'five'));
        Observer.Observe('lengthNeg', Line(3, 'Content-Length', '-1'));
        Observer.Finish();
    end;

}
