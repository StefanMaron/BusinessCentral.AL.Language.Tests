// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-calcdate-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: date formula texts at the edge of the grammar, from the anchor date 15 January 2024 (a Monday): %N placeholders (<+%2D>, <+%1M>, +%1D>, <-%1D>),
// other signs and digit counts (<+D>, <+5>, <5>), a missing closing bracket (<+6W, <-1D, <+1M), W and WD units (W, 2WD, <1WD>), and the texts 01/01/26, Y
// and 8D+<1D>; each through CalcDate and through Evaluate into a DateFormula (the stored formula and the CalcDate with it).
// Settles: date-formula-evaluate-percent-placeholder, calcdate-closing-bracket-missing-after-plus. Object id 67857.

codeunit 67857 "LT Date Formula Edges"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryCalc(Formula: Text; var Result: Text)
    begin
        Result := Format(CalcDate(Formula, 20240115D), 0, 9);
    end;

    [TryFunction]
    local procedure TryEvaluate(Formula: Text; var Stored: Text; var Calculated: Text)
    var
        DF: DateFormula;
    begin
        Evaluate(DF, Formula);
        Stored := Format(DF);
        Calculated := Format(CalcDate(DF, 20240115D), 0, 9);
    end;

    local procedure Calc(Formula: Text): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TryCalc(Formula, Result) then
            exit('ok:' + Result);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Eval(Formula: Text): Text
    var
        Stored: Text;
        Calculated: Text;
    begin
        ClearLastError();
        if TryEvaluate(Formula, Stored, Calculated) then
            exit('ok:stored=' + Stored + '|calc=' + Calculated);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Both(var Observer: Codeunit "Probe Observer"; Formula: Text)
    begin
        Observer.Observe('calc ' + Formula, Calc(Formula));
        Observer.Observe('eval ' + Formula, Eval(Formula));
    end;

    [Test]
    procedure Placeholders_PercentN()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, '<+%2D>');
        Both(Observer, '<+%1M>');
        Both(Observer, '+%1D>');
        Both(Observer, '<-%1D>');
        Both(Observer, '<+%1D>');
        Both(Observer, '<+%2W>');
        Both(Observer, '+%1D');
        Both(Observer, '%1D');
        Both(Observer, '<%1D>');
        Both(Observer, '<+%D>');
        Both(Observer, '<+%0D>');
        Observer.Finish();
    end;

    [Test]
    procedure SignsAndDigits_ErrorTexts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, '<+D>');
        Both(Observer, '<-D>');
        Both(Observer, '<D>');
        Both(Observer, '<+5>');
        Both(Observer, '<5>');
        Both(Observer, '<+0D>');
        Both(Observer, '<+10D>');
        Both(Observer, '<+123D>');
        Both(Observer, '<++1D>');
        Both(Observer, '<+-1D>');
        Observer.Finish();
    end;

    [Test]
    procedure ClosingBracket_MissingAfterPlus()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, '<+6W');
        Both(Observer, '<-1D');
        Both(Observer, '<+1M');
        Both(Observer, '<1D');
        Both(Observer, '1D>');
        Both(Observer, '<1D>>');
        Both(Observer, '<<1D>');
        Both(Observer, '<>');
        Both(Observer, '<');
        Both(Observer, '');
        Observer.Finish();
    end;

    [Test]
    procedure WeekAndWeekdayUnits()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, 'W');
        Both(Observer, '2WD');
        Both(Observer, '<W>');
        Both(Observer, '<2WD>');
        Both(Observer, '<1WD>');
        Both(Observer, '<WD>');
        Both(Observer, '<+1W>');
        Both(Observer, '<CW>');
        Both(Observer, '<-CW>');
        Both(Observer, '<1WD+1D>');
        Observer.Finish();
    end;

    [Test]
    procedure TextsFromTheTestLibraries()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, '01/01/26');
        Both(Observer, 'Y');
        Both(Observer, '<Y>');
        Both(Observer, '8D+<1D>');
        Both(Observer, '<8D+<1D>>');
        Both(Observer, '<8D>+<1D>');
        Both(Observer, '1Y+1M');
        Both(Observer, '<1Y+1M>');
        Observer.Finish();
    end;
}
