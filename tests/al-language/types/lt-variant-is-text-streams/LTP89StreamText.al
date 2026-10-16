// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-write-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT P89 Rec (74625), LT P89 Helper (74627)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74646 "LT P89 Stream Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure DumpText(V: Text): Text
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

    local procedure DumpText10(V: Text[10]): Text
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

    local procedure DumpCode(V: Code[10]): Text
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
    local procedure TryWriteLen(var Out: OutStream; V: Text; Len: Integer)
    begin
        Out.Write(V, Len);
    end;

    [TryFunction]
    local procedure TryReadText(var Ins: InStream; var V: Text; var N: Integer)
    begin
        N := Ins.Read(V);
    end;

    [TryFunction]
    local procedure TryReadTextLen(var Ins: InStream; var V: Text; Len: Integer; var N: Integer)
    begin
        N := Ins.Read(V, Len);
    end;

    [TryFunction]
    local procedure TryReadText10(var Ins: InStream; var V: Text[10]; var N: Integer)
    begin
        N := Ins.Read(V);
    end;

    [TryFunction]
    local procedure TryReadCode(var Ins: InStream; var V: Code[10]; var N: Integer)
    begin
        N := Ins.Read(V);
    end;

    local procedure ReadText(var Ins: InStream; var V: Text): Text
    var
        N: Integer;
    begin
        if TryReadText(Ins, V, N) then
            exit('ok n=' + Format(N));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ReadTextLen(var Ins: InStream; var V: Text; Len: Integer): Text
    var
        N: Integer;
    begin
        if TryReadTextLen(Ins, V, Len, N) then
            exit('ok n=' + Format(N));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ReadText10(var Ins: InStream; var V: Text[10]): Text
    var
        N: Integer;
    begin
        if TryReadText10(Ins, V, N) then
            exit('ok n=' + Format(N));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ReadCode(var Ins: InStream; var V: Code[10]): Text
    var
        N: Integer;
    begin
        if TryReadCode(Ins, V, N) then
            exit('ok n=' + Format(N));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Text_BytesWritten()
    var
        Observer: Codeunit "Probe Observer";
        Wide: Text;
    begin
        Observer.Observe('empty', DumpText(''));
        Observer.Observe('a', DumpText('a'));
        Observer.Observe('abc', DumpText('abc'));
        Observer.Observe('spaces', DumpText('  '));
        Observer.Observe('umlaut', DumpText('äöü'));
        Wide[1] := 8364;
        Observer.Observe('euro', DumpText(Wide));
        Wide[1] := 0;
        Observer.Observe('nul_char', DumpText(Wide));
        Observer.Observe('nul_between', DumpText('a' + Format(Wide) + 'b'));
        Observer.Observe('text10_abc', DumpText10('abc'));
        Observer.Observe('text10_empty', DumpText10(''));
        Observer.Observe('code_abc', DumpCode('abc'));
        Observer.Observe('code_empty', DumpCode(''));
        Observer.Finish();
    end;

    [Test]
    procedure Text_WriteWithLength()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
        Lens: List of [Integer];
        Len: Integer;
        Res: Text;
    begin
        Lens.Add(0);
        Lens.Add(1);
        Lens.Add(3);
        Lens.Add(5);
        Lens.Add(10);
        Lens.Add(-1);
        foreach Len in Lens do begin
            Helper.Fresh(Rec);
            Rec.Data.CreateOutStream(Out);
            if TryWriteLen(Out, 'abcde', Len) then
                Res := 'ok'
            else
                Res := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
            Rec.Modify();
            Observer.Observe('len' + Format(Len), Res);
            Observer.Observe('len' + Format(Len) + '_bytes', Helper.Dump(Rec));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Text_RoundTrip_PastEnd()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
        Ins: InStream;
        EmptyIns: InStream;
        R: Text;
        R2: Text;
        R3: Text;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.Write('abc');
        Out.Write('de');
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('length', Format(Rec.Data.Length()));
        Observer.Observe('read1', ReadText(Ins, R));
        Observer.Observe('value1', R);
        Observer.Observe('eos_after1', Format(Ins.EOS()));
        Observer.Observe('read2', ReadText(Ins, R2));
        Observer.Observe('value2', R2);
        Observer.Observe('read_past_end', ReadText(Ins, R3));
        Observer.Observe('value_past_end', R3);
        Helper.Fresh(Rec);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(EmptyIns);
        Observer.Observe('empty_eos', Format(EmptyIns.EOS()));
        Observer.Observe('read_empty', ReadText(EmptyIns, R3));
        Observer.Observe('value_empty', R3);
        Observer.Finish();
    end;

    [Test]
    procedure Text_ReadWithLength()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
        Ins: InStream;
        R: Text;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.Write('abcdefgh');
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('read_len3', ReadTextLen(Ins, R, 3));
        Observer.Observe('value_len3', R);
        Observer.Observe('pos_after_len3', Format(Ins.Position()));
        Observer.Observe('read_len0', ReadTextLen(Ins, R, 0));
        Observer.Observe('value_len0', R);
        Observer.Observe('read_len2', ReadTextLen(Ins, R, 2));
        Observer.Observe('value_len2', R);
        Observer.Observe('read_len100', ReadTextLen(Ins, R, 100));
        Observer.Observe('value_len100', R);
        Observer.Observe('eos', Format(Ins.EOS()));
        Observer.Observe('read_len1_past_end', ReadTextLen(Ins, R, 1));
        Observer.Observe('value_len1_past_end', R);
        Observer.Observe('read_len_minus1', ReadTextLen(Ins, R, -1));
        Observer.Finish();
    end;

    [Test]
    procedure Text_ReadIntoBoundedTypes()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
        Ins: InStream;
        T10: Text[10];
        C10: Code[10];
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.Write('abcdefghijklmnop');
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('read_text10', ReadText10(Ins, T10));
        Observer.Observe('value_text10', T10);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('read_code10', ReadCode(Ins, C10));
        Observer.Observe('value_code10', C10);
        Observer.Finish();
    end;

    [Test]
    procedure Text_WriteText_VsWrite()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.WriteText('abc');
        Rec.Modify();
        Observer.Observe('writetext', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.Write('abc');
        Rec.Modify();
        Observer.Observe('write', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.WriteText('abc');
        Out.WriteText();
        Rec.Modify();
        Observer.Observe('writetext_then_newline', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.WriteText('');
        Rec.Modify();
        Observer.Observe('writetext_empty', Helper.Dump(Rec));
        Observer.Finish();
    end;
}
