// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99250
// Probe (corpus #3): DotNet types from the System.Security.Principal.Windows assembly, declared the way Microsoft's
// Tests-TestLibraries dotnet.al declares them: WindowsIdentity (static GetCurrent, instance Name, User) and
// SecurityIdentifier (constructor from a SID string, Value, ToString, BinaryLength, IsAccountSid).
dotnet
{
    assembly("System.Security.Principal.Windows")
    {
        type("System.Security.Principal.WindowsIdentity"; LtBkWindowsIdentity) { }
        type("System.Security.Principal.SecurityIdentifier"; LtBkSecurityIdentifier) { }
    }
}

codeunit 99250 "LT BK Windows Principal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryGetCurrent(var Identity: DotNet LtBkWindowsIdentity)
    begin
        Identity := Identity.GetCurrent();
    end;

    [TryFunction]
    local procedure TryNewSid(SidText: Text; var Sid: DotNet LtBkSecurityIdentifier)
    begin
        Sid := Sid.SecurityIdentifier(SidText);
    end;

    [TryFunction]
    local procedure TryDescribeSid(var Observer: Codeunit "Probe Observer"; Name: Text; var Sid: DotNet LtBkSecurityIdentifier)
    begin
        Observer.Observe(Name + '|value', Sid.Value);
        Observer.Observe(Name + '|tostring', Sid.ToString());
        Observer.Observe(Name + '|binarylength', Format(Sid.BinaryLength));
        Observer.Observe(Name + '|isaccountsid', Format(Sid.IsAccountSid()));
    end;

    [TryFunction]
    local procedure TryIdentityName(var Identity: DotNet LtBkWindowsIdentity; var Name: Text)
    begin
        Name := Identity.Name;
    end;

    [TryFunction]
    local procedure TryIdentityUser(var Identity: DotNet LtBkWindowsIdentity; var Sid: DotNet LtBkSecurityIdentifier)
    begin
        Sid := Identity.User;
    end;

    [Test]
    procedure BK_WindowsPrincipal_Declare()
    var
        Observer: Codeunit "Probe Observer";
        Identity: DotNet LtBkWindowsIdentity;
        Sid: DotNet LtBkSecurityIdentifier;
    begin
        Observer.Observe('identity isnull', Format(IsNull(Identity)));
        Observer.Observe('sid isnull', Format(IsNull(Sid)));
        Observer.Finish();
    end;

    [Test]
    procedure BK_WindowsPrincipal_SidFromText()
    var
        Observer: Codeunit "Probe Observer";
        Sid: DotNet LtBkSecurityIdentifier;
    begin
        ClearLastError();
        if TryNewSid('S-1-5-32-544', Sid) then begin
            Observer.Observe('admins|isnull', Format(IsNull(Sid)));
            if not TryDescribeSid(Observer, 'admins', Sid) then
                Observer.ObserveError('admins|describe');
        end else
            Observer.ObserveError('admins');
        ClearLastError();
        if TryNewSid('not a sid', Sid) then
            Observer.Observe('bad', 'no error')
        else
            Observer.ObserveError('bad');
        Observer.Finish();
    end;

    [Test]
    procedure BK_WindowsPrincipal_GetCurrent()
    var
        Observer: Codeunit "Probe Observer";
        Identity: DotNet LtBkWindowsIdentity;
        Sid: DotNet LtBkSecurityIdentifier;
        Name: Text;
    begin
        ClearLastError();
        if TryGetCurrent(Identity) then begin
            Observer.Observe('getcurrent|isnull', Format(IsNull(Identity)));
            if TryIdentityName(Identity, Name) then
                Observer.Observe('name|empty', Format(Name = ''))
            else
                Observer.ObserveError('name');
            if TryIdentityUser(Identity, Sid) then
                Observer.Observe('user|isnull', Format(IsNull(Sid)))
            else
                Observer.ObserveError('user');
        end else
            Observer.ObserveError('getcurrent');
        Observer.Finish();
    end;
}
