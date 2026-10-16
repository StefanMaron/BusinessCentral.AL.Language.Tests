// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonarray/jsonarray-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74413
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: UNSURE the members exist: JsonArray.GetChar, JsonArray.GetTime
// BC versions: 29 (27 and 28 by CI)

codeunit 74413 "LT P88 Array GetChar Time"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure Array_GetChar_GetTime()
    var
        A: JsonArray;
        Ch: Char;
        Ti: Time;
    begin
        Ch := 65;
        Ti := 143015T;
        A.Add(Ch);
        A.Add(Ti);
        A.Add('B');
        A.Add(7);
        Observer.Observe('text', Format(A.GetChar(0)));
        Observer.Observe('char_from_text', Format(A.GetChar(2)));
        Observer.Observe('time', Format(A.GetTime(1), 0, 9));
        Observer.Observe('char_from_int', Format(A.GetChar(3)));
        Observer.Observe('char_from_int', 'no error');
        asserterror Observer.Observe('char_oob', Format(A.GetChar(4)));
        Observer.ObserveError('char_oob');
        asserterror Observer.Observe('char_neg', Format(A.GetChar(-1)));
        Observer.ObserveError('char_neg');
        asserterror Observer.Observe('time_oob', Format(A.GetTime(9)));
        Observer.ObserveError('time_oob');
        asserterror Observer.Observe('time_from_text', Format(A.GetTime(2)));
        Observer.ObserveError('time_from_text');
        Observer.Finish();
    end;
}
