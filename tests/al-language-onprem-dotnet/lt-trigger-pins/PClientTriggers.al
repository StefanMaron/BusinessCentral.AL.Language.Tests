// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer, and an assembly probing path that finds Microsoft.Dynamics.Nav.ClientExtensions
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained pages 61487-61491 and codeunit 61485
// RISKY (compile, runtime): client add-in types on a page run on the client; a test has no client. What a test sees is observed.
//
// The client triggers PageNotifier::PageReady, UserTours::IsTourInProgressResultReady, UserTours::ShowTourWizard, Tour::TourEnded, Tour::SpotlightTourEnded, CameraProvider::PictureAvailable and
// LocationProvider::LocationChanged: whether any of them fires when a test opens the page, and what a page does that declares the variables without handlers.
// BC versions: 27, 28, 29
dotnet
{
    assembly("Microsoft.Dynamics.Nav.ClientExtensions")
    {
        type("Microsoft.Dynamics.Nav.Client.PageNotifier"; LtPPageNotifier) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.UserTours"; LtPUserTours) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.Tour"; LtPTour) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.SpotlightTour"; LtPSpotlightTour) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.CameraProvider"; LtPCameraProvider) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.LocationProvider"; LtPLocationProvider) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.Location"; LtPLocation) { }
    }
}

codeunit 61485 "LT P Client Log"
{
    SingleInstance = true;

    var
        Entries: List of [Text];

    procedure Reset()
    begin
        Clear(Entries);
    end;

    procedure Add(Entry: Text)
    begin
        Entries.Add(Entry);
    end;

    procedure Joined(): Text
    var
        E: Text;
        R: Text;
    begin
        foreach E in Entries do
            R += E + ';';
        exit(R);
    end;
}

page 61487 "LT P Notifier Tours Page"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(G)
            {
                Caption = 'G';
            }
        }
    }

    var
        [RunOnClient]
        [WithEvents]
        UserTours: DotNet LtPUserTours;
        [RunOnClient]
        [WithEvents]
        PageNotifier: DotNet LtPPageNotifier;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P Client Log";
    begin
        Log.Add('open tours available=' + Format(UserTours.IsAvailable()));
    end;

    trigger UserTours::ShowTourWizard(hasTourCompleted: Boolean)
    var
        Log: Codeunit "LT P Client Log";
    begin
        Log.Add('ShowTourWizard ' + Format(hasTourCompleted));
    end;

    trigger UserTours::IsTourInProgressResultReady(isInProgress: Boolean)
    var
        Log: Codeunit "LT P Client Log";
    begin
        Log.Add('IsTourInProgressResultReady ' + Format(isInProgress));
    end;

    trigger PageNotifier::PageReady()
    var
        Log: Codeunit "LT P Client Log";
    begin
        Log.Add('PageReady');
    end;
}

page 61488 "LT P Tour Page"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(G)
            {
                Caption = 'G';
            }
        }
    }

    var
        [RunOnClient]
        [WithEvents]
        Tour: DotNet LtPTour;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P Client Log";
    begin
        Log.Add('open tour available=' + Format(Tour.IsAvailable()));
    end;

    trigger Tour::TourEnded(PageId: Integer; Completed: Boolean; Data: Text)
    var
        Log: Codeunit "LT P Client Log";
    begin
        Log.Add(StrSubstNo('TourEnded %1 %2 %3', PageId, Completed, Data));
    end;

    trigger Tour::SpotlightTourEnded(PageId: Integer; SpotlightTour: DotNet LtPSpotlightTour; Completed: Boolean; Data: Text)
    var
        Log: Codeunit "LT P Client Log";
    begin
        Log.Add(StrSubstNo('SpotlightTourEnded %1 %2 %3', PageId, Completed, Data));
    end;
}

page 61489 "LT P Camera Page"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(G)
            {
                Caption = 'G';
            }
        }
    }

    var
        [RunOnClient]
        [WithEvents]
        CameraProvider: DotNet LtPCameraProvider;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P Client Log";
    begin
        Log.Add('open camera available=' + Format(CameraProvider.IsAvailable()));
    end;

    trigger CameraProvider::PictureAvailable(PictureName: Text; PictureFilePath: Text)
    var
        Log: Codeunit "LT P Client Log";
    begin
        Log.Add('PictureAvailable ' + PictureName);
    end;
}

page 61490 "LT P Location Page"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(G)
            {
                Caption = 'G';
            }
        }
    }

    var
        [RunOnClient]
        [WithEvents]
        LocationProvider: DotNet LtPLocationProvider;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P Client Log";
    begin
        Log.Add('open location available=' + Format(LocationProvider.IsAvailable()));
    end;

    trigger LocationProvider::LocationChanged(NewLocation: DotNet LtPLocation)
    var
        Log: Codeunit "LT P Client Log";
    begin
        Log.Add('LocationChanged');
    end;
}

page 61491 "LT P Client No Handler Page"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(G)
            {
                Caption = 'G';
            }
        }
    }

    var
        [RunOnClient]
        [WithEvents]
        PageNotifier: DotNet LtPPageNotifier;
        [RunOnClient]
        [WithEvents]
        Tour: DotNet LtPTour;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P Client Log";
    begin
        Log.Add('open without handlers');
    end;
}
