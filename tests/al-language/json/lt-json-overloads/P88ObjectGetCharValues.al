// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74414
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: UNSURE the members exist: JsonObject.GetChar, JsonObject.Values
// BC versions: 29 (27 and 28 by CI)

codeunit 74414 "LT P88 Object GetChar Values"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure Object_GetChar()
    var
        O: JsonObject;
        Ch: Char;
    begin
        Ch := 65;
        O.Add('c', Ch);
        O.Add('t', 'B');
        O.Add('n', 7);
        Observer.Observe('char', Format(O.GetChar('c')));
        Observer.Observe('char_from_text', Format(O.GetChar('t')));
        Observer.Observe('char_from_int', Format(O.GetChar('n')));
        Observer.Observe('char_from_int', 'no error');
        asserterror Observer.Observe('char_missing', Format(O.GetChar('zzz')));
        Observer.ObserveError('char_missing');
        Observer.Finish();
    end;

    [Test]
    procedure Object_Values()
    var
        O: JsonObject;
        L: List of [JsonToken];
        T: JsonToken;
        Txt: Text;
        R: Text;
    begin
        L := O.Values();
        Observer.Observe('values_empty_count', Format(L.Count()));
        O.Add('a', 1);
        O.Add('b', 'two');
        O.Add('c', true);
        L := O.Values();
        Observer.Observe('values_count', Format(L.Count()));
        foreach T in L do begin
            T.WriteTo(Txt);
            R += Txt + ';';
        end;
        Observer.Observe('values', R);
        Observer.Finish();
    end;
}
