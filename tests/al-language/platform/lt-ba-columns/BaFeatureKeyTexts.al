// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/feature-management
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Corpus issue 656 item 3: the text columns of the platform table "Feature Key" (Description, "Learn More Link",
// "Description In English") for a few keys that exist on BC 27.5, 28.5 and 29.0 (PFFeatureKeyColumns.al pins the other columns).
// One test per key. A key that is missing on a version observes '<no row>'.
// Probe: observed values; every literal asserted below is what the BC tier produced.
// BC versions: 27, 28, 29
codeunit 80773 "LT BA Feature Key Texts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure BaFeatureKey_FinancialReportDefaults()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveKey(Observer, 'FinancialReportDefaults');
        Observer.Finish();
    end;

    [Test]
    procedure BaFeatureKey_DisableSoapWebServices()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveKey(Observer, 'DisableSoapWebServicesOnMicrosoftUIPages');
        Observer.Finish();
    end;

    [Test]
    procedure BaFeatureKey_SalesPrices()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveKey(Observer, 'SalesPrices');
        Observer.Finish();
    end;

    [Test]
    procedure BaFeatureKey_FullTextSearch()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveKey(Observer, 'FullTextSearch');
        Observer.Finish();
    end;

    [Test]
    procedure BaFeatureKey_ConcurrentJobPosting()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveKey(Observer, 'ConcurrentJobPosting');
        Observer.Finish();
    end;

    local procedure ObserveKey(var Observer: Codeunit "Probe Observer"; KeyId: Text[50])
    var
        FeatureKey: Record "Feature Key";
    begin
        if not FeatureKey.Get(KeyId) then begin
            Observer.Observe('row', '<no row>');
            exit;
        end;
        Observer.Observe('desc', FeatureKey.Description);
        Observer.Observe('link', FeatureKey."Learn More Link");
        Observer.Observe('eng', FeatureKey."Description In English");
    end;
}
