// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-the-environment
// Scope: in-scope
// Probe: written against a real BC 27.5 service tier and run on BC 29.0.54011.55816; every literal below is what those tiers produced.
//
// "Environment Information" without any test library: IsSaaS Yes, IsOnPrem Yes, IsSandbox Yes, IsProduction No, GetEnvironmentName 'Sandbox' (the bc-linux container is a sandbox).
// Fixtures used: self-contained codeunit 69340 (the OnPrem app has the sandbox / production switch probe)
// BC versions: 27.5, 29.0

codeunit 69340 "PV Environment Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure EnvironmentInformation_Default()
    var
        EnvInfo: Codeunit "Environment Information";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('default_is_saas', Format(EnvInfo.IsSaaS()));
        Observer.Observe('default_is_onprem', Format(EnvInfo.IsOnPrem()));
        Observer.Observe('default_is_sandbox', Format(EnvInfo.IsSandbox()));
        Observer.Observe('default_is_production', Format(EnvInfo.IsProduction()));
        Observer.Observe('default_environment_name', '[' + EnvInfo.GetEnvironmentName() + ']');
        Observer.Expect('default_is_saas', 'Yes');
        Observer.Expect('default_is_onprem', 'Yes');
        Observer.Expect('default_is_sandbox', 'Yes');
        Observer.Expect('default_is_production', 'No');
        Observer.Expect('default_environment_name', '[Sandbox]');
        Observer.Verify();
    end;
}
