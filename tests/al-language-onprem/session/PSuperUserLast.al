// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/user/user-table
// Scope: in-scope (Target = OnPrem: Environment Info Test Library.SetTestabilitySoftwareAsAService has Scope OnPrem)
// Fixtures used: Probe Observer (69160), Environment Info Test Library (System Application Test Library)
// RISKY (data): the test touches the User and Access Control rows of the test user. Both attempts below are expected to fail before anything changes;
// if the platform lets the change through, the test puts the user back. The environment is switched to "SaaS" only for the attempts.
//
// 'There should be at least one enabled 'SUPER' user.': raised when the last user that holds SUPER directly is disabled, or loses the SUPER assignment, while the environment is SaaS.
// BC versions: 27, 28, 29
codeunit 61289 "LT P Super User Last"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryDisable(var User: Record User)
    begin
        User.State := User.State::Disabled;
        User.Modify(true);
    end;

    [TryFunction]
    local procedure TryRemoveSuper(var AccessControl: Record "Access Control")
    begin
        AccessControl.Delete(true);
    end;

    local procedure DistinctSuperUsers(): Integer
    var
        AccessControl: Record "Access Control";
        Seen: List of [Guid];
    begin
        AccessControl.SetRange("Role ID", 'SUPER');
        AccessControl.SetRange(Scope, AccessControl.Scope::System);
        AccessControl.SetFilter("Company Name", '''''');
        if AccessControl.FindSet() then
            repeat
                if not Seen.Contains(AccessControl."User Security ID") then
                    Seen.Add(AccessControl."User Security ID");
            until AccessControl.Next() = 0;
        exit(Seen.Count());
    end;

    [Test]
    procedure PSuperUser_DisableLastSuper()
    var
        Observer: Codeunit "Probe Observer";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        User: Record User;
        Ok: Boolean;
    begin
        Observer.Observe('super_users', Format(DistinctSuperUsers()));
        Observer.Observe('user_found', Format(User.Get(UserSecurityId())));
        if User.Get(UserSecurityId()) and (DistinctSuperUsers() = 1) then begin
            EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
            ClearLastError();
            Ok := TryDisable(User);
            EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
            Observer.Observe('disable_ok', Format(Ok));
            if not Ok then
                Observer.ObserveError('disable_error')
            else begin
                User.State := User.State::Enabled;
                User.Modify(true);
            end;
            Observer.Observe('state_after', Format(User.State));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure PSuperUser_RemoveLastSuperAssignment()
    var
        Observer: Codeunit "Probe Observer";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        AccessControl: Record "Access Control";
        Ok: Boolean;
    begin
        AccessControl.SetRange("User Security ID", UserSecurityId());
        AccessControl.SetRange("Role ID", 'SUPER');
        AccessControl.SetRange(Scope, AccessControl.Scope::System);
        AccessControl.SetFilter("Company Name", '''''');
        Observer.Observe('assignment_found', Format(AccessControl.FindFirst()));
        if AccessControl.FindFirst() and (DistinctSuperUsers() = 1) then begin
            EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
            ClearLastError();
            Ok := TryRemoveSuper(AccessControl);
            EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
            Observer.Observe('remove_ok', Format(Ok));
            if not Ok then
                Observer.ObserveError('remove_error');
            Observer.Observe('assignment_after', Format(AccessControl.FindFirst()));
        end;
        Observer.Finish();
    end;
}
