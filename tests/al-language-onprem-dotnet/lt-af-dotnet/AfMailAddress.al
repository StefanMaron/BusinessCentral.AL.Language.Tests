// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.net.mail.mailaddress
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99050
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: DotNet System.Net.Mail.MailAddress: the constructor with a valid address, with a display name form, with the two-argument form, and with invalid text
// (error text and code); the properties Address, DisplayName, User and Host.
// BC versions: 27, 28, 29
dotnet
{
    assembly("System")
    {
        type("System.Net.Mail.MailAddress"; LtAfMailAddress) { }
    }
}

codeunit 99050 "LT AF MailAddress"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryCreate(Text: Text; var Addr: DotNet LtAfMailAddress)
    begin
        Addr := Addr.MailAddress(Text);
    end;

    [TryFunction]
    local procedure TryCreateWithName(Text: Text; DisplayName: Text; var Addr: DotNet LtAfMailAddress)
    begin
        Addr := Addr.MailAddress(Text, DisplayName);
    end;

    local procedure Describe(Name: Text; Input: Text)
    var
        Observer: Codeunit "Probe Observer";
        Addr: DotNet LtAfMailAddress;
    begin
        ClearLastError();
        if TryCreate(Input, Addr) then begin
            Observer.Observe(Name + '|address', Addr.Address);
            Observer.Observe(Name + '|displayname', Addr.DisplayName);
            Observer.Observe(Name + '|user', Addr.User);
            Observer.Observe(Name + '|host', Addr.Host);
            Observer.Observe(Name + '|tostring', Addr.ToString());
        end else
            Observer.ObserveError(Name);
        Observer.Finish();
    end;

    [Test]
    procedure AF_MailAddress_Valid()
    begin
        Describe('valid', 'john.doe@example.com');
    end;

    [Test]
    procedure AF_MailAddress_WithDisplayName()
    begin
        Describe('display name', 'John Doe <john.doe@example.com>');
    end;

    [Test]
    procedure AF_MailAddress_Invalid_NoAt()
    begin
        Describe('invalid no at', 'not-an-address');
    end;

    [Test]
    procedure AF_MailAddress_Invalid_Empty()
    begin
        Describe('invalid empty', '');
    end;

    [Test]
    procedure AF_MailAddress_Invalid_TwoAt()
    begin
        Describe('invalid two at', 'a@b@c.com');
    end;

    [Test]
    procedure AF_MailAddress_TwoArguments()
    var
        Observer: Codeunit "Probe Observer";
        Addr: DotNet LtAfMailAddress;
    begin
        ClearLastError();
        if TryCreateWithName('jane@example.org', 'Jane', Addr) then begin
            Observer.Observe('two args|address', Addr.Address);
            Observer.Observe('two args|displayname', Addr.DisplayName);
            Observer.Observe('two args|user', Addr.User);
            Observer.Observe('two args|host', Addr.Host);
        end else
            Observer.ObserveError('two args');
        Observer.Finish();
    end;
}
