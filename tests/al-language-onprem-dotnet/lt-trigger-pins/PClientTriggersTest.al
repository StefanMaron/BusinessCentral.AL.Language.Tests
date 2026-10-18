// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), see PClientTriggers.al
// Fixtures used: Probe Observer (69160); pages and log of PClientTriggers.al; self-contained codeunit 61486
// BC versions: 27, 28, 29
codeunit 61486 "LT P Client Triggers Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryOpen(PageId: Integer)
    begin
        case PageId of
            61487:
                OpenNotifierTours();
            61488:
                OpenTour();
            61489:
                OpenCamera();
            61490:
                OpenLocation();
            61491:
                OpenNoHandler();
        end;
    end;

    local procedure OpenNotifierTours()
    var
        TestPage: TestPage "LT P Notifier Tours Page";
    begin
        TestPage.OpenView();
        TestPage.Close();
    end;

    local procedure OpenTour()
    var
        TestPage: TestPage "LT P Tour Page";
    begin
        TestPage.OpenView();
        TestPage.Close();
    end;

    local procedure OpenCamera()
    var
        TestPage: TestPage "LT P Camera Page";
    begin
        TestPage.OpenView();
        TestPage.Close();
    end;

    local procedure OpenLocation()
    var
        TestPage: TestPage "LT P Location Page";
    begin
        TestPage.OpenView();
        TestPage.Close();
    end;

    local procedure OpenNoHandler()
    var
        TestPage: TestPage "LT P Client No Handler Page";
    begin
        TestPage.OpenView();
        TestPage.Close();
    end;

    local procedure Probe(PageId: Integer)
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P Client Log";
        Ok: Boolean;
    begin
        Log.Reset();
        ClearLastError();
        Ok := TryOpen(PageId);
        Observer.Observe('open_ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('open_error');
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    procedure PClient_NotifierAndUserTours()
    begin
        Probe(61487);
    end;

    [Test]
    procedure PClient_Tour()
    begin
        Probe(61488);
    end;

    [Test]
    procedure PClient_Camera()
    begin
        Probe(61489);
    end;

    [Test]
    procedure PClient_Location()
    begin
        Probe(61490);
    end;

    [Test]
    procedure PClient_NoHandler()
    begin
        Probe(61491);
    end;
}
