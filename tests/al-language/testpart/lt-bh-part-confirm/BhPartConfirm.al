// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-application
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects below
// Facts: a part page's OnOpenPage calls Confirm and no ConfirmHandler answers it: the host TestPage's OpenView fails with the
// unhandled-UI error of that Confirm (text and code below). The direct call is pinned in misc/lt-probes-needed-3/PnC09UnhandledUi.al.
// BC versions: 27.0 and later

table 81450 "LT BH Confirm Row"
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

page 81450 "LT BH Confirm Part"
{
    PageType = CardPart;
    SourceTable = "LT BH Confirm Row";

    layout
    {
        area(Content)
        {
            field(PartCode; Rec."Code") { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    begin
        if Confirm('LT BH part asks') then;
    end;
}

page 81451 "LT BH Confirm Host"
{
    PageType = Card;
    SourceTable = "LT BH Confirm Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(HostCode; Rec."Code") { ApplicationArea = All; }
            part(ConfirmPart; "LT BH Confirm Part") { ApplicationArea = All; }
        }
    }
}

codeunit 81452 "LT BH Part Confirm Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure HostWithUnhandledConfirmInPart_OpenView_Fails()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT BH Confirm Host";
    begin
        asserterror Host.OpenView();
        Observer.ObserveError('openView');
        Observer.Finish();
    end;
}
