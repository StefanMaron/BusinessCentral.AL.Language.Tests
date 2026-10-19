// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-selecttoken-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: leads of corpus issue 671 (part F, items 36, 37, 43): JsonObject.SelectToken with a filter that compares with double or single quotes,
// a union of keys ('$.[A,B]', '$[A,B]', "$['A','B']"), and the last array element through '[(@.length-1)]' and '[-1:]'.
// Each path is observed as: the Boolean SelectToken returns, the token written as text, and the last error text and code (an invalid path
// answers false and leaves a last error without raising, see json/lt-json-selecttokens/SelectTokensList.al); a path that raises is observed
// as 'raised' with its error.
// Facts: see the Expect lines of each test.
// BC versions: 27, 28, 29

codeunit 85723 "LT DB JPath Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySel(O: JsonObject; Path: Text; var T: JsonToken; var Ret: Boolean)
    begin
        Ret := O.SelectToken(Path, T);
    end;

    local procedure Sel(var Observer: Codeunit "Probe Observer"; Name: Text; O: JsonObject; Path: Text)
    var
        T: JsonToken;
        Ret: Boolean;
        Written: Text;
    begin
        ClearLastError();
        if not TrySel(O, Path, T, Ret) then begin
            Observer.Observe(Name, 'raised');
            Observer.ObserveError(Name);
            exit;
        end;
        if Ret then
            T.WriteTo(Written);
        Observer.Observe(Name, Format(Ret) + ' [' + Written + ']');
        Observer.ObserveError(Name);
    end;

    local procedure Employees() O: JsonObject
    begin
        O.ReadFrom('{"company":{"employees":[{"id":"John","salary":100},{"id":"Jane","salary":200}]}}');
    end;

    local procedure Messages(Json: Text) O: JsonObject
    begin
        O.ReadFrom(Json);
    end;

    [Test]
    procedure Filter_DoubleAndSingleQuotes()
    // Issue 671 item 36 (microsoft/AL#5006).
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sel(Observer, 'double', Employees(), '$.company.employees[?(@.id=="John")].salary');
        Sel(Observer, 'single', Employees(), '$.company.employees[?(@.id==''John'')].salary');
        Sel(Observer, 'single_nomatch', Employees(), '$.company.employees[?(@.id==''Nobody'')].salary');
        Sel(Observer, 'double_nomatch', Employees(), '$.company.employees[?(@.id=="Nobody")].salary');
        Sel(Observer, 'number', Employees(), '$.company.employees[?(@.salary==200)].id');
        Sel(Observer, 'single_two', Employees(), '$.company.employees[?(@.salary>50)].id');
        Observer.Finish();
    end;

    [Test]
    procedure Union_OfKeys()
    // Issue 671 item 37 (microsoft/AL#4957).
    var
        Observer: Codeunit "Probe Observer";
        OnlyApi: JsonObject;
        OnlyMsg: JsonObject;
        Both: JsonObject;
        Neither: JsonObject;
    begin
        OnlyApi := Messages('{"ApiMessage":"api"}');
        OnlyMsg := Messages('{"Message":"msg"}');
        Both := Messages('{"ApiMessage":"api","Message":"msg"}');
        Neither := Messages('{"Other":"x"}');
        Sel(Observer, 'dot_api', OnlyApi, '$.[ApiMessage,Message]');
        Sel(Observer, 'dot_msg', OnlyMsg, '$.[ApiMessage,Message]');
        Sel(Observer, 'dot_both', Both, '$.[ApiMessage,Message]');
        Sel(Observer, 'dot_neither', Neither, '$.[ApiMessage,Message]');
        Sel(Observer, 'nodot_api', OnlyApi, '$[ApiMessage,Message]');
        Sel(Observer, 'nodot_msg', OnlyMsg, '$[ApiMessage,Message]');
        Sel(Observer, 'nodot_both', Both, '$[ApiMessage,Message]');
        Sel(Observer, 'quoted_api', OnlyApi, '$[''ApiMessage'',''Message'']');
        Sel(Observer, 'quoted_msg', OnlyMsg, '$[''ApiMessage'',''Message'']');
        Sel(Observer, 'quoted_both', Both, '$[''ApiMessage'',''Message'']');
        Sel(Observer, 'quoted_neither', Neither, '$[''ApiMessage'',''Message'']');
        Sel(Observer, 'plain_api', OnlyApi, '$.ApiMessage');
        Sel(Observer, 'plain_on_msg', OnlyMsg, '$.ApiMessage');
        Observer.Finish();
    end;

    [Test]
    procedure LastArrayElement()
    // Issue 671 item 43 (microsoft/AL#6323).
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
    begin
        O.ReadFrom('{"items":[{"x":1},{"x":2},{"x":3}]}');
        Sel(Observer, 'length_minus_1', O, '$.items[(@.length-1)].x');
        Sel(Observer, 'slice_minus_1', O, '$.items[-1:].x');
        Sel(Observer, 'index_minus_1', O, '$.items[-1].x');
        Sel(Observer, 'slice_minus_2', O, '$.items[-2:].x');
        Sel(Observer, 'index_2', O, '$.items[2].x');
        Observer.Finish();
    end;
}
