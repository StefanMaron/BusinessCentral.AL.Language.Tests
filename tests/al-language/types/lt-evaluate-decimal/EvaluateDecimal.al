// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 67522
// Probe: Evaluate of a Text into a Decimal ('100', decimal and thousands separators, signs, blanks, exponent, garbage) and the conversion of a Variant that holds a Text into a Decimal. Assigning a Text to a Decimal directly does not compile (must-not-compile case 0501) (issue 580 item 5).
// BC versions: 27+

codeunit 67522 "LT Evaluate Decimal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Try(var Observer: Codeunit "Probe Observer"; Name: Text; Input: Text)
    var
        D: Decimal;
        Ok: Boolean;
    begin
        D := -1;
        Ok := Evaluate(D, Input);
        Observer.Observe(Name, '[' + Input + '] ' + Format(Ok) + ' ' + Format(D, 0, 9));
    end;

    [Test]
    procedure Evaluate_PlainAndSeparators()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Try(Observer, 'plain', '100');
        Try(Observer, 'decimal_point', '100.5');
        Try(Observer, 'thousands_comma', '1,000');
        Try(Observer, 'thousands_and_point', '1,000.5');
        Try(Observer, 'dot_thousands_comma_decimal', '1.000,5');
        Try(Observer, 'comma_decimal', '100,5');
        Try(Observer, 'space_thousands', '1 000');
        Try(Observer, 'misplaced_thousands', '1,0,0');
        Try(Observer, 'leading_point', '.5');
        Try(Observer, 'trailing_point', '5.');
        Try(Observer, 'many_decimals', '0.123456789012345678901');
        Try(Observer, 'large', '79228162514264337593543950335');
        Try(Observer, 'too_large', '792281625142643375935439503350');
        Observer.Expect('plain', '[100] Yes 100');
        Observer.Expect('decimal_point', '[100.5] Yes 100.5');
        Observer.Expect('thousands_comma', '[1,000] Yes 1000');
        Observer.Expect('thousands_and_point', '[1,000.5] Yes 1000.5');
        Observer.Expect('dot_thousands_comma_decimal', '[1.000,5] No -1');
        Observer.Expect('comma_decimal', '[100,5] Yes 1005');
        Observer.Expect('space_thousands', '[1 000] No -1');
        Observer.Expect('misplaced_thousands', '[1,0,0] Yes 100');
        Observer.Expect('leading_point', '[.5] Yes 0.5');
        Observer.Expect('trailing_point', '[5.] Yes 5');
        Observer.Expect('many_decimals', '[0.123456789012345678901] Yes 0.123456789012345678');
        Observer.Expect('large', '[79228162514264337593543950335] No -1');
        Observer.Expect('too_large', '[792281625142643375935439503350] No -1');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_SignsBlanksAndGarbage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Try(Observer, 'plus', '+100');
        Try(Observer, 'minus', '-100');
        Try(Observer, 'trailing_minus', '100-');
        Try(Observer, 'parentheses', '(100)');
        Try(Observer, 'surrounding_blanks', '  100  ');
        Try(Observer, 'trailing_blank', '100 ');
        Try(Observer, 'empty', '');
        Try(Observer, 'blank', ' ');
        Try(Observer, 'letters', 'abc');
        Try(Observer, 'trailing_letters', '100abc');
        Try(Observer, 'exponent_lower', '1e3');
        Try(Observer, 'exponent_upper', '1E3');
        Try(Observer, 'hex', '0x10');
        Try(Observer, 'percent', '100%');
        Try(Observer, 'two_points', '1.2.3');
        Try(Observer, 'zero', '0');
        Try(Observer, 'negative_zero', '-0');
        Try(Observer, 'leading_zeros', '007');
        Observer.Expect('plus', '[+100] Yes 100');
        Observer.Expect('minus', '[-100] Yes -100');
        Observer.Expect('trailing_minus', '[100-] Yes -100');
        Observer.Expect('parentheses', '[(100)] Yes -100');
        Observer.Expect('surrounding_blanks', '[  100  ] Yes 100');
        Observer.Expect('trailing_blank', '[100 ] Yes 100');
        Observer.Expect('empty', '[] No -1');
        Observer.Expect('blank', '[ ] No -1');
        Observer.Expect('letters', '[abc] No -1');
        Observer.Expect('trailing_letters', '[100abc] No -1');
        Observer.Expect('exponent_lower', '[1e3] Yes 1000');
        Observer.Expect('exponent_upper', '[1E3] Yes 1000');
        Observer.Expect('hex', '[0x10] No -1');
        Observer.Expect('percent', '[100%] No -1');
        Observer.Expect('two_points', '[1.2.3] No -1');
        Observer.Expect('zero', '[0] Yes 0');
        Observer.Expect('negative_zero', '[-0] Yes 0');
        Observer.Expect('leading_zeros', '[007] Yes 7');
        Observer.Verify();
    end;


    [Test]
    procedure Evaluate_FailureRaisesWithoutReturnValue()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
    begin
        asserterror Evaluate(D, 'abc');
        Observer.ObserveError('letters');
        asserterror Evaluate(D, '');
        Observer.ObserveError('empty');
        asserterror Evaluate(D, '1.2.3');
        Observer.ObserveError('two_points');
        Observer.Expect('letters|text', 'The value "abc" can''t be evaluated into type Decimal.');
        Observer.Expect('letters|code', 'Evaluate');
        Observer.Expect('empty|text', 'The value "" can''t be evaluated into type Decimal.');
        Observer.Expect('empty|code', 'Evaluate');
        Observer.Expect('two_points|text', 'The value "1.2.3" can''t be evaluated into type Decimal.');
        Observer.Expect('two_points|code', 'Evaluate');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure ToDecimal(V: Variant; var D: Decimal)
    begin
        D := V;
    end;

    local procedure Convert(var Observer: Codeunit "Probe Observer"; Name: Text; V: Variant)
    var
        D: Decimal;
        Ok: Boolean;
    begin
        D := -1;
        ClearLastError();
        Ok := ToDecimal(V, D);
        Observer.Observe(Name, Format(Ok) + ' ' + Format(D, 0, 9) + ' [' + GetLastErrorText() + ']');
    end;

    [Test]
    procedure Variant_HoldingText_ConvertsToDecimal()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        T := '100';
        Convert(Observer, 'plain', T);
        T := '100.5';
        Convert(Observer, 'decimal_point', T);
        T := '1,000.5';
        Convert(Observer, 'thousands_and_point', T);
        T := '1,000';
        Convert(Observer, 'thousands_comma', T);
        T := '100,5';
        Convert(Observer, 'comma_decimal', T);
        T := 'abc';
        Convert(Observer, 'letters', T);
        T := '';
        Convert(Observer, 'empty', T);
        T := ' 100 ';
        Convert(Observer, 'blanks', T);
        T := '-100';
        Convert(Observer, 'negative', T);
        Observer.Expect('plain', 'Yes 100 []');
        Observer.Expect('decimal_point', 'Yes 100.5 []');
        Observer.Expect('thousands_and_point', 'Yes 1000.5 []');
        Observer.Expect('thousands_comma', 'Yes 1000 []');
        Observer.Expect('comma_decimal', 'Yes 1005 []');
        Observer.Expect('letters', 'No -1 [The expression Variant cannot be type-converted to a Decimal value.]');
        Observer.Expect('empty', 'No -1 [The expression Variant cannot be type-converted to a Decimal value.]');
        Observer.Expect('blanks', 'Yes 100 []');
        Observer.Expect('negative', 'Yes -100 []');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_HoldingCode_ConvertsToDecimal()
    var
        Observer: Codeunit "Probe Observer";
        C: Code[20];
    begin
        C := '100';
        Convert(Observer, 'plain', C);
        C := '1,000.5';
        Convert(Observer, 'thousands_and_point', C);
        C := 'ABC';
        Convert(Observer, 'letters', C);
        Observer.Expect('plain', 'Yes 100 []');
        Observer.Expect('thousands_and_point', 'Yes 1000.5 []');
        Observer.Expect('letters', 'No -1 [The expression Variant cannot be type-converted to a Decimal value.]');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_IntoOtherNumericTypes()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        B: BigInteger;
        Ok: Boolean;
    begin
        Ok := Evaluate(I, '100');
        Observer.Observe('integer_plain', Format(Ok) + ' ' + Format(I));
        Ok := Evaluate(I, '100.5');
        Observer.Observe('integer_decimal_point', Format(Ok));
        Ok := Evaluate(I, '1,000');
        Observer.Observe('integer_thousands', Format(Ok) + ' ' + Format(I));
        Ok := Evaluate(B, '1,000');
        Observer.Observe('biginteger_thousands', Format(Ok) + ' ' + Format(B));
        Observer.Expect('integer_plain', 'Yes 100');
        Observer.Expect('integer_decimal_point', 'No');
        Observer.Expect('integer_thousands', 'Yes 1000');
        Observer.Expect('biginteger_thousands', 'Yes 1000');
        Observer.Verify();
    end;
}
