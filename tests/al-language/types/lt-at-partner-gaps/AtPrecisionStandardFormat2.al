// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunit 80004
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: Format(D, 0, '<Precision,2:2><Standard Format,2>') for a Decimal D: 0, 1234.5, -1, and the rounding and grouping edges 1234.567,
// 0.005, 1234567.1 and -0.5.
// BC versions: 27, 28, 29

codeunit 80004 "LT AT Precision Std Format 2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure F(D: Decimal): Text
    begin
        exit(Format(D, 0, '<Precision,2:2><Standard Format,2>'));
    end;

    [Test]
    procedure AT_Precision22_StandardFormat2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('0', F(0));
        Observer.Observe('1234.5', F(1234.5));
        Observer.Observe('-1', F(-1));
        Observer.Observe('1234.567', F(1234.567));
        Observer.Observe('0.005', F(0.005));
        Observer.Observe('1234567.1', F(1234567.1));
        Observer.Observe('-0.5', F(-0.5));
        Observer.Expect('0', '0.00');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('1234.567', '1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('1234567.1', '1234567.10');
        Observer.Expect('-0.5', '-0.50');
        Observer.Verify();
    end;
}
