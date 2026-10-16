// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/datetime/datetime-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: DateTime.Date, Time, ToText for 0DT and a value with milliseconds, Time.ToText and Duration.ToText
// BC versions: 29 (27 and 28 by CI)

codeunit 70321 "LT P93 DateTime"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryDT(Dt: DateTime; Mode: Integer; var R: Text)
    begin
        case Mode of
            0:
                R := Format(Dt.Date());
            1:
                R := Format(Dt.Time());
            2:
                R := Dt.ToText();
            3:
                R := Dt.ToText(true);
            4:
                R := Dt.ToText(false);
            5:
                R := Format(Dt.Date(), 0, 9);
            6:
                R := Format(Dt.Time(), 0, 9);
        end;
    end;

    [TryFunction]
    local procedure TryTime(T: Time; Mode: Integer; var R: Text)
    begin
        case Mode of
            0:
                R := T.ToText();
            1:
                R := T.ToText(true);
            2:
                R := T.ToText(false);
        end;
    end;

    [TryFunction]
    local procedure TryDur(D: Duration; Mode: Integer; var R: Text)
    begin
        case Mode of
            0:
                R := D.ToText();
            1:
                R := D.ToText(true);
            2:
                R := D.ToText(false);
        end;
    end;

    local procedure DT(V: DateTime; Mode: Integer): Text
    var
        R: Text;
    begin
        if TryDT(V, Mode, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure TM(V: Time; Mode: Integer): Text
    var
        R: Text;
    begin
        if TryTime(V, Mode, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure DU(V: Duration; Mode: Integer): Text
    var
        R: Text;
    begin
        if TryDur(V, Mode, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure DateTime_Zero()
    var
        Observer: Codeunit "Probe Observer";
        V: DateTime;
    begin
        Observer.Observe('date', DT(V, 0));
        Observer.Observe('time', DT(V, 1));
        Observer.Observe('tt', DT(V, 2));
        Observer.Observe('tt-true', DT(V, 3));
        Observer.Observe('tt-false', DT(V, 4));
        Observer.Observe('date-9', DT(V, 5));
        Observer.Observe('time-9', DT(V, 6));
        Observer.Observe('format', Format(V));
        Observer.Observe('format-9', Format(V, 0, 9));
        Observer.Observe('lit-date', DT(0DT, 0));
        Observer.Observe('lit-time', DT(0DT, 1));
        Observer.Observe('lit-tt', DT(0DT, 2));
        Observer.Finish();
    end;

    [Test]
    procedure DateTime_Millis()
    var
        Observer: Codeunit "Probe Observer";
        V: DateTime;
    begin
        V := CreateDateTime(20240315D, 123456T) + 789;
        Observer.Observe('date', DT(V, 0));
        Observer.Observe('time', DT(V, 1));
        Observer.Observe('tt', DT(V, 2));
        Observer.Observe('tt-true', DT(V, 3));
        Observer.Observe('tt-false', DT(V, 4));
        Observer.Observe('date-9', DT(V, 5));
        Observer.Observe('time-9', DT(V, 6));
        Observer.Observe('format', Format(V));
        Observer.Observe('format-9', Format(V, 0, 9));
        Observer.Observe('format-0', Format(V, 0, 0));
        Observer.Observe('format-1', Format(V, 0, 1));
        Observer.Observe('format-custom', Format(V, 0, '<Year4>-<Month,2>-<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>'));
        Observer.Finish();
    end;

    [Test]
    procedure DateTime_NoMillis_AndClosing()
    var
        Observer: Codeunit "Probe Observer";
        V: DateTime;
        W: DateTime;
    begin
        V := CreateDateTime(20240229D, 120000T);
        W := CreateDateTime(20231231D, 120000T);
        Observer.Observe('feb29-date', DT(V, 0));
        Observer.Observe('feb29-time', DT(V, 1));
        Observer.Observe('feb29-tt', DT(V, 2));
        Observer.Observe('feb29-tt-true', DT(V, 3));
        Observer.Observe('feb29-format-9', Format(V, 0, 9));
        Observer.Observe('dec31-date', DT(W, 0));
        Observer.Observe('dec31-time', DT(W, 1));
        Observer.Observe('dec31-tt', DT(W, 2));
        Observer.Observe('dec31-tt-true', DT(W, 3));
        Observer.Observe('dec31-format-9', Format(W, 0, 9));
        Observer.Observe('closing-date', DT(CreateDateTime(ClosingDate(20231231D), 120000T), 0));
        Observer.Observe('dateonly', DT(CreateDateTime(20240315D, 0T), 1));
        asserterror Observer.Observe('timeonly', DT(CreateDateTime(0D, 123456T), 0));
        Observer.ObserveError('af151');
        Observer.Finish();
    end;

    [Test]
    procedure Time_ToText()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
    begin
        Observer.Observe('zero', TM(T, 0));
        Observer.Observe('zero-true', TM(T, 1));
        Observer.Observe('zero-false', TM(T, 2));
        Observer.Observe('zero-format', Format(T));
        Observer.Observe('zero-format-9', Format(T, 0, 9));
        T := 123456T;
        Observer.Observe('t', TM(T, 0));
        Observer.Observe('t-true', TM(T, 1));
        Observer.Observe('t-false', TM(T, 2));
        Observer.Observe('t-format', Format(T));
        Observer.Observe('t-format-9', Format(T, 0, 9));
        T := 235959T;
        Observer.Observe('late', TM(T, 0));
        Observer.Observe('late-true', TM(T, 1));
        T := 000000T + 123;
        Observer.Observe('ms', TM(T, 0));
        Observer.Observe('ms-true', TM(T, 1));
        Observer.Observe('ms-format', Format(T));
        Observer.Observe('ms-format-9', Format(T, 0, 9));
        T := 120000T;
        Observer.Observe('noon', TM(T, 0));
        Observer.Observe('noon-true', TM(T, 1));
        Observer.Finish();
    end;

    [Test]
    procedure Duration_ToText()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
    begin
        Observer.Observe('zero', DU(D, 0));
        Observer.Observe('zero-true', DU(D, 1));
        Observer.Observe('zero-false', DU(D, 2));
        Observer.Observe('zero-format', Format(D));
        D := 1000;
        Observer.Observe('1s', DU(D, 0));
        Observer.Observe('1s-true', DU(D, 1));
        Observer.Observe('1s-format', Format(D));
        Observer.Observe('1s-format-9', Format(D, 0, 9));
        D := 3661000;
        Observer.Observe('1h1m1s', DU(D, 0));
        Observer.Observe('1h1m1s-true', DU(D, 1));
        Observer.Observe('1h1m1s-format-9', Format(D, 0, 9));
        D := 172800000;
        Observer.Observe('2d', DU(D, 0));
        Observer.Observe('2d-true', DU(D, 1));
        Observer.Observe('2d-format-9', Format(D, 0, 9));
        D := -5000;
        Observer.Observe('neg', DU(D, 0));
        Observer.Observe('neg-true', DU(D, 1));
        Observer.Observe('neg-format-9', Format(D, 0, 9));
        D := 1;
        Observer.Observe('1ms', DU(D, 0));
        Observer.Observe('1ms-true', DU(D, 1));
        Observer.Finish();
    end;
}
