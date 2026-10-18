// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99001
// Probe: al-runtime-rs corpus topic 203 item 3 (corpus issue 632): NavUserAccountHelper.IsDelegatedUser() from a test session.
// RISKY (compile): the member IsDelegatedUser may not exist on every BC version (Microsoft's System Application called it up to BC 26).
// BC versions: 27, 28, 29
dotnet
{
    assembly("Microsoft.Dynamics.Nav.NavUserAccount")
    {
        type("Microsoft.Dynamics.Nav.NavUserAccount.NavUserAccountHelper"; LtAeUah2) { }
    }
}

codeunit 99001 "LT AE DelegatedUser"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure DotNet_IsDelegatedUser()
    var
        Helper: DotNet LtAeUah2;
    begin
        Observer.Observe('is delegated user', Format(Helper.IsDelegatedUser()));
        Observer.Finish();
    end;
}
