// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-write-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT P89 Rec (74625), LT P89 Helper (74627)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74645 "LT P89 Stream CharByteOpt"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure DumpChar(V: Char): Text
    var
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.Write(V);
        Rec.Modify();
        exit(Helper.Dump(Rec));
    end;

    [TryFunction]
    local procedure TryReadChar(var Ins: InStream; var V: Char; var N: Integer)
    begin
        N := Ins.Read(V);
    end;

    local procedure ReadChar(var Ins: InStream; var V: Char): Text
    var
        N: Integer;
    begin
        if TryReadChar(Ins, V, N) then
            exit('ok n=' + Format(N));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Char_BytesWritten()
    var
        Observer: Codeunit "Probe Observer";
        V: Char;
    begin
        V := 0;
        Observer.Observe('v1_zero', DumpChar(V));
        V := 65;
        Observer.Observe('v2_A', DumpChar(V));
        V := 255;
        Observer.Observe('v3_255', DumpChar(V));
        V := 256;
        Observer.Observe('v4_256', DumpChar(V));
        V := 8364;
        Observer.Observe('v5_euro', DumpChar(V));
        Observer.Finish();
    end;

    [Test]
    procedure Char_RoundTrip_PastEnd()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
        Ins: InStream;
        EmptyIns: InStream;
        R: Char;
        R2: Char;
        R3: Char;
        V: Char;
    begin
        Helper.Fresh(Rec);
        V := 65;
        Rec.Data.CreateOutStream(Out);
        Out.Write(V);
        Out.Write(V);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('length', Format(Rec.Data.Length()));
        Observer.Observe('read1', ReadChar(Ins, R));
        Observer.Observe('value1', Format(R));
        Observer.Observe('matches', Format(Format(R) = Format(V)));
        Observer.Observe('eos_after1', Format(Ins.EOS()));
        Observer.Observe('read2', ReadChar(Ins, R2));
        Observer.Observe('value2', Format(R2));
        Observer.Observe('eos_after2', Format(Ins.EOS()));
        Observer.Observe('read_past_end', ReadChar(Ins, R3));
        Observer.Observe('value_past_end', Format(R3));
        Observer.Observe('eos_past_end', Format(Ins.EOS()));
        Helper.Fresh(Rec);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(EmptyIns);
        Observer.Observe('empty_eos', Format(EmptyIns.EOS()));
        Observer.Observe('read_empty', ReadChar(EmptyIns, R3));
        Observer.Observe('value_empty', Format(R3));
        Observer.Finish();
    end;

    local procedure DumpByte(V: Byte): Text
    var
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.Write(V);
        Rec.Modify();
        exit(Helper.Dump(Rec));
    end;

    [TryFunction]
    local procedure TryReadByte(var Ins: InStream; var V: Byte; var N: Integer)
    begin
        N := Ins.Read(V);
    end;

    local procedure ReadByte(var Ins: InStream; var V: Byte): Text
    var
        N: Integer;
    begin
        if TryReadByte(Ins, V, N) then
            exit('ok n=' + Format(N));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Byte_BytesWritten()
    var
        Observer: Codeunit "Probe Observer";
        V: Byte;
    begin
        V := 0;
        Observer.Observe('v1_zero', DumpByte(V));
        V := 1;
        Observer.Observe('v2_one', DumpByte(V));
        V := 200;
        Observer.Observe('v3_200', DumpByte(V));
        V := 255;
        Observer.Observe('v4_max', DumpByte(V));
        Observer.Finish();
    end;

    [Test]
    procedure Byte_RoundTrip_PastEnd()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
        Ins: InStream;
        EmptyIns: InStream;
        R: Byte;
        R2: Byte;
        R3: Byte;
        V: Byte;
    begin
        Helper.Fresh(Rec);
        V := 1;
        Rec.Data.CreateOutStream(Out);
        Out.Write(V);
        Out.Write(V);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('length', Format(Rec.Data.Length()));
        Observer.Observe('read1', ReadByte(Ins, R));
        Observer.Observe('value1', Format(R));
        Observer.Observe('matches', Format(Format(R) = Format(V)));
        Observer.Observe('eos_after1', Format(Ins.EOS()));
        Observer.Observe('read2', ReadByte(Ins, R2));
        Observer.Observe('value2', Format(R2));
        Observer.Observe('eos_after2', Format(Ins.EOS()));
        Observer.Observe('read_past_end', ReadByte(Ins, R3));
        Observer.Observe('value_past_end', Format(R3));
        Observer.Observe('eos_past_end', Format(Ins.EOS()));
        Helper.Fresh(Rec);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(EmptyIns);
        Observer.Observe('empty_eos', Format(EmptyIns.EOS()));
        Observer.Observe('read_empty', ReadByte(EmptyIns, R3));
        Observer.Observe('value_empty', Format(R3));
        Observer.Finish();
    end;

    local procedure DumpOption(V: Option A,B,C): Text
    var
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.Write(V);
        Rec.Modify();
        exit(Helper.Dump(Rec));
    end;

    [TryFunction]
    local procedure TryReadOption(var Ins: InStream; var V: Option A,B,C; var N: Integer)
    begin
        N := Ins.Read(V);
    end;

    local procedure ReadOption(var Ins: InStream; var V: Option A,B,C): Text
    var
        N: Integer;
    begin
        if TryReadOption(Ins, V, N) then
            exit('ok n=' + Format(N));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Option_BytesWritten()
    var
        Observer: Codeunit "Probe Observer";
        V: Option A,B,C;
    begin
        V := V::A;
        Observer.Observe('v1_A', DumpOption(V));
        V := V::B;
        Observer.Observe('v2_B', DumpOption(V));
        V := V::C;
        Observer.Observe('v3_C', DumpOption(V));
        Observer.Finish();
    end;

    [Test]
    procedure Option_RoundTrip_PastEnd()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
        Ins: InStream;
        EmptyIns: InStream;
        R: Option A,B,C;
        R2: Option A,B,C;
        R3: Option A,B,C;
        V: Option A,B,C;
    begin
        Helper.Fresh(Rec);
        V := V::B;
        Rec.Data.CreateOutStream(Out);
        Out.Write(V);
        Out.Write(V);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('length', Format(Rec.Data.Length()));
        Observer.Observe('read1', ReadOption(Ins, R));
        Observer.Observe('value1', Format(R));
        Observer.Observe('matches', Format(Format(R) = Format(V)));
        Observer.Observe('eos_after1', Format(Ins.EOS()));
        Observer.Observe('read2', ReadOption(Ins, R2));
        Observer.Observe('value2', Format(R2));
        Observer.Observe('eos_after2', Format(Ins.EOS()));
        Observer.Observe('read_past_end', ReadOption(Ins, R3));
        Observer.Observe('value_past_end', Format(R3));
        Observer.Observe('eos_past_end', Format(Ins.EOS()));
        Helper.Fresh(Rec);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(EmptyIns);
        Observer.Observe('empty_eos', Format(EmptyIns.EOS()));
        Observer.Observe('read_empty', ReadOption(EmptyIns, R3));
        Observer.Observe('value_empty', Format(R3));
        Observer.Finish();
    end;

}
