// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-triggers
// Scope: in-scope
// Probe: written against a BC service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 27 to 29 (CI matrix)
// Fixtures used: Probe Observer (codeunit 69160); codeunit "LT AB Log" (77050); own upgrade codeunit 77095, test codeunit 77096
// Facts: OnValidateUpgradePerCompany and OnValidateUpgradePerDatabase of an upgrade codeunit compile next to OnUpgradePerCompany and OnUpgradePerDatabase.
// A test cannot start an extension upgrade, so the triggers cannot be raised from AL: the test records what Codeunit.Run of the upgrade codeunit does (the upgrade triggers do not run).

codeunit 77095 "LT AB Upgrade"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
        Log.Add('upgrade OnRun');
    end;

    trigger OnUpgradePerCompany()
    begin
        Log.Add('upgrade OnUpgradePerCompany');
    end;

    trigger OnValidateUpgradePerCompany()
    begin
        Log.Add('upgrade OnValidateUpgradePerCompany');
    end;

    trigger OnUpgradePerDatabase()
    begin
        Log.Add('upgrade OnUpgradePerDatabase');
    end;

    trigger OnValidateUpgradePerDatabase()
    begin
        Log.Add('upgrade OnValidateUpgradePerDatabase');
    end;

    var
        Log: Codeunit "LT AB Log";
}

codeunit 77096 "LT AB Upgrade Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure RunUpgradeCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
    begin
        Log.Reset();
        asserterror Codeunit.Run(Codeunit::"LT AB Upgrade");
        Observer.ObserveError('run-upgrade-codeunit');
        Observer.Observe('log', Log.Dump());
        Observer.Finish();
    end;
}
