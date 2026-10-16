// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70318; reads the platform table Feature Key and only through a Modify that must fail
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the exact error text and code of Modify on a read-only column of the Feature Key table (Description, Learn More Link, Mandatory By, Can Try, Is One Way, Data Update Required)
// BC versions: 29 (27 and 28 by CI)

codeunit 70318 "LT P81 Feature Key Modify"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure FeatureKey_Modify_ReadOnlyColumns()
    var
        Observer: Codeunit "Probe Observer";
        FeatureKey: Record "Feature Key";
    begin
        Observer.Observe('has_rows', Format(FeatureKey.FindFirst()));

        FeatureKey.FindFirst();
        FeatureKey.Description := 'changed by a probe';
        asserterror FeatureKey.Modify();
        Observer.ObserveError('description');

        FeatureKey.FindFirst();
        FeatureKey."Learn More Link" := 'https://example.invalid';
        asserterror FeatureKey.Modify();
        Observer.ObserveError('learn_more_link');

        FeatureKey.FindFirst();
        FeatureKey."Mandatory By" := 'changed';
        asserterror FeatureKey.Modify();
        Observer.ObserveError('mandatory_by');

        FeatureKey.FindFirst();
        FeatureKey."Can Try" := not FeatureKey."Can Try";
        asserterror FeatureKey.Modify();
        Observer.ObserveError('can_try');

        FeatureKey.FindFirst();
        FeatureKey."Is One Way" := not FeatureKey."Is One Way";
        asserterror FeatureKey.Modify();
        Observer.ObserveError('is_one_way');

        FeatureKey.FindFirst();
        FeatureKey."Data Update Required" := not FeatureKey."Data Update Required";
        asserterror FeatureKey.Modify();
        Observer.ObserveError('data_update_required');

        Observer.Finish();
    end;
}
