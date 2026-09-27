// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-app-area
// Scope: in-scope
// Fixtures used: Assert (60021), table 67530 "PAA Area Record", and the page and codeunit
// declared below.
//
// CLAIM: a page ACTION whose ApplicationArea is not enabled for the session is removed from
// the page, so a TestPage reports it as not found and its OnAction does not run, while an
// action whose area IS enabled stays reachable and runs. That holds for an action nested in an
// action group too. An empty application-area string enables every area.
//
// The not-found message is a guess before this PR's first run: BC's NavTestPageBase.GetAction
// raises NavTestActionNotFoundException ("The action with ID = ... is not found on the page.")
// when the page has no such action; nothing has measured that on a service tier for an action
// removed by application area.
//
// Every test sets the session's application areas itself and restores the previous value
// BEFORE it asserts, so the result does not depend on which areas the harness opened the
// session with.
//
// Written by agent stma-auto2-15, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4795.

page 67531 "PAA Action Card"
{
    PageType = Card;
    SourceTable = "PAA Area Record";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeCtl; Rec."Code")
                {
                    ApplicationArea = Basic;
                }
                field(BasicCtl; Rec."Basic Value")
                {
                    ApplicationArea = Basic;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(BasicAction)
            {
                ApplicationArea = Basic;
                Caption = 'Basic Action';

                trigger OnAction()
                begin
                    Rec."Basic Value" := 'BASIC-RAN';
                    Rec.Modify();
                end;
            }
            action(ServiceAction)
            {
                ApplicationArea = Service;
                Caption = 'Service Action';

                trigger OnAction()
                begin
                    Rec."Service Value" := 'SERVICE-RAN';
                    Rec.Modify();
                end;
            }
            group(Functions)
            {
                Caption = 'Functions';

                action(NestedServiceAction)
                {
                    ApplicationArea = Service;
                    Caption = 'Nested Service Action';

                    trigger OnAction()
                    begin
                        Rec."Service Value" := 'NESTED-RAN';
                        Rec.Modify();
                    end;
                }
            }
        }
    }
}

codeunit 67531 "PAA Area Action Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure MakeRecord(var AreaRec: Record "PAA Area Record")
    begin
        AreaRec.DeleteAll();
        AreaRec.Init();
        AreaRec."Code" := 'PAA';
        AreaRec.Insert();
    end;

    [Test]
    procedure AreaNotEnabled_ActionIsNotFoundAndDoesNotRun()
    var
        AreaRec: Record "PAA Area Record";
        AreaPage: TestPage "PAA Action Card";
        PreviousAreas: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        asserterror AreaPage.ServiceAction.Invoke();
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');

        AreaRec.Get('PAA');
        Assert.AreEqual('', AreaRec."Service Value", 'the removed #Service action must not run its OnAction');
    end;

    [Test]
    procedure AreaNotEnabled_NestedActionIsNotFound()
    var
        AreaRec: Record "PAA Area Record";
        AreaPage: TestPage "PAA Action Card";
        PreviousAreas: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        asserterror AreaPage.NestedServiceAction.Invoke();
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');

        AreaRec.Get('PAA');
        Assert.AreEqual('', AreaRec."Service Value", 'the removed nested #Service action must not run its OnAction');
    end;

    [Test]
    procedure AreaNotEnabled_EnabledActionStillRuns()
    var
        AreaRec: Record "PAA Area Record";
        AreaPage: TestPage "PAA Action Card";
        PreviousAreas: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        AreaPage.BasicAction.Invoke();
        AreaPage.Close();
        ApplicationArea(PreviousAreas);

        AreaRec.Get('PAA');
        Assert.AreEqual('BASIC-RAN', AreaRec."Basic Value", 'the #Basic action must stay on the page and run its OnAction');
    end;

    [Test]
    procedure AreaEnabled_ActionRuns()
    var
        AreaRec: Record "PAA Area Record";
        AreaPage: TestPage "PAA Action Card";
        PreviousAreas: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Service');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        AreaPage.ServiceAction.Invoke();
        AreaPage.Close();
        ApplicationArea(PreviousAreas);

        AreaRec.Get('PAA');
        Assert.AreEqual('SERVICE-RAN', AreaRec."Service Value", 'with #Service enabled the action must be found and run');
    end;

    [Test]
    procedure EmptyAreaString_NestedActionRuns()
    var
        AreaRec: Record "PAA Area Record";
        AreaPage: TestPage "PAA Action Card";
        PreviousAreas: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        AreaPage.NestedServiceAction.Invoke();
        AreaPage.Close();
        ApplicationArea(PreviousAreas);

        AreaRec.Get('PAA');
        Assert.AreEqual('NESTED-RAN', AreaRec."Service Value", 'with every area enabled the nested #Service action must be found and run');
    end;
}
