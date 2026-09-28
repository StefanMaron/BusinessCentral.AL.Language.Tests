// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-application
// Scope: in-scope
// Fixtures used: Assert (60021), and the objects declared below.
//
// QUESTION: a part page's OnOpenPage calls Confirm, and no ConfirmHandler answers it. Opening the
// host page through a TestPage: does OpenView fail with "Unhandled UI: Confirm", or does the
// host open with nothing raised?
//
// CLAIM asserted here: OpenView fails with "Unhandled UI: Confirm". The Linux-tier run of this arm
// (corpus run 36362987733, as part of #488) passed it on BC 27.0/27.3/27.5 and failed it on
// BC 28.0-28.5, where the host opened and nothing was raised. The Windows nightly adjudicates
// which BC 28 behaviour is real.
//
// Written by agent stma-auto2-4, an automated implementation agent acting on the account holder's
// behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4903.

table 67020 "PCF Row"
{
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Code"; Code[20]) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 67020 "PCF Confirm Part"
{
    PageType = CardPart;
    SourceTable = "PCF Row";

    layout
    {
        area(Content)
        {
            field(PartCode; Rec."Code") { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    begin
        if Confirm('PCF part asks') then;
    end;
}

page 67021 "PCF Confirm Host"
{
    PageType = Card;
    SourceTable = "PCF Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(HostCode; Rec."Code") { ApplicationArea = All; }
            part(ConfirmPart; "PCF Confirm Part") { ApplicationArea = All; }
        }
    }
}

codeunit 67020 "PCF Part Confirm Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure HostWithUnhandledConfirmInPart_OpenView_Fails()
    var
        Host: TestPage "PCF Confirm Host";
    begin
        asserterror Host.OpenView();
        Assert.ExpectedError('Unhandled UI: Confirm');
    end;
}
