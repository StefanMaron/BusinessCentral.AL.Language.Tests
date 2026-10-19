// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
// Scope: in-scope
// Fixtures used: LT BK Install User Obs (81750)
//
// Records who the session user is while this app installs (corpus #376). An install trigger
// that raises breaks the publish of the whole app, so every read that could fail runs in a
// TryFunction and the insert is guarded.
codeunit 81750 "LT BK Install User Recorder"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    begin
        Recordit('DATABASE', '');
    end;

    trigger OnInstallAppPerCompany()
    begin
        Recordit('COMPANY', CompanyName());
    end;

    local procedure Recordit(TriggerName: Code[20]; Comp: Text)
    var
        Obs: Record "LT BK Install User Obs";
    begin
        Obs.Init();
        Obs."Trigger" := TriggerName;
        Obs."Company" := CopyStr(Comp, 1, MaxStrLen(Obs."Company"));
        if not TryFill(Obs) then
            Obs."Error Text" := CopyStr(GetLastErrorText(), 1, MaxStrLen(Obs."Error Text"));
        ClearLastError();
        if not Obs.Insert() then
            if Obs.Modify() then;
    end;

    [TryFunction]
    local procedure TryFill(var Obs: Record "LT BK Install User Obs")
    var
        LtBkUser: Record User;
        LtBkAccessControl: Record "Access Control";
        UserPermissions: Codeunit "User Permissions";
    begin
        Obs."User Id" := CopyStr(UserId(), 1, MaxStrLen(Obs."User Id"));
        Obs."Sec Id Is Null" := IsNullGuid(UserSecurityId());
        Obs."Client Type" := CopyStr(Format(CurrentClientType()), 1, MaxStrLen(Obs."Client Type"));
        Obs."Exec Ctx" := CopyStr(Format(Session.GetExecutionContext()), 1, MaxStrLen(Obs."Exec Ctx"));
        Obs."User Table Rows" := LtBkUser.Count();
        Obs."User Row Found" := LtBkUser.Get(UserSecurityId());
        if Obs."User Row Found" then
            Obs."User Row Name" := LtBkUser."User Name";
        LtBkAccessControl.SetRange("User Security ID", UserSecurityId());
        Obs."Access Control Rows" := LtBkAccessControl.Count();
        LtBkAccessControl.SetRange("Role ID", 'SUPER');
        Obs."Super Rows" := LtBkAccessControl.Count();
        Obs."Is Super" := UserPermissions.IsSuper(UserSecurityId());
    end;
}
