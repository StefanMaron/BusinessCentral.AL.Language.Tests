// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/decimal/decimal-data-type
// Scope: in-scope
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier produced. Other BC versions were not measured.
//
// A Decimal given to an Integer parameter or assigned to an Integer variable: an integral value (2, 2.0, -3, 2147483647, an integral Decimal variable) converts; ANY fraction
// (1.5, 1.4, -1.5, 0.0001, also 2.4 and -2.5 by assignment) and a value beyond Integer (3000000000) raise "Overflow under conversion of
// Microsoft.Dynamics.Nav.Runtime.Decimal18 value <value> to System.Int32." with the code ConversionCast; there is NO rounding. The same refusal happens for a page extension
// overload (pageext/POPageExtOverload.al, Describe(1.5) resolves to the Integer overload).
// Fixtures used: self-contained codeunit 69551
// BC versions: 27.5

codeunit 69551 "PR Decimal Integer Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TakeInteger(Value: Integer): Text
    begin
        exit('int:' + Format(Value));
    end;

    local procedure TakeBigInteger(Value: BigInteger): Text
    begin
        exit('big:' + Format(Value));
    end;

    [TryFunction]
    local procedure TryTake(Dec: Decimal; var Result: Text)
    begin
        Result := TakeInteger(Dec);
    end;

    local procedure Try(Dec: Decimal): Text
    var
        Result: Text;
    begin
        if TryTake(Dec, Result) then
            exit(Result);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure DecimalToIntegerParameter_ValuesAndErrors()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('integral_2', Try(2));
        Observer.Observe('integral_2_0', Try(2.0));
        Observer.Observe('minus_3', Try(-3));
        Observer.Observe('one_point_five', Try(1.5));
        Observer.Observe('one_point_four', Try(1.4));
        Observer.Observe('minus_one_point_five', Try(-1.5));
        Observer.Observe('tiny_fraction', Try(0.0001));
        Observer.Observe('too_large', Try(3000000000.0));
        Observer.Observe('max_integer', Try(2147483647));
        Observer.Expect('integral_2', 'int:2');
        Observer.Expect('integral_2_0', 'int:2');
        Observer.Expect('minus_3', 'int:-3');
        Observer.Expect('one_point_five', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.5 to System.Int32.|ConversionCast');
        Observer.Expect('one_point_four', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.4 to System.Int32.|ConversionCast');
        Observer.Expect('minus_one_point_five', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -1.5 to System.Int32.|ConversionCast');
        Observer.Expect('tiny_fraction', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.0001 to System.Int32.|ConversionCast');
        Observer.Expect('too_large', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 3000000000.0 to System.Int32.|ConversionCast');
        Observer.Expect('max_integer', 'int:2147483647');
        Observer.Verify();
    end;

    [Test]
    procedure DecimalAssignedToInteger_RoundsOrRaises()
    var
        Dec: Decimal;
        I: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        Dec := 3;
        I := Dec;
        Observer.Observe('assign_integral', Format(I));
        Dec := 1.5;
        asserterror I := Dec;
        Observer.ObserveError('assign_1_5');
        Dec := 2.4;
        asserterror I := Dec;
        Observer.ObserveError('assign_2_4');
        Dec := -2.5;
        asserterror I := Dec;
        Observer.ObserveError('assign_minus_2_5');
        Observer.Expect('assign_integral', '3');
        Observer.Expect('assign_1_5|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.5 to System.Int32.');
        Observer.Expect('assign_1_5|code', 'ConversionCast');
        Observer.Expect('assign_2_4|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.4 to System.Int32.');
        Observer.Expect('assign_2_4|code', 'ConversionCast');
        Observer.Expect('assign_minus_2_5|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -2.5 to System.Int32.');
        Observer.Expect('assign_minus_2_5|code', 'ConversionCast');
        Observer.Verify();
    end;
}
