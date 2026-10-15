// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonvalue/jsonvalue-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunit 72504
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 72504 "LT JsT Value Setters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Lf(): Text
    var
        C: Text[1];
    begin
        C[1] := 10;
        exit(C);
    end;

    [Test]
    procedure NullAndUndefined()
    var
        V: JsonValue;
        Txt: Text;
    begin
        Observer.Observe('default_isnull', Format(V.IsNull()));
        Observer.Observe('default_isundefined', Format(V.IsUndefined()));
        V.SetValueToNull();
        Observer.Observe('null_isnull', Format(V.IsNull()));
        Observer.Observe('null_isundefined', Format(V.IsUndefined()));
        V.WriteTo(Txt);
        Observer.Observe('null_text', Txt);
        V.SetValueToUndefined();
        Observer.Observe('undef_isnull', Format(V.IsNull()));
        Observer.Observe('undef_isundefined', Format(V.IsUndefined()));
        V.WriteTo(Txt);
        Observer.Observe('undef_text', Txt);
        V.SetValue(1);
        Observer.Observe('int_isnull', Format(V.IsNull()));
        Observer.Observe('int_isundefined', Format(V.IsUndefined()));
        V.SetValueToNull();
        Observer.Observe('null_again', Format(V.IsNull()));
        Observer.Expect('default_isnull', 'Yes');
        Observer.Expect('default_isundefined', 'No');
        Observer.Expect('null_isnull', 'Yes');
        Observer.Expect('null_isundefined', 'No');
        Observer.Expect('null_text', 'null');
        Observer.Expect('undef_isnull', 'No');
        Observer.Expect('undef_isundefined', 'Yes');
        Observer.Expect('undef_text', 'undefined');
        Observer.Expect('int_isnull', 'No');
        Observer.Expect('int_isundefined', 'No');
        Observer.Expect('null_again', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure UndefinedInContainers()
    var
        V: JsonValue;
        O: JsonObject;
        A: JsonArray;
        Txt: Text;
    begin
        V.SetValueToUndefined();
        O.Add('u', V);
        O.WriteTo(Txt);
        Observer.Observe('object_text', Txt);
        Observer.Observe('object_count', Format(O.Keys().Count()));
        A.Add(V);
        A.WriteTo(Txt);
        Observer.Observe('array_text', Txt);
        Observer.Observe('array_count', Format(A.Count()));
        V.SetValueToNull();
        A.Add(V);
        A.WriteTo(Txt);
        Observer.Observe('array_with_null', Txt);
        Observer.Expect('object_text', '{"u":undefined}');
        Observer.Expect('object_count', '1');
        Observer.Expect('array_text', '[undefined]');
        Observer.Expect('array_count', '1');
        Observer.Expect('array_with_null', '[undefined,null]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValueText()
    var
        V: JsonValue;
        Txt: Text;
    begin
        V.SetValue('hello');
        V.WriteTo(Txt);
        Observer.Observe('text', Txt);
        V.SetValue('');
        V.WriteTo(Txt);
        Observer.Observe('empty', Txt);
        V.SetValue('a"b\c/d');
        V.WriteTo(Txt);
        Observer.Observe('escapes', Txt);
        V.SetValue('line1' + Lf() + 'line2');
        V.WriteTo(Txt);
        Observer.Observe('newline', Txt);
        V.SetValue('tab' + Format(9 - 9) + 'x');
        V.WriteTo(Txt);
        Observer.Observe('nul_like', Txt);
        V.SetValue('äöü€');
        V.WriteTo(Txt);
        Observer.Observe('unicode', Txt);
        V.SetValue('<>&''');
        V.WriteTo(Txt);
        Observer.Observe('html_chars', Txt);
        V.SetValue('  padded  ');
        V.WriteTo(Txt);
        Observer.Observe('padded', Txt);
        Observer.Expect('text', '"hello"');
        Observer.Expect('empty', '""');
        Observer.Expect('escapes', '"a\"b\\c/d"');
        Observer.Expect('newline', '"line1\nline2"');
        Observer.Expect('nul_like', '"tab0x"');
        Observer.Expect('unicode', '"äöü€"');
        Observer.Expect('html_chars', '"<>&''"');
        Observer.Expect('padded', '"  padded  "');
        Observer.Verify();
    end;

    [Test]
    procedure SetValueNumbers()
    var
        V: JsonValue;
        Txt: Text;
        Dec: Decimal;
        Big: BigInteger;
    begin
        V.SetValue(0);
        V.WriteTo(Txt);
        Observer.Observe('zero', Txt);
        V.SetValue(-1);
        V.WriteTo(Txt);
        Observer.Observe('minus_one', Txt);
        V.SetValue(1.0);
        V.WriteTo(Txt);
        Observer.Observe('one_point_zero', Txt);
        V.SetValue(1.10);
        V.WriteTo(Txt);
        Observer.Observe('one_point_one', Txt);
        Dec := 0.00001;
        V.SetValue(Dec);
        V.WriteTo(Txt);
        Observer.Observe('small', Txt);
        Dec := 123456789.123456789;
        V.SetValue(Dec);
        V.WriteTo(Txt);
        Observer.Observe('many_digits', Txt);
        Dec := 1 / 3;
        V.SetValue(Dec);
        V.WriteTo(Txt);
        Observer.Observe('third', Txt);
        Dec := 79228162514264337593543950335.0;
        V.SetValue(Dec);
        V.WriteTo(Txt);
        Observer.Observe('decimal_big', Txt);
        Evaluate(Big, '9223372036854775807');
        V.SetValue(Big);
        V.WriteTo(Txt);
        Observer.Observe('bigint_max', Txt);
        Evaluate(Big, '-9223372036854775808');
        V.SetValue(Big);
        V.WriteTo(Txt);
        Observer.Observe('bigint_min', Txt);
        Dec := 100;
        V.SetValue(Dec);
        V.WriteTo(Txt);
        Observer.Observe('hundred', Txt);
        Evaluate(Dec, '1000000000000');
        V.SetValue(Dec);
        V.WriteTo(Txt);
        Observer.Observe('trillion', Txt);
        Dec := -0.5;
        V.SetValue(Dec);
        V.WriteTo(Txt);
        Observer.Observe('minus_half', Txt);
        Observer.Expect('zero', '0');
        Observer.Expect('minus_one', '-1');
        Observer.Expect('one_point_zero', '1.0');
        Observer.Expect('one_point_one', '1.10');
        Observer.Expect('small', '0.00001');
        Observer.Expect('many_digits', '123456789.123456789');
        Observer.Expect('third', '0.333333333333333333');
        Observer.Expect('decimal_big', '79228162514264337500000000000.0');
        Observer.Expect('bigint_max', '9223372036854775807');
        Observer.Expect('bigint_min', '-9223372036854775808');
        Observer.Expect('hundred', '100.0');
        Observer.Expect('trillion', '1000000000000.0');
        Observer.Expect('minus_half', '-0.5');
        Observer.Verify();
    end;

    [Test]
    procedure SetValueOthers()
    var
        V: JsonValue;
        Txt: Text;
        D: Date;
        DT: DateTime;
        Tm: Time;
    begin
        V.SetValue(true);
        V.WriteTo(Txt);
        Observer.Observe('true', Txt);
        V.SetValue(false);
        V.WriteTo(Txt);
        Observer.Observe('false', Txt);
        V.SetValue(D);
        V.WriteTo(Txt);
        Observer.Observe('date_default', Txt);
        V.SetValue(DT);
        V.WriteTo(Txt);
        Observer.Observe('datetime_default', Txt);
        V.SetValue(Tm);
        V.WriteTo(Txt);
        Observer.Observe('time_default', Txt);
        V.SetValue(DMY2Date(31, 12, 9999));
        V.WriteTo(Txt);
        Observer.Observe('date_max', Txt);
        V.SetValue(DMY2Date(1, 1, 1753));
        V.WriteTo(Txt);
        Observer.Observe('date_min', Txt);
        V.SetValue(235959.999T);
        V.WriteTo(Txt);
        Observer.Observe('time_ms', Txt);
        V.SetValue(000000T);
        V.WriteTo(Txt);
        Observer.Observe('time_midnight', Txt);
        V.SetValue(CreateDateTime(DMY2Date(1, 1, 2000), 000000T));
        V.WriteTo(Txt);
        Observer.Observe('datetime_midnight', Txt);
        Observer.Expect('true', 'true');
        Observer.Expect('false', 'false');
        Observer.Expect('date_default', '"0001-01-01"');
        Observer.Expect('datetime_default', '"0001-01-01T00:00:00.0000000"');
        Observer.Expect('time_default', '"00:00:00"');
        Observer.Expect('date_max', '"9999-12-31"');
        Observer.Expect('date_min', '"1753-01-01"');
        Observer.Expect('time_ms', '"23:59:59.999"');
        Observer.Expect('time_midnight', '"00:00:00"');
        Observer.Expect('datetime_midnight', '"2000-01-01T00:00:00.0000000Z"');
        Observer.Verify();
    end;

    [Test]
    procedure ValueInContainerReference()
    var
        V: JsonValue;
        A: JsonArray;
        T: JsonToken;
        Txt: Text;
    begin
        V.SetValue(1);
        A.Add(V);
        V.SetValue(2);
        A.WriteTo(Txt);
        Observer.Observe('array_after_setvalue', Txt);
        A.Get(0, T);
        T.AsValue().SetValue(3);
        A.WriteTo(Txt);
        Observer.Observe('array_after_token_setvalue', Txt);
        Observer.Observe('var_value', V.AsText());
        Observer.Expect('array_after_setvalue', '[1]');
        Observer.Expect('array_after_token_setvalue', '[1]');
        Observer.Expect('var_value', '2');
        Observer.Verify();
    end;

    [Test]
    procedure ValueAsToken()
    var
        V: JsonValue;
        T: JsonToken;
        Txt: Text;
    begin
        V.SetValue('x');
        T := V.AsToken();
        Observer.Observe('isvalue', Format(T.IsValue()));
        T.WriteTo(Txt);
        Observer.Observe('text', Txt);
        Observer.Observe('path', V.Path());
        Observer.Observe('clone', V.Clone().AsValue().AsText());
        Observer.Observe('format', Format(V));
        V.SetValue(12.50);
        Observer.Observe('format_dec', Format(V));
        V.SetValue(true);
        Observer.Observe('format_bool', Format(V));
        Observer.Expect('isvalue', 'Yes');
        Observer.Expect('text', '"x"');
        Observer.Expect('path', '');
        Observer.Expect('clone', 'x');
        Observer.Expect('format', '"x"');
        Observer.Expect('format_dec', '12.50');
        Observer.Expect('format_bool', 'true');
        Observer.Verify();
    end;
}
