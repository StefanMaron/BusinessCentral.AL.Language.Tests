// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/datetime/datetime-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); test codeunit 73578
// Probe: written against BC on CI (no local container); every literal asserted below is what the CI tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the instance methods DateTime.Date() and DateTime.Time() next to the functions DT2Date(Dt) and DT2Time(Dt), for a DateTime with date and time,
//   a DateTime at midnight, the undefined DateTime (0DT), a DateTime made from 0D and a time, and one made from a date and 0T.
// BC versions: 27, 28, 29 by CI

codeunit 73578 "LT DateTime Date Time Methods"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";

    local procedure Show(Name: Text; Dt: DateTime)
    begin
        Obs.Observe(Name + '.dt', Format(Dt, 0, 9));
        Obs.Observe(Name + '.date_method', Format(Dt.Date(), 0, 9));
        Obs.Observe(Name + '.date_fn', Format(DT2Date(Dt), 0, 9));
        Obs.Observe(Name + '.time_method', Format(Dt.Time(), 0, 9));
        Obs.Observe(Name + '.time_fn', Format(DT2Time(Dt), 0, 9));
    end;

    [Test]
    procedure DateTime_DateAndTimeMethods_SetValue()
    begin
        Show('set', CreateDateTime(DMY2Date(15, 6, 2026), 143025.123T));
        Show('midnight', CreateDateTime(DMY2Date(15, 6, 2026), 0T));
        Show('endday', CreateDateTime(DMY2Date(31, 12, 2026), 235959.999T));
        Obs.Finish();
    end;

    [Test]
    procedure DateTime_DateAndTimeMethods_Undefined()
    var
        Dt: DateTime;
    begin
        Show('zero', 0DT);
        Show('var', Dt);
        Show('date0', CreateDateTime(0D, 120000T));
        Show('time0', CreateDateTime(DMY2Date(15, 6, 2026), 0T));
        Obs.Observe('date_is_zero', Format(Dt.Date() = 0D));
        Obs.Observe('time_is_zero', Format(Dt.Time() = 0T));
        Obs.Finish();
    end;
}
