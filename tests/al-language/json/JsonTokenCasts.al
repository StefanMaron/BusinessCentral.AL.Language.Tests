// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsontoken/jsontoken-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunit 72503
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 72503 "LT JsT Token Casts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure DoCast(T: JsonToken; Kind: Text; var R: Text)
    var
        O: JsonObject;
        A: JsonArray;
        V: JsonValue;
    begin
        case Kind of
            'AsObject':
                begin
                    O := T.AsObject();
                    O.WriteTo(R);
                end;
            'AsArray':
                begin
                    A := T.AsArray();
                    A.WriteTo(R);
                end;
            'AsValue':
                begin
                    V := T.AsValue();
                    V.WriteTo(R);
                end;
        end;
    end;

    local procedure Cast(T: JsonToken; Kind: Text): Text
    var
        R: Text;
    begin
        if DoCast(T, Kind, R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Describe(Name: Text; T: JsonToken)
    begin
        Observer.Observe(Name + '_isobject', Format(T.IsObject()));
        Observer.Observe(Name + '_isarray', Format(T.IsArray()));
        Observer.Observe(Name + '_isvalue', Format(T.IsValue()));
        Observer.Observe(Name + '_asobject', Cast(T, 'AsObject'));
        Observer.Observe(Name + '_asarray', Cast(T, 'AsArray'));
        Observer.Observe(Name + '_asvalue', Cast(T, 'AsValue'));
    end;

    [Test]
    procedure ObjectToken()
    var
        O: JsonObject;
        T: JsonToken;
    begin
        O.Add('a', 1);
        T := O.AsToken();
        Describe('obj', T);
        Observer.Expect('obj_isobject', 'Yes');
        Observer.Expect('obj_isarray', 'No');
        Observer.Expect('obj_isvalue', 'No');
        Observer.Expect('obj_asobject', 'ok:{"a":1}');
        Observer.Expect('obj_asarray', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonArray.|Conversion');
        Observer.Expect('obj_asvalue', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonValue.|Conversion');
        Observer.Verify();
    end;

    [Test]
    procedure ArrayToken()
    var
        A: JsonArray;
        T: JsonToken;
    begin
        A.Add(1);
        T := A.AsToken();
        Describe('arr', T);
        Observer.Expect('arr_isobject', 'No');
        Observer.Expect('arr_isarray', 'Yes');
        Observer.Expect('arr_isvalue', 'No');
        Observer.Expect('arr_asobject', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonObject.|Conversion');
        Observer.Expect('arr_asarray', 'ok:[1]');
        Observer.Expect('arr_asvalue', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonValue.|Conversion');
        Observer.Verify();
    end;

    [Test]
    procedure ValueTokens()
    var
        A: JsonArray;
        T: JsonToken;
    begin
        A.ReadFrom('[1,"s",true,null,1.5]');
        A.Get(0, T);
        Describe('int', T);
        A.Get(1, T);
        Describe('str', T);
        A.Get(2, T);
        Describe('bool', T);
        A.Get(3, T);
        Describe('null', T);
        Observer.Expect('int_isobject', 'No');
        Observer.Expect('int_isarray', 'No');
        Observer.Expect('int_isvalue', 'Yes');
        Observer.Expect('int_asobject', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonObject.|Conversion');
        Observer.Expect('int_asarray', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonArray.|Conversion');
        Observer.Expect('int_asvalue', 'ok:1');
        Observer.Expect('str_isobject', 'No');
        Observer.Expect('str_isarray', 'No');
        Observer.Expect('str_isvalue', 'Yes');
        Observer.Expect('str_asobject', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonObject.|Conversion');
        Observer.Expect('str_asarray', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonArray.|Conversion');
        Observer.Expect('str_asvalue', 'ok:"s"');
        Observer.Expect('bool_isobject', 'No');
        Observer.Expect('bool_isarray', 'No');
        Observer.Expect('bool_isvalue', 'Yes');
        Observer.Expect('bool_asobject', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonObject.|Conversion');
        Observer.Expect('bool_asarray', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonArray.|Conversion');
        Observer.Expect('bool_asvalue', 'ok:true');
        Observer.Expect('null_isobject', 'No');
        Observer.Expect('null_isarray', 'No');
        Observer.Expect('null_isvalue', 'Yes');
        Observer.Expect('null_asobject', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonObject.|Conversion');
        Observer.Expect('null_asarray', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonArray.|Conversion');
        Observer.Expect('null_asvalue', 'ok:null');
        Observer.Verify();
    end;

    [Test]
    procedure DefaultTokens()
    var
        T: JsonToken;
        O: JsonObject;
        A: JsonArray;
        V: JsonValue;
        Txt: Text;
    begin
        Describe('default_token', T);
        O.WriteTo(Txt);
        Observer.Observe('default_object', Txt);
        A.WriteTo(Txt);
        Observer.Observe('default_array', Txt);
        V.WriteTo(Txt);
        Observer.Observe('default_value', Txt);
        Observer.Observe('default_value_isnull', Format(V.IsNull()));
        Observer.Observe('default_value_isundefined', Format(V.IsUndefined()));
        Observer.Observe('default_object_count', Format(O.Keys().Count()));
        Observer.Observe('default_array_count', Format(A.Count()));
        Observer.Expect('default_token_isobject', 'No');
        Observer.Expect('default_token_isarray', 'No');
        Observer.Expect('default_token_isvalue', 'Yes');
        Observer.Expect('default_token_asobject', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonObject.|Conversion');
        Observer.Expect('default_token_asarray', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonArray.|Conversion');
        Observer.Expect('default_token_asvalue', 'ok:null');
        Observer.Expect('default_object', '{}');
        Observer.Expect('default_array', '[]');
        Observer.Expect('default_value', 'null');
        Observer.Expect('default_value_isnull', 'Yes');
        Observer.Expect('default_value_isundefined', 'No');
        Observer.Expect('default_object_count', '0');
        Observer.Expect('default_array_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TokenAssignmentSemantics()
    var
        O: JsonObject;
        O2: JsonObject;
        T: JsonToken;
        T2: JsonToken;
        Txt: Text;
    begin
        O.Add('a', 1);
        T := O.AsToken();
        T2 := T;
        O2 := T2.AsObject();
        O2.Add('b', 2);
        O.WriteTo(Txt);
        Observer.Observe('orig_after_alias_add', Txt);
        T2 := T.Clone();
        T2.AsObject().Add('c', 3);
        O.WriteTo(Txt);
        Observer.Observe('orig_after_clone_add', Txt);
        T2.WriteTo(Txt);
        Observer.Observe('clone', Txt);
        Observer.Observe('path_token', T.Path());
        Observer.Observe('path_clone', T2.Path());
        Observer.Expect('orig_after_alias_add', '{"a":1,"b":2}');
        Observer.Expect('orig_after_clone_add', '{"a":1,"b":2}');
        Observer.Expect('clone', '{"a":1,"b":2,"c":3}');
        Observer.Expect('path_token', '');
        Observer.Expect('path_clone', '');
        Observer.Verify();
    end;

    [Test]
    procedure TokenSelect()
    var
        O: JsonObject;
        Inner: JsonObject;
        T: JsonToken;
        R: JsonToken;
    begin
        Inner.Add('x', 5);
        O.Add('in', Inner);
        T := O.AsToken();
        Observer.Observe('select', Format(T.SelectToken('in.x', R)));
        Observer.Observe('select_val', Format(R.AsValue().AsInteger()));
        Observer.Observe('select_missing', Format(T.SelectToken('in.y', R)));
        Observer.Observe('select_on_value', Format(R.SelectToken('a', R)));
        Observer.Expect('select', 'Yes');
        Observer.Expect('select_val', '5');
        Observer.Expect('select_missing', 'No');
        Observer.Expect('select_on_value', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure TokenWriteReadFrom()
    var
        T: JsonToken;
        Txt: Text;
    begin
        Observer.Observe('read_object', Format(T.ReadFrom('{"a":1}')));
        T.WriteTo(Txt);
        Observer.Observe('object_text', Txt);
        Observer.Observe('object_isobject', Format(T.IsObject()));
        Observer.Observe('read_array', Format(T.ReadFrom('[1,2]')));
        T.WriteTo(Txt);
        Observer.Observe('array_text', Txt);
        Observer.Observe('array_isarray', Format(T.IsArray()));
        Observer.Observe('read_number', Format(T.ReadFrom('12')));
        T.WriteTo(Txt);
        Observer.Observe('number_text', Txt);
        Observer.Observe('number_isvalue', Format(T.IsValue()));
        Observer.Observe('read_string', Format(T.ReadFrom('"x"')));
        T.WriteTo(Txt);
        Observer.Observe('string_text', Txt);
        Observer.Observe('read_null', Format(T.ReadFrom('null')));
        T.WriteTo(Txt);
        Observer.Observe('null_text', Txt);
        Observer.Observe('read_true', Format(T.ReadFrom('true')));
        T.WriteTo(Txt);
        Observer.Observe('true_text', Txt);
        Observer.Expect('read_object', 'Yes');
        Observer.Expect('object_text', '{"a":1}');
        Observer.Expect('object_isobject', 'Yes');
        Observer.Expect('read_array', 'Yes');
        Observer.Expect('array_text', '[1,2]');
        Observer.Expect('array_isarray', 'Yes');
        Observer.Expect('read_number', 'Yes');
        Observer.Expect('number_text', '12');
        Observer.Expect('number_isvalue', 'Yes');
        Observer.Expect('read_string', 'Yes');
        Observer.Expect('string_text', '"x"');
        Observer.Expect('read_null', 'Yes');
        Observer.Expect('null_text', 'null');
        Observer.Expect('read_true', 'Yes');
        Observer.Expect('true_text', 'true');
        Observer.Verify();
    end;
}
