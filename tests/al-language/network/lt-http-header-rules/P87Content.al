// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpcontent/httpcontent-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT P87 Helper (codeunit 74228), table 74221
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: HttpContent header collections before and after WriteFrom / Clear, GetHeaders called twice, Content-Type value and ReadAs
// BC versions: 29 (27 and 28 by CI)

codeunit 74225 "LT P87 Content Headers"
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

    [Test]
    procedure AddThenWrite_Text()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
        H2: HttpHeaders;
    begin
        C.GetHeaders(H);
        Observer.Observe('freshKeys', Helper.Keys(H));
        Observer.Observe('add', Helper.DoAdd(H, 'X-A', '1'));
        C.WriteFrom('x');
        Observer.Observe('oldHasA', Helper.DoContains(H, 'X-A'));
        Observer.Observe('oldKeys', Helper.Keys(H));
        Observer.Observe('oldType', Type(H));
        C.GetHeaders(H2);
        Observer.Observe('newHasA', Helper.DoContains(H2, 'X-A'));
        Observer.Observe('newKeys', Helper.Keys(H2));
        Observer.Observe('newType', Type(H2));
        Observer.Observe('read', Read(C));
        Observer.Finish();
    end;

    [Test]
    procedure WriteThenAdd_Text()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
        H2: HttpHeaders;
    begin
        C.WriteFrom('x');
        C.GetHeaders(H);
        Observer.Observe('keys', Helper.Keys(H));
        Observer.Observe('add', Helper.DoAdd(H, 'X-A', '1'));
        C.WriteFrom('y');
        Observer.Observe('oldHasA', Helper.DoContains(H, 'X-A'));
        Observer.Observe('oldKeys', Helper.Keys(H));
        C.GetHeaders(H2);
        Observer.Observe('newHasA', Helper.DoContains(H2, 'X-A'));
        Observer.Observe('newKeys', Helper.Keys(H2));
        Observer.Observe('newType', Type(H2));
        Observer.Observe('read', Read(C));
        Observer.Finish();
    end;

    [Test]
    procedure ClearAfterAdd()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
        H2: HttpHeaders;
    begin
        C.GetHeaders(H);
        Helper.DoAdd(H, 'X-A', '1');
        C.WriteFrom('x');
        C.Clear();
        Observer.Observe('oldHasA', Helper.DoContains(H, 'X-A'));
        Observer.Observe('oldKeys', Helper.Keys(H));
        Observer.Observe('oldType', Type(H));
        C.GetHeaders(H2);
        Observer.Observe('newHasA', Helper.DoContains(H2, 'X-A'));
        Observer.Observe('newKeys', Helper.Keys(H2));
        Observer.Observe('newType', Type(H2));
        Observer.Observe('read', Read(C));
        Observer.Observe('addAfterClear', Helper.DoAdd(H, 'X-B', '2'));
        Observer.Observe('hasBOld', Helper.DoContains(H, 'X-B'));
        C.GetHeaders(H2);
        Observer.Observe('hasBNew', Helper.DoContains(H2, 'X-B'));
        Observer.Finish();
    end;

    [Test]
    procedure ClearBeforeWrite()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
        H2: HttpHeaders;
    begin
        C.GetHeaders(H);
        Helper.DoAdd(H, 'X-A', '1');
        C.Clear();
        C.WriteFrom('x');
        Observer.Observe('oldHasA', Helper.DoContains(H, 'X-A'));
        C.GetHeaders(H2);
        Observer.Observe('newHasA', Helper.DoContains(H2, 'X-A'));
        Observer.Observe('newKeys', Helper.Keys(H2));
        Observer.Observe('newType', Type(H2));
        Observer.Observe('read', Read(C));
        Observer.Finish();
    end;

    [Test]
    procedure ClearFresh()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
    begin
        C.Clear();
        C.GetHeaders(H);
        Observer.Observe('keys', Helper.Keys(H));
        Observer.Observe('type', Type(H));
        Observer.Observe('read', Read(C));
        C.Clear();
        Observer.Observe('clearTwice', Read(C));
        Observer.Finish();
    end;

    [Test]
    procedure RewriteKeepsHeader()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
        H2: HttpHeaders;
    begin
        C.WriteFrom('x');
        C.GetHeaders(H);
        Helper.DoAdd(H, 'X-A', '1');
        C.WriteFrom('longer text');
        C.GetHeaders(H2);
        Observer.Observe('hasA', Helper.DoContains(H2, 'X-A'));
        Observer.Observe('keys', Helper.Keys(H2));
        Observer.Observe('type', Type(H2));
        Observer.Observe('read', Read(C));
        Observer.Observe('removeType', Helper.DoRemove(H2, 'Content-Type'));
        C.WriteFrom('third');
        C.GetHeaders(H2);
        Observer.Observe('typeAfterRemoveAndWrite', Type(H2));
        Observer.Observe('keysAfter', Helper.Keys(H2));
        Observer.Observe('read2', Read(C));
        Observer.Finish();
    end;

    [Test]
    procedure RequestContentHeaders_AfterAssign()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        C: HttpContent;
        H: HttpHeaders;
        H2: HttpHeaders;
        H3: HttpHeaders;
        C2: HttpContent;
    begin
        C.GetHeaders(H);
        Helper.DoAdd(H, 'X-A', '1');
        C.WriteFrom('x');
        Req.Content := C;
        Req.Content.GetHeaders(H2);
        Observer.Observe('reqHasA', Helper.DoContains(H2, 'X-A'));
        Observer.Observe('reqKeys', Helper.Keys(H2));
        Observer.Observe('reqType', Type(H2));
        Helper.DoAdd(H2, 'X-B', '2');
        C.GetHeaders(H3);
        Observer.Observe('origHasB', Helper.DoContains(H3, 'X-B'));
        Req.Content.GetHeaders(H3);
        Observer.Observe('reqHasB', Helper.DoContains(H3, 'X-B'));
        C2 := Req.Content;
        Observer.Observe('reqRead', Read(C2));
        Observer.Finish();
    end;

    [Test]
    procedure ResponseContentHeaders()
    var
        Observer: Codeunit "Probe Observer";
        Resp: HttpResponseMessage;
        H: HttpHeaders;
        H2: HttpHeaders;
        H3: HttpHeaders;
    begin
        Resp.Content.GetHeaders(H);
        Observer.Observe('freshKeys', Helper.Keys(H));
        Observer.Observe('add', Helper.DoAdd(H, 'X-A', '1'));
        Resp.Content.WriteFrom('x');
        Resp.Content.GetHeaders(H2);
        Observer.Observe('hasA', Helper.DoContains(H2, 'X-A'));
        Observer.Observe('keys', Helper.Keys(H2));
        Observer.Observe('type', Type(H2));
        H3 := Resp.Headers;
        Observer.Observe('respHeadersKeys', Helper.Keys(H3));
        Observer.Observe('respHasA', Helper.DoContains(H3, 'X-A'));
        Observer.Finish();
    end;
}
