// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/cookie/cookie-data-type
// Scope: in-scope
// Fixtures used: Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Cookie.Name, Value (get and set), Domain, Path, Expires, Secure, HttpOnly (get) on a cookie built in AL and on cookies read with HttpResponseMessage.GetCookie / GetCookieNames from a response built locally with Set-Cookie headers. No request is sent.
// BC versions: 29 (27 and 28 by CI)

codeunit 73085 "LT P94 Cookie"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure ErrText(): Text
    begin
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryAddSetCookie(var Resp: HttpResponseMessage; Header: Text)
    var
        Headers: HttpHeaders;
    begin
        Headers := Resp.Headers;
        Headers.Add('Set-Cookie', Header);
    end;

    local procedure SetName(var C: Cookie; NewName: Text)
    var
        Ignore: Text;
    begin
        Ignore := C.Name(NewName);
    end;

    local procedure SetValue(var C: Cookie; NewValue: Text)
    var
        Ignore: Text;
    begin
        Ignore := C.Value(NewValue);
    end;

    local procedure Describe(var C: Cookie): Text
    begin
        exit('name=[' + C.Name() + '];value=[' + C.Value() + '];domain=[' + C.Domain() + '];path=[' + C.Path() + '];secure=' + Format(C.Secure()) + ';httpOnly=' + Format(C.HttpOnly()) + ';expires=' + Format(C.Expires(), 0, 9));
    end;

    local procedure ReadCookie(Header: Text; CookieName: Text): Text
    var
        Resp: HttpResponseMessage;
        C: Cookie;
        Names: List of [Text];
    begin
        if not TryAddSetCookie(Resp, Header) then
            exit('add ' + ErrText());
        Names := Resp.GetCookieNames();
        if not Resp.GetCookie(CookieName, C) then
            exit('not found; names=' + Format(Names.Count()));
        exit(Describe(C));
    end;

    [Test]
    procedure Fresh_Defaults()
    var
        C: Cookie;
    begin
        Observer.Observe('name', '[' + C.Name() + ']');
        Observer.Observe('value', '[' + C.Value() + ']');
        Observer.Observe('domain', '[' + C.Domain() + ']');
        Observer.Observe('path', '[' + C.Path() + ']');
        Observer.Observe('secure', Format(C.Secure()));
        Observer.Observe('httpOnly', Format(C.HttpOnly()));
        Observer.Observe('expires', Format(C.Expires(), 0, 9));
        Observer.Observe('expiresIsZero', Format(C.Expires() = 0DT));
        Observer.Finish();
    end;

    [Test]
    procedure Value_SetAndRead()
    var
        C: Cookie;
    begin
        SetValue(C, 'abc123');
        Observer.Observe('plain', '[' + C.Value() + ']');
        SetValue(C, '');
        Observer.Observe('empty', '[' + C.Value() + ']');
        SetValue(C, 'a b');
        Observer.Observe('space', '[' + C.Value() + ']');
        SetValue(C, 'a=b;c');
        Observer.Observe('specials', '[' + C.Value() + ']');
        SetValue(C, '"quoted"');
        Observer.Observe('quoted', '[' + C.Value() + ']');
        SetValue(C, 'Ä€');
        Observer.Observe('unicode', '[' + C.Value() + ']');
        SetValue(C, PadStr('', 5000, 'v'));
        Observer.Observe('longLen', Format(StrLen(C.Value())));
        Observer.Finish();
    end;

    [Test]
    procedure SetName_DoesNotTouchOtherMembers()
    var
        C: Cookie;
    begin
        SetName(C, 'n');
        SetValue(C, 'v');
        Observer.Observe('all', Describe(C));
        SetName(C, 'n2');
        Observer.Observe('afterRename', Describe(C));
        Observer.Finish();
    end;

    [Test]
    procedure Copy_AndClear()
    var
        A: Cookie;
        B: Cookie;
    begin
        SetName(A, 'n');
        SetValue(A, 'v');
        B := A;
        Observer.Observe('copy', Describe(B));
        SetValue(B, 'changed');
        Observer.Observe('originalAfterChange', Describe(A));
        Observer.Observe('copyAfterChange', Describe(B));
        Clear(A);
        Observer.Observe('cleared', Describe(A));
        Observer.Observe('copyAfterClear', Describe(B));
        Observer.Finish();
    end;

    [Test]
    procedure Response_NoCookies()
    var
        Resp: HttpResponseMessage;
        C: Cookie;
        Names: List of [Text];
    begin
        Names := Resp.GetCookieNames();
        Observer.Observe('names', Format(Names.Count()));
        SetName(C, 'keep');
        Observer.Observe('found', Format(Resp.GetCookie('sid', C)));
        Observer.Observe('afterMiss', Describe(C));
        Observer.Finish();
    end;

    [Test]
    procedure Response_AddSetCookieHeader()
    var
        Resp: HttpResponseMessage;
        Headers: HttpHeaders;
        Names: List of [Text];
    begin
        Headers := Resp.Headers;
        Observer.Observe('add', Format(TryAddSetCookie(Resp, 'sid=abc123')));
        Observer.Observe('headerKeys', Format(Headers.Keys().Count()));
        Observer.Observe('hasHeader', Format(Headers.Contains('Set-Cookie')));
        Names := Resp.GetCookieNames();
        Observer.Observe('names', Format(Names.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure Response_SimpleCookie()
    begin
        Observer.Observe('simple', ReadCookie('sid=abc123', 'sid'));
        Observer.Observe('caseName', ReadCookie('sid=abc123', 'SID'));
        Observer.Observe('missing', ReadCookie('sid=abc123', 'other'));
        Observer.Finish();
    end;

    [Test]
    procedure Response_AllAttributes()
    begin
        asserterror Observer.Observe('all', ReadCookie('sid=abc; Path=/app; Domain=example.com; Secure; HttpOnly; Expires=Wed, 21 Oct 2037 07:28:00 GMT', 'sid'));
        Observer.ObserveError('af199');
        Observer.Finish();
    end;

    [Test]
    procedure Response_AttributeCaseInsensitive()
    begin
        asserterror Observer.Observe('lower', ReadCookie('sid=abc; path=/x; domain=example.org; secure; httponly', 'sid'));
        Observer.ObserveError('af207');
        asserterror Observer.Observe('upper', ReadCookie('sid=abc; PATH=/y; DOMAIN=example.net; SECURE; HTTPONLY', 'sid'));
        Observer.ObserveError('af210');
        Observer.Finish();
    end;

    [Test]
    procedure Response_OneAttributeEach()
    begin
        Observer.Observe('path', ReadCookie('sid=abc; Path=/only', 'sid'));
        asserterror Observer.Observe('domain', ReadCookie('sid=abc; Domain=example.com', 'sid'));
        Observer.ObserveError('af217');
        Observer.Observe('secure', ReadCookie('sid=abc; Secure', 'sid'));
        Observer.Observe('httpOnly', ReadCookie('sid=abc; HttpOnly', 'sid'));
        Observer.Observe('expires', ReadCookie('sid=abc; Expires=Wed, 21 Oct 2037 07:28:00 GMT', 'sid'));
        Observer.Observe('sameSite', ReadCookie('sid=abc; SameSite=Lax', 'sid'));
        Observer.Finish();
    end;

    [Test]
    procedure Response_MaxAge()
    var
        Resp: HttpResponseMessage;
        C: Cookie;
    begin
        TryAddSetCookie(Resp, 'sid=abc; Max-Age=3600');
        Observer.Observe('found', Format(Resp.GetCookie('sid', C)));
        Observer.Observe('expiresSet', Format(C.Expires() <> 0DT));
        Observer.Observe('expiresInFuture', Format(C.Expires() > CurrentDateTime()));
        Observer.Finish();
    end;

    [Test]
    procedure Response_ExpiresInPast()
    var
        Resp: HttpResponseMessage;
        C: Cookie;
    begin
        TryAddSetCookie(Resp, 'old=1; Expires=Thu, 01 Jan 1970 00:00:01 GMT');
        Observer.Observe('found', Format(Resp.GetCookie('old', C)));
        Observer.Observe('describe', Describe(C));
        Observer.Finish();
    end;

    [Test]
    procedure Response_ValueForms()
    begin
        Observer.Observe('empty', ReadCookie('sid=', 'sid'));
        Observer.Observe('quoted', ReadCookie('sid="abc def"', 'sid'));
        Observer.Observe('equalsInValue', ReadCookie('sid=a=b=c', 'sid'));
        Observer.Observe('noEquals', ReadCookie('sid', 'sid'));
        Observer.Observe('spaces', ReadCookie('sid = abc', 'sid'));
        Observer.Finish();
    end;

    [Test]
    procedure Response_MultipleCookies()
    var
        Resp: HttpResponseMessage;
        C: Cookie;
        Names: List of [Text];
        N: Text;
        i: Integer;
    begin
        TryAddSetCookie(Resp, 'a=1; Path=/a');
        TryAddSetCookie(Resp, 'b=2; Secure');
        TryAddSetCookie(Resp, 'c=3; HttpOnly');
        Names := Resp.GetCookieNames();
        Observer.Observe('count', Format(Names.Count()));
        foreach N in Names do begin
            i += 1;
            Observer.Observe('name' + Format(i), N);
        end;
        Observer.Observe('getB', Format(Resp.GetCookie('b', C)));
        Observer.Observe('describeB', Describe(C));
        Observer.Observe('getA', Format(Resp.GetCookie('a', C)));
        Observer.Observe('describeA', Describe(C));
        Observer.Finish();
    end;

    [Test]
    procedure Response_SameNameTwice()
    var
        Resp: HttpResponseMessage;
        C: Cookie;
        Names: List of [Text];
    begin
        TryAddSetCookie(Resp, 'dup=first; Path=/1');
        TryAddSetCookie(Resp, 'dup=second; Path=/2');
        Names := Resp.GetCookieNames();
        Observer.Observe('count', Format(Names.Count()));
        Observer.Observe('found', Format(Resp.GetCookie('dup', C)));
        Observer.Observe('describe', Describe(C));
        Observer.Finish();
    end;

    [Test]
    procedure Response_ReadCookieIsIndependentCopy()
    var
        Resp: HttpResponseMessage;
        C1: Cookie;
        C2: Cookie;
    begin
        TryAddSetCookie(Resp, 'sid=abc');
        Resp.GetCookie('sid', C1);
        SetValue(C1, 'changed');
        Resp.GetCookie('sid', C2);
        Observer.Observe('first', Describe(C1));
        Observer.Observe('second', Describe(C2));
        Observer.Finish();
    end;

    [Test]
    procedure Response_EmptyAndBlankNames()
    var
        Resp: HttpResponseMessage;
        C: Cookie;
    begin
        TryAddSetCookie(Resp, 'sid=abc');
        Observer.Observe('emptyName', Format(Resp.GetCookie('', C)));
        Observer.Observe('blankName', Format(Resp.GetCookie(' ', C)));
        Observer.Finish();
    end;
}
