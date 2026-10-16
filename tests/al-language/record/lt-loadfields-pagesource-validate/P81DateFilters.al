// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 70316 and codeunit 70317
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.SetFilter on a Date field with text values ('01012026', '010126', 'T', 'W', ranges, '..' forms, 0D, invalid dates) and with %1 / %2 placeholders: which forms work, the filter text BC keeps (GetFilter), the rows found, the exact error texts and codes
// BC versions: 29 (27 and 28 by CI)

table 70316 "LT P81 DF"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; D; Date) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

codeunit 70317 "LT P81 Date Filters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P81 DF";
    begin
        Row.DeleteAll();
        AddRow('E0', 0D);
        AddRow('E1', 20251231D);
        AddRow('E2', 20260101D);
        AddRow('E3', 20260102D);
        AddRow('E4', 20260201D);
    end;

    local procedure AddRow(NewCode: Code[10]; NewDate: Date)
    var
        Row: Record "LT P81 DF";
    begin
        Row.Code := NewCode;
        Row.D := NewDate;
        Row.Insert();
    end;

    [TryFunction]
    local procedure TryFilter(var Row: Record "LT P81 DF"; Txt: Text)
    begin
        Row.SetFilter(D, Txt);
    end;

    [TryFunction]
    local procedure TryFilter2(var Row: Record "LT P81 DF"; Txt: Text; D1: Date; D2: Date)
    begin
        Row.SetFilter(D, Txt, D1, D2);
    end;

    [TryFunction]
    local procedure TryFilter1(var Row: Record "LT P81 DF"; Txt: Text; D1: Date)
    begin
        Row.SetFilter(D, Txt, D1);
    end;

    local procedure Describe(var Row: Record "LT P81 DF"): Text
    var
        Codes: Text;
    begin
        if Row.FindSet() then
            repeat
                Codes += Row.Code + ',';
            until Row.Next() = 0;
        exit('ok|filter=' + Scrub(Row.GetFilter(D)) + '|rows=' + Codes);
    end;

    local procedure Scrub(Txt: Text): Text
    begin
        exit(Txt.Replace(Format(Today()), '<today>').Replace(Format(WorkDate()), '<workdate>'));
    end;

    local procedure Failed(): Text
    begin
        exit('error:' + Scrub(GetLastErrorText()) + '|' + GetLastErrorCode());
    end;

    local procedure Apply(Txt: Text): Text
    var
        Row: Record "LT P81 DF";
    begin
        if TryFilter(Row, Txt) then
            exit(Describe(Row));
        exit(Failed());
    end;

    local procedure Apply1(Txt: Text; D1: Date): Text
    var
        Row: Record "LT P81 DF";
    begin
        if TryFilter1(Row, Txt, D1) then
            exit(Describe(Row));
        exit(Failed());
    end;

    local procedure Apply2(Txt: Text; D1: Date; D2: Date): Text
    var
        Row: Record "LT P81 DF";
    begin
        if TryFilter2(Row, Txt, D1, D2) then
            exit(Describe(Row));
        exit(Failed());
    end;

    local procedure ObserveList(var Observer: Codeunit "Probe Observer"; Texts: List of [Text]; Prefix: Text)
    var
        i: Integer;
    begin
        for i := 1 to Texts.Count() do
            Observer.Observe(Prefix + Format(i) + '[' + Texts.Get(i) + ']', Apply(Texts.Get(i)));
    end;

    [Test]
    procedure SetFilter_Date_NumericForms()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
    begin
        Seed();
        Texts.Add('01012026');
        Texts.Add('010126');
        Texts.Add('1/1/2026');
        Texts.Add('01/01/2026');
        Texts.Add('2026-01-01');
        Texts.Add('20260101');
        Texts.Add('1.1.2026');
        Texts.Add('1.1.26');
        Texts.Add('311225');
        Texts.Add('31122025');
        Texts.Add('0101');
        Texts.Add('1');
        ObserveList(Observer, Texts, 'n');
        Observer.Finish();
    end;

    [Test]
    procedure SetFilter_Date_RangeForms()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
    begin
        Seed();
        Texts.Add('010126..020126');
        Texts.Add('01012026..02012026');
        Texts.Add('01012026..');
        Texts.Add('..01012026');
        Texts.Add('..');
        Texts.Add('010126|020126');
        Texts.Add('<>010126');
        Texts.Add('<010126');
        Texts.Add('>010126');
        Texts.Add('>=010126');
        Texts.Add('<=010126');
        Texts.Add('>010126&<010226');
        Texts.Add('020126..010126');
        Texts.Add('<010126|>020126');
        Texts.Add('010126..010126');
        Texts.Add('311225..010126|010226');
        ObserveList(Observer, Texts, 'r');
        Observer.Finish();
    end;

    [Test]
    procedure SetFilter_Date_EmptyAndZeroForms()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
    begin
        Seed();
        Texts.Add('');
        Texts.Add(' ');
        Texts.Add('0D');
        Texts.Add('0D..');
        Texts.Add('..0D');
        Texts.Add('<>0D');
        Texts.Add('>0D');
        Texts.Add('0D..010126');
        Texts.Add('''''');
        Texts.Add('<>''''');
        Texts.Add('0');
        Texts.Add('000000');
        Texts.Add('0D|010126');
        ObserveList(Observer, Texts, 'z');
        Observer.Finish();
    end;

    [Test]
    procedure SetFilter_Date_TodayAndWorkDateKeywords()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
        SavedWorkDate: Date;
    begin
        SavedWorkDate := WorkDate();
        WorkDate(20260101D);
        Seed();
        Texts.Add('T');
        Texts.Add('t');
        Texts.Add('W');
        Texts.Add('w');
        Texts.Add('T..');
        Texts.Add('..T');
        Texts.Add('W..');
        Texts.Add('..W');
        Texts.Add('T|W');
        Texts.Add('<>W');
        Texts.Add('>W');
        Texts.Add('<=W');
        Texts.Add('W..T');
        Texts.Add('T..W');
        ObserveList(Observer, Texts, 'k');
        WorkDate(SavedWorkDate);
        Observer.Finish();
    end;

    [Test]
    procedure SetFilter_Date_OtherKeywordLetters()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
        SavedWorkDate: Date;
    begin
        SavedWorkDate := WorkDate();
        WorkDate(20260101D);
        Seed();
        Texts.Add('TODAY');
        Texts.Add('Today');
        Texts.Add('WORKDATE');
        Texts.Add('M');
        Texts.Add('Y');
        Texts.Add('D');
        Texts.Add('CM');
        Texts.Add('CY');
        Texts.Add('CW');
        Texts.Add('-1D');
        Texts.Add('+1D');
        Texts.Add('T-1D');
        Texts.Add('1D');
        ObserveList(Observer, Texts, 'o');
        WorkDate(SavedWorkDate);
        Observer.Finish();
    end;

    [Test]
    procedure SetFilter_Date_Placeholders_TwoDates()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('range', Apply2('%1..%2', 20260101D, 20260102D));
        Observer.Observe('range_reversed', Apply2('%1..%2', 20260102D, 20260101D));
        Observer.Observe('range_same', Apply2('%1..%2', 20260101D, 20260101D));
        Observer.Observe('range_zero_first', Apply2('%1..%2', 0D, 20260101D));
        Observer.Observe('range_zero_second', Apply2('%1..%2', 20260101D, 0D));
        Observer.Observe('range_both_zero', Apply2('%1..%2', 0D, 0D));
        Observer.Observe('or', Apply2('%1|%2', 20251231D, 20260201D));
        Observer.Observe('and', Apply2('>%1&<%2', 20251231D, 20260201D));
        Observer.Observe('swapped_placeholders', Apply2('%2..%1', 20260101D, 20260102D));
        Observer.Observe('only_second', Apply2('%2', 20260101D, 20260102D));
        Observer.Observe('only_first_extra_arg', Apply2('%1', 20260101D, 20260102D));
        Observer.Observe('no_placeholder_extra_args', Apply2('010126', 20260102D, 20260201D));
        Observer.Observe('not_equal', Apply2('<>%1&<>%2', 20260101D, 20260102D));
        Observer.Observe('repeated', Apply2('%1|%1', 20260101D, 20260102D));
        Observer.Finish();
    end;

    [Test]
    procedure SetFilter_Date_Placeholders_OneDate()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('eq', Apply1('%1', 20260101D));
        Observer.Observe('ge', Apply1('%1..', 20260101D));
        Observer.Observe('le', Apply1('..%1', 20260101D));
        Observer.Observe('lt', Apply1('<%1', 20260101D));
        Observer.Observe('gt', Apply1('>%1', 20260101D));
        Observer.Observe('ne', Apply1('<>%1', 20260101D));
        Observer.Observe('zero', Apply1('%1', 0D));
        Observer.Observe('ge_zero', Apply1('%1..', 0D));
        Observer.Observe('ne_zero', Apply1('<>%1', 0D));
        Observer.Observe('missing_second_arg', Apply1('%1..%2', 20260101D));
        Observer.Observe('placeholder_3', Apply1('%3', 20260101D));
        Observer.Observe('placeholder_0', Apply1('%0', 20260101D));
        Observer.Observe('percent_alone', Apply1('%', 20260101D));
        Observer.Observe('undefined_date', Apply1('%1', 99991231D));
        Observer.Observe('closing_date', Apply1('%1', ClosingDate(20260101D)));
        Observer.Observe('normal_of_closing', Apply1('%1', NormalDate(ClosingDate(20260101D))));
        Observer.Finish();
    end;

    [Test]
    procedure SetFilter_Date_InvalidTexts()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
    begin
        Seed();
        Texts.Add('abc');
        Texts.Add('13132026');
        Texts.Add('32012026');
        Texts.Add('00012026');
        Texts.Add('31022026');
        Texts.Add('01012026..abc');
        Texts.Add('abc..01012026');
        Texts.Add('..abc');
        Texts.Add('|');
        Texts.Add('&');
        Texts.Add('01012026||020126');
        Texts.Add('(01012026)');
        Texts.Add('99999999');
        Texts.Add('01-01-2026');
        Texts.Add('A..B');
        Texts.Add('*');
        Texts.Add('01012026 ');
        Texts.Add(' 01012026');
        Texts.Add('0101202');
        Texts.Add('010126...020126');
        ObserveList(Observer, Texts, 'i');
        Observer.Finish();
    end;

    [Test]
    procedure SetFilter_Date_InvalidKeepsOldFilter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 DF";
    begin
        Seed();
        Row.SetFilter(D, '010126..020126');
        Observer.Observe('before', Row.GetFilter(D));
        if TryFilter(Row, 'abc') then
            Observer.Observe('apply_abc', 'no error')
        else
            Observer.Observe('apply_abc', Failed());
        Observer.Observe('after_invalid', Row.GetFilter(D));
        Observer.Observe('count_after_invalid', Format(Row.Count()));
        Row.SetFilter(D, '');
        Observer.Observe('after_empty', Row.GetFilter(D));
        Observer.Observe('has_filter_after_empty', Format(Row.GetFilter(D) <> ''));
        Observer.Finish();
    end;

    [Test]
    procedure SetFilter_Date_GetRangeAndFilterText()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 DF";
    begin
        Seed();
        Row.SetFilter(D, '010126..020126');
        Observer.Observe('range_min', Format(Row.GetRangeMin(D)));
        Observer.Observe('range_max', Format(Row.GetRangeMax(D)));
        Observer.Observe('filter', Row.GetFilter(D));
        Observer.Observe('filters', Row.GetFilters());
        Row.SetFilter(D, '%1|%2', 20260101D, 20260201D);
        Observer.Observe('or_filter', Row.GetFilter(D));
        Row.SetFilter(D, '01012026');
        Observer.Observe('single_filter', Row.GetFilter(D));
        Observer.Observe('single_min', Format(Row.GetRangeMin(D)));
        Observer.Observe('single_max', Format(Row.GetRangeMax(D)));
        Observer.Observe('single_count', Format(Row.Count()));
        Row.SetRange(D, 20260101D, 20260102D);
        Observer.Observe('setrange_filter', Row.GetFilter(D));
        Row.SetRange(D, 0D);
        Observer.Observe('setrange_zero_filter', Row.GetFilter(D));
        Observer.Observe('setrange_zero_count', Format(Row.Count()));
        Row.SetRange(D, 20260102D, 20260101D);
        Observer.Observe('setrange_reversed_filter', Row.GetFilter(D));
        Observer.Observe('setrange_reversed_count', Format(Row.Count()));
        Observer.Finish();
    end;
}
