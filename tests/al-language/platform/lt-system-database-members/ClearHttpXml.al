// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74019
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Clear on HttpRequestMessage, HttpContent, XmlDocument, FilterPageBuilder
// BC versions: 29 (27 and 28 by CI)
// Tag: P95

codeunit 74019 "LT P95 Clear Http Xml"
{
    Subtype = Test;
    TestPermissions = Disabled;


    [Test]
    procedure ClearHttpXml()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        Cnt: HttpContent;
        Txt: Text;
        Xd: XmlDocument;
        Xe: XmlElement;
        FP: FilterPageBuilder;
    begin
        Req.Method := 'POST';
        Req.SetRequestUri('http://localhost/p95');
        Clear(Req);
        Observer.Observe('request', '[' + Req.Method + '][' + Req.GetRequestUri() + ']');
        Cnt.WriteFrom('abc');
        Clear(Cnt);
        Cnt.ReadAs(Txt);
        Observer.Observe('content', '[' + Txt + ']');
        Xd := XmlDocument.Create();
        Xd.Add(XmlElement.Create('root'));
        Clear(Xd);
        Observer.Observe('xml_has_root', Format(Xd.GetRoot(Xe)));
        FP.AddTable('Rows', 2000000038);
        Clear(FP);
        Observer.Observe('filterpage_count', Format(FP.Count()));

        Observer.Finish();
    end;

}
