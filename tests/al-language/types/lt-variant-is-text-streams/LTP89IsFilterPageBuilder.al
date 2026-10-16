// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT P89 Rec (74625), enum LT P89 Color (74626)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74633 "LT P89 Is FilterPageBuilder"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Flags(V: Variant): Text
    var
        R: Text;
    begin
        if V.IsFilterPageBuilder() then
            R += 'FilterPageBuilder,';
        if V.IsRecord() then
            R += 'Record,';
        if V.IsRecordRef() then
            R += 'RecordRef,';
        if V.IsOption() then
            R += 'Option,';
        if V.IsInteger() then
            R += 'Integer,';
        exit(R);
    end;

    [Test]
    procedure FilterPageBuilder_InVariant()
    var
        Observer: Codeunit "Probe Observer";
        X: FilterPageBuilder;
        V: Variant;
    begin
        V := X; Observer.Observe('default', Flags(V));
        X.AddTable('LT P89 Rec', Database::"LT P89 Rec");
        V := X; Observer.Observe('with_table', Flags(V));
        Observer.Observe('count', Format(X.Count()));
        Observer.Finish();
    end;
}
