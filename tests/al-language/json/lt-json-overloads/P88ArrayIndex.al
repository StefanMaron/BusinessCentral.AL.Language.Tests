// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonarray/jsonarray-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74406
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: JsonArray index errors, RemoveAt, IndexOf per value type
// BC versions: 29 (27 and 28 by CI)

codeunit 74406 "LT P88 Array Index"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Txt(A: JsonArray): Text
    var
        R: Text;
    begin
        A.WriteTo(R);
        exit(R);
    end;

    local procedure Three(var A: JsonArray)
    begin
        Clear(A);
        A.Add(1);
        A.Add(2);
        A.Add(3);
    end;

    [Test]
    procedure InsertIndexErrors()
    var
        A: JsonArray;
    begin
        Three(A);
        asserterror A.Insert(-1, 5);
        Observer.ObserveError('insert_minus1');
        asserterror A.Insert(4, 5);
        Observer.ObserveError('insert_4_of_3');
        asserterror A.Insert(2147483647, 5);
        Observer.ObserveError('insert_intmax');
        asserterror A.Insert(-2147483647, 5);
        Observer.ObserveError('insert_intmin');
        Observer.Observe('after_errors', Txt(A));
        A.Insert(3, 5);
        Observer.Observe('insert_at_count', Txt(A));
        A.Insert(0, 0);
        Observer.Observe('insert_at_0', Txt(A));
        A.Insert(2, 'mid');
        Observer.Observe('insert_at_2', Txt(A));
        Observer.Finish();
    end;

    [Test]
    procedure SetIndexErrors()
    var
        A: JsonArray;
    begin
        Three(A);
        asserterror A.Set(-1, 5);
        Observer.ObserveError('set_minus1');
        asserterror A.Set(3, 5);
        Observer.ObserveError('set_3_of_3');
        asserterror A.Set(2147483647, 5);
        Observer.ObserveError('set_intmax');
        asserterror A.Set(-2147483647, 5);
        Observer.ObserveError('set_intmin');
        Observer.Observe('after_errors', Txt(A));
        A.Set(0, 'first');
        A.Set(2, false);
        Observer.Observe('after_sets', Txt(A));
        Clear(A);
        asserterror A.Set(0, 1);
        Observer.ObserveError('set_0_empty');
        asserterror A.Insert(1, 1);
        Observer.ObserveError('insert_1_empty');
        A.Insert(0, 1);
        Observer.Observe('insert_0_empty', Txt(A));
        Observer.Finish();
    end;

    [Test]
    procedure GetAndRemoveErrors()
    var
        A: JsonArray;
        T: JsonToken;
    begin
        Three(A);
        asserterror A.Get(3, T);
        Observer.ObserveError('get_3_of_3');
        asserterror A.Get(-1, T);
        Observer.ObserveError('get_minus1');
        asserterror A.RemoveAt(3);
        Observer.ObserveError('removeat_3_of_3');
        asserterror A.RemoveAt(-1);
        Observer.ObserveError('removeat_minus1');
        Observer.Observe('removeat_1', Format(A.RemoveAt(1)));
        Observer.Observe('after_removeat', Txt(A));
        A.RemoveAt(0);
        A.RemoveAt(0);
        Observer.Observe('after_all_removed', Txt(A));
        asserterror A.RemoveAt(0);
        Observer.ObserveError('removeat_0_empty');
        Observer.Observe('count_empty', Format(A.Count()));
        Observer.Finish();
    end;

    local procedure Mixed(var A: JsonArray)
    var
        Bi: BigInteger;
    begin
        Clear(A);
        Bi := 2147483647;
        Bi := Bi * 3;
        A.Add(true);
        A.Add(42);
        A.Add('hello');
        A.Add(12.345);
        A.Add(DMY2Date(15, 3, 2024));
        A.Add(143015T);
        A.Add(CreateDateTime(DMY2Date(15, 3, 2024), 143015T));
        A.Add(Bi);
        A.Add(90061001);
    end;

    local procedure Tok(var V: JsonValue): JsonToken
    begin
        exit(V.AsToken());
    end;

    [Test]
    procedure Mixed_Text()
    var
        A: JsonArray;
    begin
        Mixed(A);
        Observer.Observe('mixed_text', Txt(A));
        Observer.Observe('mixed_count', Format(A.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure IndexOf_ByValueType()
    var
        A: JsonArray;
        V: JsonValue;
        Bi: BigInteger;
        Op: Option Alpha,Beta,Gamma;
    begin
        Mixed(A);
        Bi := 2147483647;
        Bi := Bi * 3;
        V.SetValue(true);
        Observer.Observe('indexof_true', Format(A.IndexOf(Tok(V))));
        V.SetValue(false);
        Observer.Observe('indexof_false', Format(A.IndexOf(Tok(V))));
        V.SetValue(42);
        Observer.Observe('indexof_42', Format(A.IndexOf(Tok(V))));
        V.SetValue(43);
        Observer.Observe('indexof_43', Format(A.IndexOf(Tok(V))));
        V.SetValue('hello');
        Observer.Observe('indexof_hello', Format(A.IndexOf(Tok(V))));
        V.SetValue('HELLO');
        Observer.Observe('indexof_HELLO', Format(A.IndexOf(Tok(V))));
        V.SetValue(12.345);
        Observer.Observe('indexof_12_345', Format(A.IndexOf(Tok(V))));
        V.SetValue(12.3450);
        Observer.Observe('indexof_12_3450', Format(A.IndexOf(Tok(V))));
        V.SetValue(DMY2Date(15, 3, 2024));
        Observer.Observe('indexof_date', Format(A.IndexOf(Tok(V))));
        V.SetValue(DMY2Date(16, 3, 2024));
        Observer.Observe('indexof_date_other', Format(A.IndexOf(Tok(V))));
        V.SetValue(143015T);
        Observer.Observe('indexof_time', Format(A.IndexOf(Tok(V))));
        V.SetValue(CreateDateTime(DMY2Date(15, 3, 2024), 143015T));
        Observer.Observe('indexof_datetime', Format(A.IndexOf(Tok(V))));
        V.SetValue(Bi);
        Observer.Observe('indexof_bigint', Format(A.IndexOf(Tok(V))));
        V.SetValue(Bi + 1);
        Observer.Observe('indexof_bigint_other', Format(A.IndexOf(Tok(V))));
        V.SetValue(Op::Beta);
        Observer.Observe('indexof_option_beta', Format(A.IndexOf(Tok(V))));
        V.SetValue('42');
        Observer.Observe('indexof_text_42', Format(A.IndexOf(Tok(V))));
        V.SetValue(1);
        Observer.Observe('indexof_int_1', Format(A.IndexOf(Tok(V))));
        V.SetValueToNull();
        Observer.Observe('indexof_null', Format(A.IndexOf(Tok(V))));
        Observer.Finish();
    end;

    [Test]
    procedure IndexOf_ContainersAndDuplicates()
    var
        A: JsonArray;
        Inner: JsonArray;
        Obj: JsonObject;
        T: JsonToken;
        Probe: JsonToken;
        PA: JsonArray;
        PO: JsonObject;
    begin
        Inner.ReadFrom('[1,2]');
        Obj.ReadFrom('{"k":"v"}');
        A.Add(7);
        A.Add(Inner);
        A.Add(Obj);
        A.Add(7);
        A.Get(0, T);
        Observer.Observe('indexof_first_7', Format(A.IndexOf(T)));
        A.Get(3, T);
        Observer.Observe('indexof_second_7_token', Format(A.IndexOf(T)));
        A.Get(1, T);
        Observer.Observe('indexof_inner_instance', Format(A.IndexOf(T)));
        A.Get(2, T);
        Observer.Observe('indexof_obj_instance', Format(A.IndexOf(T)));
        PA.ReadFrom('[1,2]');
        Probe := PA.AsToken();
        Observer.Observe('indexof_equal_array_other_instance', Format(A.IndexOf(Probe)));
        PO.ReadFrom('{"k":"v"}');
        Probe := PO.AsToken();
        Observer.Observe('indexof_equal_object_other_instance', Format(A.IndexOf(Probe)));
        PA.ReadFrom('[2,1]');
        Probe := PA.AsToken();
        Observer.Observe('indexof_array_other_order', Format(A.IndexOf(Probe)));
        Clear(A);
        Probe.ReadFrom('7');
        Observer.Observe('indexof_empty_array', Format(A.IndexOf(Probe)));
        Observer.Finish();
    end;
}
