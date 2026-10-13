// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-calcdate-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-round-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-strchecksum-method
// Scope: in-scope
// Fixtures used: ALT Status (60009), ALTFixtureCleanup (60019), shared Assert (60021)
// Probe: written against a real BC 27.5 service tier (en-US, UTC); every literal below is what
// that tier produced. Other BC versions were not measured.
//
// Pins CreateDateTime and the ISO week numbers, the forms CalcDate understands (weeks, quarters,
// week days, current periods, formulas without brackets) and its undefined-date error, how a
// DateFormula prints, the picture codes of Format(<...>), the default precision and directions of
// Round, Power, the StrCheckSum algorithm, and the order of Enum Names() and Ordinals().
// BC versions: 27.5

codeunit 68161 "Probe Date Round Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    [Test]
    procedure CreateDateTime_MidnightBlankAndInvalid()
    var
        Result: DateTime;
    begin
        Initialize();

        Assert.AreEqual('2024-03-05T00:00:00Z', Format(CreateDateTime(DMY2Date(5, 3, 2024), 0T), 0, 9), 'a date with 0T is midnight');
        Assert.AreEqual('', Format(CreateDateTime(0D, 0T)), 'both blank: the blank DateTime');
        Assert.AreEqual('12/31/24', Format(DT2Date(CreateDateTime(DMY2Date(31, 12, 2024), 235959T))), 'DT2Date');
        Assert.AreEqual('11:59:59 PM', Format(DT2Time(CreateDateTime(DMY2Date(31, 12, 2024), 235959T))), 'DT2Time');

        asserterror Result := CreateDateTime(0D, 120000T);
        Assert.AreEqual('The date is not valid.', GetLastErrorText(), 'a blank date with a time');
        Assert.AreEqual('DateInvalid', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure Date2DWY_WeekNumbers_AreIso8601()
    begin
        Initialize();

        Assert.AreEqual(2024, Date2DWY(DMY2Date(1, 1, 2024), 3), 'year');
        Assert.AreEqual(1, Date2DWY(DMY2Date(1, 1, 2024), 2), '2024-01-01 is in week 1');
        Assert.AreEqual(52, Date2DWY(DMY2Date(29, 12, 2024), 2), 'Sunday 2024-12-29');
        Assert.AreEqual(1, Date2DWY(DMY2Date(30, 12, 2024), 2), 'Monday 2024-12-30 already belongs to week 1 of 2025');
        Assert.AreEqual(53, Date2DWY(DMY2Date(1, 1, 2021), 2), '2021-01-01 belongs to week 53 of 2020');
        Assert.AreEqual(53, Date2DWY(DMY2Date(3, 1, 2021), 2), '2021-01-03');
        Assert.AreEqual(53, Date2DWY(DMY2Date(31, 12, 2020), 2), '2020-12-31');
    end;

    [Test]
    procedure Date2DMY_Part4_Throws()
    var
        Part: Integer;
    begin
        Initialize();

        asserterror Part := Date2DMY(DMY2Date(5, 3, 2024), 4);

        Assert.AreEqual('The value of DATE2DMY parameter 2 is outside of the permitted range. The current value is: 4. The permitted range is: from 1 to 3.', GetLastErrorText(), 'text');
        Assert.AreEqual('OutsidePermittedRange', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure CalcDate_MonthYearClamping()
    begin
        Initialize();

        Assert.AreEqual('02/29/24', Format(CalcDate('<1M>', DMY2Date(31, 1, 2024))), 'Jan 31 + 1M');
        Assert.AreEqual('12/30/24', Format(CalcDate('<1M>', DMY2Date(30, 11, 2024))), 'Nov 30 + 1M');
        Assert.AreEqual('02/29/24', Format(CalcDate('<-1M>', DMY2Date(31, 3, 2024))), 'Mar 31 - 1M');
        Assert.AreEqual('02/28/25', Format(CalcDate('<1Y>', DMY2Date(29, 2, 2024))), 'Feb 29 + 1Y');
    end;

    [Test]
    procedure CalcDate_WeeksQuartersWeekDaysAndCurrentPeriods()
    var
        Tuesday: Date;
    begin
        Initialize();
        Tuesday := DMY2Date(5, 3, 2024);

        Assert.AreEqual('03/12/24', Format(CalcDate('<1W>', Tuesday)), '+1W');
        Assert.AreEqual('03/10/24', Format(CalcDate('<CW>', Tuesday)), 'end of the current week (Sunday)');
        Assert.AreEqual('03/04/24', Format(CalcDate('<-CW>', Tuesday)), 'start of the current week (Monday)');
        Assert.AreEqual('03/05/24', Format(CalcDate('<CD>', Tuesday)), 'current day');
        Assert.AreEqual('06/05/24', Format(CalcDate('<1Q>', Tuesday)), '+1Q');
        Assert.AreEqual('01/01/24', Format(CalcDate('<-CQ>', Tuesday)), 'start of the quarter');
        Assert.AreEqual('03/31/24', Format(CalcDate('<CQ>', Tuesday)), 'end of the quarter');
        Assert.AreEqual('03/11/24', Format(CalcDate('<WD1>', Tuesday)), 'next Monday');
        Assert.AreEqual('03/04/24', Format(CalcDate('<-WD1>', Tuesday)), 'previous Monday');
        Assert.AreEqual('03/10/24', Format(CalcDate('<WD7>', Tuesday)), 'next Sunday');
        Assert.AreEqual('04/05/24', Format(CalcDate('1M', Tuesday)), 'a formula without brackets is accepted');
        Assert.AreEqual('04/30/24', Format(CalcDate('<1M+CM>', Tuesday)), '<1M+CM>');
        Assert.AreEqual('04/01/24', Format(CalcDate('<CM+1D>', Tuesday)), '<CM+1D>');
        Assert.AreEqual('02/04/24', Format(CalcDate('<-1D-1M>', Tuesday)), '<-1D-1M>');
    end;

    [Test]
    procedure CalcDate_UndefinedDate_Throws()
    var
        Cr: Text[1];
        Result: Date;
    begin
        Initialize();
        Cr[1] := 13;

        asserterror Result := CalcDate('<1D>', 0D);

        Assert.AreEqual('You cannot base a date calculation on an undefined date.' + Cr + '\' + Cr + '\' + 'Date: 0D' + Cr + '\' + 'Formula: 1D.', GetLastErrorText(), 'text');
        Assert.AreEqual('Argument', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure DateFormula_Evaluate_ThenFormat_PrintsTheNormalizedFormula()
    var
        Formula: DateFormula;
    begin
        Initialize();

        Evaluate(Formula, '<1D>');
        Assert.AreEqual('1D', Format(Formula), '<1D>');
        Evaluate(Formula, '<+1M>');
        Assert.AreEqual('+1M', Format(Formula), '<+1M>');
        Evaluate(Formula, '1D');
        Assert.AreEqual('1D', Format(Formula), 'without brackets');
        Evaluate(Formula, '<1D+1M>');
        Assert.AreEqual('1D+1M', Format(Formula), 'two parts');
        Evaluate(Formula, '<-CM>');
        Assert.AreEqual('-CM', Format(Formula), 'current month');
    end;

    [Test]
    procedure Format_PictureCodes()
    var
        Day: Date;
    begin
        Initialize();
        Day := DMY2Date(5, 3, 2024);

        Assert.AreEqual('2024-03-05', Format(Day, 0, '<Year4>-<Month,2>-<Day,2>'), 'padded numbers');
        Assert.AreEqual('5/3/24', Format(Day, 0, '<Day>/<Month>/<Year>'), 'unpadded numbers, two-digit year');
        Assert.AreEqual('March 5 2024', Format(Day, 0, '<Month Text> <Day> <Year4>'), 'month text');
        Assert.AreEqual('Tuesday', Format(Day, 0, '<Weekday Text>'), 'weekday text');
        Assert.AreEqual('05', Format(Day, 0, '<Closing><Day,2>'), 'closing date code');
        Assert.AreEqual('14:30:05', Format(CreateDateTime(Day, 143005T), 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'), 'time parts');
        Assert.AreEqual(' 2:30 PM', Format(143005T, 0, '<Hours12,2>:<Minutes,2> <AM/PM>'), 'twelve-hour clock pads the hour with a space');
        Assert.AreEqual('1,234.50', Format(1234.5, 0, '<Integer Thousand><Decimals,3>'), 'thousands and two decimals');
        Assert.AreEqual('0005', Format(5, 0, '<Integer,4><Filler Character,0>'), 'filler');
        Assert.AreEqual('1', Format(true, 0, '<Standard Format,2>'), 'standard format 2 of a Boolean');
        Assert.AreEqual('1,234.57', Format(1234.567, 0, '<Precision,2:2><Standard Format,0>'), 'precision');
        Assert.AreEqual('-5', Format(-5, 0, '<Sign><Integer>'), 'sign of a negative number');
        Assert.AreEqual(' 5', Format(5, 0, '<Sign,1><Integer>'), 'sign position with a width of 1 for a positive number');
    end;

    [Test]
    procedure Round_DefaultPrecision_Directions_AndPrecisions()
    begin
        Initialize();

        Assert.AreEqual('3', Format(Round(2.5, 1)), '2.5 to 1');
        Assert.AreEqual('-3', Format(Round(-2.5, 1)), '-2.5 to 1');
        Assert.AreEqual('2.5', Format(Round(2.5)), 'the default precision is 0.01');
        Assert.AreEqual('-2.5', Format(Round(-2.5)), 'negative with the default precision');
        Assert.AreEqual('3', Format(Round(2.4999, 1, '>')), '> rounds up');
        Assert.AreEqual('-2', Format(Round(-2.4001, 1, '<')), '< on a negative number');
        Assert.AreEqual('-3', Format(Round(-2.4001, 1, '>')), '> on a negative number');
        Assert.AreEqual('3', Format(Round(2.0001, 1, '>')), '> of a number just above a whole one');
        Assert.AreEqual('1.01', Format(Round(1.005, 0.01)), 'decimal arithmetic: 1.005 to 0.01');
        Assert.AreEqual('1,234.6', Format(Round(1234.5678, 0.1)), 'to 0.1');
        Assert.AreEqual('1,200', Format(Round(1234.5678, 100)), 'to 100');
    end;

    [Test]
    procedure Power_NonWholeAndNegativeExponents()
    begin
        Initialize();

        Assert.AreEqual('1.4142135623731', Format(Power(2, 0.5)), '2 to the power 0.5');
        Assert.AreEqual('0.5', Format(Power(2, -1)), '2 to the power -1');
        Assert.AreEqual('1', Format(Power(0, 0)), '0 to the power 0');
        Assert.AreEqual('-512', Format(Power(-8, 3)), '-8 to the power 3');
    end;

    [Test]
    procedure StrCheckSum_IsModulusMinusWeightedDigitSum_AndWeightsRepeat()
    begin
        Initialize();

        Assert.AreEqual(0, StrCheckSum('12345', '12345', 11), 'weighted sum 55, modulus 11');
        Assert.AreEqual(5, StrCheckSum('12345', '12345', 10), 'weighted sum 55, modulus 10');
        Assert.AreEqual(0, StrCheckSum('1234', '1234', 10), 'weighted sum 30, modulus 10');
        Assert.AreEqual(0, StrCheckSum('0', '1', 10), 'weighted sum 0');
        Assert.AreEqual(0, StrCheckSum('123456789', '987654321', 11), 'weighted sum 165, modulus 11');
        Assert.AreEqual(7, StrCheckSum('12345', '1', 11), 'a short weight string repeats: sum 15, 11 - 4');
        Assert.AreEqual(1, StrCheckSum('9', '1', 10), 'sum 9: 10 - 9');
        Assert.AreEqual(2, StrCheckSum('99', '11', 10), 'sum 18: 10 - 8');
    end;

    [Test]
    procedure Enum_NamesAndOrdinals_AreInDeclarationOrder()
    var
        Names: List of [Text];
        Ordinals: List of [Integer];
        Name: Text;
        Ordinal: Integer;
        NameText: Text;
        OrdinalText: Text;
    begin
        Initialize();

        Names := Enum::"ALT Status".Names();
        Ordinals := Enum::"ALT Status".Ordinals();
        foreach Name in Names do
            NameText += Name + ',';
        foreach Ordinal in Ordinals do
            OrdinalText += Format(Ordinal) + ',';

        Assert.AreEqual(' ,Draft,Active,Closed,Archived,', NameText, 'names');
        Assert.AreEqual('0,1,2,3,4,', OrdinalText, 'ordinals');
    end;

    [Test]
    procedure Decimal_Division_KeepsEighteenSignificantDigits()
    begin
        Initialize();

        Assert.AreEqual('2.333', Format(Round(7 / 3, 0.001)), 'rounded');
        Assert.AreEqual('2.33333333333333333', Format(7 / 3), 'default Format of 7 / 3');
        Assert.AreEqual('0.333333333333333333', Format(1 / 3, 0, 9), 'format 9 of 1 / 3');
        Assert.AreEqual('0.666666666666666667', Format(2 / 3), '2 / 3 is rounded at the last digit');
    end;
}
