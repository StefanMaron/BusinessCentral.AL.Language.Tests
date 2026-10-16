// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74408
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: JsonObject Add existing key, Replace missing key, Remove, Keys, key edge cases
// BC versions: 29 (27 and 28 by CI)

codeunit 74408 "LT P88 Object Keys"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Txt(O: JsonObject): Text
    var
        R: Text;
    begin
        O.WriteTo(R);
        exit(R);
    end;

    [Test]
    procedure Add_ExistingKey()
    var
        O: JsonObject;
    begin
        O.Add('k', 1);
        asserterror O.Add('k', 2);
        Observer.ObserveError('add_same_type');
        asserterror O.Add('k', 'text');
        Observer.ObserveError('add_other_type');
        asserterror O.Add('k', true);
        Observer.ObserveError('add_boolean');
        O.Add('K', 3);
        Observer.Observe('add_other_case', 'no error');
        Observer.Observe('after_errors', Txt(O));
        Observer.Observe('count', Format(O.Keys().Count()));
        Observer.Finish();
    end;

    [Test]
    procedure Add_ExistingKey_Containers()
    var
        O: JsonObject;
        Ja: JsonArray;
        Jo: JsonObject;
        Jv: JsonValue;
        T: JsonToken;
    begin
        O.Add('k', 1);
        Ja.Add(1);
        Jo.Add('x', 1);
        Jv.SetValue(5);
        T := Jv.AsToken();
        asserterror O.Add('k', Ja);
        Observer.ObserveError('add_array');
        asserterror O.Add('k', Jo);
        Observer.ObserveError('add_object');
        asserterror O.Add('k', Jv);
        Observer.ObserveError('add_value');
        asserterror O.Add('k', T);
        Observer.ObserveError('add_token');
        Observer.Observe('after_errors', Txt(O));
        Observer.Finish();
    end;

    [Test]
    procedure Replace_ExistingAndMissing()
    var
        O: JsonObject;
    begin
        O.Add('a', 1);
        O.Add('b', 2);
        O.Add('c', 3);
        O.Replace('b', 'two');
        Observer.Observe('replace_b', Txt(O));
        O.Replace('c', 3.5);
        Observer.Observe('replace_c', Txt(O));
        O.Replace('a', true);
        Observer.Observe('replace_a', Txt(O));
        asserterror O.Replace('zzz', 1);
        Observer.ObserveError('replace_missing');
        asserterror O.Replace('B', 1);
        Observer.ObserveError('replace_other_case');
        asserterror O.Replace('', 1);
        Observer.ObserveError('replace_empty_key');
        Observer.Observe('after_errors', Txt(O));
        Observer.Observe('count', Format(O.Keys().Count()));
        Observer.Finish();
    end;

    [Test]
    procedure Replace_EmptyObject()
    var
        O: JsonObject;
    begin
        asserterror O.Replace('a', 1);
        Observer.ObserveError('replace_in_empty');
        Observer.Observe('text', Txt(O));
        Observer.Finish();
    end;

    [Test]
    procedure Replace_ContainerOrder()
    var
        O: JsonObject;
        Jo: JsonObject;
        Ja: JsonArray;
    begin
        O.ReadFrom('{"first":1,"second":2,"third":3}');
        Jo.Add('n', 1);
        Ja.Add('x');
        O.Replace('second', Jo);
        Observer.Observe('replace_with_object', Txt(O));
        O.Replace('first', Ja);
        Observer.Observe('replace_with_array', Txt(O));
        Observer.Finish();
    end;

    [Test]
    procedure Add_KeyEdgeCases()
    var
        O: JsonObject;
        Keys: List of [Text];
        K: Text;
        R: Text;
    begin
        O.Add('', 1);
        Observer.Observe('empty_key', Txt(O));
        O.Add(' ', 2);
        O.Add('with "quote"', 3);
        O.Add('back\slash', 4);
        O.Add('ünï', 5);
        O.Add('a.b', 6);
        O.Add('[0]', 7);
        Observer.Observe('edge_keys', Txt(O));
        Keys := O.Keys();
        foreach K in Keys do
            R += '<' + K + '>';
        Observer.Observe('keys', R);
        Observer.Observe('count', Format(O.Keys().Count()));
        Observer.Observe('contains_empty', Format(O.Contains('')));
        Observer.Observe('contains_other_case', Format(O.Contains('A.B')));
        Observer.Finish();
    end;
}
