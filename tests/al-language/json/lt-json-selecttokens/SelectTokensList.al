// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-selecttokens-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunits 78800, 78801
// Probe: JsonObject.SelectTokens and JsonArray.SelectTokens with a List of [JsonToken]; the methods need app runtime 17 (BC 28 and 29; on BC 27 the app runs on 16.1 and the compiler refuses them: must-not-compile cases 0364 and 0640).
// Facts: result, list content, list pre-filled, no match, several matches, invalid path
// BC versions: 28, 29

#if BC28PLUS
codeunit 78800 "LT S Array SelectTokens"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Doc(var A: JsonArray)
    begin
        A.ReadFrom('[{"a":1,"n":{"a":"deep"}},{"a":2},{"b":3},[{"a":4}]]');
    end;

    local procedure Render(L: List of [JsonToken]): Text
    var
        T: JsonToken;
        R: Text;
        Part: Text;
    begin
        foreach T in L do begin
            T.WriteTo(Part);
            R += Part + '|';
        end;
        exit(Format(L.Count()) + ':' + R);
    end;

    [Test]
    procedure SelectTokens_Array()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        L: List of [JsonToken];
        B: Boolean;
    begin
        Doc(A);
        B := A.SelectTokens('$[0].a', L);
        Observer.Observe('single_result', Format(B));
        Observer.Observe('single_list', Render(L));
        B := A.SelectTokens('$[9]', L);
        Observer.Observe('nomatch_result', Format(B));
        Observer.Observe('nomatch_list', Render(L));
        B := A.SelectTokens('$[*].a', L);
        Observer.Observe('wild_result', Format(B));
        Observer.Observe('wild_list', Render(L));
        B := A.SelectTokens('$..a', L);
        Observer.Observe('recursive_result', Format(B));
        Observer.Observe('recursive_list', Render(L));
        B := A.SelectTokens('$', L);
        Observer.Observe('root_result', Format(B));
        Observer.Observe('root_list', Render(L));
        B := A.SelectTokens('$[1:3]', L);
        Observer.Observe('slice_result', Format(B));
        Observer.Observe('slice_list', Render(L));
        Observer.Finish();
    end;

    [Test]
    procedure SelectTokens_Array_PrefilledList()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        L: List of [JsonToken];
        Filler: JsonToken;
        B: Boolean;
    begin
        Doc(A);
        Filler.ReadFrom('"old"');
        L.Add(Filler);
        B := A.SelectTokens('$[1].a', L);
        Observer.Observe('prefilled_match_result', Format(B));
        Observer.Observe('prefilled_match_list', Render(L));
        B := A.SelectTokens('$[9]', L);
        Observer.Observe('prefilled_nomatch_result', Format(B));
        Observer.Observe('prefilled_nomatch_list', Render(L));
        Observer.Finish();
    end;

    [Test]
    procedure SelectTokens_Array_Errors()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        L: List of [JsonToken];
        Empty: JsonArray;
    begin
        Doc(A);
        asserterror Observer.Observe('bad1', Format(A.SelectTokens('$[', L)));
        Observer.ObserveError('bad1');
        asserterror Observer.Observe('bad2', Format(A.SelectTokens('$.a[?(@.x', L)));
        Observer.ObserveError('bad2');
        asserterror Observer.Observe('bad3', Format(A.SelectTokens('', L)));
        Observer.ObserveError('bad3');
        asserterror Observer.Observe('bad4', Format(A.SelectTokens('a..[', L)));
        Observer.ObserveError('bad4');
        Observer.Observe('empty_array', Format(Empty.SelectTokens('$[*]', L)));
        Observer.Observe('empty_array_list', Render(L));
        Observer.Finish();
    end;
}

codeunit 78801 "LT S Object SelectTokens"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Doc(var O: JsonObject)
    begin
        O.ReadFrom('{"a":1,"list":[{"id":10},{"id":20},{"x":30}],"n":{"a":"deep","list":[{"id":40}]}}');
    end;

    local procedure Render(L: List of [JsonToken]): Text
    var
        T: JsonToken;
        R: Text;
        Part: Text;
    begin
        foreach T in L do begin
            T.WriteTo(Part);
            R += Part + '|';
        end;
        exit(Format(L.Count()) + ':' + R);
    end;

    [Test]
    procedure SelectTokens_Object()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        L: List of [JsonToken];
        B: Boolean;
    begin
        Doc(O);
        B := O.SelectTokens('$.a', L);
        Observer.Observe('single_result', Format(B));
        Observer.Observe('single_list', Render(L));
        B := O.SelectTokens('$.nope', L);
        Observer.Observe('nomatch_result', Format(B));
        Observer.Observe('nomatch_list', Render(L));
        B := O.SelectTokens('$.list[*].id', L);
        Observer.Observe('wild_result', Format(B));
        Observer.Observe('wild_list', Render(L));
        B := O.SelectTokens('$..id', L);
        Observer.Observe('recursive_result', Format(B));
        Observer.Observe('recursive_list', Render(L));
        B := O.SelectTokens('$..a', L);
        Observer.Observe('recursive_a_result', Format(B));
        Observer.Observe('recursive_a_list', Render(L));
        B := O.SelectTokens('$.list[?(@.id > 10)]', L);
        Observer.Observe('filter_result', Format(B));
        Observer.Observe('filter_list', Render(L));
        B := O.SelectTokens('$.*', L);
        Observer.Observe('allprops_result', Format(B));
        Observer.Observe('allprops_count', Format(L.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure SelectTokens_Object_PrefilledList()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        L: List of [JsonToken];
        Filler: JsonToken;
        B: Boolean;
    begin
        Doc(O);
        Filler.ReadFrom('"old"');
        L.Add(Filler);
        B := O.SelectTokens('$.a', L);
        Observer.Observe('prefilled_match_result', Format(B));
        Observer.Observe('prefilled_match_list', Render(L));
        B := O.SelectTokens('$.nope', L);
        Observer.Observe('prefilled_nomatch_result', Format(B));
        Observer.Observe('prefilled_nomatch_list', Render(L));
        Observer.Finish();
    end;

    [Test]
    procedure SelectTokens_Object_Errors()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        L: List of [JsonToken];
        Empty: JsonObject;
    begin
        Doc(O);
        asserterror Observer.Observe('bad1', Format(O.SelectTokens('$[', L)));
        Observer.ObserveError('bad1');
        asserterror Observer.Observe('bad2', Format(O.SelectTokens('$.list[?(@.x', L)));
        Observer.ObserveError('bad2');
        asserterror Observer.Observe('bad3', Format(O.SelectTokens('', L)));
        Observer.ObserveError('bad3');
        asserterror Observer.Observe('bad4', Format(O.SelectTokens('a..[', L)));
        Observer.ObserveError('bad4');
        Observer.Observe('empty_object', Format(Empty.SelectTokens('$.*', L)));
        Observer.Observe('empty_object_list', Render(L));
        Observer.Finish();
    end;
}
#endif
