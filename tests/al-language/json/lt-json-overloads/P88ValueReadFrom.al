// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonvalue/jsonvalue-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74410
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: JsonValue ReadFrom each JSON scalar and invalid text, SelectToken, WriteTo
// BC versions: 29 (27 and 28 by CI)

codeunit 74410 "LT P88 Value ReadFrom"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryRead(Src: Text; var R: Text)
    var
        V: JsonValue;
        Txt: Text;
    begin
        V.ReadFrom(Src);
        V.WriteTo(Txt);
        R := 'null=' + Format(V.IsNull()) + ' undef=' + Format(V.IsUndefined()) + ' text=' + V.AsText() + ' json=' + Txt;
    end;

    local procedure Rd(Name: Text; Src: Text)
    var
        R: Text;
    begin
        if TryRead(Src, R) then
            Observer.Observe(Name, R)
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure ReadFrom_Scalars()
    begin
        Rd('int', '42');
        Rd('negint', '-7');
        Rd('zero', '0');
        Rd('decimal', '1.50');
        Rd('exp', '1e3');
        Rd('bigint', '9007199254740993');
        Rd('true', 'true');
        Rd('false', 'false');
        Rd('null', 'null');
        Rd('string', '"hello"');
        Rd('string_empty', '""');
        Rd('string_escapes', '"a\"b\\c\n"');
        Rd('string_unicode', '"\u00fc"');
        Rd('string_date', '"2024-03-15"');
        Rd('string_datetime', '"2024-03-15T14:30:15Z"');
        Rd('leading_space', '  5  ');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFrom_Invalid()
    begin
        Rd('empty', '');
        Rd('blank', ' ');
        Rd('bare_word', 'hello');
        Rd('single_quote', '''x''');
        Rd('unterminated', '"abc');
        Rd('two_values', '1 2');
        Rd('trailing_comma', '1,');
        Rd('upper_true', 'TRUE');
        Rd('nan', 'NaN');
        Rd('plus', '+1');
        Rd('leading_zero', '007');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFrom_Containers()
    begin
        Rd('array', '[1,2]');
        Rd('object', '{"a":1}');
        Rd('empty_array', '[]');
        Rd('empty_object', '{}');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TrySel(V: JsonValue; P: Text; var R: Text)
    var
        T: JsonToken;
        Txt: Text;
        Found: Boolean;
    begin
        Found := V.SelectToken(P, T);
        T.WriteTo(Txt);
        R := Format(Found) + '|' + Txt;
    end;

    local procedure Sel(Name: Text; V: JsonValue; P: Text)
    var
        R: Text;
    begin
        if TrySel(V, P, R) then
            Observer.Observe(Name, R)
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure SelectToken_OnValue()
    var
        V: JsonValue;
    begin
        V.SetValue(42);
        Sel('sel_dollar', V, '$');
        Sel('sel_empty', V, '');
        Sel('sel_name', V, 'a');
        Sel('sel_idx0', V, '[0]');
        Sel('sel_wild', V, '*');
        Sel('sel_recursive', V, '$..a');
        Sel('sel_bad', V, '[');
        V.SetValue('text');
        Sel('sel_text_dollar', V, '$');
        V.SetValueToNull();
        Sel('sel_null_dollar', V, '$');
        Sel('sel_null_name', V, 'a');
        Observer.Finish();
    end;

    [Test]
    procedure WriteTo_OnValue()
    var
        V: JsonValue;
        Txt: Text;
    begin
        V.SetValue(42);
        V.WriteTo(Txt);
        Observer.Observe('int', Txt);
        V.SetValue('a "q" b');
        V.WriteTo(Txt);
        Observer.Observe('text', Txt);
        V.SetValue(true);
        V.WriteTo(Txt);
        Observer.Observe('bool', Txt);
        V.SetValue(1.10);
        V.WriteTo(Txt);
        Observer.Observe('decimal', Txt);
        V.SetValueToNull();
        V.WriteTo(Txt);
        Observer.Observe('null', Txt);
        Txt := 'previous';
        Clear(V);
        V.WriteTo(Txt);
        Observer.Observe('undefined_value', Txt);
        Observer.Observe('undefined_isnull', Format(V.IsNull()));
        Observer.Observe('undefined_isundefined', Format(V.IsUndefined()));
        Observer.Finish();
    end;
}
