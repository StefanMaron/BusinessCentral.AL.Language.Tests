// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httprequesttype/httprequesttype-option
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: the HttpRequestType option type: Format of every member as text (Format 0,0), as ordinal (Format 0,2) and as number text (Format 0,1), a case statement over every member, Evaluate by name and by number, and the error text of Evaluate for an invalid name and ordinal. The type is option-like: AsInteger does not exist and an Integer is not assignable (AL0132 and AL0122 at compile time).
//   Settles #626 items 11 to 15 for HttpRequestType.
// BC versions: 27, 28, 29

codeunit 77510 "LT AC HttpReqType Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_HttpRequestType_Format()
    var
        Observer: Codeunit "Probe Observer";
    begin

        Observer.Observe('text_Unknown', Format(HttpRequestType::Unknown));
        Observer.Observe('text_Get', Format(HttpRequestType::Get));
        Observer.Observe('text_Delete', Format(HttpRequestType::Delete));
        Observer.Observe('text_Post', Format(HttpRequestType::Post));
        Observer.Observe('text_Put', Format(HttpRequestType::Put));
        Observer.Observe('text_Patch', Format(HttpRequestType::Patch));
        Observer.Observe('text_Options', Format(HttpRequestType::Options));
        Observer.Observe('text_Head', Format(HttpRequestType::Head));
        Observer.Observe('text_Connect', Format(HttpRequestType::Connect));
        Observer.Observe('text_Trace', Format(HttpRequestType::Trace));
        Observer.Observe('ordinal_Unknown', Format(HttpRequestType::Unknown, 0, 2));
        Observer.Observe('ordinal_Get', Format(HttpRequestType::Get, 0, 2));
        Observer.Observe('ordinal_Delete', Format(HttpRequestType::Delete, 0, 2));
        Observer.Observe('ordinal_Post', Format(HttpRequestType::Post, 0, 2));
        Observer.Observe('ordinal_Put', Format(HttpRequestType::Put, 0, 2));
        Observer.Observe('ordinal_Patch', Format(HttpRequestType::Patch, 0, 2));
        Observer.Observe('ordinal_Options', Format(HttpRequestType::Options, 0, 2));
        Observer.Observe('ordinal_Head', Format(HttpRequestType::Head, 0, 2));
        Observer.Observe('ordinal_Connect', Format(HttpRequestType::Connect, 0, 2));
        Observer.Observe('ordinal_Trace', Format(HttpRequestType::Trace, 0, 2));
        Observer.Observe('number_Unknown', Format(HttpRequestType::Unknown, 0, 1));
        Observer.Observe('number_Get', Format(HttpRequestType::Get, 0, 1));
        Observer.Observe('number_Delete', Format(HttpRequestType::Delete, 0, 1));
        Observer.Observe('number_Post', Format(HttpRequestType::Post, 0, 1));
        Observer.Observe('number_Put', Format(HttpRequestType::Put, 0, 1));
        Observer.Observe('number_Patch', Format(HttpRequestType::Patch, 0, 1));
        Observer.Observe('number_Options', Format(HttpRequestType::Options, 0, 1));
        Observer.Observe('number_Head', Format(HttpRequestType::Head, 0, 1));
        Observer.Observe('number_Connect', Format(HttpRequestType::Connect, 0, 1));
        Observer.Observe('number_Trace', Format(HttpRequestType::Trace, 0, 1));
        Observer.Finish();
    end;

    [Test]
    procedure AC_HttpRequestType_Variable()
    var
        Observer: Codeunit "Probe Observer";
        V: HttpRequestType;
    begin

        Observer.Observe('default', Format(V));
        Observer.Observe('default_ordinal', Format(V, 0, 2));
        V := HttpRequestType::Trace;
        Observer.Observe('last', Format(V));
        Observer.Observe('last_ordinal', Format(V, 0, 2));
        Observer.Observe('eq_last', Format(V = HttpRequestType::Trace));
        Observer.Observe('eq_first', Format(V = HttpRequestType::Unknown));
        Clear(V);
        Observer.Observe('cleared', Format(V));
        Observer.Finish();
    end;

    [Test]
    procedure AC_HttpRequestType_Case()
    var
        Observer: Codeunit "Probe Observer";
        V: HttpRequestType;
    begin
        V := HttpRequestType::Unknown;
        Observer.Observe('case_Unknown', CaseName(V));
        V := HttpRequestType::Get;
        Observer.Observe('case_Get', CaseName(V));
        V := HttpRequestType::Delete;
        Observer.Observe('case_Delete', CaseName(V));
        V := HttpRequestType::Post;
        Observer.Observe('case_Post', CaseName(V));
        V := HttpRequestType::Put;
        Observer.Observe('case_Put', CaseName(V));
        V := HttpRequestType::Patch;
        Observer.Observe('case_Patch', CaseName(V));
        V := HttpRequestType::Options;
        Observer.Observe('case_Options', CaseName(V));
        V := HttpRequestType::Head;
        Observer.Observe('case_Head', CaseName(V));
        V := HttpRequestType::Connect;
        Observer.Observe('case_Connect', CaseName(V));
        V := HttpRequestType::Trace;
        Observer.Observe('case_Trace', CaseName(V));
        Observer.Finish();
    end;

    local procedure CaseName(V: HttpRequestType): Text
    begin
        case V of
            HttpRequestType::Unknown:
                exit('is_Unknown');
            HttpRequestType::Get:
                exit('is_Get');
            HttpRequestType::Delete:
                exit('is_Delete');
            HttpRequestType::Post:
                exit('is_Post');
            HttpRequestType::Put:
                exit('is_Put');
            HttpRequestType::Patch:
                exit('is_Patch');
            HttpRequestType::Options:
                exit('is_Options');
            HttpRequestType::Head:
                exit('is_Head');
            HttpRequestType::Connect:
                exit('is_Connect');
            HttpRequestType::Trace:
                exit('is_Trace');
            else
                exit('other');
        end;
    end;
}

codeunit 77511 "LT AC HttpReqType Eval"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_HttpRequestType_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        V: HttpRequestType;
        Ok: Boolean;
    begin
        Clear(V);
        Ok := Evaluate(V, 'Unknown');
        Observer.Observe('name_Unknown', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'Get');
        Observer.Observe('name_Get', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'Delete');
        Observer.Observe('name_Delete', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'Post');
        Observer.Observe('name_Post', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'Put');
        Observer.Observe('name_Put', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'Patch');
        Observer.Observe('name_Patch', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'Options');
        Observer.Observe('name_Options', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'Head');
        Observer.Observe('name_Head', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'Connect');
        Observer.Observe('name_Connect', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'Trace');
        Observer.Observe('name_Trace', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'get');
        Observer.Observe('name_lowercase', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'GET');
        Observer.Observe('name_uppercase', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '0');
        Observer.Observe('number_0', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '1');
        Observer.Observe('number_1', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '2');
        Observer.Observe('number_2', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '3');
        Observer.Observe('number_3', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '4');
        Observer.Observe('number_4', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '5');
        Observer.Observe('number_5', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '6');
        Observer.Observe('number_6', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '7');
        Observer.Observe('number_7', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '8');
        Observer.Observe('number_8', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '9');
        Observer.Observe('number_9', Format(Ok) + '/' + Format(V, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure AC_HttpRequestType_EvaluateInvalid()
    var
        Observer: Codeunit "Probe Observer";
        V: HttpRequestType;
    begin
        Clear(V);
        if Evaluate(V, 'Bogus') then
            Observer.Observe('bogus_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('bogus');
        Clear(V);
        if Evaluate(V, '') then
            Observer.Observe('empty_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('empty');
        Clear(V);
        if Evaluate(V, '10') then
            Observer.Observe('past_end_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('past_end');
        Clear(V);
        if Evaluate(V, '99') then
            Observer.Observe('large_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('large');
        Clear(V);
        if Evaluate(V, '-1') then
            Observer.Observe('negative_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('negative');
        Clear(V);
        if Evaluate(V, ' Get') then
            Observer.Observe('space_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('space');
        Clear(V);
        if Evaluate(V, '1.5') then
            Observer.Observe('decimal_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('decimal');
        Observer.Finish();
    end;
}
