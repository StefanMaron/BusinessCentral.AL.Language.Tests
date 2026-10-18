// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 70316 "LT P81 DF" (record/lt-loadfields-pagesource-validate/P81DateFilters.al)
// Probe: the date filter letters TODAY, WORKDATE, M, Y, D, CM, CY, CW, -1D, +1D, T-1D and 1D set with Record.SetFilter, each under five fixed work dates, so
// that the filter text shows which letters follow the work date and which follow Today(). Moved here from P81DateFilters.al (test
// SetFilter_Date_OtherKeywordLetters, which asserted dates of the day it was written). Object id 78000.

codeunit 78000 "LT AD Date Filter Letters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Base: Date)
    var
        Row: Record "LT P81 DF";
    begin
        Row.DeleteAll();
        AddRow('Z0', 0D);
        AddRow('P7', Base - 7);
        AddRow('P1', Base - 1);
        AddRow('P0', Base);
        AddRow('N1', Base + 1);
        AddRow('N7', Base + 7);
        AddRow('MS', CalcDate('<-CM>', Base));
        AddRow('ME', CalcDate('<CM>', Base));
        AddRow('YE', CalcDate('<CY>', Base));
    end;

    local procedure SeedOriginal()
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

    local procedure Scrub(Txt: Text): Text
    begin
        exit(Txt.Replace(Format(Today()), '<today>').Replace(Format(WorkDate()), '<workdate>'));
    end;

    local procedure Apply(Txt: Text): Text
    var
        Row: Record "LT P81 DF";
        Codes: Text;
    begin
        if TryFilter(Row, Txt) then begin
            if Row.FindSet() then
                repeat
                    Codes += Row.Code + ',';
                until Row.Next() = 0;
            exit('ok|filter=' + Scrub(Row.GetFilter(D)) + '|rows=' + Codes);
        end;
        exit('error:' + Scrub(GetLastErrorText()) + '|' + GetLastErrorCode());
    end;

    local procedure ObserveLetters(var Observer: Codeunit "Probe Observer"; Prefix: Text; Part: Integer)
    var
        Texts: List of [Text];
        i: Integer;
    begin
        if Part = 1 then begin
            Texts.Add('TODAY');
            Texts.Add('Today');
            Texts.Add('WORKDATE');
            Texts.Add('M');
            Texts.Add('Y');
            Texts.Add('D');
            Texts.Add('CM');
        end else begin
            Texts.Add('CY');
            Texts.Add('CW');
            Texts.Add('-1D');
            Texts.Add('+1D');
            Texts.Add('T-1D');
            Texts.Add('1D');
        end;
        for i := 1 to Texts.Count() do
            Observer.Observe(Prefix + Texts.Get(i), Apply(Texts.Get(i)));
    end;

    local procedure RunFor(var Observer: Codeunit "Probe Observer"; WorkDay: Date; Part: Integer)
    var
        SavedWorkDate: Date;
    begin
        SavedWorkDate := WorkDate();
        WorkDate(WorkDay);
        Seed(WorkDay);
        ObserveLetters(Observer, 'w' + Format(WorkDay, 0, '<Year4>-<Month,2>-<Day,2>') + ' ', Part);
        WorkDate(SavedWorkDate);
    end;

    local procedure RunOriginal(var Observer: Codeunit "Probe Observer"; Part: Integer)
    var
        SavedWorkDate: Date;
    begin
        SavedWorkDate := WorkDate();
        WorkDate(20260101D);
        SeedOriginal();
        ObserveLetters(Observer, 'o ', Part);
        WorkDate(SavedWorkDate);
    end;

    [Test]
    procedure Letters_Original_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunOriginal(Observer, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Letters_Original_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunOriginal(Observer, 2);
        Observer.Finish();
    end;

    [Test]
    procedure Letters_March18_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFor(Observer, 20260318D, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Letters_March18_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFor(Observer, 20260318D, 2);
        Observer.Finish();
    end;

    [Test]
    procedure Letters_July1_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFor(Observer, 20260701D, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Letters_July1_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFor(Observer, 20260701D, 2);
        Observer.Finish();
    end;

    [Test]
    procedure Letters_Dec31_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFor(Observer, 20261231D, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Letters_Dec31_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFor(Observer, 20261231D, 2);
        Observer.Finish();
    end;

    [Test]
    procedure Letters_2030_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFor(Observer, 20300515D, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Letters_2030_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFor(Observer, 20300515D, 2);
        Observer.Finish();
    end;

    [Test]
    procedure Letters_Today()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('today', Format(Today(), 0, '<Year4>-<Month,2>-<Day,2>'));
        Observer.Observe('today_weekday', Format(Today(), 0, '<Weekday Text>'));
        Observer.Finish();
    end;
}
