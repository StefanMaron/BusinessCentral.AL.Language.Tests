// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/duration/duration-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Facts: a Duration divided by an Integer, a Decimal and a BigInteger into a Decimal and into a Duration, Format(D / Dec), a zero Decimal
//   divisor; Format(D * 1.5, 0, 9) and Format(D / 2.5, 0, 9); a Decimal of 1E19 assigned to a Duration; a Date assigned to a DateTime
//   through a Variant (defined, blank, closing date); Time plus and minus a BigInteger.
// BC versions: 27.5+

codeunit 80424 "LT AX Duration DateTime"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryDivDec(D: Duration; Divisor: Decimal; var Result: Decimal)
    begin
        Result := D / Divisor;
    end;

    [Test]
    procedure Duration_DividedBy_IntegerAndDecimal()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
        Dec: Decimal;
        Divisor: Decimal;
    begin
        D := 26820000;
        Dec := D / 60000;
        Observer.Observe('26820000/60000', Format(Dec, 0, 9));
        D := 30000;
        Dec := D / 60000;
        Observer.Observe('30000/60000', Format(Dec, 0, 9));
        Divisor := 60000;
        D := 26820000;
        Dec := D / Divisor;
        Observer.Observe('26820000/Dec60000', Format(Dec, 0, 9));
        Observer.Observe('Format(D/Dec)', Format(D / Divisor));
        D := 30000;
        Observer.Observe('Format(30000/Dec)', Format(D / Divisor));
        Divisor := 7;
        Observer.Observe('Format(30000/Dec7)', Format(D / Divisor));
        Observer.Finish();
    end;

    [Test]
    procedure Duration_DividedBy_ZeroDecimal()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
        Dec: Decimal;
    begin
        D := 26820000;
        Dec := 42;
        if TryDivDec(D, 0, Dec) then
            Observer.Observe('zero', 'no error|' + Format(Dec, 0, 9))
        else begin
            Observer.ObserveError('zero');
            Observer.Observe('after', Format(Dec, 0, 9));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Duration_MulDiv_Decimal_Format9()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
    begin
        D := 90000;
        Observer.Observe('90000*1.5', Format(D * 1.5, 0, 9));
        Observer.Observe('90000/2.5', Format(D / 2.5, 0, 9));
        D := 7;
        Observer.Observe('7*1.5', Format(D * 1.5, 0, 9));
        Observer.Observe('7/2.5', Format(D / 2.5, 0, 9));
        Observer.Observe('7*1.5 plain', Format(D * 1.5));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryDurDivBig(D: Duration; B: BigInteger; var Result: Duration)
    begin
        Result := D / B;
    end;

    [TryFunction]
    local procedure TryDurFromDec(Dec: Decimal; var Result: Duration)
    begin
        Result := Dec;
    end;

    [Test]
    procedure Duration_IntoDecimal_And_BigInteger()
    var
        Observer: Codeunit "Probe Observer";
        D1: Duration;
        D: Duration;
        Dec: Decimal;
        B: BigInteger;
    begin
        D1 := 90000;
        Dec := D1 / 7;
        Observer.Observe('dec D1/7', Format(Dec, 0, 9));
        B := 7;
        Dec := D1 / B;
        Observer.Observe('dec D1/big7', Format(Dec, 0, 9));
        B := 4;
        D := 1;
        if TryDurDivBig(D1, B, D) then
            Observer.Observe('dur D1/big4', Format(D, 0, 9))
        else
            Observer.ObserveError('dur D1/big4');
        B := 7;
        D := 1;
        if TryDurDivBig(D1, B, D) then
            Observer.Observe('dur D1/big7', Format(D, 0, 9))
        else begin
            Observer.ObserveError('dur D1/big7');
            Observer.Observe('dur after', Format(D, 0, 9));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Duration_FromDecimal_1E19()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
        Dec: Decimal;
    begin
        Dec := 10000000000000000000.0;
        D := 1;
        if TryDurFromDec(Dec, D) then
            Observer.Observe('1E19', Format(D, 0, 9))
        else begin
            Observer.ObserveError('1E19');
            Observer.Observe('after', Format(D, 0, 9));
        end;
        Dec := 1500.5;
        if TryDurFromDec(Dec, D) then
            Observer.Observe('1500.5', Format(D, 0, 9))
        else
            Observer.ObserveError('1500.5');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryDateToDateTime(D: Date; var DT: DateTime)
    var
        V: Variant;
    begin
        // DT := D does not compile (AL0122, must-not-compile case 1193): the date goes through a Variant.
        V := D;
        DT := V;
    end;

    local procedure DateToDT(D: Date): Text
    var
        DT: DateTime;
    begin
        DT := 0DT;
        if not TryDateToDateTime(D, DT) then
            exit('error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        exit(Format(DT, 0, 9) + '|same as CreateDateTime ' + Format(DT = CreateDateTime(D, 0T)) + '|0DT ' + Format(DT = 0DT));
    end;

    [Test]
    procedure Date_AssignedTo_DateTime()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := DMY2Date(15, 3, 2024);
        Observer.Observe('defined', DateToDT(D));
        Observer.Observe('blank', DateToDT(0D));
        Observer.Observe('closing', DateToDT(ClosingDate(D)));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryTimeMinusBig(T: Time; B: BigInteger; var Result: Time)
    begin
        Result := T - B;
    end;

    [TryFunction]
    local procedure TryTimePlusBig(T: Time; B: BigInteger; var Result: Time)
    begin
        Result := T + B;
    end;

    local procedure TimeBig(T: Time; B: BigInteger; Minus: Boolean): Text
    var
        R: Time;
        Ok: Boolean;
    begin
        if Minus then
            Ok := TryTimeMinusBig(T, B, R)
        else
            Ok := TryTimePlusBig(T, B, R);
        if Ok then
            exit('ok:' + Format(R, 0, 9));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Time_PlusMinus_BigInteger()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('T-1500', TimeBig(120000T, 1500, true));
        Observer.Observe('T+1500', TimeBig(120000T, 1500, false));
        Observer.Observe('T--1500', TimeBig(120000T, -1500, true));
        Observer.Observe('T-day', TimeBig(120000T, 86400000, true));
        Observer.Observe('T+3e9', TimeBig(120000T, 3000000000L, false));
        Observer.Observe('0T-1', TimeBig(0T, 1, true));
        Observer.Finish();
    end;
}
