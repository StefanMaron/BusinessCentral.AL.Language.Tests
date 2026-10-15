// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/decimal/decimal-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Round with precision and direction, Abs, Power, Exp, Ln, Log.
// BC versions: 29 (27 and 28 by CI)

codeunit 72507 "LT SyT Round"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Round_Default()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1.5', Format(Round(1.5)));
        Observer.Observe('2.5', Format(Round(2.5)));
        Observer.Observe('-1.5', Format(Round(-1.5)));
        Observer.Observe('-2.5', Format(Round(-2.5)));
        Observer.Observe('0.49999', Format(Round(0.49999)));
        Observer.Observe('0.5', Format(Round(0.5)));
        Observer.Observe('-0.5', Format(Round(-0.5)));
        Observer.Observe('0', Format(Round(0)));
        Observer.Observe('big', Format(Round(123456789012.5)));
        Observer.Observe('bigneg', Format(Round(-123456789012.5)));
        Observer.Observe('tiny', Format(Round(0.0000001)));
        Observer.Expect('1.5', '1.5');
        Observer.Expect('2.5', '2.5');
        Observer.Expect('-1.5', '-1.5');
        Observer.Expect('-2.5', '-2.5');
        Observer.Expect('0.49999', '0.5');
        Observer.Expect('0.5', '0.5');
        Observer.Expect('-0.5', '-0.5');
        Observer.Expect('0', '0');
        Observer.Expect('big', '123,456,789,012.5');
        Observer.Expect('bigneg', '-123,456,789,012.5');
        Observer.Expect('tiny', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Round_Precision()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('p0.01 1.005', Format(Round(1.005, 0.01)));
        Observer.Observe('p0.01 1.015', Format(Round(1.015, 0.01)));
        Observer.Observe('p0.01 -1.005', Format(Round(-1.005, 0.01)));
        Observer.Observe('p0.1 1.25', Format(Round(1.25, 0.1)));
        Observer.Observe('p0.1 1.35', Format(Round(1.35, 0.1)));
        Observer.Observe('p10 15', Format(Round(15, 10)));
        Observer.Observe('p10 14', Format(Round(14, 10)));
        Observer.Observe('p10 -15', Format(Round(-15, 10)));
        Observer.Observe('p100 150', Format(Round(150, 100)));
        Observer.Observe('p0.05 1.02', Format(Round(1.02, 0.05)));
        Observer.Observe('p0.05 1.03', Format(Round(1.03, 0.05)));
        Observer.Observe('p0.25 1.1', Format(Round(1.1, 0.25)));
        Observer.Observe('p1 2.5', Format(Round(2.5, 1)));
        Observer.Observe('p0.00001', Format(Round(3.141592653, 0.00001)));
        Observer.Observe('p0.000000001', Format(Round(3.141592653589, 0.000000001)));
        Observer.Expect('p0.01 1.005', '1.01');
        Observer.Expect('p0.01 1.015', '1.02');
        Observer.Expect('p0.01 -1.005', '-1.01');
        Observer.Expect('p0.1 1.25', '1.3');
        Observer.Expect('p0.1 1.35', '1.4');
        Observer.Expect('p10 15', '20');
        Observer.Expect('p10 14', '10');
        Observer.Expect('p10 -15', '-20');
        Observer.Expect('p100 150', '200');
        Observer.Expect('p0.05 1.02', '1');
        Observer.Expect('p0.05 1.03', '1.05');
        Observer.Expect('p0.25 1.1', '1');
        Observer.Expect('p1 2.5', '3');
        Observer.Expect('p0.00001', '3.14159');
        Observer.Expect('p0.000000001', '3.141592654');
        Observer.Verify();
    end;

    [Test]
    procedure Round_Direction()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('= 2.5', Format(Round(2.5, 1, '=')));
        Observer.Observe('= -2.5', Format(Round(-2.5, 1, '=')));
        Observer.Observe('> 2.1', Format(Round(2.1, 1, '>')));
        Observer.Observe('> -2.1', Format(Round(-2.1, 1, '>')));
        Observer.Observe('> 2', Format(Round(2, 1, '>')));
        Observer.Observe('< 2.9', Format(Round(2.9, 1, '<')));
        Observer.Observe('< -2.9', Format(Round(-2.9, 1, '<')));
        Observer.Observe('< 2', Format(Round(2, 1, '<')));
        Observer.Observe('> 0.001 p0.01', Format(Round(0.001, 0.01, '>')));
        Observer.Observe('< 0.009 p0.01', Format(Round(0.009, 0.01, '<')));
        Observer.Observe('> 11 p10', Format(Round(11, 10, '>')));
        Observer.Observe('< 19 p10', Format(Round(19, 10, '<')));
        Observer.Observe('< -11 p10', Format(Round(-11, 10, '<')));
        Observer.Observe('> 0', Format(Round(0, 1, '>')));
        Observer.Expect('= 2.5', '3');
        Observer.Expect('= -2.5', '-3');
        Observer.Expect('> 2.1', '3');
        Observer.Expect('> -2.1', '-3');
        Observer.Expect('> 2', '2');
        Observer.Expect('< 2.9', '2');
        Observer.Expect('< -2.9', '-2');
        Observer.Expect('< 2', '2');
        Observer.Expect('> 0.001 p0.01', '0.01');
        Observer.Expect('< 0.009 p0.01', '0');
        Observer.Expect('> 11 p10', '20');
        Observer.Expect('< 19 p10', '10');
        Observer.Expect('< -11 p10', '-10');
        Observer.Expect('> 0', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Round_InvalidDirection()
    var
        Observer: Codeunit "Probe Observer";
        Result: Decimal;
    begin
        asserterror Result := Round(2.5, 1, 'x');
        Observer.ObserveError('dir x');
        asserterror Result := Round(2.5, 1, '');
        Observer.ObserveError('dir empty');
        asserterror Result := Round(2.5, 1, '>>');
        Observer.ObserveError('dir two chars');
        asserterror Result := Round(2.5, 0);
        Observer.ObserveError('precision zero');
        asserterror Result := Round(2.5, -1);
        Observer.ObserveError('precision negative');
        Observer.Expect('dir x|text', 'The supplied value is not valid.');
        Observer.Expect('dir x|code', 'InvalidValue');
        Observer.Expect('dir empty|text', 'The supplied value is not valid.');
        Observer.Expect('dir empty|code', 'InvalidValue');
        Observer.Expect('dir two chars|text', 'The supplied value is not valid.');
        Observer.Expect('dir two chars|code', 'InvalidValue');
        Observer.Expect('precision zero|text', 'The value of ROUND parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647.');
        Observer.Expect('precision zero|code', 'OutsidePermittedRange');
        Observer.Expect('precision negative|text', 'The value of ROUND parameter 2 is outside of the permitted range. The current value is: 1. The permitted range is: from 1 to 2,147,483,647.');
        Observer.Expect('precision negative|code', 'OutsidePermittedRange');
        Observer.Verify();
    end;

    [Test]
    procedure Round_IntegerArguments()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        D: Decimal;
    begin
        I := 7;
        D := 7.5;
        Observer.Observe('int', Format(Round(I)));
        Observer.Observe('int p2', Format(Round(I, 2)));
        Observer.Observe('dec', Format(Round(D)));
        Observer.Observe('dec p0.1', Format(Round(D, 0.1)));
        Observer.Observe('int / int', Format(Round(7 / 2)));
        Observer.Observe('int div int', Format(7 div 2));
        Observer.Observe('big p1', Format(Round(99999999999999.5, 1)));
        Observer.Expect('int', '7');
        Observer.Expect('int p2', '8');
        Observer.Expect('dec', '7.5');
        Observer.Expect('dec p0.1', '7.5');
        Observer.Expect('int / int', '3.5');
        Observer.Expect('int div int', '3');
        Observer.Expect('big p1', '100,000,000,000,000');
        Observer.Verify();
    end;

    [Test]
    procedure Abs_Values()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        B: BigInteger;
    begin
        Observer.Observe('-1.5', Format(Abs(-1.5)));
        Observer.Observe('1.5', Format(Abs(1.5)));
        Observer.Observe('0', Format(Abs(0)));
        Observer.Observe('-0.0', Format(Abs(-0.0)));
        I := -2147483647;
        Observer.Observe('int min+1', Format(Abs(I)));
        I := -5;
        Observer.Observe('int -5', Format(Abs(I)));
        Evaluate(B, '-9223372036854775807');
        Observer.Observe('big', Format(Abs(B)));
        Observer.Observe('dec big', Format(Abs(-123456789012345.678)));
        I := -2147483647 - 1;
        asserterror Observer.Observe('int min', Format(Abs(I)));
        Observer.ObserveError('int min');
        Observer.Expect('-1.5', '1.5');
        Observer.Expect('1.5', '1.5');
        Observer.Expect('0', '0');
        Observer.Expect('-0.0', '0');
        Observer.Expect('int min+1', '2147483647');
        Observer.Expect('int -5', '5');
        Observer.Expect('big', '9223372036854775807');
        Observer.Expect('dec big', '123,456,789,012,345.678');
        Observer.Expect('int min|text', 'Negating the minimum value of a twos complement number is invalid.');
        Observer.Expect('int min|code', 'AL:Overflow');
        Observer.Verify();
    end;

    [Test]
    procedure Power_Values()
    var
        Observer: Codeunit "Probe Observer";
        R: Decimal;
    begin
        Observer.Observe('2^10', Format(Power(2, 10)));
        Observer.Observe('2^0', Format(Power(2, 0)));
        Observer.Observe('0^0', Format(Power(0, 0)));
        Observer.Observe('0^1', Format(Power(0, 1)));
        Observer.Observe('2^-1', Format(Power(2, -1)));
        Observer.Observe('2^-2', Format(Power(2, -2)));
        Observer.Observe('-2^3', Format(Power(-2, 3)));
        Observer.Observe('-2^2', Format(Power(-2, 2)));
        Observer.Observe('4^0.5', Format(Power(4, 0.5)));
        Observer.Observe('8^(1/3)', Format(Round(Power(8, 1 / 3), 0.00001)));
        Observer.Observe('1.5^2', Format(Power(1.5, 2)));
        asserterror Observer.Observe('10^15', Format(Power(10, 15)));
        Observer.ObserveError('af156');
        Observer.Observe('1^1000', Format(Power(1, 1000)));
        asserterror R := Power(0, -1);
        Observer.ObserveError('0^-1');
        asserterror R := Power(-8, 0.5);
        Observer.ObserveError('-8^0.5');
        asserterror R := Power(10, 1000);
        Observer.ObserveError('10^1000');
        Observer.Expect('2^10', '1,024');
        Observer.Expect('2^0', '1');
        Observer.Expect('0^0', '1');
        Observer.Expect('0^1', '0');
        Observer.Expect('2^-1', '0.5');
        Observer.Expect('2^-2', '0.25');
        Observer.Expect('-2^3', '-8');
        Observer.Expect('-2^2', '4');
        Observer.Expect('4^0.5', '2');
        Observer.Expect('8^(1/3)', '2');
        Observer.Expect('1.5^2', '2.25');
        Observer.Expect('af156|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 1,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('af156|code', 'OutsidePermittedRange');
        Observer.Expect('1^1000', '1');
        Observer.Expect('0^-1|text', 'Value was either too large or too small for a Decimal.');
        Observer.Expect('0^-1|code', 'AL:Overflow');
        Observer.Expect('-8^0.5|text', 'Value was either too large or too small for a Decimal.');
        Observer.Expect('-8^0.5|code', 'AL:Overflow');
        Observer.Expect('10^1000|text', 'Value was either too large or too small for a Decimal.');
        Observer.Expect('10^1000|code', 'AL:Overflow');
        Observer.Verify();
    end;

}
