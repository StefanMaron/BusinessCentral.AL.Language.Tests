// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-data-types
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70055
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Evaluate of Integer, BigInteger, Decimal, Byte from text
// BC versions: 29 (27 and 28 by CI)

codeunit 70055 "LT ScT Evaluate Num"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure EvalInt(Txt: Text): Text
    var
        I: Integer;
        Ok: Boolean;
    begin
        I := 777;
        Ok := Evaluate(I, Txt);
        exit(Format(Ok) + '|' + Format(I));
    end;

    local procedure EvalDec(Txt: Text): Text
    var
        D: Decimal;
        Ok: Boolean;
    begin
        D := 777;
        Ok := Evaluate(D, Txt);
        exit(Format(Ok) + '|' + Format(D, 0, 9));
    end;

    local procedure EvalBig(Txt: Text): Text
    var
        B: BigInteger;
        Ok: Boolean;
    begin
        B := 777;
        Ok := Evaluate(B, Txt);
        exit(Format(Ok) + '|' + Format(B));
    end;

    [Test]
    procedure EvaluateInteger_Valid()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1', EvalInt('1'));
        Observer.Observe('neg', EvalInt('-1'));
        Observer.Observe('plus', EvalInt('+5'));
        Observer.Observe('zero', EvalInt('0'));
        Observer.Observe('negzero', EvalInt('-0'));
        Observer.Observe('lead0', EvalInt('007'));
        Observer.Observe('max', EvalInt('2147483647'));
        Observer.Observe('min', EvalInt('-2147483648'));
        Observer.Observe('spaces', EvalInt(' 12 '));
        Observer.Observe('lead_space', EvalInt('  12'));
        Observer.Observe('trail_space', EvalInt('12  '));
        Observer.Expect('1', 'Yes|1');
        Observer.Expect('neg', 'Yes|-1');
        Observer.Expect('plus', 'Yes|5');
        Observer.Expect('zero', 'Yes|0');
        Observer.Expect('negzero', 'Yes|0');
        Observer.Expect('lead0', 'Yes|7');
        Observer.Expect('max', 'Yes|2147483647');
        Observer.Expect('min', 'Yes|-2147483648');
        Observer.Expect('spaces', 'Yes|12');
        Observer.Expect('lead_space', 'Yes|12');
        Observer.Expect('trail_space', 'Yes|12');
        Observer.Verify();
    end;

    [Test]
    procedure EvaluateInteger_Invalid()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('empty', EvalInt(''));
        Observer.Observe('blank', EvalInt(' '));
        Observer.Observe('abc', EvalInt('abc'));
        Observer.Observe('overflow', EvalInt('2147483648'));
        Observer.Observe('underflow', EvalInt('-2147483649'));
        Observer.Observe('decimal', EvalInt('1.5'));
        Observer.Observe('decimal0', EvalInt('1.0'));
        Observer.Observe('comma', EvalInt('1,5'));
        Observer.Observe('thousand', EvalInt('1,000'));
        Observer.Observe('exp', EvalInt('1E3'));
        Observer.Observe('hex', EvalInt('0x10'));
        Observer.Observe('trailing_text', EvalInt('12abc'));
        Observer.Observe('two_signs', EvalInt('--1'));
        Observer.Observe('sign_only', EvalInt('-'));
        Observer.Observe('bigval', EvalInt('99999999999999999999'));
        Observer.Expect('empty', 'No|777');
        Observer.Expect('blank', 'No|777');
        Observer.Expect('abc', 'No|777');
        Observer.Expect('overflow', 'No|777');
        Observer.Expect('underflow', 'No|777');
        Observer.Expect('decimal', 'No|777');
        Observer.Expect('decimal0', 'Yes|1');
        Observer.Expect('comma', 'Yes|15');
        Observer.Expect('thousand', 'Yes|1000');
        Observer.Expect('exp', 'Yes|1000');
        Observer.Expect('hex', 'No|777');
        Observer.Expect('trailing_text', 'No|777');
        Observer.Expect('two_signs', 'No|777');
        Observer.Expect('sign_only', 'No|777');
        Observer.Expect('bigval', 'No|777');
        Observer.Verify();
    end;

    [Test]
    procedure EvaluateDecimal_Valid()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('int', EvalDec('1'));
        Observer.Observe('frac', EvalDec('1.5'));
        Observer.Observe('neg', EvalDec('-1.5'));
        Observer.Observe('plus', EvalDec('+1.5'));
        Observer.Observe('dot_start', EvalDec('.5'));
        Observer.Observe('dot_end', EvalDec('5.'));
        Observer.Observe('zero', EvalDec('0.000'));
        Observer.Observe('exp', EvalDec('1E3'));
        Observer.Observe('exp_neg', EvalDec('1.5e-2'));
        Observer.Observe('thousand', EvalDec('1,000'));
        Observer.Observe('thousand_dec', EvalDec('1,000.25'));
        Observer.Observe('comma_dec', EvalDec('1,5'));
        Observer.Observe('prec18', EvalDec('123456789012345678'));
        Observer.Observe('prec_frac', EvalDec('0.123456789012345678'));
        Observer.Observe('round_frac', EvalDec('0.00000000000000000001'));
        Observer.Observe('spaces', EvalDec(' 2.5 '));
        Observer.Expect('int', 'Yes|1');
        Observer.Expect('frac', 'Yes|1.5');
        Observer.Expect('neg', 'Yes|-1.5');
        Observer.Expect('plus', 'Yes|1.5');
        Observer.Expect('dot_start', 'Yes|0.5');
        Observer.Expect('dot_end', 'Yes|5');
        Observer.Expect('zero', 'Yes|0');
        Observer.Expect('exp', 'Yes|1000');
        Observer.Expect('exp_neg', 'Yes|0.015');
        Observer.Expect('thousand', 'Yes|1000');
        Observer.Expect('thousand_dec', 'Yes|1000.25');
        Observer.Expect('comma_dec', 'Yes|15');
        Observer.Expect('prec18', 'No|777');
        Observer.Expect('prec_frac', 'Yes|0.123456789012345678');
        Observer.Expect('round_frac', 'Yes|0');
        Observer.Expect('spaces', 'Yes|2.5');
        Observer.Verify();
    end;

    [Test]
    procedure EvaluateDecimal_Invalid()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('empty', EvalDec(''));
        Observer.Observe('abc', EvalDec('abc'));
        Observer.Observe('two_dots', EvalDec('1.2.3'));
        Observer.Observe('dot_only', EvalDec('.'));
        Observer.Observe('huge', EvalDec('1E40'));
        Observer.Observe('huge_digits', EvalDec('99999999999999999999999999999999999'));
        Observer.Observe('trailing', EvalDec('1.5x'));
        Observer.Observe('percent', EvalDec('50%'));
        Observer.Observe('currency', EvalDec('$5'));
        Observer.Observe('nan', EvalDec('NaN'));
        Observer.Observe('inf', EvalDec('Infinity'));
        Observer.Expect('empty', 'No|777');
        Observer.Expect('abc', 'No|777');
        Observer.Expect('two_dots', 'No|777');
        Observer.Expect('dot_only', 'No|777');
        Observer.Expect('huge', 'No|777');
        Observer.Expect('huge_digits', 'No|777');
        Observer.Expect('trailing', 'No|777');
        Observer.Expect('percent', 'No|777');
        Observer.Expect('currency', 'Yes|5');
        Observer.Expect('nan', 'No|777');
        Observer.Expect('inf', 'No|777');
        Observer.Verify();
    end;

    [Test]
    procedure EvaluateBigInteger()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('max', EvalBig('9223372036854775807'));
        Observer.Observe('min', EvalBig('-9223372036854775808'));
        Observer.Observe('over', EvalBig('9223372036854775808'));
        Observer.Observe('under', EvalBig('-9223372036854775809'));
        Observer.Observe('five_bn', EvalBig('5000000000'));
        Observer.Observe('dec', EvalBig('1.5'));
        Observer.Observe('empty', EvalBig(''));
        Observer.Observe('abc', EvalBig('x'));
        Observer.Expect('max', 'Yes|9223372036854775807');
        Observer.Expect('min', 'Yes|-9223372036854775808');
        Observer.Expect('over', 'No|777');
        Observer.Expect('under', 'No|777');
        Observer.Expect('five_bn', 'Yes|5000000000');
        Observer.Expect('dec', 'No|777');
        Observer.Expect('empty', 'No|777');
        Observer.Expect('abc', 'No|777');
        Observer.Verify();
    end;

    [Test]
    procedure EvaluateByte_Char()
    var
        Observer: Codeunit "Probe Observer";
        B: Byte;
        C: Char;
        Ok: Boolean;
    begin
        Ok := Evaluate(B, '255');
        Observer.Observe('b255', Format(Ok) + '|' + Format(B));
        B := 1;
        Ok := Evaluate(B, '256');
        Observer.Observe('b256', Format(Ok) + '|' + Format(B));
        B := 1;
        Ok := Evaluate(B, '-1');
        Observer.Observe('bneg', Format(Ok) + '|' + Format(B));
        B := 1;
        Ok := Evaluate(B, '0');
        Observer.Observe('b0', Format(Ok) + '|' + Format(B));
        B := 1;
        Ok := Evaluate(B, 'x');
        Observer.Observe('bx', Format(Ok) + '|' + Format(B));
        C := 'z';
        Ok := Evaluate(C, '65');
        Observer.Observe('c65', Format(Ok) + '|' + Format(C));
        C := 'z';
        Ok := Evaluate(C, 'A');
        Observer.Observe('cA', Format(Ok) + '|' + Format(C));
        C := 'z';
        Ok := Evaluate(C, '');
        Observer.Observe('cempty', Format(Ok) + '|' + Format(C));
        C := 'z';
        Ok := Evaluate(C, '70000');
        Observer.Observe('c70000', Format(Ok) + '|' + Format(C));
        Observer.Expect('b255', 'No|\u0000');
        Observer.Expect('b256', 'No|\u0001');
        Observer.Expect('bneg', 'No|\u0001');
        Observer.Expect('b0', 'Yes|0');
        Observer.Expect('bx', 'Yes|x');
        Observer.Expect('c65', 'No|z');
        Observer.Expect('cA', 'Yes|A');
        Observer.Expect('cempty', 'No|z');
        Observer.Expect('c70000', 'No|z');
        Observer.Verify();
    end;
}
