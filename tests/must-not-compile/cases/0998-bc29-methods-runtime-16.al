// @expect AL0666 | 'IsDirty' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @expect AL0666 | 'Get' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @expect AL0666 | 'Get' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @expect AL0666 | 'Get' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @expect AL0666 | 'Get' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @expect AL0666 | 'ContextSensitiveHelpUrl' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @expect AL0666 | 'EULA' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @expect AL0666 | 'Help' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @expect AL0666 | 'PrivacyStatement' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @expect AL0666 | 'GetResource' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @expect AL0666 | 'GetResourceAsJson' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @expect AL0666 | 'GetResourceAsText' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @expect AL0666 | 'ListResources' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @expect AL0666 | 'ListAppsWithPublicResources' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @from 29
// The BC 29 methods Record.IsDirty, IsolatedStorage.Get with an IsolationLevel, ModuleInfo.ContextSensitiveHelpUrl, EULA, Help, PrivacyStatement and the NavApp resource methods need runtime 18.0. The corpus app compiles at runtime 16.0, so no corpus test can call them on BC 29 (cases 0960 to 0966 give the BC 27 and 28 verdict).
table 59150 "MNC Bc29 Row 0998"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { } }
}

codeunit 59151 "MNC Bc29 Methods 0998"
{
    procedure Run1()
    var
        Row: Record "MNC Bc29 Row 0998";
        Info: ModuleInfo;
        Stream: InStream;
        Json: JsonObject;
        Names: List of [Text];
        Apps: List of [Guid];
        Value: Text;
        Secret: SecretText;
        AppId: Guid;
        Flag: Boolean;
    begin
        Flag := Row.IsDirty();
        Flag := IsolatedStorage.Get('k', DataScope::Module, IsolationLevel::ReadCommitted, Value);
        Flag := IsolatedStorage.Get('k', DataScope::Module, IsolationLevel::ReadCommitted, Secret);
        Flag := IsolatedStorage.Get('k', IsolationLevel::ReadCommitted, Value);
        Flag := IsolatedStorage.Get('k', IsolationLevel::ReadCommitted, Secret);
        Value := Info.ContextSensitiveHelpUrl();
        Value := Info.EULA();
        Value := Info.Help();
        Value := Info.PrivacyStatement();
        NavApp.GetResource('a.txt', AppId, Stream);
        Json := NavApp.GetResourceAsJson('a.json', AppId);
        Value := NavApp.GetResourceAsText('a.txt', AppId);
        Names := NavApp.ListResources(AppId, '*');
        Apps := NavApp.ListAppsWithPublicResources();
    end;
}
