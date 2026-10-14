// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained codeunit 69100
// Probe: written against a real BC 27.5 service tier started by bc-linux (database CRONUS275); every literal below is what that tier
// produced. The Enabled state of a feature is stored per tenant, so a database that differs (another image, a changed feature
// management setup) can read differently: this test is the way to see what the CI image shows. Other BC versions were not measured.
//
// Pins "Feature Key".Enabled for every row of the 27.5 platform list (ID: state):
//   AdvancedTellMe None, CalcOnlyVisibleFlowFields All Users, ConcealedMaskType All Users, ConcurrentInventoryPosting All Users,
//   ConcurrentJobPosting All Users, ConcurrentResourcePosting All Users, DisableSoapWebServicesOnMicrosoftUIPages All Users,
//   EnableMcpAccess All Users, FinancialReportDefaults All Users, FullTextSearch None, GLCurrencyRevaluation None,
//   Manufacturing_FlushingMethod_ActivateManualWoPick None, ReminderTermsCommunicationTexts All Users, SalesPrices None,
//   SaveValueToDatabasePromptly All Users, SemanticMetadataSearch All Users.
// BC versions: 27.3 and 27.5 (the list differs by minor: 27.0 reads differently, so the exact list is asserted only there; the row-count test runs everywhere)

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

#if not BC28PLUS
    [Test]
    procedure FeatureKey_Enabled_PerId_On27()
    var
        FeatureKey: Record "Feature Key";
        Rows: Text;
        Version: Text;
        AppConstants: Codeunit "Application System Constants";
    begin
        // Measured on 27.5 and 27.3; 27.0 differs, so the exact list is asserted only where it was measured.
        Version := AppConstants.ApplicationVersion();
        if not (Version.StartsWith('27.5.') or Version.StartsWith('27.3.')) then
            exit;
        FeatureKey.FindSet();
        repeat
            Rows += FeatureKey.ID + ':' + Format(FeatureKey.Enabled) + ' ';
        until FeatureKey.Next() = 0;

        Assert.AreEqual(
            'AdvancedTellMe:None CalcOnlyVisibleFlowFields:All Users ConcealedMaskType:All Users ConcurrentInventoryPosting:All Users ' +
            'ConcurrentJobPosting:All Users ConcurrentResourcePosting:All Users DisableSoapWebServicesOnMicrosoftUIPages:All Users ' +
            'EnableMcpAccess:All Users FinancialReportDefaults:All Users FullTextSearch:None GLCurrencyRevaluation:None ' +
            'Manufacturing_FlushingMethod_ActivateManualWoPick:None ReminderTermsCommunicationTexts:All Users SalesPrices:None ' +
            'SaveValueToDatabasePromptly:All Users SemanticMetadataSearch:All Users ',
            Rows, 'Enabled per ID');
    end;
#endif
}
