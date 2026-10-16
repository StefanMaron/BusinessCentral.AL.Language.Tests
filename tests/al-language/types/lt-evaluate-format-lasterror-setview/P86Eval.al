// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained objects
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Evaluate into Integer, Date, Time, DateTime, Option and Enum from texts of every form, with and without format number: return value, value and error text
// BC versions: 29 (27 and 28 by CI)

enum 73521 "LT P86 Color"
{
    Extensible = true;

    value(0; Red) { }
    value(1; Green) { Caption = 'Green Caption'; }
    value(5; Blue) { }
    value(10; "Dark Blue") { }
}

codeunit 73522 "LT P86 Eval Integer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryInt(Txt: Text; Fmt: Integer; var V: Integer)
    begin
        if Fmt < 0 then
            Evaluate(V, Txt)
        else
            Evaluate(V, Txt, Fmt);
    end;

    local procedure RInt(Txt: Text; Fmt: Integer): Text
    var
        V: Integer;
        Ok: Boolean;
    begin
        V := 777;
        if Fmt < 0 then
            Ok := Evaluate(V, Txt)
        else
            Ok := Evaluate(V, Txt, Fmt);
        exit(Format(Ok) + '|' + Format(V));
    end;

    local procedure EInt(Txt: Text; Fmt: Integer): Text
    var
        V: Integer;
    begin
        V := 777;
        if TryInt(Txt, Fmt, V) then
            exit('ok|' + Format(V));
        exit('err:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Format(V));
    end;

    [Test]
    procedure Dflt1_Return_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RInt('0', -1));
        Observer.Observe('t2', RInt('1', -1));
        Observer.Observe('t3', RInt('-1', -1));
        Observer.Observe('t4', RInt('+1', -1));
        Observer.Observe('t5', RInt('007', -1));
        Observer.Observe('t6', RInt('-0', -1));
        Observer.Observe('t7', RInt('  12', -1));
        Observer.Observe('t8', RInt('12  ', -1));
        Observer.Observe('t9', RInt('  12  ', -1));
        Observer.Observe('t10', RInt('1,234', -1));
        Observer.Observe('t11', RInt('1 234', -1));
        Observer.Observe('t12', RInt('1.5', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Dflt1_Error_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EInt('0', -1));
        Observer.Observe('t2', EInt('1', -1));
        Observer.Observe('t3', EInt('-1', -1));
        Observer.Observe('t4', EInt('+1', -1));
        Observer.Observe('t5', EInt('007', -1));
        Observer.Observe('t6', EInt('-0', -1));
        Observer.Observe('t7', EInt('  12', -1));
        Observer.Observe('t8', EInt('12  ', -1));
        Observer.Observe('t9', EInt('  12  ', -1));
        Observer.Observe('t10', EInt('1,234', -1));
        Observer.Observe('t11', EInt('1 234', -1));
        Observer.Observe('t12', EInt('1.5', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Dflt2_Return_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RInt('1e3', -1));
        Observer.Observe('t2', RInt('abc', -1));
        Observer.Observe('t3', RInt('', -1));
        Observer.Observe('t4', RInt('   ', -1));
        Observer.Observe('t5', RInt('2147483647', -1));
        Observer.Observe('t6', RInt('2147483648', -1));
        Observer.Observe('t7', RInt('-2147483648', -1));
        Observer.Observe('t8', RInt('-2147483649', -1));
        Observer.Observe('t9', RInt('1-', -1));
        Observer.Observe('t10', RInt('--1', -1));
        Observer.Observe('t11', RInt('+-1', -1));
        Observer.Observe('t12', RInt('12abc', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Dflt2_Error_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EInt('1e3', -1));
        Observer.Observe('t2', EInt('abc', -1));
        Observer.Observe('t3', EInt('', -1));
        Observer.Observe('t4', EInt('   ', -1));
        Observer.Observe('t5', EInt('2147483647', -1));
        Observer.Observe('t6', EInt('2147483648', -1));
        Observer.Observe('t7', EInt('-2147483648', -1));
        Observer.Observe('t8', EInt('-2147483649', -1));
        Observer.Observe('t9', EInt('1-', -1));
        Observer.Observe('t10', EInt('--1', -1));
        Observer.Observe('t11', EInt('+-1', -1));
        Observer.Observe('t12', EInt('12abc', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Dflt3_Return_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RInt('0x1F', -1));
        Observer.Observe('t2', RInt('١٢', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Dflt3_Error_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EInt('0x1F', -1));
        Observer.Observe('t2', EInt('١٢', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt01_Return_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RInt('0', 0));
        Observer.Observe('t2', RInt('1', 0));
        Observer.Observe('t3', RInt('-1', 0));
        Observer.Observe('t4', RInt('+1', 0));
        Observer.Observe('t5', RInt('007', 0));
        Observer.Observe('t6', RInt('-0', 0));
        Observer.Observe('t7', RInt('  12', 0));
        Observer.Observe('t8', RInt('12  ', 0));
        Observer.Observe('t9', RInt('  12  ', 0));
        Observer.Observe('t10', RInt('1,234', 0));
        Observer.Observe('t11', RInt('1 234', 0));
        Observer.Observe('t12', RInt('1.5', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt01_Error_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EInt('0', 0));
        Observer.Observe('t2', EInt('1', 0));
        Observer.Observe('t3', EInt('-1', 0));
        Observer.Observe('t4', EInt('+1', 0));
        Observer.Observe('t5', EInt('007', 0));
        Observer.Observe('t6', EInt('-0', 0));
        Observer.Observe('t7', EInt('  12', 0));
        Observer.Observe('t8', EInt('12  ', 0));
        Observer.Observe('t9', EInt('  12  ', 0));
        Observer.Observe('t10', EInt('1,234', 0));
        Observer.Observe('t11', EInt('1 234', 0));
        Observer.Observe('t12', EInt('1.5', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt02_Return_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RInt('1e3', 0));
        Observer.Observe('t2', RInt('abc', 0));
        Observer.Observe('t3', RInt('', 0));
        Observer.Observe('t4', RInt('   ', 0));
        Observer.Observe('t5', RInt('2147483647', 0));
        Observer.Observe('t6', RInt('2147483648', 0));
        Observer.Observe('t7', RInt('-2147483648', 0));
        Observer.Observe('t8', RInt('-2147483649', 0));
        Observer.Observe('t9', RInt('1-', 0));
        Observer.Observe('t10', RInt('--1', 0));
        Observer.Observe('t11', RInt('+-1', 0));
        Observer.Observe('t12', RInt('12abc', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt02_Error_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EInt('1e3', 0));
        Observer.Observe('t2', EInt('abc', 0));
        Observer.Observe('t3', EInt('', 0));
        Observer.Observe('t4', EInt('   ', 0));
        Observer.Observe('t5', EInt('2147483647', 0));
        Observer.Observe('t6', EInt('2147483648', 0));
        Observer.Observe('t7', EInt('-2147483648', 0));
        Observer.Observe('t8', EInt('-2147483649', 0));
        Observer.Observe('t9', EInt('1-', 0));
        Observer.Observe('t10', EInt('--1', 0));
        Observer.Observe('t11', EInt('+-1', 0));
        Observer.Observe('t12', EInt('12abc', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt03_Return_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RInt('0x1F', 0));
        Observer.Observe('t2', RInt('١٢', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt03_Error_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EInt('0x1F', 0));
        Observer.Observe('t2', EInt('١٢', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt91_Return_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RInt('0', 9));
        Observer.Observe('t2', RInt('1', 9));
        Observer.Observe('t3', RInt('-1', 9));
        Observer.Observe('t4', RInt('+1', 9));
        Observer.Observe('t5', RInt('007', 9));
        Observer.Observe('t6', RInt('-0', 9));
        Observer.Observe('t7', RInt('  12', 9));
        Observer.Observe('t8', RInt('12  ', 9));
        Observer.Observe('t9', RInt('  12  ', 9));
        Observer.Observe('t10', RInt('1,234', 9));
        Observer.Observe('t11', RInt('1 234', 9));
        Observer.Observe('t12', RInt('1.5', 9));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt91_Error_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EInt('0', 9));
        Observer.Observe('t2', EInt('1', 9));
        Observer.Observe('t3', EInt('-1', 9));
        Observer.Observe('t4', EInt('+1', 9));
        Observer.Observe('t5', EInt('007', 9));
        Observer.Observe('t6', EInt('-0', 9));
        Observer.Observe('t7', EInt('  12', 9));
        Observer.Observe('t8', EInt('12  ', 9));
        Observer.Observe('t9', EInt('  12  ', 9));
        Observer.Observe('t10', EInt('1,234', 9));
        Observer.Observe('t11', EInt('1 234', 9));
        Observer.Observe('t12', EInt('1.5', 9));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt92_Return_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RInt('1e3', 9));
        Observer.Observe('t2', RInt('abc', 9));
        Observer.Observe('t3', RInt('', 9));
        Observer.Observe('t4', RInt('   ', 9));
        Observer.Observe('t5', RInt('2147483647', 9));
        Observer.Observe('t6', RInt('2147483648', 9));
        Observer.Observe('t7', RInt('-2147483648', 9));
        Observer.Observe('t8', RInt('-2147483649', 9));
        Observer.Observe('t9', RInt('1-', 9));
        Observer.Observe('t10', RInt('--1', 9));
        Observer.Observe('t11', RInt('+-1', 9));
        Observer.Observe('t12', RInt('12abc', 9));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt92_Error_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EInt('1e3', 9));
        Observer.Observe('t2', EInt('abc', 9));
        Observer.Observe('t3', EInt('', 9));
        Observer.Observe('t4', EInt('   ', 9));
        Observer.Observe('t5', EInt('2147483647', 9));
        Observer.Observe('t6', EInt('2147483648', 9));
        Observer.Observe('t7', EInt('-2147483648', 9));
        Observer.Observe('t8', EInt('-2147483649', 9));
        Observer.Observe('t9', EInt('1-', 9));
        Observer.Observe('t10', EInt('--1', 9));
        Observer.Observe('t11', EInt('+-1', 9));
        Observer.Observe('t12', EInt('12abc', 9));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt93_Return_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RInt('0x1F', 9));
        Observer.Observe('t2', RInt('١٢', 9));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt93_Error_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EInt('0x1F', 9));
        Observer.Observe('t2', EInt('١٢', 9));
        Observer.Finish();
    end;

}

codeunit 73523 "LT P86 Eval Date"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryDate(Txt: Text; Fmt: Integer; var V: Date)
    begin
        if Fmt < 0 then
            Evaluate(V, Txt)
        else
            Evaluate(V, Txt, Fmt);
    end;

    local procedure RDate(Txt: Text; Fmt: Integer): Text
    var
        V: Date;
        Ok: Boolean;
    begin
        V := 0D;
        if Fmt < 0 then
            Ok := Evaluate(V, Txt)
        else
            Ok := Evaluate(V, Txt, Fmt);
        exit(Format(Ok) + '|' + Format(V, 0, 9) + '|' + Format(V = Today()));
    end;

    local procedure EDate(Txt: Text; Fmt: Integer): Text
    var
        V: Date;
    begin
        V := 0D;
        if TryDate(Txt, Fmt, V) then
            exit('ok|' + Format(V, 0, 9) + '|' + Format(V = Today()));
        exit('err:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Format(V, 0, 9) + '|' + Format(V = Today()));
    end;

    [Test]
    procedure Dflt1_Return_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RDate('2024-01-15', -1));
        Observer.Observe('t2', RDate('15.01.2024', -1));
        Observer.Observe('t3', RDate('01/15/2024', -1));
        Observer.Observe('t4', RDate('1/15/24', -1));
        Observer.Observe('t5', RDate('150124', -1));
        Observer.Observe('t6', RDate('15012024', -1));
        Observer.Observe('t7', RDate('20240115', -1));
        Observer.Observe('t8', RDate('2024-01-15T00:00:00Z', -1));
        Observer.Observe('t9', RDate('0D', -1));
        Observer.Observe('t10', RDate('0d', -1));
        Observer.Observe('t11', RDate('T', -1));
        Observer.Observe('t12', RDate('t', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Dflt2_Return_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RDate('  2024-01-15  ', -1));
        Observer.Observe('t2', RDate('2024-02-30', -1));
        Observer.Observe('t3', RDate('2024-13-01', -1));
        Observer.Observe('t4', RDate('', -1));
        Observer.Observe('t5', RDate('abc', -1));
        Observer.Observe('t6', RDate('12/31/9999', -1));
        Observer.Observe('t7', RDate('01/01/0001', -1));
        Observer.Observe('t8', RDate('01/01/1753', -1));
        Observer.Observe('t9', RDate('12/31/1752', -1));
        Observer.Observe('t10', RDate('W', -1));
        Observer.Observe('t11', RDate('2024/01/15', -1));
        Observer.Observe('t12', RDate('Jan 15 2024', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Dflt2_Error_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EDate('  2024-01-15  ', -1));
        Observer.Observe('t2', EDate('2024-02-30', -1));
        Observer.Observe('t3', EDate('2024-13-01', -1));
        Observer.Observe('t4', EDate('', -1));
        Observer.Observe('t5', EDate('abc', -1));
        Observer.Observe('t6', EDate('12/31/9999', -1));
        Observer.Observe('t7', EDate('01/01/0001', -1));
        Observer.Observe('t8', EDate('01/01/1753', -1));
        Observer.Observe('t9', EDate('12/31/1752', -1));
        Observer.Observe('t10', EDate('W', -1));
        Observer.Observe('t11', EDate('2024/01/15', -1));
        Observer.Observe('t12', EDate('Jan 15 2024', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Dflt3_Return_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RDate('15-01-2024', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Dflt3_Error_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EDate('15-01-2024', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt01_Return_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RDate('2024-01-15', 0));
        Observer.Observe('t2', RDate('15.01.2024', 0));
        Observer.Observe('t3', RDate('01/15/2024', 0));
        Observer.Observe('t4', RDate('1/15/24', 0));
        Observer.Observe('t5', RDate('150124', 0));
        Observer.Observe('t6', RDate('15012024', 0));
        Observer.Observe('t7', RDate('20240115', 0));
        Observer.Observe('t8', RDate('2024-01-15T00:00:00Z', 0));
        Observer.Observe('t9', RDate('0D', 0));
        Observer.Observe('t10', RDate('0d', 0));
        Observer.Observe('t11', RDate('T', 0));
        Observer.Observe('t12', RDate('t', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt02_Return_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RDate('  2024-01-15  ', 0));
        Observer.Observe('t2', RDate('2024-02-30', 0));
        Observer.Observe('t3', RDate('2024-13-01', 0));
        Observer.Observe('t4', RDate('', 0));
        Observer.Observe('t5', RDate('abc', 0));
        Observer.Observe('t6', RDate('12/31/9999', 0));
        Observer.Observe('t7', RDate('01/01/0001', 0));
        Observer.Observe('t8', RDate('01/01/1753', 0));
        Observer.Observe('t9', RDate('12/31/1752', 0));
        Observer.Observe('t10', RDate('W', 0));
        Observer.Observe('t11', RDate('2024/01/15', 0));
        Observer.Observe('t12', RDate('Jan 15 2024', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt02_Error_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EDate('  2024-01-15  ', 0));
        Observer.Observe('t2', EDate('2024-02-30', 0));
        Observer.Observe('t3', EDate('2024-13-01', 0));
        Observer.Observe('t4', EDate('', 0));
        Observer.Observe('t5', EDate('abc', 0));
        Observer.Observe('t6', EDate('12/31/9999', 0));
        Observer.Observe('t7', EDate('01/01/0001', 0));
        Observer.Observe('t8', EDate('01/01/1753', 0));
        Observer.Observe('t9', EDate('12/31/1752', 0));
        Observer.Observe('t10', EDate('W', 0));
        Observer.Observe('t11', EDate('2024/01/15', 0));
        Observer.Observe('t12', EDate('Jan 15 2024', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt03_Return_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RDate('15-01-2024', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt03_Error_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EDate('15-01-2024', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt91_Return_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RDate('2024-01-15', 9));
        Observer.Observe('t2', RDate('15.01.2024', 9));
        Observer.Observe('t3', RDate('01/15/2024', 9));
        Observer.Observe('t4', RDate('1/15/24', 9));
        Observer.Observe('t5', RDate('150124', 9));
        Observer.Observe('t6', RDate('15012024', 9));
        Observer.Observe('t7', RDate('20240115', 9));
        Observer.Observe('t8', RDate('2024-01-15T00:00:00Z', 9));
        Observer.Observe('t9', RDate('0D', 9));
        Observer.Observe('t10', RDate('0d', 9));
        Observer.Observe('t11', RDate('T', 9));
        Observer.Observe('t12', RDate('t', 9));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt92_Return_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RDate('  2024-01-15  ', 9));
        Observer.Observe('t2', RDate('2024-02-30', 9));
        Observer.Observe('t3', RDate('2024-13-01', 9));
        Observer.Observe('t4', RDate('', 9));
        Observer.Observe('t5', RDate('abc', 9));
        Observer.Observe('t6', RDate('12/31/9999', 9));
        Observer.Observe('t7', RDate('01/01/0001', 9));
        Observer.Observe('t8', RDate('01/01/1753', 9));
        Observer.Observe('t9', RDate('12/31/1752', 9));
        Observer.Observe('t10', RDate('W', 9));
        Observer.Observe('t11', RDate('2024/01/15', 9));
        Observer.Observe('t12', RDate('Jan 15 2024', 9));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt93_Return_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RDate('15-01-2024', 9));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt93_Error_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EDate('15-01-2024', 9));
        Observer.Finish();
    end;

}

codeunit 73524 "LT P86 Eval Time"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryTime(Txt: Text; Fmt: Integer; var V: Time)
    begin
        if Fmt < 0 then
            Evaluate(V, Txt)
        else
            Evaluate(V, Txt, Fmt);
    end;

    local procedure RTime(Txt: Text; Fmt: Integer): Text
    var
        V: Time;
        Ok: Boolean;
    begin
        V := 0T;
        if Fmt < 0 then
            Ok := Evaluate(V, Txt)
        else
            Ok := Evaluate(V, Txt, Fmt);
        exit(Format(Ok) + '|' + Format(V, 0, 9));
    end;

    local procedure ETime(Txt: Text; Fmt: Integer): Text
    var
        V: Time;
    begin
        V := 0T;
        if TryTime(Txt, Fmt, V) then
            exit('ok|' + Format(V, 0, 9));
        exit('err:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Format(V, 0, 9));
    end;

    [Test]
    procedure Dflt1_Return_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RTime('12:00:00', -1));
        Observer.Observe('t2', RTime('12:00:00.000', -1));
        Observer.Observe('t3', RTime('12:00:00.123', -1));
        Observer.Observe('t4', RTime('12:00', -1));
        Observer.Observe('t5', RTime('1200', -1));
        Observer.Observe('t6', RTime('12:00 PM', -1));
        Observer.Observe('t7', RTime('12:00:00 AM', -1));
        Observer.Observe('t8', RTime('11:59:59 PM', -1));
        Observer.Observe('t9', RTime('25:00:00', -1));
        Observer.Observe('t10', RTime('24:00:00', -1));
        Observer.Observe('t11', RTime('0T', -1));
        Observer.Observe('t12', RTime('0t', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Dflt1_Error_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', ETime('12:00:00', -1));
        Observer.Observe('t2', ETime('12:00:00.000', -1));
        Observer.Observe('t3', ETime('12:00:00.123', -1));
        Observer.Observe('t4', ETime('12:00', -1));
        Observer.Observe('t5', ETime('1200', -1));
        Observer.Observe('t6', ETime('12:00 PM', -1));
        Observer.Observe('t7', ETime('12:00:00 AM', -1));
        Observer.Observe('t8', ETime('11:59:59 PM', -1));
        Observer.Observe('t9', ETime('25:00:00', -1));
        Observer.Observe('t10', ETime('24:00:00', -1));
        Observer.Observe('t11', ETime('0T', -1));
        Observer.Observe('t12', ETime('0t', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Dflt2_Return_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RTime('  12:00:00  ', -1));
        Observer.Observe('t2', RTime('12:00:60', -1));
        Observer.Observe('t3', RTime('12:00:00.5', -1));
        Observer.Observe('t4', RTime('12.00.00', -1));
        Observer.Observe('t5', RTime('', -1));
        Observer.Observe('t6', RTime('abc', -1));
        Observer.Observe('t7', RTime('-1:00:00', -1));
        Observer.Observe('t8', RTime('1:2:3', -1));
        Observer.Observe('t9', RTime('00:00:00', -1));
        Observer.Observe('t10', RTime('23:59:59.999', -1));
        Observer.Observe('t11', RTime('12:00:00Z', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Dflt2_Error_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', ETime('  12:00:00  ', -1));
        Observer.Observe('t2', ETime('12:00:60', -1));
        Observer.Observe('t3', ETime('12:00:00.5', -1));
        Observer.Observe('t4', ETime('12.00.00', -1));
        Observer.Observe('t5', ETime('', -1));
        Observer.Observe('t6', ETime('abc', -1));
        Observer.Observe('t7', ETime('-1:00:00', -1));
        Observer.Observe('t8', ETime('1:2:3', -1));
        Observer.Observe('t9', ETime('00:00:00', -1));
        Observer.Observe('t10', ETime('23:59:59.999', -1));
        Observer.Observe('t11', ETime('12:00:00Z', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt01_Return_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RTime('12:00:00', 0));
        Observer.Observe('t2', RTime('12:00:00.000', 0));
        Observer.Observe('t3', RTime('12:00:00.123', 0));
        Observer.Observe('t4', RTime('12:00', 0));
        Observer.Observe('t5', RTime('1200', 0));
        Observer.Observe('t6', RTime('12:00 PM', 0));
        Observer.Observe('t7', RTime('12:00:00 AM', 0));
        Observer.Observe('t8', RTime('11:59:59 PM', 0));
        Observer.Observe('t9', RTime('25:00:00', 0));
        Observer.Observe('t10', RTime('24:00:00', 0));
        Observer.Observe('t11', RTime('0T', 0));
        Observer.Observe('t12', RTime('0t', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt01_Error_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', ETime('12:00:00', 0));
        Observer.Observe('t2', ETime('12:00:00.000', 0));
        Observer.Observe('t3', ETime('12:00:00.123', 0));
        Observer.Observe('t4', ETime('12:00', 0));
        Observer.Observe('t5', ETime('1200', 0));
        Observer.Observe('t6', ETime('12:00 PM', 0));
        Observer.Observe('t7', ETime('12:00:00 AM', 0));
        Observer.Observe('t8', ETime('11:59:59 PM', 0));
        Observer.Observe('t9', ETime('25:00:00', 0));
        Observer.Observe('t10', ETime('24:00:00', 0));
        Observer.Observe('t11', ETime('0T', 0));
        Observer.Observe('t12', ETime('0t', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt02_Return_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RTime('  12:00:00  ', 0));
        Observer.Observe('t2', RTime('12:00:60', 0));
        Observer.Observe('t3', RTime('12:00:00.5', 0));
        Observer.Observe('t4', RTime('12.00.00', 0));
        Observer.Observe('t5', RTime('', 0));
        Observer.Observe('t6', RTime('abc', 0));
        Observer.Observe('t7', RTime('-1:00:00', 0));
        Observer.Observe('t8', RTime('1:2:3', 0));
        Observer.Observe('t9', RTime('00:00:00', 0));
        Observer.Observe('t10', RTime('23:59:59.999', 0));
        Observer.Observe('t11', RTime('12:00:00Z', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt02_Error_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', ETime('  12:00:00  ', 0));
        Observer.Observe('t2', ETime('12:00:60', 0));
        Observer.Observe('t3', ETime('12:00:00.5', 0));
        Observer.Observe('t4', ETime('12.00.00', 0));
        Observer.Observe('t5', ETime('', 0));
        Observer.Observe('t6', ETime('abc', 0));
        Observer.Observe('t7', ETime('-1:00:00', 0));
        Observer.Observe('t8', ETime('1:2:3', 0));
        Observer.Observe('t9', ETime('00:00:00', 0));
        Observer.Observe('t10', ETime('23:59:59.999', 0));
        Observer.Observe('t11', ETime('12:00:00Z', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt91_Return_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RTime('12:00:00', 9));
        Observer.Observe('t2', RTime('12:00:00.000', 9));
        Observer.Observe('t3', RTime('12:00:00.123', 9));
        Observer.Observe('t4', RTime('12:00', 9));
        Observer.Observe('t5', RTime('1200', 9));
        Observer.Observe('t6', RTime('12:00 PM', 9));
        Observer.Observe('t7', RTime('12:00:00 AM', 9));
        Observer.Observe('t8', RTime('11:59:59 PM', 9));
        Observer.Observe('t9', RTime('25:00:00', 9));
        Observer.Observe('t10', RTime('24:00:00', 9));
        Observer.Observe('t11', RTime('0T', 9));
        Observer.Observe('t12', RTime('0t', 9));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt91_Error_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', ETime('12:00:00', 9));
        Observer.Observe('t2', ETime('12:00:00.000', 9));
        Observer.Observe('t3', ETime('12:00:00.123', 9));
        Observer.Observe('t4', ETime('12:00', 9));
        Observer.Observe('t5', ETime('1200', 9));
        Observer.Observe('t6', ETime('12:00 PM', 9));
        Observer.Observe('t7', ETime('12:00:00 AM', 9));
        Observer.Observe('t8', ETime('11:59:59 PM', 9));
        Observer.Observe('t9', ETime('25:00:00', 9));
        Observer.Observe('t10', ETime('24:00:00', 9));
        Observer.Observe('t11', ETime('0T', 9));
        Observer.Observe('t12', ETime('0t', 9));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt92_Return_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RTime('  12:00:00  ', 9));
        Observer.Observe('t2', RTime('12:00:60', 9));
        Observer.Observe('t3', RTime('12:00:00.5', 9));
        Observer.Observe('t4', RTime('12.00.00', 9));
        Observer.Observe('t5', RTime('', 9));
        Observer.Observe('t6', RTime('abc', 9));
        Observer.Observe('t7', RTime('-1:00:00', 9));
        Observer.Observe('t8', RTime('1:2:3', 9));
        Observer.Observe('t9', RTime('00:00:00', 9));
        Observer.Observe('t10', RTime('23:59:59.999', 9));
        Observer.Observe('t11', RTime('12:00:00Z', 9));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt92_Error_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', ETime('  12:00:00  ', 9));
        Observer.Observe('t2', ETime('12:00:60', 9));
        Observer.Observe('t3', ETime('12:00:00.5', 9));
        Observer.Observe('t4', ETime('12.00.00', 9));
        Observer.Observe('t5', ETime('', 9));
        Observer.Observe('t6', ETime('abc', 9));
        Observer.Observe('t7', ETime('-1:00:00', 9));
        Observer.Observe('t8', ETime('1:2:3', 9));
        Observer.Observe('t9', ETime('00:00:00', 9));
        Observer.Observe('t10', ETime('23:59:59.999', 9));
        Observer.Observe('t11', ETime('12:00:00Z', 9));
        Observer.Finish();
    end;

}

codeunit 73525 "LT P86 Eval DateTime"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryDT(Txt: Text; Fmt: Integer; var V: DateTime)
    begin
        if Fmt < 0 then
            Evaluate(V, Txt)
        else
            Evaluate(V, Txt, Fmt);
    end;

    local procedure RDT(Txt: Text; Fmt: Integer): Text
    var
        V: DateTime;
        Ok: Boolean;
    begin
        V := 0DT;
        if Fmt < 0 then
            Ok := Evaluate(V, Txt)
        else
            Ok := Evaluate(V, Txt, Fmt);
        exit(Format(Ok) + '|' + Format(V, 0, 9));
    end;

    local procedure EDT(Txt: Text; Fmt: Integer): Text
    var
        V: DateTime;
    begin
        V := 0DT;
        if TryDT(Txt, Fmt, V) then
            exit('ok|' + Format(V, 0, 9));
        exit('err:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Format(V, 0, 9));
    end;

    [Test]
    procedure Dflt1_Return_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RDT('2024-01-15T10:20:30Z', -1));
        Observer.Observe('t2', RDT('2024-01-15T10:20:30', -1));
        Observer.Observe('t3', RDT('2024-01-15T10:20:30.123Z', -1));
        Observer.Observe('t4', RDT('2024-01-15 10:20:30', -1));
        Observer.Observe('t5', RDT('2024-01-15', -1));
        Observer.Observe('t6', RDT('10:20', -1));
        Observer.Observe('t7', RDT('01/15/2024 10:20:30', -1));
        Observer.Observe('t8', RDT('15.01.2024 10:20', -1));
        Observer.Observe('t9', RDT('0DT', -1));
        Observer.Observe('t10', RDT('0dt', -1));
        Observer.Observe('t11', RDT('  2024-01-15T10:20:30Z  ', -1));
        Observer.Observe('t12', RDT('2024-01-15T10:20:30+02:00', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Dflt1_Error_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EDT('2024-01-15T10:20:30Z', -1));
        Observer.Observe('t2', EDT('2024-01-15T10:20:30', -1));
        Observer.Observe('t3', EDT('2024-01-15T10:20:30.123Z', -1));
        Observer.Observe('t4', EDT('2024-01-15 10:20:30', -1));
        Observer.Observe('t5', EDT('2024-01-15', -1));
        Observer.Observe('t6', EDT('10:20', -1));
        Observer.Observe('t7', EDT('01/15/2024 10:20:30', -1));
        Observer.Observe('t8', EDT('15.01.2024 10:20', -1));
        Observer.Observe('t9', EDT('0DT', -1));
        Observer.Observe('t10', EDT('0dt', -1));
        Observer.Observe('t11', EDT('  2024-01-15T10:20:30Z  ', -1));
        Observer.Observe('t12', EDT('2024-01-15T10:20:30+02:00', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Dflt2_Return_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RDT('2024-01-15T25:00:00Z', -1));
        Observer.Observe('t2', RDT('', -1));
        Observer.Observe('t3', RDT('abc', -1));
        Observer.Observe('t4', RDT('0D', -1));
        Observer.Observe('t5', RDT('0T', -1));
        Observer.Observe('t6', RDT('2024-01-15T24:00:00Z', -1));
        Observer.Observe('t7', RDT('1/15/24 1:20 AM', -1));
        Observer.Observe('t8', RDT('01/15/2024 10:20 PM', -1));
        Observer.Observe('t9', RDT('2024-02-30T10:00:00Z', -1));
        Observer.Observe('t10', RDT('12/31/9999 23:59:59', -1));
        Observer.Observe('t11', RDT('2024-01-15T10:20:30.1234567Z', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Dflt2_Error_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EDT('2024-01-15T25:00:00Z', -1));
        Observer.Observe('t2', EDT('', -1));
        Observer.Observe('t3', EDT('abc', -1));
        Observer.Observe('t4', EDT('0D', -1));
        Observer.Observe('t5', EDT('0T', -1));
        Observer.Observe('t6', EDT('2024-01-15T24:00:00Z', -1));
        Observer.Observe('t7', EDT('1/15/24 1:20 AM', -1));
        Observer.Observe('t8', EDT('01/15/2024 10:20 PM', -1));
        Observer.Observe('t9', EDT('2024-02-30T10:00:00Z', -1));
        Observer.Observe('t10', EDT('12/31/9999 23:59:59', -1));
        Observer.Observe('t11', EDT('2024-01-15T10:20:30.1234567Z', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt01_Return_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RDT('2024-01-15T10:20:30Z', 0));
        Observer.Observe('t2', RDT('2024-01-15T10:20:30', 0));
        Observer.Observe('t3', RDT('2024-01-15T10:20:30.123Z', 0));
        Observer.Observe('t4', RDT('2024-01-15 10:20:30', 0));
        Observer.Observe('t5', RDT('2024-01-15', 0));
        Observer.Observe('t6', RDT('10:20', 0));
        Observer.Observe('t7', RDT('01/15/2024 10:20:30', 0));
        Observer.Observe('t8', RDT('15.01.2024 10:20', 0));
        Observer.Observe('t9', RDT('0DT', 0));
        Observer.Observe('t10', RDT('0dt', 0));
        Observer.Observe('t11', RDT('  2024-01-15T10:20:30Z  ', 0));
        Observer.Observe('t12', RDT('2024-01-15T10:20:30+02:00', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt01_Error_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EDT('2024-01-15T10:20:30Z', 0));
        Observer.Observe('t2', EDT('2024-01-15T10:20:30', 0));
        Observer.Observe('t3', EDT('2024-01-15T10:20:30.123Z', 0));
        Observer.Observe('t4', EDT('2024-01-15 10:20:30', 0));
        Observer.Observe('t5', EDT('2024-01-15', 0));
        Observer.Observe('t6', EDT('10:20', 0));
        Observer.Observe('t7', EDT('01/15/2024 10:20:30', 0));
        Observer.Observe('t8', EDT('15.01.2024 10:20', 0));
        Observer.Observe('t9', EDT('0DT', 0));
        Observer.Observe('t10', EDT('0dt', 0));
        Observer.Observe('t11', EDT('  2024-01-15T10:20:30Z  ', 0));
        Observer.Observe('t12', EDT('2024-01-15T10:20:30+02:00', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt02_Return_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RDT('2024-01-15T25:00:00Z', 0));
        Observer.Observe('t2', RDT('', 0));
        Observer.Observe('t3', RDT('abc', 0));
        Observer.Observe('t4', RDT('0D', 0));
        Observer.Observe('t5', RDT('0T', 0));
        Observer.Observe('t6', RDT('2024-01-15T24:00:00Z', 0));
        Observer.Observe('t7', RDT('1/15/24 1:20 AM', 0));
        Observer.Observe('t8', RDT('01/15/2024 10:20 PM', 0));
        Observer.Observe('t9', RDT('2024-02-30T10:00:00Z', 0));
        Observer.Observe('t10', RDT('12/31/9999 23:59:59', 0));
        Observer.Observe('t11', RDT('2024-01-15T10:20:30.1234567Z', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt02_Error_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EDT('2024-01-15T25:00:00Z', 0));
        Observer.Observe('t2', EDT('', 0));
        Observer.Observe('t3', EDT('abc', 0));
        Observer.Observe('t4', EDT('0D', 0));
        Observer.Observe('t5', EDT('0T', 0));
        Observer.Observe('t6', EDT('2024-01-15T24:00:00Z', 0));
        Observer.Observe('t7', EDT('1/15/24 1:20 AM', 0));
        Observer.Observe('t8', EDT('01/15/2024 10:20 PM', 0));
        Observer.Observe('t9', EDT('2024-02-30T10:00:00Z', 0));
        Observer.Observe('t10', EDT('12/31/9999 23:59:59', 0));
        Observer.Observe('t11', EDT('2024-01-15T10:20:30.1234567Z', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt91_Return_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RDT('2024-01-15T10:20:30Z', 9));
        Observer.Observe('t2', RDT('2024-01-15T10:20:30', 9));
        Observer.Observe('t3', RDT('2024-01-15T10:20:30.123Z', 9));
        Observer.Observe('t4', RDT('2024-01-15 10:20:30', 9));
        Observer.Observe('t5', RDT('2024-01-15', 9));
        Observer.Observe('t6', RDT('10:20', 9));
        Observer.Observe('t7', RDT('01/15/2024 10:20:30', 9));
        Observer.Observe('t8', RDT('15.01.2024 10:20', 9));
        Observer.Observe('t9', RDT('0DT', 9));
        Observer.Observe('t10', RDT('0dt', 9));
        Observer.Observe('t11', RDT('  2024-01-15T10:20:30Z  ', 9));
        Observer.Observe('t12', RDT('2024-01-15T10:20:30+02:00', 9));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt91_Error_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EDT('2024-01-15T10:20:30Z', 9));
        Observer.Observe('t2', EDT('2024-01-15T10:20:30', 9));
        Observer.Observe('t3', EDT('2024-01-15T10:20:30.123Z', 9));
        Observer.Observe('t4', EDT('2024-01-15 10:20:30', 9));
        Observer.Observe('t5', EDT('2024-01-15', 9));
        Observer.Observe('t6', EDT('10:20', 9));
        Observer.Observe('t7', EDT('01/15/2024 10:20:30', 9));
        Observer.Observe('t8', EDT('15.01.2024 10:20', 9));
        Observer.Observe('t9', EDT('0DT', 9));
        Observer.Observe('t10', EDT('0dt', 9));
        Observer.Observe('t11', EDT('  2024-01-15T10:20:30Z  ', 9));
        Observer.Observe('t12', EDT('2024-01-15T10:20:30+02:00', 9));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt92_Return_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', RDT('2024-01-15T25:00:00Z', 9));
        Observer.Observe('t2', RDT('', 9));
        Observer.Observe('t3', RDT('abc', 9));
        Observer.Observe('t4', RDT('0D', 9));
        Observer.Observe('t5', RDT('0T', 9));
        Observer.Observe('t6', RDT('2024-01-15T24:00:00Z', 9));
        Observer.Observe('t7', RDT('1/15/24 1:20 AM', 9));
        Observer.Observe('t8', RDT('01/15/2024 10:20 PM', 9));
        Observer.Observe('t9', RDT('2024-02-30T10:00:00Z', 9));
        Observer.Observe('t10', RDT('12/31/9999 23:59:59', 9));
        Observer.Observe('t11', RDT('2024-01-15T10:20:30.1234567Z', 9));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt92_Error_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EDT('2024-01-15T25:00:00Z', 9));
        Observer.Observe('t2', EDT('', 9));
        Observer.Observe('t3', EDT('abc', 9));
        Observer.Observe('t4', EDT('0D', 9));
        Observer.Observe('t5', EDT('0T', 9));
        Observer.Observe('t6', EDT('2024-01-15T24:00:00Z', 9));
        Observer.Observe('t7', EDT('1/15/24 1:20 AM', 9));
        Observer.Observe('t8', EDT('01/15/2024 10:20 PM', 9));
        Observer.Observe('t9', EDT('2024-02-30T10:00:00Z', 9));
        Observer.Observe('t10', EDT('12/31/9999 23:59:59', 9));
        Observer.Observe('t11', EDT('2024-01-15T10:20:30.1234567Z', 9));
        Observer.Finish();
    end;

}

codeunit 73526 "LT P86 Eval Option"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure OrdOf(O: Option Alpha,"Beta Two",Gamma): Integer
    begin
        exit(O);
    end;

    [TryFunction]
    local procedure TryOpt(Txt: Text; Fmt: Integer; var V: Option Alpha,"Beta Two",Gamma)
    begin
        if Fmt < 0 then
            Evaluate(V, Txt)
        else
            Evaluate(V, Txt, Fmt);
    end;

    local procedure ROpt(Txt: Text; Fmt: Integer): Text
    var
        V: Option Alpha,"Beta Two",Gamma;
        Ok: Boolean;
    begin
        V := V::Gamma;
        if Fmt < 0 then
            Ok := Evaluate(V, Txt)
        else
            Ok := Evaluate(V, Txt, Fmt);
        exit(Format(Ok) + '|' + Format(V) + '|' + Format(OrdOf(V)));
    end;

    local procedure EOpt(Txt: Text; Fmt: Integer): Text
    var
        V: Option Alpha,"Beta Two",Gamma;
    begin
        V := V::Gamma;
        if TryOpt(Txt, Fmt, V) then
            exit('ok|' + Format(V) + '|' + Format(OrdOf(V)));
        exit('err:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Format(V) + '|' + Format(OrdOf(V)));
    end;

    [Test]
    procedure Dflt1_Return_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', ROpt('Alpha', -1));
        Observer.Observe('t2', ROpt('alpha', -1));
        Observer.Observe('t3', ROpt('ALPHA', -1));
        Observer.Observe('t4', ROpt('Beta Two', -1));
        Observer.Observe('t5', ROpt('beta two', -1));
        Observer.Observe('t6', ROpt('Bet', -1));
        Observer.Observe('t7', ROpt('Gamma', -1));
        Observer.Observe('t8', ROpt('Alphabet', -1));
        Observer.Observe('t9', ROpt('0', -1));
        Observer.Observe('t10', ROpt('1', -1));
        Observer.Observe('t11', ROpt('2', -1));
        Observer.Observe('t12', ROpt('3', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Dflt1_Error_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EOpt('Alpha', -1));
        Observer.Observe('t2', EOpt('alpha', -1));
        Observer.Observe('t3', EOpt('ALPHA', -1));
        Observer.Observe('t4', EOpt('Beta Two', -1));
        Observer.Observe('t5', EOpt('beta two', -1));
        Observer.Observe('t6', EOpt('Bet', -1));
        Observer.Observe('t7', EOpt('Gamma', -1));
        Observer.Observe('t8', EOpt('Alphabet', -1));
        Observer.Observe('t9', EOpt('0', -1));
        Observer.Observe('t10', EOpt('1', -1));
        Observer.Observe('t11', EOpt('2', -1));
        Observer.Observe('t12', EOpt('3', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Dflt2_Return_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', ROpt('-1', -1));
        Observer.Observe('t2', ROpt('00', -1));
        Observer.Observe('t3', ROpt('+1', -1));
        Observer.Observe('t4', ROpt(' Alpha', -1));
        Observer.Observe('t5', ROpt('Alpha ', -1));
        Observer.Observe('t6', ROpt(' 1 ', -1));
        Observer.Observe('t7', ROpt('', -1));
        Observer.Observe('t8', ROpt('  ', -1));
        Observer.Observe('t9', ROpt('Delta', -1));
        Observer.Observe('t10', ROpt('Alpha,Beta Two', -1));
        Observer.Observe('t11', ROpt('1.0', -1));
        Observer.Observe('t12', ROpt('Beta  Two', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Dflt2_Error_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EOpt('-1', -1));
        Observer.Observe('t2', EOpt('00', -1));
        Observer.Observe('t3', EOpt('+1', -1));
        Observer.Observe('t4', EOpt(' Alpha', -1));
        Observer.Observe('t5', EOpt('Alpha ', -1));
        Observer.Observe('t6', EOpt(' 1 ', -1));
        Observer.Observe('t7', EOpt('', -1));
        Observer.Observe('t8', EOpt('  ', -1));
        Observer.Observe('t9', EOpt('Delta', -1));
        Observer.Observe('t10', EOpt('Alpha,Beta Two', -1));
        Observer.Observe('t11', EOpt('1.0', -1));
        Observer.Observe('t12', EOpt('Beta  Two', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Dflt3_Return_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', ROpt('1,0', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Dflt3_Error_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EOpt('1,0', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt01_Return_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', ROpt('Alpha', 0));
        Observer.Observe('t2', ROpt('alpha', 0));
        Observer.Observe('t3', ROpt('ALPHA', 0));
        Observer.Observe('t4', ROpt('Beta Two', 0));
        Observer.Observe('t5', ROpt('beta two', 0));
        Observer.Observe('t6', ROpt('Bet', 0));
        Observer.Observe('t7', ROpt('Gamma', 0));
        Observer.Observe('t8', ROpt('Alphabet', 0));
        Observer.Observe('t9', ROpt('0', 0));
        Observer.Observe('t10', ROpt('1', 0));
        Observer.Observe('t11', ROpt('2', 0));
        Observer.Observe('t12', ROpt('3', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt01_Error_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EOpt('Alpha', 0));
        Observer.Observe('t2', EOpt('alpha', 0));
        Observer.Observe('t3', EOpt('ALPHA', 0));
        Observer.Observe('t4', EOpt('Beta Two', 0));
        Observer.Observe('t5', EOpt('beta two', 0));
        Observer.Observe('t6', EOpt('Bet', 0));
        Observer.Observe('t7', EOpt('Gamma', 0));
        Observer.Observe('t8', EOpt('Alphabet', 0));
        Observer.Observe('t9', EOpt('0', 0));
        Observer.Observe('t10', EOpt('1', 0));
        Observer.Observe('t11', EOpt('2', 0));
        Observer.Observe('t12', EOpt('3', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt02_Return_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', ROpt('-1', 0));
        Observer.Observe('t2', ROpt('00', 0));
        Observer.Observe('t3', ROpt('+1', 0));
        Observer.Observe('t4', ROpt(' Alpha', 0));
        Observer.Observe('t5', ROpt('Alpha ', 0));
        Observer.Observe('t6', ROpt(' 1 ', 0));
        Observer.Observe('t7', ROpt('', 0));
        Observer.Observe('t8', ROpt('  ', 0));
        Observer.Observe('t9', ROpt('Delta', 0));
        Observer.Observe('t10', ROpt('Alpha,Beta Two', 0));
        Observer.Observe('t11', ROpt('1.0', 0));
        Observer.Observe('t12', ROpt('Beta  Two', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt02_Error_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EOpt('-1', 0));
        Observer.Observe('t2', EOpt('00', 0));
        Observer.Observe('t3', EOpt('+1', 0));
        Observer.Observe('t4', EOpt(' Alpha', 0));
        Observer.Observe('t5', EOpt('Alpha ', 0));
        Observer.Observe('t6', EOpt(' 1 ', 0));
        Observer.Observe('t7', EOpt('', 0));
        Observer.Observe('t8', EOpt('  ', 0));
        Observer.Observe('t9', EOpt('Delta', 0));
        Observer.Observe('t10', EOpt('Alpha,Beta Two', 0));
        Observer.Observe('t11', EOpt('1.0', 0));
        Observer.Observe('t12', EOpt('Beta  Two', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt03_Return_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', ROpt('1,0', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt03_Error_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EOpt('1,0', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt91_Return_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', ROpt('Alpha', 9));
        Observer.Observe('t2', ROpt('alpha', 9));
        Observer.Observe('t3', ROpt('ALPHA', 9));
        Observer.Observe('t4', ROpt('Beta Two', 9));
        Observer.Observe('t5', ROpt('beta two', 9));
        Observer.Observe('t6', ROpt('Bet', 9));
        Observer.Observe('t7', ROpt('Gamma', 9));
        Observer.Observe('t8', ROpt('Alphabet', 9));
        Observer.Observe('t9', ROpt('0', 9));
        Observer.Observe('t10', ROpt('1', 9));
        Observer.Observe('t11', ROpt('2', 9));
        Observer.Observe('t12', ROpt('3', 9));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt91_Error_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EOpt('Alpha', 9));
        Observer.Observe('t2', EOpt('alpha', 9));
        Observer.Observe('t3', EOpt('ALPHA', 9));
        Observer.Observe('t4', EOpt('Beta Two', 9));
        Observer.Observe('t5', EOpt('beta two', 9));
        Observer.Observe('t6', EOpt('Bet', 9));
        Observer.Observe('t7', EOpt('Gamma', 9));
        Observer.Observe('t8', EOpt('Alphabet', 9));
        Observer.Observe('t9', EOpt('0', 9));
        Observer.Observe('t10', EOpt('1', 9));
        Observer.Observe('t11', EOpt('2', 9));
        Observer.Observe('t12', EOpt('3', 9));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt92_Return_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', ROpt('-1', 9));
        Observer.Observe('t2', ROpt('00', 9));
        Observer.Observe('t3', ROpt('+1', 9));
        Observer.Observe('t4', ROpt(' Alpha', 9));
        Observer.Observe('t5', ROpt('Alpha ', 9));
        Observer.Observe('t6', ROpt(' 1 ', 9));
        Observer.Observe('t7', ROpt('', 9));
        Observer.Observe('t8', ROpt('  ', 9));
        Observer.Observe('t9', ROpt('Delta', 9));
        Observer.Observe('t10', ROpt('Alpha,Beta Two', 9));
        Observer.Observe('t11', ROpt('1.0', 9));
        Observer.Observe('t12', ROpt('Beta  Two', 9));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt92_Error_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EOpt('-1', 9));
        Observer.Observe('t2', EOpt('00', 9));
        Observer.Observe('t3', EOpt('+1', 9));
        Observer.Observe('t4', EOpt(' Alpha', 9));
        Observer.Observe('t5', EOpt('Alpha ', 9));
        Observer.Observe('t6', EOpt(' 1 ', 9));
        Observer.Observe('t7', EOpt('', 9));
        Observer.Observe('t8', EOpt('  ', 9));
        Observer.Observe('t9', EOpt('Delta', 9));
        Observer.Observe('t10', EOpt('Alpha,Beta Two', 9));
        Observer.Observe('t11', EOpt('1.0', 9));
        Observer.Observe('t12', EOpt('Beta  Two', 9));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt93_Return_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', ROpt('1,0', 9));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt93_Error_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EOpt('1,0', 9));
        Observer.Finish();
    end;

}

codeunit 73527 "LT P86 Eval Enum"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryEn(Txt: Text; Fmt: Integer; var V: Enum "LT P86 Color")
    begin
        if Fmt < 0 then
            Evaluate(V, Txt)
        else
            Evaluate(V, Txt, Fmt);
    end;

    local procedure REn(Txt: Text; Fmt: Integer): Text
    var
        V: Enum "LT P86 Color";
        Ok: Boolean;
    begin
        V := V::Blue;
        if Fmt < 0 then
            Ok := Evaluate(V, Txt)
        else
            Ok := Evaluate(V, Txt, Fmt);
        exit(Format(Ok) + '|' + Format(V) + '|' + Format(V.AsInteger()));
    end;

    local procedure EEn(Txt: Text; Fmt: Integer): Text
    var
        V: Enum "LT P86 Color";
    begin
        V := V::Blue;
        if TryEn(Txt, Fmt, V) then
            exit('ok|' + Format(V) + '|' + Format(V.AsInteger()));
        exit('err:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Format(V) + '|' + Format(V.AsInteger()));
    end;

    [Test]
    procedure Dflt1_Return_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', REn('Red', -1));
        Observer.Observe('t2', REn('red', -1));
        Observer.Observe('t3', REn('RED', -1));
        Observer.Observe('t4', REn('Green', -1));
        Observer.Observe('t5', REn('Green Caption', -1));
        Observer.Observe('t6', REn('green caption', -1));
        Observer.Observe('t7', REn('Dark Blue', -1));
        Observer.Observe('t8', REn('dark blue', -1));
        Observer.Observe('t9', REn('DarkBlue', -1));
        Observer.Observe('t10', REn('Blue', -1));
        Observer.Observe('t11', REn('0', -1));
        Observer.Observe('t12', REn('1', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Dflt1_Error_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EEn('Red', -1));
        Observer.Observe('t2', EEn('red', -1));
        Observer.Observe('t3', EEn('RED', -1));
        Observer.Observe('t4', EEn('Green', -1));
        Observer.Observe('t5', EEn('Green Caption', -1));
        Observer.Observe('t6', EEn('green caption', -1));
        Observer.Observe('t7', EEn('Dark Blue', -1));
        Observer.Observe('t8', EEn('dark blue', -1));
        Observer.Observe('t9', EEn('DarkBlue', -1));
        Observer.Observe('t10', EEn('Blue', -1));
        Observer.Observe('t11', EEn('0', -1));
        Observer.Observe('t12', EEn('1', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Dflt2_Return_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', REn('2', -1));
        Observer.Observe('t2', REn('5', -1));
        Observer.Observe('t3', REn('10', -1));
        Observer.Observe('t4', REn('11', -1));
        Observer.Observe('t5', REn('-1', -1));
        Observer.Observe('t6', REn(' Red ', -1));
        Observer.Observe('t7', REn(' 5 ', -1));
        Observer.Observe('t8', REn('', -1));
        Observer.Observe('t9', REn('  ', -1));
        Observer.Observe('t10', REn('Purple', -1));
        Observer.Observe('t11', REn('00', -1));
        Observer.Observe('t12', REn('+5', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Dflt2_Error_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EEn('2', -1));
        Observer.Observe('t2', EEn('5', -1));
        Observer.Observe('t3', EEn('10', -1));
        Observer.Observe('t4', EEn('11', -1));
        Observer.Observe('t5', EEn('-1', -1));
        Observer.Observe('t6', EEn(' Red ', -1));
        Observer.Observe('t7', EEn(' 5 ', -1));
        Observer.Observe('t8', EEn('', -1));
        Observer.Observe('t9', EEn('  ', -1));
        Observer.Observe('t10', EEn('Purple', -1));
        Observer.Observe('t11', EEn('00', -1));
        Observer.Observe('t12', EEn('+5', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Dflt3_Return_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', REn('5.0', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Dflt3_Error_FNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EEn('5.0', -1));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt01_Return_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', REn('Red', 0));
        Observer.Observe('t2', REn('red', 0));
        Observer.Observe('t3', REn('RED', 0));
        Observer.Observe('t4', REn('Green', 0));
        Observer.Observe('t5', REn('Green Caption', 0));
        Observer.Observe('t6', REn('green caption', 0));
        Observer.Observe('t7', REn('Dark Blue', 0));
        Observer.Observe('t8', REn('dark blue', 0));
        Observer.Observe('t9', REn('DarkBlue', 0));
        Observer.Observe('t10', REn('Blue', 0));
        Observer.Observe('t11', REn('0', 0));
        Observer.Observe('t12', REn('1', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt01_Error_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EEn('Red', 0));
        Observer.Observe('t2', EEn('red', 0));
        Observer.Observe('t3', EEn('RED', 0));
        Observer.Observe('t4', EEn('Green', 0));
        Observer.Observe('t5', EEn('Green Caption', 0));
        Observer.Observe('t6', EEn('green caption', 0));
        Observer.Observe('t7', EEn('Dark Blue', 0));
        Observer.Observe('t8', EEn('dark blue', 0));
        Observer.Observe('t9', EEn('DarkBlue', 0));
        Observer.Observe('t10', EEn('Blue', 0));
        Observer.Observe('t11', EEn('0', 0));
        Observer.Observe('t12', EEn('1', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt02_Return_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', REn('2', 0));
        Observer.Observe('t2', REn('5', 0));
        Observer.Observe('t3', REn('10', 0));
        Observer.Observe('t4', REn('11', 0));
        Observer.Observe('t5', REn('-1', 0));
        Observer.Observe('t6', REn(' Red ', 0));
        Observer.Observe('t7', REn(' 5 ', 0));
        Observer.Observe('t8', REn('', 0));
        Observer.Observe('t9', REn('  ', 0));
        Observer.Observe('t10', REn('Purple', 0));
        Observer.Observe('t11', REn('00', 0));
        Observer.Observe('t12', REn('+5', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt02_Error_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EEn('2', 0));
        Observer.Observe('t2', EEn('5', 0));
        Observer.Observe('t3', EEn('10', 0));
        Observer.Observe('t4', EEn('11', 0));
        Observer.Observe('t5', EEn('-1', 0));
        Observer.Observe('t6', EEn(' Red ', 0));
        Observer.Observe('t7', EEn(' 5 ', 0));
        Observer.Observe('t8', EEn('', 0));
        Observer.Observe('t9', EEn('  ', 0));
        Observer.Observe('t10', EEn('Purple', 0));
        Observer.Observe('t11', EEn('00', 0));
        Observer.Observe('t12', EEn('+5', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt03_Return_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', REn('5.0', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt03_Error_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EEn('5.0', 0));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt91_Return_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', REn('Red', 9));
        Observer.Observe('t2', REn('red', 9));
        Observer.Observe('t3', REn('RED', 9));
        Observer.Observe('t4', REn('Green', 9));
        Observer.Observe('t5', REn('Green Caption', 9));
        Observer.Observe('t6', REn('green caption', 9));
        Observer.Observe('t7', REn('Dark Blue', 9));
        Observer.Observe('t8', REn('dark blue', 9));
        Observer.Observe('t9', REn('DarkBlue', 9));
        Observer.Observe('t10', REn('Blue', 9));
        Observer.Observe('t11', REn('0', 9));
        Observer.Observe('t12', REn('1', 9));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt91_Error_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EEn('Red', 9));
        Observer.Observe('t2', EEn('red', 9));
        Observer.Observe('t3', EEn('RED', 9));
        Observer.Observe('t4', EEn('Green', 9));
        Observer.Observe('t5', EEn('Green Caption', 9));
        Observer.Observe('t6', EEn('green caption', 9));
        Observer.Observe('t7', EEn('Dark Blue', 9));
        Observer.Observe('t8', EEn('dark blue', 9));
        Observer.Observe('t9', EEn('DarkBlue', 9));
        Observer.Observe('t10', EEn('Blue', 9));
        Observer.Observe('t11', EEn('0', 9));
        Observer.Observe('t12', EEn('1', 9));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt92_Return_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', REn('2', 9));
        Observer.Observe('t2', REn('5', 9));
        Observer.Observe('t3', REn('10', 9));
        Observer.Observe('t4', REn('11', 9));
        Observer.Observe('t5', REn('-1', 9));
        Observer.Observe('t6', REn(' Red ', 9));
        Observer.Observe('t7', REn(' 5 ', 9));
        Observer.Observe('t8', REn('', 9));
        Observer.Observe('t9', REn('  ', 9));
        Observer.Observe('t10', REn('Purple', 9));
        Observer.Observe('t11', REn('00', 9));
        Observer.Observe('t12', REn('+5', 9));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt92_Error_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EEn('2', 9));
        Observer.Observe('t2', EEn('5', 9));
        Observer.Observe('t3', EEn('10', 9));
        Observer.Observe('t4', EEn('11', 9));
        Observer.Observe('t5', EEn('-1', 9));
        Observer.Observe('t6', EEn(' Red ', 9));
        Observer.Observe('t7', EEn(' 5 ', 9));
        Observer.Observe('t8', EEn('', 9));
        Observer.Observe('t9', EEn('  ', 9));
        Observer.Observe('t10', EEn('Purple', 9));
        Observer.Observe('t11', EEn('00', 9));
        Observer.Observe('t12', EEn('+5', 9));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt93_Return_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', REn('5.0', 9));
        Observer.Finish();
    end;

    [Test]
    procedure Fmt93_Error_F9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', EEn('5.0', 9));
        Observer.Finish();
    end;

}

