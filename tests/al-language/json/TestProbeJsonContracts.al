// Observe-only probes (writer A). Rows: JSON WriteTo compact, ReadFrom wrong kind, Add copy/share, Path, ISO reads,
// typed getter errors, exponent floats, Duration/Time/DateTime values, YAML.
codeunit 69801 "PA Json Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure WriteTo_CompactShape()
    var
        O: Codeunit "Probe Observer";
        Obj: JsonObject;
        Inner: JsonObject;
        Arr: JsonArray;
        Txt: Text;
    begin
        Inner.Add('z', 1);
        Inner.Add('a', 'x');
        Arr.Add(1);
        Arr.Add('two');
        Arr.Add(true);
        Arr.Add(Inner);
        Obj.Add('b', 'bee');
        Obj.Add('a', Arr);
        Obj.Add('c', 1.5);
        Obj.Add('d', false);
        Obj.Add('empty_obj', Inner);
        Obj.WriteTo(Txt);
        O.Observe('object', Txt);
        Arr.WriteTo(Txt);
        O.Observe('array', Txt);
        O.Expect('object', '{"b":"bee","a":[1,"two",true,{"z":1,"a":"x"}],"c":1.5,"d":false,"empty_obj":{"z":1,"a":"x"}}');
        O.Expect('array', '[1,"two",true,{"z":1,"a":"x"}]');
        O.Verify();
    end;

    [Test]
    procedure WriteTo_StringEscapes()
    var
        O: Codeunit "Probe Observer";
        Obj: JsonObject;
        Txt: Text;
        Nl: Text;
    begin
        Nl[1] := 10;
        Obj.Add('quote', 'a"b');
        Obj.Add('backslash', 'a\b');
        Obj.Add('newline', 'a' + Nl + 'b');
        Obj.Add('angle', '<a>&''x''');
        Obj.Add('umlaut', 'äö€');
        Obj.Add('slash', 'a/b');
        Obj.Add('key"with quote', 1);
        Obj.Add('', 'emptykey');
        Obj.WriteTo(Txt);
        O.Observe('escaped', Txt);
        O.Expect('escaped', '{"quote":"a\"b","backslash":"a\\b","newline":"a\nb","angle":"<a>&''x''","umlaut":"äö€","slash":"a/b","key\"with quote":1,"":"emptykey"}');
        O.Verify();
    end;

    [Test]
    procedure WriteTo_NumberForms()
    var
        O: Codeunit "Probe Observer";
        Arr: JsonArray;
        Txt: Text;
        D: Decimal;
        B: BigInteger;
    begin
        Arr.Add(1.0);
        Arr.Add(1.50);
        Arr.Add(0.0001);
        Arr.Add(0.00001);
        Arr.Add(0.000000001);
        Arr.Add(123456789012345.0);
        Arr.Add(1234567890123456.0);
        Arr.Add(12345678901234567890.0);
        Arr.Add(-0.5);
        Arr.Add(0);
        Evaluate(B, '9223372036854775807');
        Arr.Add(B);
        D := 1;
        D := D / 3;
        Arr.Add(D);
        Arr.WriteTo(Txt);
        O.Observe('numbers', Txt);
        O.Expect('numbers', '[1.0,1.50,0.0001,0.00001,0.000000001,123456789012345.0,1234567890123456.0,12345678901234567900.0,-0.5,0,9223372036854775807,0.333333333333333333]');
        O.Verify();
    end;

    [Test]
    procedure ReadFrom_ArrayIntoObject_ResultUsed()
    var
        O: Codeunit "Probe Observer";
        Obj: JsonObject;
        Arr: JsonArray;
    begin
        O.Observe('array_into_object', Format(Obj.ReadFrom('[1,2]')));
        O.Observe('object_into_array', Format(Arr.ReadFrom('{"a":1}')));
        O.Observe('scalar_into_object', Format(Obj.ReadFrom('5')));
        O.Observe('empty_into_object', Format(Obj.ReadFrom('')));
        O.Observe('null_into_object', Format(Obj.ReadFrom('null')));
        O.Observe('invalid_into_object', Format(Obj.ReadFrom('{bad')));
        O.Expect('array_into_object', 'No');
        O.Expect('object_into_array', 'No');
        O.Expect('scalar_into_object', 'No');
        O.Expect('empty_into_object', 'No');
        O.Expect('null_into_object', 'No');
        O.Expect('invalid_into_object', 'No');
        O.Verify();
    end;

    [Test]
    procedure ReadFrom_ArrayIntoObject_Statement()
    var
        O: Codeunit "Probe Observer";
        Obj: JsonObject;
    begin
        asserterror Obj.ReadFrom('[1,2]');
        O.ObserveError('array_into_object_statement');
        O.Expect('array_into_object_statement|text', 'JSON tokens of type ''Array'' are not supported by this implementation.');
        O.Expect('array_into_object_statement|code', 'InvalidJsonType');
        O.Verify();
    end;

    [Test]
    procedure ReadFrom_ObjectIntoArray_Statement()
    var
        O: Codeunit "Probe Observer";
        Arr: JsonArray;
    begin
        asserterror Arr.ReadFrom('{"a":1}');
        O.ObserveError('object_into_array_statement');
        O.Expect('object_into_array_statement|text', 'JSON tokens of type ''Object'' are not supported by this implementation.');
        O.Expect('object_into_array_statement|code', 'InvalidJsonType');
        O.Verify();
    end;

    [Test]
    procedure ReadFrom_Invalid_Statement()
    var
        O: Codeunit "Probe Observer";
        Obj: JsonObject;
        Tok: JsonToken;
    begin
        asserterror Obj.ReadFrom('{bad');
        O.ObserveError('invalid_object');
        asserterror Tok.ReadFrom('');
        O.ObserveError('empty_token');
        Tok.ReadFrom('{"a":1} trailing');
        O.Observe('trailing_garbage', 'no error');
        O.Expect('invalid_object|text', 'The data does not represent a valid JSON token.');
        O.Expect('invalid_object|code', 'InvalidJsonData');
        O.Expect('empty_token|text', 'The data does not represent a valid JSON token.');
        O.Expect('empty_token|code', 'InvalidJsonData');
        O.Expect('trailing_garbage', 'no error');
        O.Verify();
    end;

    [Test]
    procedure Add_TokenWithParent_CopyOrShare()
    var
        O: Codeunit "Probe Observer";
        P1: JsonObject;
        P2: JsonObject;
        Child: JsonObject;
        Tok: JsonToken;
        Tok2: JsonToken;
        Txt: Text;
    begin
        // free (unattached) object added: shared?
        Child.Add('x', 1);
        P1.Add('c', Child);
        Child.Add('y', 2);
        P1.WriteTo(Txt);
        O.Observe('free_child_after_later_change_via_original', Txt);
        // token that already has a parent added elsewhere: copy?
        P1.Get('c', Tok);
        P2.Add('c', Tok);
        Tok.AsObject().Add('z', 3);
        P1.WriteTo(Txt);
        O.Observe('p1_after_change_via_token', Txt);
        P2.WriteTo(Txt);
        O.Observe('p2_after_change_via_token', Txt);
        P2.Get('c', Tok2);
        Tok2.AsObject().Add('w', 4);
        P1.WriteTo(Txt);
        O.Observe('p1_after_change_via_p2_token', Txt);
        P2.WriteTo(Txt);
        O.Observe('p2_after_change_via_p2_token', Txt);
        O.Expect('free_child_after_later_change_via_original', '{"c":{"x":1,"y":2}}');
        O.Expect('p1_after_change_via_token', '{"c":{"x":1,"y":2,"z":3}}');
        O.Expect('p2_after_change_via_token', '{"c":{"x":1,"y":2}}');
        O.Expect('p1_after_change_via_p2_token', '{"c":{"x":1,"y":2,"z":3}}');
        O.Expect('p2_after_change_via_p2_token', '{"c":{"x":1,"y":2,"w":4}}');
        O.Verify();
    end;

    [Test]
    procedure Add_ArrayElementWithParent_CopyOrShare()
    var
        O: Codeunit "Probe Observer";
        A1: JsonArray;
        A2: JsonArray;
        Child: JsonObject;
        Tok: JsonToken;
        Txt: Text;
    begin
        Child.Add('x', 1);
        A1.Add(Child);
        A1.Get(0, Tok);
        A2.Add(Tok);
        Tok.AsObject().Add('after', 2);
        A1.WriteTo(Txt);
        O.Observe('a1', Txt);
        A2.WriteTo(Txt);
        O.Observe('a2', Txt);
        Child.Add('late', 3);
        A1.WriteTo(Txt);
        O.Observe('a1_after_original_change', Txt);
        A2.WriteTo(Txt);
        O.Observe('a2_after_original_change', Txt);
        O.Expect('a1', '[{"x":1,"after":2}]');
        O.Expect('a2', '[{"x":1}]');
        O.Expect('a1_after_original_change', '[{"x":1,"after":2,"late":3}]');
        O.Expect('a2_after_original_change', '[{"x":1}]');
        O.Verify();
    end;

    [Test]
    procedure Path_Forms()
    var
        O: Codeunit "Probe Observer";
        Root: JsonObject;
        Tok: JsonToken;
        Tok2: JsonToken;
        Tok3: JsonToken;
    begin
        Root.ReadFrom('{"a":{"b":[10,{"c":"deep"}]},"key with space":1,"dotted.key":2,"quote":3,"0":4}');
        O.Observe('root_path', '[' + Root.AsToken().Path() + ']');
        Root.SelectToken('a', Tok);
        O.Observe('a', Tok.Path());
        Root.SelectToken('a.b', Tok);
        O.Observe('a_b', Tok.Path());
        Root.SelectToken('a.b[0]', Tok2);
        O.Observe('a_b_0', Tok2.Path());
        Root.SelectToken('a.b[1].c', Tok3);
        O.Observe('a_b_1_c', Tok3.Path());
        Root.SelectToken('[''key with space'']', Tok);
        O.Observe('key_with_space', Tok.Path());
        Root.SelectToken('[''dotted.key'']', Tok);
        O.Observe('dotted_key', Tok.Path());
        Root.SelectToken('[''0'']', Tok);
        O.Observe('numeric_key', Tok.Path());
        Root.Get('a', Tok);
        O.Observe('get_a_path', Tok.Path());
        O.Expect('root_path', '[]');
        O.Expect('a', 'a');
        O.Expect('a_b', 'a.b');
        O.Expect('a_b_0', 'a.b[0]');
        O.Expect('a_b_1_c', 'a.b[1].c');
        O.Expect('key_with_space', '[''key with space'']');
        O.Expect('dotted_key', '[''dotted.key'']');
        O.Expect('numeric_key', '0');
        O.Expect('get_a_path', 'a');
        O.Verify();
    end;

    [Test]
    procedure IsoText_ReadAsDateTimeKinds()
    var
        O: Codeunit "Probe Observer";
        Obj: JsonObject;
    begin
        Obj.ReadFrom('{"d":"2024-01-15","dt":"2024-01-15T10:20:30Z","dtnoz":"2024-01-15T10:20:30","dtoff":"2024-01-15T10:20:30+02:00","dtms":"2024-01-15T10:20:30.123Z","t":"10:20:30","tms":"10:20:30.5","n":1500,"nd":"1500","bad":"hello","dsl":"15.01.2024","dus":"01/15/2024"}');
        O.Observe('d_as_date', TryAs(Obj, 'd', 'date'));
        O.Observe('d_as_datetime', TryAs(Obj, 'd', 'datetime'));
        O.Observe('dt_as_datetime', TryAs(Obj, 'dt', 'datetime'));
        O.Observe('dt_as_date', TryAs(Obj, 'dt', 'date'));
        O.Observe('dt_as_time', TryAs(Obj, 'dt', 'time'));
        O.Observe('dtnoz_as_datetime', TryAs(Obj, 'dtnoz', 'datetime'));
        O.Observe('dtoff_as_datetime', TryAs(Obj, 'dtoff', 'datetime'));
        O.Observe('dtms_as_datetime', TryAs(Obj, 'dtms', 'datetime'));
        O.Observe('t_as_time', TryAs(Obj, 't', 'time'));
        O.Observe('tms_as_time', TryAs(Obj, 'tms', 'time'));
        O.Observe('n_as_duration', TryAs(Obj, 'n', 'duration'));
        O.Observe('nd_as_duration', TryAs(Obj, 'nd', 'duration'));
        O.Observe('bad_as_date', TryAs(Obj, 'bad', 'date'));
        O.Observe('dsl_as_date', TryAs(Obj, 'dsl', 'date'));
        O.Observe('dus_as_date', TryAs(Obj, 'dus', 'date'));
        O.Observe('n_as_datetime', TryAs(Obj, 'n', 'datetime'));
        O.Expect('d_as_date', '2024-01-15');
        O.Expect('d_as_datetime', 'ERR:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDateTime./Conversion');
        O.Expect('dt_as_datetime', '2024-01-15T10:20:30Z');
        O.Expect('dt_as_date', 'ERR:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDate./Conversion');
        O.Expect('dt_as_time', 'ERR:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavTime./Conversion');
        O.Expect('dtnoz_as_datetime', '2024-01-15T10:20:30Z');
        O.Expect('dtoff_as_datetime', '2024-01-15T08:20:30Z');
        O.Expect('dtms_as_datetime', '2024-01-15T10:20:30.123Z');
        O.Expect('t_as_time', '10:20:30');
        O.Expect('tms_as_time', '10:20:30.5');
        O.Expect('n_as_duration', 'P0DT0H0M1.5S');
        O.Expect('nd_as_duration', 'P0DT0H0M1.5S');
        O.Expect('bad_as_date', 'ERR:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDate./Conversion');
        O.Expect('dsl_as_date', 'ERR:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDate./Conversion');
        O.Expect('dus_as_date', 'ERR:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDate./Conversion');
        O.Expect('n_as_datetime', 'ERR:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDateTime./Conversion');
        O.Verify();
    end;

    local procedure TryAs(Obj: JsonObject; KeyName: Text; Kind: Text): Text
    var
        Res: Text;
    begin
        if TryAsF(Obj, KeyName, Kind, Res) then
            exit(Res);
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryAsF(Obj: JsonObject; KeyName: Text; Kind: Text; var Res: Text)
    var
        Tok: JsonToken;
    begin
        Obj.Get(KeyName, Tok);
        case Kind of
            'date':
                Res := Format(Tok.AsValue().AsDate(), 0, 9);
            'datetime':
                Res := Format(Tok.AsValue().AsDateTime(), 0, 9);
            'time':
                Res := Format(Tok.AsValue().AsTime(), 0, 9);
            'duration':
                Res := Format(Tok.AsValue().AsDuration(), 0, 9);
        end;
    end;

    [Test]
    procedure TypedGetters_OutOfRangeAndMissing()
    var
        O: Codeunit "Probe Observer";
        Arr: JsonArray;
        Obj: JsonObject;
        T: Text;
        IntV: Integer;
        ObjV: JsonObject;
    begin
        Arr.Add('a');
        Obj.Add('k', 'v');
        asserterror T := Arr.GetText(5);
        O.ObserveError('array_gettext_5');
        asserterror T := Arr.GetText(-1);
        O.ObserveError('array_gettext_minus1');
        asserterror IntV := Arr.GetInteger(5);
        O.ObserveError('array_getinteger_5');
        asserterror ObjV := Arr.GetObject(5);
        O.ObserveError('array_getobject_5');
        asserterror T := Obj.GetText('missing');
        O.ObserveError('object_gettext_missing');
        asserterror IntV := Obj.GetInteger('missing');
        O.ObserveError('object_getinteger_missing');
        asserterror ObjV := Obj.GetObject('missing');
        O.ObserveError('object_getobject_missing');
        O.Expect('array_gettext_5|text', 'Index out of bounds.');
        O.Expect('array_gettext_5|code', 'IndexOutOfBounds');
        O.Expect('array_gettext_minus1|text', 'Index out of bounds.');
        O.Expect('array_gettext_minus1|code', 'IndexOutOfBounds');
        O.Expect('array_getinteger_5|text', 'Index out of bounds.');
        O.Expect('array_getinteger_5|code', 'IndexOutOfBounds');
        O.Expect('array_getobject_5|text', 'Index out of bounds.');
        O.Expect('array_getobject_5|code', 'IndexOutOfBounds');
        O.Expect('object_gettext_missing|text', 'There is no property with the ''missing'' key on the JSON object.');
        O.Expect('object_gettext_missing|code', 'JsonPropertyNotFound');
        O.Expect('object_getinteger_missing|text', 'There is no property with the ''missing'' key on the JSON object.');
        O.Expect('object_getinteger_missing|code', 'JsonPropertyNotFound');
        O.Expect('object_getobject_missing|text', 'There is no property with the ''missing'' key on the JSON object.');
        O.Expect('object_getobject_missing|code', 'JsonPropertyNotFound');
        O.Verify();
    end;

    [Test]
    procedure TypedGetters_WrongKinds()
    var
        O: Codeunit "Probe Observer";
        Obj: JsonObject;
        Tok: JsonToken;
        I: Integer;
        T: Text;
    begin
        Obj.ReadFrom('{"num":12,"numtext":"12","txt":"abc","obj":{"a":1},"arr":[1],"b":true,"nul":null}');
        Obj.Get('num', Tok);
        asserterror T := Tok.AsObject().Keys().Get(1);
        O.ObserveError('value_asobject');
        Obj.Get('obj', Tok);
        asserterror I := Tok.AsArray().Count();
        O.ObserveError('object_asarray');
        Obj.Get('arr', Tok);
        asserterror I := Tok.AsValue().AsInteger();
        O.ObserveError('array_asvalue');
        I := Obj.GetInteger('numtext');
        O.Observe('getinteger_of_numeric_text', 'no error');
        asserterror I := Obj.GetInteger('txt');
        O.ObserveError('getinteger_of_text');
        T := Obj.GetText('num');
        O.Observe('gettext_of_number', 'no error');
        T := Obj.GetText('obj');
        O.Observe('gettext_of_object', 'no error');
        T := Obj.GetText('nul');
        O.Observe('gettext_of_null', 'no error');
        O.Observe('gettext_of_bool', TryGetText(Obj, 'b'));
        O.Observe('getinteger_of_null', TryGetInt(Obj, 'nul'));
        O.Expect('value_asobject|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonObject.');
        O.Expect('value_asobject|code', 'Conversion');
        O.Expect('object_asarray|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonArray.');
        O.Expect('object_asarray|code', 'Conversion');
        O.Expect('array_asvalue|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonValue.');
        O.Expect('array_asvalue|code', 'Conversion');
        O.Expect('getinteger_of_numeric_text', 'no error');
        O.Expect('getinteger_of_text|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Int32.');
        O.Expect('getinteger_of_text|code', 'Conversion');
        O.Expect('gettext_of_number', 'no error');
        O.Expect('gettext_of_object', 'no error');
        O.Expect('gettext_of_null', 'no error');
        O.Expect('gettext_of_bool', 'ok:True');
        O.Expect('getinteger_of_null', 'ERR:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Int32./Conversion');
        O.Verify();
    end;

    local procedure TryGetText(Obj: JsonObject; KeyName: Text): Text
    var
        R: Text;
    begin
        if TryGetTextF(Obj, KeyName, R) then
            exit('ok:' + R);
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryGetTextF(Obj: JsonObject; KeyName: Text; var R: Text)
    begin
        R := Obj.GetText(KeyName);
    end;

    local procedure TryGetInt(Obj: JsonObject; KeyName: Text): Text
    var
        R: Integer;
    begin
        if TryGetIntF(Obj, KeyName, R) then
            exit('ok:' + Format(R));
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryGetIntF(Obj: JsonObject; KeyName: Text; var R: Integer)
    begin
        R := Obj.GetInteger(KeyName);
    end;

    [Test]
    procedure ExponentNumbers_ReadAndWrite()
    var
        O: Codeunit "Probe Observer";
        Obj: JsonObject;
        Tok: JsonToken;
        Txt: Text;
        K: Text;
    begin
        Obj.ReadFrom('{"a":1e-5,"b":1E15,"c":1.5e300,"d":1e20,"e":0.00001,"f":123456789012345678901234567890,"g":1e3,"h":-0.0,"i":0.1,"j":1E-7}');
        Obj.WriteTo(Txt);
        O.Observe('roundtrip', Txt);
        O.Expect('roundtrip', '{"a":1E-05,"b":1000000000000000.0,"c":1.5E+300,"d":1E+20,"e":1E-05,"f":123456789012345678901234567890,"g":1000.0,"h":-0.0,"i":0.1,"j":1E-07}');
        O.Verify();
    end;

    local procedure TryDec(Tok: JsonToken): Text
    var
        R: Decimal;
    begin
        if TryDecF(Tok, R) then
            exit(Format(R, 0, 9));
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryDecF(Tok: JsonToken; var R: Decimal)
    begin
        R := Tok.AsValue().AsDecimal();
    end;

    [Test]
    procedure ValueTypes_DurationTimeDateTime()
    var
        O: Codeunit "Probe Observer";
        Obj: JsonObject;
        V: JsonValue;
        Txt: Text;
        Dur: Duration;
        T: Time;
        Dt: DateTime;
        D: Date;
    begin
        Dur := 1500;
        V.SetValue(Dur);
        Obj.Add('dur', V.AsToken());
        T := 100000T + 123;
        V.SetValue(T);
        Obj.Add('time_ms', V.AsToken());
        T := 100000T;
        V.SetValue(T);
        Obj.Add('time_noms', V.AsToken());
        Dt := CreateDateTime(DMY2Date(15, 1, 2024), 102030T + 45);
        V.SetValue(Dt);
        Obj.Add('dt_ms', V.AsToken());
        Dt := CreateDateTime(DMY2Date(15, 1, 2024), 102030T);
        V.SetValue(Dt);
        Obj.Add('dt_noms', V.AsToken());
        D := DMY2Date(15, 1, 2024);
        V.SetValue(D);
        Obj.Add('date', V.AsToken());
        Obj.WriteTo(Txt);
        O.Observe('all', Txt);
        O.Expect('all', '{"dur":1500,"time_ms":"10:00:00.123","time_noms":"10:00:00","dt_ms":"2024-01-15T10:20:30.0450000Z","dt_noms":"2024-01-15T10:20:30.0000000Z","date":"2024-01-15"}');
        O.Verify();
    end;

    [Test]
    procedure Yaml_WriteNested()
    var
        O: Codeunit "Probe Observer";
        Obj: JsonObject;
        Inner: JsonObject;
        Arr: JsonArray;
    begin
        Inner.Add('x', 1);
        Arr.Add('one');
        Arr.Add(2);
        Obj.Add('plain', 'text');
        Obj.Add('num', 3);
        Obj.Add('flag', true);
        Obj.Add('nested', Inner);
        Obj.Add('list', Arr);
        Obj.Add('needs_quote', 'a: b # c');
        Obj.Add('colon_start', ': x');
        Obj.Add('numeric_text', '123');
        Obj.Add('true_text', 'true');
        Obj.Add('empty_text', '');
        O.Observe('yaml', TryYaml(Obj));
        O.Expect('yaml', 'plain: text\nnum: 3\nflag: true\nnested:\n  x: 1\nlist:\n- one\n- 2\nneeds_quote: ''a: b # c''\ncolon_start: '': x''\nnumeric_text: 123\ntrue_text: true\nempty_text: ''''\n');
        O.Verify();
    end;

    local procedure TryYaml(Obj: JsonObject): Text
    var
        R: Text;
    begin
        if TryYamlF(Obj, R) then
            exit(R);
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryYamlF(Obj: JsonObject; var R: Text)
    begin
        Obj.WriteToYaml(R);
    end;

    [Test]
    procedure Yaml_Read()
    var
        O: Codeunit "Probe Observer";
        Obj: JsonObject;
        Txt: Text;
    begin
        O.Observe('read_flat', TryRead('a: 1' + '\n' + 'b: text'));
        O.Observe('read_nested', TryRead('a:' + '\n' + '  b: 1'));
        O.Expect('read_flat', 'ERR:The data does not represent valid YAML./YamlBadFormat');
        O.Expect('read_nested', '{"a:\\n  b":"1"}');
        O.Verify();
    end;

    local procedure TryRead(Y: Text): Text
    var
        R: Text;
    begin
        if TryReadF(Y, R) then
            exit(R);
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryReadF(Y: Text; var R: Text)
    var
        Obj: JsonObject;
    begin
        Obj.ReadFromYaml(Y);
        Obj.WriteTo(R);
    end;
}
