// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-testpermissions-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT BI TP Probe (81551)
// Corpus issue 658, one TestPermissions variant with Tests-TestLibraries installed: codeunit Disabled, method attribute InheritFromTestCodeunit.
// Probe: observed values under Microsoft's test runner (see BiTpHelper.al).
// BC versions: 27, 28, 29
codeunit 81561 "LT BI TP DisMInherit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [HandlerFunctions('BiTpMsg')]
    [TestPermissions(TestPermissions::InheritFromTestCodeunit)]
    procedure BiTpDisMInherit_Permissions()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BI TP Probe";
    begin
        Message('LT BI');
        Probe.ObservePermissions(Observer);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('BiTpMsg')]
    [TestPermissions(TestPermissions::InheritFromTestCodeunit)]
    procedure BiTpDisMInherit_Insert()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BI TP Probe";
    begin
        Message('LT BI');
        asserterror Probe.InsertThenFail();
        Observer.ObserveError('ins');
        Observer.Finish();
    end;

    [MessageHandler]
    procedure BiTpMsg(Msg: Text[1024])
    begin
    end;
}
