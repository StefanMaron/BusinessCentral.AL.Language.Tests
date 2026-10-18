// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-calcdate-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: CalcDate with a signed working-day unit (+1WD, -1WD, with and without angle brackets) and with the percent forms <%Q> and <%Y>, for
// a Friday, a Saturday, a Sunday, a Monday, the end of a quarter, the end of a year and a mid-quarter date; the result or the error text and code.
// Object id 78001.

codeunit 78001 "LT AD Date Formula Signed WD"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryCalc(Formula: Text; D: Date; var Result: Date)
    begin
        Result := CalcDate(Formula, D);
    end;

    local procedure Calc(Formula: Text; D: Date): Text
    var
        Result: Date;
    begin
        ClearLastError();
        if TryCalc(Formula, D, Result) then
            exit('ok:' + Format(Result, 0, '<Year4>-<Month,2>-<Day,2>'));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ObserveFormula(var Observer: Codeunit "Probe Observer"; Formula: Text)
    begin
        Observer.Observe(Formula + ' fri', Calc(Formula, 20240112D));
        Observer.Observe(Formula + ' sat', Calc(Formula, 20240113D));
        Observer.Observe(Formula + ' sun', Calc(Formula, 20240114D));
        Observer.Observe(Formula + ' mon', Calc(Formula, 20240115D));
        Observer.Observe(Formula + ' q-end', Calc(Formula, 20240331D));
        Observer.Observe(Formula + ' y-end', Calc(Formula, 20241231D));
        Observer.Observe(Formula + ' mid', Calc(Formula, 20260518D));
    end;

    [Test]
    procedure SignedWD_Plus()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveFormula(Observer, '+1WD');
        ObserveFormula(Observer, '<+1WD>');
        Observer.Finish();
    end;

    [Test]
    procedure SignedWD_Minus()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveFormula(Observer, '-1WD');
        ObserveFormula(Observer, '<-1WD>');
        Observer.Finish();
    end;

    [Test]
    procedure Percent_Quarter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveFormula(Observer, '<%Q>');
        ObserveFormula(Observer, '%Q');
        Observer.Finish();
    end;

    [Test]
    procedure Percent_Year()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveFormula(Observer, '<%Y>');
        ObserveFormula(Observer, '%Y');
        Observer.Finish();
    end;
}
