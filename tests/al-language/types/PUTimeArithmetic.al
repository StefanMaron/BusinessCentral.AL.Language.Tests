// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/time-data-type
// Scope: in-scope
// Probe: written against a real BC 27.5 service tier and run on BC 29.0.54011.55816; every literal below is what those tiers produced.
//
// Time +/- Integer (the Integer is milliseconds): 12:00:00 - 1000 gives 11:59:59, + 1000 gives 12:00:01, - 1500 gives 11:59:58.5; the result wraps around midnight (23:59:59.999 + 1 ms is
// 00:00:00, 23:59:59 + 2000 ms is 00:00:01, 00:00:01 - 2000 ms is 23:59:59, a whole day or more adds modulo 24 hours); an UNDEFINED time (0T) cannot be added to or subtracted from:
// "Adding to an undefined (0T) time." / "Subtracting from an undefined (0T) time." with the code InvalidTime. Time - Time is a Duration in milliseconds (later minus earlier positive, the
// reverse negative). A Decimal with a fraction as the second operand raises the Decimal to Integer conversion error (see types/PRDecimalToInteger.al).
// Fixtures used: self-contained codeunit 69337
// BC versions: 27.5, 29.0

codeunit 69337 "PU Time Arithmetic Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryMinusInt(T: Time; Millis: Integer; var Result: Text)
    begin
        Result := Format(T - Millis, 0, 9);
    end;

    [TryFunction]
    local procedure TryPlusInt(T: Time; Millis: Integer; var Result: Text)
    begin
        Result := Format(T + Millis, 0, 9);
    end;

    local procedure Outcome(Ok: Boolean; Value: Text): Text
    begin
        if Ok then
            exit('ok:' + Value);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Time_PlusMinusInteger_Values()
    var
        T: Time;
        Result: Text;
        Observer: Codeunit "Probe Observer";
    begin
        T := 120000T;
        Observer.Observe('minus_1000', Outcome(TryMinusInt(T, 1000, Result), Result));
        Observer.Observe('plus_1000', Outcome(TryPlusInt(T, 1000, Result), Result));
        Observer.Observe('minus_zero', Outcome(TryMinusInt(T, 0, Result), Result));
        Observer.Observe('minus_negative', Outcome(TryMinusInt(T, -1000, Result), Result));
        Observer.Observe('minus_1500_ms', Outcome(TryMinusInt(T, 1500, Result), Result));
        Observer.Expect('minus_1000', 'ok:11:59:59');
        Observer.Expect('plus_1000', 'ok:12:00:01');
        Observer.Expect('minus_zero', 'ok:12:00:00');
        Observer.Expect('minus_negative', 'ok:12:00:01');
        Observer.Expect('minus_1500_ms', 'ok:11:59:58.5');
        Observer.Verify();
    end;

    [Test]
    procedure Time_PlusMinusInteger_PastMidnight()
    var
        T: Time;
        Result: Text;
        Observer: Codeunit "Probe Observer";
    begin
        T := 235959T;
        Observer.Observe('plus_2000_ms_past_midnight', Outcome(TryPlusInt(T, 2000, Result), Result));
        T := 000001T;
        Observer.Observe('minus_2000_ms_before_midnight', Outcome(TryMinusInt(T, 2000, Result), Result));
        T := 235959.999T;
        Observer.Observe('plus_one_ms_at_end_of_day', Outcome(TryPlusInt(T, 1, Result), Result));
        T := 0T;
        Observer.Observe('minus_one_ms_at_zero', Outcome(TryMinusInt(T, 1, Result), Result));
        T := 120000T;
        Observer.Observe('plus_a_whole_day', Outcome(TryPlusInt(T, 86400000, Result), Result));
        Observer.Observe('plus_more_than_a_day', Outcome(TryPlusInt(T, 90000000, Result), Result));
        Observer.Expect('plus_2000_ms_past_midnight', 'ok:00:00:01');
        Observer.Expect('minus_2000_ms_before_midnight', 'ok:23:59:59');
        Observer.Expect('plus_one_ms_at_end_of_day', 'ok:00:00:00');
        Observer.Expect('minus_one_ms_at_zero', 'error:Adding to an undefined (0T) time.|InvalidTime');
        Observer.Expect('plus_a_whole_day', 'ok:12:00:00');
        Observer.Expect('plus_more_than_a_day', 'ok:13:00:00');
        Observer.Verify();
    end;

    [Test]
    procedure Time_MinusTime_IsDuration()
    var
        A: Time;
        B: Time;
        D: Duration;
        Observer: Codeunit "Probe Observer";
    begin
        A := 130000T;
        B := 120000T;
        D := A - B;
        Observer.Observe('later_minus_earlier_ms', Format(D, 0, 9));
        Observer.Observe('later_minus_earlier_text', Format(D));
        D := B - A;
        Observer.Observe('earlier_minus_later_ms', Format(D, 0, 9));
        D := A - A;
        Observer.Observe('same_minus_same', Format(D, 0, 9));
        asserterror Observer.Observe('undefined_minus_time', Format(0T - B, 0, 9));
        Observer.ObserveError('undefined_minus_time');
        Observer.Expect('later_minus_earlier_ms', 'P0DT1H0M0.0S');
        Observer.Expect('later_minus_earlier_text', '1 hour');
        Observer.Expect('earlier_minus_later_ms', '-P0DT1H0M0.0S');
        Observer.Expect('same_minus_same', 'P0DT0H0M0.0S');
        Observer.Expect('undefined_minus_time|text', 'Subtracting from an undefined (0T) time.');
        Observer.Expect('undefined_minus_time|code', 'InvalidTime');
        Observer.Verify();
    end;

    [Test]
    procedure Time_PlusDuration_AndComparison()
    var
        T: Time;
        D: Duration;
        Observer: Codeunit "Probe Observer";
    begin
        T := 120000T;
        D := 3600000;
        Observer.Observe('plus_duration', Format(T + D, 0, 9));
        Observer.Observe('minus_duration', Format(T - D, 0, 9));
        asserterror Observer.Observe('plus_decimal', Format(T + 1500.5, 0, 9));
        Observer.ObserveError('plus_decimal');
        Observer.Expect('plus_duration', '13:00:00');
        Observer.Expect('minus_duration', '11:00:00');
        Observer.Expect('plus_decimal|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1500.5 to System.Int32.');
        Observer.Expect('plus_decimal|code', 'ConversionCast');
        Observer.Verify();
    end;
}
