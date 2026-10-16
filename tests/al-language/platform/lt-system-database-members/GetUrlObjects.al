// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-geturl-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73981
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: GetUrl with object type and id, without record: each object type, odd ids, other client types
// BC versions: 29 (27 and 28 by CI)
// Tag: P95

codeunit 73981 "LT P95 GetUrl Objects"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Shape(Url: Text): Text
    begin
        exit(Format(Url <> '') + '|' + Format(Url.StartsWith('http')) + '|' + Format(Url.Contains('company=')) + '|' + Format(Url.Contains('page=')) + '|' + Format(Url.Contains('report=')) + '|' + Format(Url.Contains('codeunit=')) + '|' + Format(Url.Contains('table=')));
    end;

    local procedure Tail(Url: Text): Text
    var
        P: Integer;
    begin
        P := StrPos(Url, '?');
        if P = 0 then
            exit('noquery');
        exit(CopyStr(Url, P));
    end;

    local procedure Err(): Text
    begin
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;


    [TryFunction]
    local procedure TryO(CT: ClientType; OT: ObjectType; Id: Integer; var R: Text)
    begin
        R := GetUrl(CT, CompanyName(), OT, Id);
    end;

    local procedure One(var Observer: Codeunit "Probe Observer"; Name: Text; CT: ClientType; OT: ObjectType; Id: Integer)
    var
        R: Text;
    begin
        if TryO(CT, OT, Id, R) then
            Observer.Observe(Name, Shape(R) + '|' + Tail(R))
        else
            Observer.Observe(Name, Err());
    end;

    [Test]
    procedure GetUrl_Object_Types_Web()
    var
        Observer: Codeunit "Probe Observer";
    begin
        One(Observer, 'page', ClientType::Web, ObjectType::Page, 21);
        One(Observer, 'report', ClientType::Web, ObjectType::Report, 101);
        One(Observer, 'codeunit', ClientType::Web, ObjectType::Codeunit, 1);
        One(Observer, 'table', ClientType::Web, ObjectType::Table, 18);
        One(Observer, 'query', ClientType::Web, ObjectType::Query, 100);
        One(Observer, 'xmlport', ClientType::Web, ObjectType::XMLport, 1);
        Observer.Finish();
    end;

    [Test]
    procedure GetUrl_Object_Ids_Web()
    var
        Observer: Codeunit "Probe Observer";
    begin
        One(Observer, 'page_zero', ClientType::Web, ObjectType::Page, 0);
        One(Observer, 'page_negative', ClientType::Web, ObjectType::Page, -1);
        One(Observer, 'page_missing', ClientType::Web, ObjectType::Page, 2147483647);
        One(Observer, 'page_unused_id', ClientType::Web, ObjectType::Page, 73999);
        One(Observer, 'report_missing', ClientType::Web, ObjectType::Report, 2147483647);
        One(Observer, 'codeunit_zero', ClientType::Web, ObjectType::Codeunit, 0);
        One(Observer, 'table_zero', ClientType::Web, ObjectType::Table, 0);
        One(Observer, 'table_missing', ClientType::Web, ObjectType::Table, 2147483647);
        Observer.Finish();
    end;

    [Test]
    procedure GetUrl_Object_Types_OtherClients()
    var
        Observer: Codeunit "Probe Observer";
    begin
        One(Observer, 'tablet_page', ClientType::Tablet, ObjectType::Page, 21);
        One(Observer, 'phone_page', ClientType::Phone, ObjectType::Page, 21);
        One(Observer, 'desktop_page', ClientType::Desktop, ObjectType::Page, 21);
        One(Observer, 'default_page', ClientType::Default, ObjectType::Page, 21);
        One(Observer, 'soap_page', ClientType::SOAP, ObjectType::Page, 21);
        One(Observer, 'soap_codeunit', ClientType::SOAP, ObjectType::Codeunit, 1);
        One(Observer, 'odata_page', ClientType::OData, ObjectType::Page, 21);
        One(Observer, 'odata_table', ClientType::OData, ObjectType::Table, 18);
        One(Observer, 'odatav4_page', ClientType::ODataV4, ObjectType::Page, 21);
        One(Observer, 'api_page', ClientType::Api, ObjectType::Page, 21);
        One(Observer, 'web_report_tablet', ClientType::Tablet, ObjectType::Report, 101);
        Observer.Finish();
    end;

}
