// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsontoken/jsontoken-selecttokens-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 80505
// Probe: observe probe; every literal asserted below is what the corpus CI service tiers produced.
// Facts: JsonToken.SelectTokens(Path, var List of [JsonToken]) on an object token, an array token and a value token: several matches (wildcard, recursive
// descent, filter), no match, a pre-filled list, and invalid paths: the Boolean, the tokens returned, GetLastErrorText and GetLastErrorCode.
// The method needs app runtime 17: on BC 27 (runtime 16.1) the compiler refuses it (must-not-compile case 1200), so the tests are BC28PLUS.
// BC versions: 28, 29 (corpus CI)

codeunit 80505 "LT AY JsonToken SelectTokens"
{
    Subtype = Test;
    TestPermissions = Disabled;
#if BC28PLUS

    [TryFunction]
    local procedure TrySelect(T: JsonToken; Path: Text; var L: List of [JsonToken]; var Ret: Boolean)
    begin
        Ret := T.SelectTokens(Path, L);
    end;

    local procedure Q(var Observer: Codeunit "Probe Observer"; T: JsonToken; ObsKey: Text; Path: Text; PreFill: Boolean)
    var
        L: List of [JsonToken];
        X: JsonToken;
        Ret: Boolean;
        Out: Text;
    begin
        if PreFill then begin
            X.ReadFrom('"old"');
            L.Add(X);
        end;
        ClearLastError();
        if TrySelect(T, Path, L, Ret) then begin
            Out := Format(Ret) + ' n=' + Format(L.Count()) + ':';
            foreach X in L do
                Out += Format(X) + '@' + X.Path() + ';';
            if GetLastErrorText() <> '' then
                Out += ' last=' + GetLastErrorText() + '|' + GetLastErrorCode();
            Observer.Observe(ObsKey, Out);
        end else
            Observer.ObserveError(ObsKey);
    end;

    local procedure Doc(): JsonToken
    var
        T: JsonToken;
    begin
        T.ReadFrom('{"a":[{"n":1,"p":5},{"n":2,"p":15},{"n":3}],"b":{"n":4}}');
        exit(T);
    end;

    [Test]
    procedure SelectTokens_ObjectToken_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Q(Observer, Doc(), 'wildcard', '$.a[*].n', false);
        Q(Observer, Doc(), 'recursive', '$..n', false);
        Q(Observer, Doc(), 'filter', '$.a[?(@.p > 10)].n', false);
        Observer.Finish();
    end;

    [Test]
    procedure SelectTokens_ObjectToken_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Q(Observer, Doc(), 'single', '$.b.n', false);
        Q(Observer, Doc(), 'no_dollar', 'a[0].n', false);
        Q(Observer, Doc(), 'no_match', '$.zz', false);
        Observer.Finish();
    end;

    [Test]
    procedure SelectTokens_ObjectToken_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Q(Observer, Doc(), 'no_match_prefilled', '$.zz', true);
        Q(Observer, Doc(), 'match_prefilled', '$.a[*].n', true);
        Observer.Finish();
    end;

    [Test]
    procedure SelectTokens_ArrayAndValueToken_1()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonToken;
        V: JsonToken;
    begin
        A.ReadFrom('[1,[2,3],{"x":4}]');
        V.ReadFrom('7');
        Q(Observer, A, 'array_all', '$[*]', false);
        Q(Observer, A, 'array_slice', '$[0:2]', false);
        Q(Observer, A, 'array_recursive', '$..x', false);
        Observer.Finish();
    end;

    [Test]
    procedure SelectTokens_ArrayAndValueToken_2()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonToken;
        V: JsonToken;
    begin
        A.ReadFrom('[1,[2,3],{"x":4}]');
        V.ReadFrom('7');
        Q(Observer, V, 'value_root', '$', false);
        Q(Observer, V, 'value_child', '$.a', false);
        Observer.Finish();
    end;

    [Test]
    procedure SelectTokens_InvalidPath_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Q(Observer, Doc(), 'unclosed_bracket', '$.a[', false);
        Q(Observer, Doc(), 'bad_filter', '$.a[?(@.p >)]', false);
        Q(Observer, Doc(), 'empty', '', false);
        Observer.Finish();
    end;

    [Test]
    procedure SelectTokens_InvalidPath_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Q(Observer, Doc(), 'unclosed_prefilled', '$.a[', true);
        Observer.Finish();
    end;
#endif
}
