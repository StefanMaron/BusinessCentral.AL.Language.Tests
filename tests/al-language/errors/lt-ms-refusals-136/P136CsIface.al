// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-callstack-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); codeunit 74337 of P136CsBase.al; interface "LT P136 CS Iface", codeunit 74344, enum 74345, codeunit 74346
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SessionInformation.Callstack read inside an interface method implemented by a codeunit, called through an interface variable and through an enum that implements the interface
// BC versions: 29 (27 and 28 by CI)

interface "LT P136 CS Iface"
{
    procedure Work();
}

codeunit 74344 "LT P136 CS Impl" implements "LT P136 CS Iface"
{
    procedure Work()
    var
        Log: Codeunit "LT P136 CS Log";
    begin
        Log.Capture('ifaceWork');
    end;
}

enum 74345 "LT P136 CS Enum" implements "LT P136 CS Iface"
{
    Extensible = true;

    value(0; One)
    {
        Implementation = "LT P136 CS Iface" = "LT P136 CS Impl";
    }
}

codeunit 74346 "LT P136 CS Iface Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT P136 CS Log";

    [Test]
    procedure P136_Callstack_InterfaceMethod()
    var
        Observer: Codeunit "Probe Observer";
        Impl: Codeunit "LT P136 CS Impl";
        Iface: Interface "LT P136 CS Iface";
        E: Enum "LT P136 CS Enum";
    begin
        Log.Reset();
        Iface := Impl;
        Iface.Work();
        Observer.Observe('viaCodeunitVariable', Log.Frames('ifaceWork'));
        Log.Reset();
        E := E::One;
        Iface := E;
        Iface.Work();
        Observer.Observe('viaEnumConversion', Log.Frames('ifaceWork'));
        Log.Reset();
        Impl.Work();
        Observer.Observe('direct', Log.Frames('ifaceWork'));
        Observer.Expect('viaCodeunitVariable', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Impl"(CodeUnit 74344).Work line 4 < "LT P136 CS Iface Tests"(CodeUnit 74346).P136_Callstack_InterfaceMethod line 9');
        Observer.Expect('viaEnumConversion', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Impl"(CodeUnit 74344).Work line 4 < "LT P136 CS Iface Tests"(CodeUnit 74346).P136_Callstack_InterfaceMethod line 14');
        Observer.Expect('direct', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Impl"(CodeUnit 74344).Work line 4 < "LT P136 CS Iface Tests"(CodeUnit 74346).P136_Callstack_InterfaceMethod line 17');
        Observer.Verify();
    end;
}
