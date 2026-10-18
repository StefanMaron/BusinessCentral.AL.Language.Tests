// @expect AL0132 | 'ModuleInfo' does not contain a definition for 'ContextSensitiveHelpUrl'
// @expect AL0132 | 'ModuleInfo' does not contain a definition for 'EULA'
// @expect AL0132 | 'ModuleInfo' does not contain a definition for 'Help'
// @expect AL0132 | 'ModuleInfo' does not contain a definition for 'PrivacyStatement'
// @until 28
// ModuleInfo.ContextSensitiveHelpUrl, EULA, Help and PrivacyStatement exist from BC 29. On BC 29 the call needs runtime 18.0, which the corpus app does not use (case 0998).
codeunit 58980 "MNC ModInfo 0964"
{
    procedure Run1(): Text
    var
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        exit(Info.ContextSensitiveHelpUrl() + Info.EULA() + Info.Help() + Info.PrivacyStatement());
    end;
}
