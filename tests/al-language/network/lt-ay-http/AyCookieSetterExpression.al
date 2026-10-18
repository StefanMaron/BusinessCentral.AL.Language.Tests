// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/cookie/cookie-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 80506
// Probe: observe probe; every literal asserted below is what the corpus CI service tiers produced.
// Facts: the setter forms Cookie.Name(Text) and Cookie.Value(Text) (the only Cookie members with a setter) used as an expression: Format of the value
// they return, on a fresh cookie, on a cookie that held other values and with an empty text, and the getter afterwards.
// BC versions: 27, 28, 29 (corpus CI)

codeunit 80506 "LT AY Cookie Setter Expression"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure CookieSetter_AsExpression_FreshCookie()
    var
        Observer: Codeunit "Probe Observer";
        C: Cookie;
    begin
        Observer.Observe('name', '[' + Format(C.Name('n')) + '] get=' + C.Name());
        Observer.Observe('value', '[' + Format(C.Value('v')) + '] get=' + C.Value());
        Observer.Finish();
    end;

    [Test]
    procedure CookieSetter_AsExpression_CookieWithOtherValues()
    var
        Observer: Codeunit "Probe Observer";
        C: Cookie;
    begin
        C.Name('old-name');
        C.Value('old-value');
        Observer.Observe('name', '[' + Format(C.Name('n')) + '] get=' + C.Name());
        Observer.Observe('value', '[' + Format(C.Value('v')) + '] get=' + C.Value());
        Observer.Observe('name_empty', '[' + Format(C.Name('')) + '] get=' + C.Name());
        Observer.Observe('value_empty', '[' + Format(C.Value('')) + '] get=' + C.Value());
        Observer.Finish();
    end;
}
