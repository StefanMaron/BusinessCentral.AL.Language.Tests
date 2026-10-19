// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: own enum 72292, table 72291, codeunit 72293
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

enum 72292 "LT P123 Kind"
{
    Extensible = false;
    value(0; Open) { }
    value(1; Released) { }
    value(2; Closed) { }
}

table 72291 "LT P123 VA"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "LT P123 Kind") { ValuesAllowed = Open, Released; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72293 "LT P123 TValuesAllowed Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P123_ValuesAllowedOnTableField()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT P123 VA";
    begin
        T.DeleteAll();
        T.Init(); T.Id := 1;
        T.Validate(Kind, T.Kind::Released);
        Observer.Observe('allowed validate', Format(T.Kind));
        T.Validate(Kind, T.Kind::Closed);
        Observer.Observe('disallowed validate', 'no error');
        T.Kind := T.Kind::Closed;
        Observer.Observe('assign disallowed', Format(T.Kind));
        T.Insert();
        Observer.Observe('insert disallowed count', Format(T.Count()));
        Observer.Expect('allowed validate', 'Released');
        Observer.Expect('disallowed validate', 'no error');
        Observer.Expect('assign disallowed', 'Closed');
        Observer.Expect('insert disallowed count', '1');
        Observer.Verify();
    end;
}
