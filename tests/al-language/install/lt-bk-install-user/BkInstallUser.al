// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
// Scope: in-scope
// Fixtures used: LT BK Install User Obs (81750), LT BK Install User Recorder (81750), Probe Observer (69160)
// Probe (corpus #376): who the session user is inside OnInstallAppPerDatabase and OnInstallAppPerCompany, and at test time.
codeunit 81751 "LT BK Install User"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Describe(var Observer: Codeunit "Probe Observer"; Name: Text; var Obs: Record "LT BK Install User Obs")
    begin
        Observer.Observe(Name + '|user id', Obs."User Id");
        Observer.Observe(Name + '|sec id null', Format(Obs."Sec Id Is Null"));
        Observer.Observe(Name + '|user row', Format(Obs."User Row Found"));
        Observer.Observe(Name + '|user row name', Obs."User Row Name");
        Observer.Observe(Name + '|is super', Format(Obs."Is Super"));
        Observer.Observe(Name + '|access control rows', Format(Obs."Access Control Rows"));
        Observer.Observe(Name + '|super rows', Format(Obs."Super Rows"));
        Observer.Observe(Name + '|client type', Obs."Client Type");
        Observer.Observe(Name + '|exec ctx', Obs."Exec Ctx");
        Observer.Observe(Name + '|user table rows', Format(Obs."User Table Rows"));
        Observer.Observe(Name + '|error', Obs."Error Text");
    end;

    [Test]
    procedure BK_InstallUser_PerDatabase()
    var
        Observer: Codeunit "Probe Observer";
        Obs: Record "LT BK Install User Obs";
    begin
        Observer.Observe('found', Format(Obs.Get('DATABASE', '')));
        Describe(Observer, 'db', Obs);
        Observer.Finish();
    end;

    [Test]
    procedure BK_InstallUser_PerCompany()
    var
        Observer: Codeunit "Probe Observer";
        Obs: Record "LT BK Install User Obs";
    begin
        Observer.Observe('found', Format(Obs.Get('COMPANY', CompanyName())));
        Describe(Observer, 'company', Obs);
        Observer.Finish();
    end;

    [Test]
    procedure BK_InstallUser_TestTime()
    var
        Observer: Codeunit "Probe Observer";
        LtBkUser: Record User;
        LtBkAccessControl: Record "Access Control";
        UserPermissions: Codeunit "User Permissions";
    begin
        Observer.Observe('user id', UserId());
        Observer.Observe('sec id null', Format(IsNullGuid(UserSecurityId())));
        Observer.Observe('user row', Format(LtBkUser.Get(UserSecurityId())));
        Observer.Observe('user row name', LtBkUser."User Name");
        Observer.Observe('is super', Format(UserPermissions.IsSuper(UserSecurityId())));
        LtBkAccessControl.SetRange("User Security ID", UserSecurityId());
        Observer.Observe('access control rows', Format(LtBkAccessControl.Count()));
        LtBkAccessControl.SetRange("Role ID", 'SUPER');
        Observer.Observe('super rows', Format(LtBkAccessControl.Count()));
        Observer.Observe('client type', Format(CurrentClientType()));
        LtBkUser.Reset();
        Observer.Observe('user table rows', Format(LtBkUser.Count()));
        Observer.Finish();
    end;
}
