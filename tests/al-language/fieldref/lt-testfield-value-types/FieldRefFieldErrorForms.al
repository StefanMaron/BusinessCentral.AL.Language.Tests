// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-fielderror-method
// Scope: in-scope
// Fixtures used: table 67900 and codeunit 67901 (TestFieldValueFixture.al), Probe Observer
// Probe: FieldRef.FieldError() and FieldRef.FieldError(Text) (issue 589): error text and code, with and without text, field and table captions
// BC versions: 27 and later (values by CI matrix)

codeunit 67906 "LT R FRFE"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure FieldRef_FieldError_Forms()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(11);
        asserterror Fld.FieldError();
        Observer.ObserveError('integer_no_text');
        asserterror Fld.FieldError('custom reason');
        Observer.ObserveError('integer_text');
        asserterror Fld.FieldError('');
        Observer.ObserveError('integer_empty_text');
        Fld := RecRef.Field(9);
        asserterror Fld.FieldError();
        Observer.ObserveError('text_no_text');
        asserterror Fld.FieldError('custom reason');
        Observer.ObserveError('text_text');
        Fld := RecRef.Field(3);
        asserterror Fld.FieldError('custom reason');
        Observer.ObserveError('boolean_text');
        Fld := RecRef.Field(8);
        asserterror Fld.FieldError('custom reason');
        Observer.ObserveError('enum_text');
        RecRef.Close();
        Observer.Finish();
    end;
}
