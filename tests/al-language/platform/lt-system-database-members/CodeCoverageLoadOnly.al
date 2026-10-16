// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-codecoverageload-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74024
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CodeCoverageLoad called with logging inactive: no error or error text
// BC versions: 29 (27 and 28 by CI)
// Tag: P95

codeunit 74024 "LT P95 CodeCoverage Load"
{
    Subtype = Test;
    TestPermissions = Disabled;


    local procedure Err(): Text
    begin
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryLoad()
    begin
        CodeCoverageLoad();
    end;

    [Test]
    procedure CodeCoverageLoadOnly()
    var
        Observer: Codeunit "Probe Observer";

    begin
        if TryLoad() then
            Observer.Observe('load', 'ok')
        else
            Observer.Observe('load', Err());
        if TryLoad() then
            Observer.Observe('load_again', 'ok')
        else
            Observer.Observe('load_again', Err());

        Observer.Finish();
    end;

}
