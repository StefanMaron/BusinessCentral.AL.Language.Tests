// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-app-area
// Scope: in-scope
// Fixtures used: Assert (60021), and the table, page and codeunit declared below.
//
// CLAIM: a TestPage field's Value() called as a statement of its own, with the result thrown
// away, is still evaluated. On a control that application areas removed from the page it raises
// the same "is not found on the page." error an assignment from Value() does; on a control that
// is on the page it raises nothing.
//
// Every test sets the session's application areas itself and restores the previous value
// BEFORE it asserts, as TestPageApplicationAreaControlRemoval.al does.
//
// Written by agent stma-auto2-13, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4861.

table 67612 "PDV Area Record"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Basic Value"; Text[30]) { }
        field(3; "Service Value"; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 67612 "PDV Area Card"
{
    PageType = Card;
    SourceTable = "PDV Area Record";

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
                field(ServiceCtl; Rec."Service Value")
                {
                    ApplicationArea = Service;
                }
            }
        }
    }
}

codeunit 67612 "PDV Discarded Value Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure MakeRecord(var AreaRec: Record "PDV Area Record")
    begin
        AreaRec.DeleteAll();
        AreaRec.Init();
        AreaRec."Code" := 'PDV';
        AreaRec."Basic Value" := 'B0';
        AreaRec."Service Value" := 'S0';
        AreaRec.Insert();
    end;

    [Test]
    procedure RemovedControl_DiscardedValueCall_RaisesNotFound()
    var
        AreaRec: Record "PDV Area Record";
        AreaPage: TestPage "PDV Area Card";
        PreviousAreas: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        AreaPage.OpenView();
        AreaPage.GoToRecord(AreaRec);
        asserterror AreaPage.ServiceCtl.Value();
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
    end;

    [Test]
    procedure RemovedControl_ValueAssignedToAVariable_RaisesNotFound()
    var
        AreaRec: Record "PDV Area Record";
        AreaPage: TestPage "PDV Area Card";
        PreviousAreas: Text;
        Shown: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        AreaPage.OpenView();
        AreaPage.GoToRecord(AreaRec);
        asserterror Shown := AreaPage.ServiceCtl.Value();
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
    end;

    [Test]
    procedure FoundControl_DiscardedValueCall_RaisesNothing()
    var
        AreaRec: Record "PDV Area Record";
        AreaPage: TestPage "PDV Area Card";
        PreviousAreas: Text;
        Shown: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        AreaPage.OpenView();
        AreaPage.GoToRecord(AreaRec);
        AreaPage.BasicCtl.Value();
        Shown := AreaPage.BasicCtl.Value();
        AreaPage.Close();
        ApplicationArea(PreviousAreas);

        Assert.AreEqual('B0', Shown, 'the #Basic control must be found and read its field');
    end;
}
