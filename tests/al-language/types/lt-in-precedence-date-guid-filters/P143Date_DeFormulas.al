// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: table 74647 and codeunit 74648 (P143Fixtures.al), codeunit 69160 "Probe Observer"
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74657 "LT P143 DeFormulas"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P143_DeFormulas()
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
        Observer.Expect('CD_err|text', 'Der Filter ''CD'' ist für das Feld ''D'' der Tabelle ''LT P143 Row'' nicht gültig. Das Format Date „CD“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.');
        Observer.Expect('CD_err|code', 'Filter:CSide');
        Observer.Expect('T_count_eq_on_expected', 'Ja');
        Observer.Expect('T_filter_is_text', 'Nein');
        Observer.Expect('T_filter_is_expected_date', 'Ja');
        Observer.Expect('W_count_eq_on_expected', 'Ja');
        Observer.Expect('W_filter_is_text', 'Nein');
        Observer.Expect('W_filter_is_expected_date', 'Ja');
        Observer.Expect('lower_CD_err|text', 'Der Filter ''cd'' ist für das Feld ''D'' der Tabelle ''LT P143 Row'' nicht gültig. Das Format Date „cd“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.');
        Observer.Expect('lower_CD_err|code', 'Filter:CSide');
        Observer.Expect('lower_T_count_eq_on_expected', 'Ja');
        Observer.Expect('lower_T_filter_is_text', 'Nein');
        Observer.Expect('lower_T_filter_is_expected_date', 'Ja');
        Observer.Expect('lower_W_count_eq_on_expected', 'Ja');
        Observer.Expect('lower_W_filter_is_text', 'Nein');
        Observer.Expect('lower_W_filter_is_expected_date', 'Ja');
        Observer.Expect('T_range_open_count_eq_on_expected', 'Nein');
        Observer.Expect('T_range_open_filter_is_text', 'Nein');
        Observer.Expect('T_range_open_filter_is_expected_date', 'Nein');
        Observer.Expect('count_all', '1');
        Observer.Expect('language_restored', 'Yes');
        Observer.Verify();
    end;

    // every statement that can raise sits inside the helper's TryFunctions, so Run cannot leave the language changed
    local procedure Run(var Observer: Codeunit "Probe Observer"; var Helper: Codeunit "LT P143 Helper")
    begin
        Helper.ProbeFormula(Observer, 'CD', 'CD', Today());
        Helper.ProbeFormula(Observer, 'T', 'T', Today());
        Helper.ProbeFormula(Observer, 'W', 'W', WorkDate());
        Helper.ProbeFormula(Observer, 'lower_CD', 'cd', Today());
        Helper.ProbeFormula(Observer, 'lower_T', 't', Today());
        Helper.ProbeFormula(Observer, 'lower_W', 'w', WorkDate());
        Helper.ProbeFormula(Observer, 'T_range_open', '..T', Today());
        Observer.Observe('count_all', Format(Helper.CountOn(0D) + 0));
    end;

    // Corpus issue 668 item 7 (writer BQ): date filter formulas with arithmetic under German and French (Canada) (microsoft/AL issue 5923).
    // The filter text is compared with the date computed in the same language, so no value depends on the run date.
    [TryFunction]
    local procedure BqTryLanguage(LanguageId: Integer)
    begin
        GlobalLanguage(LanguageId);
    end;

    local procedure BqProbe(var Observer: Codeunit "Probe Observer"; var Helper: Codeunit "LT P143 Helper"; Name: Text; FilterText: Text; Expected: Text)
    var
        Got: Text;
        Cnt: Integer;
    begin
        if Helper.TryDate(FilterText, Got, Cnt) then
            Observer.Observe(Name, 'ok filter_is_expected=' + Format(Got = Expected, 0, 9))
        else
            Observer.ObserveError(Name + '_err');
    end;

    local procedure BqRunFormulas(var Observer: Codeunit "Probe Observer"; var Helper: Codeunit "LT P143 Helper"; Prefix: Text)
    begin
        BqProbe(Observer, Helper, Prefix + '_dotdot_t_minus_1d', '..t-1d', '..' + Format(Today() - 1));
        BqProbe(Observer, Helper, Prefix + '_dotdot_t_minus_1t', '..t-1t', '..' + Format(Today() - 1));
        BqProbe(Observer, Helper, Prefix + '_t_plus_1d', 't+1d', Format(Today() + 1));
        BqProbe(Observer, Helper, Prefix + '_h', 'h', Format(Today()));
        BqProbe(Observer, Helper, Prefix + '_a', 'a', Format(Today()));
        BqProbe(Observer, Helper, Prefix + '_j', 'j', Format(Today()));
    end;

    [Test]
    procedure P143_LocalizedFormulas_Arithmetic_BQ()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P143 Helper";
        OldLanguage: Integer;
    begin
        Helper.Seed();
        OldLanguage := GlobalLanguage();
        BqRunFormulas(Observer, Helper, 'en');
        GlobalLanguage(1031);
        BqRunFormulas(Observer, Helper, 'de');
        GlobalLanguage(OldLanguage);
        if BqTryLanguage(3084) then begin
            Observer.Observe('frca_language', 'ok');
            BqRunFormulas(Observer, Helper, 'frca');
        end else
            Observer.ObserveError('frca_language');
        GlobalLanguage(OldLanguage);
        Observer.Observe('language_restored', Format(GlobalLanguage() = OldLanguage));
        Observer.Finish();
    end;
}
