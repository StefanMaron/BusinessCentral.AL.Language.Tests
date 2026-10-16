// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: table 74647 and codeunit 74648 (P143Fixtures.al), codeunit 69160 "Probe Observer"
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74655 "LT P143 DeInvalid"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P143_DeInvalid()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P143 Helper";
        OldLanguage: Integer;
    begin
        Helper.Seed();
        OldLanguage := GlobalLanguage();
        GlobalLanguage(1031);
        Run(Observer, Helper);
        GlobalLanguage(OldLanguage);
        Observer.Observe('language_restored', Format(GlobalLanguage() = OldLanguage));
        Observer.Expect('i_iso_filter', '01/17/27');
        Observer.Expect('i_iso_count', '1');
        Observer.Expect('i_abc_err|text', 'Der Filter ''abc'' ist für das Feld ''D'' der Tabelle ''LT P143 Row'' nicht gültig. Das Format Date „abc“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.');
        Observer.Expect('i_abc_err|code', 'Filter:CSide');
        Observer.Expect('i_month13_err|text', 'Der Filter ''45.13.27'' ist für das Feld ''D'' der Tabelle ''LT P143 Row'' nicht gültig. Das Format Date „45.13.27“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.');
        Observer.Expect('i_month13_err|code', 'Filter:CSide');
        Observer.Expect('i_us_2027_filter', '01/17/27');
        Observer.Expect('i_us_2027_count', '1');
        Observer.Expect('i_wild_filter', '10/01/26');
        Observer.Expect('i_wild_count', '1');
        Observer.Expect('language_restored', 'Yes');
        Observer.Verify();
    end;

    // every statement that can raise sits inside the helper's TryFunctions, so Run cannot leave the language changed
    local procedure Run(var Observer: Codeunit "Probe Observer"; var Helper: Codeunit "LT P143 Helper")
    begin
        Helper.ProbeDate(Observer, 'i_iso', '2027-01-17');
        Helper.ProbeDate(Observer, 'i_abc', 'abc');
        Helper.ProbeDate(Observer, 'i_month13', '45.13.27');
        Helper.ProbeDate(Observer, 'i_us_2027', '01/17/2027');
        Helper.ProbeDate(Observer, 'i_wild', '01.*');
    end;
}
