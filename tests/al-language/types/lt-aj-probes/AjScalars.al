// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Facts: Evaluate into a Decimal for texts with letters or a slash (result, variable, error text and code); Evaluate of a date text into a Time; JsonValue.AsDecimal / AsInteger on JSON strings; Format with <Filler Character,0> on Date, Time and DateTime; Random with a Decimal argument (range only).
// BC versions: 27.5+

codeunit 79000 "LT AJ Scalars"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure ObserveEvaluateDecimal(T: Text)
    var
        D: Decimal;
        Ok: Boolean;
    begin
        D := 99;
        Ok := Evaluate(D, T);
        Observer.Observe(T + ' bool', Format(Ok) + '|' + Format(D));
        D := 99;
        ClearLastError();
        if TryEvaluateDecimal(T, D) then
            Observer.Observe(T + ' statement', 'no error|' + Format(D))
        else begin
            Observer.ObserveError(T + ' statement');
            Observer.Observe(T + ' value after', Format(D));
        end;
    end;

    [Test]
    procedure Evaluate_Decimal_Slash_Texts()
    begin
        ObserveEvaluateDecimal('New/Updated');
        ObserveEvaluateDecimal('12/5');
        ObserveEvaluateDecimal('1/2');
        Observer.Finish();
    end;

    [Test]
    procedure Evaluate_Decimal_Letter_Texts()
    begin
        ObserveEvaluateDecimal('abc1');
        ObserveEvaluateDecimal('1abc');
        ObserveEvaluateDecimal('5-');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryEvaluateDecimal(T: Text; var D: Decimal)
    begin
        Evaluate(D, T);
    end;

    [TryFunction]
    local procedure TryEvaluateTime(T: Text; var Tm: Time)
    begin
        Evaluate(Tm, T);
    end;

    [Test]
    procedure Evaluate_Time_FromDateText()
    var
        Tm: Time;
        Ok: Boolean;
    begin
        Tm := 120000T;
        Ok := Evaluate(Tm, '2021-12-19');
        Observer.Observe('date text bool', Format(Ok) + '|' + Format(Tm, 0, 9));
        Tm := 120000T;
        ClearLastError();
        if TryEvaluateTime('2021-12-19', Tm) then
            Observer.Observe('date text statement', 'no error|' + Format(Tm, 0, 9))
        else
            Observer.ObserveError('date text statement');
        Tm := 120000T;
        Ok := Evaluate(Tm, '2021-12-19', 9);
        Observer.Observe('date text fmt 9', Format(Ok) + '|' + Format(Tm, 0, 9));
        Tm := 120000T;
        Ok := Evaluate(Tm, '12/19/21');
        Observer.Observe('us date text', Format(Ok) + '|' + Format(Tm, 0, 9));
        Observer.Expect('date text bool', 'Yes|20:21:12.19');
        Observer.Expect('date text statement', 'no error|20:21:12.19');
        Observer.Expect('date text fmt 9', 'No|12:00:00');
        Observer.Expect('us date text', 'Yes|12:19:21');
        Observer.Verify();
    end;

    local procedure ObserveJsonString(JKey: Text)
    var
        Obj: JsonObject;
        Tok: JsonToken;
        Val: JsonValue;
        D: Decimal;
        I: Integer;
    begin
        Obj.ReadFrom('{"a":"100.00","b":"4","c":"abc","d":"","e":" 7 ","f":"1e2","g":"-3.5"}');
        Obj.Get(JKey, Tok);
        Val := Tok.AsValue();
        Observer.Observe(JKey + ' AsText', Val.AsText());
        D := -1;
        ClearLastError();
        if TryDecimal(Val, D) then
            Observer.Observe(JKey + ' AsDecimal', 'ok ' + Format(D, 0, 9))
        else
            Observer.Observe(JKey + ' AsDecimal', GetLastErrorText() + '|' + GetLastErrorCode());
        I := -1;
        ClearLastError();
        if TryInteger(Val, I) then
            Observer.Observe(JKey + ' AsInteger', 'ok ' + Format(I))
        else
            Observer.Observe(JKey + ' AsInteger', GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
    end;

    [Test]
    procedure JsonValue_String_100_00_AsDecimalAndInteger()
    begin
        ObserveJsonString('a');
        Observer.Expect('a AsText', '100.00');
        Observer.Expect('a AsDecimal', 'ok 100');
        Observer.Expect('a AsInteger', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Int32.|Conversion');
        Observer.Verify();
    end;

    [Test]
    procedure JsonValue_String_4_AsDecimalAndInteger()
    begin
        ObserveJsonString('b');
        Observer.Expect('b AsText', '4');
        Observer.Expect('b AsDecimal', 'ok 4');
        Observer.Expect('b AsInteger', 'ok 4');
        Observer.Verify();
    end;

    [Test]
    procedure JsonValue_String_Letters_AsDecimalAndInteger()
    begin
        ObserveJsonString('c');
        Observer.Expect('c AsText', 'abc');
        Observer.Expect('c AsDecimal', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.Decimal18.|Conversion');
        Observer.Expect('c AsInteger', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Int32.|Conversion');
        Observer.Verify();
    end;

    [Test]
    procedure JsonValue_String_Empty_AsDecimalAndInteger()
    begin
        ObserveJsonString('d');
        Observer.Expect('d AsText', '');
        Observer.Expect('d AsDecimal', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.Decimal18.|Conversion');
        Observer.Expect('d AsInteger', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Int32.|Conversion');
        Observer.Verify();
    end;

    [Test]
    procedure JsonValue_String_Padded_AsDecimalAndInteger()
    begin
        ObserveJsonString('e');
        Observer.Expect('e AsText', ' 7 ');
        Observer.Expect('e AsDecimal', 'ok 7');
        Observer.Expect('e AsInteger', 'ok 7');
        Observer.Verify();
    end;

    [Test]
    procedure JsonValue_String_Exponent_AsDecimalAndInteger()
    begin
        ObserveJsonString('f');
        Observer.Expect('f AsText', '1e2');
        Observer.Expect('f AsDecimal', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.Decimal18.|Conversion');
        Observer.Expect('f AsInteger', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Int32.|Conversion');
        Observer.Verify();
    end;

    [Test]
    procedure JsonValue_String_Negative_AsDecimalAndInteger()
    begin
        ObserveJsonString('g');
        Observer.Expect('g AsText', '-3.5');
        Observer.Expect('g AsDecimal', 'ok -3.5');
        Observer.Expect('g AsInteger', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Int32.|Conversion');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryDecimal(Val: JsonValue; var D: Decimal)
    begin
        D := Val.AsDecimal();
    end;

    [TryFunction]
    local procedure TryInteger(Val: JsonValue; var I: Integer)
    begin
        I := Val.AsInteger();
    end;

    local procedure ObserveFiller(Kind: Text; FromIndex: Integer; ToIndex: Integer)
    var
        Dt: DateTime;
        D: Date;
        Tm: Time;
        Fmts: List of [Text];
        F: Text;
        Index: Integer;
    begin
        Dt := CreateDateTime(DMY2Date(5, 3, 2024), 090702.123T);
        D := DMY2Date(5, 3, 2024);
        Tm := 090702.123T;
        Fmts.Add('<Filler Character,0>');
        Fmts.Add('<Filler Character,0><Day,4>');
        Fmts.Add('<Day,4><Filler Character,0>');
        Fmts.Add('<Filler Character,0><Day,2><Month,4><Year4>');
        Fmts.Add('<Filler Character,0><Hours24,5><Minutes,5>');
        Fmts.Add('<Filler Character,#><Day,4>');
        Fmts.Add('<Filler Character,*><Hours12,4>');
        Fmts.Add('<Filler Character,0><Standard Format,0>');
        Fmts.Add('<Day,4><Filler Character,0><Month,4>');
        for Index := FromIndex to ToIndex do begin
            F := Fmts.Get(Index);
            case Kind of
                'DateTime':
                    Observer.Observe(F, TryFormat(Dt, F));
                'Date':
                    Observer.Observe(F, TryFormat(D, F));
                'Time':
                    Observer.Observe(F, TryFormat(Tm, F));
            end;
        end;
    end;

    [Test]
    procedure Format_FillerCharacter_OnDateTime()
    begin
        ObserveFiller('DateTime', 1, 9);
        Observer.Expect('<Filler Character,0>', '');
        Observer.Expect('<Filler Character,0><Day,4>', '0005');
        Observer.Expect('<Day,4><Filler Character,0>', '0005');
        Observer.Expect('<Filler Character,0><Day,2><Month,4><Year4>', '0500032024');
        Observer.Expect('<Filler Character,0><Hours24,5><Minutes,5>', '0000900007');
        Observer.Expect('<Filler Character,#><Day,4>', '0005');
        Observer.Expect('<Filler Character,*><Hours12,4>', '0009');
        Observer.Expect('<Filler Character,0><Standard Format,0>', '03/05/24 09:07 AM');
        Observer.Expect('<Day,4><Filler Character,0><Month,4>', '00050003');
        Observer.Verify();
    end;

    [Test]
    procedure Format_FillerCharacter_OnDate_1()
    begin
        ObserveFiller('Date', 1, 5);
        Observer.Finish();
    end;

    [Test]
    procedure Format_FillerCharacter_OnDate_2()
    begin
        ObserveFiller('Date', 6, 9);
        Observer.Finish();
    end;

    [Test]
    procedure Format_FillerCharacter_OnTime_1()
    begin
        ObserveFiller('Time', 1, 5);
        Observer.Finish();
    end;

    [Test]
    procedure Format_FillerCharacter_OnTime_2()
    begin
        ObserveFiller('Time', 6, 9);
        Observer.Finish();
    end;

    local procedure TryFormat(V: Variant; F: Text): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if not TryFormatInner(V, F, Result) then
            exit('err:' + GetLastErrorText() + '|' + GetLastErrorCode());
        exit(Result);
    end;

    [TryFunction]
    local procedure TryFormatInner(V: Variant; F: Text; var Result: Text)
    begin
        Result := Format(V, 0, F);
    end;

    local procedure ObserveRandom(A: Decimal)
    var
        Index: Integer;
        R: Integer;
        MinR: Integer;
        MaxR: Integer;
    begin
        MinR := 1000;
        MaxR := -1000;
        ClearLastError();
        for Index := 1 to 600 do begin
            if not TryRandom(A, R) then begin
                Observer.ObserveError('Random(' + Format(A) + ') at ' + Format(Index));
                break;
            end;
            if R < MinR then
                MinR := R;
            if R > MaxR then
                MaxR := R;
        end;
        Observer.Observe('Random(' + Format(A) + ') min|max', Format(MinR) + '|' + Format(MaxR));
    end;

    [TryFunction]
    local procedure TryRandom(A: Decimal; var R: Integer)
    begin
        R := Random(A);
    end;

    [Test]
    procedure Random_Decimal_0_4()
    begin
        ObserveRandom(0.4);
        Observer.Expect('Random(0.4) at 1|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.4 to System.Int32.');
        Observer.Expect('Random(0.4) at 1|code', 'ConversionCast');
        Observer.Expect('Random(0.4) min|max', '1000|-1000');
        Observer.Verify();
    end;

    [Test]
    procedure Random_Decimal_1_0()
    begin
        ObserveRandom(1.0);
        Observer.Expect('Random(1) min|max', '1|1');
        Observer.Verify();
    end;

    [Test]
    procedure Random_Decimal_1_5()
    begin
        ObserveRandom(1.5);
        Observer.Expect('Random(1.5) at 1|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.5 to System.Int32.');
        Observer.Expect('Random(1.5) at 1|code', 'ConversionCast');
        Observer.Expect('Random(1.5) min|max', '1000|-1000');
        Observer.Verify();
    end;

    [Test]
    procedure Random_Decimal_2_5()
    begin
        ObserveRandom(2.5);
        Observer.Expect('Random(2.5) at 1|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.');
        Observer.Expect('Random(2.5) at 1|code', 'ConversionCast');
        Observer.Expect('Random(2.5) min|max', '1000|-1000');
        Observer.Verify();
    end;

    [Test]
    procedure Random_Decimal_2_9()
    begin
        ObserveRandom(2.9);
        Observer.Expect('Random(2.9) at 1|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.9 to System.Int32.');
        Observer.Expect('Random(2.9) at 1|code', 'ConversionCast');
        Observer.Expect('Random(2.9) min|max', '1000|-1000');
        Observer.Verify();
    end;

    [Test]
    procedure Random_Decimal_3_0()
    begin
        ObserveRandom(3.0);
        Observer.Expect('Random(3) min|max', '1|3');
        Observer.Verify();
    end;
}
