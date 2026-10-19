// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/decimal/decimal-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Operands are built with Evaluate from text so that no literal-length compile rule applies; results are printed with Format(x, 0, 9) (XML format, all digits).

codeunit 73232 "LT P163 Decimal Digits"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure D(Value: Text): Decimal
    var
        Result: Decimal;
    begin
        if not Evaluate(Result, Value, 9) then
            exit(-999999);
        exit(Result);
    end;

    local procedure F(Value: Decimal): Text
    begin
        exit(Format(Value, 0, 9));
    end;

    [Test]
    procedure P163_Decimal_Operands_RoundTrip()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('18_decimals', F(D('0.123456789012345678')));
        Observer.Observe('19_decimals', F(D('0.1234567890123456789')));
        Observer.Observe('28_decimals', F(D('0.1234567890123456789012345678')));
        Observer.Observe('29_decimals', F(D('0.12345678901234567890123456789')));
        Observer.Observe('28_digits_integer_part', F(D('1234567890123456789012345678')));
        Observer.Observe('1_plus_17_decimals', F(D('1.12345678901234567')));
        Observer.Observe('20_digits_total', F(D('12345678901234567890')));
        Observer.Observe('10_decimals_with_7_integer_digits', F(D('1234567.1234567890')));
        Observer.Expect('18_decimals', '0.123456789012345678');
        Observer.Expect('19_decimals', '0.123456789012345678');
        Observer.Expect('28_decimals', '0.123456789012345678');
        Observer.Expect('29_decimals', '0.123456789012345678');
        Observer.Expect('28_digits_integer_part', '-999999');
        Observer.Expect('1_plus_17_decimals', '1.12345678901234567');
        Observer.Expect('20_digits_total', '-999999');
        Observer.Expect('10_decimals_with_7_integer_digits', '1234567.123456789');
        Observer.Verify();
    end;

    [Test]
    procedure P163_Decimal_Division_SignificantDigits()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1_3', F(D('1') / D('3')));
        Observer.Observe('2_3', F(D('2') / D('3')));
        Observer.Observe('10_3', F(D('10') / D('3')));
        Observer.Observe('100_3', F(D('100') / D('3')));
        Observer.Observe('1000000_3', F(D('1000000') / D('3')));
        Observer.Observe('1e12_3', F(D('1000000000000') / D('3')));
        Observer.Observe('1_7', F(D('1') / D('7')));
        Observer.Observe('1_3000', F(D('1') / D('3000')));
        Observer.Observe('1_3000000', F(D('1') / D('3000000')));
        Observer.Observe('1_30000000000', F(D('1') / D('30000000000')));
        Observer.Observe('neg_2_3', F(D('-2') / D('3')));
        Observer.Observe('1_8', F(D('1') / D('8')));
        Observer.Observe('1_1024', F(D('1') / D('1024')));
        Observer.Observe('big_by_small', F(D('123456789012345678') / D('7')));
        Observer.Observe('small_decimals_by_3', F(D('0.000000000000000001') / D('3')));
        Observer.Expect('1_3', '0.333333333333333333');
        Observer.Expect('2_3', '0.666666666666666667');
        Observer.Expect('10_3', '3.33333333333333333');
        Observer.Expect('100_3', '33.3333333333333333');
        Observer.Expect('1000000_3', '333333.333333333333');
        Observer.Expect('1e12_3', '333333333333.333333');
        Observer.Expect('1_7', '0.142857142857142857');
        Observer.Expect('1_3000', '0.000333333333333333');
        Observer.Expect('1_3000000', '0.000000333333333333');
        Observer.Expect('1_30000000000', '0.000000000033333333');
        Observer.Expect('neg_2_3', '-0.666666666666666667');
        Observer.Expect('1_8', '0.125');
        Observer.Expect('1_1024', '0.0009765625');
        Observer.Expect('big_by_small', '-142857');
        Observer.Expect('small_decimals_by_3', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P163_Decimal_Multiplication_KeepsDigits()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('18x18_decimals', F(D('0.123456789012345678') * D('0.123456789012345678')));
        Observer.Observe('14x14_decimals', F(D('0.12345678901234') * D('0.12345678901234')));
        Observer.Observe('10x10_decimals', F(D('0.1234567890') * D('0.1234567890')));
        asserterror Observer.Observe('big_x_big', F(D('123456789012') * D('123456789012')));
        Observer.ObserveError('af74');
        asserterror Observer.Observe('big_x_fraction', F(D('123456789.123456789') * D('987654321.987654321')));
        Observer.ObserveError('af76');
        Observer.Observe('third_times_3', F((D('1') / D('3')) * D('3')));
        Observer.Observe('third_times_third', F((D('1') / D('3')) * (D('1') / D('3'))));
        Observer.Expect('18x18_decimals', '0.015241578753238837');
        Observer.Expect('14x14_decimals', '0.015241578753237435');
        Observer.Expect('10x10_decimals', '0.015241578750190521');
        Observer.Expect('af74|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 15,241,578,753,153,483,900,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('af74|code', 'OutsidePermittedRange');
        Observer.Expect('af76|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 121,932,631,356,500,531. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('af76|code', 'OutsidePermittedRange');
        Observer.Expect('third_times_3', '0.999999999999999999');
        Observer.Expect('third_times_third', '0.111111111111111111');
        Observer.Verify();
    end;

    [Test]
    procedure P163_Decimal_AddSubtract_KeepsDigits()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('add_18_decimals', F(D('0.123456789012345678') + D('0.000000000000000001')));
        Observer.Observe('add_28_decimals', F(D('0.1234567890123456789012345678') + D('0.0000000000000000000000000001')));
        Observer.Observe('add_big', F(D('12345678901234567890') + D('0.12345678')));
        Observer.Observe('sub_big', F(D('12345678901234567890.5') - D('0.25')));
        Observer.Observe('sub_to_zero', F(D('0.1234567890123456789') - D('0.1234567890123456789')));
        Observer.Observe('third_plus_third', F((D('1') / D('3')) + (D('1') / D('3'))));
        Observer.Observe('third_plus_third_plus_third', F((D('1') / D('3')) + (D('1') / D('3')) + (D('1') / D('3'))));
        Observer.Observe('add_third_to_big', F(D('100000000') + (D('1') / D('3'))));
        Observer.Expect('add_18_decimals', '0.123456789012345679');
        Observer.Expect('add_28_decimals', '0.123456789012345678');
        Observer.Expect('add_big', '-999998.87654322');
        Observer.Expect('sub_big', '-999999.25');
        Observer.Expect('sub_to_zero', '0');
        Observer.Expect('third_plus_third', '0.666666666666666666');
        Observer.Expect('third_plus_third_plus_third', '0.999999999999999999');
        Observer.Expect('add_third_to_big', '100000000.333333333');
        Observer.Verify();
    end;

    [Test]
    procedure P163_Decimal_PowerAndRound()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('2_pow_0_5', F(Power(2, 0.5)));
        Observer.Observe('2_pow_minus_1', F(Power(2, -1)));
        Observer.Observe('3_pow_minus_1', F(Power(3, -1)));
        asserterror Observer.Observe('10_pow_20', F(Power(10, 20)));
        Observer.ObserveError('af106');
        Observer.Observe('1_1_pow_30', F(Power(1.1, 30)));
        Observer.Observe('round_third_to_10', F(Round(D('1') / D('3'), 0.0000000001)));
        Observer.Observe('round_third_default', F(Round(D('1') / D('3'))));
        Observer.Observe('format_third_default', Format(D('1') / D('3')));
        Observer.Observe('format_third_precision_20', Format(D('1') / D('3'), 0, '<Precision,18:18><Standard Format,2>'));
        Observer.Observe('format_big_default', Format(D('12345678901234567890.123456')));
        Observer.Expect('2_pow_0_5', '1.4142135623731');
        Observer.Expect('2_pow_minus_1', '0.5');
        Observer.Expect('3_pow_minus_1', '0.333333333333333');
        Observer.Expect('af106|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 100,000,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('af106|code', 'OutsidePermittedRange');
        Observer.Expect('1_1_pow_30', '17.4494022688864073');
        Observer.Expect('round_third_to_10', '0.3333333333');
        Observer.Expect('round_third_default', '0.33');
        Observer.Expect('format_third_default', '0.333333333333333333');
        Observer.Expect('format_third_precision_20', '0.333333333333333333');
        Observer.Expect('format_big_default', '-999,999');
        Observer.Verify();
    end;
}
