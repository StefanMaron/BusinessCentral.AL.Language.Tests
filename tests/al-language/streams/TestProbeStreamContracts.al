// Observe-only probes (writer A). Rows: Streams Write(Date)/Write(Decimal), Read types, Blob.Length stored size,
// Blob record copy and temp rename, MSDos/Windows text, ReadText lengths.
table 69801 "PA Blob Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
        field(3; Txt; Text[30]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 69803 "PA Stream Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Hex(var Blob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        B: Byte;
        R: Text;
        HexDigits: Text;
    begin
        HexDigits := '0123456789ABCDEF';
        Blob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.Read(B);
            R += CopyStr(HexDigits, (B div 16) + 1, 1) + CopyStr(HexDigits, (B mod 16) + 1, 1) + ' ';
        end;
        exit(R.TrimEnd());
    end;

    local procedure HexOfRecBlob(var Rec: Record "PA Blob Row"): Text
    var
        InS: InStream;
        B: Byte;
        R: Text;
        HexDigits: Text;
    begin
        HexDigits := '0123456789ABCDEF';
        Rec.Data.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.Read(B);
            R += CopyStr(HexDigits, (B div 16) + 1, 1) + CopyStr(HexDigits, (B mod 16) + 1, 1) + ' ';
        end;
        exit(R.TrimEnd());
    end;

    local procedure DateHex(D: Date): Text
    var
        Blob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Blob.CreateOutStream(OutS);
        OutS.Write(D);
        exit(Hex(Blob));
    end;

    local procedure DecHex(D: Decimal): Text
    var
        Blob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Blob.CreateOutStream(OutS);
        OutS.Write(D);
        exit(Hex(Blob));
    end;

    [Test]
    procedure WriteDate_ByteForms()
    var
        O: Codeunit "Probe Observer";
    begin
        O.Observe('0D', DateHex(0D));
        O.Observe('1753-01-01', DateHex(DMY2Date(1, 1, 1753)));
        O.Observe('1900-01-01', DateHex(DMY2Date(1, 1, 1900)));
        O.Observe('2000-01-01', DateHex(DMY2Date(1, 1, 2000)));
        O.Observe('2024-01-01', DateHex(DMY2Date(1, 1, 2024)));
        O.Observe('2024-01-02', DateHex(DMY2Date(2, 1, 2024)));
        O.Observe('2024-12-30', DateHex(DMY2Date(30, 12, 2024)));
        O.Observe('2024-12-31', DateHex(DMY2Date(31, 12, 2024)));
        O.Observe('2025-06-15', DateHex(DMY2Date(15, 6, 2025)));
        O.Observe('9999-12-31', DateHex(DMY2Date(31, 12, 9999)));
        O.Expect('0D', '00 00 00 00');
        O.Expect('1753-01-01', '1F 8A 13 00');
        O.Expect('1900-01-01', '93 2D 15 00');
        O.Expect('2000-01-01', 'EB 4A 16 00');
        O.Expect('2024-01-01', '67 8F 16 00');
        O.Expect('2024-01-02', '69 8F 16 00');
        O.Expect('2024-12-30', '3F 92 16 00');
        O.Expect('2024-12-31', '41 92 16 00');
        O.Expect('2025-06-15', '8D 93 16 00');
        O.Expect('9999-12-31', '91 76 6F 00');
        O.Verify();
    end;

    [Test]
    procedure WriteDate_ClosingDates()
    var
        O: Codeunit "Probe Observer";
    begin
        O.Observe('closing_2024-12-31', DateHex(ClosingDate(DMY2Date(31, 12, 2024))));
        O.Observe('closing_2024-12-30', DateHex(ClosingDate(DMY2Date(30, 12, 2024))));
        O.Observe('closing_2023-12-31', DateHex(ClosingDate(DMY2Date(31, 12, 2023))));
        O.Observe('closing_2025-01-01', DateHex(ClosingDate(DMY2Date(1, 1, 2025))));
        O.Observe('closing_1900-01-01', DateHex(ClosingDate(DMY2Date(1, 1, 1900))));
        O.Observe('closing_2000-02-29', DateHex(ClosingDate(DMY2Date(29, 2, 2000))));
        asserterror O.Observe('closing_0D', DateHexSafe(ClosingDate(0D)));
        O.ObserveError('closing_0D');
        O.Expect('closing_2024-12-31', '42 92 16 00');
        O.Expect('closing_2024-12-30', '40 92 16 00');
        O.Expect('closing_2023-12-31', '66 8F 16 00');
        O.Expect('closing_2025-01-01', '44 92 16 00');
        O.Expect('closing_1900-01-01', '94 2D 15 00');
        O.Expect('closing_2000-02-29', '62 4B 16 00');
        O.Expect('closing_0D|text', 'The date is not valid.');
        O.Expect('closing_0D|code', 'DateInvalid');
        O.Verify();
    end;

    local procedure DateHexSafe(D: Date): Text
    begin
        exit(DateHex(D));
    end;

    [Test]
    procedure WriteDecimal_ByteForms()
    var
        O: Codeunit "Probe Observer";
    begin
        O.Observe('0', DecHex(0));
        O.Observe('1', DecHex(1));
        O.Observe('minus1', DecHex(-1));
        O.Observe('0_5', DecHex(0.5));
        O.Observe('10', DecHex(10));
        O.Observe('100', DecHex(100));
        O.Observe('123_45', DecHex(123.45));
        O.Observe('minus123_45', DecHex(-123.45));
        O.Observe('1000000', DecHex(1000000));
        O.Observe('0_00001', DecHex(0.00001));
        O.Observe('0_000000000000000001', DecHex(0.000000000000000001));
        O.Observe('123456789012345678', DecHexText('123456789012345678'));
        O.Observe('1234567890123456789', DecHexText('1234567890123456789'));
        O.Observe('big_28_digits_decimal', DecHexText('1234567890123456789012345678'));
        O.Expect('0', '00 00 00 00 00 00 00 00 00 00 00 00');
        O.Expect('1', '40 00 00 00 00 00 00 00 00 10 00 00');
        O.Expect('minus1', 'C0 00 00 00 00 00 00 00 00 10 00 00');
        O.Expect('0_5', '3F 00 00 00 00 00 00 00 00 50 00 00');
        O.Expect('10', '41 00 00 00 00 00 00 00 00 10 00 00');
        O.Expect('100', '42 00 00 00 00 00 00 00 00 10 00 00');
        O.Expect('123_45', '42 00 00 00 00 00 00 50 34 12 00 00');
        O.Expect('minus123_45', 'C2 00 00 00 00 00 00 50 34 12 00 00');
        O.Expect('1000000', '46 00 00 00 00 00 00 00 00 10 00 00');
        O.Expect('0_00001', '3B 00 00 00 00 00 00 00 00 10 00 00');
        O.Expect('0_000000000000000001', '2E 00 00 00 00 00 00 00 00 10 00 00');
        O.Expect('123456789012345678', 'evaluate failed');
        O.Expect('1234567890123456789', 'evaluate failed');
        O.Expect('big_28_digits_decimal', 'evaluate failed');
        O.Verify();
    end;

    local procedure DecHexText(T: Text): Text
    var
        D: Decimal;
    begin
        if not Evaluate(D, T) then
            exit('evaluate failed');
        exit(DecHex(D));
    end;

    [Test]
    procedure WriteDecimal_ManyDigits()
    var
        O: Codeunit "Probe Observer";
    begin
        O.Observe('19_digits_text', DecHexText('1234567890123456789'));
        O.Observe('20_digits_text', DecHexText('12345678901234567890'));
        O.Observe('18_int_plus_fraction', DecHexText('123456789012.345678'));
        O.Observe('29_digits_text', DecHexText('12345678901234567890123456789'));
        O.Observe('1e_minus_18', DecHexText('0.000000000000000001'));
        O.Observe('1e_minus_19', DecHexText('0.0000000000000000001'));
        O.Observe('1e_minus_28', DecHexText('0.0000000000000000000000000001'));
        O.Observe('1e_minus_29', DecHexText('0.00000000000000000000000000001'));
        O.Observe('decimal_max', DecHexText('79228162514264337593543950335'));
        O.Expect('19_digits_text', 'evaluate failed');
        O.Expect('20_digits_text', 'evaluate failed');
        O.Expect('18_int_plus_fraction', '4B 78 56 34 12 90 78 56 34 12 00 00');
        O.Expect('29_digits_text', 'evaluate failed');
        O.Expect('1e_minus_18', '2E 00 00 00 00 00 00 00 00 10 00 00');
        O.Expect('1e_minus_19', '2D 00 00 00 00 00 00 00 00 10 00 00');
        O.Expect('1e_minus_28', '24 00 00 00 00 00 00 00 00 10 00 00');
        O.Expect('1e_minus_29', '00 00 00 00 00 00 00 00 00 00 00 00');
        O.Expect('decimal_max', 'evaluate failed');
        O.Verify();
    end;

    [Test]
    procedure WriteText_NonAscii_Char_Byte_Length()
    var
        O: Codeunit "Probe Observer";
        Blob: Codeunit "Temp Blob";
        OutS: OutStream;
        C: Char;
        B: Byte;
        T: Text;
    begin
        T := 'aäö€';
        Blob.CreateOutStream(OutS);
        OutS.Write(T);
        O.Observe('write_text_nonascii', Hex(Blob));
        Clear(Blob);
        Blob.CreateOutStream(OutS);
        T := 'abc';
        OutS.Write(T);
        O.Observe('write_text_ascii', Hex(Blob));
        Clear(Blob);
        Blob.CreateOutStream(OutS);
        C := 65;
        OutS.Write(C);
        O.Observe('write_char_65', Hex(Blob));
        Clear(Blob);
        Blob.CreateOutStream(OutS);
        C := 228;
        OutS.Write(C);
        O.Observe('write_char_228', Hex(Blob));
        Clear(Blob);
        Blob.CreateOutStream(OutS);
        B := 200;
        OutS.Write(B);
        O.Observe('write_byte_200', Hex(Blob));
        Clear(Blob);
        Blob.CreateOutStream(OutS);
        T := 'abcdef';
        OutS.Write(T, 3);
        O.Observe('write_text_len3', Hex(Blob));
        Clear(Blob);
        Blob.CreateOutStream(OutS);
        T := 'ab';
        O.Observe('write_text_len5_over', TryWriteLen(OutS, T, 5));
        O.Observe('write_text_len5_over_bytes', Hex(Blob));
        O.Expect('write_text_nonascii', '61 E4 F6 80 00');
        O.Expect('write_text_ascii', '61 62 63 00');
        O.Expect('write_char_65', '41');
        O.Expect('write_char_228', 'E4');
        O.Expect('write_byte_200', 'C8');
        O.Expect('write_text_len3', '61 62 63 00');
        O.Expect('write_text_len5_over', 'ok');
        O.Expect('write_text_len5_over_bytes', '61 62 00');
        O.Verify();
    end;

    local procedure TryWriteLen(var OutS: OutStream; T: Text; L: Integer): Text
    begin
        if TryWriteLenF(OutS, T, L) then
            exit('ok');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryWriteLenF(var OutS: OutStream; T: Text; L: Integer)
    begin
        OutS.Write(T, L);
    end;

    [Test]
    procedure WriteBooleanGuidBigIntegerOthers()
    var
        O: Codeunit "Probe Observer";
        Blob: Codeunit "Temp Blob";
        OutS: OutStream;
        G: Guid;
        Bo: Boolean;
        Bi: BigInteger;
        I: Integer;
        Ti: Time;
    begin
        Evaluate(G, '{01234567-89AB-CDEF-0123-456789ABCDEF}');
        Blob.CreateOutStream(OutS);
        OutS.Write(G);
        O.Observe('guid', Hex(Blob));
        Clear(Blob);
        Blob.CreateOutStream(OutS);
        Bo := true;
        OutS.Write(Bo);
        O.Observe('boolean_true', Hex(Blob));
        Clear(Blob);
        Blob.CreateOutStream(OutS);
        Evaluate(Bi, '4294967297');
        OutS.Write(Bi);
        O.Observe('biginteger_2pow32_plus_1', Hex(Blob));
        Clear(Blob);
        Blob.CreateOutStream(OutS);
        I := 258;
        OutS.Write(I);
        O.Observe('integer_258', Hex(Blob));
        Clear(Blob);
        Blob.CreateOutStream(OutS);
        Ti := 123456T;
        OutS.Write(Ti);
        O.Observe('time_123456', Hex(Blob));
        O.Expect('guid', '67 45 23 01 AB 89 EF CD 01 23 45 67 89 AB CD EF');
        O.Expect('boolean_true', '01 00 00 00');
        O.Expect('biginteger_2pow32_plus_1', '01 00 00 00 01 00 00 00');
        O.Expect('integer_258', '02 01 00 00');
        O.Expect('time_123456', '81 29 B3 02');
        O.Verify();
    end;

    [Test]
    procedure Read_IntoTypes()
    var
        O: Codeunit "Probe Observer";
    begin
        O.Observe('integer_into_integer', ReadBack(1, 1));
        O.Observe('integer_into_byte', ReadBack(1, 2));
        O.Observe('integer_into_biginteger', ReadBack(1, 3));
        O.Observe('integer_into_text', ReadBack(1, 4));
        O.Observe('integer_into_boolean', ReadBack(1, 5));
        O.Observe('integer_into_char', ReadBack(1, 6));
        O.Observe('integer_into_decimal', ReadBack(1, 7));
        O.Observe('integer_into_date', ReadBack(1, 8));
        O.Observe('date_into_date', ReadBack(2, 8));
        O.Observe('date_into_integer', ReadBack(2, 1));
        O.Observe('decimal_into_decimal', ReadBack(3, 7));
        O.Observe('guid_into_guid', ReadBack(4, 9));
        O.Observe('boolean_into_boolean', ReadBack(5, 5));
        O.Observe('biginteger_into_biginteger', ReadBack(6, 3));
        O.Expect('integer_into_integer', '65794 eos=Yes');
        O.Expect('integer_into_byte', '\u0002 eos=No');
        O.Expect('integer_into_biginteger', 'ERR:Invalid data encountered in stream, unable to read text./InvalidStreamData');
        O.Expect('integer_into_text', '\u0002\u0001\u0001 eos=Yes');
        O.Expect('integer_into_boolean', 'Yes eos=Yes');
        O.Expect('integer_into_char', '\u0002 eos=No');
        O.Expect('integer_into_decimal', 'ERR:Invalid data encountered in stream, unable to read text./InvalidStreamData');
        O.Expect('integer_into_date', '0090-01-24 eos=Yes');
        O.Expect('date_into_date', '2025-06-15 eos=Yes');
        O.Expect('date_into_integer', '1479565 eos=Yes');
        O.Expect('decimal_into_decimal', '12.5 eos=Yes');
        O.Expect('guid_into_guid', '{01234567-89AB-CDEF-0123-456789ABCDEF} eos=Yes');
        O.Expect('boolean_into_boolean', 'Yes eos=Yes');
        O.Expect('biginteger_into_biginteger', '4294967297 eos=Yes');
        O.Verify();
    end;

    local procedure ReadBack(WriteKind: Integer; ReadKind: Integer): Text
    var
        Blob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        I: Integer;
        By: Byte;
        Bi: BigInteger;
        T: Text;
        Bo: Boolean;
        C: Char;
        D: Decimal;
        Da: Date;
        G: Guid;
        Res: Text;
    begin
        Blob.CreateOutStream(OutS);
        case WriteKind of
            1:
                OutS.Write(65536 + 258);
            2:
                OutS.Write(DMY2Date(15, 6, 2025));
            3:
                OutS.Write(12.5);
            4:
                begin
                    Evaluate(G, '{01234567-89AB-CDEF-0123-456789ABCDEF}');
                    OutS.Write(G);
                end;
            5:
                OutS.Write(true);
            6:
                begin
                    Evaluate(Bi, '4294967297');
                    OutS.Write(Bi);
                end;
        end;
        Blob.CreateInStream(InS);
        if not TryReadKind(InS, ReadKind, Res) then
            exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
        exit(Res + ' eos=' + Format(InS.EOS()));
    end;

    [TryFunction]
    local procedure TryReadKind(var InS: InStream; ReadKind: Integer; var Res: Text)
    var
        I: Integer;
        By: Byte;
        Bi: BigInteger;
        T: Text;
        Bo: Boolean;
        C: Char;
        D: Decimal;
        Da: Date;
        G: Guid;
    begin
        case ReadKind of
            1:
                begin
                    InS.Read(I);
                    Res := Format(I);
                end;
            2:
                begin
                    InS.Read(By);
                    Res := Format(By);
                end;
            3:
                begin
                    InS.Read(Bi);
                    Res := Format(Bi);
                end;
            4:
                begin
                    InS.Read(T);
                    Res := Format(T);
                end;
            5:
                begin
                    InS.Read(Bo);
                    Res := Format(Bo);
                end;
            6:
                begin
                    InS.Read(C);
                    Res := Format(C);
                end;
            7:
                begin
                    InS.Read(D);
                    Res := Format(D);
                end;
            8:
                begin
                    InS.Read(Da);
                    Res := Format(Da, 0, 9);
                end;
            9:
                begin
                    InS.Read(G);
                    Res := Format(G);
                end;
        end;
    end;

    [Test]
    procedure ReadText_LengthPositionAndTerminators()
    var
        O: Codeunit "Probe Observer";
        Blob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        T: Text;
        Lf: Text;
        N: Integer;
    begin
        Lf[1] := 10;
        Blob.CreateOutStream(OutS);
        OutS.WriteText('abcdef' + Lf + 'gh');
        Blob.CreateInStream(InS);
        N := InS.ReadText(T, 3);
        O.Observe('readtext_len3', Format(N) + ':' + T + ' pos=' + Format(InS.Position()));
        N := InS.ReadText(T, 100);
        O.Observe('readtext_len100_stops_at_lf', Format(N) + ':' + T + ' pos=' + Format(InS.Position()));
        N := InS.ReadText(T);
        O.Observe('readtext_rest', Format(N) + ':' + T + ' eos=' + Format(InS.EOS()) + ' pos=' + Format(InS.Position()));
        Blob.CreateInStream(InS);
        InS.Position := 3;
        N := InS.ReadText(T, 2);
        O.Observe('position_set_3_read2', Format(N) + ':' + T);
        O.Observe('position_after', Format(InS.Position()));
        O.Observe('position_set_beyond', TrySetPos(InS, 1000));
        O.Observe('position_set_zero', TrySetPos(InS, 0));
        O.Expect('readtext_len3', '3:abc pos=4');
        O.Expect('readtext_len100_stops_at_lf', '3:def pos=8');
        O.Expect('readtext_rest', '2:gh eos=Yes pos=10');
        O.Expect('position_set_3_read2', '2:cd');
        O.Expect('position_after', '5');
        O.Expect('position_set_beyond', 'ERR:The value of Position parameter 1 is outside of the permitted range. The current value is: 1,000. The permitted range is: from 1 to 9./OutsidePermittedRange');
        O.Expect('position_set_zero', 'ERR:The value of Position parameter 1 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 9./OutsidePermittedRange');
        O.Verify();
    end;

    local procedure TrySetPos(var InS: InStream; P: Integer): Text
    begin
        if TrySetPosF(InS, P) then
            exit('ok pos=' + Format(InS.Position()));
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TrySetPosF(var InS: InStream; P: Integer)
    begin
        InS.Position := P;
    end;

    [Test]
    procedure ReadText_Utf16Terminator()
    var
        O: Codeunit "Probe Observer";
        Blob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        T: Text;
        Lf: Text;
        Cr: Text;
        N: Integer;
    begin
        Lf[1] := 10;
        Cr[1] := 13;
        Blob.CreateOutStream(OutS, TextEncoding::UTF16);
        OutS.WriteText('ab' + Lf + 'cd' + Cr + Lf + 'ef' + Cr + 'gh');
        O.Observe('bytes', Hex(Blob));
        Blob.CreateInStream(InS, TextEncoding::UTF16);
        N := InS.ReadText(T);
        O.Observe('line1', Format(N) + ':[' + T + ']');
        N := InS.ReadText(T);
        O.Observe('line2', Format(N) + ':[' + T + ']');
        N := InS.ReadText(T);
        O.Observe('line3', Format(N) + ':[' + T + ']');
        N := InS.ReadText(T);
        O.Observe('line4', Format(N) + ':[' + T + ']');
        O.Expect('bytes', '61 00 62 00 0A 00 63 00 64 00 0D 00 0A 00 65 00 66 00 0D 00 67 00 68 00');
        O.Expect('line1', '4:[ab]');
        O.Expect('line2', '4:[cd]');
        O.Expect('line3', '8:[efgh]');
        O.Expect('line4', '0:[]');
        O.Verify();
    end;

    [Test]
    procedure TextEncodings_BytesOfUmlaut()
    var
        O: Codeunit "Probe Observer";
        Blob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Blob.CreateOutStream(OutS, TextEncoding::MSDos);
        OutS.WriteText('aä€');
        O.Observe('msdos', Hex(Blob));
        Clear(Blob);
        Blob.CreateOutStream(OutS, TextEncoding::Windows);
        OutS.WriteText('aä€');
        O.Observe('windows', Hex(Blob));
        Clear(Blob);
        Blob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('aä€');
        O.Observe('utf8', Hex(Blob));
        Clear(Blob);
        Blob.CreateOutStream(OutS, TextEncoding::UTF16);
        OutS.WriteText('aä€');
        O.Observe('utf16', Hex(Blob));
        Clear(Blob);
        Blob.CreateOutStream(OutS, TextEncoding::MSDos);
        OutS.Write('aä');
        O.Observe('msdos_write_text', Hex(Blob));
        O.Expect('msdos', '61 E4 80');
        O.Expect('windows', '61 E4 80');
        O.Expect('utf8', '61 C3 A4 E2 82 AC');
        O.Expect('utf16', '61 00 E4 00 AC 20');
        O.Expect('msdos_write_text', '61 E4 00');
        O.Verify();
    end;

    [Test]
    procedure TextEncodings_MsDosRoundTrip()
    var
        O: Codeunit "Probe Observer";
        Blob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        T: Text;
    begin
        Blob.CreateOutStream(OutS, TextEncoding::MSDos);
        OutS.WriteText('aäö');
        Blob.CreateInStream(InS, TextEncoding::MSDos);
        InS.ReadText(T);
        O.Observe('msdos_msdos', T);
        Blob.CreateInStream(InS, TextEncoding::Windows);
        InS.ReadText(T);
        O.Observe('msdos_written_windows_read', T);
        O.Expect('msdos_msdos', 'aäö');
        O.Expect('msdos_written_windows_read', 'aäö');
        O.Verify();
    end;

    [Test]
    procedure BlobLength_StoredSizes()
    var
        O: Codeunit "Probe Observer";
        Sizes: List of [Integer];
        Sz: Integer;
    begin
        Sizes.Add(0);
        Sizes.Add(1);
        Sizes.Add(5);
        Sizes.Add(100);
        Sizes.Add(10000);
        Sizes.Add(100000);
        foreach Sz in Sizes do
            O.Observe('size_' + Format(Sz), BlobSize(Sz));
        O.Expect('size_0', 'before_insert_len=0 hasvalue=No after_insert_len=0 fresh_get_len=0 hasvalue=No after_calcfields_len=0');
        O.Expect('size_1', 'before_insert_len=1 hasvalue=Yes after_insert_len=1 fresh_get_len=7 hasvalue=Yes after_calcfields_len=1');
        O.Expect('size_5', 'before_insert_len=5 hasvalue=Yes after_insert_len=5 fresh_get_len=9 hasvalue=Yes after_calcfields_len=5');
        O.Expect('size_100', 'before_insert_len=100 hasvalue=Yes after_insert_len=100 fresh_get_len=10 hasvalue=Yes after_calcfields_len=100');
        O.Expect('size_10000', 'before_insert_len=10000 hasvalue=Yes after_insert_len=10000 fresh_get_len=31 hasvalue=Yes after_calcfields_len=10000');
        O.Expect('size_100000', 'before_insert_len=100000 hasvalue=Yes after_insert_len=100000 fresh_get_len=118 hasvalue=Yes after_calcfields_len=100000');
        O.Verify();
    end;

    local procedure BlobSize(Sz: Integer): Text
    var
        Rec: Record "PA Blob Row";
        Rec2: Record "PA Blob Row";
        OutS: OutStream;
        i: Integer;
        Res: Text;
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.Data.CreateOutStream(OutS);
        for i := 1 to Sz do
            OutS.WriteText('x');
        Res := 'before_insert_len=' + Format(Rec.Data.Length()) + ' hasvalue=' + Format(Rec.Data.HasValue());
        Rec.Insert();
        Res += ' after_insert_len=' + Format(Rec.Data.Length());
        Rec2.Get(1);
        Res += ' fresh_get_len=' + Format(Rec2.Data.Length()) + ' hasvalue=' + Format(Rec2.Data.HasValue());
        Rec2.CalcFields(Data);
        Res += ' after_calcfields_len=' + Format(Rec2.Data.Length());
        Rec.DeleteAll();
        exit(Res);
    end;

    [Test]
    procedure BlobLength_EmptyUnloaded()
    var
        O: Codeunit "Probe Observer";
        Rec: Record "PA Blob Row";
        Rec2: Record "PA Blob Row";
    begin
        Rec.DeleteAll();
        Rec.Id := 2;
        Rec.Insert();
        Rec2.Get(2);
        O.Observe('empty_unloaded_len', Format(Rec2.Data.Length()));
        O.Observe('empty_unloaded_hasvalue', Format(Rec2.Data.HasValue()));
        Rec2.CalcFields(Data);
        O.Observe('empty_loaded_len', Format(Rec2.Data.Length()));
        Rec.DeleteAll();
        O.Expect('empty_unloaded_len', '0');
        O.Expect('empty_unloaded_hasvalue', 'No');
        O.Expect('empty_loaded_len', '0');
        O.Verify();
    end;

    [Test]
    procedure RecordAssign_CopiesBlobBytes()
    var
        O: Codeunit "Probe Observer";
        R1: Record "PA Blob Row";
        R2: Record "PA Blob Row";
        OutS: OutStream;
        S: Text;
    begin
        R1.Id := 1;
        R1.Data.CreateOutStream(OutS);
        OutS.WriteText('hello');
        R2 := R1;
        O.Observe('copy_hasvalue', Format(R2.Data.HasValue()));
        O.Observe('copy_hex', HexOfRecBlob(R2));
        Clear(OutS);
        R2.Data.CreateOutStream(OutS);
        OutS.WriteText('changed');
        O.Observe('original_after_copy_changed_hex', HexOfRecBlob(R1));
        O.Observe('copy_after_change_hex', HexOfRecBlob(R2));
        O.Observe('format_copy', Format(R2));
        O.Expect('copy_hasvalue', 'Yes');
        O.Expect('copy_hex', '68 65 6C 6C 6F');
        O.Expect('original_after_copy_changed_hex', '68 65 6C 6C 6F');
        O.Expect('copy_after_change_hex', '63 68 61 6E 67 65 64');
        O.Expect('format_copy', '1\t*\t');
        O.Verify();
    end;

    [Test]
    procedure TempRename_UnpersistedBlobWrite()
    var
        O: Codeunit "Probe Observer";
        T: Record "PA Blob Row" temporary;
        OutS: OutStream;
    begin
        T.Id := 1;
        T.Insert();
        T.Data.CreateOutStream(OutS);
        OutS.WriteText('abc');
        T.Rename(2);
        O.Observe('id_after_rename', Format(T.Id));
        O.Observe('blob_after_rename_unpersisted', HexOfRecBlob(T));
        T.Get(2);
        O.Observe('blob_after_get', HexOfRecBlob(T));
        O.Expect('id_after_rename', '2');
        O.Expect('blob_after_rename_unpersisted', '');
        O.Expect('blob_after_get', '');
        O.Verify();
    end;

    [Test]
    procedure TempRename_PersistedBlobWrite()
    var
        O: Codeunit "Probe Observer";
        T: Record "PA Blob Row" temporary;
        OutS: OutStream;
    begin
        T.Id := 1;
        T.Insert();
        T.Data.CreateOutStream(OutS);
        OutS.WriteText('abc');
        T.Modify();
        T.Rename(2);
        O.Observe('id_after_rename', Format(T.Id));
        O.Observe('blob_after_rename_persisted', HexOfRecBlob(T));
        T.Get(2);
        O.Observe('blob_after_get', HexOfRecBlob(T));
        O.Expect('id_after_rename', '2');
        O.Expect('blob_after_rename_persisted', '');
        O.Expect('blob_after_get', '');
        O.Verify();
    end;

    [Test]
    procedure TempRename_BlobInsertedWithValueThenRename()
    var
        O: Codeunit "Probe Observer";
        T: Record "PA Blob Row" temporary;
        OutS: OutStream;
    begin
        T.Id := 1;
        T.Data.CreateOutStream(OutS);
        OutS.WriteText('abc');
        T.Insert();
        T.Rename(2);
        O.Observe('blob_after_insert_with_value_then_rename', HexOfRecBlob(T));
        T.Get(2);
        O.Observe('blob_after_get', HexOfRecBlob(T));
        O.Expect('blob_after_insert_with_value_then_rename', '');
        O.Expect('blob_after_get', '');
        O.Verify();
    end;
}
