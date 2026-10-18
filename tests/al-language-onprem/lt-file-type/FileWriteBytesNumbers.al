// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-data-type
// Scope: in-scope (OnPrem test app only: the File type is Scope = OnPrem; temporary paths only)
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Pins File.Write per value type in binary and in text mode: the Write result, File.Pos and File.Len afterward (Pos/Len), and the exact bytes in the file read back through File.CreateInStream (hex). A value that BC refuses shows the error text and code.
// BC versions: 29 (27 and 28 by CI)
codeunit 61283 "LT Q File Write Num"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ErrHead(T: Text): Text
    var
        P1: Integer;
        P2: Integer;
        Cut: Integer;
    begin
        P1 := StrPos(T, '/');
        P2 := StrPos(T, '''');
        Cut := P1;
        if (Cut = 0) or ((P2 > 0) and (P2 < Cut)) then
            Cut := P2;
        if Cut > 0 then
            exit(CopyStr(T, 1, Cut - 1));
        exit(CopyStr(T, 1, 200));
    end;

    local procedure TempName(): Text
    begin
        exit(TemporaryPath() + DelChr(Format(CreateGuid()), '=', '{}-') + '.tmp');
    end;

    local procedure Cleanup(Name: Text)
    begin
        if File.Exists(Name) then
            File.Erase(Name);
    end;

    local procedure ByteHex(B: Byte): Text
    var
        Digits: Text;
    begin
        Digits := '0123456789ABCDEF';
        exit(CopyStr(Digits, (B div 16) + 1, 1) + CopyStr(Digits, (B mod 16) + 1, 1));
    end;

    [TryFunction]
    local procedure Dump(var F: File; var Hex: Text)
    var
        Ins: InStream;
        B: Byte;
    begin
        Hex := '';
        F.CreateInStream(Ins);
        while not Ins.EOS() do begin
            Ins.Read(B);
            Hex += ByteHex(B);
        end;
    end;

    [TryFunction]
    local procedure W_BigInteger(var F: File; V: BigInteger)
    begin
        F.Write(V);
    end;

    local procedure Do_BigInteger(var Observer: Codeunit "Probe Observer"; Id: Text; V: BigInteger; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_BigInteger(F, V) then
            Observer.Observe(Id + '_w', 'ok')
        else
            Observer.ObserveError(Id + '_w');
        Observer.Observe(Id + '_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_bytes', Hex)
        else
            Observer.ObserveError(Id + '_bytes');
        F.Close();
        Cleanup(P);
    end;

    [TryFunction]
    local procedure W_Boolean(var F: File; V: Boolean)
    begin
        F.Write(V);
    end;

    local procedure Do_Boolean(var Observer: Codeunit "Probe Observer"; Id: Text; V: Boolean; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Boolean(F, V) then
            Observer.Observe(Id + '_w', 'ok')
        else
            Observer.ObserveError(Id + '_w');
        Observer.Observe(Id + '_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_bytes', Hex)
        else
            Observer.ObserveError(Id + '_bytes');
        F.Close();
        Cleanup(P);
    end;

    [TryFunction]
    local procedure W_Byte(var F: File; V: Byte)
    begin
        F.Write(V);
    end;

    local procedure Do_Byte(var Observer: Codeunit "Probe Observer"; Id: Text; V: Byte; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Byte(F, V) then
            Observer.Observe(Id + '_w', 'ok')
        else
            Observer.ObserveError(Id + '_w');
        Observer.Observe(Id + '_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_bytes', Hex)
        else
            Observer.ObserveError(Id + '_bytes');
        F.Close();
        Cleanup(P);
    end;

    [TryFunction]
    local procedure W_Char(var F: File; V: Char)
    begin
        F.Write(V);
    end;

    local procedure Do_Char(var Observer: Codeunit "Probe Observer"; Id: Text; V: Char; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Char(F, V) then
            Observer.Observe(Id + '_w', 'ok')
        else
            Observer.ObserveError(Id + '_w');
        Observer.Observe(Id + '_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_bytes', Hex)
        else
            Observer.ObserveError(Id + '_bytes');
        F.Close();
        Cleanup(P);
    end;

    [TryFunction]
    local procedure W_Decimal(var F: File; V: Decimal)
    begin
        F.Write(V);
    end;

    local procedure Do_Decimal(var Observer: Codeunit "Probe Observer"; Id: Text; V: Decimal; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Decimal(F, V) then
            Observer.Observe(Id + '_w', 'ok')
        else
            Observer.ObserveError(Id + '_w');
        Observer.Observe(Id + '_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_bytes', Hex)
        else
            Observer.ObserveError(Id + '_bytes');
        F.Close();
        Cleanup(P);
    end;

    [TryFunction]
    local procedure W_Guid(var F: File; V: Guid)
    begin
        F.Write(V);
    end;

    local procedure Do_Guid(var Observer: Codeunit "Probe Observer"; Id: Text; V: Guid; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Guid(F, V) then
            Observer.Observe(Id + '_w', 'ok')
        else
            Observer.ObserveError(Id + '_w');
        Observer.Observe(Id + '_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_bytes', Hex)
        else
            Observer.ObserveError(Id + '_bytes');
        F.Close();
        Cleanup(P);
    end;

    [TryFunction]
    local procedure W_Integer(var F: File; V: Integer)
    begin
        F.Write(V);
    end;

    local procedure Do_Integer(var Observer: Codeunit "Probe Observer"; Id: Text; V: Integer; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Integer(F, V) then
            Observer.Observe(Id + '_w', 'ok')
        else
            Observer.ObserveError(Id + '_w');
        Observer.Observe(Id + '_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_bytes', Hex)
        else
            Observer.ObserveError(Id + '_bytes');
        F.Close();
        Cleanup(P);
    end;

    [TryFunction]
    local procedure W_Option(var F: File; V: Option A,B,C)
    begin
        F.Write(V);
    end;

    local procedure Do_Option(var Observer: Codeunit "Probe Observer"; Id: Text; V: Option A,B,C; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Option(F, V) then
            Observer.Observe(Id + '_w', 'ok')
        else
            Observer.ObserveError(Id + '_w');
        Observer.Observe(Id + '_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_bytes', Hex)
        else
            Observer.ObserveError(Id + '_bytes');
        F.Close();
        Cleanup(P);
    end;

    [Test]
    procedure Write_BigInteger_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: BigInteger;
    begin
        Clear(V);
        V := 258;
        Do_BigInteger(Observer, 'bin_small', V, false);
        Do_BigInteger(Observer, 'txt_small', V, true);
        Clear(V);
        V := 2147483647; V := V * 4;
        Do_BigInteger(Observer, 'bin_big', V, false);
        Do_BigInteger(Observer, 'txt_big', V, true);
        Observer.Expect('bin_small_w', 'ok');
        Observer.Expect('bin_small_pos', '8/8');
        Observer.Expect('bin_small_bytes', '0201000000000000');
        Observer.Expect('txt_small_w', 'ok');
        Observer.Expect('txt_small_pos', '5/5');
        Observer.Expect('txt_small_bytes', '3235380D0A');
        Observer.Expect('bin_big_w', 'ok');
        Observer.Expect('bin_big_pos', '8/8');
        Observer.Expect('bin_big_bytes', 'FCFFFFFF01000000');
        Observer.Expect('txt_big_w', 'ok');
        Observer.Expect('txt_big_pos', '12/12');
        Observer.Expect('txt_big_bytes', '383538393933343538380D0A');
        Observer.Verify();
    end;

    [Test]
    procedure Write_Boolean_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: Boolean;
    begin
        Clear(V);
        V := true;
        Do_Boolean(Observer, 'bin_yes', V, false);
        Do_Boolean(Observer, 'txt_yes', V, true);
        Clear(V);
        V := false;
        Do_Boolean(Observer, 'bin_no', V, false);
        Do_Boolean(Observer, 'txt_no', V, true);
        Observer.Expect('bin_yes_w', 'ok');
        Observer.Expect('bin_yes_pos', '4/4');
        Observer.Expect('bin_yes_bytes', '01000000');
        Observer.Expect('txt_yes_w', 'ok');
        Observer.Expect('txt_yes_pos', '5/5');
        Observer.Expect('txt_yes_bytes', '5965730D0A');
        Observer.Expect('bin_no_w', 'ok');
        Observer.Expect('bin_no_pos', '4/4');
        Observer.Expect('bin_no_bytes', '00000000');
        Observer.Expect('txt_no_w', 'ok');
        Observer.Expect('txt_no_pos', '4/4');
        Observer.Expect('txt_no_bytes', '4E6F0D0A');
        Observer.Verify();
    end;

    [Test]
    procedure Write_Byte_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: Byte;
    begin
        Clear(V);
        V := 200;
        Do_Byte(Observer, 'bin_b200', V, false);
        Do_Byte(Observer, 'txt_b200', V, true);
        Clear(V);
        V := 0;
        Do_Byte(Observer, 'bin_b0', V, false);
        Do_Byte(Observer, 'txt_b0', V, true);
        Observer.Expect('bin_b200_w', 'ok');
        Observer.Expect('bin_b200_pos', '1/1');
        Observer.Expect('bin_b200_bytes', 'C8');
        Observer.Expect('txt_b200_w', 'ok');
        Observer.Expect('txt_b200_pos', '3/3');
        Observer.Expect('txt_b200_bytes', 'C80D0A');
        Observer.Expect('bin_b0_w', 'ok');
        Observer.Expect('bin_b0_pos', '1/1');
        Observer.Expect('bin_b0_bytes', '00');
        Observer.Expect('txt_b0_w', 'ok');
        Observer.Expect('txt_b0_pos', '3/3');
        Observer.Expect('txt_b0_bytes', '000D0A');
        Observer.Verify();
    end;

    [Test]
    procedure Write_Char_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: Char;
    begin
        Clear(V);
        V := 65;
        Do_Char(Observer, 'bin_a', V, false);
        Do_Char(Observer, 'txt_a', V, true);
        Clear(V);
        V := 8364;
        Do_Char(Observer, 'bin_euro', V, false);
        Do_Char(Observer, 'txt_euro', V, true);
        Observer.Expect('bin_a_w', 'ok');
        Observer.Expect('bin_a_pos', '1/1');
        Observer.Expect('bin_a_bytes', '41');
        Observer.Expect('txt_a_w', 'ok');
        Observer.Expect('txt_a_pos', '3/3');
        Observer.Expect('txt_a_bytes', '410D0A');
        Observer.Expect('bin_euro_w', 'ok');
        Observer.Expect('bin_euro_pos', '1/1');
        Observer.Expect('bin_euro_bytes', 'B1');
        Observer.Expect('txt_euro_w', 'ok');
        Observer.Expect('txt_euro_pos', '3/3');
        Observer.Expect('txt_euro_bytes', 'B10D0A');
        Observer.Verify();
    end;

    [Test]
    procedure Write_Decimal_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: Decimal;
    begin
        Clear(V);
        V := -12345.6789;
        Do_Decimal(Observer, 'bin_neg', V, false);
        Do_Decimal(Observer, 'txt_neg', V, true);
        Clear(V);
        V := 0;
        Do_Decimal(Observer, 'bin_zero', V, false);
        Do_Decimal(Observer, 'txt_zero', V, true);
        Observer.Expect('bin_neg_w', 'ok');
        Observer.Expect('bin_neg_pos', '12/12');
        Observer.Expect('bin_neg_bytes', 'C40000000090785634120000');
        Observer.Expect('txt_neg_w', 'ok');
        Observer.Expect('txt_neg_pos', '14/14');
        Observer.Expect('txt_neg_bytes', '2D31322C3334352E363738390D0A');
        Observer.Expect('bin_zero_w', 'ok');
        Observer.Expect('bin_zero_pos', '12/12');
        Observer.Expect('bin_zero_bytes', '000000000000000000000000');
        Observer.Expect('txt_zero_w', 'ok');
        Observer.Expect('txt_zero_pos', '3/3');
        Observer.Expect('txt_zero_bytes', '300D0A');
        Observer.Verify();
    end;

    [Test]
    procedure Write_Guid_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: Guid;
    begin
        Clear(V);
        Evaluate(V, '{12345678-1234-1234-1234-123456789ABC}');
        Do_Guid(Observer, 'bin_g', V, false);
        Do_Guid(Observer, 'txt_g', V, true);
        Observer.Expect('bin_g_w', 'ok');
        Observer.Expect('bin_g_pos', '16/16');
        Observer.Expect('bin_g_bytes', '78563412341234121234123456789ABC');
        Observer.Expect('txt_g_w', 'ok');
        Observer.Expect('txt_g_pos', '40/40');
        Observer.Expect('txt_g_bytes', '7B31323334353637382D313233342D313233342D313233342D3132333435363738394142437D0D0A');
        Observer.Verify();
    end;

    [Test]
    procedure Write_Integer_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: Integer;
    begin
        Clear(V);
        V := -42;
        Do_Integer(Observer, 'bin_neg', V, false);
        Do_Integer(Observer, 'txt_neg', V, true);
        Clear(V);
        V := 258;
        Do_Integer(Observer, 'bin_n258', V, false);
        Do_Integer(Observer, 'txt_n258', V, true);
        Observer.Expect('bin_neg_w', 'ok');
        Observer.Expect('bin_neg_pos', '4/4');
        Observer.Expect('bin_neg_bytes', 'D6FFFFFF');
        Observer.Expect('txt_neg_w', 'ok');
        Observer.Expect('txt_neg_pos', '5/5');
        Observer.Expect('txt_neg_bytes', '2D34320D0A');
        Observer.Expect('bin_n258_w', 'ok');
        Observer.Expect('bin_n258_pos', '4/4');
        Observer.Expect('bin_n258_bytes', '02010000');
        Observer.Expect('txt_n258_w', 'ok');
        Observer.Expect('txt_n258_pos', '5/5');
        Observer.Expect('txt_n258_bytes', '3235380D0A');
        Observer.Verify();
    end;

    [Test]
    procedure Write_Option_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: Option A,B,C;
    begin
        Clear(V);
        V := V::B;
        Do_Option(Observer, 'bin_b', V, false);
        Do_Option(Observer, 'txt_b', V, true);
        Observer.Expect('bin_b_w', 'ok');
        Observer.Expect('bin_b_pos', '4/4');
        Observer.Expect('bin_b_bytes', '01000000');
        Observer.Expect('txt_b_w', 'ok');
        Observer.Expect('txt_b_pos', '3/3');
        Observer.Expect('txt_b_bytes', '420D0A');
        Observer.Verify();
    end;
}
