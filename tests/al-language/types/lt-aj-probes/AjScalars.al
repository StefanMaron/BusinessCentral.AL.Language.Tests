// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Facts: Evaluate into a Decimal for texts with letters or a slash (result, variable, error text and code); Evaluate of a date text into a Time; JsonValue.AsDecimal / AsInteger on JSON strings; Format with <Filler Character,0> on Date, Time and DateTime; Random with a Decimal argument (range only).
// BC versions: 27.5+

codeunit 79000 "LT AJ Scalars"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Evaluate_Decimal_TextWithLetters()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
        Ok: Boolean;
        Texts: List of [Text];
        T: Text;
    begin
        Texts.Add('New/Updated');
        Texts.Add('12/5');
        Texts.Add('abc1');
        Texts.Add('1abc');
        Texts.Add('1/2');
        Texts.Add('5-');
        foreach T in Texts do begin
            D := 99;
            Ok := Evaluate(D, T);
            Observer.Observe(T + ' bool', Format(Ok) + '|' + Format(D));
            D := 99;
            asserterror Evaluate(D, T);
            Observer.ObserveError(T);
            Observer.Observe(T + ' value after', Format(D));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Evaluate_Time_FromDateText()
    var
        Observer: Codeunit "Probe Observer";
        Tm: Time;
        Ok: Boolean;
    begin
        Tm := 120000T;
        Ok := Evaluate(Tm, '2021-12-19');
        Observer.Observe('date text bool', Format(Ok) + '|' + Format(Tm, 0, 9));
        Tm := 120000T;
        asserterror Evaluate(Tm, '2021-12-19');
        Observer.ObserveError('date text');
        Tm := 120000T;
        Ok := Evaluate(Tm, '2021-12-19', 9);
        Observer.Observe('date text fmt 9', Format(Ok) + '|' + Format(Tm, 0, 9));
        Tm := 120000T;
        Ok := Evaluate(Tm, '12/19/21');
        Observer.Observe('us date text', Format(Ok) + '|' + Format(Tm, 0, 9));
        Observer.Finish();
    end;

    [Test]
    procedure JsonValue_StringAsDecimalAndInteger()
    var
        Observer: Codeunit "Probe Observer";
        Obj: JsonObject;
        Tok: JsonToken;
        Val: JsonValue;
        D: Decimal;
        I: Integer;
        JKey: Text;
        JKeys: List of [Text];
    begin
        Obj.ReadFrom('{"a":"100.00","b":"4","c":"abc","d":"","e":" 7 ","f":"1e2","g":"-3.5"}');
        JKeys.Add('a');
        JKeys.Add('b');
        JKeys.Add('c');
        JKeys.Add('d');
        JKeys.Add('e');
        JKeys.Add('f');
        JKeys.Add('g');
        foreach JKey in JKeys do begin
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
        end;
        ClearLastError();
        Observer.Finish();
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

    [Test]
    procedure Format_FillerCharacter_DateTimeDateTime()
    var
        Observer: Codeunit "Probe Observer";
        Dt: DateTime;
        D: Date;
        Tm: Time;
        Fmts: List of [Text];
        F: Text;
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
        foreach F in Fmts do begin
            Observer.Observe('dt ' + F, TryFormat(Dt, F));
            Observer.Observe('date ' + F, TryFormat(D, F));
            Observer.Observe('time ' + F, TryFormat(Tm, F));
        end;
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

    [Test]
    procedure Random_DecimalArgument_RangeOnly()
    var
        Observer: Codeunit "Probe Observer";
        Args: List of [Decimal];
        A: Decimal;
        Index: Integer;
        R: Integer;
        MinR: Integer;
        MaxR: Integer;
    begin
        Args.Add(0.4);
        Args.Add(0.6);
        Args.Add(1.0);
        Args.Add(1.4);
        Args.Add(1.5);
        Args.Add(1.6);
        Args.Add(2.5);
        Args.Add(2.9);
        foreach A in Args do begin
            MinR := 1000;
            MaxR := -1000;
            for Index := 1 to 600 do begin
                R := Random(A);
                if R < MinR then
                    MinR := R;
                if R > MaxR then
                    MaxR := R;
            end;
            Observer.Observe('Random(' + Format(A) + ') min|max', Format(MinR) + '|' + Format(MaxR));
        end;
        Observer.Finish();
    end;
}
