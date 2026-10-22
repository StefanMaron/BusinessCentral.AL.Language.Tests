// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-rounddatetime-function
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained codeunit 68960
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins RoundDateTime(DateTime [, Precision [, Direction]]):
//  - the default Precision is 1000 (milliseconds, so seconds) and the default Direction '=' (nearest);
//    12:00:31.500 rounds to 12:00:32;
//  - '=' rounds a value exactly half way up (12:00:30 with precision 60000 gives 12:01:00) and a value just below half
//    (12:00:29.999) down; '<' rounds down and '>' up; a value on a multiple stays whatever the direction;
//  - for 700000, which does not divide a day, 12:00:31 on 2024-03-05 rounds to 12:00:00 with '=' and '<' and to 12:11:40
//    with '>' (so 12:00:00 that day is a multiple; the origin of the count is not derivable from this);
//  - Precision may be a Duration or BigInteger; 0 and negative values raise "The contents '0' of ROUNDDATETIME parameter
//    number 2 are invalid." (code Argument), an unknown direction "The contents 'x' of ROUNDDATETIME parameter number 3 are
//    invalid."; the undefined DateTime stays undefined.
// BC versions: 27.5

codeunit 68960 "Probe RoundDateTime"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure At(Hour: Time; Millis: Integer): DateTime
    begin
        exit(CreateDateTime(DMY2Date(5, 3, 2024), Hour) + Millis);
    end;

    local procedure Rounded(Value: DateTime; Precision: BigInteger; Direction: Text): Text
    begin
        exit(Format(RoundDateTime(Value, Precision, Direction), 0, 9));
    end;

    [Test]
    procedure DefaultsAndMinutePrecision()
    begin
        Assert.AreEqual('2024-03-05T12:00:32Z', Format(RoundDateTime(At(120031T, 500)), 0, 9), 'default');
        Assert.AreEqual('2024-03-05T12:00:32Z', Format(RoundDateTime(At(120031T, 500), 1000), 0, 9), '1000');
        Assert.AreEqual('2024-03-05T12:01:00Z', Format(RoundDateTime(At(120031T, 500), 60000), 0, 9), '60000');
    end;

    [Test]
    procedure Directions_OnAndBetweenMultiples()
    begin
        Assert.AreEqual('2024-03-05T12:00:00Z', Rounded(At(120031T, 500), 180000, '<'), '< below');
        Assert.AreEqual('2024-03-05T12:03:00Z', Rounded(At(120031T, 500), 180000, '>'), '> above');
        Assert.AreEqual('2024-03-05T12:00:00Z', Rounded(At(120031T, 500), 180000, '='), '= nearest');

        Assert.AreEqual('2024-03-05T12:00:00Z', Rounded(At(120000T, 0), 60000, '='), 'on a multiple =');
        Assert.AreEqual('2024-03-05T12:00:00Z', Rounded(At(120000T, 0), 60000, '<'), 'on a multiple <');
        Assert.AreEqual('2024-03-05T12:00:00Z', Rounded(At(120000T, 0), 60000, '>'), 'on a multiple >');

        Assert.AreEqual('2024-03-05T12:01:00Z', Rounded(At(120030T, 0), 60000, '='), 'exactly half way rounds up');
        Assert.AreEqual('2024-03-05T12:00:00Z', Rounded(At(120029T, 999), 60000, '='), 'just below half way');
    end;

    [Test]
    procedure PrecisionThatDoesNotDivideADay_AndOtherTypes()
    var
        Precision: Duration;
    begin
        Assert.AreEqual('2024-03-05T12:00:00Z', Rounded(At(120031T, 0), 700000, '='), '700000 =');
        Assert.AreEqual('2024-03-05T12:00:00Z', Rounded(At(120031T, 0), 700000, '<'), '700000 <');
        Assert.AreEqual('2024-03-05T12:11:40Z', Rounded(At(120031T, 0), 700000, '>'), '700000 >');

        Precision := 180000;
        Assert.AreEqual('2024-03-05T12:00:00Z', Format(RoundDateTime(At(120031T, 0), Precision), 0, 9), 'Duration precision');
        Assert.AreEqual(0DT, RoundDateTime(0DT, 60000), 'the undefined DateTime');
    end;

    [Test]
    procedure InvalidArguments_RaiseArgumentErrors()
    var
        Result: DateTime;
    begin
        asserterror Result := RoundDateTime(At(120031T, 0), 0);
        Assert.AreEqual('The contents ''0'' of ROUNDDATETIME parameter number 2 are invalid.', GetLastErrorText(), 'precision 0');
        Assert.AreEqual('Argument', GetLastErrorCode(), 'code');
        asserterror Result := RoundDateTime(At(120031T, 0), -5);
        Assert.AreEqual('The contents ''-5'' of ROUNDDATETIME parameter number 2 are invalid.', GetLastErrorText(), 'negative');
        asserterror Result := RoundDateTime(At(120031T, 0), 60000, 'x');
        Assert.AreEqual('The contents ''x'' of ROUNDDATETIME parameter number 3 are invalid.', GetLastErrorText(), 'direction');
    end;
}
