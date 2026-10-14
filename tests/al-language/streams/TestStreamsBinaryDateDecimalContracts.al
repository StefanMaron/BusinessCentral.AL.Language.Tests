// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-write-method
// Scope: in-scope
// Fixtures used: shared Assert (60021)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins the 4-byte little endian form of OutStream.Write(Date) (the day number, 0 for 0D) and the
// 12-byte form of OutStream.Write(Decimal): byte 0 holds the sign (0x80) and the decimal exponent
// (0x40 + number of integer digits - 1, so 0.01 is 0x3E and 100 is 0x42); bytes 1 to 9 hold 18 digits as
// packed BCD, most significant digits in byte 9 (the first digit sits in the high nibble of byte 9), so 1 is
// 10 in byte 9; bytes 10 and 11 are zero. Zero is twelve zero bytes. Reading the bytes back with InStream.Read
// gives the same Decimal.
// BC versions: 27.5

codeunit 68321 "Probe Streams Binary"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure HexOf(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InStr: InStream;
        Value: Byte;
        Result: Text;
        Digits: Text;
    begin
        Digits := '0123456789ABCDEF';
        TempBlob.CreateInStream(InStr);
        while not InStr.EOS() do begin
            InStr.Read(Value);
            Result += CopyStr(Digits, (Value div 16) + 1, 1) + CopyStr(Digits, (Value mod 16) + 1, 1);
        end;
        exit(Result);
    end;

    local procedure DateBytes(Value: Date): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        OutStr.Write(Value);
        exit(HexOf(TempBlob));
    end;

    local procedure DecimalBytes(Value: Decimal): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        OutStr.Write(Value);
        exit(HexOf(TempBlob));
    end;

    local procedure DecimalRoundTrip(Value: Decimal): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Result: Decimal;
    begin
        TempBlob.CreateOutStream(OutStr);
        OutStr.Write(Value);
        TempBlob.CreateInStream(InStr);
        InStr.Read(Result);
        exit(Format(Result, 0, 9));
    end;

    [Test]
    procedure Write_Date_IsTheDayNumberAsFourBytes()
    begin
        Assert.AreEqual('00000000', DateBytes(0D), '0D');
        Assert.AreEqual('1F8A1300', DateBytes(DMY2Date(1, 1, 1753)), '1753-01-01 is the first valid date');
        Assert.AreEqual('932D1500', DateBytes(DMY2Date(1, 1, 1900)), '1900-01-01');
        Assert.AreEqual('EB4A1600', DateBytes(DMY2Date(1, 1, 2000)), '2000-01-01');
        Assert.AreEqual('E78F1600', DateBytes(DMY2Date(5, 3, 2024)), '2024-03-05');
        Assert.AreEqual('91766F00', DateBytes(DMY2Date(31, 12, 9999)), '9999-12-31 is the last valid date');
        Assert.AreEqual('42921600', DateBytes(ClosingDate(DMY2Date(31, 12, 2024))), 'the closing date of 2024-12-31 is one day number later than the date itself');
    end;

    [Test]
    procedure Write_Decimal_IsTwelveBytes_ExponentThenPackedDigits()
    begin
        Assert.AreEqual('000000000000000000000000', DecimalBytes(0), '0');
        Assert.AreEqual('400000000000000000100000', DecimalBytes(1), '1');
        Assert.AreEqual('C00000000000000000100000', DecimalBytes(-1), '-1');
        Assert.AreEqual('400000000000000000150000', DecimalBytes(1.5), '1.5');
        Assert.AreEqual('420000000000000000100000', DecimalBytes(100), '100');
        Assert.AreEqual('3E0000000000000000100000', DecimalBytes(0.01), '0.01');
        Assert.AreEqual('380000000000000000100000', DecimalBytes(0.00000001), '0.00000001');
        Assert.AreEqual('BF0000000000000000500000', DecimalBytes(-0.5), '-0.5');
        Assert.AreEqual('488967452391785634120000', DecimalBytes(123456789.123456789), '123456789.123456789');
        Assert.AreEqual('4E9099999999999999990000', DecimalBytes(999999999999999.99), '999999999999999.99');
    end;

    [Test]
    procedure Write_Decimal_ReadsBackUnchanged()
    begin
        Assert.AreEqual('1.5', DecimalRoundTrip(1.5), '1.5');
        Assert.AreEqual('123456789.123456789', DecimalRoundTrip(123456789.123456789), 'nine decimals');
        Assert.AreEqual('0.01', DecimalRoundTrip(0.01), '0.01');
    end;
}
