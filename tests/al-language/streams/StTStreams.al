// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/instream/instream-data-type
// Scope: in-scope
// Fixtures used: table 74200, codeunit 69160 "Probe Observer"
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74200 "LT StT Streams"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Fresh(var Rec: Record "LT StT Rec")
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 1;
        Rec.Insert();
    end;

    local procedure Crlf(): Text
    var
        T: Text;
    begin
        T[1] := 13;
        T[2] := 10;
        exit(T);
    end;

    [Test]
    procedure WriteTextReadText()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        T: Text;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.WriteText('Hello');
        Out.WriteText(' World');
        Observer.Observe('hasvalue-before-modify', Format(Rec.Data.HasValue()));
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('hasvalue', Format(Rec.Data.HasValue()));
        Observer.Observe('length', Format(Rec.Data.Length()));
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('eos-start', Format(Ins.EOS()));
        Ins.ReadText(T);
        Observer.Observe('text', T);
        Observer.Observe('eos-after', Format(Ins.EOS()));
        Observer.Observe('pos', Format(Ins.Position()));
        Observer.Expect('hasvalue-before-modify', 'Yes');
        Observer.Expect('hasvalue', 'Yes');
        Observer.Expect('length', '11');
        Observer.Expect('eos-start', 'No');
        Observer.Expect('text', 'Hello World');
        Observer.Expect('eos-after', 'Yes');
        Observer.Expect('pos', '12');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTextNoLineEnding()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        T: Text;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.WriteText('A');
        Out.WriteText();
        Out.WriteText('B');
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('length', Format(Rec.Data.Length()));
        Rec.Data.CreateInStream(Ins);
        Ins.ReadText(T);
        Observer.Observe('read', T);
        Observer.Observe('eos', Format(Ins.EOS()));
        Observer.Expect('length', '4');
        Observer.Expect('read', 'A');
        Observer.Expect('eos', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTextLineEnding()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        T: Text;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.WriteText('Line1');
        Out.WriteText();
        Out.WriteText('Line2');
        Out.WriteText();
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('length', Format(Rec.Data.Length()));
        Rec.Data.CreateInStream(Ins);
        Ins.ReadText(T);
        Observer.Observe('l1', T);
        Observer.Observe('eos1', Format(Ins.EOS()));
        Ins.ReadText(T);
        Observer.Observe('l2', T);
        Observer.Observe('eos2', Format(Ins.EOS()));
        Observer.Expect('length', '14');
        Observer.Expect('l1', 'Line1');
        Observer.Expect('eos1', 'No');
        Observer.Expect('l2', 'Line2');
        Observer.Expect('eos2', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadTextLineEndings()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        T: Text;
        Cr: Text[1];
        Lf: Text[1];
    begin
        Cr[1] := 13;
        Lf[1] := 10;
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.WriteText('a' + Cr + 'b' + Lf + 'c' + Cr + Lf + 'd' + Lf + Cr + 'e');
        Rec.Modify();
        Rec.Data.CreateInStream(Ins);
        Ins.ReadText(T);
        Observer.Observe('1', T);
        Ins.ReadText(T);
        Observer.Observe('2', T);
        Ins.ReadText(T);
        Observer.Observe('3', T);
        Ins.ReadText(T);
        Observer.Observe('4', T);
        Ins.ReadText(T);
        Observer.Observe('5', T);
        Observer.Observe('eos', Format(Ins.EOS()));
        Observer.Expect('1', 'ab');
        Observer.Expect('2', 'c');
        Observer.Expect('3', 'd');
        Observer.Expect('4', 'e');
        Observer.Expect('5', '');
        Observer.Expect('eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadTextLength()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        T: Text;
        Count: Integer;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.WriteText('0123456789');
        Rec.Modify();
        Rec.Data.CreateInStream(Ins);
        Count := Ins.ReadText(T, 4);
        Observer.Observe('count1', Format(Count));
        Observer.Observe('t1', T);
        Count := Ins.ReadText(T, 4);
        Observer.Observe('count2', Format(Count));
        Observer.Observe('t2', T);
        Count := Ins.ReadText(T, 4);
        Observer.Observe('count3', Format(Count));
        Observer.Observe('t3', T);
        Count := Ins.ReadText(T, 4);
        Observer.Observe('count4', Format(Count));
        Observer.Observe('t4', T);
        Observer.Observe('eos', Format(Ins.EOS()));
        Observer.Expect('count1', '4');
        Observer.Expect('t1', '0123');
        Observer.Expect('count2', '4');
        Observer.Expect('t2', '4567');
        Observer.Expect('count3', '2');
        Observer.Expect('t3', '89');
        Observer.Expect('count4', '0');
        Observer.Expect('t4', '');
        Observer.Expect('eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadTextLengthZeroAndNegative()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        T: Text;
        Count: Integer;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.WriteText('abc');
        Rec.Modify();
        Rec.Data.CreateInStream(Ins);
        T := 'unchanged';
        asserterror Count := Ins.ReadText(T, 0);
        Observer.ObserveError('af187');
        Observer.Observe('count0', Format(Count));
        Observer.Observe('t0', T);
        Observer.Observe('pos0', Format(Ins.Position()));
        asserterror Count := Ins.ReadText(T, -1);
        Observer.ObserveError('negative');
        Observer.Expect('af187|text', 'An invalid length 0 was specified in stream function. Length must be in range 1 to 2147483647.');
        Observer.Expect('af187|code', 'InvalidStreamLength');
        Observer.Expect('count0', '0');
        Observer.Expect('t0', 'unchanged');
        Observer.Expect('pos0', '1');
        Observer.Expect('negative|text', 'An invalid length -1 was specified in stream function. Length must be in range 1 to 2147483647.');
        Observer.Expect('negative|code', 'InvalidStreamLength');
        Observer.Verify();
    end;

    [Test]
    procedure ReadPastEnd()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        T: Text;
        Dec: Decimal;
        Int: Integer;
        Big: BigInteger;
        Bool: Boolean;
        Ch: Char;
        Dt: Date;
        Cnt: Integer;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.WriteText('x');
        Rec.Modify();
        Rec.Data.CreateInStream(Ins);
        Ins.ReadText(T);
        Observer.Observe('eos', Format(Ins.EOS()));
        Ins.ReadText(T);
        Observer.Observe('readtext', 'no error');
        asserterror Ins.Read(Int);
        Observer.ObserveError('readint');
        asserterror Ins.Read(Dec);
        Observer.ObserveError('readdec');
        asserterror Ins.Read(Big);
        Observer.ObserveError('readbig');
        asserterror Ins.Read(Bool);
        Observer.ObserveError('readbool');
        asserterror Ins.Read(Ch);
        Observer.ObserveError('readchar');
        asserterror Ins.Read(Dt);
        Observer.ObserveError('readdate');
        Ins.Read(T);
        Observer.Observe('readtextvia-read', 'no error');
        Observer.Expect('eos', 'Yes');
        Observer.Expect('readtext', 'no error');
        Observer.Expect('readint|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('readint|code', 'InvalidStreamData');
        Observer.Expect('readdec|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('readdec|code', 'InvalidStreamData');
        Observer.Expect('readbig|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('readbig|code', 'InvalidStreamData');
        Observer.Expect('readbool|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('readbool|code', 'InvalidStreamData');
        Observer.Expect('readchar|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('readchar|code', 'InvalidStreamData');
        Observer.Expect('readdate|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('readdate|code', 'InvalidStreamData');
        Observer.Expect('readtextvia-read', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromEmptyBlob()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Ins: InStream;
        T: Text;
        Int: Integer;
        Cnt: Integer;
    begin
        Fresh(Rec);
        Observer.Observe('hasvalue', Format(Rec.Data.HasValue()));
        Observer.Observe('length', Format(Rec.Data.Length()));
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('eos', Format(Ins.EOS()));
        Observer.Observe('pos', Format(Ins.Position()));
        Ins.ReadText(T);
        Observer.Observe('readtext', 'no error');
        asserterror Ins.Read(Int);
        Observer.ObserveError('readint');
        Cnt := Ins.ReadText(T, 3);
        Observer.Observe('readtext-len-count', Format(Cnt));
        Observer.Expect('hasvalue', 'No');
        Observer.Expect('length', '0');
        Observer.Expect('eos', 'Yes');
        Observer.Expect('pos', '1');
        Observer.Expect('readtext', 'no error');
        Observer.Expect('readint|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('readint|code', 'InvalidStreamData');
        Observer.Expect('readtext-len-count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure WriteReadTypes()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Ch: Char;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        Du: Duration;
        Co: Code[20];
        Tx: Text;
        Gu: Guid;
        By: Byte;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.Write(42);
        Out.Write(1234567890123L);
        Out.Write(3.14159);
        Out.Write(true);
        Out.Write('Z');
        Out.Write(DMY2Date(1, 2, 2020));
        Out.Write(123456T);
        Out.Write(CreateDateTime(DMY2Date(3, 4, 2021), 101112T));
        Out.Write(Format(1)); // text
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('length', Format(Rec.Data.Length()));
        Rec.Data.CreateInStream(Ins);
        Ins.Read(I);
        Observer.Observe('int', Format(I));
        Ins.Read(B);
        Observer.Observe('big', Format(B));
        Ins.Read(D);
        Observer.Observe('dec', Format(D));
        Ins.Read(Bo);
        Observer.Observe('bool', Format(Bo));
        Ins.Read(Ch);
        Observer.Observe('char', Format(Ch));
        asserterror Ins.Read(Dt);
        Observer.ObserveError('af310');
        Observer.Observe('date', Format(Dt, 0, 9));
        asserterror Ins.Read(Tm);
        Observer.ObserveError('af313');
        Observer.Observe('time', Format(Tm, 0, 9));
        asserterror Ins.Read(Dtm);
        Observer.ObserveError('af316');
        Observer.Observe('datetime', Format(Dtm, 0, 9));
        Observer.Observe('pos', Format(Ins.Position()));
        Observer.Expect('length', '48');
        Observer.Expect('int', '42');
        Observer.Expect('big', '1234567890123');
        Observer.Expect('dec', '3.14159');
        Observer.Expect('bool', 'Yes');
        Observer.Expect('char', 'Z');
        Observer.Expect('af310|text', 'The date is not valid.');
        Observer.Expect('af310|code', 'DateInvalid');
        Observer.Expect('date', '');
        Observer.Expect('af313|text', 'The time is not valid.');
        Observer.Expect('af313|code', 'InvalidTime');
        Observer.Expect('time', '');
        Observer.Expect('af316|text', 'The date is not valid.');
        Observer.Expect('af316|code', 'DateInvalid');
        Observer.Expect('datetime', '');
        Observer.Expect('pos', '46');
        Observer.Verify();
    end;

    [Test]
    procedure ReadWriteSizes()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.Write(1);
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('int-len', Format(Rec.Data.Length()));
        Rec.Data.CreateOutStream(Out);
        Out.Write(1L);
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('big-len', Format(Rec.Data.Length()));
        Rec.Data.CreateOutStream(Out);
        Out.Write(1.5);
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('dec-len', Format(Rec.Data.Length()));
        Rec.Data.CreateOutStream(Out);
        Out.Write(true);
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('bool-len', Format(Rec.Data.Length()));
        Rec.Data.CreateOutStream(Out);
        Out.Write('A');
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('char-len', Format(Rec.Data.Length()));
        Rec.Data.CreateOutStream(Out);
        Out.Write(0D);
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('date-len', Format(Rec.Data.Length()));
        Rec.Data.CreateOutStream(Out);
        Out.Write(0T);
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('time-len', Format(Rec.Data.Length()));
        Rec.Data.CreateOutStream(Out);
        Out.Write(0DT);
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('datetime-len', Format(Rec.Data.Length()));
        Observer.Expect('int-len', '4');
        Observer.Expect('big-len', '8');
        Observer.Expect('dec-len', '12');
        Observer.Expect('bool-len', '12');
        Observer.Expect('char-len', '12');
        Observer.Expect('date-len', '12');
        Observer.Expect('time-len', '12');
        Observer.Expect('datetime-len', '12');
        Observer.Verify();
    end;

    [Test]
    procedure ReadWriteTextBinary()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        Tx: Text;
        Co: Code[10];
        Tx2: Text;
        I: Integer;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.Write('abc');
        Out.Write('defg');
        Out.Write(7);
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('length', Format(Rec.Data.Length()));
        Rec.Data.CreateInStream(Ins);
        Ins.Read(Tx);
        Observer.Observe('t1', Tx);
        Ins.Read(Tx2);
        Observer.Observe('t2', Tx2);
        Ins.Read(I);
        Observer.Observe('i', Format(I));
        Observer.Observe('eos', Format(Ins.EOS()));
        Observer.Expect('length', '13');
        Observer.Expect('t1', 'abc');
        Observer.Expect('t2', 'defg');
        Observer.Expect('i', '7');
        Observer.Expect('eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadWriteCodeAndEmptyText()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        Co: Code[10];
        Tx: Text;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.Write('');
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('empty-len', Format(Rec.Data.Length()));
        Rec.Data.CreateOutStream(Out);
        Co := 'abc';
        Out.Write(Co);
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('code-len', Format(Rec.Data.Length()));
        Rec.Data.CreateInStream(Ins);
        Ins.Read(Tx);
        Observer.Observe('code-read', Tx);
        Observer.Expect('empty-len', '1');
        Observer.Expect('code-len', '4');
        Observer.Expect('code-read', 'ABC');
        Observer.Verify();
    end;

    [Test]
    procedure PositionAndReset()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        T: Text;
        I: Integer;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.Write(1);
        Out.Write(2);
        Out.WriteText('abc');
        Rec.Modify();
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('in-pos0', Format(Ins.Position()));
        Ins.Read(I);
        Observer.Observe('in-pos1', Format(Ins.Position()));
        Observer.Observe('i1', Format(I));
        Ins.ResetPosition();
        Observer.Observe('in-pos-reset', Format(Ins.Position()));
        Ins.Read(I);
        Observer.Observe('i-after-reset', Format(I));
        Ins.Read(I);
        Observer.Observe('i2', Format(I));
        Ins.ReadText(T);
        Observer.Observe('t', T);
        Observer.Observe('in-pos-end', Format(Ins.Position()));
        Observer.Expect('in-pos0', '1');
        Observer.Expect('in-pos1', '5');
        Observer.Expect('i1', '1');
        Observer.Expect('in-pos-reset', '1');
        Observer.Expect('i-after-reset', '1');
        Observer.Expect('i2', '2');
        Observer.Expect('t', 'abc');
        Observer.Expect('in-pos-end', '12');
        Observer.Verify();
    end;

    [Test]
    procedure CreateOutStreamTruncates()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        T: Text;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.WriteText('long long text');
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('len1', Format(Rec.Data.Length()));
        Rec.Data.CreateOutStream(Out);
        Out.WriteText('s');
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('len2', Format(Rec.Data.Length()));
        Rec.Data.CreateInStream(Ins);
        Ins.ReadText(T);
        Observer.Observe('text', T);
        Observer.Expect('len1', '14');
        Observer.Expect('len2', '14');
        Observer.Expect('text', 'song long text');
        Observer.Verify();
    end;

    [Test]
    procedure WriteWithoutModify()
    var
        Rec: Record "LT StT Rec";
        Rec2: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.WriteText('not stored');
        Rec2.Get(1);
        Rec2.CalcFields(Data);
        Observer.Observe('stored-len', Format(Rec2.Data.Length()));
        Observer.Observe('stored-has', Format(Rec2.Data.HasValue()));
        Rec.Modify();
        Rec2.Get(1);
        Rec2.CalcFields(Data);
        Observer.Observe('after-modify-len', Format(Rec2.Data.Length()));
        Observer.Expect('stored-len', '0');
        Observer.Expect('stored-has', 'No');
        Observer.Expect('after-modify-len', '10');
        Observer.Verify();
    end;

    [Test]
    procedure LengthNeedsCalcFields()
    var
        Rec: Record "LT StT Rec";
        Rec2: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.WriteText('abcd');
        Rec.Modify();
        Rec2.Get(1);
        Observer.Observe('before-calc-has', Format(Rec2.Data.HasValue()));
        Observer.Observe('before-calc-len', Format(Rec2.Data.Length()));
        Rec2.CalcFields(Data);
        Observer.Observe('after-calc-has', Format(Rec2.Data.HasValue()));
        Observer.Observe('after-calc-len', Format(Rec2.Data.Length()));
        Observer.Expect('before-calc-has', 'Yes');
        Observer.Expect('before-calc-len', '10');
        Observer.Expect('after-calc-has', 'Yes');
        Observer.Expect('after-calc-len', '4');
        Observer.Verify();
    end;

    [Test]
    procedure BlobClearAndEmpty()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.WriteText('abcd');
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('has1', Format(Rec.Data.HasValue()));
        Clear(Rec.Data);
        Observer.Observe('has-after-clear', Format(Rec.Data.HasValue()));
        Observer.Observe('len-after-clear', Format(Rec.Data.Length()));
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('has-after-modify', Format(Rec.Data.HasValue()));
        Rec.Data.CreateOutStream(Out);
        Out.WriteText('');
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('has-empty-write', Format(Rec.Data.HasValue()));
        Observer.Expect('has1', 'Yes');
        Observer.Expect('has-after-clear', 'No');
        Observer.Expect('len-after-clear', '0');
        Observer.Expect('has-after-modify', 'No');
        Observer.Expect('has-empty-write', 'No');
        Observer.Verify();
    end;
}
