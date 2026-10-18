// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99000
// Probe: al-runtime-rs corpus topic 203 item 3 (corpus issue 632): the delegated-user members of the DotNet class Microsoft.Dynamics.Nav.NavUserAccount.NavUserAccountHelper
//   (IsUserDelegatedAdmin, IsUserDelegatedHelpdesk) and the System Application codeunit "Azure AD Graph User" that wraps them, called from a test session.
//   The older member IsDelegatedUser() is in AeDelegatedUser.al, a file of its own because a member the class lacks fails the compile of its file.
// BC versions: 27, 28, 29
dotnet
{
    assembly("Microsoft.Dynamics.Nav.NavUserAccount")
    {
        type("Microsoft.Dynamics.Nav.NavUserAccount.NavUserAccountHelper"; LtAeUah) { }
    }
}

codeunit 99000 "LT AE UserAccountHelper"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure DotNet_IsUserDelegatedAdmin_And_Helpdesk()
    var
        Helper: DotNet LtAeUah;
    begin
        Observer.Observe('is delegated admin', Format(Helper.IsUserDelegatedAdmin()));
        Observer.Observe('is delegated helpdesk', Format(Helper.IsUserDelegatedHelpdesk()));
        Observer.Finish();
    end;

    [Test]
    procedure Codeunit_AzureADGraphUser_Delegated()
    var
        GraphUser: Codeunit "Azure AD Graph User";
    begin
        Observer.Observe('graph delegated admin', Format(GraphUser.IsUserDelegatedAdmin()));
        Observer.Observe('graph delegated helpdesk', Format(GraphUser.IsUserDelegatedHelpdesk()));
        Observer.Finish();
    end;
}
