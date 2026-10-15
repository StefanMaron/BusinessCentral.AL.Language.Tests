// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-readfrom-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunit 72505
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 72505 "LT JsT ReadFrom"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure DoReadObj(Json: Text; var R: Text)
    var
        O: JsonObject;
    begin
        O.Add('pre', 1);
        R := 'ret=' + Format(O.ReadFrom(Json)) + ' ';
        O.WriteTo(Json);
        R += Json;
    end;

    local procedure ReadObj(Json: Text): Text
    var
        R: Text;
    begin
        if DoReadObj(Json, R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure DoReadArr(Json: Text; var R: Text)
    var
        A: JsonArray;
    begin
        A.Add(1);
        R := 'ret=' + Format(A.ReadFrom(Json)) + ' ';
        A.WriteTo(Json);
        R += Json;
    end;

    local procedure ReadArr(Json: Text): Text
    var
        R: Text;
    begin
        if DoReadArr(Json, R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure DoReadTok(Json: Text; var R: Text)
    var
        T: JsonToken;
    begin
        R := 'ret=' + Format(T.ReadFrom(Json)) + ' ';
        T.WriteTo(Json);
        R += Json;
    end;

    local procedure ReadTok(Json: Text): Text
    var
        R: Text;
    begin
        if DoReadTok(Json, R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Lf(): Text
    var
        C: Text[1];
    begin
        C[1] := 10;
        exit(C);
    end;

    [Test]
    procedure ObjectReadFromErrors()
    begin
        Observer.Observe('valid', ReadObj('{"a":1}'));
        Observer.Observe('empty_obj_replaces', ReadObj('{}'));
        Observer.Observe('array', ReadObj('[1]'));
        Observer.Observe('scalar_number', ReadObj('1'));
        Observer.Observe('scalar_string', ReadObj('"x"'));
        Observer.Observe('null', ReadObj('null'));
        Observer.Observe('empty_text', ReadObj(''));
        Observer.Observe('blank', ReadObj('   '));
        Observer.Observe('garbage', ReadObj('abc'));
        Observer.Observe('unclosed', ReadObj('{"a":1'));
        Observer.Observe('trailing_comma', ReadObj('{"a":1,}'));
        Observer.Observe('single_quotes', ReadObj('{''a'':1}'));
        Observer.Observe('unquoted_key', ReadObj('{a:1}'));
        Observer.Observe('trailing_text', ReadObj('{"a":1} x'));
        Observer.Observe('two_objects', ReadObj('{"a":1}{"b":2}'));
        Observer.Observe('missing_value', ReadObj('{"a":}'));
        Observer.Observe('missing_colon', ReadObj('{"a" 1}'));
        Observer.Observe('leading_ws', ReadObj('  {"a":1}  '));
        Observer.Observe('comment', ReadObj('{"a":1/*c*/}'));
        Observer.Expect('valid', 'ok:ret=Yes {"a":1}');
        Observer.Expect('empty_obj_replaces', 'ok:ret=Yes {}');
        Observer.Expect('array', 'ok:ret=No {"pre":1}');
        Observer.Expect('scalar_number', 'ok:ret=No {"pre":1}');
        Observer.Expect('scalar_string', 'ok:ret=No {"pre":1}');
        Observer.Expect('null', 'ok:ret=No {"pre":1}');
        Observer.Expect('empty_text', 'ok:ret=No {"pre":1}');
        Observer.Expect('blank', 'ok:ret=No {"pre":1}');
        Observer.Expect('garbage', 'ok:ret=No {"pre":1}');
        Observer.Expect('unclosed', 'ok:ret=No {"pre":1}');
        Observer.Expect('trailing_comma', 'ok:ret=Yes {"a":1}');
        Observer.Expect('single_quotes', 'ok:ret=Yes {"a":1}');
        Observer.Expect('unquoted_key', 'ok:ret=Yes {"a":1}');
        Observer.Expect('trailing_text', 'ok:ret=Yes {"a":1}');
        Observer.Expect('two_objects', 'ok:ret=Yes {"a":1}');
        Observer.Expect('missing_value', 'ok:ret=No {"pre":1}');
        Observer.Expect('missing_colon', 'ok:ret=No {"pre":1}');
        Observer.Expect('leading_ws', 'ok:ret=Yes {"a":1}');
        Observer.Expect('comment', 'ok:ret=Yes {"a":1}');
        Observer.Verify();
    end;

    [Test]
    procedure ObjectDuplicateAndOrder()
    begin
        Observer.Observe('dup_keys', ReadObj('{"a":1,"a":2}'));
        Observer.Observe('dup_keys_case', ReadObj('{"a":1,"A":2}'));
        Observer.Observe('order', ReadObj('{"z":1,"a":2,"m":3}'));
        Observer.Observe('empty_key', ReadObj('{"":1}'));
        Observer.Observe('nested', ReadObj('{"a":{"b":{"c":[1,{"d":null}]}}}'));
        Observer.Observe('null_value', ReadObj('{"a":null}'));
        Observer.Observe('escapes', ReadObj('{"a":"\"\\\/\b\f\n\r\t"}'));
        Observer.Observe('unicode_escape', ReadObj('{"a":"ä€"}'));
        Observer.Observe('surrogate_pair', ReadObj('{"a":"😀"}'));
        Observer.Observe('bad_escape', ReadObj('{"a":"\x"}'));
        Observer.Observe('bad_unicode_escape', ReadObj('{"a":"\u12"}'));
        Observer.Observe('raw_newline_in_string', ReadObj('{"a":"x' + Lf() + 'y"}'));
        Observer.Expect('dup_keys', 'ok:ret=Yes {"a":2}');
        Observer.Expect('dup_keys_case', 'ok:ret=Yes {"a":1,"A":2}');
        Observer.Expect('order', 'ok:ret=Yes {"z":1,"a":2,"m":3}');
        Observer.Expect('empty_key', 'ok:ret=Yes {"":1}');
        Observer.Expect('nested', 'ok:ret=Yes {"a":{"b":{"c":[1,{"d":null}]}}}');
        Observer.Expect('null_value', 'ok:ret=Yes {"a":null}');
        Observer.Expect('escapes', 'ok:ret=Yes {"a":"\"\\/\b\f\n\r\t"}');
        Observer.Expect('unicode_escape', 'ok:ret=Yes {"a":"ä€"}');
        Observer.Expect('surrogate_pair', 'ok:ret=Yes {"a":"\uD83D\uDE00"}');
        Observer.Expect('bad_escape', 'ok:ret=No {"pre":1}');
        Observer.Expect('bad_unicode_escape', 'ok:ret=No {"pre":1}');
        Observer.Expect('raw_newline_in_string', 'ok:ret=Yes {"a":"x\ny"}');
        Observer.Verify();
    end;

    [Test]
    procedure NumberTextsRoundtrip()
    begin
        Observer.Observe('int', ReadArr('[1]'));
        Observer.Observe('neg', ReadArr('[-1]'));
        Observer.Observe('neg_zero', ReadArr('[-0]'));
        Observer.Observe('zero_point_zero', ReadArr('[0.0]'));
        Observer.Observe('one_point_zero', ReadArr('[1.0]'));
        Observer.Observe('one_point_five_zero', ReadArr('[1.50]'));
        Observer.Observe('exp', ReadArr('[1e3]'));
        Observer.Observe('exp_big', ReadArr('[1E+3]'));
        Observer.Observe('exp_neg', ReadArr('[1e-3]'));
        Observer.Observe('exp_float', ReadArr('[1.5e2]'));
        Observer.Observe('long_int', ReadArr('[9223372036854775807]'));
        Observer.Observe('over_long', ReadArr('[9223372036854775808]'));
        Observer.Observe('huge', ReadArr('[123456789012345678901234567890]'));
        Observer.Observe('many_decimals', ReadArr('[0.1234567890123456789]'));
        Observer.Observe('float_noise', ReadArr('[0.30000000000000004]'));
        Observer.Observe('leading_zero', ReadArr('[01]'));
        Observer.Observe('plus_sign', ReadArr('[+1]'));
        Observer.Observe('dot_start', ReadArr('[.5]'));
        Observer.Observe('dot_end', ReadArr('[5.]'));
        Observer.Observe('nan', ReadArr('[NaN]'));
        Observer.Observe('infinity', ReadArr('[Infinity]'));
        Observer.Observe('hex', ReadArr('[0x10]'));
        Observer.Observe('too_big_exp', ReadArr('[1e400]'));
        Observer.Expect('int', 'ok:ret=Yes [1]');
        Observer.Expect('neg', 'ok:ret=Yes [-1]');
        Observer.Expect('neg_zero', 'ok:ret=Yes [0]');
        Observer.Expect('zero_point_zero', 'ok:ret=Yes [0.0]');
        Observer.Expect('one_point_zero', 'ok:ret=Yes [1.0]');
        Observer.Expect('one_point_five_zero', 'ok:ret=Yes [1.5]');
        Observer.Expect('exp', 'ok:ret=Yes [1000.0]');
        Observer.Expect('exp_big', 'ok:ret=Yes [1000.0]');
        Observer.Expect('exp_neg', 'ok:ret=Yes [0.001]');
        Observer.Expect('exp_float', 'ok:ret=Yes [150.0]');
        Observer.Expect('long_int', 'ok:ret=Yes [9223372036854775807]');
        Observer.Expect('over_long', 'ok:ret=Yes [9223372036854775808]');
        Observer.Expect('huge', 'ok:ret=Yes [123456789012345678901234567890]');
        Observer.Expect('many_decimals', 'ok:ret=Yes [0.12345678901234568]');
        Observer.Expect('float_noise', 'ok:ret=Yes [0.30000000000000004]');
        Observer.Expect('leading_zero', 'ok:ret=Yes [1]');
        Observer.Expect('plus_sign', 'ok:ret=No [1]');
        Observer.Expect('dot_start', 'ok:ret=Yes [0.5]');
        Observer.Expect('dot_end', 'ok:ret=Yes [5.0]');
        Observer.Expect('nan', 'ok:ret=Yes ["NaN"]');
        Observer.Expect('infinity', 'ok:ret=Yes ["Infinity"]');
        Observer.Expect('hex', 'ok:ret=Yes [16]');
        Observer.Expect('too_big_exp', 'ok:ret=Yes ["Infinity"]');
        Observer.Verify();
    end;

    [Test]
    procedure ArrayReadFrom()
    begin
        Observer.Observe('empty_array', ReadArr('[]'));
        Observer.Observe('nested', ReadArr('[[],[[]],{}]'));
        Observer.Observe('mixed', ReadArr('[1,"a",true,null,{"k":[]}]'));
        Observer.Observe('trailing_comma', ReadArr('[1,]'));
        Observer.Observe('leading_comma', ReadArr('[,1]'));
        Observer.Observe('double_comma', ReadArr('[1,,2]'));
        Observer.Observe('unclosed', ReadArr('[1'));
        Observer.Observe('scalar', ReadArr('5'));
        Observer.Observe('blank', ReadArr(' '));
        Observer.Observe('object_text', ReadArr('{}'));
        Observer.Observe('deep', ReadArr('[[[[[[[[[[[[[[[[[[[[1]]]]]]]]]]]]]]]]]]]]'));
        Observer.Expect('empty_array', 'ok:ret=Yes []');
        Observer.Expect('nested', 'ok:ret=Yes [[],[[]],{}]');
        Observer.Expect('mixed', 'ok:ret=Yes [1,"a",true,null,{"k":[]}]');
        Observer.Expect('trailing_comma', 'ok:ret=Yes [1]');
        Observer.Expect('leading_comma', 'ok:ret=Yes [undefined,1]');
        Observer.Expect('double_comma', 'ok:ret=Yes [1,undefined,2]');
        Observer.Expect('unclosed', 'ok:ret=No [1]');
        Observer.Expect('scalar', 'ok:ret=No [1]');
        Observer.Expect('blank', 'ok:ret=No [1]');
        Observer.Expect('object_text', 'ok:ret=No [1]');
        Observer.Expect('deep', 'ok:ret=Yes [[[[[[[[[[[[[[[[[[[[1]]]]]]]]]]]]]]]]]]]]');
        Observer.Verify();
    end;

    [Test]
    procedure TokenReadFromScalars()
    begin
        Observer.Observe('int', ReadTok('1'));
        Observer.Observe('string', ReadTok('"abc"'));
        Observer.Observe('true', ReadTok('true'));
        Observer.Observe('false', ReadTok('false'));
        Observer.Observe('null', ReadTok('null'));
        Observer.Observe('upper_true', ReadTok('True'));
        Observer.Observe('empty', ReadTok(''));
        Observer.Observe('blank', ReadTok('  '));
        Observer.Observe('bare_word', ReadTok('abc'));
        Observer.Observe('single_quoted', ReadTok('''abc'''));
        Observer.Observe('unterminated_string', ReadTok('"abc'));
        Observer.Observe('padded_int', ReadTok('  7  '));
        Observer.Observe('two_scalars', ReadTok('1 2'));
        Observer.Observe('undefined', ReadTok('undefined'));
        Observer.Observe('empty_string', ReadTok('""'));
        Observer.Observe('object', ReadTok('{"a":[]}'));
        Observer.Observe('array', ReadTok('[ ]'));
        Observer.Observe('pretty', ReadTok('{ "a" : [ 1 , 2 ] }'));
        Observer.Expect('int', 'ok:ret=Yes 1');
        Observer.Expect('string', 'ok:ret=Yes "abc"');
        Observer.Expect('true', 'ok:ret=Yes true');
        Observer.Expect('false', 'ok:ret=Yes false');
        Observer.Expect('null', 'ok:ret=Yes null');
        Observer.Expect('upper_true', 'ok:ret=No null');
        Observer.Expect('empty', 'ok:ret=No null');
        Observer.Expect('blank', 'ok:ret=No null');
        Observer.Expect('bare_word', 'ok:ret=No null');
        Observer.Expect('single_quoted', 'ok:ret=Yes "abc"');
        Observer.Expect('unterminated_string', 'ok:ret=No null');
        Observer.Expect('padded_int', 'ok:ret=Yes 7');
        Observer.Expect('two_scalars', 'ok:ret=Yes 1');
        Observer.Expect('undefined', 'ok:ret=Yes undefined');
        Observer.Expect('empty_string', 'ok:ret=Yes ""');
        Observer.Expect('object', 'ok:ret=Yes {"a":[]}');
        Observer.Expect('array', 'ok:ret=Yes []');
        Observer.Expect('pretty', 'ok:ret=Yes {"a":[1,2]}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromReplacesContent()
    var
        O: JsonObject;
        A: JsonArray;
        Txt: Text;
    begin
        O.Add('old', 1);
        O.ReadFrom('{"new":2}');
        O.WriteTo(Txt);
        Observer.Observe('object_replaced', Txt);
        asserterror O.ReadFrom('garbage');
        Observer.ObserveError('af206');
        O.WriteTo(Txt);
        Observer.Observe('object_after_failed_read', Txt);
        A.Add(1);
        A.ReadFrom('[2]');
        A.WriteTo(Txt);
        Observer.Observe('array_replaced', Txt);
        asserterror A.ReadFrom('garbage');
        Observer.ObserveError('af214');
        A.WriteTo(Txt);
        Observer.Observe('array_after_failed_read', Txt);
        Observer.Expect('object_replaced', '{"new":2}');
        Observer.Expect('af206|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('af206|code', 'InvalidJsonData');
        Observer.Expect('object_after_failed_read', '{"new":2}');
        Observer.Expect('array_replaced', '[2]');
        Observer.Expect('af214|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('af214|code', 'InvalidJsonData');
        Observer.Expect('array_after_failed_read', '[2]');
        Observer.Verify();
    end;
}
