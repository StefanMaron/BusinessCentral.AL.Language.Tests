// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-joker-method
// Scope: in-scope
// Fixtures used: shared Assert (60021)
// Probe: written against a real BC 27.5 service tier (en-US); every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins an empty DateFormula (Evaluate of an empty text succeeds, prints as an empty text, and CalcDate
// with it returns the date unchanged) and the standard formats 0, 1, 2 and 9 of a Duration for many
// values: zero, milliseconds only, whole units, more than a day, negative values.
//
// Format 2 of a Duration is a list of pairs "<value> <unit code>" where the unit code is 0 day, 1 days,
// 2 hour, 3 hours, 4 minute, 5 minutes, 6 second, 7 seconds, 8 millisecond, 9 milliseconds. A negative
// Duration carries its sign on the first unit only, in formats 0, 1 and 2; format 9 puts the sign in
// front of the P.
// BC versions: 27.5

codeunit 68320 "Probe DateFormula Duration"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure DateFormula_EvaluateEmptyText_Succeeds_PrintsEmpty_CalcDateReturnsTheDate()
    var
        Formula: DateFormula;
        Day: Date;
    begin
        Day := DMY2Date(5, 3, 2024);

        Assert.IsTrue(Evaluate(Formula, ''), 'Evaluate of an empty text');
        Assert.AreEqual('', Format(Formula), 'Format');
        Assert.AreEqual('', Format(Formula, 0, 9), 'Format 9');
        Assert.AreEqual(Day, CalcDate(Formula, Day), 'CalcDate with the empty formula');
        Assert.AreEqual(Day, CalcDate('', Day), 'CalcDate with an empty text');

        Clear(Formula);
        Assert.AreEqual('', Format(Formula), 'a cleared formula prints empty');
        Assert.AreEqual(Day, CalcDate(Formula, Day), 'and CalcDate returns the date');
    end;

    [Test]
    procedure DateFormula_Evaluate_BlankLikeTexts_AndGarbage()
    var
        Formula: DateFormula;
    begin
        Assert.IsTrue(Evaluate(Formula, '<>'), 'empty brackets');
        Assert.AreEqual('', Format(Formula), 'empty brackets print empty');
        Assert.IsTrue(Evaluate(Formula, ' '), 'a space');
        Assert.AreEqual('', Format(Formula), 'a space prints empty');
        Assert.IsTrue(Evaluate(Formula, '0D'), '0D');
        Assert.AreEqual('0D', Format(Formula), '0D prints as 0D');
        Assert.AreEqual(DMY2Date(5, 3, 2024), CalcDate(Formula, DMY2Date(5, 3, 2024)), 'and moves nothing');
        Assert.IsTrue(Evaluate(Formula, '<0D>'), '<0D>');
        Assert.AreEqual('0D', Format(Formula), '<0D> prints as 0D');
        Assert.IsFalse(Evaluate(Formula, 'xyz'), 'garbage');
        Assert.AreEqual('0D', Format(Formula), 'a failed Evaluate leaves the value');
        Evaluate(Formula, '<1D>');
        Assert.IsTrue(Evaluate(Formula, ''), 'an empty text after <1D>');
        Assert.AreEqual('', Format(Formula), 'replaces it with the empty formula');
    end;

    local procedure Formats(Milliseconds: BigInteger): Text
    var
        Value: Duration;
    begin
        Value := Milliseconds;
        exit(Format(Value, 0, 0) + ' | ' + Format(Value, 0, 1) + ' | ' + Format(Value, 0, 2) + ' | ' + Format(Value, 0, 9));
    end;

    [Test]
    procedure Duration_StandardFormats_ZeroAndMillisecondsOnly()
    begin
        Assert.AreEqual(' |  |  | P0DT0H0M0.0S', Formats(0), '0');
        Assert.AreEqual('1 millisecond | 1 millisecond | 1 8 | P0DT0H0M0.001S', Formats(1), '1');
        Assert.AreEqual('999 milliseconds | 999 milliseconds | 999 9 | P0DT0H0M0.999S', Formats(999), '999');
    end;

    [Test]
    procedure Duration_StandardFormats_WholeUnitsAndMixed()
    begin
        Assert.AreEqual('1 second | 1 second | 1 6 | P0DT0H0M1.0S', Formats(1000), '1000');
        Assert.AreEqual('1 second 1 millisecond | 1 second 1 millisecond | 1 6 1 8 | P0DT0H0M1.001S', Formats(1001), '1001');
        Assert.AreEqual('1 second 500 milliseconds | 1 second 500 milliseconds | 1 6 500 9 | P0DT0H0M1.5S', Formats(1500), '1500');
        Assert.AreEqual('1 minute | 1 minute | 1 4 | P0DT0H1M0.0S', Formats(60000), '1 minute');
        Assert.AreEqual('2 minutes | 2 minutes | 2 5 | P0DT0H2M0.0S', Formats(120000), '2 minutes');
        Assert.AreEqual('1 minute 1 second | 1 minute 1 second | 1 4 1 6 | P0DT0H1M1.0S', Formats(61000), '61 seconds');
        Assert.AreEqual('1 hour | 1 hour | 1 2 | P0DT1H0M0.0S', Formats(3600000), '1 hour');
        Assert.AreEqual('1 hour 1 minute 1 second 1 millisecond | 1 hour 1 minute 1 second 1 millisecond | 1 2 1 4 1 6 1 8 | P0DT1H1M1.001S', Formats(3661001), '3661001');
        Assert.AreEqual('23 hours 59 minutes 59 seconds 999 milliseconds | 23 hours 59 minutes 59 seconds 999 milliseconds | 23 3 59 5 59 7 999 9 | P0DT23H59M59.999S', Formats(86399999), 'just under a day');
    end;

    [Test]
    procedure Duration_StandardFormats_MoreThanADay()
    var
        OneYear: BigInteger;
        Large: BigInteger;
    begin
        Evaluate(OneYear, '31536000000');
        Evaluate(Large, '123456789012');

        Assert.AreEqual('1 day | 1 day | 1 0 | P1DT0H0M0.0S', Formats(86400000), 'one day');
        Assert.AreEqual('1 day 1 hour 1 minute 1 second 1 millisecond | 1 day 1 hour 1 minute 1 second 1 millisecond | 1 0 1 2 1 4 1 6 1 8 | P1DT1H1M1.001S', Formats(90061001), '90061001');
        Assert.AreEqual('2 days | 2 days | 2 1 | P2DT0H0M0.0S', Formats(172800000), 'two days');
        Assert.AreEqual('2 days 5 milliseconds | 2 days 5 milliseconds | 2 1 5 9 | P2DT0H0M0.005S', Formats(172800005), 'two days and 5 ms');
        Assert.AreEqual('365 days | 365 days | 365 1 | P365DT0H0M0.0S', Formats(OneYear), 'a year');
        Assert.AreEqual('1428 days 21 hours 33 minutes 9 seconds 12 milliseconds | 1428 days 21 hours 33 minutes 9 seconds 12 milliseconds | 1428 1 21 3 33 5 9 7 12 9 | P1428DT21H33M9.012S', Formats(Large), 'a large value');
    end;

    [Test]
    procedure Duration_StandardFormats_Negative()
    begin
        Assert.AreEqual('-1 millisecond | -1 millisecond | -1 8 | -P0DT0H0M0.001S', Formats(-1), '-1');
        Assert.AreEqual('-1 second | -1 second | -1 6 | -P0DT0H0M1.0S', Formats(-1000), '-1000');
        Assert.AreEqual('-1 day 1 hour 1 minute 1 second 1 millisecond | -1 day 1 hour 1 minute 1 second 1 millisecond | -1 0 1 2 1 4 1 6 1 8 | -P1DT1H1M1.001S', Formats(-90061001), 'the sign is on the first unit only');
    end;
}
