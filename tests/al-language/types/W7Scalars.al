// Batch 7 probes: Power, Text to Guid, Decimal multiplication, text order, DateTime + Decimal, RoundDateTime origin. Observe only.
codeunit 68271 "W7 Scalars"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Ch(Code: Integer): Text
    var
        T: Text[1];
    begin
        T[1] := Code;
        exit(T);
    end;

    [TryFunction]
    local procedure TryPower(Base: Decimal; Exponent: Decimal; var Result: Decimal)
    begin
        Result := Power(Base, Exponent);
    end;

    local procedure PowerText(Base: Decimal; Exponent: Decimal): Text
    var
        Result: Decimal;
    begin
        if TryPower(Base, Exponent, Result) then
            exit(Format(Result, 0, 9));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryTextToGuid(Value: Text; var Result: Guid)
    begin
        Result := Value;
    end;

    local procedure GuidText(Value: Text): Text
    var
        Result: Guid;
    begin
        if TryTextToGuid(Value, Result) then
            exit(Format(Result, 0, 9));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure TextToGuid_AssignmentForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('braces_lower', GuidText('{0a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d}'));
        Observer.Observe('no_braces_lower', GuidText('0a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d'));
        Observer.Observe('braces_upper', GuidText('{0A1B2C3D-4E5F-6A7B-8C9D-0E1F2A3B4C5D}'));
        Observer.Observe('no_hyphens', GuidText('0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d'));
        Observer.Observe('only_open_brace', GuidText('{0a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d'));
        Observer.Observe('empty', GuidText(''));
        Observer.Observe('blank', GuidText('   '));
        Observer.Observe('too_short', GuidText('0a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5'));
        Observer.Observe('too_long', GuidText('0a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d0'));
        Observer.Observe('not_hex', GuidText('0a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5g'));
        Observer.Observe('padded', GuidText(' 0a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d '));
        Observer.Observe('null_guid_text', GuidText('00000000-0000-0000-0000-000000000000'));
        Observer.Observe('text', GuidText('hello'));
        Observer.Expect('braces_lower', '{0A1B2C3D-4E5F-6A7B-8C9D-0E1F2A3B4C5D}');
        Observer.Expect('no_braces_lower', '{0A1B2C3D-4E5F-6A7B-8C9D-0E1F2A3B4C5D}');
        Observer.Expect('braces_upper', '{0A1B2C3D-4E5F-6A7B-8C9D-0E1F2A3B4C5D}');
        Observer.Expect('no_hyphens', '{0A1B2C3D-4E5F-6A7B-8C9D-0E1F2A3B4C5D}');
        Observer.Expect('only_open_brace', 'error:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidGuidFormat');
        Observer.Expect('empty', 'error:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidGuidFormat');
        Observer.Expect('blank', 'error:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidGuidFormat');
        Observer.Expect('too_short', 'error:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidGuidFormat');
        Observer.Expect('too_long', 'error:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidGuidFormat');
        Observer.Expect('not_hex', 'error:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidGuidFormat');
        Observer.Expect('padded', '{0A1B2C3D-4E5F-6A7B-8C9D-0E1F2A3B4C5D}');
        Observer.Expect('null_guid_text', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('text', 'error:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidGuidFormat');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryMultiply(Left: Decimal; Right: Decimal; var Product: Decimal)
    begin
        Product := Left * Right;
    end;

    local procedure SortedCodes(Codes: List of [Integer]): Text
    var
        Items: List of [Text];
        Code: Integer;
        Item: Text;
        Current: Text;
        i: Integer;
        j: Integer;
        Result: Text;
    begin
        foreach Code in Codes do
            Items.Add(Ch(Code));
        for i := 2 to Items.Count() do begin
            Current := Items.Get(i);
            j := i - 1;
            while (j >= 1) and (Items.Get(j) > Current) do begin
                Items.Set(j + 1, Items.Get(j));
                j -= 1;
            end;
            Items.Set(j + 1, Current);
        end;
        foreach Item in Items do begin
            Code := Item[1];
            Result += Format(Code) + ' ';
        end;
        exit(Result);
    end;

    local procedure Range(From: Integer; UpTo: Integer; var Codes: List of [Integer])
    var
        n: Integer;
    begin
        for n := From to UpTo do
            Codes.Add(n);
    end;

    local procedure CompareText(Left: Text; Right: Text): Text
    begin
        if Left < Right then
            exit('<');
        if Left > Right then
            exit('>');
        if Left = Right then
            exit('=');
        exit('?');
    end;

    [Test]
    procedure TextOrder_PairsOfDifferentAccentsAndOtherLetters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('a-grave vs a-acute', CompareText(Ch(224), Ch(225)));
        Observer.Observe('a-acute vs a-circumflex', CompareText(Ch(225), Ch(226)));
        Observer.Observe('a-diaeresis vs a-ring', CompareText(Ch(228), Ch(229)));
        Observer.Observe('a-ring vs b', CompareText(Ch(229), 'b'));
        Observer.Observe('e-acute vs e-grave', CompareText(Ch(233), Ch(232)));
        Observer.Observe('o-diaeresis vs o-stroke', CompareText(Ch(246), Ch(248)));
        Observer.Observe('o-stroke vs p', CompareText(Ch(248), 'p'));
        Observer.Observe('sharp s vs ss', CompareText(Ch(223), 'ss'));
        Observer.Observe('sharp s vs s', CompareText(Ch(223), 's'));
        Observer.Observe('sharp s vs t', CompareText(Ch(223), 't'));
        Observer.Observe('ae ligature vs ae', CompareText(Ch(230), 'ae'));
        Observer.Observe('ae ligature vs af', CompareText(Ch(230), 'af'));
        Observer.Observe('l-stroke vs l', CompareText(Ch(322), 'l'));
        Observer.Observe('l-stroke vs m', CompareText(Ch(322), 'm'));
        Observer.Observe('s-caron vs s', CompareText(Ch(353), 's'));
        Observer.Observe('s-caron vs t', CompareText(Ch(353), 't'));
        Observer.Observe('a-macron vs a', CompareText(Ch(257), 'a'));
        Observer.Observe('a-macron vs a-acute', CompareText(Ch(257), Ch(225)));
        Observer.Observe('alpha vs z', CompareText(Ch(945), 'z'));
        Observer.Observe('cyrillic ya vs z', CompareText(Ch(1103), 'z'));
        Observer.Observe('euro vs 9', CompareText(Ch(8364), '9'));
        Observer.Observe('euro vs a', CompareText(Ch(8364), 'a'));
        Observer.Expect('a-grave vs a-acute', '>');
        Observer.Expect('a-acute vs a-circumflex', '<');
        Observer.Expect('a-diaeresis vs a-ring', '>');
        Observer.Expect('a-ring vs b', '<');
        Observer.Expect('e-acute vs e-grave', '<');
        Observer.Expect('o-diaeresis vs o-stroke', '<');
        Observer.Expect('o-stroke vs p', '<');
        Observer.Expect('sharp s vs ss', '>');
        Observer.Expect('sharp s vs s', '>');
        Observer.Expect('sharp s vs t', '<');
        Observer.Expect('ae ligature vs ae', '>');
        Observer.Expect('ae ligature vs af', '<');
        Observer.Expect('l-stroke vs l', '>');
        Observer.Expect('l-stroke vs m', '<');
        Observer.Expect('s-caron vs s', '>');
        Observer.Expect('s-caron vs t', '<');
        Observer.Expect('a-macron vs a', '>');
        Observer.Expect('a-macron vs a-acute', '>');
        Observer.Expect('alpha vs z', '>');
        Observer.Expect('cyrillic ya vs z', '>');
        Observer.Expect('euro vs 9', '<');
        Observer.Expect('euro vs a', '<');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryDateTimePlus(Stamp: DateTime; Amount: Decimal; var Result: DateTime)
    begin
        Result := Stamp + Amount;
    end;

    [TryFunction]
    local procedure TryDateTimeMinus(Stamp: DateTime; Amount: Decimal; var Result: DateTime)
    begin
        Result := Stamp - Amount;
    end;

    [Test]
    procedure DateTimePlusDecimal_ErrorCodeAndWholeDecimal()
    var
        Observer: Codeunit "Probe Observer";
        Stamp: DateTime;
        Result: DateTime;
        Whole: Decimal;
        Fraction: Decimal;
        Big: Decimal;
    begin
        Stamp := CreateDateTime(DMY2Date(5, 3, 2024), 120000T);
        Whole := 1000.0;
        Fraction := 1000.5;
        Big := 99999999999999999.0;
        Observer.Observe('plus whole decimal variable', Format(Stamp + Whole, 0, 9));
        Observer.Observe('plus decimal literal 1000.0', Format(Stamp + 1000.0, 0, 9));
        Observer.Observe('minus whole decimal variable', Format(Stamp - Whole, 0, 9));
        Observer.Observe('plus negative whole', Format(Stamp + (-Whole), 0, 9));
        Observer.Observe('plus whole decimal from division', Format(Stamp + (2000 / 2), 0, 9));
        Observer.Observe('try fraction', Format(TryDateTimePlus(Stamp, Fraction, Result)));
        Observer.ObserveError('plus fraction');
        Observer.Observe('try minus fraction', Format(TryDateTimeMinus(Stamp, Fraction, Result)));
        Observer.ObserveError('minus fraction');
        Observer.Observe('try fraction 0.4', Format(TryDateTimePlus(Stamp, 0.4, Result)));
        Observer.ObserveError('plus 0.4');
        Observer.Observe('try big', Format(TryDateTimePlus(Stamp, Big, Result)));
        Observer.ObserveError('plus big');
        Observer.Observe('try undefined plus whole', Format(TryDateTimePlus(0DT, Whole, Result)));
        Observer.Observe('result of undefined plus whole', Format(Result, 0, 9));
        Observer.Expect('plus whole decimal variable', '2024-03-05T12:00:01Z');
        Observer.Expect('plus decimal literal 1000.0', '2024-03-05T12:00:01Z');
        Observer.Expect('minus whole decimal variable', '2024-03-05T11:59:59Z');
        Observer.Expect('plus negative whole', '2024-03-05T11:59:59Z');
        Observer.Expect('plus whole decimal from division', '2024-03-05T12:00:01Z');
        Observer.Expect('try fraction', 'No');
        Observer.Expect('plus fraction|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1000.5 to System.Int64.');
        Observer.Expect('plus fraction|code', 'ConversionCast');
        Observer.Expect('try minus fraction', 'No');
        Observer.Expect('minus fraction|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -1000.5 to System.Int64.');
        Observer.Expect('minus fraction|code', 'ConversionCast');
        Observer.Expect('try fraction 0.4', 'No');
        Observer.Expect('plus 0.4|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.4 to System.Int64.');
        Observer.Expect('plus 0.4|code', 'ConversionCast');
        Observer.Expect('try big', 'No');
        Observer.Expect('plus big|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('plus big|code', 'AL:Overflow');
        Observer.Expect('try undefined plus whole', 'No');
        Observer.Expect('result of undefined plus whole', '');
        Observer.Verify();
    end;

    local procedure DayStamp(Offset: Integer; Time: Time): DateTime
    begin
        exit(CreateDateTime(DMY2Date(4, 3, 2024) + Offset, Time));
    end;

    local procedure RoundedDown(Stamp: DateTime; Precision: BigInteger): Text
    begin
        exit(Format(RoundDateTime(Stamp, Precision, '<'), 0, 9));
    end;

    local procedure RoundedSeries(Precision: BigInteger; Days: Integer): Text
    var
        Offset: Integer;
        Result: Text;
    begin
        for Offset := 0 to Days - 1 do
            Result += CopyStr(Format(RoundDateTime(DayStamp(Offset, 100000T), Precision, '<'), 0, 9), 1, 16) + ' ';
        exit(Result);
    end;

    [Test]
    procedure RoundDateTime_OriginOfTheCount_ForPrecisionsThatDoNotDivideADay()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // 700000 ms (11 min 40 s) divides no day: the count starts at an origin that these results reveal
        Observer.Observe('700000 2024-03-04 12:00:31', RoundedDown(DayStamp(0, 120031T), 700000));
        Observer.Observe('700000 2024-03-05 12:00:31', RoundedDown(DayStamp(1, 120031T), 700000));
        Observer.Observe('700000 2024-03-06 12:00:31', RoundedDown(DayStamp(2, 120031T), 700000));
        Observer.Observe('700000 2024-03-11 12:00:31', RoundedDown(DayStamp(7, 120031T), 700000));
        Observer.Observe('700000 2024-03-12 12:00:31', RoundedDown(DayStamp(8, 120031T), 700000));
        Observer.Observe('700000 2024-03-05 00:00:00', RoundedDown(DayStamp(1, 000000T), 700000));
        Observer.Observe('700000 2000-01-01 12:00:31', RoundedDown(CreateDateTime(DMY2Date(1, 1, 2000), 120031T), 700000));
        Observer.Observe('700000 1900-01-01 12:00:31', RoundedDown(CreateDateTime(DMY2Date(1, 1, 1900), 120031T), 700000));
        Observer.Observe('700000 1753-01-01 12:00:31', RoundedDown(CreateDateTime(DMY2Date(1, 1, 1753), 120031T), 700000));
        Observer.Observe('700000 2024-03-05 12:00:31 up', Format(RoundDateTime(DayStamp(1, 120031T), 700000, '>'), 0, 9));
        Observer.Expect('700000 2024-03-04 12:00:31', '2024-03-04T11:53:20Z');
        Observer.Expect('700000 2024-03-05 12:00:31', '2024-03-05T12:00:00Z');
        Observer.Expect('700000 2024-03-06 12:00:31', '2024-03-06T11:55:00Z');
        Observer.Expect('700000 2024-03-11 12:00:31', '2024-03-11T11:53:20Z');
        Observer.Expect('700000 2024-03-12 12:00:31', '2024-03-12T12:00:00Z');
        Observer.Expect('700000 2024-03-05 00:00:00', '2024-03-04T23:56:40Z');
        Observer.Expect('700000 2000-01-01 12:00:31', '2000-01-01T11:51:40Z');
        Observer.Expect('700000 1900-01-01 12:00:31', '1900-01-01T11:53:20Z');
        Observer.Expect('700000 1753-01-01 12:00:31', '1753-01-01T11:53:20Z');
        Observer.Expect('700000 2024-03-05 12:00:31 up', '2024-03-05T12:11:40Z');
        Observer.Verify();
    end;

    [Test]
    procedure RoundDateTime_OriginOfTheCount_1100000()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1100000 2024-03-04 12:00:31', RoundedDown(DayStamp(0, 120031T), 1100000));
        Observer.Observe('1100000 2024-03-05 12:00:31', RoundedDown(DayStamp(1, 120031T), 1100000));
        Observer.Observe('1100000 2024-03-06 12:00:31', RoundedDown(DayStamp(2, 120031T), 1100000));
        Observer.Observe('1100000 2024-03-11 12:00:31', RoundedDown(DayStamp(7, 120031T), 1100000));
        Observer.Observe('1100000 2024-03-12 12:00:31', RoundedDown(DayStamp(8, 120031T), 1100000));
        Observer.Observe('1100000 2024-03-05 00:00:00', RoundedDown(DayStamp(1, 000000T), 1100000));
        Observer.Observe('1100000 2000-01-01 12:00:31', RoundedDown(CreateDateTime(DMY2Date(1, 1, 2000), 120031T), 1100000));
        Observer.Observe('1100000 1900-01-01 12:00:31', RoundedDown(CreateDateTime(DMY2Date(1, 1, 1900), 120031T), 1100000));
        Observer.Observe('1100000 up 2024-03-05 12:00:31', Format(RoundDateTime(DayStamp(1, 120031T), 1100000, '>'), 0, 9));
        Observer.Observe('1100000 nearest 2024-03-05 12:00:31', Format(RoundDateTime(DayStamp(1, 120031T), 1100000, '='), 0, 9));
        Observer.Expect('1100000 2024-03-04 12:00:31', '2024-03-04T11:51:40Z');
        Observer.Expect('1100000 2024-03-05 12:00:31', '2024-03-05T12:00:00Z');
        Observer.Expect('1100000 2024-03-06 12:00:31', '2024-03-06T11:50:00Z');
        Observer.Expect('1100000 2024-03-11 12:00:31', '2024-03-11T11:55:00Z');
        Observer.Expect('1100000 2024-03-12 12:00:31', '2024-03-12T11:45:00Z');
        Observer.Expect('1100000 2024-03-05 00:00:00', '2024-03-04T23:46:40Z');
        Observer.Expect('1100000 2000-01-01 12:00:31', '2000-01-01T11:48:20Z');
        Observer.Expect('1100000 1900-01-01 12:00:31', '1900-01-01T11:51:40Z');
        Observer.Expect('1100000 up 2024-03-05 12:00:31', '2024-03-05T12:18:20Z');
        Observer.Expect('1100000 nearest 2024-03-05 12:00:31', '2024-03-05T12:00:00Z');
        Observer.Verify();
    end;

    [Test]
    procedure RoundDateTime_OriginOfTheCount_MultiDayPrecisions()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // 2, 3, 7 and 14 days in milliseconds; eight consecutive days from 2024-03-04 (a Monday) at 10:00
        Observer.Observe('2 days', RoundedSeries(172800000, 8));
        Observer.Observe('3 days', RoundedSeries(259200000, 8));
        Observer.Observe('7 days', RoundedSeries(604800000, 8));
        Observer.Observe('14 days', RoundedSeries(1209600000, 8));
        Observer.Observe('1 day', RoundedSeries(86400000, 3));
        Observer.Observe('5 days', RoundedSeries(432000000, 8));
        Observer.Observe('36 hours', RoundedSeries(129600000, 8));
        Observer.Expect('2 days', '2024-03-04T00:00 2024-03-04T00:00 2024-03-06T00:00 2024-03-06T00:00 2024-03-08T00:00 2024-03-08T00:00 2024-03-10T00:00 2024-03-10T00:00 ');
        Observer.Expect('3 days', '2024-03-04T00:00 2024-03-04T00:00 2024-03-04T00:00 2024-03-07T00:00 2024-03-07T00:00 2024-03-07T00:00 2024-03-10T00:00 2024-03-10T00:00 ');
        Observer.Expect('7 days', '2024-03-02T00:00 2024-03-02T00:00 2024-03-02T00:00 2024-03-02T00:00 2024-03-02T00:00 2024-03-09T00:00 2024-03-09T00:00 2024-03-09T00:00 ');
        Observer.Expect('14 days', '2024-03-02T00:00 2024-03-02T00:00 2024-03-02T00:00 2024-03-02T00:00 2024-03-02T00:00 2024-03-02T00:00 2024-03-02T00:00 2024-03-02T00:00 ');
        Observer.Expect('1 day', '2024-03-04T00:00 2024-03-05T00:00 2024-03-06T00:00 ');
        Observer.Expect('5 days', '2024-02-29T00:00 2024-03-05T00:00 2024-03-05T00:00 2024-03-05T00:00 2024-03-05T00:00 2024-03-05T00:00 2024-03-10T00:00 2024-03-10T00:00 ');
        Observer.Expect('36 hours', '2024-03-04T00:00 2024-03-04T00:00 2024-03-05T12:00 2024-03-07T00:00 2024-03-07T00:00 2024-03-08T12:00 2024-03-10T00:00 2024-03-10T00:00 ');
        Observer.Verify();
    end;

    [Test]
    procedure Encryption_NoKeyCreatedByTheTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('enabled', Format(EncryptionEnabled()));
        Observer.Observe('key exists', Format(EncryptionKeyExists()));
        Observer.Expect('enabled', 'Yes');
        Observer.Expect('key exists', 'Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryEncrypt(Value: Text; var Result: Text)
    begin
        Result := Encrypt(Value);
    end;

    [TryFunction]
    local procedure TryDecrypt(Value: Text; var Result: Text)
    begin
        Result := Decrypt(Value);
    end;

    [Test]
    procedure Encryption_EncryptAndDecryptForms()
    var
        Observer: Codeunit "Probe Observer";
        Encrypted: Text;
        Plain: Text;
    begin
        Observer.Observe('encrypt x ok', Format(TryEncrypt('x', Encrypted)));
        Observer.ObserveError('encrypt x');
        Observer.Observe('encrypted length', Format(StrLen(Encrypted)));
        Observer.Observe('decrypt it', Format(TryDecrypt(Encrypted, Plain)));
        Observer.Observe('decrypted', Plain);
        Observer.Observe('decrypt empty ok', Format(TryDecrypt('', Plain)));
        Observer.Observe('decrypt empty result', Plain);
        Observer.ObserveError('decrypt empty');
        Observer.Observe('encrypt empty ok', Format(TryEncrypt('', Encrypted)));
        Observer.Observe('encrypt empty result', Encrypted);
        Observer.Observe('decrypt garbage ok', Format(TryDecrypt('garbage', Plain)));
        Observer.ObserveError('decrypt garbage');
        Observer.Observe('decrypt short base64 ok', Format(TryDecrypt('AAAA', Plain)));
        Observer.ObserveError('decrypt short base64');
        Observer.Observe('decrypt 344 chars not encrypted ok', Format(TryDecrypt(PadStr('', 344, 'A'), Plain)));
        Observer.ObserveError('decrypt 344 chars');
        Observer.Observe('encrypt 1000 chars ok', Format(TryEncrypt(PadStr('', 1000, 'y'), Encrypted)));
        Observer.Observe('encrypted 1000 length', Format(StrLen(Encrypted)));
        Observer.Observe('encrypt unicode ok', Format(TryEncrypt(Ch(233) + Ch(8364), Encrypted)));
        Observer.Observe('decrypt unicode', Format(TryDecrypt(Encrypted, Plain)));
        Observer.Observe('decrypted length', Format(StrLen(Plain)));
        Observer.Expect('encrypt x ok', 'Yes');
        Observer.Expect('encrypt x|text', '');
        Observer.Expect('encrypt x|code', '');
        Observer.Expect('encrypted length', '344');
        Observer.Expect('decrypt it', 'Yes');
        Observer.Expect('decrypted', 'x');
        Observer.Expect('decrypt empty ok', 'Yes');
        Observer.Expect('decrypt empty result', '');
        Observer.Expect('decrypt empty|text', '');
        Observer.Expect('decrypt empty|code', '');
        Observer.Expect('encrypt empty ok', 'Yes');
        Observer.Expect('encrypt empty result', '');
        Observer.Expect('decrypt garbage ok', 'No');
        Observer.Expect('decrypt garbage|text', 'Unable to decrypt data. The data was encrypted using a different key.');
        Observer.Expect('decrypt garbage|code', 'Encryption:Format');
        Observer.Expect('decrypt short base64 ok', 'No');
        Observer.Expect('decrypt short base64|text', 'Unable to decrypt data. The data was encrypted using a different key.');
        Observer.Expect('decrypt short base64|code', 'Encryption:Cryptographic');
        Observer.Expect('decrypt 344 chars not encrypted ok', 'No');
        Observer.Expect('decrypt 344 chars|text', 'Unable to decrypt data. The data was encrypted using a different key.');
        Observer.Expect('decrypt 344 chars|code', 'Encryption:Cryptographic');
        Observer.Expect('encrypt 1000 chars ok', 'No');
        Observer.Expect('encrypted 1000 length', '0');
        Observer.Expect('encrypt unicode ok', 'Yes');
        Observer.Expect('decrypt unicode', 'Yes');
        Observer.Expect('decrypted length', '2');
        Observer.Verify();
    end;
}
