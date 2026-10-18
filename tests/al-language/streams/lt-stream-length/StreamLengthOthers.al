// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-write-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT OutIn Rec (71751), LT OutIn Helper (71752)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Pins OutStream.Write(Value, Length) and InStream.Read(var Value, Length) for Char, Decimal, Guid, Option: per case the Write return or error, the bytes in the blob, and a read of the same Length (return or error, value, EOS, position) followed by a second read at the end of the stream.
// BC versions: 29 (27 and 28 by CI)

codeunit 67861 "LT Q Stream Len Oth"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure W_Char(var O: OutStream; V: Char; WL: Integer; var Ret: Integer)
    begin
        if WL < 0 then
            Ret := O.Write(V)
        else
            Ret := O.Write(V, WL);
    end;

    [TryFunction]
    local procedure R_Char(var I: InStream; var V: Char; RL: Integer; var Ret: Integer)
    begin
        if RL < 0 then
            Ret := I.Read(V)
        else
            Ret := I.Read(V, RL);
    end;

    local procedure Do_Char(var Observer: Codeunit "Probe Observer"; Id: Text; V: Char; WL: Integer; RL: Integer)
    var
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
        R: Char;
        Ret: Integer;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        if W_Char(Out, V, WL, Ret) then
            Observer.Observe(Id + '_wret', Format(Ret))
        else
            Observer.ObserveError(Id + '_w');
        Rec.Modify();
        Observer.Observe(Id + '_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        if R_Char(Ins, R, RL, Ret) then
            Observer.Observe(Id + '_rd', Format(Ret) + '/' + Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()))
        else begin
            Observer.ObserveError(Id + '_r');
            Observer.Observe(Id + '_rval', Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()));
        end;
        if R_Char(Ins, R, RL, Ret) then
            Observer.Observe(Id + '_rd2', Format(Ret) + '/' + Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()))
        else
            Observer.ObserveError(Id + '_r2');
    end;

    [TryFunction]
    local procedure W_Decimal(var O: OutStream; V: Decimal; WL: Integer; var Ret: Integer)
    begin
        if WL < 0 then
            Ret := O.Write(V)
        else
            Ret := O.Write(V, WL);
    end;

    [TryFunction]
    local procedure R_Decimal(var I: InStream; var V: Decimal; RL: Integer; var Ret: Integer)
    begin
        if RL < 0 then
            Ret := I.Read(V)
        else
            Ret := I.Read(V, RL);
    end;

    local procedure Do_Decimal(var Observer: Codeunit "Probe Observer"; Id: Text; V: Decimal; WL: Integer; RL: Integer)
    var
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
        R: Decimal;
        Ret: Integer;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        if W_Decimal(Out, V, WL, Ret) then
            Observer.Observe(Id + '_wret', Format(Ret))
        else
            Observer.ObserveError(Id + '_w');
        Rec.Modify();
        Observer.Observe(Id + '_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        if R_Decimal(Ins, R, RL, Ret) then
            Observer.Observe(Id + '_rd', Format(Ret) + '/' + Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()))
        else begin
            Observer.ObserveError(Id + '_r');
            Observer.Observe(Id + '_rval', Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()));
        end;
        if R_Decimal(Ins, R, RL, Ret) then
            Observer.Observe(Id + '_rd2', Format(Ret) + '/' + Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()))
        else
            Observer.ObserveError(Id + '_r2');
    end;

    [TryFunction]
    local procedure W_Guid(var O: OutStream; V: Guid; WL: Integer; var Ret: Integer)
    begin
        if WL < 0 then
            Ret := O.Write(V)
        else
            Ret := O.Write(V, WL);
    end;

    [TryFunction]
    local procedure R_Guid(var I: InStream; var V: Guid; RL: Integer; var Ret: Integer)
    begin
        if RL < 0 then
            Ret := I.Read(V)
        else
            Ret := I.Read(V, RL);
    end;

    local procedure Do_Guid(var Observer: Codeunit "Probe Observer"; Id: Text; V: Guid; WL: Integer; RL: Integer)
    var
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
        R: Guid;
        Ret: Integer;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        if W_Guid(Out, V, WL, Ret) then
            Observer.Observe(Id + '_wret', Format(Ret))
        else
            Observer.ObserveError(Id + '_w');
        Rec.Modify();
        Observer.Observe(Id + '_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        if R_Guid(Ins, R, RL, Ret) then
            Observer.Observe(Id + '_rd', Format(Ret) + '/' + Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()))
        else begin
            Observer.ObserveError(Id + '_r');
            Observer.Observe(Id + '_rval', Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()));
        end;
        if R_Guid(Ins, R, RL, Ret) then
            Observer.Observe(Id + '_rd2', Format(Ret) + '/' + Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()))
        else
            Observer.ObserveError(Id + '_r2');
    end;

    [TryFunction]
    local procedure W_Option(var O: OutStream; V: Option A,B,C; WL: Integer; var Ret: Integer)
    begin
        if WL < 0 then
            Ret := O.Write(V)
        else
            Ret := O.Write(V, WL);
    end;

    [TryFunction]
    local procedure R_Option(var I: InStream; var V: Option A,B,C; RL: Integer; var Ret: Integer)
    begin
        if RL < 0 then
            Ret := I.Read(V)
        else
            Ret := I.Read(V, RL);
    end;

    local procedure Do_Option(var Observer: Codeunit "Probe Observer"; Id: Text; V: Option A,B,C; WL: Integer; RL: Integer)
    var
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
        R: Option A,B,C;
        Ret: Integer;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        if W_Option(Out, V, WL, Ret) then
            Observer.Observe(Id + '_wret', Format(Ret))
        else
            Observer.ObserveError(Id + '_w');
        Rec.Modify();
        Observer.Observe(Id + '_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        if R_Option(Ins, R, RL, Ret) then
            Observer.Observe(Id + '_rd', Format(Ret) + '/' + Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()))
        else begin
            Observer.ObserveError(Id + '_r');
            Observer.Observe(Id + '_rval', Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()));
        end;
        if R_Option(Ins, R, RL, Ret) then
            Observer.Observe(Id + '_rd2', Format(Ret) + '/' + Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()))
        else
            Observer.ObserveError(Id + '_r2');
    end;

    [Test]
    procedure Char_WriteReadLength_1()
    var
        Observer: Codeunit "Probe Observer";
        V: Char;
    begin
        V := 65;
        Do_Char(Observer, 'n65', V, -1, -1);
        V := 65;
        Do_Char(Observer, 'w1', V, 1, 1);
        V := 65;
        Do_Char(Observer, 'w2', V, 2, 2);
        Observer.Finish();
    end;

    [Test]
    procedure Char_WriteReadLength_2()
    var
        Observer: Codeunit "Probe Observer";
        V: Char;
    begin
        V := 65;
        Do_Char(Observer, 'w0', V, 0, 0);
        V := 65;
        Do_Char(Observer, 'r2', V, -1, 2);
        V := 65;
        Do_Char(Observer, 'r0', V, -1, 0);
        Observer.Finish();
    end;

    [Test]
    procedure Decimal_WriteReadLength_1()
    var
        Observer: Codeunit "Probe Observer";
        V: Decimal;
    begin
        V := -12.5;
        Do_Decimal(Observer, 'nneg', V, -1, -1);
        V := -12.5;
        Do_Decimal(Observer, 'w12', V, 12, 12);
        V := -12.5;
        Do_Decimal(Observer, 'w8', V, 8, 8);
        Observer.Finish();
    end;

    [Test]
    procedure Decimal_WriteReadLength_2()
    var
        Observer: Codeunit "Probe Observer";
        V: Decimal;
    begin
        V := -12.5;
        Do_Decimal(Observer, 'w16', V, 16, 16);
        V := -12.5;
        Do_Decimal(Observer, 'w0', V, 0, 0);
        V := -12.5;
        Do_Decimal(Observer, 'r8', V, -1, 8);
        Observer.Finish();
    end;

    [Test]
    procedure Decimal_WriteReadLength_3()
    var
        Observer: Codeunit "Probe Observer";
        V: Decimal;
    begin
        V := -12.5;
        Do_Decimal(Observer, 'r0', V, -1, 0);
        Observer.Finish();
    end;

    [Test]
    procedure Guid_WriteReadLength_1()
    var
        Observer: Codeunit "Probe Observer";
        V: Guid;
    begin
        Evaluate(V, '{12345678-1234-1234-1234-123456789ABC}');
        Do_Guid(Observer, 'nguid', V, -1, -1);
        Evaluate(V, '{12345678-1234-1234-1234-123456789ABC}');
        Do_Guid(Observer, 'w16', V, 16, 16);
        Evaluate(V, '{12345678-1234-1234-1234-123456789ABC}');
        Do_Guid(Observer, 'w8', V, 8, 8);
        Observer.Finish();
    end;

    [Test]
    procedure Guid_WriteReadLength_2()
    var
        Observer: Codeunit "Probe Observer";
        V: Guid;
    begin
        Evaluate(V, '{12345678-1234-1234-1234-123456789ABC}');
        Do_Guid(Observer, 'w0', V, 0, 0);
        Evaluate(V, '{12345678-1234-1234-1234-123456789ABC}');
        Do_Guid(Observer, 'r4', V, -1, 4);
        Evaluate(V, '{12345678-1234-1234-1234-123456789ABC}');
        Do_Guid(Observer, 'r0', V, -1, 0);
        Observer.Finish();
    end;

    [Test]
    procedure Option_WriteReadLength_1()
    var
        Observer: Codeunit "Probe Observer";
        V: Option A,B,C;
    begin
        V := V::B;
        Do_Option(Observer, 'nb', V, -1, -1);
        V := V::B;
        Do_Option(Observer, 'w4', V, 4, 4);
        V := V::B;
        Do_Option(Observer, 'w1', V, 1, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Option_WriteReadLength_2()
    var
        Observer: Codeunit "Probe Observer";
        V: Option A,B,C;
    begin
        V := V::B;
        Do_Option(Observer, 'w2', V, 2, 2);
        V := V::B;
        Do_Option(Observer, 'w0', V, 0, 0);
        V := V::B;
        Do_Option(Observer, 'r1', V, -1, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Option_WriteReadLength_3()
    var
        Observer: Codeunit "Probe Observer";
        V: Option A,B,C;
    begin
        V := V::B;
        Do_Option(Observer, 'r0', V, -1, 0);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure W_Record(var O: OutStream; var Rr: Record "LT OutIn Rec"; WL: Integer; var Ret: Integer)
    begin
        if WL < 0 then
            Ret := O.Write(Rr)
        else
            Ret := O.Write(Rr, WL);
    end;

    [TryFunction]
    local procedure W_RecordId(var O: OutStream; Id: RecordId; WL: Integer; var Ret: Integer)
    begin
        if WL < 0 then
            Ret := O.Write(Id)
        else
            Ret := O.Write(Id, WL);
    end;

    local procedure Do_RecordKinds(var Observer: Codeunit "Probe Observer"; WL: Integer)
    var
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ret: Integer;
        Id: Text;
    begin
        Id := 'l' + Format(WL);
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        if W_Record(Out, Rec, WL, Ret) then
            Observer.Observe(Id + '_rec', Format(Ret))
        else
            Observer.ObserveError(Id + '_rec');
        Rec.Modify();
        Observer.Observe(Id + '_rec_bytes', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        if W_RecordId(Out, Rec.RecordId(), WL, Ret) then
            Observer.Observe(Id + '_rid', Format(Ret))
        else
            Observer.ObserveError(Id + '_rid');
        Rec.Modify();
        Observer.Observe(Id + '_rid_bytes', Helper.Dump(Rec));
    end;

    [Test]
    procedure Record_RecordId_WriteLength()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Do_RecordKinds(Observer, -1);
        Do_RecordKinds(Observer, 0);
        Do_RecordKinds(Observer, 4);
        Do_RecordKinds(Observer, 16);
        Observer.Finish();
    end;
}
