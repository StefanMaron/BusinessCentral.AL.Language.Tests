// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/navapp/navapp-listresources-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), resource files session/res/greeting.txt, session/res/sub/nested.txt, session/res/ac-sample.json
// Probe: ModuleInfo.ContextSensitiveHelpUrl, EULA, Help, PrivacyStatement and the NavApp resource overloads that take an AppId: GetResource, GetResourceAsJson, GetResourceAsText, ListResources and ListAppsWithPublicResources (BC 29 and later; BC 27 and 28 reject them, see must-not-compile cases 0964 to 0966). Settles #627 items 5 to 13.
// BC versions: 29

#if BC29PLUS
codeunit 77521 "LT AC ModuleInfo Help"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_ModuleInfo_HelpTexts_CurrentApp()
    var
        Observer: Codeunit "Probe Observer";
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        Observer.Observe('name', Info.Name());
        Observer.Observe('context_help', Info.ContextSensitiveHelpUrl());
        Observer.Observe('eula', Info.EULA());
        Observer.Observe('help', Info.Help());
        Observer.Observe('privacy', Info.PrivacyStatement());
        Observer.Finish();
    end;

    [Test]
    procedure AC_ModuleInfo_HelpTexts_Dependency()
    var
        Observer: Codeunit "Probe Observer";
        Info: ModuleInfo;
    begin
        Observer.Observe('found_sysapp', Format(NavApp.GetModuleInfo('63ca2fa4-4f03-4f2b-a480-172fef340d3f', Info)));
        Observer.Observe('sysapp_name', Info.Name());
        Observer.Observe('sysapp_context_help', Info.ContextSensitiveHelpUrl());
        Observer.Observe('sysapp_eula', Info.EULA());
        Observer.Observe('sysapp_help', Info.Help());
        Observer.Observe('sysapp_privacy', Info.PrivacyStatement());
        Clear(Info);
        Observer.Observe('found_baseapp', Format(NavApp.GetModuleInfo('437dbf0e-84ff-417a-965d-ed2bb9650972', Info)));
        Observer.Observe('baseapp_name', Info.Name());
        Observer.Observe('baseapp_context_help', Info.ContextSensitiveHelpUrl());
        Observer.Observe('baseapp_eula', Info.EULA());
        Observer.Observe('baseapp_help', Info.Help());
        Observer.Observe('baseapp_privacy', Info.PrivacyStatement());
        Clear(Info);
        Observer.Observe('found_fixture', Format(NavApp.GetModuleInfo('f1e2d3c4-b5a6-7890-fedc-ba9876543210', Info)));
        Observer.Observe('fixture_name', Info.Name());
        Observer.Observe('fixture_context_help', Info.ContextSensitiveHelpUrl());
        Observer.Observe('fixture_eula', Info.EULA());
        Observer.Observe('fixture_help', Info.Help());
        Observer.Observe('fixture_privacy', Info.PrivacyStatement());
        Clear(Info);
        Observer.Observe('found_unknown', Format(NavApp.GetModuleInfo('00000000-0000-0000-0000-000000000001', Info)));
        Observer.Observe('unknown_context_help', Info.ContextSensitiveHelpUrl());
        Observer.Observe('unknown_eula', Info.EULA());
        Observer.Observe('unknown_help', Info.Help());
        Observer.Observe('unknown_privacy', Info.PrivacyStatement());
        Observer.Finish();
    end;
}

codeunit 77522 "LT AC NavApp Resources"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_NavApp_GetResource_AppId()
    var
        Observer: Codeunit "Probe Observer";
        Stream: InStream;
        Content: Text;
    begin
        NavApp.GetResource('greeting.txt', GetCurrentAppId(), Stream);
        Stream.ReadText(Content);
        Observer.Observe('default_encoding', Content);
        Clear(Stream);
        NavApp.GetResource('greeting.txt', GetCurrentAppId(), Stream, TextEncoding::UTF8);
        Stream.ReadText(Content);
        Observer.Observe('utf8', Content);
        Clear(Stream);
        NavApp.GetResource('sub/nested.txt', GetCurrentAppId(), Stream, TextEncoding::UTF8);
        Stream.ReadText(Content);
        Observer.Observe('nested', Content);
        Clear(Stream);
        NavApp.GetResource('greeting.txt', GetCurrentAppId(), Stream, TextEncoding::UTF16);
        Stream.ReadText(Content);
        Observer.Observe('utf16', Content);
        Observer.Finish();
    end;

    [Test]
    procedure AC_NavApp_GetResource_AppId_Errors()
    var
        Observer: Codeunit "Probe Observer";
        Stream: InStream;
        Unknown: Guid;
    begin
        Evaluate(Unknown, '00000000-0000-0000-0000-000000000001');
        asserterror NavApp.GetResource('missing.txt', GetCurrentAppId(), Stream);
        Observer.ObserveError('missing_resource');
        asserterror NavApp.GetResource('greeting.txt', Unknown, Stream);
        Observer.ObserveError('unknown_app');
        asserterror NavApp.GetResource('greeting.txt', '63ca2fa4-4f03-4f2b-a480-172fef340d3f', Stream);
        Observer.ObserveError('other_app_not_public');
        asserterror NavApp.GetResource('', GetCurrentAppId(), Stream);
        Observer.ObserveError('empty_name');
        Observer.Finish();
    end;

    [Test]
    procedure AC_NavApp_GetResourceAsJson_AppId()
    var
        Observer: Codeunit "Probe Observer";
        Json: JsonObject;
        Token: JsonToken;
        Unknown: Guid;
    begin
        Json := NavApp.GetResourceAsJson('ac-sample.json', GetCurrentAppId());
        Observer.Observe('content', Format(Json));
        Observer.Observe('name', Format(Json.Get('name', Token)) + '/' + Format(Token));
        Json := NavApp.GetResourceAsJson('ac-sample.json', GetCurrentAppId(), TextEncoding::UTF8);
        Observer.Observe('utf8', Format(Json));
        asserterror Json := NavApp.GetResourceAsJson('greeting.txt', GetCurrentAppId());
        Observer.ObserveError('not_json');
        asserterror Json := NavApp.GetResourceAsJson('missing.json', GetCurrentAppId());
        Observer.ObserveError('missing');
        Evaluate(Unknown, '00000000-0000-0000-0000-000000000001');
        asserterror Json := NavApp.GetResourceAsJson('ac-sample.json', Unknown);
        Observer.ObserveError('unknown_app');
        Observer.Finish();
    end;

    [Test]
    procedure AC_NavApp_GetResourceAsText_AppId()
    var
        Observer: Codeunit "Probe Observer";
        Unknown: Guid;
    begin
        Observer.Observe('default', NavApp.GetResourceAsText('greeting.txt', GetCurrentAppId()));
        Observer.Observe('utf8', NavApp.GetResourceAsText('greeting.txt', GetCurrentAppId(), TextEncoding::UTF8));
        Observer.Observe('utf16', NavApp.GetResourceAsText('greeting.txt', GetCurrentAppId(), TextEncoding::UTF16));
        Observer.Observe('ansi', NavApp.GetResourceAsText('greeting.txt', GetCurrentAppId(), TextEncoding::MSDos));
        Observer.Observe('windows', NavApp.GetResourceAsText('greeting.txt', GetCurrentAppId(), TextEncoding::Windows));
        Observer.Observe('nested', NavApp.GetResourceAsText('sub/nested.txt', GetCurrentAppId()));
        Observer.Observe('json_length', Format(StrLen(NavApp.GetResourceAsText('ac-sample.json', GetCurrentAppId()))));
        Evaluate(Unknown, '00000000-0000-0000-0000-000000000001');
        asserterror Observer.Observe('unused', NavApp.GetResourceAsText('missing.txt', GetCurrentAppId()));
        Observer.ObserveError('missing');
        asserterror Observer.Observe('unused', NavApp.GetResourceAsText('greeting.txt', Unknown));
        Observer.ObserveError('unknown_app');
        Observer.Finish();
    end;

    [Test]
    procedure AC_NavApp_ListResources_AppId()
    var
        Observer: Codeunit "Probe Observer";
        Names: List of [Text];
        Name: Text;
        Joined: Text;
        Unknown: Guid;
    begin
        Names := NavApp.ListResources(GetCurrentAppId());
        
        
        foreach Name in Names do
            Joined += '[' + Name + ']';
        Observer.Observe('all', Joined);
        Observer.Observe('all_count', Format(Names.Count()));
        Clear(Joined);
        Names := NavApp.ListResources(GetCurrentAppId(), '*.txt');
        foreach Name in Names do
            Joined += '[' + Name + ']';
        Observer.Observe('txt', Joined);
        Clear(Joined);
        Names := NavApp.ListResources(GetCurrentAppId(), '*.json');
        foreach Name in Names do
            Joined += '[' + Name + ']';
        Observer.Observe('json', Joined);
        Clear(Joined);
        Names := NavApp.ListResources(GetCurrentAppId(), 'sub/*');
        foreach Name in Names do
            Joined += '[' + Name + ']';
        Observer.Observe('sub', Joined);
        Clear(Joined);
        Names := NavApp.ListResources(GetCurrentAppId(), '*.xyz');
        Observer.Observe('no_match_count', Format(Names.Count()));
        Evaluate(Unknown, '00000000-0000-0000-0000-000000000001');
        if TryList(Unknown, Names) then
            Observer.Observe('unknown_app', Format(Names.Count()))
        else
            Observer.ObserveError('unknown_app');
        if TryList('63ca2fa4-4f03-4f2b-a480-172fef340d3f', Names) then
            Observer.Observe('system_application', Format(Names.Count()))
        else
            Observer.ObserveError('system_application');
        Observer.Finish();
    end;

    [Test]
    procedure AC_NavApp_ListAppsWithPublicResources()
    var
        Observer: Codeunit "Probe Observer";
        Apps: List of [Guid];
        AppId: Guid;
        Joined: Text;
    begin
        Apps := NavApp.ListAppsWithPublicResources();
        foreach AppId in Apps do
            Joined += '[' + Format(AppId) + ']';
        Observer.Observe('all', Joined);
        Observer.Observe('all_count', Format(Apps.Count()));
        Observer.Observe('contains_self', Format(Apps.Contains(GetCurrentAppId())));
        Clear(Joined);
        Apps := NavApp.ListAppsWithPublicResources('*.json');
        foreach AppId in Apps do
            Joined += '[' + Format(AppId) + ']';
        Observer.Observe('json', Joined);
        Clear(Joined);
        Apps := NavApp.ListAppsWithPublicResources('*.xyz');
        foreach AppId in Apps do
            Joined += '[' + Format(AppId) + ']';
        Observer.Observe('xyz', Joined);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryList(AppId: Guid; var Names: List of [Text])
    begin
        Names := NavApp.ListResources(AppId);
    end;

    local procedure GetCurrentAppId(): Guid
    var
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        exit(Info.Id());
    end;
}
#endif
