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
        Observer.Expect('double', 'No []');
        Observer.Expect('double|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('double|code', 'InvalidOperation');
        Observer.Expect('single', 'Yes [100]');
        Observer.Expect('single|text', '');
        Observer.Expect('single|code', '');
        Observer.Expect('single_nomatch', 'No []');
        Observer.Expect('single_nomatch|text', '');
        Observer.Expect('single_nomatch|code', '');
        Observer.Expect('double_nomatch', 'No []');
        Observer.Expect('double_nomatch|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('double_nomatch|code', 'InvalidOperation');
        Observer.Expect('number', 'Yes ["Jane"]');
        Observer.Expect('number|text', '');
        Observer.Expect('number|code', '');
        Observer.Expect('single_two', 'No []');
        Observer.Expect('single_two|text', '');
        Observer.Expect('single_two|code', '');
        Observer.Verify();
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
        Observer.Expect('dot_api', 'No []');
        Observer.Expect('dot_api|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('dot_api|code', 'InvalidOperation');
        Observer.Expect('dot_msg', 'No []');
        Observer.Expect('dot_msg|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('dot_msg|code', 'InvalidOperation');
        Observer.Expect('dot_both', 'No []');
        Observer.Expect('dot_both|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('dot_both|code', 'InvalidOperation');
        Observer.Expect('dot_neither', 'No []');
        Observer.Expect('dot_neither|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('dot_neither|code', 'InvalidOperation');
        Observer.Expect('nodot_api', 'No []');
        Observer.Expect('nodot_api|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('nodot_api|code', 'InvalidOperation');
        Observer.Expect('nodot_msg', 'No []');
        Observer.Expect('nodot_msg|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('nodot_msg|code', 'InvalidOperation');
        Observer.Expect('nodot_both', 'No []');
        Observer.Expect('nodot_both|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('nodot_both|code', 'InvalidOperation');
        Observer.Expect('quoted_api', 'Yes ["api"]');
        Observer.Expect('quoted_api|text', '');
        Observer.Expect('quoted_api|code', '');
        Observer.Expect('quoted_msg', 'Yes ["msg"]');
        Observer.Expect('quoted_msg|text', '');
        Observer.Expect('quoted_msg|code', '');
        Observer.Expect('quoted_both', 'No []');
        Observer.Expect('quoted_both|text', '');
        Observer.Expect('quoted_both|code', '');
        Observer.Expect('quoted_neither', 'No []');
        Observer.Expect('quoted_neither|text', '');
        Observer.Expect('quoted_neither|code', '');
        Observer.Expect('plain_api', 'Yes ["api"]');
        Observer.Expect('plain_api|text', '');
        Observer.Expect('plain_api|code', '');
        Observer.Expect('plain_on_msg', 'No []');
        Observer.Expect('plain_on_msg|text', '');
        Observer.Expect('plain_on_msg|code', '');
        Observer.Verify();
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
        Observer.Expect('length_minus_1', 'No []');
        Observer.Expect('length_minus_1|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('length_minus_1|code', 'InvalidOperation');
        Observer.Expect('slice_minus_1', 'Yes [3]');
        Observer.Expect('slice_minus_1|text', '');
        Observer.Expect('slice_minus_1|code', '');
        Observer.Expect('index_minus_1', 'No []');
        Observer.Expect('index_minus_1|text', 'An invalid argument was passed to a ''Json'' data type method.');
        Observer.Expect('index_minus_1|code', 'ArgumentOutOfRange');
        Observer.Expect('slice_minus_2', 'No []');
        Observer.Expect('slice_minus_2|text', '');
        Observer.Expect('slice_minus_2|code', '');
        Observer.Expect('index_2', 'Yes [3]');
        Observer.Expect('index_2|text', '');
        Observer.Expect('index_2|code', '');
        Observer.Verify();
    end;
}
