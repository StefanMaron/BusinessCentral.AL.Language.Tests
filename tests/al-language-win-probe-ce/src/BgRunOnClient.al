// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer, and an assembly probing path that finds Microsoft.Dynamics.Nav.ClientExtensions
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99490
// Probe: RunOnClient DotNet in a test session. The static IsAvailable() of the client feature types (camera, location, barcode scanners, device contacts, user tours, page notifier) and a RunOnClient
// variable of a type that is not a client feature (System.Text.StringBuilder: its constructor and a static call). Before MsDyn365Bc.On.Linux PR #130 the Linux test runner answered these calls with a null
// handle (BC 27.5: an uncatchable NullReferenceException; BC 28+: "A call to IsAvailable failed ... Object reference not set to an instance of an object.").
// BC versions: 27, 28, 29
dotnet
{
    assembly("Microsoft.Dynamics.Nav.ClientExtensions")
    {
        type("Microsoft.Dynamics.Nav.Client.Capabilities.CameraProvider"; LtBgCameraProvider) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.LocationProvider"; LtBgLocationProvider) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.BarcodeScannerProvider"; LtBgBarcodeScannerProvider) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.CameraBarcodeScannerProvider"; LtBgCameraBarcodeScannerProvider) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.DeviceContactProvider"; LtBgDeviceContactProvider) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.UserTours"; LtBgUserTours) { }
        type("Microsoft.Dynamics.Nav.Client.PageNotifier"; LtBgPageNotifier) { }
    }
    assembly("mscorlib")
    {
        type("System.Text.StringBuilder"; LtBgStringBuilder) { }
        type("System.Environment"; LtBgEnvironment) { }
    }
}

codeunit 99490 "LT BG RunOnClient"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        [RunOnClient]
        Camera: DotNet LtBgCameraProvider;
        [RunOnClient]
        Location: DotNet LtBgLocationProvider;
        [RunOnClient]
        Barcode: DotNet LtBgBarcodeScannerProvider;
        [RunOnClient]
        CameraBarcode: DotNet LtBgCameraBarcodeScannerProvider;
        [RunOnClient]
        Contacts: DotNet LtBgDeviceContactProvider;
        [RunOnClient]
        Tours: DotNet LtBgUserTours;
        [RunOnClient]
        Notifier: DotNet LtBgPageNotifier;
        [RunOnClient]
        Builder: DotNet LtBgStringBuilder;
        [RunOnClient]
        Env: DotNet LtBgEnvironment;

    [TryFunction]
    local procedure TryAvailable(Kind: Integer; var R: Boolean)
    begin
        case Kind of
            1:
                R := Camera.IsAvailable();
            2:
                R := Location.IsAvailable();
            3:
                R := Barcode.IsAvailable();
            4:
                R := CameraBarcode.IsAvailable();
            5:
                R := Contacts.IsAvailable();
            6:
                R := Tours.IsAvailable();
            7:
                R := Notifier.IsAvailable();
        end;
    end;

    local procedure AvailableCase(var Observer: Codeunit "Probe Observer"; Name: Text; Kind: Integer)
    var
        R: Boolean;
    begin
        R := true;
        if TryAvailable(Kind, R) then
            Observer.Observe(Name, 'ok ret=' + Format(R))
        else
            Observer.ObserveError(Name);
    end;

    [TryFunction]
    local procedure TryBuild(var Result: Text)
    begin
        Builder := Builder.StringBuilder();
        Builder.Append('client');
        Result := Builder.ToString();
    end;

    [TryFunction]
    local procedure TryMachineName(var Result: Text)
    begin
        Result := Env.MachineName();
    end;

    [Test]
    procedure BG_RunOnClient_ClientFeatures_IsAvailable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AvailableCase(Observer, 'camera', 1);
        AvailableCase(Observer, 'location', 2);
        AvailableCase(Observer, 'barcode scanner', 3);
        AvailableCase(Observer, 'camera barcode scanner', 4);
        AvailableCase(Observer, 'device contacts', 5);
        AvailableCase(Observer, 'user tours', 6);
        AvailableCase(Observer, 'page notifier', 7);
        Observer.Finish();
    end;

    [Test]
    procedure BG_RunOnClient_OtherType_Constructor()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        Result := 'untouched';
        if TryBuild(Result) then
            Observer.Observe('stringbuilder', 'ok [' + Result + ']')
        else
            Observer.ObserveError('stringbuilder');
        Observer.Finish();
    end;

    [Test]
    procedure BG_RunOnClient_OtherType_StaticCall()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        Result := 'untouched';
        if TryMachineName(Result) then
            Observer.Observe('machinename', 'ok nonempty=' + Format(Result <> ''))
        else
            Observer.ObserveError('machinename');
        Observer.Finish();
    end;
}
