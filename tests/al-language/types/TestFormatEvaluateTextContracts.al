// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-joker-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: ALTFixtureCleanup (60019), shared Assert (60021)
// Probe: written against a real BC 27.5 service tier (en-US, UTC); every literal below is what
// that tier produced. Other BC versions were not measured.
//
// Pins the standard formats of Format for Decimal, Date, Time, DateTime, Duration and Boolean,
// the Evaluate rules for Date and Boolean, text comparison, operand evaluation of and/or,
// the error code of Error(), and text helpers (Trim, Split, TextBuilder.AppendLine, SelectStr,
// ConvertStr, Substring, IncStr).
// BC versions: 27.5

codeunit 68121 "Probe Format Eval Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        Calls: Text;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        Calls := '';
    end;

    [Test]
    procedure Format_Decimal_StandardFormats()
    // CLAIM: format 0 groups thousands with commas; formats 1, 2 and 9 do not; format 2 does not pad decimals.
    begin
        Initialize();

        Assert.AreEqual('1,234,567.891', Format(1234567.891, 0, 0), 'format 0');
        Assert.AreEqual('1234567.891', Format(1234567.891, 0, 1), 'format 1');
        Assert.AreEqual('1234567.891', Format(1234567.891, 0, 2), 'format 2');
        Assert.AreEqual('1234567.891', Format(1234567.891, 0, 9), 'format 9');
        Assert.AreEqual('1.5', Format(1.5, 0, 2), 'format 2 of 1.50');
        Assert.AreEqual('1.5', Format(1.5), 'default format of 1.50');
        Assert.AreEqual('-5.5', Format(-5.5), 'negative');
    end;

    [Test]
    procedure Format_Date_StandardFormats()
    var
        TestDate: Date;
    begin
        Initialize();
        TestDate := DMY2Date(5, 3, 2024);

        Assert.AreEqual('03/05/24', Format(TestDate, 0, 0), 'format 0');
        Assert.AreEqual('03/05/24', Format(TestDate, 0, 1), 'format 1');
        Assert.AreEqual('030524D', Format(TestDate, 0, 2), 'format 2');
        Assert.AreEqual('24/03/05', Format(TestDate, 0, 3), 'format 3');
        Assert.AreEqual('March 5, 2024', Format(TestDate, 0, 4), 'format 4');
        Assert.AreEqual('030524', Format(TestDate, 0, 5), 'format 5');
        Assert.AreEqual('240305', Format(TestDate, 0, 6), 'format 6');
        Assert.AreEqual('Mar 5, 2024', Format(TestDate, 0, 7), 'format 7');
        Assert.AreEqual('2024-03-05', Format(TestDate, 0, 9), 'format 9');
        Assert.AreEqual('', Format(0D), 'the blank date');
    end;

    [Test]
    procedure Format_Date_Format8_DoesNotExist()
    var
        TestDate: Date;
        Result: Text;
    begin
        Initialize();
        TestDate := DMY2Date(5, 3, 2024);

        asserterror Result := Format(TestDate, 0, 8);

        Assert.AreEqual('Standard format number 8 does not exist for the type ''Date''.', GetLastErrorText(), 'text');
        Assert.AreEqual('InvalidStandardFormat', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure Format_Time_StandardFormats()
    // CLAIM: format 2 is the AL literal (hhmmss.fffT), not a 12-hour clock; format 0 pads the hour with a space.
    begin
        Initialize();

        Assert.AreEqual(' 2:30:05 PM', Format(143005.123T, 0, 0), 'format 0');
        Assert.AreEqual(' 2:30:05.123 PM', Format(143005.123T, 0, 1), 'format 1');
        Assert.AreEqual('143005.123T', Format(143005.123T, 0, 2), 'format 2');
        Assert.AreEqual('235959T', Format(235959T, 0, 2), 'format 2 without milliseconds');
        Assert.AreEqual('000500T', Format(000500T, 0, 2), 'format 2 early morning');
        Assert.AreEqual('14:30:05.123', Format(143005.123T, 0, 9), 'format 9');
        Assert.AreEqual('12:00:00 AM', Format(000000T), 'midnight');
        Assert.AreEqual('', Format(0T), 'the blank time');
    end;

    [Test]
    procedure Format_DateTime_StandardFormats()
    var
        TestDateTime: DateTime;
    begin
        Initialize();
        TestDateTime := CreateDateTime(DMY2Date(5, 3, 2024), 143005.123T);

        Assert.AreEqual('03/05/24 02:30 PM', Format(TestDateTime, 0, 0), 'format 0');
        Assert.AreEqual('03/05/24 02:30:05.123 PM', Format(TestDateTime, 0, 1), 'format 1');
        Assert.AreEqual('03/05/24 02:30 PM', Format(TestDateTime, 0, 2), 'format 2');
        Assert.AreEqual('2024-03-05T14:30:05.123Z', Format(TestDateTime, 0, 9), 'format 9');
        Assert.AreEqual('03/05/24 11:59 PM', Format(CreateDateTime(DMY2Date(5, 3, 2024), 235900T), 0, 2), 'late evening');
        Assert.AreEqual('03/05/24 12:00 AM', Format(CreateDateTime(DMY2Date(5, 3, 2024), 000000T), 0, 2), 'midnight');
        Assert.AreEqual('03/05/24 12:00 PM', Format(CreateDateTime(DMY2Date(5, 3, 2024), 120000T), 0, 2), 'noon');
        Assert.AreEqual('2024-03-05T14:30:05.007Z', Format(CreateDateTime(DMY2Date(5, 3, 2024), 143005.007T), 0, 9), 'milliseconds are padded');
        Assert.AreEqual('', Format(0DT), 'the blank datetime');
    end;

    [Test]
    procedure Format_Duration_StandardFormats()
    var
        TestDuration: Duration;
    begin
        Initialize();
        TestDuration := 90061001;

        Assert.AreEqual('1 day 1 hour 1 minute 1 second 1 millisecond', Format(TestDuration, 0, 0), 'format 0');
        Assert.AreEqual('1 day 1 hour 1 minute 1 second 1 millisecond', Format(TestDuration, 0, 1), 'format 1');
        Assert.AreEqual('P1DT1H1M1.001S', Format(TestDuration, 0, 9), 'format 9');
    end;

    [Test]
    procedure Format_Boolean_StandardFormats()
    begin
        Initialize();

        Assert.AreEqual('Yes', Format(true, 0, 0), 'format 0');
        Assert.AreEqual('Yes', Format(true, 0, 1), 'format 1');
        Assert.AreEqual('1', Format(true, 0, 2), 'format 2');
        Assert.AreEqual('true', Format(true, 0, 9), 'format 9');
        Assert.AreEqual('false', Format(false, 0, 9), 'format 9 of false');
    end;

    local procedure ReturnsTrue(): Boolean
    begin
        Calls += 'T';
        exit(true);
    end;

    local procedure ReturnsFalse(): Boolean
    begin
        Calls += 'F';
        exit(false);
    end;

    [Test]
    procedure Operators_AndOr_EvaluateBothOperands()
    // CLAIM: there is no short-circuit: the right operand is called even when the left one decides the result.
    var
        Result: Boolean;
    begin
        Initialize();

        Result := ReturnsFalse() and ReturnsTrue();
        Assert.IsFalse(Result, 'false and true');
        Assert.AreEqual('FT', Calls, 'and calls both');

        Calls := '';
        Result := ReturnsTrue() or ReturnsFalse();
        Assert.IsTrue(Result, 'true or false');
        Assert.AreEqual('TF', Calls, 'or calls both');
    end;

    [Test]
    procedure Operators_TextComparison_IsCultureOrderAndCaseSensitiveEquality()
    // CLAIM: = is case sensitive and does not ignore a trailing space; < and > follow the culture order (lower case before upper case, accents after the plain letter), not code points.
    begin
        Initialize();

        Assert.IsFalse('a' = 'A', 'a = A');
        Assert.IsFalse('abc' = 'abc ', 'abc = "abc "');
        Assert.IsTrue('a' < 'A', 'a < A');
        Assert.IsTrue('a' < 'B', 'a < B');
        Assert.IsTrue('A' < 'b', 'A < b');
        Assert.IsFalse('Z' < 'a', 'Z < a would be true by code point');
        Assert.IsTrue('_' < 'a', '_ < a');
        Assert.IsTrue('1' < 'A', '1 < A');
        Assert.IsTrue('ä' > 'a', 'a with diaeresis > a');
        Assert.IsTrue('ä' < 'b', 'a with diaeresis < b');
        Assert.IsTrue('a b' < 'ab', 'a b < ab');
        Assert.IsTrue('' < 'a', 'empty < a');
    end;

    [Test]
    procedure Code_Assignment_UpperCasesAndTrims()
    var
        CodeValue: Code[10];
    begin
        Initialize();

        CodeValue := '  ab c  ';

        Assert.AreEqual('AB C', Format(CodeValue), 'trimmed and upper case; the inner space stays');
    end;

    [Test]
    procedure Error_WithText_HasErrorCodeDialog()
    begin
        Initialize();

        asserterror Error('plain %1', 1);
        Assert.AreEqual('plain 1', GetLastErrorText(), 'text');
        Assert.AreEqual('Dialog', GetLastErrorCode(), 'code');

        asserterror Error('');
        Assert.AreEqual('', GetLastErrorText(), 'empty text');
        Assert.AreEqual('Dialog', GetLastErrorCode(), 'code of Error with an empty text');
    end;

    [Test]
    procedure Asserterror_NothingRaised_ReportsAssertError()
    // CLAIM: an asserterror block that raises nothing fails with this text and code AssertError.
    var
        Ok: Boolean;
    begin
        Initialize();

        Commit();
        Ok := Codeunit.Run(Codeunit::"Probe No Error Runner");

        Assert.IsFalse(Ok, 'the guarded run fails');
        Assert.AreEqual('An error was expected inside an ASSERTERROR statement.', GetLastErrorText(), 'text');
        Assert.AreEqual('AssertError', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure Evaluate_Date_TwoDigitYear_PivotsAt50()
    // CLAIM: 00..49 are 2000..2049 and 50..99 are 1950..1999.
    var
        TestDate: Date;
    begin
        Initialize();

        Assert.IsTrue(Evaluate(TestDate, '01/02/00'), '00');
        Assert.AreEqual('2000-01-02', Format(TestDate, 0, 9), '00');
        Evaluate(TestDate, '01/02/29');
        Assert.AreEqual('2029-01-02', Format(TestDate, 0, 9), '29');
        Evaluate(TestDate, '01/02/30');
        Assert.AreEqual('2030-01-02', Format(TestDate, 0, 9), '30');
        Evaluate(TestDate, '01/02/49');
        Assert.AreEqual('2049-01-02', Format(TestDate, 0, 9), '49');
        Evaluate(TestDate, '01/02/50');
        Assert.AreEqual('1950-01-02', Format(TestDate, 0, 9), '50');
        Evaluate(TestDate, '01/02/99');
        Assert.AreEqual('1999-01-02', Format(TestDate, 0, 9), '99');
        Assert.IsTrue(Evaluate(TestDate, '2024-03-05'), 'ISO date');
        Assert.AreEqual('2024-03-05', Format(TestDate, 0, 9), 'ISO date');
        Assert.IsFalse(Evaluate(TestDate, '13/45/24'), 'month 13');
    end;

    [Test]
    procedure Evaluate_Boolean_AcceptsTrueFalseYesNoOneAndT_IgnoringCase()
    var
        Flag: Boolean;
    begin
        Initialize();

        Flag := true;
        Assert.IsTrue(Evaluate(Flag, 'false'), 'false');
        Assert.IsFalse(Flag, 'false');
        Flag := false;
        Assert.IsTrue(Evaluate(Flag, 'TRUE'), 'TRUE');
        Assert.IsTrue(Flag, 'TRUE');
        Flag := false;
        Assert.IsTrue(Evaluate(Flag, 'yes'), 'yes');
        Assert.IsTrue(Flag, 'yes');
        Flag := true;
        Assert.IsTrue(Evaluate(Flag, 'No'), 'No');
        Assert.IsFalse(Flag, 'No');
        Flag := false;
        Assert.IsTrue(Evaluate(Flag, '1'), '1');
        Assert.IsTrue(Flag, '1');
        Flag := false;
        Assert.IsTrue(Evaluate(Flag, 'T'), 'T');
        Assert.IsTrue(Flag, 'T');
        Flag := false;
        Assert.IsFalse(Evaluate(Flag, 'Ja'), 'Ja is refused');
        Assert.IsFalse(Flag, 'Ja leaves the variable');
    end;

    [Test]
    procedure Evaluate_Failed_LeavesTheVariableUnchanged()
    var
        IntegerValue: Integer;
        DateValue: Date;
        DecimalValue: Decimal;
    begin
        Initialize();

        IntegerValue := 7;
        Assert.IsFalse(Evaluate(IntegerValue, 'abc'), 'integer');
        Assert.AreEqual(7, IntegerValue, 'integer unchanged');
        DateValue := 20240101D;
        Assert.IsFalse(Evaluate(DateValue, 'garbage'), 'date');
        Assert.AreEqual(20240101D, DateValue, 'date unchanged');
        Assert.IsTrue(Evaluate(DecimalValue, '1,234.5'), 'decimal with a thousands separator');
        Assert.AreEqual(1234.5, DecimalValue, 'decimal value');
    end;

    [Test]
    procedure Text_Trim_RemovesWhiteSpaceIncludingNoBreakSpace_AndTrimStartEndTakeACharacterSet()
    var
        Nbsp: Text[1];
        LineFeed: Text[1];
    begin
        Initialize();
        Nbsp[1] := 160;
        LineFeed[1] := 10;

        Assert.AreEqual(2, StrLen((Nbsp + 'ab').Trim()), 'no-break space');
        Assert.AreEqual(2, StrLen((LineFeed + 'ab' + LineFeed).Trim()), 'line feed');
        Assert.AreEqual('abxx', 'xxabxx'.TrimStart('x'), 'TrimStart with a character');
        Assert.AreEqual('xxab', 'xxabxx'.TrimEnd('x'), 'TrimEnd with a character');
        Assert.AreEqual('abyx', 'xyabyx'.TrimStart('xy'), 'TrimStart with a set');
        Assert.AreEqual('xyab', 'xyabyx'.TrimEnd('xy'), 'TrimEnd with a set');
    end;

    [Test]
    procedure Text_Split_TriesSeparatorsInOrderAndKeepsEmptyParts()
    var
        Parts: List of [Text];
    begin
        Initialize();

        Assert.AreEqual(3, 'a,b;c'.Split(',', ';').Count(), 'two separators');
        Assert.AreEqual(4, 'a  b c'.Split().Count(), 'no separator splits on white space and keeps the empty part');
        Assert.AreEqual(3, 'a,,b'.Split(',').Count(), 'empty part kept');
        Parts := 'a-->b'.Split('-', '-->');
        Assert.AreEqual(3, Parts.Count(), 'overlapping separators');
        Assert.AreEqual('a', Parts.Get(1), 'first');
        Assert.AreEqual('', Parts.Get(2), 'second: the first separator in the list wins at each position');
        Assert.AreEqual('>b', Parts.Get(3), 'third');
        Assert.AreEqual(1, 'hello'.Split('').Count(), 'an empty separator does not split');
    end;

    [Test]
    procedure Text_DelChr_WithoutWhich_RemovesSpaces()
    begin
        Initialize();

        Assert.AreEqual('ab', DelChr('  a b  '), 'default removes spaces');
        Assert.AreEqual('a b  ', DelChr('  a b  ', '<'), 'leading');
        Assert.AreEqual('ab', DelChr('  a b  ', '='), 'all');
    end;

    [Test]
    procedure TextBuilder_AppendLine_EndsWithNewLineOnly()
    var
        Builder: TextBuilder;
        NewLine: Text[2];
    begin
        Initialize();
        NewLine[1] := 13;
        NewLine[2] := 10;

        Builder.AppendLine('x');
        Builder.Append('y');
        Assert.AreEqual('x' + NewLine + 'y', Builder.ToText(), 'AppendLine adds LF');

        Builder.Clear();
        Builder.AppendLine();
        Assert.AreEqual(NewLine, Builder.ToText(), 'AppendLine without text');
    end;

    [Test]
    procedure SelectStr_IndexOutsideTheList_Throws()
    var
        Result: Text;
    begin
        Initialize();

        asserterror Result := SelectStr(4, 'a,b,c');
        Assert.AreEqual('The SELECTSTR comma-string a,b,c does not contain a value for index 4.', GetLastErrorText(), 'index 4');
        Assert.AreEqual('InvalidStringFormat', GetLastErrorCode(), 'code');

        asserterror Result := SelectStr(0, 'a,b,c');
        Assert.AreEqual('The SELECTSTR comma-string a,b,c does not contain a value for index 0.', GetLastErrorText(), 'index 0');

        asserterror Result := SelectStr(-1, 'a,b,c');
        Assert.AreEqual('The SELECTSTR comma-string a,b,c does not contain a value for index -1.', GetLastErrorText(), 'index -1');
    end;

    [Test]
    procedure Text_EmptyArguments_ContainsStartsEndsAreTrueIndexOfIsOne()
    var
        Value: Text;
    begin
        Initialize();
        Value := 'hello';

        Assert.IsTrue(Value.Contains(''), 'Contains');
        Assert.IsTrue(Value.StartsWith(''), 'StartsWith');
        Assert.IsTrue(Value.EndsWith(''), 'EndsWith');
        Assert.AreEqual(1, Value.IndexOf(''), 'IndexOf');
        Assert.AreEqual(6, Value.LastIndexOf(''), 'LastIndexOf');
        Assert.AreEqual(3, Value.LastIndexOf('l', 3), 'LastIndexOf with a start index');

        asserterror Value := Value.Replace('', 'x');
        Assert.AreEqual('The value cannot be an empty string. (Parameter ''oldValue'')', GetLastErrorText(), 'Replace text');
        Assert.AreEqual('Argument', GetLastErrorCode(), 'Replace code');
    end;

    [Test]
    procedure Text_OutOfRangeArguments()
    var
        Value: Text;
    begin
        Initialize();
        Value := 'hello';

        asserterror Value := Value.Substring(7);
        Assert.AreEqual('startIndex cannot be larger than length of string. (Parameter ''startIndex'')', GetLastErrorText(), 'Substring start beyond the end');
        Assert.AreEqual('ArgumentOutOfRange', GetLastErrorCode(), 'Substring code');
        Value := 'hello';
        Assert.AreEqual('ello', Value.Substring(2, 10), 'Substring length beyond the end is clamped');
        Assert.AreEqual('hello', DelStr(Value, 9), 'DelStr beyond the end');
        Assert.AreEqual('hellox', InsStr(Value, 'x', 9), 'InsStr beyond the end appends');
        Assert.AreEqual('', CopyStr(Value, 9), 'CopyStr beyond the end');

        asserterror Value := ConvertStr(Value, 'abc', 'x');
        Assert.AreEqual('ALConvertStr expects 2 strings in the conversion to be of equal length: Converting from abc to x.', GetLastErrorText(), 'ConvertStr text');
        Assert.AreEqual('InvalidStringFormat', GetLastErrorCode(), 'ConvertStr code');
    end;

    [Test]
    procedure IncStr_IncrementsTheLastDigitBlock()
    begin
        Initialize();

        Assert.AreEqual('A10', IncStr('A9'), 'carry');
        Assert.AreEqual('A02', IncStr('A01'), 'width kept');
        Assert.AreEqual('100', IncStr('99'), 'all digits');
        Assert.AreEqual('A2B', IncStr('A1B'), 'digits not at the end');
        Assert.AreEqual('', IncStr('ab'), 'no digits');
    end;
}

codeunit 68122 "Probe No Error Runner"
{
    trigger OnRun()
    begin
        asserterror;
    end;
}
