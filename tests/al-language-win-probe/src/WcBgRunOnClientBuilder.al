// Windows check copy of corpus codeunit 61492 "LT AC Dn RunOnClient" (tests/al-language-onprem-dotnet/lt-ac/AcDnAttributes.al), observe form.
dotnet
{
    assembly("mscorlib")
    {
        type("System.Text.StringBuilder"; WcBgBuilder) { }
    }
}

codeunit 81360 "WC BG RunOnClient Builder"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        [RunOnClient]
        ClientBuilder: DotNet WcBgBuilder;

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
