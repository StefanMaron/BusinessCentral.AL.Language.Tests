// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74017
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Clear on an Interface variable: calling afterwards
// BC versions: 29 (27 and 28 by CI)
// Tag: P95

interface "LT P95 IFace 74015"
{
    procedure Hello(): Text;
}

codeunit 74016 "LT P95 Impl 74016" implements "LT P95 IFace 74015"
{
    procedure Hello(): Text
    begin
        exit('hello');
    end;
}

codeunit 74017 "LT P95 Clear Interface"
{
    Subtype = Test;
    TestPermissions = Disabled;


    [Test]
    procedure ClearInterface()
    var
        Observer: Codeunit "Probe Observer";
        I: Interface "LT P95 IFace 74015";
        I2: Interface "LT P95 IFace 74015";
        Impl: Codeunit "LT P95 Impl 74016";
    begin
        I := Impl;
        Observer.Observe('before', I.Hello());
        Clear(I);
        asserterror Observer.Observe('after', I.Hello());
        Observer.ObserveError('call_after_clear');
        asserterror Observer.Observe('unassigned', I2.Hello());
        Observer.ObserveError('call_unassigned');
        I := Impl;
        Clear(Impl);
        Observer.Observe('interface_survives_clear_of_codeunit', I.Hello());

        Observer.Finish();
    end;

}
