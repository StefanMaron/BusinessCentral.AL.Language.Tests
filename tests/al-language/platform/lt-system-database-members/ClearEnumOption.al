// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74005
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Clear on Enum and Option variables, default value and ordinal
// BC versions: 29 (27 and 28 by CI)
// Tag: P95

enum 74004 "LT P95 Enum 74004"
{
    Extensible = true;
    value(5; Five) { }
    value(7; Seven) { }
    value(0; Zero) { }
}

codeunit 74005 "LT P95 Clear Enum Option"
{
    Subtype = Test;
    TestPermissions = Disabled;


    [Test]
    procedure ClearEnumOption()
    var
        Observer: Codeunit "Probe Observer";
        E: Enum "LT P95 Enum 74004";
        E2: Enum "LT P95 Enum 74004";
        E3: Enum "LT P95 Enum 74004";
        Op: Option Alpha,Beta,Gamma;
        Bt: Option Alpha,Beta;
    begin
        E := E::Seven;
        Op := Op::Beta;
        Observer.Observe('enum_before', Format(E) + '|' + Format(E.AsInteger()));
        Observer.Observe('option_before', Format(Op) + '|' + Format(Op, 0, 2));
        Clear(E);
        Clear(Op);
        Observer.Observe('enum_after', Format(E) + '|' + Format(E.AsInteger()));
        Observer.Observe('option_after', Format(Op) + '|' + Format(Op, 0, 2));
        E2 := E2::Five;
        Observer.Observe('enum_fresh_default_vs_five', Format(E3.AsInteger()));
        Clear(E2);
        Observer.Observe('enum_five_cleared', Format(E2.AsInteger()));
        Bt := Bt::Beta;
        Clear(Bt);
        Observer.Observe('option2_cleared', Format(Bt, 0, 2));

        Observer.Finish();
    end;

}
