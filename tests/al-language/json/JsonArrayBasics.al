// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonarray/jsonarray-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunit 72501
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 72501 "LT JsT Array Basics"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure AddAndGet()
    var
        A: JsonArray;
        T: JsonToken;
        Txt: Text;
    begin
        Observer.Observe('empty_count', Format(A.Count()));
        A.Add(1);
        Observer.Observe('add_int', 'done');
        A.Add('two');
        A.Add(true);
        A.Add(4.5);
        Observer.Observe('count', Format(A.Count()));
        Observer.Observe('get0', Format(A.Get(0, T)));
        Observer.Observe('get0_value', Format(T.AsValue().AsInteger()));
        Observer.Observe('get3', Format(A.Get(3, T)));
        Observer.Observe('get3_value', Format(T.AsValue().AsDecimal()));
        A.WriteTo(Txt);
        Observer.Observe('text', Txt);
        Observer.Expect('empty_count', '0');
        Observer.Expect('add_int', 'done');
        Observer.Expect('count', '4');
        Observer.Expect('get0', 'Yes');
        Observer.Expect('get0_value', '1');
        Observer.Expect('get3', 'Yes');
        Observer.Expect('get3_value', '4.5');
        Observer.Expect('text', '[1,"two",true,4.5]');
        Observer.Verify();
    end;

    [Test]
    procedure GetOutOfRange()
    var
        A: JsonArray;
        T: JsonToken;
    begin
        asserterror A.Get(0, T);
        Observer.ObserveError('get0_empty');
        A.Add(1);
        asserterror A.Get(1, T);
        Observer.ObserveError('get1_size1');
        asserterror A.Get(-1, T);
        Observer.ObserveError('get_minus1');
        asserterror A.Get(100000, T);
        Observer.ObserveError('get_big');
        asserterror A.Get(2147483647, T);
        Observer.ObserveError('get_intmax');
        asserterror A.Get(-2147483647, T);
        Observer.ObserveError('get_intmin');
        Observer.Expect('get0_empty|text', 'Index out of bounds.');
        Observer.Expect('get0_empty|code', 'IndexOutOfBounds');
        Observer.Expect('get1_size1|text', 'Index out of bounds.');
        Observer.Expect('get1_size1|code', 'IndexOutOfBounds');
        Observer.Expect('get_minus1|text', 'Index out of bounds.');
        Observer.Expect('get_minus1|code', 'IndexOutOfBounds');
        Observer.Expect('get_big|text', 'Index out of bounds.');
        Observer.Expect('get_big|code', 'IndexOutOfBounds');
        Observer.Expect('get_intmax|text', 'Index out of bounds.');
        Observer.Expect('get_intmax|code', 'IndexOutOfBounds');
        Observer.Expect('get_intmin|text', 'Index out of bounds.');
        Observer.Expect('get_intmin|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure InsertAt()
    var
        A: JsonArray;
        Txt: Text;
    begin
        A.Add(1);
        A.Add(3);
        A.Insert(1, 2);
        Observer.Observe('insert_mid', 'done');
        A.Insert(0, 0);
        Observer.Observe('insert_front', 'done');
        A.Insert(4, 4);
        Observer.Observe('insert_end', 'done');
        A.WriteTo(Txt);
        Observer.Observe('text', Txt);
        asserterror A.Insert(7, 9);
        Observer.ObserveError('insert_beyond_end');
        asserterror A.Insert(-1, 9);
        Observer.ObserveError('insert_negative');
        A.Insert(0, 'txt');
        A.Insert(0, true);
        A.Insert(0, 1.5);
        A.WriteTo(Txt);
        Observer.Observe('text2', Txt);
        Observer.Expect('insert_mid', 'done');
        Observer.Expect('insert_front', 'done');
        Observer.Expect('insert_end', 'done');
        Observer.Expect('text', '[0,1,2,3,4]');
        Observer.Expect('insert_beyond_end|text', 'Index out of bounds.');
        Observer.Expect('insert_beyond_end|code', 'IndexOutOfBounds');
        Observer.Expect('insert_negative|text', 'Index out of bounds.');
        Observer.Expect('insert_negative|code', 'IndexOutOfBounds');
        Observer.Expect('text2', '[1.5,true,"txt",0,1,2,3,4]');
        Observer.Verify();
    end;

    [Test]
    procedure InsertTokens()
    var
        A: JsonArray;
        O: JsonObject;
        Inner: JsonArray;
        Txt: Text;
    begin
        O.Add('k', 1);
        Inner.Add(1);
        A.Insert(0, O);
        A.Insert(1, Inner);
        A.Insert(0, Inner.AsToken());
        A.WriteTo(Txt);
        Observer.Observe('text', Txt);
        Inner.Add(2);
        O.Add('k2', 2);
        A.WriteTo(Txt);
        Observer.Observe('after_edit_originals', Txt);
        Observer.Expect('text', '[[1],{"k":1},[1]]');
        Observer.Expect('after_edit_originals', '[[1],{"k":1,"k2":2},[1,2]]');
        Observer.Verify();
    end;

    [Test]
    procedure SetAtIndex()
    var
        A: JsonArray;
        T: JsonToken;
        Txt: Text;
    begin
        A.Add(1);
        A.Add(2);
        A.Add(3);
        A.Set(1, 'x');
        Observer.Observe('set1', 'done');
        A.WriteTo(Txt);
        Observer.Observe('text', Txt);
        asserterror A.Set(3, 1);
        Observer.ObserveError('set_oob');
        asserterror A.Set(-1, 1);
        Observer.ObserveError('set_negative');
        A.Set(0, A.AsToken());
        A.WriteTo(Txt);
        Observer.Observe('set_self', Txt);
        Observer.Expect('set1', 'done');
        Observer.Expect('text', '[1,"x",3]');
        Observer.Expect('set_oob|text', 'Index out of bounds.');
        Observer.Expect('set_oob|code', 'IndexOutOfBounds');
        Observer.Expect('set_negative|text', 'Index out of bounds.');
        Observer.Expect('set_negative|code', 'IndexOutOfBounds');
        Observer.Expect('set_self', '[[1,"x",3],"x",3]');
        Observer.Verify();
    end;

    [Test]
    procedure RemoveAtAndRemove()
    var
        A: JsonArray;
        Txt: Text;
    begin
        A.Add(1);
        A.Add(2);
        A.Add(3);
        A.Add(2);
        A.RemoveAt(1);
        Observer.Observe('removeat1', 'done');
        A.WriteTo(Txt);
        Observer.Observe('text', Txt);
        asserterror A.RemoveAt(3);
        Observer.ObserveError('removeat_oob');
        asserterror A.RemoveAt(-1);
        Observer.ObserveError('removeat_negative');
        Observer.Observe('count', Format(A.Count()));
        A.RemoveAt(0);
        A.RemoveAt(0);
        A.RemoveAt(0);
        Observer.Observe('count_empty', Format(A.Count()));
        asserterror A.RemoveAt(0);
        Observer.ObserveError('removeat_empty');
        Observer.Expect('removeat1', 'done');
        Observer.Expect('text', '[1,3,2]');
        Observer.Expect('removeat_oob|text', 'Index out of bounds.');
        Observer.Expect('removeat_oob|code', 'IndexOutOfBounds');
        Observer.Expect('removeat_negative|text', 'Index out of bounds.');
        Observer.Expect('removeat_negative|code', 'IndexOutOfBounds');
        Observer.Expect('count', '3');
        Observer.Expect('count_empty', '0');
        Observer.Expect('removeat_empty|text', 'Index out of bounds.');
        Observer.Expect('removeat_empty|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure IndexOfAndClone()
    var
        A: JsonArray;
        Cl: JsonArray;
        T: JsonToken;
        Other: JsonToken;
        O: JsonObject;
        Txt: Text;
    begin
        A.Add(1);
        A.Add('two');
        O.Add('k', 1);
        A.Add(O);
        A.Get(1, T);
        Observer.Observe('indexof_two', Format(A.IndexOf(T)));
        A.Get(2, T);
        Observer.Observe('indexof_obj', Format(A.IndexOf(T)));
        Observer.Observe('indexof_obj_token', Format(A.IndexOf(O.AsToken())));
        Observer.Observe('indexof_foreign', Format(A.IndexOf(Other)));
        A.Get(0, T);
        Other := T;
        Observer.Observe('indexof_alias', Format(A.IndexOf(Other)));
        Cl := A.Clone().AsArray();
        Cl.Add(4);
        A.WriteTo(Txt);
        Observer.Observe('orig', Txt);
        Cl.WriteTo(Txt);
        Observer.Observe('clone', Txt);
        Cl.Get(2, T);
        Observer.Observe('clone_indexof_own', Format(Cl.IndexOf(T)));
        Observer.Observe('orig_indexof_clone_elem', Format(A.IndexOf(T)));
        Observer.Expect('indexof_two', '1');
        Observer.Expect('indexof_obj', '2');
        Observer.Expect('indexof_obj_token', '2');
        Observer.Expect('indexof_foreign', '-1');
        Observer.Expect('indexof_alias', '0');
        Observer.Expect('orig', '[1,"two",{"k":1}]');
        Observer.Expect('clone', '[1,"two",{"k":1},4]');
        Observer.Expect('clone_indexof_own', '2');
        Observer.Expect('orig_indexof_clone_elem', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure ForeachAndPath()
    var
        A: JsonArray;
        T: JsonToken;
        Txt: Text;
        All: Text;
    begin
        A.Add(1);
        A.Add('b');
        A.Add(false);
        foreach T in A do begin
            T.WriteTo(Txt);
            All += Txt + '|';
        end;
        Observer.Observe('foreach', All);
        A.Get(2, T);
        Observer.Observe('path2', T.Path());
        Observer.Observe('path_root', A.AsToken().Path());
        Observer.Observe('select0', Format(A.SelectToken('[0]', T)));
        Observer.Observe('select_oob', Format(A.SelectToken('[9]', T)));
        Observer.Observe('select_dollar', Format(A.SelectToken('$[1]', T)));
        Observer.Observe('select_name', Format(A.SelectToken('x', T)));
        Clear(A);
        All := '';
        foreach T in A do
            All += 'x';
        Observer.Observe('foreach_empty', All);
        Observer.Expect('foreach', '1|"b"|false|');
        Observer.Expect('path2', '[2]');
        Observer.Expect('path_root', '');
        Observer.Expect('select0', 'Yes');
        Observer.Expect('select_oob', 'No');
        Observer.Expect('select_dollar', 'Yes');
        Observer.Expect('select_name', 'No');
        Observer.Expect('foreach_empty', '');
        Observer.Verify();
    end;

    [Test]
    procedure NestedArrays()
    var
        A: JsonArray;
        B: JsonArray;
        C: JsonArray;
        T: JsonToken;
        Txt: Text;
    begin
        C.Add(1);
        B.Add(C);
        A.Add(B);
        A.Add(A.Count());
        A.WriteTo(Txt);
        Observer.Observe('text', Txt);
        A.SelectToken('[0][0][0]', T);
        Observer.Observe('deep', Format(T.AsValue().AsInteger()));
        Observer.Observe('deep_path', T.Path());
        C.Add(2);
        A.WriteTo(Txt);
        Observer.Observe('after_inner_add', Txt);
        Clear(C);
        A.WriteTo(Txt);
        Observer.Observe('after_clear_var', Txt);
        Observer.Expect('text', '[[[1]],1]');
        Observer.Expect('deep', '1');
        Observer.Expect('deep_path', '[0][0][0]');
        Observer.Expect('after_inner_add', '[[[1,2]],1]');
        Observer.Expect('after_clear_var', '[[[1,2]],1]');
        Observer.Verify();
    end;
}
