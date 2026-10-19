// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type
// Scope: in-scope
// Fixtures used: Probe Observer, collections/Fixtures.al (interface "LT ClT Shape", codeunits 74600/74601, enum 74602)
// Probe: corpus issue 670 (odd AL behavior leads, part E), items 1-14. Every literal asserted below is what BC produced; the CI matrix checks BC 27.5, 28.5 and 29.0.
// Covers: array and List of JsonObject elements (item 1), the last error after a Get whose result is used (4), Enum.Ordinals()/Names() lists (7),
//   AddRange on interface lists (8), Contains/IndexOf with Dictionary elements (9), Variant holding a Dictionary, List or Codeunit (10),
//   Dictionary of enum values (11), GetRange is a shallow copy (12), List of [RecordRef] (13).
// BC versions: 27, 28, 29

codeunit 85180 "LT CS Collections"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure JsonText(J: JsonObject): Text
    var
        T: Text;
    begin
        J.WriteTo(T);
        exit(T);
    end;

    [Test]
    procedure JsonObject_ArrayElements_AreSeparate()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[3] of JsonObject;
    begin
        Arr[1].ReadFrom('{"a":1}');
        Arr[2].ReadFrom('{"a":2}');
        Arr[3].ReadFrom('{"a":3}');
        Observer.Observe('arr 1', JsonText(Arr[1]));
        Observer.Observe('arr 2', JsonText(Arr[2]));
        Observer.Observe('arr 3', JsonText(Arr[3]));
        Arr[1].Add('b', true);
        Observer.Observe('arr 1 after add', JsonText(Arr[1]));
        Observer.Observe('arr 2 after add', JsonText(Arr[2]));
        Observer.Finish();
    end;

    [Test]
    procedure JsonObject_ListElements_DifferentVariables()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [JsonObject];
        J1: JsonObject;
        J2: JsonObject;
        J3: JsonObject;
    begin
        J1.ReadFrom('{"a":1}');
        J2.ReadFrom('{"a":2}');
        J3.ReadFrom('{"a":3}');
        L.Add(J1);
        L.Add(J2);
        L.Add(J3);
        Observer.Observe('list 1', JsonText(L.Get(1)));
        Observer.Observe('list 2', JsonText(L.Get(2)));
        Observer.Observe('list 3', JsonText(L.Get(3)));
        J1.Add('b', true);
        Observer.Observe('list 1 after source add', JsonText(L.Get(1)));
        Observer.Finish();
    end;

    [Test]
    procedure JsonObject_ListElements_OneVariableReused()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [JsonObject];
        J: JsonObject;
    begin
        J.ReadFrom('{"a":1}');
        L.Add(J);
        J.ReadFrom('{"a":2}');
        L.Add(J);
        J.ReadFrom('{"a":3}');
        L.Add(J);
        Observer.Observe('reuse 1', JsonText(L.Get(1)));
        Observer.Observe('reuse 2', JsonText(L.Get(2)));
        Observer.Observe('reuse 3', JsonText(L.Get(3)));
        Clear(J);
        J.Add('c', 1);
        L.Add(J);
        Observer.Observe('clear then add 1', JsonText(L.Get(1)));
        Observer.Observe('clear then add 4', JsonText(L.Get(4)));
        Observer.Finish();
    end;

    [Test]
    procedure JsonObject_ListSet_OneVariableEachSlot()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [JsonObject];
        J: JsonObject;
        Empty: JsonObject;
    begin
        L.Add(Empty);
        L.Add(Empty);
        L.Add(Empty);
        J.ReadFrom('{"a":1}');
        L.Set(1, J);
        J.ReadFrom('{"a":2}');
        L.Set(2, J);
        J.ReadFrom('{"a":3}');
        L.Set(3, J);
        Observer.Observe('set 1', JsonText(L.Get(1)));
        Observer.Observe('set 2', JsonText(L.Get(2)));
        Observer.Observe('set 3', JsonText(L.Get(3)));
        Observer.Finish();
    end;

    [Test]
    procedure LastError_DictionaryGet_ResultUsed()
    var
        Observer: Codeunit "Probe Observer";
        DI: Dictionary of [Integer, Integer];
        DT: Dictionary of [Text, Text];
        I: Integer;
        V: Text;
    begin
        ClearLastError();
        if DI.Get(42, I) then;
        Observer.Observe('int get text', GetLastErrorText());
        Observer.Observe('int get code', GetLastErrorCode());
        ClearLastError();
        if not DT.Get('missing', V) then;
        Observer.Observe('text get text', GetLastErrorText());
        Observer.Observe('text get code', GetLastErrorCode());
        ClearLastError();
        Observer.Observe('contains', Format(DT.ContainsKey('missing')));
        Observer.Observe('contains text', GetLastErrorText());
        asserterror Error('LT CS first error');
        if not DT.Get('missing', V) then;
        Observer.Observe('after real error text', GetLastErrorText());
        Observer.Observe('after real error code', GetLastErrorCode());
        Observer.Finish();
    end;

    [Test]
    procedure LastError_SelectSingleNodeAndRecordGet_ResultUsed()
    var
        Observer: Codeunit "Probe Observer";
        XDoc: XmlDocument;
        N: XmlNode;
        R: Record "LT ClT Rec";
    begin
        XmlDocument.ReadFrom('<r><a/></r>', XDoc);
        ClearLastError();
        if XDoc.SelectSingleNode('//nope', N) then;
        Observer.Observe('xml text', GetLastErrorText());
        Observer.Observe('xml code', GetLastErrorCode());
        R.DeleteAll();
        ClearLastError();
        if R.Get(4711) then;
        Observer.Observe('rec text', GetLastErrorText());
        Observer.Observe('rec code', GetLastErrorCode());
        asserterror Error('LT CS first error');
        if XDoc.SelectSingleNode('//nope', N) then;
        Observer.Observe('xml after real error', GetLastErrorText());
        if R.Get(4711) then;
        Observer.Observe('rec after real error', GetLastErrorText());
        Observer.Finish();
    end;

    [Test]
    procedure EnumOrdinals_Mutations()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
    begin
        L := Enum::"LT ClT Color".Ordinals();
        Observer.Observe('count', Format(L.Count()));
        asserterror L.Reverse();
        Observer.ObserveError('reverse');
        asserterror L.Add(9);
        Observer.ObserveError('add');
        asserterror L.RemoveAt(1);
        Observer.ObserveError('removeat');
        asserterror L.Insert(1, 9);
        Observer.ObserveError('insert');
        asserterror L.Set(1, 9);
        Observer.ObserveError('set');
        asserterror L.Remove(0);
        Observer.ObserveError('remove');
        asserterror L.RemoveRange(1, 1);
        Observer.ObserveError('removerange');
        Observer.Observe('count after', Format(L.Count()));
        Observer.Observe('get 3', Format(L.Get(3)));
        Observer.Finish();
    end;

    [Test]
    procedure EnumNames_MutationsAndCopies()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Text];
        R: List of [Text];
        C: List of [Text];
        O: List of [Integer];
        Copy: List of [Integer];
        S: Text;
    begin
        L := Enum::"LT ClT Color".Names();
        asserterror L.Reverse();
        Observer.ObserveError('names reverse');
        asserterror L.Add('x');
        Observer.ObserveError('names add');
        asserterror L.Set(1, 'x');
        Observer.ObserveError('names set');
        R := L.GetRange(2, L.Count() - 1);
        Observer.Observe('getrange count', Format(R.Count()));
        R.Add('x');
        Observer.Observe('getrange add', Format(R.Count()));
        foreach S in L do
            C.Add(S);
        C.Reverse();
        Observer.Observe('loop copy reversed', C.Get(1));
        O := Enum::"LT ClT Color".Ordinals();
        Copy := O.GetRange(1, O.Count());
        Copy.Reverse();
        Copy.Add(9);
        Observer.Observe('ordinals copy', Format(Copy.Get(1)) + ',' + Format(Copy.Count()));
        Observer.Observe('ordinals source', Format(O.Get(1)) + ',' + Format(O.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure InterfaceList_AddRange()
    var
        Observer: Codeunit "Probe Observer";
        BaseList: List of [Interface "LT ClT Shape"];
        EmptyList: List of [Interface "LT ClT Shape"];
        Other: List of [Interface "LT ClT Shape"];
        C: Codeunit "LT ClT Circle";
        S: Codeunit "LT ClT Square";
        I: Interface "LT ClT Shape";
    begin
        I := C;
        BaseList.Add(I);
        BaseList.AddRange(EmptyList);
        Observer.Observe('after empty', Format(BaseList.Count()));
        I := S;
        Other.Add(I);
        Other.Add(I);
        BaseList.AddRange(Other);
        Observer.Observe('after other', Format(BaseList.Count()));
        Observer.Observe('third', BaseList.Get(3).Name());
        EmptyList.AddRange(EmptyList);
        Observer.Observe('empty to empty', Format(EmptyList.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure DictionaryList_ContainsAndIndexOf()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Dictionary of [Integer, Code[20]]];
        D: Dictionary of [Integer, Code[20]];
        E: Dictionary of [Integer, Code[20]];
    begin
        D.Add(1, 'A');
        L.Add(D);
        asserterror Observer.Observe('contains same', Format(L.Contains(D)));
        Observer.ObserveError('contains same');
        asserterror Observer.Observe('indexof same', Format(L.IndexOf(D)));
        Observer.ObserveError('indexof same');
        asserterror Observer.Observe('contains other', Format(L.Contains(E)));
        Observer.ObserveError('contains other');
        asserterror Observer.Observe('lastindexof same', Format(L.LastIndexOf(D)));
        Observer.ObserveError('lastindexof same');
        asserterror L.Remove(D);
        Observer.ObserveError('remove same');
        Observer.Observe('count', Format(L.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure Variant_HoldingDictionary_AssignBackAndEvaluate()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Integer, Text];
        Back: Dictionary of [Integer, Text];
        Target: Dictionary of [Integer, Text];
        V: Variant;
        Ok: Boolean;
    begin
        D.Add(1, 'one');
        V := D;
        Back := V;
        Observer.Observe('back get', Back.Get(1));
        Back.Add(2, 'two');
        Observer.Observe('source count after back add', Format(D.Count()));
        ClearLastError();
        asserterror Ok := Evaluate(Target, V);
        Observer.ObserveError('evaluate used');
        asserterror Evaluate(Target, V);
        Observer.ObserveError('evaluate plain');
        Observer.Observe('target count', Format(Target.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure Variant_HoldingList_AssignBack()
    var
        Observer: Codeunit "Probe Observer";
        SourceList: List of [Text];
        TargetList: List of [Text];
        Ints: List of [Integer];
        V: Variant;
    begin
        SourceList.Add('a');
        V := SourceList;
        TargetList := V;
        TargetList.Add('b');
        Observer.Observe('source count', Format(SourceList.Count()));
        Ints.Add(7);
        V := Ints;
        asserterror TargetList := V;
        Observer.ObserveError('int list to text list');
        Observer.Observe('target after failed', Format(TargetList.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure Variant_HoldingCodeunit_AssignBack()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "LT ClT Circle";
        Back: Codeunit "LT ClT Circle";
        Sq: Codeunit "LT ClT Square";
        D: Dictionary of [Integer, Text];
        V: Variant;
    begin
        C.SetTag('V');
        V := C;
        Observer.Observe('is codeunit', Format(V.IsCodeunit()));
        Back := V;
        Observer.Observe('back name', Back.Name());
        C.SetTag('W');
        Observer.Observe('back after source retag', Back.Name());
        asserterror Sq := V;
        Observer.ObserveError('to other codeunit');
        asserterror D := V;
        Observer.ObserveError('to dictionary');
        Finish(Observer);
    end;

    local procedure Finish(var Observer: Codeunit "Probe Observer")
    begin
        Observer.Finish();
    end;

    [Test]
    procedure Dictionary_EnumValue_GetSetValuesContainsKey()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Text, Enum "LT ClT Color"];
        V: Enum "LT ClT Color";
        Vals: List of [Enum "LT ClT Color"];
    begin
        D.Add('k', Enum::"LT ClT Color"::Green);
        Observer.Observe('get out', Format(D.Get('k', V)));
        Observer.Observe('get out value', Format(V.AsInteger()));
        Observer.Observe('get missing', Format(D.Get('x', V)));
        Observer.Observe('value after missing', Format(V.AsInteger()));
        D.Set('k', Enum::"LT ClT Color"::Blue);
        D.Set('n', Enum::"LT ClT Color"::Red);
        Observer.Observe('after set', Format(D.Get('k')));
        Observer.Observe('contains', Format(D.ContainsKey('n')));
        Vals := D.Values();
        Observer.Observe('values', Format(Vals.Get(1).AsInteger()) + ',' + Format(Vals.Get(2).AsInteger()));
        Observer.Observe('values contains', Format(Vals.Contains(Enum::"LT ClT Color"::Red)));
        Observer.Finish();
    end;

    [Test]
    procedure List_GetRange_IsShallowCopy()
    var
        Observer: Codeunit "Probe Observer";
        Outer: List of [List of [Integer]];
        Inner: List of [Integer];
        Copy: List of [List of [Integer]];
        Got: List of [Integer];
    begin
        Inner.Add(1);
        Outer.Add(Inner);
        Copy := Outer.GetRange(1, Outer.Count());
        Copy.Get(1, Got);
        Got.Add(2);
        Observer.Observe('outer inner count', Format(Outer.Get(1).Count()));
        Observer.Observe('source inner count', Format(Inner.Count()));
        Copy.Add(Inner);
        Observer.Observe('outer count', Format(Outer.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure List_OfRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        ListOfRecRefs: List of [RecordRef];
        RR: RecordRef;
        Got: RecordRef;
        R: Record "LT ClT Rec";
    begin
        Observer.Observe('empty count', Format(ListOfRecRefs.Count()));
        R.DeleteAll();
        R.Id := 1;
        R.Name := 'first';
        R.Insert();
        RR.Open(Database::"LT ClT Rec");
        RR.FindFirst();
        ListOfRecRefs.Add(RR);
        Observer.Observe('count', Format(ListOfRecRefs.Count()));
        Got := ListOfRecRefs.Get(1);
        Observer.Observe('number', Format(Got.Number()));
        Observer.Observe('name', Format(Got.Field(2).Value()));
        RR.Field(2).Value := 'changed';
        Observer.Observe('name after source change', Format(ListOfRecRefs.Get(1).Field(2).Value()));
        RR.Close();
        asserterror Observer.Observe('number after source close', Format(ListOfRecRefs.Get(1).Number()));
        Observer.ObserveError('after close');
        Observer.Finish();
    end;
}
