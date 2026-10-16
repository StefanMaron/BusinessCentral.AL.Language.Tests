// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpcontent/httpcontent-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT P87 Helper (codeunit 74228), table 74221
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Content-Type set by header and by WriteFrom: which one wins and what ReadAs gives back
// BC versions: 29 (27 and 28 by CI)

codeunit 74227 "LT P87 Content Type"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT P87 Helper";

    local procedure Type(var H: HttpHeaders): Text
    begin
        exit(Helper.DoGet(H, 'Content-Type'));
    end;

    local procedure Read(var C: HttpContent): Text
    var
        T: Text;
        R: Boolean;
    begin
        T := 'preset';
        R := C.ReadAs(T);
        exit(Format(R) + '/' + T);
    end;

    local procedure ReplaceType(var H: HttpHeaders; V: Text): Text
    begin
        Helper.DoRemove(H, 'Content-Type');
        exit(Helper.DoAdd(H, 'Content-Type', V));
    end;

    [Test]
    procedure HeaderBeforeWrite()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
        H2: HttpHeaders;
    begin
        C.GetHeaders(H);
        Observer.Observe('freshType', Type(H));
        Observer.Observe('replace', ReplaceType(H, 'application/json'));
        Observer.Observe('typeBefore', Type(H));
        C.WriteFrom('{"a":1}');
        C.GetHeaders(H2);
        Observer.Observe('typeAfterWrite', Type(H2));
        Observer.Observe('oldRefType', Type(H));
        Observer.Observe('read', Read(C));
        Observer.Finish();
    end;

    [Test]
    procedure HeaderAfterWrite()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
        H2: HttpHeaders;
    begin
        C.WriteFrom('{"a":1}');
        C.GetHeaders(H);
        Observer.Observe('typeAfterWrite', Type(H));
        Observer.Observe('replace', ReplaceType(H, 'application/json'));
        C.GetHeaders(H2);
        Observer.Observe('typeNew', Type(H2));
        Observer.Observe('typeOld', Type(H));
        Observer.Observe('read', Read(C));
        Observer.Finish();
    end;

    [Test]
    procedure AddWithoutRemove()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
    begin
        C.WriteFrom('abc');
        C.GetHeaders(H);
        Observer.Observe('addJson', Helper.DoAdd(H, 'Content-Type', 'application/json'));
        Observer.Observe('type', Type(H));
        Observer.Observe('keys', Helper.Keys(H));
        Observer.Observe('raw', Helper.DoRaw(H, 'Content-Type', 'text/html'));
        Observer.Observe('typeRaw', Type(H));
        Observer.Observe('read', Read(C));
        Observer.Finish();
    end;

    [Test]
    procedure SecondWriteAfterHeaderChange()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
        H2: HttpHeaders;
    begin
        C.WriteFrom('first');
        C.GetHeaders(H);
        Observer.Observe('replace', ReplaceType(H, 'application/xml'));
        C.WriteFrom('<a/>');
        C.GetHeaders(H2);
        Observer.Observe('typeAfterSecondWrite', Type(H2));
        Observer.Observe('read', Read(C));
        C.WriteFrom('third');
        C.GetHeaders(H2);
        Observer.Observe('typeAfterThird', Type(H2));
        Observer.Finish();
    end;

    [Test]
    procedure WriteAfterRemovedType()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
        H2: HttpHeaders;
    begin
        C.WriteFrom('first');
        C.GetHeaders(H);
        Observer.Observe('remove', Helper.DoRemove(H, 'Content-Type'));
        Observer.Observe('keysNow', Helper.Keys(H));
        C.GetHeaders(H2);
        Observer.Observe('keysNew', Helper.Keys(H2));
        Observer.Observe('read', Read(C));
        C.WriteFrom('second');
        C.GetHeaders(H2);
        Observer.Observe('typeAfterWrite', Type(H2));
        Observer.Finish();
    end;

    [Test]
    procedure ReadAsIgnoresCharsetHeader()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
    begin
        C.WriteFrom('äöü€');
        C.GetHeaders(H);
        Observer.Observe('type', Type(H));
        Observer.Observe('readUtf8', Read(C));
        Observer.Observe('replace', ReplaceType(H, 'text/plain; charset=iso-8859-1'));
        Observer.Observe('readLatin1', Read(C));
        Observer.Observe('replace2', ReplaceType(H, 'text/plain; charset=utf-16'));
        Observer.Observe('readUtf16', Read(C));
        Observer.Observe('replace3', ReplaceType(H, 'application/octet-stream'));
        Observer.Observe('readOctet', Read(C));
        Observer.Observe('replace4', ReplaceType(H, 'image/png'));
        Observer.Observe('readPng', Read(C));
        Observer.Finish();
    end;

    [Test]
    procedure ContentTypeVariantsStayVerbatim()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
    begin
        C.WriteFrom('x');
        C.GetHeaders(H);
        Observer.Observe('upper', ReplaceType(H, 'TEXT/PLAIN; CHARSET=UTF-8'));
        Observer.Observe('upperType', Type(H));
        Observer.Observe('noSpace', ReplaceType(H, 'text/plain;charset=utf-8'));
        Observer.Observe('noSpaceType', Type(H));
        Observer.Observe('quotedCharset', ReplaceType(H, 'text/plain; charset="utf-8"'));
        Observer.Observe('quotedType', Type(H));
        Observer.Observe('extraParam', ReplaceType(H, 'text/plain; charset=utf-8; format=flowed'));
        Observer.Observe('extraType', Type(H));
        Observer.Observe('bareType', ReplaceType(H, 'application/vnd.api+json'));
        Observer.Observe('bareTypeValue', Type(H));
        Observer.Observe('read', Read(C));
        Observer.Finish();
    end;

    [Test]
    procedure Request_ContentTypeWins()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        C: HttpContent;
        H: HttpHeaders;
        H2: HttpHeaders;
        C2: HttpContent;
    begin
        C.WriteFrom('{}');
        C.GetHeaders(H);
        Observer.Observe('replace', ReplaceType(H, 'application/json'));
        Req.Content := C;
        Req.Content.GetHeaders(H2);
        Observer.Observe('reqType', Type(H2));
        Observer.Observe('reqKeys', Helper.Keys(H2));
        C2 := Req.Content;
        Observer.Observe('reqRead', Read(C2));
        Observer.Finish();
    end;

    [Test]
    procedure Response_ContentTypeHeaderLocation()
    var
        Observer: Codeunit "Probe Observer";
        Resp: HttpResponseMessage;
        H: HttpHeaders;
        H2: HttpHeaders;
    begin
        Resp.Content.WriteFrom('{}');
        Resp.Content.GetHeaders(H);
        Observer.Observe('contentType', Type(H));
        H2 := Resp.Headers;
        Observer.Observe('respTypeHas', Helper.DoContains(H2, 'Content-Type'));
        Observer.Observe('respTypeAdd', Helper.DoAdd(H2, 'Content-Type', 'application/json'));
        Observer.Observe('respKeys', Helper.Keys(H2));
        Observer.Observe('contentKeys', Helper.Keys(H));
        Observer.Finish();
    end;
}
