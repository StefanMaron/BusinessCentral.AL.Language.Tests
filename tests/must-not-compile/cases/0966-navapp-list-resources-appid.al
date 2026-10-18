// @expect AL0126 | No overload for method 'ListResources' takes 2 arguments
// @expect AL0132 | 'NavApp' does not contain a definition for 'ListAppsWithPublicResources'
// @until 28
// NavApp.ListResources(AppId) and NavApp.ListAppsWithPublicResources exist from BC 29. On BC 29 the call needs runtime 18.0, which the corpus app does not use (case 0998).
codeunit 58990 "MNC NavAppList 0966"
{
    procedure Run1()
    var
        Names: List of [Text];
        Apps: List of [Guid];
        AppId: Guid;
    begin
        Names := NavApp.ListResources(AppId, '*.txt');
        Apps := NavApp.ListAppsWithPublicResources();
    end;
}
