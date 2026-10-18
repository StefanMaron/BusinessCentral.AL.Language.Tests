// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), see PClientTriggers.al
// Fixtures used: Probe Observer (69160); pages and log of PClientTriggers.al; self-contained codeunit 99131
// BC versions: 27, 28, 29
codeunit 99131 "LT AL Client Triggers Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryOpen(PageId: Integer)
    begin
        case PageId of
            99132:
                OpenNotifierTours();
            99133:
                OpenTour();
            99134:
                OpenCamera();
            99135:
                OpenLocation();
            99136:
                OpenNoHandler();
        end;
    end;

    local procedure OpenNotifierTours()
    var
        TestPage: TestPage "LT AL Notifier Tours Page";
    begin
        TestPage.OpenView();
        TestPage.Close();
    end;

    local procedure OpenTour()
    var
        TestPage: TestPage "LT AL Tour Page";
    begin
        TestPage.OpenView();
        TestPage.Close();
    end;

    local procedure OpenCamera()
    var
        TestPage: TestPage "LT AL Camera Page";
    begin
        TestPage.OpenView();
        TestPage.Close();
    end;

    local procedure OpenLocation()
    var
        TestPage: TestPage "LT AL Location Page";
    begin
        TestPage.OpenView();
        TestPage.Close();
    end;

    local procedure OpenNoHandler()
    var
        TestPage: TestPage "LT AL Client No Handler Page";
    begin
        TestPage.OpenView();
        TestPage.Close();
    end;

    local procedure Probe(PageId: Integer; Refused: Boolean)
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AL Client Log";
        Ok: Boolean;
    begin
        Log.Reset();
        ClearLastError();
        Ok := TryOpen(PageId);
        Observer.Observe('open_ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('open_error');
        Observer.Observe('log', Log.Joined());
        if Refused then begin
            Observer.Expect('open_ok', 'No');
            Observer.Expect('open_error|text', 'A call to IsAvailable failed with this message: Object reference not set to an instance of an object.');
            Observer.Expect('open_error|code', 'DotNetInvoke:NullReference');
            Observer.Expect('log', '');
        end else begin
            Observer.Expect('open_ok', 'Yes');
            Observer.Expect('log', 'open without handlers;');
        end;
        Observer.Verify();
    end;

    [Test]
    procedure ALClient_NotifierAndUserTours()
    begin
        Probe(99132, true);
    end;

    [Test]
    procedure ALClient_Tour()
    begin
        Probe(99133, true);
    end;

    [Test]
    procedure ALClient_Camera()
    begin
        Probe(99134, true);
    end;

    [Test]
    procedure ALClient_Location()
    begin
        Probe(99135, true);
    end;

    [Test]
    procedure ALClient_NoHandler()
    begin
        Probe(99136, false);
    end;
}
