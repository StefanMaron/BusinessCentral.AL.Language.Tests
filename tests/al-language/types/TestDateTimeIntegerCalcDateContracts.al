// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-calcdate-function
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained codeunit 68991
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins:
//  - DateTime + Integer, BigInteger and an integer constant add MILLISECONDS (12:00:00 + 1000 is 12:00:01); DateTime - Integer subtracts
//    them; DateTime - DateTime is a Duration; a Decimal with a fraction raises the conversion error
//    "Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1000.5 to System.Int64.".
//  - CalcDate(DateFormula) and CalcDate(Text) without a date count from TODAY, not from WorkDate: after WorkDate is moved to another
//    date the result is the same as CalcDate(formula, Today()).
// BC versions: 27.5

codeunit 68991 "Probe DateTime Int CalcDate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure DateTimePlusInteger_AddsMilliseconds()
    var
        Stamp: DateTime;
        IntVal: Integer;
        BigVal: BigInteger;
    begin
        Stamp := CreateDateTime(DMY2Date(5, 3, 2024), 120000T);
        IntVal := 1000;
        BigVal := 1000;

        Assert.AreEqual('2024-03-05T12:00:01Z', Format(Stamp + IntVal, 0, 9), 'Integer variable');
        Assert.AreEqual('2024-03-05T12:00:01Z', Format(Stamp + BigVal, 0, 9), 'BigInteger variable');
        Assert.AreEqual('2024-03-05T12:00:01Z', Format(Stamp + 1000, 0, 9), 'constant');
        Assert.AreEqual('2024-03-05T11:59:59Z', Format(Stamp - IntVal, 0, 9), 'minus');
        Assert.AreEqual('2024-03-05T12:16:40Z', Format(Stamp + (IntVal * 1000), 0, 9), '1000 seconds');
        Assert.AreEqual('5 seconds', Format(Stamp - (Stamp - 5000)), 'DateTime - DateTime');
    end;

    [Test]
    procedure DateTimePlusDecimalWithFraction_RaisesAConversionError()
    var
        Stamp: DateTime;
        DecVal: Decimal;
        Result: DateTime;
    begin
        Stamp := CreateDateTime(DMY2Date(5, 3, 2024), 120000T);
        DecVal := 1000.5;

        asserterror Result := Stamp + DecVal;

        Assert.AreEqual('Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1000.5 to System.Int64.', GetLastErrorText(), 'text');
    end;

    [Test]
    procedure CalcDateWithoutADate_UsesToday_NotWorkDate()
    var
        Formula: DateFormula;
        OldWorkDate: Date;
    begin
        Evaluate(Formula, '1D');
        OldWorkDate := WorkDate();

        WorkDate(CalcDate('<-1Y>', Today()));
        Assert.AreEqual(CalcDate(Formula, Today()), CalcDate(Formula), 'DateFormula');
        Assert.AreEqual(CalcDate('<CM>', Today()), CalcDate('<CM>'), 'text');
        Assert.AreNotEqual(CalcDate(Formula, WorkDate()), CalcDate(Formula), 'not WorkDate');

        WorkDate(OldWorkDate);
    end;
}
