// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-the-environment
// Scope: in-scope (OnPrem app: the "Environment Info Test Library" procedures are Scope = OnPrem)
// Fixtures used: Probe Observer (69160); self-contained codeunit 61293
// Probe: written against a real BC 27.5 service tier and run on BC 29.0.54011.55816 (the bc-linux container is a sandbox environment); every literal below is what they produced.
//
// What "Environment Information" answers: IsSaaS Yes, IsSandbox Yes, IsProduction No, GetEnvironmentName "Sandbox" (IsOnPrem is Yes as well, because the service tier is not Azure infrastructure).
// The test library's SetTestabilitySandbox(true / false) and SetTestabilitySoftwareAsAService(true / false) change NOTHING a test can see on this tier: after SetTestabilitySandbox(false) the
// session still reads IsSandbox Yes, IsProduction No and the name "Sandbox"; after SetTestabilitySoftwareAsAService(false) IsSaaS stays Yes.
// BC versions: 27.5, 29.0
codeunit 61293 "PV Environment Testability"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure EnvironmentInformation_SandboxAndProduction_ThroughTheTestLibrary()
    var
        EnvInfo: Codeunit "Environment Information";
        EnvTestLib: Codeunit "Environment Info Test Library";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('default_is_saas', Format(EnvInfo.IsSaaS()));
        Observer.Observe('default_is_sandbox', Format(EnvInfo.IsSandbox()));
        Observer.Observe('default_is_production', Format(EnvInfo.IsProduction()));
        EnvTestLib.SetTestabilitySoftwareAsAService(true);
        EnvTestLib.SetTestabilitySandbox(true);
        Observer.Observe('sandbox_is_saas', Format(EnvInfo.IsSaaS()));
        Observer.Observe('sandbox_is_onprem', Format(EnvInfo.IsOnPrem()));
        Observer.Observe('sandbox_is_sandbox', Format(EnvInfo.IsSandbox()));
        Observer.Observe('sandbox_is_production', Format(EnvInfo.IsProduction()));
        Observer.Observe('sandbox_environment_name', '[' + EnvInfo.GetEnvironmentName() + ']');
        EnvTestLib.SetTestabilitySandbox(false);
        Observer.Observe('production_is_sandbox', Format(EnvInfo.IsSandbox()));
        Observer.Observe('production_is_production', Format(EnvInfo.IsProduction()));
        Observer.Observe('production_environment_name', '[' + EnvInfo.GetEnvironmentName() + ']');
        EnvTestLib.SetTestabilitySoftwareAsAService(false);
        Observer.Observe('after_reset_is_saas', Format(EnvInfo.IsSaaS()));
        Observer.Observe('after_reset_is_sandbox', Format(EnvInfo.IsSandbox()));
        Observer.Observe('after_reset_is_production', Format(EnvInfo.IsProduction()));
        Observer.Expect('default_is_saas', 'Yes');
        Observer.Expect('default_is_sandbox', 'Yes');
        Observer.Expect('default_is_production', 'No');
        Observer.Expect('sandbox_is_saas', 'Yes');
        Observer.Expect('sandbox_is_onprem', 'Yes');
        Observer.Expect('sandbox_is_sandbox', 'Yes');
        Observer.Expect('sandbox_is_production', 'No');
        Observer.Expect('sandbox_environment_name', '[Sandbox]');
        Observer.Expect('production_is_sandbox', 'Yes');
        Observer.Expect('production_is_production', 'No');
        Observer.Expect('production_environment_name', '[Sandbox]');
        Observer.Expect('after_reset_is_saas', 'Yes');
        Observer.Expect('after_reset_is_sandbox', 'Yes');
        Observer.Expect('after_reset_is_production', 'No');
        Observer.Verify();
    end;
}
