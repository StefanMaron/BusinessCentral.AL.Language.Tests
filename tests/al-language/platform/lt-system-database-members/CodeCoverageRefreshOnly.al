// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-codecoverageload-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74025
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CodeCoverageRefresh called with logging inactive
// BC versions: 29 (27 and 28 by CI)
// Tag: P95

codeunit 74025 "LT P95 CodeCoverage Refresh"
{
    Subtype = Test;
    TestPermissions = Disabled;


    local procedure Err(): Text
    begin
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryRefresh()
    begin
        CodeCoverageRefresh();
    end;

    [Test]
    procedure CodeCoverageRefreshOnly()
    var
        Observer: Codeunit "Probe Observer";

    begin
        if TryRefresh() then
            Observer.Observe('refresh', 'ok')
        else
            Observer.Observe('refresh', Err());
        if TryRefresh() then
            Observer.Observe('refresh_again', 'ok')
        else
            Observer.Observe('refresh_again', Err());

        Observer.Finish();
    end;

}
