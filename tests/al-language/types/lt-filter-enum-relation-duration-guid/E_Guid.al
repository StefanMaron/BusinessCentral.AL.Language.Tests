// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), test codeunit 72693 (P85); a fixed Guid literal is used, no CreateGuid
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Guid assigned to Text[40], Text, Code[40], Dictionary of [Text, Text], List of [Text], Evaluate(T, G) forms
// BC versions: 29 (27 and 28 by CI)

codeunit 72693 "LT P85 Guid To Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryEvalText(G: Guid; var T: Text)
    var
        Ok: Boolean;
    begin
        Ok := Evaluate(T, G);
    end;

    local procedure Fixed(): Guid
    var
        G: Guid;
    begin
        Evaluate(G, '{AB12CD34-EF56-4A78-9B01-23456789ABCD}');
        exit(G);
    end;

    [Test]
    procedure Guid_To_Text40_Text_Code40()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        T40: Text[40];
        TAny: Text;
        C40: Code[40];
        T50: Text[50];
        C50: Code[50];
    begin
        G := Fixed();
        T40 := G;
        TAny := G;
        C40 := G;
        T50 := G;
        C50 := G;
        Observer.Observe('t40', T40);
        Observer.Observe('t40_len', Format(StrLen(T40)));
        Observer.Observe('text', TAny);
        Observer.Observe('text_len', Format(StrLen(TAny)));
        Observer.Observe('c40', C40);
        Observer.Observe('c40_len', Format(StrLen(C40)));
        Observer.Observe('t50', T50);
        Observer.Observe('c50', C50);
        Observer.Observe('t40_eq_format', Format(T40 = Format(G)));
        Observer.Observe('text_eq_format', Format(TAny = Format(G)));
        Observer.Observe('c40_eq_format', Format(C40 = Format(G)));
        Observer.Observe('c40_eq_upper_format', Format(C40 = UpperCase(Format(G))));
        Observer.Observe('t40_eq_lower_format', Format(T40 = LowerCase(Format(G))));
        Observer.Finish();
    end;

    [Test]
    procedure Guid_Null_To_Text()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        T40: Text[40];
        TAny: Text;
        C40: Code[40];
    begin
        T40 := G;
        TAny := G;
        C40 := G;
        Observer.Observe('t40', T40);
        Observer.Observe('text', TAny);
        Observer.Observe('c40', C40);
        Observer.Observe('t40_len', Format(StrLen(T40)));
        Observer.Observe('c40_len', Format(StrLen(C40)));
        Observer.Finish();
    end;

    [Test]
    procedure Text_To_Guid_RoundTrip()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        G2: Guid;
        T40: Text[40];
        C40: Code[40];
    begin
        G := Fixed();
        T40 := G;
        G2 := T40;
        Observer.Observe('t40_roundtrip_equal', Format(G = G2));
        C40 := G;
        G2 := C40;
        Observer.Observe('c40_roundtrip_equal', Format(G = G2));
        T40 := '{ab12cd34-ef56-4a78-9b01-23456789abcd}';
        G2 := T40;
        Observer.Observe('lowercase_equal', Format(G = G2));
        T40 := 'AB12CD34-EF56-4A78-9B01-23456789ABCD';
        G2 := T40;
        Observer.Observe('nobraces_equal', Format(G = G2));
        T40 := 'AB12CD34EF564A789B0123456789ABCD';
        G2 := T40;
        Observer.Observe('nodashes_equal', Format(G = G2));
        Observer.Finish();
    end;

    [Test]
    procedure Guid_To_Text_BadText_Errors()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        T40: Text[40];
    begin
        T40 := 'not a guid';
        asserterror G := T40;
        Observer.ObserveError('bad_text');
        T40 := '';
        asserterror G := T40;
        Observer.ObserveError('af121');
        Observer.Observe('empty_text_is_null', Format(IsNullGuid(G)));
        T40 := '{AB12CD34-EF56-4A78-9B01-23456789ABC}';
        asserterror G := T40;
        Observer.ObserveError('short');
        Observer.Finish();
    end;

    [Test]
    procedure Dictionary_Text_Text_Add_Guid()
    var
        Observer: Codeunit "Probe Observer";
        Dict: Dictionary of [Text, Text];
        G: Guid;
        T: Text;
    begin
        G := Fixed();
        Dict.Add('k', G);
        Observer.Observe('count', Format(Dict.Count()));
        Observer.Observe('value', Dict.Get('k'));
        Observer.Observe('len', Format(StrLen(Dict.Get('k'))));
        Observer.Observe('contains', Format(Dict.ContainsKey('k')));
        Dict.Set('k', G);
        Observer.Observe('set_value', Dict.Get('k'));
        Dict.Add('null', CreateNullGuid());
        Observer.Observe('null_value', Dict.Get('null'));
        Dict.Get('k', T);
        Observer.Observe('get_out', T);
        Observer.Finish();
    end;

    local procedure CreateNullGuid(): Guid
    var
        G: Guid;
    begin
        exit(G);
    end;

    [Test]
    procedure List_Of_Text_Add_Guid_And_Dict_Of_Guid()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Text];
        DG: Dictionary of [Text, Guid];
        LG: List of [Guid];
        G: Guid;
    begin
        G := Fixed();
        L.Add(G);
        Observer.Observe('list_text', L.Get(1));
        Observer.Observe('list_contains_format', Format(L.Contains(Format(G))));
        DG.Add('k', G);
        Observer.Observe('dict_guid_value', Format(DG.Get('k')));
        LG.Add(G);
        Observer.Observe('list_guid', Format(LG.Get(1)));
        Observer.Observe('list_guid_contains', Format(LG.Contains(G)));
        Observer.Finish();
    end;

    [Test]
    procedure Evaluate_Text_From_Guid()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        T: Text;
        T40: Text[40];
        C40: Code[40];
        Ok: Boolean;
    begin
        G := Fixed();
        Ok := Evaluate(T, G);
        Observer.Observe('text_ok', Format(Ok) + '|' + T);
        Ok := Evaluate(T40, G);
        Observer.Observe('t40_ok', Format(Ok) + '|' + T40);
        Ok := Evaluate(C40, G);
        Observer.Observe('c40_ok', Format(Ok) + '|' + C40);
        Ok := Evaluate(T, Format(G));
        Observer.Observe('text_format_ok', Format(Ok) + '|' + T);
        Ok := Evaluate(T, Format(G, 0, 1));
        Observer.Observe('text_format1', Format(Ok) + '|' + T);
        Ok := Evaluate(T, Format(G, 0, 2));
        Observer.Observe('text_format2', Format(Ok) + '|' + T);
        Ok := Evaluate(T, Format(G, 0, 3));
        Observer.Observe('text_format3', Format(Ok) + '|' + T);
        Ok := Evaluate(T, Format(G, 0, 4));
        Observer.Observe('text_format4', Format(Ok) + '|' + T);
        Observer.Finish();
    end;

    [Test]
    procedure Evaluate_Guid_From_Text_Forms()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        Ref: Guid;
        Ok: Boolean;
    begin
        Ref := Fixed();
        Ok := Evaluate(G, Format(Ref));
        Observer.Observe('braced', Format(Ok) + '|' + Format(G = Ref));
        Clear(G);
        Ok := Evaluate(G, Format(Ref, 0, 4));
        Observer.Observe('format4', Format(Ok) + '|' + Format(G = Ref));
        Clear(G);
        Ok := Evaluate(G, Format(Ref, 0, 2));
        Observer.Observe('format2', Format(Ok) + '|' + Format(G = Ref));
        Clear(G);
        Ok := Evaluate(G, 'garbage');
        Observer.Observe('garbage', Format(Ok) + '|' + Format(IsNullGuid(G)));
        Ok := Evaluate(G, '');
        Observer.Observe('empty', Format(Ok) + '|' + Format(IsNullGuid(G)));
        Ok := Evaluate(G, Ref);
        Observer.Observe('guid_arg', Format(Ok) + '|' + Format(G = Ref));
        Ok := Evaluate(G, '{00000000-0000-0000-0000-000000000000}');
        Observer.Observe('null_text', Format(Ok) + '|' + Format(IsNullGuid(G)));
        Observer.Finish();
    end;

    [Test]
    procedure Evaluate_Text_From_Guid_TryFunction()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        T: Text;
    begin
        G := Fixed();
        if TryEvalText(G, T) then
            Observer.Observe('try_ok', T)
        else
            Observer.Observe('try_error', GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Finish();
    end;
}
