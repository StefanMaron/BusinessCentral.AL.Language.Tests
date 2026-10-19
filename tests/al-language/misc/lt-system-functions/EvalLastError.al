// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Evaluate with every type, success and failure; the variable after a failed Evaluate.
// BC versions: 29 (27 and 28 by CI)

codeunit 72510 "LT SyT Evaluate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Evaluate_Integer()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        Ok: Boolean;
    begin
        I := 99;
        Ok := Evaluate(I, '123');
        Observer.Observe('123', Format(Ok) + '|' + Format(I));
        Ok := Evaluate(I, '-45');
        Observer.Observe('-45', Format(Ok) + '|' + Format(I));
        Ok := Evaluate(I, ' 7 ');
        Observer.Observe('padded', Format(Ok) + '|' + Format(I));
        Ok := Evaluate(I, '+8');
        Observer.Observe('+8', Format(Ok) + '|' + Format(I));
        Ok := Evaluate(I, '1,234');
        Observer.Observe('1,234', Format(Ok) + '|' + Format(I));
        I := 99;
        Ok := Evaluate(I, '');
        Observer.Observe('empty', Format(Ok) + '|' + Format(I));
        I := 99;
        Ok := Evaluate(I, 'abc');
        Observer.Observe('abc', Format(Ok) + '|' + Format(I));
        I := 99;
        Ok := Evaluate(I, '1.5');
        Observer.Observe('1.5', Format(Ok) + '|' + Format(I));
        I := 99;
        Ok := Evaluate(I, '2147483648');
        Observer.Observe('overflow', Format(Ok) + '|' + Format(I));
        Ok := Evaluate(I, '2147483647');
        Observer.Observe('max', Format(Ok) + '|' + Format(I));
        Ok := Evaluate(I, '-2147483648');
        Observer.Observe('min', Format(Ok) + '|' + Format(I));
        I := 99;
        Ok := Evaluate(I, '12abc');
        Observer.Observe('12abc', Format(Ok) + '|' + Format(I));
        asserterror Evaluate(I, 'abc');
        Observer.ObserveError('abc raises');
        Observer.Expect('123', 'Yes|123');
        Observer.Expect('-45', 'Yes|-45');
        Observer.Expect('padded', 'Yes|7');
        Observer.Expect('+8', 'Yes|8');
        Observer.Expect('1,234', 'Yes|1234');
        Observer.Expect('empty', 'No|99');
        Observer.Expect('abc', 'No|99');
        Observer.Expect('1.5', 'No|99');
        Observer.Expect('overflow', 'No|99');
        Observer.Expect('max', 'Yes|2147483647');
        Observer.Expect('min', 'Yes|-2147483648');
        Observer.Expect('12abc', 'No|99');
        Observer.Expect('abc raises|text', 'The value "abc" can''t be evaluated into type Integer.');
        Observer.Expect('abc raises|code', 'Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
        Ok: Boolean;
    begin
        D := 99;
        Ok := Evaluate(D, '1.5');
        Observer.Observe('1.5', Format(Ok) + '|' + Format(D));
        Ok := Evaluate(D, '-0.25');
        Observer.Observe('-0.25', Format(Ok) + '|' + Format(D));
        Ok := Evaluate(D, '1,5');
        Observer.Observe('1,5', Format(Ok) + '|' + Format(D));
        Ok := Evaluate(D, '1,234.56');
        Observer.Observe('1,234.56', Format(Ok) + '|' + Format(D));
        Ok := Evaluate(D, '1e3');
        Observer.Observe('1e3', Format(Ok) + '|' + Format(D));
        Ok := Evaluate(D, '.5');
        Observer.Observe('.5', Format(Ok) + '|' + Format(D));
        Ok := Evaluate(D, '5.');
        Observer.Observe('5.', Format(Ok) + '|' + Format(D));
        D := 99;
        Ok := Evaluate(D, 'x');
        Observer.Observe('x', Format(Ok) + '|' + Format(D));
        D := 99;
        Ok := Evaluate(D, '');
        Observer.Observe('empty', Format(Ok) + '|' + Format(D));
        Ok := Evaluate(D, '1.123456789012345678901');
        Observer.Observe('many decimals', Format(Ok) + '|' + Format(D, 0, 9));
        Ok := Evaluate(D, '99999999999999999999');
        Observer.Observe('20 digits', Format(Ok) + '|' + Format(D, 0, 9));
        Ok := Evaluate(D, '1.5', 9);
        Observer.Observe('1.5 format 9', Format(Ok) + '|' + Format(D, 0, 9));
        Ok := Evaluate(D, '1,5', 9);
        Observer.Observe('1,5 format 9', Format(Ok) + '|' + Format(D, 0, 9));
        Ok := Evaluate(D, '1234.5', 9);
        Observer.Observe('1234.5 format 9', Format(Ok) + '|' + Format(D, 0, 9));
        Ok := Evaluate(D, '1,234.5', 9);
        Observer.Observe('1,234.5 format 9', Format(Ok) + '|' + Format(D, 0, 9));
        Observer.Expect('1.5', 'Yes|1.5');
        Observer.Expect('-0.25', 'Yes|-0.25');
        Observer.Expect('1,5', 'Yes|15');
        Observer.Expect('1,234.56', 'Yes|1,234.56');
        Observer.Expect('1e3', 'Yes|1,000');
        Observer.Expect('.5', 'Yes|0.5');
        Observer.Expect('5.', 'Yes|5');
        Observer.Expect('x', 'No|99');
        Observer.Expect('empty', 'No|99');
        Observer.Expect('many decimals', 'Yes|1.12345678901234567');
        Observer.Expect('20 digits', 'No|1.12345678901234567');
        Observer.Expect('1.5 format 9', 'Yes|1.5');
        Observer.Expect('1,5 format 9', 'No|1.5');
        Observer.Expect('1234.5 format 9', 'Yes|1234.5');
        Observer.Expect('1,234.5 format 9', 'No|1234.5');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_Boolean()
    var
        Observer: Codeunit "Probe Observer";
        B: Boolean;
        Ok: Boolean;
        Inputs: List of [Text];
        Input: Text;
    begin
        Inputs.Add('true');
        Inputs.Add('TRUE');
        Inputs.Add('True');
        Inputs.Add('false');
        Inputs.Add('1');
        Inputs.Add('0');
        Inputs.Add('yes');
        Inputs.Add('no');
        Inputs.Add('Yes');
        Inputs.Add('Ja');
        Inputs.Add('t');
        Inputs.Add('f');
        Inputs.Add('y');
        Inputs.Add('on');
        Inputs.Add('off');
        Inputs.Add('');
        Inputs.Add(' true ');
        Inputs.Add('2');
        Inputs.Add('-1');
        foreach Input in Inputs do begin
            B := true;
            Ok := Evaluate(B, Input);
            Observer.Observe('[' + Input + ']', Format(Ok) + '|' + Format(B));
        end;
        Observer.Expect('[true]', 'Yes|Yes');
        Observer.Expect('[TRUE]', 'Yes|Yes');
        Observer.Expect('[True]', 'Yes|Yes');
        Observer.Expect('[false]', 'Yes|No');
        Observer.Expect('[1]', 'Yes|Yes');
        Observer.Expect('[0]', 'Yes|No');
        Observer.Expect('[yes]', 'Yes|Yes');
        Observer.Expect('[no]', 'Yes|No');
        Observer.Expect('[Yes]', 'Yes|Yes');
        Observer.Expect('[Ja]', 'No|Yes');
        Observer.Expect('[t]', 'Yes|Yes');
        Observer.Expect('[f]', 'Yes|No');
        Observer.Expect('[y]', 'Yes|Yes');
        Observer.Expect('[on]', 'No|Yes');
        Observer.Expect('[off]', 'No|Yes');
        Observer.Expect('[]', 'No|Yes');
        Observer.Expect('[ true ]', 'Yes|Yes');
        Observer.Expect('[2]', 'No|Yes');
        Observer.Expect('[-1]', 'No|Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_Boolean_Format9()
    var
        Observer: Codeunit "Probe Observer";
        B: Boolean;
        Ok: Boolean;
        Inputs: List of [Text];
        Input: Text;
    begin
        Inputs.Add('true');
        Inputs.Add('false');
        Inputs.Add('1');
        Inputs.Add('0');
        Inputs.Add('Yes');
        Inputs.Add('No');
        Inputs.Add('');
        foreach Input in Inputs do begin
            B := true;
            Ok := Evaluate(B, Input, 9);
            Observer.Observe('9 [' + Input + ']', Format(Ok) + '|' + Format(B));
        end;
        Observer.Expect('9 [true]', 'Yes|Yes');
        Observer.Expect('9 [false]', 'Yes|No');
        Observer.Expect('9 [1]', 'Yes|Yes');
        Observer.Expect('9 [0]', 'Yes|No');
        Observer.Expect('9 [Yes]', 'No|Yes');
        Observer.Expect('9 [No]', 'No|Yes');
        Observer.Expect('9 []', 'No|Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_DateTimeTypes()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
        T: Time;
        DT: DateTime;
        Dur: Duration;
        Ok: Boolean;
    begin
        Ok := Evaluate(D, '2024-03-05', 9);
        Observer.Observe('date iso 9', Format(Ok) + '|' + Format(D, 0, 9));
        Ok := Evaluate(D, '03/05/24');
        Observer.Observe('date 03/05/24', Format(Ok) + '|' + Format(D, 0, 9));
        Ok := Evaluate(D, '05.03.2024');
        Observer.Observe('date 05.03.2024', Format(Ok) + '|' + Format(D, 0, 9));
        Ok := Evaluate(D, '2024-02-30', 9);
        Observer.Observe('date invalid day', Format(Ok) + '|' + Format(D, 0, 9));
        Ok := Evaluate(D, '', 9);
        Observer.Observe('date empty', Format(Ok) + '|' + Format(D, 0, 9));
        Ok := Evaluate(D, 'x', 9);
        Observer.Observe('date x', Format(Ok) + '|' + Format(D, 0, 9));
        Ok := Evaluate(D, '0001-01-01', 9);
        Observer.Observe('date min', Format(Ok) + '|' + Format(D, 0, 9));
        Ok := Evaluate(D, '9999-12-31', 9);
        Observer.Observe('date max', Format(Ok) + '|' + Format(D, 0, 9));
        Ok := Evaluate(D, '2024-03-05T10:00:00Z', 9);
        Observer.Observe('date with time', Format(Ok) + '|' + Format(D, 0, 9));
        Ok := Evaluate(T, '14:30:25', 9);
        Observer.Observe('time 14:30:25', Format(Ok) + '|' + Format(T, 0, 9));
        Ok := Evaluate(T, '14:30:25.123', 9);
        Observer.Observe('time ms', Format(Ok) + '|' + Format(T, 0, 9));
        Ok := Evaluate(T, '25:00:00', 9);
        Observer.Observe('time 25', Format(Ok) + '|' + Format(T, 0, 9));
        Ok := Evaluate(T, '', 9);
        Observer.Observe('time empty', Format(Ok) + '|' + Format(T, 0, 9));
        Ok := Evaluate(DT, '2024-03-05T14:30:25.123Z', 9);
        Observer.Observe('datetime Z', Format(Ok) + '|' + Format(DT, 0, 9));
        Ok := Evaluate(DT, '2024-03-05T14:30:25', 9);
        Observer.Observe('datetime no Z', Format(Ok) + '|' + Format(DT, 0, 9));
        Ok := Evaluate(DT, '2024-03-05', 9);
        Observer.Observe('datetime date only', Format(Ok) + '|' + Format(DT, 0, 9));
        Ok := Evaluate(DT, 'garbage', 9);
        Observer.Observe('datetime garbage', Format(Ok) + '|' + Format(DT, 0, 9));
        Ok := Evaluate(Dur, '1 day', 0);
        Observer.Observe('duration 1 day', Format(Ok) + '|' + Format(Dur, 0, 9));
        Ok := Evaluate(Dur, '1 hour 30 minutes', 0);
        Observer.Observe('duration 1h30m', Format(Ok) + '|' + Format(Dur, 0, 9));
        Ok := Evaluate(Dur, '5000', 9);
        Observer.Observe('duration 5000', Format(Ok) + '|' + Format(Dur, 0, 9));
        Ok := Evaluate(Dur, 'x', 9);
        Observer.Observe('duration x', Format(Ok) + '|' + Format(Dur, 0, 9));
        Observer.Expect('date iso 9', 'Yes|2024-03-05');
        Observer.Expect('date 03/05/24', 'Yes|2024-03-05');
        Observer.Expect('date 05.03.2024', 'Yes|2024-05-03');
        Observer.Expect('date invalid day', 'No|2024-05-03');
        Observer.Expect('date empty', 'Yes|');
        Observer.Expect('date x', 'No|');
        Observer.Expect('date min', 'Yes|');
        Observer.Expect('date max', 'Yes|9999-12-31');
        Observer.Expect('date with time', 'No|9999-12-31');
        Observer.Expect('time 14:30:25', 'Yes|14:30:25');
        Observer.Expect('time ms', 'Yes|14:30:25.123');
        Observer.Expect('time 25', 'No|14:30:25.123');
        Observer.Expect('time empty', 'Yes|');
        Observer.Expect('datetime Z', 'Yes|2024-03-05T14:30:25.123Z');
        Observer.Expect('datetime no Z', 'Yes|2024-03-05T14:30:25Z');
        Observer.Expect('datetime date only', 'Yes|2024-03-05T00:00:00Z');
        Observer.Expect('datetime garbage', 'No|2024-03-05T00:00:00Z');
        Observer.Expect('duration 1 day', 'Yes|P1DT0H0M0.0S');
        Observer.Expect('duration 1h30m', 'Yes|P0DT1H30M0.0S');
        Observer.Expect('duration 5000', 'No|P0DT1H30M0.0S');
        Observer.Expect('duration x', 'No|P0DT1H30M0.0S');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_Text_Code_Option_Other()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        C: Code[5];
        Opt: Option A,"B C",D;
        B: BigInteger;
        G: Guid;
        DF: DateFormula;
        Ch: Char;
        Ok: Boolean;
    begin
        Ok := Evaluate(T, 'hello');
        Observer.Observe('text', Format(Ok) + '|' + T);
        Ok := Evaluate(T, '');
        Observer.Observe('text empty', Format(Ok) + '|' + T);
        Ok := Evaluate(C, 'abcdefgh');
        Observer.Observe('code 5 too long', Format(Ok) + '|' + C);
        Ok := Evaluate(C, 'ab');
        Observer.Observe('code lower', Format(Ok) + '|' + C);
        Ok := Evaluate(Opt, 'D');
        Observer.Observe('option D', Format(Ok) + '|' + Format(Opt));
        Ok := Evaluate(Opt, 'b c');
        Observer.Observe('option case', Format(Ok) + '|' + Format(Opt));
        Ok := Evaluate(Opt, '0');
        Observer.Observe('option ordinal 0', Format(Ok) + '|' + Format(Opt));
        Ok := Evaluate(Opt, '7');
        Observer.Observe('option ordinal 7', Format(Ok) + '|' + Format(Opt));
        Ok := Evaluate(Opt, 'Z');
        Observer.Observe('option Z', Format(Ok) + '|' + Format(Opt));
        Ok := Evaluate(Opt, '');
        Observer.Observe('option empty', Format(Ok) + '|' + Format(Opt));
        Ok := Evaluate(B, '9223372036854775807');
        Observer.Observe('bigint max', Format(Ok) + '|' + Format(B));
        Ok := Evaluate(B, '9223372036854775808');
        Observer.Observe('bigint overflow', Format(Ok) + '|' + Format(B));
        Ok := Evaluate(G, '{12345678-1234-1234-1234-123456789ABC}');
        Observer.Observe('guid braces', Format(Ok) + '|' + Format(G));
        Ok := Evaluate(G, '12345678-1234-1234-1234-123456789abc');
        Observer.Observe('guid no braces', Format(Ok) + '|' + Format(G));
        Ok := Evaluate(G, 'nope');
        Observer.Observe('guid invalid', Format(Ok));
        Ok := Evaluate(G, '');
        Observer.Observe('guid empty', Format(Ok) + '|' + Format(G));
        Ok := Evaluate(DF, '1D');
        Observer.Observe('dateformula 1D', Format(Ok) + '|' + Format(DF));
        Ok := Evaluate(DF, '-CM+1D');
        Observer.Observe('dateformula -CM+1D', Format(Ok) + '|' + Format(DF));
        Ok := Evaluate(DF, 'xyz');
        Observer.Observe('dateformula invalid', Format(Ok));
        Ok := Evaluate(DF, '');
        Observer.Observe('dateformula empty', Format(Ok) + '|' + Format(DF));
        Ok := Evaluate(Ch, '65');
        Observer.Observe('char 65', Format(Ok) + '|' + Format(Ch, 0, 9));
        Observer.Expect('text', 'Yes|hello');
        Observer.Expect('text empty', 'Yes|');
        Observer.Expect('code 5 too long', 'No|');
        Observer.Expect('code lower', 'Yes|AB');
        Observer.Expect('option D', 'Yes|D');
        Observer.Expect('option case', 'Yes|B C');
        Observer.Expect('option ordinal 0', 'Yes|A');
        Observer.Expect('option ordinal 7', 'Yes|7');
        Observer.Expect('option Z', 'No|7');
        Observer.Expect('option empty', 'No|7');
        Observer.Expect('bigint max', 'Yes|9223372036854775807');
        Observer.Expect('bigint overflow', 'No|9223372036854775807');
        Observer.Expect('guid braces', 'Yes|{12345678-1234-1234-1234-123456789ABC}');
        Observer.Expect('guid no braces', 'Yes|{12345678-1234-1234-1234-123456789ABC}');
        Observer.Expect('guid invalid', 'No');
        Observer.Expect('guid empty', 'No|{12345678-1234-1234-1234-123456789ABC}');
        Observer.Expect('dateformula 1D', 'Yes|1D');
        Observer.Expect('dateformula -CM+1D', 'Yes|-CM+1D');
        Observer.Expect('dateformula invalid', 'No');
        Observer.Expect('dateformula empty', 'Yes|');
        Observer.Expect('char 65', 'No|\u0000');
        Observer.Verify();
    end;
}

codeunit 72511 "LT SyT Last Error"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure FailText()
    begin
        Error('boom %1', 5);
    end;

    [TryFunction]
    local procedure FailDivide()
    var
        a: Integer;
        b: Integer;
    begin
        a := 1;
        b := 0;
        a := a div b;
    end;

    [TryFunction]
    local procedure Succeed()
    begin
    end;

    [Test]
    procedure LastError_Initial_AndAfterTry()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('text initial', GetLastErrorText());
        Observer.Observe('code initial', GetLastErrorCode());
        Observer.Observe('try fail', Format(FailText()));
        Observer.Observe('text', GetLastErrorText());
        Observer.Observe('code', GetLastErrorCode());
        Observer.Observe('try succeed', Format(Succeed()));
        Observer.Observe('text after success', GetLastErrorText());
        ClearLastError();
        Observer.Observe('text after clear', GetLastErrorText());
        Observer.Observe('code after clear', GetLastErrorCode());
        Observer.Expect('text initial', '');
        Observer.Expect('code initial', '');
        Observer.Expect('try fail', 'No');
        Observer.Expect('text', 'boom 5');
        Observer.Expect('code', 'Dialog');
        Observer.Expect('try succeed', 'Yes');
        Observer.Expect('text after success', 'boom 5');
        Observer.Expect('text after clear', '');
        Observer.Expect('code after clear', '');
        Observer.Verify();
    end;

    [Test]
    procedure LastError_Divide()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('try fail', Format(FailDivide()));
        Observer.Observe('text', GetLastErrorText());
        Observer.Observe('code', GetLastErrorCode());
        Observer.Observe('callstack nonempty', Format(GetLastErrorCallStack() <> ''));
        ClearLastError();
        Observer.Observe('callstack after clear', GetLastErrorCallStack());
        Observer.Expect('try fail', 'No');
        Observer.Expect('text', 'Attempted to divide by zero.');
        Observer.Expect('code', 'AL:DivideByZero');
        Observer.Expect('callstack nonempty', 'Yes');
        Observer.Expect('callstack after clear', '');
        Observer.Verify();
    end;

    [Test]
    procedure LastError_Asserterror()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Error('first');
        Observer.Observe('1 text', GetLastErrorText());
        asserterror Error('second');
        Observer.Observe('2 text', GetLastErrorText());
        asserterror Error('');
        Observer.Observe('3 empty text', GetLastErrorText());
        Observer.Observe('3 empty code', GetLastErrorCode());
        Observer.Expect('1 text', 'first');
        Observer.Expect('2 text', 'second');
        Observer.Expect('3 empty text', '');
        Observer.Expect('3 empty code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure LastError_SurvivesPassingCalls()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Error('keep');
        Observer.Observe('Succeed', Format(Succeed()));
        Observer.Observe('text after succeeding try', GetLastErrorText());
        asserterror Error('keep');
        Observer.Observe('text after Format', Format(1) + GetLastErrorText());
        asserterror Error('keep2');
        ClearLastError();
        asserterror Error('keep3');
        Observer.Observe('text', GetLastErrorText());
        Observer.Observe('text twice', GetLastErrorText());
        Observer.Expect('Succeed', 'Yes');
        Observer.Expect('text after succeeding try', 'keep');
        Observer.Expect('text after Format', '1keep');
        Observer.Expect('text', 'keep3');
        Observer.Expect('text twice', 'keep3');
        Observer.Verify();
    end;
}
