// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-data-type
// Scope: in-scope (OnPrem test app only: the File type is Scope = OnPrem; temporary paths only)
// Fixtures used: Probe Observer (69160); own table LT P110 File Rec (61279)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Pins File.Write per value type in binary and in text mode: the Write result, File.Pos and File.Len afterward (Pos/Len), and the exact bytes in the file read back through File.CreateInStream (hex). A value that BC refuses shows the error text and code.
// BC versions: 29 (27 and 28 by CI)
codeunit 61284 "LT Q File Write Oth"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LblText: Label 'label text';

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
    local procedure W_Code(var F: File; V: Code[10])
    begin
        F.Write(V);
    end;

    local procedure Do_Code(var Observer: Codeunit "Probe Observer"; Id: Text; V: Code[10]; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Code(F, V) then
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
    local procedure W_Date(var F: File; V: Date)
    begin
        F.Write(V);
    end;

    local procedure Do_Date(var Observer: Codeunit "Probe Observer"; Id: Text; V: Date; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Date(F, V) then
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
    local procedure W_DateFormula(var F: File; V: DateFormula)
    begin
        F.Write(V);
    end;

    local procedure Do_DateFormula(var Observer: Codeunit "Probe Observer"; Id: Text; V: DateFormula; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_DateFormula(F, V) then
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
    local procedure W_DateTime(var F: File; V: DateTime)
    begin
        F.Write(V);
    end;

    local procedure Do_DateTime(var Observer: Codeunit "Probe Observer"; Id: Text; V: DateTime; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_DateTime(F, V) then
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
    local procedure W_Duration(var F: File; V: Duration)
    begin
        F.Write(V);
    end;

    local procedure Do_Duration(var Observer: Codeunit "Probe Observer"; Id: Text; V: Duration; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Duration(F, V) then
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
    local procedure W_Text(var F: File; V: Text)
    begin
        F.Write(V);
    end;

    local procedure Do_Text(var Observer: Codeunit "Probe Observer"; Id: Text; V: Text; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Text(F, V) then
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
    local procedure W_Time(var F: File; V: Time)
    begin
        F.Write(V);
    end;

    local procedure Do_Time(var Observer: Codeunit "Probe Observer"; Id: Text; V: Time; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Time(F, V) then
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
    local procedure W_BigText(var F: File; V: BigText)
    begin
        F.Write(V);
    end;

    local procedure Do_BigText(var Observer: Codeunit "Probe Observer"; Id: Text; V: BigText; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_BigText(F, V) then
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
    procedure Write_Code_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: Code[10];
    begin
        Clear(V);
        V := 'ABC123';
        Do_Code(Observer, 'bin_abc', V, false);
        Do_Code(Observer, 'txt_abc', V, true);
        Clear(V);
        V := '';
        Do_Code(Observer, 'bin_empty', V, false);
        Do_Code(Observer, 'txt_empty', V, true);
        Observer.Finish();
    end;

    [Test]
    procedure Write_Date_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: Date;
    begin
        Clear(V);
        V := DMY2Date(24, 12, 2020);
        Do_Date(Observer, 'bin_d', V, false);
        Do_Date(Observer, 'txt_d', V, true);
        Clear(V);
        V := 0D;
        Do_Date(Observer, 'bin_blank', V, false);
        Do_Date(Observer, 'txt_blank', V, true);
        Observer.Finish();
    end;

    [Test]
    procedure Write_DateFormula_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: DateFormula;
    begin
        Clear(V);
        Evaluate(V, '<1M+CM>');
        Do_DateFormula(Observer, 'bin_f', V, false);
        Do_DateFormula(Observer, 'txt_f', V, true);
        Observer.Finish();
    end;

    [Test]
    procedure Write_DateTime_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: DateTime;
    begin
        Clear(V);
        V := CreateDateTime(DMY2Date(1, 2, 2021), 143015T);
        Do_DateTime(Observer, 'bin_dt', V, false);
        Do_DateTime(Observer, 'txt_dt', V, true);
        Clear(V);
        V := 0DT;
        Do_DateTime(Observer, 'bin_blank', V, false);
        Do_DateTime(Observer, 'txt_blank', V, true);
        Observer.Finish();
    end;

    [Test]
    procedure Write_Duration_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: Duration;
    begin
        Clear(V);
        V := 90061001;
        Do_Duration(Observer, 'bin_d', V, false);
        Do_Duration(Observer, 'txt_d', V, true);
        Clear(V);
        V := 0;
        Do_Duration(Observer, 'bin_zero', V, false);
        Do_Duration(Observer, 'txt_zero', V, true);
        Observer.Finish();
    end;

    [Test]
    procedure Write_Text_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: Text;
    begin
        Clear(V);
        V := 'plain text';
        Do_Text(Observer, 'bin_plain', V, false);
        Do_Text(Observer, 'txt_plain', V, true);
        Clear(V);
        V := '';
        Do_Text(Observer, 'bin_empty', V, false);
        Do_Text(Observer, 'txt_empty', V, true);
        Observer.Finish();
    end;

    [Test]
    procedure Write_Time_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: Time;
    begin
        Clear(V);
        V := 235959T;
        Do_Time(Observer, 'bin_t', V, false);
        Do_Time(Observer, 'txt_t', V, true);
        Clear(V);
        V := 0T;
        Do_Time(Observer, 'bin_blank', V, false);
        Do_Time(Observer, 'txt_blank', V, true);
        Observer.Finish();
    end;

    [Test]
    procedure Write_BigText_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: BigText;
    begin
        Clear(V);
        V.AddText('bigtext value');
        Do_BigText(Observer, 'bin_bt', V, false);
        Do_BigText(Observer, 'txt_bt', V, true);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure W_Label(var F: File)
    begin
        F.Write(LblText);
    end;

    [Test]
    procedure Write_Label_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(false);
        if W_Label(F) then
            Observer.Observe('bin_w', 'ok')
        else
            Observer.ObserveError('bin_w');
        Observer.Observe('bin_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe('bin_bytes', Hex)
        else
            Observer.ObserveError('bin_bytes');
        F.Close();
        Cleanup(P);
        P := TempName();
        F.Create(P);
        F.TextMode(true);
        if W_Label(F) then
            Observer.Observe('txt_w', 'ok')
        else
            Observer.ObserveError('txt_w');
        Observer.Observe('txt_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe('txt_bytes', Hex)
        else
            Observer.ObserveError('txt_bytes');
        F.Close();
        Cleanup(P);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure W_Record(var F: File; var R: Record "LT P110 File Rec")
    begin
        F.Write(R);
    end;

    [TryFunction]
    local procedure W_RecordId(var F: File; Id: RecordId)
    begin
        F.Write(Id);
    end;

    local procedure Do_Record(var Observer: Codeunit "Probe Observer"; Id: Text; AsText: Boolean)
    var
        R: Record "LT P110 File Rec";
        F: File;
        P: Text;
        Hex: Text;
    begin
        R.Code := 'A1';
        R.Amount := 12.5;
        R.Note := 'note';
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Record(F, R) then
            Observer.Observe(Id + '_rec_w', 'ok')
        else
            Observer.ObserveError(Id + '_rec_w');
        Observer.Observe(Id + '_rec_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_rec_bytes', Hex)
        else
            Observer.ObserveError(Id + '_rec_bytes');
        F.Close();
        Cleanup(P);
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_RecordId(F, R.RecordId()) then
            Observer.Observe(Id + '_rid_w', 'ok')
        else
            Observer.ObserveError(Id + '_rid_w');
        Observer.Observe(Id + '_rid_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_rid_bytes', Hex)
        else
            Observer.ObserveError(Id + '_rid_bytes');
        F.Close();
        Cleanup(P);
    end;

    [Test]
    procedure Write_Record_RecordId_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Do_Record(Observer, 'bin', false);
        Do_Record(Observer, 'txt', true);
        Observer.Finish();
    end;
}
