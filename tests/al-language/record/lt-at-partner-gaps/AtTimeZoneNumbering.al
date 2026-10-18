// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own codeunit 80007
// Probe: the "Time Zone" virtual table (2000000164) lists the time zones of the HOST operating system, so "No." and ID depend on the machine.
// The shape (1..N, no gaps, non-blank IDs) is pinned host-independently in record/TestTimeZoneVirtualTable.al.
// Facts asked: the No. of the row with ID 'W. Europe Standard Time', the row count, the first and last ID.
// BC versions: 27, 28, 29

codeunit 80007 "LT AT Time Zone Numbering"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AT_TimeZone_Numbering_Probe()
    var
        Observer: Codeunit "Probe Observer";
        TimeZone: Record "Time Zone";
    begin
        Observer.Observe('count', Format(TimeZone.Count()));
        TimeZone.SetRange(ID, 'W. Europe Standard Time');
        if TimeZone.FindFirst() then
            Observer.Observe('W. Europe No.', Format(TimeZone."No."))
        else
            Observer.Observe('W. Europe No.', 'absent');
        TimeZone.SetRange(ID, 'Europe/Berlin');
        if TimeZone.FindFirst() then
            Observer.Observe('Europe/Berlin No.', Format(TimeZone."No."))
        else
            Observer.Observe('Europe/Berlin No.', 'absent');
        TimeZone.SetRange(ID);
        TimeZone.FindFirst();
        Observer.Observe('first', Format(TimeZone."No.") + '=' + TimeZone.ID);
        TimeZone.FindLast();
        Observer.Observe('last', Format(TimeZone."No.") + '=' + TimeZone.ID);
        TimeZone.Get(2);
        Observer.Observe('2', TimeZone.ID);
        TimeZone.Get(3);
        Observer.Observe('3', TimeZone.ID);
        Observer.Finish();
    end;
}
