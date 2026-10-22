// Batch 7 probes: Format and Evaluate of an enum, Evaluate of a DateFormula with other formats, InitValue of a DateFormula field. Observe only.
codeunit 68529 "W7 Evaluate Probes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Members(): List of [Integer]
    var
        Result: List of [Integer];
    begin
        Result.Add(0);
        Result.Add(5);
        Result.Add(10);
        exit(Result);
    end;

    [Test]
    procedure FormatOfAnEnum_AllFormatNumbers()
    var
        Observer: Codeunit "Probe Observer";
        Mixed: Enum "W7 Mixed";
        Ordinal: Integer;
    begin
        foreach Ordinal in Members() do begin
            Mixed := "W7 Mixed".FromInteger(Ordinal);
            Observer.Observe('format ' + Format(Ordinal), Format(Mixed));
            Observer.Observe('format 0 ' + Format(Ordinal), Format(Mixed, 0, 0));
            Observer.Observe('format 1 ' + Format(Ordinal), Format(Mixed, 0, 1));
            Observer.Observe('format 2 ' + Format(Ordinal), Format(Mixed, 0, 2));
            Observer.Observe('format 9 ' + Format(Ordinal), Format(Mixed, 0, 9));
            Observer.Observe('format length 6 ' + Format(Ordinal), Format(Mixed, 6));
        end;
        Observer.Observe('format of an unknown ordinal', Format("W7 Mixed".FromInteger(3), 0, 9));
        Observer.Expect('format 0', 'First One');
        Observer.Expect('format 0 0', 'First One');
        Observer.Expect('format 1 0', 'First One');
        Observer.Expect('format 2 0', '0');
        Observer.Expect('format 9 0', '0');
        Observer.Expect('format length 6 0', 'First ');
        Observer.Expect('format 5', 'Second');
        Observer.Expect('format 0 5', 'Second');
        Observer.Expect('format 1 5', 'Second');
        Observer.Expect('format 2 5', '5');
        Observer.Expect('format 9 5', '5');
        Observer.Expect('format length 6 5', 'Second');
        Observer.Expect('format 10', 'third');
        Observer.Expect('format 0 10', 'third');
        Observer.Expect('format 1 10', 'third');
        Observer.Expect('format 2 10', '10');
        Observer.Expect('format 9 10', '10');
        Observer.Expect('format length 6 10', 'third ');
        Observer.Expect('format of an unknown ordinal', '3');
        Observer.Verify();
    end;

    local procedure Texts(): List of [Text]
    var
        Result: List of [Text];
    begin
        Result.Add('First One');
        Result.Add('first one');
        Result.Add('FIRST ONE');
        Result.Add('Second');
        Result.Add('second');
        Result.Add('third');
        Result.Add('Third');
        Result.Add('5');
        Result.Add('0');
        Result.Add('10');
        Result.Add('3');
        Result.Add('-1');
        Result.Add(' Second ');
        Result.Add('');
        Result.Add('Nope');
        exit(Result);
    end;

    [Test]
    procedure EvaluateIntoAnEnum_DefaultFormat()
    var
        Observer: Codeunit "Probe Observer";
        Mixed: Enum "W7 Mixed";
        Text: Text;
        Ok: Boolean;
    begin
        foreach Text in Texts() do begin
            Mixed := "W7 Mixed".FromInteger(5);
            Ok := Evaluate(Mixed, Text);
            Observer.Observe('[' + Text + ']', Format(Ok) + ' ' + Format(Mixed, 0, 9));
        end;
        Observer.Expect('[First One]', 'Yes 0');
        Observer.Expect('[first one]', 'Yes 0');
        Observer.Expect('[FIRST ONE]', 'Yes 0');
        Observer.Expect('[Second]', 'Yes 5');
        Observer.Expect('[second]', 'Yes 5');
        Observer.Expect('[third]', 'Yes 10');
        Observer.Expect('[Third]', 'Yes 10');
        Observer.Expect('[5]', 'Yes 5');
        Observer.Expect('[0]', 'Yes 0');
        Observer.Expect('[10]', 'Yes 10');
        Observer.Expect('[3]', 'Yes 3');
        Observer.Expect('[-1]', 'No 5');
        Observer.Expect('[ Second ]', 'Yes 5');
        Observer.Expect('[]', 'No 5');
        Observer.Expect('[Nope]', 'No 5');
        Observer.Verify();
    end;

    [Test]
    procedure EvaluateIntoAnEnum_Format9()
    var
        Observer: Codeunit "Probe Observer";
        Mixed: Enum "W7 Mixed";
        Text: Text;
        Ok: Boolean;
    begin
        foreach Text in Texts() do begin
            Mixed := "W7 Mixed".FromInteger(5);
            Ok := Evaluate(Mixed, Text, 9);
            Observer.Observe('[' + Text + ']', Format(Ok) + ' ' + Format(Mixed, 0, 9));
        end;
        Observer.Expect('[First One]', 'Yes 0');
        Observer.Expect('[first one]', 'Yes 0');
        Observer.Expect('[FIRST ONE]', 'Yes 0');
        Observer.Expect('[Second]', 'Yes 5');
        Observer.Expect('[second]', 'Yes 5');
        Observer.Expect('[third]', 'Yes 10');
        Observer.Expect('[Third]', 'Yes 10');
        Observer.Expect('[5]', 'Yes 5');
        Observer.Expect('[0]', 'Yes 0');
        Observer.Expect('[10]', 'Yes 10');
        Observer.Expect('[3]', 'Yes 3');
        Observer.Expect('[-1]', 'No 5');
        Observer.Expect('[ Second ]', 'Yes 5');
        Observer.Expect('[]', 'No 5');
        Observer.Expect('[Nope]', 'No 5');
        Observer.Verify();
    end;

    [Test]
    procedure EvaluateIntoAnEnum_RoundTripOfFormatNine()
    var
        Observer: Codeunit "Probe Observer";
        Mixed: Enum "W7 Mixed";
        Back: Enum "W7 Mixed";
        Ordinal: Integer;
        Ok: Boolean;
    begin
        foreach Ordinal in Members() do begin
            Mixed := "W7 Mixed".FromInteger(Ordinal);
            Ok := Evaluate(Back, Format(Mixed, 0, 9), 9);
            Observer.Observe('format 9 then evaluate 9, member ' + Format(Ordinal), Format(Ok) + ' ' + Format(Back.AsInteger()));
            Ok := Evaluate(Back, Format(Mixed, 0, 9));
            Observer.Observe('format 9 then evaluate default, member ' + Format(Ordinal), Format(Ok) + ' ' + Format(Back.AsInteger()));
            Ok := Evaluate(Back, Format(Mixed));
            Observer.Observe('format default then evaluate default, member ' + Format(Ordinal), Format(Ok) + ' ' + Format(Back.AsInteger()));
        end;
        Observer.Expect('format 9 then evaluate 9, member 0', 'Yes 0');
        Observer.Expect('format 9 then evaluate default, member 0', 'Yes 0');
        Observer.Expect('format default then evaluate default, member 0', 'Yes 0');
        Observer.Expect('format 9 then evaluate 9, member 5', 'Yes 5');
        Observer.Expect('format 9 then evaluate default, member 5', 'Yes 5');
        Observer.Expect('format default then evaluate default, member 5', 'Yes 5');
        Observer.Expect('format 9 then evaluate 9, member 10', 'Yes 10');
        Observer.Expect('format 9 then evaluate default, member 10', 'Yes 10');
        Observer.Expect('format default then evaluate default, member 10', 'Yes 10');
        Observer.Verify();
    end;

    local procedure DateFormulaTexts(): List of [Text]
    var
        Result: List of [Text];
    begin
        Result.Add('1D');
        Result.Add('1T');
        Result.Add('1J');
        Result.Add('1A');
        Result.Add('1M');
        Result.Add('1W');
        Result.Add('1WD');
        Result.Add('CM');
        Result.Add('GM');
        Result.Add('<1D>');
        Result.Add('<1T>');
        Result.Add('1Y');
        exit(Result);
    end;

    local procedure DateFormulaResult(Text: Text; FormatNumber: Integer): Text
    var
        Formula: DateFormula;
        Ok: Boolean;
    begin
        case FormatNumber of
            0:
                Ok := Evaluate(Formula, Text);
            2:
                Ok := Evaluate(Formula, Text, 2);
            9:
                Ok := Evaluate(Formula, Text, 9);
        end;
        if not Ok then
            exit('false');
        exit('true ' + Format(Formula) + ' | ' + Format(Formula, 0, 9) + ' | ' + Format(CalcDate(Formula, DMY2Date(15, 3, 2024)), 0, 9));
    end;

    [Test]
    procedure EvaluateDateFormula_Format2_NonEnglishFormulas()
    var
        Observer: Codeunit "Probe Observer";
        Text: Text;
    begin
        foreach Text in DateFormulaTexts() do
            Observer.Observe('format 2 [' + Text + ']', DateFormulaResult(Text, 2));
        Observer.Expect('format 2 [1D]', 'true 1D | 1D | 2024-03-16');
        Observer.Expect('format 2 [1T]', 'false');
        Observer.Expect('format 2 [1J]', 'false');
        Observer.Expect('format 2 [1A]', 'false');
        Observer.Expect('format 2 [1M]', 'true 1M | 1M | 2024-04-15');
        Observer.Expect('format 2 [1W]', 'true 1W | 1W | 2024-03-22');
        Observer.Expect('format 2 [1WD]', 'true 1WD | 1WD | 2024-03-16');
        Observer.Expect('format 2 [CM]', 'true CM | CM | 2024-03-31');
        Observer.Expect('format 2 [GM]', 'false');
        Observer.Expect('format 2 [<1D>]', 'true 1D | 1D | 2024-03-16');
        Observer.Expect('format 2 [<1T>]', 'false');
        Observer.Expect('format 2 [1Y]', 'true 1Y | 1Y | 2025-03-15');
        Observer.Verify();
    end;

    [Test]
    procedure EvaluateDateFormula_Format0AndFormat9_NonEnglishFormulas()
    var
        Observer: Codeunit "Probe Observer";
        Text: Text;
    begin
        foreach Text in DateFormulaTexts() do begin
            Observer.Observe('format 0 [' + Text + ']', DateFormulaResult(Text, 0));
            Observer.Observe('format 9 [' + Text + ']', DateFormulaResult(Text, 9));
        end;
        Observer.Expect('format 0 [1D]', 'true 1D | 1D | 2024-03-16');
        Observer.Expect('format 9 [1D]', 'true 1D | 1D | 2024-03-16');
        Observer.Expect('format 0 [1T]', 'false');
        Observer.Expect('format 9 [1T]', 'false');
        Observer.Expect('format 0 [1J]', 'false');
        Observer.Expect('format 9 [1J]', 'false');
        Observer.Expect('format 0 [1A]', 'false');
        Observer.Expect('format 9 [1A]', 'false');
        Observer.Expect('format 0 [1M]', 'true 1M | 1M | 2024-04-15');
        Observer.Expect('format 9 [1M]', 'true 1M | 1M | 2024-04-15');
        Observer.Expect('format 0 [1W]', 'true 1W | 1W | 2024-03-22');
        Observer.Expect('format 9 [1W]', 'true 1W | 1W | 2024-03-22');
        Observer.Expect('format 0 [1WD]', 'true 1WD | 1WD | 2024-03-16');
        Observer.Expect('format 9 [1WD]', 'true 1WD | 1WD | 2024-03-16');
        Observer.Expect('format 0 [CM]', 'true CM | CM | 2024-03-31');
        Observer.Expect('format 9 [CM]', 'true CM | CM | 2024-03-31');
        Observer.Expect('format 0 [GM]', 'false');
        Observer.Expect('format 9 [GM]', 'false');
        Observer.Expect('format 0 [<1D>]', 'true 1D | 1D | 2024-03-16');
        Observer.Expect('format 9 [<1D>]', 'true 1D | 1D | 2024-03-16');
        Observer.Expect('format 0 [<1T>]', 'false');
        Observer.Expect('format 9 [<1T>]', 'false');
        Observer.Expect('format 0 [1Y]', 'true 1Y | 1Y | 2025-03-15');
        Observer.Expect('format 9 [1Y]', 'true 1Y | 1Y | 2025-03-15');
        Observer.Verify();
    end;

    local procedure FieldText(Formula: DateFormula): Text
    begin
        exit('[' + Format(Formula) + '] [' + Format(Formula, 0, 9) + '] ' + Format(CalcDate(Formula, DMY2Date(15, 3, 2024)), 0, 9));
    end;

    [Test]
    procedure InitValueOfADateFormulaField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W7 DF Row";
    begin
        Row.Init();
        Observer.Observe('1Y', FieldText(Row.F1Y));
        Observer.Observe('<1M>', FieldText(Row.F1MBrackets));
        Observer.Observe('CM', FieldText(Row.FCM));
        Observer.Observe('no InitValue', FieldText(Row.FNone));
        Observer.Observe('empty InitValue', FieldText(Row.FEmptyInit));
        Observer.Observe('1D', FieldText(Row.F1D));
        Observer.Observe('-1D', FieldText(Row.FNegative));
        Observer.Observe('1D+1W', FieldText(Row.FMixed));
        Observer.Observe('1d', FieldText(Row.FLower));
        Observer.Observe('spaces around 1D', FieldText(Row.FSpaces));
        Observer.Observe('<-CM+1D>', FieldText(Row.FCombined));
        Observer.Expect('1Y', '[1Y] [1Y] 2025-03-15');
        Observer.Expect('<1M>', '[1M] [1M] 2024-04-15');
        Observer.Expect('CM', '[CM] [CM] 2024-03-31');
        Observer.Expect('no InitValue', '[] [] 2024-03-15');
        Observer.Expect('empty InitValue', '[] [] 2024-03-15');
        Observer.Expect('1D', '[1D] [1D] 2024-03-16');
        Observer.Expect('-1D', '[-1D] [-1D] 2024-03-14');
        Observer.Expect('1D+1W', '[1D+1W] [1D+1W] 2024-03-23');
        Observer.Expect('1d', '[1D] [1D] 2024-03-16');
        Observer.Expect('spaces around 1D', '[1D] [1D] 2024-03-16');
        Observer.Expect('<-CM+1D>', '[-CM+1D] [-CM+1D] 2024-03-02');
        Observer.Verify();
    end;

    [Test]
    procedure InitValueOfADateFormulaField_TemporaryRecordAndClear()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W7 DF Row" temporary;
    begin
        Observer.Observe('before Init, 1Y', FieldText(Row.F1Y));
        Row.Init();
        Observer.Observe('after Init, 1Y', FieldText(Row.F1Y));
        Clear(Row.F1Y);
        Observer.Observe('after Clear of the field, 1Y', FieldText(Row.F1Y));
        Clear(Row);
        Observer.Observe('after Clear of the record, 1Y', FieldText(Row.F1Y));
        Row.Init();
        Row.Validate(F1Y);
        Observer.Observe('after Validate, 1Y', FieldText(Row.F1Y));
        Observer.Expect('before Init, 1Y', '[1Y] [1Y] 2025-03-15');
        Observer.Expect('after Init, 1Y', '[1Y] [1Y] 2025-03-15');
        Observer.Expect('after Clear of the field, 1Y', '[] [] 2024-03-15');
        Observer.Expect('after Clear of the record, 1Y', '[1Y] [1Y] 2025-03-15');
        Observer.Expect('after Validate, 1Y', '[1Y] [1Y] 2025-03-15');
        Observer.Verify();
    end;
}
