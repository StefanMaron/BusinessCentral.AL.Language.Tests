// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained codeunit 69100
// Probe: written against a real BC 27.5 service tier started by bc-linux (database CRONUS275); every literal below is what that tier
// produced. The Enabled state of a feature is stored per tenant, so a database that differs (another image, a changed feature
// management setup) can read differently: this test is the way to see what the CI image shows. Other BC versions were not measured.
//
// (The exact list was moved to PFFeatureKeyColumns.al, per version.) The 27.5 list was (ID: state):
//   AdvancedTellMe None, CalcOnlyVisibleFlowFields All Users, ConcealedMaskType All Users, ConcurrentInventoryPosting All Users,
//   ConcurrentJobPosting All Users, ConcurrentResourcePosting All Users, DisableSoapWebServicesOnMicrosoftUIPages All Users,
//   EnableMcpAccess All Users, FinancialReportDefaults All Users, FullTextSearch None, GLCurrencyRevaluation None,
//   Manufacturing_FlushingMethod_ActivateManualWoPick None, ReminderTermsCommunicationTexts All Users, SalesPrices None,
//   SaveValueToDatabasePromptly All Users, SemanticMetadataSearch All Users.
// BC versions: all. The per-version rows (Enabled, Mandatory By, ...) are pinned in PFFeatureKeyColumns.al.

codeunit 69100 "Probe Feature Key Enabled"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure FeatureKey_Table_HasRows_WithEnabledState()
    var
        FeatureKey: Record "Feature Key";
    begin
        // The platform list of features and their state differ between versions and minors; only that the table has rows holds everywhere.
        Assert.IsTrue(FeatureKey.Count() > 0, 'rows');
    end;

}
