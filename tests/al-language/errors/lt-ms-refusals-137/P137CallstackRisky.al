// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-callstack-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); P137Callstack.al (table 74436, page 74439)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SessionInformation.Callstack read from a query's OnBeforeOpen, an xmlport's OnPreXmlPort, OnAfterGetRecord of a table element and OnPostXmlPort, and from subscribers of the page events OnOpenPageEvent and OnAfterGetRecordEvent
// BC versions: 29 (27 and 28 by CI)

query 74440 "LT P137 CS Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Source; "LT P137 CS Table")
        {
            column(Id; Id) { }
        }
    }

    trigger OnBeforeOpen()
    var
        Ctl: Codeunit "LT P137 Ctl";
    begin
        Ctl.Add('query OnBeforeOpen: ' + Ctl.CutRunner(SessionInformation.Callstack));
    end;
}

xmlport 74441 "LT P137 CS Xmlport"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Source; "LT P137 CS Table")
            {
                fieldelement(Id; Source.Id) { }

                trigger OnAfterGetRecord()
                var
                    Ctl: Codeunit "LT P137 Ctl";
                begin
                    Ctl.Add('xmlport OnAfterGetRecord: ' + Ctl.CutRunner(SessionInformation.Callstack));
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    var
        Ctl: Codeunit "LT P137 Ctl";
    begin
        Ctl.Add('xmlport OnPreXmlPort: ' + Ctl.CutRunner(SessionInformation.Callstack));
    end;

    trigger OnPostXmlPort()
    var
        Ctl: Codeunit "LT P137 Ctl";
    begin
        Ctl.Add('xmlport OnPostXmlPort: ' + Ctl.CutRunner(SessionInformation.Callstack));
    end;
}

codeunit 74443 "LT P137 CS Page Subs"
{
    [EventSubscriber(ObjectType::Page, Page::"LT P137 CS Page", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPageSub()
    var
        Ctl: Codeunit "LT P137 Ctl";
    begin
        Ctl.Add('sub OnOpenPageEvent: ' + Ctl.CutRunner(SessionInformation.Callstack));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P137 CS Page", 'OnAfterGetRecordEvent', '', false, false)]
    local procedure OnAfterGetRecordSub(var Rec: Record "LT P137 CS Table")
    var
        Ctl: Codeunit "LT P137 Ctl";
    begin
        Ctl.Add('sub OnAfterGetRecordEvent: ' + Ctl.CutRunner(SessionInformation.Callstack));
    end;
}

codeunit 74444 "LT P137 Callstack Risky"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Clean()
    var
        Row: Record "LT P137 CS Table";
        Ctl: Codeunit "LT P137 Ctl";
    begin
        Row.DeleteAll(false);
        Row.Id := 1;
        Row.Insert(false);
        Ctl.Take();
    end;

    [Test]
    procedure P137_Callstack_Query()
    var
        Observer: Codeunit "Probe Observer";
        Ctl: Codeunit "LT P137 Ctl";
        Qry: Query "LT P137 CS Query";
    begin
        Clean();
        Qry.Open();
        Observer.Observe('open', Ctl.Take());
        Qry.Close();
        Observer.Expect('open', 'query OnBeforeOpen: "LT P137 CS Query"(Query 74440).OnBeforeOpen(Trigger) line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack Risky"(CodeUnit 74444).P137_Callstack_Query line 7 - AL Language Coverage Tests by AL Language version x\;');
        Observer.Verify();
    end;

    [Test]
    procedure P137_Callstack_Xmlport()
    var
        Observer: Codeunit "Probe Observer";
        Ctl: Codeunit "LT P137 Ctl";
        Row: Record "LT P137 CS Table";
        OutS: OutStream;
    begin
        Clean();
        Row.Get(1);
        Row.Data.CreateOutStream(OutS);
        Xmlport.Export(Xmlport::"LT P137 CS Xmlport", OutS);
        Observer.Observe('export', Ctl.Take());
        Observer.Expect('export', 'xmlport OnPreXmlPort: "LT P137 CS Xmlport"(XmlPort 74441).OnPreXmlPort(Trigger) line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack Risky"(CodeUnit 74444).P137_Callstack_Xmlport line 10 - AL Language Coverage Tests by AL Language version x\;xmlport OnAfterGetRecord: "LT P137 CS Xmlport"(XmlPort 74441)."Source - OnAfterGetRecord"(Trigger) line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack Risky"(CodeUnit 74444).P137_Callstack_Xmlport line 10 - AL Language Coverage Tests by AL Language version x\;xmlport OnPostXmlPort: "LT P137 CS Xmlport"(XmlPort 74441).OnPostXmlPort(Trigger) line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack Risky"(CodeUnit 74444).P137_Callstack_Xmlport line 10 - AL Language Coverage Tests by AL Language version x\;');
        Observer.Verify();
    end;

    [Test]
    procedure P137_Callstack_PageEventSubscribers()
    var
        Observer: Codeunit "Probe Observer";
        Ctl: Codeunit "LT P137 Ctl";
        Card: TestPage "LT P137 CS Page";
    begin
        Clean();
        Card.OpenEdit();
        Observer.Observe('open_edit', Ctl.Take());
        Card.Close();
        Ctl.Take();
        Observer.Expect('open_edit', 'sub OnOpenPageEvent: "LT P137 CS Page Subs"(CodeUnit 74443).OnOpenPageSub line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack Risky"(CodeUnit 74444).P137_Callstack_PageEventSubscribers line 7 - AL Language Coverage Tests by AL Language version x\;page OnAfterGetRecord: "LT P137 CS Page"(Page 74439).OnAfterGetRecord(Trigger) line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack Risky"(CodeUnit 74444).P137_Callstack_PageEventSubscribers line 7 - AL Language Coverage Tests by AL Language version x\;sub OnAfterGetRecordEvent: "LT P137 CS Page Subs"(CodeUnit 74443).OnAfterGetRecordSub line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack Risky"(CodeUnit 74444).P137_Callstack_PageEventSubscribers line 7 - AL Language Coverage Tests by AL Language version x\;');
        Observer.Verify();
    end;
}
