// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/decimal/decimal-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Decimal, Boolean, Byte, Integer, BigInteger ToText with each argument form against Format
// BC versions: 29 (27 and 28 by CI)

codeunit 70323 "LT P93 ScalarToText"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryDec(V: Decimal; Mode: Integer; var R: Text)
    begin
        case Mode of
            0:
                R := V.ToText();
            1:
                R := V.ToText(true);
            2:
                R := V.ToText(false);
        end;
    end;

    local procedure Dc(V: Decimal; Mode: Integer): Text
    var
        R: Text;
    begin
        if TryDec(V, Mode, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Decimal_Basic()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
    begin
        D := 1234567.891;
        Observer.Observe('tt', Dc(D, 0));
        Observer.Observe('tt-true', Dc(D, 1));
        Observer.Observe('tt-false', Dc(D, 2));
        Observer.Observe('format', Format(D));
        Observer.Observe('format-9', Format(D, 0, 9));
        Observer.Observe('format-0', Format(D, 0, 0));
        D := 0;
        Observer.Observe('zero', Dc(D, 0));
        Observer.Observe('zero-true', Dc(D, 1));
        Observer.Observe('zero-false', Dc(D, 2));
        Observer.Observe('zero-format', Format(D));
        D := -0.5;
        Observer.Observe('neg', Dc(D, 0));
        Observer.Observe('neg-true', Dc(D, 1));
        Observer.Observe('neg-format-9', Format(D, 0, 9));
        D := 1000;
        Observer.Observe('thousand', Dc(D, 0));
        Observer.Observe('thousand-true', Dc(D, 1));
        Observer.Observe('thousand-format', Format(D));
        Observer.Finish();
    end;

    [Test]
    procedure Decimal_Edges()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
        i: Integer;
    begin
        D := 0.00001;
        Observer.Observe('small', Dc(D, 0));
        Observer.Observe('small-true', Dc(D, 1));
        Observer.Observe('small-format-9', Format(D, 0, 9));
        D := 1 / 3;
        Observer.Observe('third', Dc(D, 0));
        Observer.Observe('third-true', Dc(D, 1));
        Observer.Observe('third-format-9', Format(D, 0, 9));
        D := 1;
        for i := 1 to 27 do
            D := D * 10;
        Observer.Observe('big', Dc(D, 0));
        Observer.Observe('big-true', Dc(D, 1));
        asserterror Observer.Observe('big-format-9', Format(D, 0, 9));
        Observer.ObserveError('af84');
        D := 12.50;
        Observer.Observe('trailing', Dc(D, 0));
        Observer.Observe('trailing-true', Dc(D, 1));
        D := 100000000000000.0;
        Observer.Observe('1e14', Dc(D, 0));
        Observer.Observe('1e14-true', Dc(D, 1));
        D := -1234.5;
        Observer.Observe('neg-big', Dc(D, 0));
        Observer.Observe('neg-big-true', Dc(D, 1));
        D := 0.1 + 0.2;
        Observer.Observe('sum', Dc(D, 0));
        Observer.Observe('sum-eq-point3', Format(D = 0.3));
        Observer.Finish();
    end;

    [Test]
    procedure Boolean_ToText()
    var
        Observer: Codeunit "Probe Observer";
        B: Boolean;
    begin
        Observer.Observe('false', B.ToText());
        Observer.Observe('false-true', B.ToText(true));
        Observer.Observe('false-false', B.ToText(false));
        Observer.Observe('false-format', Format(B));
        Observer.Observe('false-format-9', Format(B, 0, 9));
        Observer.Observe('false-format-0', Format(B, 0, 0));
        Observer.Observe('false-format-1', Format(B, 0, 1));
        Observer.Observe('false-format-2', Format(B, 0, 2));
        B := true;
        Observer.Observe('true', B.ToText());
        Observer.Observe('true-true', B.ToText(true));
        Observer.Observe('true-false', B.ToText(false));
        Observer.Observe('true-format', Format(B));
        Observer.Observe('true-format-9', Format(B, 0, 9));
        Observer.Observe('true-format-0', Format(B, 0, 0));
        Observer.Observe('true-format-1', Format(B, 0, 1));
        Observer.Observe('true-format-2', Format(B, 0, 2));
        Observer.Observe('expr', (1 = 1).ToText());
        Observer.Finish();
    end;

    [Test]
    procedure Byte_ToText()
    var
        Observer: Codeunit "Probe Observer";
        B: Byte;
    begin
        Observer.Observe('zero', B.ToText());
        Observer.Observe('zero-true', B.ToText(true));
        Observer.Observe('zero-false', B.ToText(false));
        Observer.Observe('zero-format', Format(B));
        B := 255;
        Observer.Observe('max', B.ToText());
        Observer.Observe('max-true', B.ToText(true));
        Observer.Observe('max-false', B.ToText(false));
        Observer.Observe('max-format', Format(B));
        Observer.Observe('max-format-9', Format(B, 0, 9));
        B := 65;
        Observer.Observe('a', B.ToText());
        Observer.Observe('a-true', B.ToText(true));
        Observer.Observe('a-format', Format(B));
        B := 10;
        Observer.Observe('lf', B.ToText());
        Observer.Observe('lf-format-9', Format(B, 0, 9));
        Observer.Finish();
    end;

    [Test]
    procedure Integer_ToText()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        Observer.Observe('zero', I.ToText());
        Observer.Observe('zero-format', Format(I));
        I := 2147483647;
        Observer.Observe('max', I.ToText());
        Observer.Observe('max-format', Format(I));
        Observer.Observe('max-format-9', Format(I, 0, 9));
        I := -2147483647;
        I := I - 1;
        Observer.Observe('min', I.ToText());
        Observer.Observe('min-format', Format(I));
        I := -42;
        Observer.Observe('neg', I.ToText());
        Observer.Observe('neg-format-9', Format(I, 0, 9));
        I := 1000;
        Observer.Observe('thousand', I.ToText());
        Observer.Observe('thousand-format', Format(I));
        Observer.Observe('expr', (7 * 6).ToText());
        Observer.Finish();
    end;

    [Test]
    procedure BigInteger_ToText()
    var
        Observer: Codeunit "Probe Observer";
        B: BigInteger;
    begin
        Observer.Observe('zero', B.ToText());
        Observer.Observe('zero-format', Format(B));
        B := 2147483647;
        B := B * 4294967296L;
        Observer.Observe('big', B.ToText());
        Observer.Observe('big-format', Format(B));
        Observer.Observe('big-format-9', Format(B, 0, 9));
        B := -B;
        Observer.Observe('neg-big', B.ToText());
        Observer.Observe('neg-big-format-9', Format(B, 0, 9));
        B := 1000;
        Observer.Observe('thousand', B.ToText());
        Observer.Observe('thousand-format', Format(B));
        B := 9223372036854775807L;
        Observer.Observe('max', B.ToText());
        Observer.Observe('max-format', Format(B));
        B := -9223372036854775807L;
        B := B - 1;
        Observer.Observe('min', B.ToText());
        Observer.Observe('min-format', Format(B));
        Observer.Finish();
    end;
}
