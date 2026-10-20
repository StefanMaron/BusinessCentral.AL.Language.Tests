// Scope: probe (scratch branch al-runtime-rs-staging-winprobe, not for master)
// Fixtures used: Probe Observer (codeunit 69160), table 85064 "LT CQ Dec" (CqOddLeadObjects.al)
// Topic: corpus issue 679 (item 37 of 672): DecimalPlaces = 30 : 40 at run time on Windows BC.
// The first test is the probe from the issue. The other two ask each question alone, so one crash does not hide the other answer.
// BC versions: 27.5, 28.5, 29.0

codeunit 85065 "LT CQ Dec Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Item37_DecimalPlacesAbove28()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT CQ Dec";
    begin
        Rec.D3040 := 1.5;
        Observer.Observe('value = 1.5', Format(Rec.D3040 = 1.5));
        Observer.Observe('format 9', Format(Rec.D3040, 0, 9));
        asserterror Observer.Observe('format', Format(Rec.D3040));
        Observer.ObserveError('format');
        Observer.Finish();
    end;

    [Test]
    procedure Item37_Format9Only()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT CQ Dec";
    begin
        Rec.D3040 := 1.5;
        Observer.Observe('value = 1.5', Format(Rec.D3040 = 1.5));
        Observer.Observe('format 9', Format(Rec.D3040, 0, 9));
        Observer.Finish();
    end;

    [Test]
    procedure Item37_AssertErrorFormatOnly()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT CQ Dec";
    begin
        Rec.D3040 := 1.5;
        asserterror Observer.Observe('format', Format(Rec.D3040));
        Observer.ObserveError('format');
        Observer.Finish();
    end;
}
