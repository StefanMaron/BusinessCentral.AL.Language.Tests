// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: table 74647 and codeunit 74648 (P143Fixtures.al), codeunit 69160 "Probe Observer"
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74652 "LT P143 EnInvalid"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P143_EnInvalid()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P143 Helper";
        OldLanguage: Integer;
    begin
        Helper.Seed();
        OldLanguage := GlobalLanguage();
        Helper.ProbeDate(Observer, 'i_dotted', '17.01.2027');
        Helper.ProbeDate(Observer, 'i_iso', '2027-01-17');
        Helper.ProbeDate(Observer, 'i_abc', 'abc');
        Helper.ProbeDate(Observer, 'i_month13', '13/45/27');
        Helper.ProbeDate(Observer, 'i_noyear', '01/17');
        Helper.ProbeDate(Observer, 'i_day32', '01/32/27');
        Helper.ProbeDate(Observer, 'i_wild', '01/*');
        Helper.ProbeDate(Observer, 'i_range_bad', '01/01/27..abc');
        Observer.Observe('language_unchanged', Format(GlobalLanguage() = OldLanguage));
        Observer.Expect('i_dotted_err|text', 'The filter "17.01.2027" is not valid for the D field on the LT P143 Row table. The format of the Date ''17.01.2027'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('i_dotted_err|code', 'Filter:CSide');
        Observer.Expect('i_iso_filter', '01/17/27');
        Observer.Expect('i_iso_count', '1');
        Observer.Expect('i_abc_err|text', 'The filter "abc" is not valid for the D field on the LT P143 Row table. The format of the Date ''abc'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('i_abc_err|code', 'Filter:CSide');
        Observer.Expect('i_month13_err|text', 'The filter "13/45/27" is not valid for the D field on the LT P143 Row table. The format of the Date ''13/45/27'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('i_month13_err|code', 'Filter:CSide');
        Observer.Expect('i_noyear_filter', '01/17/26');
        Observer.Expect('i_noyear_count', '0');
        Observer.Expect('i_day32_err|text', 'The filter "01/32/27" is not valid for the D field on the LT P143 Row table. The format of the Date ''01/32/27'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('i_day32_err|code', 'Filter:CSide');
        Observer.Expect('i_wild_filter', '10/01/26');
        Observer.Expect('i_wild_count', '1');
        Observer.Expect('i_range_bad_err|text', 'The filter "01/01/27..abc" is not valid for the D field on the LT P143 Row table. The format of the Date ''abc'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('i_range_bad_err|code', 'Filter:CSide');
        Observer.Expect('language_unchanged', 'Yes');
        Observer.Verify();
    end;




}
