// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability-overview
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunits 61490 to 61492 (the ids of this app are exhausted below 61490)
// Probe: the OnPrem-only variable attributes. WithEvents on a DotNet variable (a trigger Variable::Event runs when the object raises the event; System.ComponentModel.Component.Disposed is raised synchronously by Dispose()), SuppressDispose on a local DotNet variable (the object is not disposed at the end of the procedure) and RunOnClient on a global DotNet variable. Settles #629 items 11, 15 and 18 (WithEvents on a type without events: must-not-compile case 0992).
// BC versions: 27, 28, 29

dotnet
{
    assembly("mscorlib")
    {
        type("System.EventArgs"; AcEventArgs) { }
        type("System.Text.StringBuilder"; AcBuilder) { }
    }
    assembly("System")
    {
        type("System.Timers.Timer"; AcTimer) { }
    }
}

codeunit 61490 "LT AC Dn WithEvents"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        [WithEvents]
        Timer: DotNet AcTimer;
        Disposed: Integer;
        LastSender: Text;

    trigger Timer::Disposed(sender: Variant; e: DotNet AcEventArgs)
    begin
        Disposed += 1;
        LastSender := Format(sender);
    end;

    [Test]
    procedure AC_DnWithEvents_DisposedEvent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Timer := Timer.Timer();
        Observer.Observe('before_dispose', Format(Disposed));
        Timer.Dispose();
        Observer.Observe('after_dispose', Format(Disposed));
        Observer.Observe('sender_is_timer', Format(LastSender = Format(Timer)));
        Timer.Dispose();
        Observer.Observe('after_second_dispose', Format(Disposed));
        Observer.Finish();
    end;
}

codeunit 61491 "LT AC Dn SuppressDispose"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        [WithEvents]
        Kept: DotNet AcTimer;
        Disposed: Integer;

    trigger Kept::Disposed(sender: Variant; e: DotNet AcEventArgs)
    begin
        Disposed += 1;
    end;

    [Test]
    procedure AC_DnSuppressDispose_LocalVariable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clear(Disposed);
        WithDefaultDispose();
        Observer.Observe('default_disposed_at_scope_end', Format(Disposed));
        Clear(Disposed);
        WithSuppressedDispose();
        Observer.Observe('suppressed_disposed_at_scope_end', Format(Disposed));
        Observer.Finish();
    end;

    local procedure WithDefaultDispose()
    var
        Scoped: DotNet AcTimer;
    begin
        Scoped := Scoped.Timer();
        Kept := Scoped;
    end;

    local procedure WithSuppressedDispose()
    var
        [SuppressDispose]
        Scoped: DotNet AcTimer;
    begin
        Scoped := Scoped.Timer();
        Kept := Scoped;
    end;
}

codeunit 61492 "LT AC Dn RunOnClient"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        [RunOnClient]
        ClientBuilder: DotNet AcBuilder;

    [Test]
    procedure AC_DnRunOnClient_GlobalVariable()
    var
        Observer: Codeunit "Probe Observer";
        Text1: Text;
    begin
        if TryBuild(Text1) then
            Observer.Observe('built', Text1)
        else
            Observer.ObserveError('built');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryBuild(var Result: Text)
    begin
        ClientBuilder := ClientBuilder.StringBuilder();
        ClientBuilder.Append('client');
        Result := ClientBuilder.ToString();
    end;
}
