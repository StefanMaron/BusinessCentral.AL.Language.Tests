// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-round-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Corpus issue 659 item 5 (from al-runtime-rs #254): Round(Duration, Precision [, Direction]) for zero, positive and negative durations, several
// precisions and directions, and the type of the result.

codeunit 80980 "BC Round Duration"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryRound(D: Duration; Precision: Decimal; Direction: Text; var R: Decimal)
    begin
        if Direction = '' then
            R := Round(D, Precision)
        else
            R := Round(D, Precision, Direction);
    end;

    local procedure Rnd(D: Duration; Precision: Decimal; Direction: Text): Text
    var
        R: Decimal;
    begin
        if TryRound(D, Precision, Direction, R) then
            exit(Format(R, 0, 9));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryRoundToDuration(D: Duration; Precision: Decimal; var R: Duration)
    begin
        R := Round(D, Precision);
    end;

    local procedure RndDur(D: Duration; Precision: Decimal): Text
    var
        R: Duration;
    begin
        if TryRoundToDuration(D, Precision, R) then
            exit(Format(R) + ' = ' + Format(R, 0, 9));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Row(D: Duration): Text
    begin
        exit(Rnd(D, 1, '') + ' ; ' + Rnd(D, 1000, '') + ' ; ' + Rnd(D, 1000, '<') + ' ; ' + Rnd(D, 1000, '>') + ' ; ' + Rnd(D, 1000, '=') + ' ; ' + Rnd(D, 0.5, '') + ' ; ' + Rnd(D, 60000, ''));
    end;

    [Test]
    procedure Round_Zero_Duration_Repro()
    var
        Value: Duration;
    begin
        // The repro of al-runtime-rs #254.
        if Round(Value, 1) <> 0 then
            Error('The rounded duration differs from zero.');
    end;

    [Test]
    procedure Round_Durations_PrecisionsAndDirections()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
    begin
        // Each row: precision 1 ; 1000 ; 1000 '<' ; 1000 '>' ; 1000 '=' ; 0.5 ; 60000.
        Observer.Observe('zero', Row(D));
        D := 1500;
        Observer.Observe('1500', Row(D));
        D := 2500;
        Observer.Observe('2500', Row(D));
        D := -1500;
        Observer.Observe('-1500', Row(D));
        D := -2500;
        Observer.Observe('-2500', Row(D));
        D := 1234567;
        Observer.Observe('1234567', Row(D));
        D := 1;
        Observer.Observe('1', Row(D));
        Observer.Finish();
    end;

    [Test]
    procedure Round_Duration_DefaultPrecision_And_Errors()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
    begin
        D := 1499;
        Observer.Observe('no precision 1499', Format(Round(D), 0, 9));
        D := 1500;
        Observer.Observe('no precision 1500', Format(Round(D), 0, 9));
        Observer.Observe('precision 0', Rnd(D, 0, ''));
        Observer.Observe('precision -1000', Rnd(D, -1000, ''));
        Observer.Observe('direction x', Rnd(D, 1000, 'x'));
        Observer.Finish();
    end;

    [Test]
    procedure Round_Duration_ResultType()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
        Dec: Decimal;
        V: Variant;
    begin
        D := 2500;
        V := Round(D, 1000);
        Observer.Observe('is decimal', Format(V.IsDecimal()));
        Observer.Observe('is duration', Format(V.IsDuration()));
        Observer.Observe('is integer', Format(V.IsInteger()));
        Observer.Observe('is biginteger', Format(V.IsBigInteger()));
        Dec := Round(D, 1000);
        Observer.Observe('as decimal', Format(Dec, 0, 9));
        Observer.Observe('to duration 2500 by 1000', RndDur(D, 1000));
        Observer.Observe('to duration 2500 by 1', RndDur(D, 1));
        D := 1;
        Observer.Observe('to duration 1 by 0.3', RndDur(D, 0.3));
        D := -3723004;
        Observer.Observe('to duration -3723004 by 60000', RndDur(D, 60000));
        Observer.Finish();
    end;
}
