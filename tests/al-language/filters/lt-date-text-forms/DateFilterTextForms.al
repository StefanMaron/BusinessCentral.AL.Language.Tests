// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-getrangemin-method
// Scope: in-scope. GetRangeMin and GetRangeMax of a Date field filtered by text in short forms (4, 6 and 8 digits, with separators).
// Fixtures used: Probe Observer (69160) from the AL Language Coverage Tests app; self-contained objects 67358 (table) and 67359 (tests)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SetFilter(Field, '0201'), '02012026', '02-01-26', '2026-02-01' and, in a German session (language 1031), '020126'; the answers of GetRangeMin and GetRangeMax (as XML dates, Format(Date, 0, 9)).
//   Forms without a year take it from a date: WorkDate is set to a fixed date, the test is run with two different WorkDates, so the answers do not depend on the day the test runs.
//   Corpus issue 576 item 4.
// BC versions: 27, 28, 29

table 67358 "LT DTF Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Day; Date) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67359 "LT DTF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryRange(FilterText: Text; var Result: Text)
    var
        Rec: Record "LT DTF Table";
    begin
        Rec.SetFilter(Day, FilterText);
        Result := Format(Rec.GetRangeMin(Day), 0, 9) + ' .. ' + Format(Rec.GetRangeMax(Day), 0, 9) + ' | filter ' + Rec.GetFilter(Day);
    end;

    local procedure Run(Name: Text; FilterText: Text; var Observer: Codeunit "Probe Observer")
    var
        Result: Text;
    begin
        ClearLastError();
        Result := '';
        if TryRange(FilterText, Result) then
            Observer.Observe(Name, 'ok:' + Result)
        else begin
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
    end;

    [Test]
    procedure GetRange_DateTextForms_English()
    var
        Observer: Codeunit "Probe Observer";
        SavedLanguage: Integer;
        SavedWorkDate: Date;
    begin
        SavedLanguage := GlobalLanguage();
        SavedWorkDate := WorkDate();
        GlobalLanguage(1033);
        WorkDate(DMY2Date(15, 6, 2031));
        Run('four_digits', '0201', Observer);
        Run('eight_digits', '02012026', Observer);
        Run('separators_short_year', '02-01-26', Observer);
        Run('separators_iso', '2026-02-01', Observer);
        Run('separators_slash_short_year', '02/01/26', Observer);
        WorkDate(SavedWorkDate);
        GlobalLanguage(SavedLanguage);
        Observer.Finish();
    end;

    [Test]
    procedure GetRange_FourDigits_OtherWorkDate()
    var
        Observer: Codeunit "Probe Observer";
        SavedLanguage: Integer;
        SavedWorkDate: Date;
    begin
        SavedLanguage := GlobalLanguage();
        SavedWorkDate := WorkDate();
        GlobalLanguage(1033);
        WorkDate(DMY2Date(15, 6, 2038));
        Run('four_digits', '0201', Observer);
        WorkDate(SavedWorkDate);
        GlobalLanguage(SavedLanguage);
        Observer.Finish();
    end;

    [Test]
    procedure GetRange_SixDigits_German()
    var
        Observer: Codeunit "Probe Observer";
        SavedLanguage: Integer;
        SavedWorkDate: Date;
    begin
        SavedLanguage := GlobalLanguage();
        SavedWorkDate := WorkDate();
        GlobalLanguage(1031);
        WorkDate(DMY2Date(15, 6, 2031));
        Run('six_digits', '020126', Observer);
        Run('eight_digits', '02012026', Observer);
        Run('four_digits', '0201', Observer);
        Run('separators_short_year', '02.01.26', Observer);
        WorkDate(SavedWorkDate);
        GlobalLanguage(SavedLanguage);
        Observer.Finish();
    end;

    [Test]
    procedure GetRange_SixDigits_English()
    var
        Observer: Codeunit "Probe Observer";
        SavedLanguage: Integer;
        SavedWorkDate: Date;
    begin
        SavedLanguage := GlobalLanguage();
        SavedWorkDate := WorkDate();
        GlobalLanguage(1033);
        WorkDate(DMY2Date(15, 6, 2031));
        Run('six_digits', '020126', Observer);
        WorkDate(SavedWorkDate);
        GlobalLanguage(SavedLanguage);
        Observer.Finish();
    end;

    [Test]
    procedure GetRange_DayAboveTwelve_English()
    var
        Observer: Codeunit "Probe Observer";
        SavedLanguage: Integer;
        SavedWorkDate: Date;
    begin
        SavedLanguage := GlobalLanguage();
        SavedWorkDate := WorkDate();
        GlobalLanguage(1033);
        WorkDate(DMY2Date(15, 6, 2031));
        Run('dd_mm_four', '1301', Observer);
        Run('mm_dd_four', '0113', Observer);
        Run('dd_mm_yy_six', '130126', Observer);
        Run('mm_dd_yy_six', '011326', Observer);
        Run('dd_mm_yyyy_eight', '13012026', Observer);
        Run('mm_dd_yyyy_eight', '01132026', Observer);
        Run('dd_mm_yy_separators', '13-01-26', Observer);
        Run('mm_dd_yy_separators', '01-13-26', Observer);
        WorkDate(SavedWorkDate);
        GlobalLanguage(SavedLanguage);
        Observer.Finish();
    end;

    [Test]
    procedure GetRange_DayAboveTwelve_German()
    var
        Observer: Codeunit "Probe Observer";
        SavedLanguage: Integer;
        SavedWorkDate: Date;
    begin
        SavedLanguage := GlobalLanguage();
        SavedWorkDate := WorkDate();
        GlobalLanguage(1031);
        WorkDate(DMY2Date(15, 6, 2031));
        Run('dd_mm_four', '1301', Observer);
        Run('mm_dd_four', '0113', Observer);
        Run('dd_mm_yy_six', '130126', Observer);
        Run('mm_dd_yy_six', '011326', Observer);
        Run('dd_mm_yyyy_eight', '13012026', Observer);
        Run('mm_dd_yyyy_eight', '01132026', Observer);
        Run('dd_mm_yy_separators', '13.01.26', Observer);
        Run('mm_dd_yy_separators', '01.13.26', Observer);
        WorkDate(SavedWorkDate);
        GlobalLanguage(SavedLanguage);
        Observer.Finish();
    end;
}
