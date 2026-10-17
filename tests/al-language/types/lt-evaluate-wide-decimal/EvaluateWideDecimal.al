// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); test codeunit 71889
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced.
// Facts: Evaluate of integer-only and fractional decimals with 13 to 17 digits into a Decimal (plain and with format number 9) and into a
//   BigInteger. Each observation is the Boolean result and Format(Value, 0, 9) of the target. Already pinned: 12 digits accepted
//   (json/JsonValueSetters.al) and 20 digits rejected (misc/lt-system-functions/EvalLastError.al).
// BC versions: 27, 28, 29
codeunit 71889 "LT Evaluate Wide Decimal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Dec(X: Text): Text
    var
        D: Decimal;
        Ok: Boolean;
    begin
        D := 7;
        Ok := Evaluate(D, X);
        exit(Format(Ok) + '|' + Format(D, 0, 9));
    end;

    local procedure Dec9(X: Text): Text
    var
        D: Decimal;
        Ok: Boolean;
    begin
        D := 7;
        Ok := Evaluate(D, X, 9);
        exit(Format(Ok) + '|' + Format(D, 0, 9));
    end;

    local procedure Big(X: Text): Text
    var
        B: BigInteger;
        Ok: Boolean;
    begin
        B := 7;
        Ok := Evaluate(B, X);
        exit(Format(Ok) + '|' + Format(B, 0, 9));
    end;

    local procedure Big9(X: Text): Text
    var
        B: BigInteger;
        Ok: Boolean;
    begin
        B := 7;
        Ok := Evaluate(B, X, 9);
        exit(Format(Ok) + '|' + Format(B, 0, 9));
    end;

    [Test]
    procedure Evaluate_Decimal_IntegerDigits()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('d12', Dec('100000000000'));
        Observer.Observe('d13', Dec('1000000000000'));
        Observer.Observe('d13_nines', Dec('9999999999999'));
        Observer.Observe('d15', Dec('100000000000000'));
        Observer.Observe('d15_nines', Dec('999999999999999'));
        Observer.Observe('d16', Dec('1000000000000000'));
        Observer.Observe('d16_nines', Dec('9999999999999999'));
        Observer.Observe('d17', Dec('12345678901234567'));
        Observer.Observe('d18', Dec('123456789012345678'));
        Observer.Finish();
    end;

    [Test]
    procedure Evaluate_Decimal_Format9_IntegerDigits()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('d12', Dec9('100000000000'));
        Observer.Observe('d13', Dec9('1000000000000'));
        Observer.Observe('d13_nines', Dec9('9999999999999'));
        Observer.Observe('d15', Dec9('100000000000000'));
        Observer.Observe('d15_nines', Dec9('999999999999999'));
        Observer.Observe('d16', Dec9('1000000000000000'));
        Observer.Observe('d16_nines', Dec9('9999999999999999'));
        Observer.Observe('d17', Dec9('12345678901234567'));
        Observer.Observe('d18', Dec9('123456789012345678'));
        Observer.Finish();
    end;

    [Test]
    procedure Evaluate_Decimal_Fraction()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('f13', Dec('1000000000000.5'));
        Observer.Observe('f15', Dec('100000000000000.5'));
        Observer.Observe('f16', Dec('1000000000000000.5'));
        Observer.Observe('f17', Dec('12345678901234567.5'));
        Observer.Observe('f16_9', Dec9('1000000000000000.5'));
        Observer.Observe('f17_9', Dec9('12345678901234567.5'));
        Observer.Observe('f13_exact', Dec('1000000000000.123456789'));
        Observer.Observe('f13_exact_9', Dec9('1000000000000.123456789'));
        Observer.Finish();
    end;

    [Test]
    procedure Evaluate_Decimal_Negative()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('n13', Dec('-1000000000000'));
        Observer.Observe('n15_nines', Dec('-999999999999999'));
        Observer.Observe('n16', Dec('-1000000000000000'));
        Observer.Observe('n17', Dec('-12345678901234567'));
        Observer.Observe('n16_fraction', Dec('-1000000000000000.5'));
        Observer.Observe('n13_9', Dec9('-1000000000000'));
        Observer.Observe('n16_9', Dec9('-1000000000000000'));
        Observer.Observe('n17_9', Dec9('-12345678901234567'));
        Observer.Observe('plus_16', Dec('+1000000000000000'));
        Observer.Finish();
    end;

    [Test]
    procedure Evaluate_BigInteger_IntegerDigits()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('b13', Big('1000000000000'));
        Observer.Observe('b15_nines', Big('999999999999999'));
        Observer.Observe('b16', Big('1000000000000000'));
        Observer.Observe('b16_nines', Big('9999999999999999'));
        Observer.Observe('b17', Big('12345678901234567'));
        Observer.Observe('b18', Big('123456789012345678'));
        Observer.Observe('b19_max', Big('9223372036854775807'));
        Observer.Observe('b19_over', Big('9223372036854775808'));
        Observer.Observe('b17_9', Big9('12345678901234567'));
        Observer.Observe('b19_max_9', Big9('9223372036854775807'));
        Observer.Observe('bn17', Big('-12345678901234567'));
        Observer.Observe('bn19_min', Big('-9223372036854775808'));
        Observer.Observe('b16_fraction', Big('1000000000000000.5'));
        Observer.Finish();
    end;
}
