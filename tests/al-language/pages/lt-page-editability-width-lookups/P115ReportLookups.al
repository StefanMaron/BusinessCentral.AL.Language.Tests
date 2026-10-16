// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P115 Grp/State and LT P115 Grp List (P115Fixtures.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

report 70213 "LT P115 Rpt"
{
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(G)
                {
                    field(GrpFld; GrpCode)
                    {
                        ApplicationArea = All;
                        TableRelation = "LT P115 Grp".Code;
                    }
                    field(PageIdFld; PageText)
                    {
                        ApplicationArea = All;
                        LookupPageId = "LT P115 Grp List";
                    }
                    field(AssistFld; AssistText)
                    {
                        ApplicationArea = All;
                        trigger OnAssistEdit()
                        var
                            State: Codeunit "LT P115 State";
                        begin
                            State.Add('rpt assist:' + AssistText);
                            AssistText := 'assisted';
                        end;
                    }
                }
            }
        }
    }

    var
        GrpCode: Code[10];
        PageText: Text[50];
        AssistText: Text[50];

    trigger OnPreReport()
    var
        State: Codeunit "LT P115 State";
    begin
        State.Add('pre:' + GrpCode + '|' + PageText + '|' + AssistText);
    end;
}

codeunit 70214 "LT P115 Report Lookups"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Grp: Record "LT P115 Grp";
        State: Codeunit "LT P115 State";
    begin
        Grp.DeleteAll();
        State.Take();
        Grp.Code := 'G1';
        Grp.Descr := 'Group one';
        Grp.Insert();
        Grp.Code := 'G2';
        Grp.Descr := 'Group two';
        Grp.Insert();
        Commit();
    end;

    [ModalPageHandler]
    procedure PickG2(var P: TestPage "LT P115 Grp List")
    begin
        Observer.Observe('lookup-first-code', P.CodeCtl.Value());
        P.GoToKey('G2');
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CancelG(var P: TestPage "LT P115 Grp List")
    begin
        P.GoToKey('G2');
        P.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure RelationOk(var RP: TestRequestPage "LT P115 Rpt")
    begin
        Observer.Observe('rel-before', RP.GrpFld.Value());
        RP.GrpFld.Lookup();
        Observer.Observe('rel-after', RP.GrpFld.Value());
        RP.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure RelationCancel(var RP: TestRequestPage "LT P115 Rpt")
    begin
        RP.GrpFld.Lookup();
        Observer.Observe('rel-after-cancel', RP.GrpFld.Value());
        RP.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure PageIdOk(var RP: TestRequestPage "LT P115 Rpt")
    begin
        RP.PageIdFld.Lookup();
        Observer.Observe('pageid-after', RP.PageIdFld.Value());
        RP.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure AssistOk(var RP: TestRequestPage "LT P115 Rpt")
    begin
        Observer.Observe('assist-before', RP.AssistFld.Value());
        RP.AssistFld.AssistEdit();
        Observer.Observe('assist-after', RP.AssistFld.Value());
        RP.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure TypedRelation(var RP: TestRequestPage "LT P115 Rpt")
    begin
        RP.GrpFld.SetValue('G1');
        Observer.Observe('typed-valid', RP.GrpFld.Value());
        asserterror RP.GrpFld.SetValue('NOPE');
        Observer.ObserveError('typed-invalid');
        Observer.Observe('typed-after-invalid', RP.GrpFld.Value());
        RP.GrpFld.SetValue('');
        Observer.Observe('typed-blank', RP.GrpFld.Value());
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('AssistOk')]
    procedure P115_RequestPage_AssistEdit()
    var
        State: Codeunit "LT P115 State";
    begin
        Seed();
        Report.Run(Report::"LT P115 Rpt");
        Observer.Observe('log', State.Take());
        Observer.Expect('assist-before', '');
        Observer.Expect('assist-after', 'assisted');
        Observer.Expect('log', 'rpt assist:;pre:||assisted;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TypedRelation')]
    procedure P115_RequestPage_TableRelation_Validation()
    var
        State: Codeunit "LT P115 State";
    begin
        Seed();
        Report.Run(Report::"LT P115 Rpt");
        Observer.Observe('log', State.Take());
        Observer.Expect('typed-valid', 'G1');
        Observer.Expect('typed-invalid|text', 'Validation error for Field: GrpFld,  Message = ''The LT P115 Grp does not exist. Identification fields and values: Code=''NOPE''''');
        Observer.Expect('typed-invalid|code', 'TestValidation');
        Observer.Expect('typed-after-invalid', 'G1');
        Observer.Expect('typed-blank', '');
        Observer.Expect('log', 'pre:||;');
        Observer.Verify();
    end;
}
