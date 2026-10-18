// @expect AL0132 | 'NavApp' does not contain a definition for 'GetCallstackModuleInfos'
// NavApp.GetCallstackModuleInfos does not exist (neither Cloud nor OnPrem target).
codeunit 50560 "MNC O 0560"
{
    procedure Probe()
    var Infos: List of [ModuleInfo];
    begin
        Infos := NavApp.GetCallstackModuleInfos();
    end;
}
