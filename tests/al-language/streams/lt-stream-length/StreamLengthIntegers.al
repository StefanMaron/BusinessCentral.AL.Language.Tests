// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-write-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT OutIn Rec (71751), LT OutIn Helper (71752)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Pins OutStream.Write(Value, Length) and InStream.Read(var Value, Length) for Integer, BigInteger, Boolean, Byte: per case the Write return or error, the bytes in the blob, and a read of the same Length (return or error, value, EOS, position) followed by a second read at the end of the stream.
// BC versions: 29 (27 and 28 by CI)

codeunit 67860 "LT Q Stream Len Int"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure W_Integer(var O: OutStream; V: Integer; WL: Integer; var Ret: Integer)
    begin
        if WL < 0 then
            Ret := O.Write(V)
        else
            Ret := O.Write(V, WL);
    end;

    [TryFunction]
    local procedure R_Integer(var I: InStream; var V: Integer; RL: Integer; var Ret: Integer)
    begin
        if RL < 0 then
            Ret := I.Read(V)
        else
            Ret := I.Read(V, RL);
    end;

    local procedure Do_Integer(var Observer: Codeunit "Probe Observer"; Id: Text; V: Integer; WL: Integer; RL: Integer)
    var
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
        R: Integer;
        Ret: Integer;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        if W_Integer(Out, V, WL, Ret) then
            Observer.Observe(Id + '_wret', Format(Ret))
        else
            Observer.ObserveError(Id + '_w');
        Rec.Modify();
        Observer.Observe(Id + '_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        if R_Integer(Ins, R, RL, Ret) then
            Observer.Observe(Id + '_rd', Format(Ret) + '/' + Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()))
        else begin
            Observer.ObserveError(Id + '_r');
            Observer.Observe(Id + '_rval', Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()));
        end;
        if R_Integer(Ins, R, RL, Ret) then
            Observer.Observe(Id + '_rd2', Format(Ret) + '/' + Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()))
        else
            Observer.ObserveError(Id + '_r2');
    end;

    [TryFunction]
    local procedure W_BigInteger(var O: OutStream; V: BigInteger; WL: Integer; var Ret: Integer)
    begin
        if WL < 0 then
            Ret := O.Write(V)
        else
            Ret := O.Write(V, WL);
    end;

    [TryFunction]
    local procedure R_BigInteger(var I: InStream; var V: BigInteger; RL: Integer; var Ret: Integer)
    begin
        if RL < 0 then
            Ret := I.Read(V)
        else
            Ret := I.Read(V, RL);
    end;

    local procedure Do_BigInteger(var Observer: Codeunit "Probe Observer"; Id: Text; V: BigInteger; WL: Integer; RL: Integer)
    var
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
        R: BigInteger;
        Ret: Integer;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        if W_BigInteger(Out, V, WL, Ret) then
            Observer.Observe(Id + '_wret', Format(Ret))
        else
            Observer.ObserveError(Id + '_w');
        Rec.Modify();
        Observer.Observe(Id + '_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        if R_BigInteger(Ins, R, RL, Ret) then
            Observer.Observe(Id + '_rd', Format(Ret) + '/' + Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()))
        else begin
            Observer.ObserveError(Id + '_r');
            Observer.Observe(Id + '_rval', Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()));
        end;
        if R_BigInteger(Ins, R, RL, Ret) then
            Observer.Observe(Id + '_rd2', Format(Ret) + '/' + Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()))
        else
            Observer.ObserveError(Id + '_r2');
    end;

    [TryFunction]
    local procedure W_Boolean(var O: OutStream; V: Boolean; WL: Integer; var Ret: Integer)
    begin
        if WL < 0 then
            Ret := O.Write(V)
        else
            Ret := O.Write(V, WL);
    end;

    [TryFunction]
    local procedure R_Boolean(var I: InStream; var V: Boolean; RL: Integer; var Ret: Integer)
    begin
        if RL < 0 then
            Ret := I.Read(V)
        else
            Ret := I.Read(V, RL);
    end;

    local procedure Do_Boolean(var Observer: Codeunit "Probe Observer"; Id: Text; V: Boolean; WL: Integer; RL: Integer)
    var
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
        R: Boolean;
        Ret: Integer;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        if W_Boolean(Out, V, WL, Ret) then
            Observer.Observe(Id + '_wret', Format(Ret))
        else
            Observer.ObserveError(Id + '_w');
        Rec.Modify();
        Observer.Observe(Id + '_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        if R_Boolean(Ins, R, RL, Ret) then
            Observer.Observe(Id + '_rd', Format(Ret) + '/' + Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()))
        else begin
            Observer.ObserveError(Id + '_r');
            Observer.Observe(Id + '_rval', Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()));
        end;
        if R_Boolean(Ins, R, RL, Ret) then
            Observer.Observe(Id + '_rd2', Format(Ret) + '/' + Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()))
        else
            Observer.ObserveError(Id + '_r2');
    end;

    [TryFunction]
    local procedure W_Byte(var O: OutStream; V: Byte; WL: Integer; var Ret: Integer)
    begin
        if WL < 0 then
            Ret := O.Write(V)
        else
            Ret := O.Write(V, WL);
    end;

    [TryFunction]
    local procedure R_Byte(var I: InStream; var V: Byte; RL: Integer; var Ret: Integer)
    begin
        if RL < 0 then
            Ret := I.Read(V)
        else
            Ret := I.Read(V, RL);
    end;

    local procedure Do_Byte(var Observer: Codeunit "Probe Observer"; Id: Text; V: Byte; WL: Integer; RL: Integer)
    var
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
        R: Byte;
        Ret: Integer;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        if W_Byte(Out, V, WL, Ret) then
            Observer.Observe(Id + '_wret', Format(Ret))
        else
            Observer.ObserveError(Id + '_w');
        Rec.Modify();
        Observer.Observe(Id + '_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        if R_Byte(Ins, R, RL, Ret) then
            Observer.Observe(Id + '_rd', Format(Ret) + '/' + Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()))
        else begin
            Observer.ObserveError(Id + '_r');
            Observer.Observe(Id + '_rval', Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()));
        end;
        if R_Byte(Ins, R, RL, Ret) then
            Observer.Observe(Id + '_rd2', Format(Ret) + '/' + Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()))
        else
            Observer.ObserveError(Id + '_r2');
    end;

    [Test]
    procedure Integer_WriteReadLength_1()
    var
        Observer: Codeunit "Probe Observer";
        V: Integer;
    begin
        V := 258;
        Do_Integer(Observer, 'n258', V, -1, -1);
        V := 258;
        Do_Integer(Observer, 'w4', V, 4, 4);
        V := 258;
        Do_Integer(Observer, 'w2', V, 2, 2);
        Observer.Finish();
    end;

    [Test]
    procedure Integer_WriteReadLength_2()
    var
        Observer: Codeunit "Probe Observer";
        V: Integer;
    begin
        V := 258;
        Do_Integer(Observer, 'w1', V, 1, 1);
        V := 258;
        Do_Integer(Observer, 'w0', V, 0, 0);
        V := 258;
        Do_Integer(Observer, 'w8', V, 8, 8);
        Observer.Finish();
    end;

    [Test]
    procedure Integer_WriteReadLength_3()
    var
        Observer: Codeunit "Probe Observer";
        V: Integer;
    begin
        V := -1;
        Do_Integer(Observer, 'neg4', V, 4, 4);
        V := 258;
        Do_Integer(Observer, 'r2', V, -1, 2);
        V := 258;
        Do_Integer(Observer, 'r8', V, -1, 8);
        Observer.Finish();
    end;

    [Test]
    procedure Integer_WriteReadLength_4()
    var
        Observer: Codeunit "Probe Observer";
        V: Integer;
    begin
        V := 258;
        Do_Integer(Observer, 'r0', V, -1, 0);
        Observer.Finish();
    end;

    [Test]
    procedure BigInteger_WriteReadLength_1()
    var
        Observer: Codeunit "Probe Observer";
        V: BigInteger;
    begin
        V := 258;
        Do_BigInteger(Observer, 'n258', V, -1, -1);
        V := 258;
        Do_BigInteger(Observer, 'w8', V, 8, 8);
        V := 258;
        Do_BigInteger(Observer, 'w4', V, 4, 4);
        Observer.Finish();
    end;

    [Test]
    procedure BigInteger_WriteReadLength_2()
    var
        Observer: Codeunit "Probe Observer";
        V: BigInteger;
    begin
        V := 258;
        Do_BigInteger(Observer, 'w0', V, 0, 0);
        V := 258;
        Do_BigInteger(Observer, 'w9', V, 9, 9);
        V := 258;
        Do_BigInteger(Observer, 'r4', V, -1, 4);
        Observer.Finish();
    end;

    [Test]
    procedure BigInteger_WriteReadLength_3()
    var
        Observer: Codeunit "Probe Observer";
        V: BigInteger;
    begin
        V := 258;
        Do_BigInteger(Observer, 'r0', V, -1, 0);
        Observer.Finish();
    end;

    [Test]
    procedure Boolean_WriteReadLength_1()
    var
        Observer: Codeunit "Probe Observer";
        V: Boolean;
    begin
        V := true;
        Do_Boolean(Observer, 'ntrue', V, -1, -1);
        V := true;
        Do_Boolean(Observer, 'w4', V, 4, 4);
        V := true;
        Do_Boolean(Observer, 'w1', V, 1, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Boolean_WriteReadLength_2()
    var
        Observer: Codeunit "Probe Observer";
        V: Boolean;
    begin
        V := true;
        Do_Boolean(Observer, 'w2', V, 2, 2);
        V := true;
        Do_Boolean(Observer, 'w0', V, 0, 0);
        V := true;
        Do_Boolean(Observer, 'w8', V, 8, 8);
        Observer.Finish();
    end;

    [Test]
    procedure Boolean_WriteReadLength_3()
    var
        Observer: Codeunit "Probe Observer";
        V: Boolean;
    begin
        V := true;
        Do_Boolean(Observer, 'r1', V, -1, 1);
        V := true;
        Do_Boolean(Observer, 'r0', V, -1, 0);
        Observer.Finish();
    end;

    [Test]
    procedure Byte_WriteReadLength_1()
    var
        Observer: Codeunit "Probe Observer";
        V: Byte;
    begin
        V := 200;
        Do_Byte(Observer, 'n200', V, -1, -1);
        V := 200;
        Do_Byte(Observer, 'w1', V, 1, 1);
        V := 200;
        Do_Byte(Observer, 'w2', V, 2, 2);
        Observer.Finish();
    end;

    [Test]
    procedure Byte_WriteReadLength_2()
    var
        Observer: Codeunit "Probe Observer";
        V: Byte;
    begin
        V := 200;
        Do_Byte(Observer, 'w0', V, 0, 0);
        V := 200;
        Do_Byte(Observer, 'r2', V, -1, 2);
        V := 200;
        Do_Byte(Observer, 'r0', V, -1, 0);
        Observer.Finish();
    end;
}
