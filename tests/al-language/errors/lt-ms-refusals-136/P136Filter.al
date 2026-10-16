// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 74333
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.SetFilter with a literal text (no %1 argument) on Date, DateFormula, Time and DateTime fields: empty text, the blank filter '', <>'', a formula such as 1M, a date in other spellings; observed by Count and GetFilter, or by the error
// BC versions: 29 (27 and 28 by CI)

table 74333 "LT P136 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; D; Date) { }
        field(3; DF; DateFormula) { }
        field(4; T; Time) { }
        field(5; DT; DateTime) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74334 "LT P136 Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT P136 Row";
    begin
        R.DeleteAll();
        R.Init();
        R.Id := 1;
        R.D := 20240101D;
        Evaluate(R.DF, '<1M>');
        R.T := 080000T;
        R.DT := CreateDateTime(20240101D, 080000T);
        R.Insert();
        R.Init();
        R.Id := 2;
        R.D := 20240115D;
        Evaluate(R.DF, '<1D>');
        R.T := 120000T;
        R.DT := CreateDateTime(20240115D, 120000T);
        R.Insert();
        R.Init();
        R.Id := 3;
        R.Insert();
        R.Init();
        R.Id := 4;
        R.D := 20240229D;
        Evaluate(R.DF, '<1M>');
        R.T := 235959T;
        R.DT := CreateDateTime(20240229D, 235959T);
        R.Insert();
    end;

    [TryFunction]
    local procedure TryD(Txt: Text; var Outcome: Text)
    var
        R: Record "LT P136 Row";
    begin
        R.SetFilter(D, Txt);
        Outcome := Format(R.Count()) + '|' + R.GetFilter(D);
    end;

    [TryFunction]
    local procedure TryDOnly(Txt: Text)
    var
        R: Record "LT P136 Row";
        N: Integer;
    begin
        R.SetFilter(D, Txt);
        N := R.Count();
    end;

    [TryFunction]
    local procedure TryDF(Txt: Text; var Outcome: Text)
    var
        R: Record "LT P136 Row";
    begin
        R.SetFilter(DF, Txt);
        Outcome := Format(R.Count()) + '|' + R.GetFilter(DF);
    end;

    [TryFunction]
    local procedure TryT(Txt: Text; var Outcome: Text)
    var
        R: Record "LT P136 Row";
    begin
        R.SetFilter(T, Txt);
        Outcome := Format(R.Count()) + '|' + R.GetFilter(T);
    end;

    [TryFunction]
    local procedure TryDT(Txt: Text; var Outcome: Text)
    var
        R: Record "LT P136 Row";
    begin
        R.SetFilter(DT, Txt);
        Outcome := Format(R.Count()) + '|' + R.GetFilter(DT);
    end;

    local procedure FD(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        O: Text;
    begin
        if TryD(Txt, O) then
            Observer.Observe(Name, O)
        else
            Observer.ObserveError(Name);
    end;

    local procedure FDOnly(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    begin
        if TryDOnly(Txt) then
            Observer.Observe(Name, 'ok')
        else
            Observer.ObserveError(Name);
    end;

    local procedure FDF(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        O: Text;
    begin
        if TryDF(Txt, O) then
            Observer.Observe(Name, O)
        else
            Observer.ObserveError(Name);
    end;

    local procedure FT(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        O: Text;
    begin
        if TryT(Txt, O) then
            Observer.Observe(Name, O)
        else
            Observer.ObserveError(Name);
    end;

    local procedure FDT(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        O: Text;
    begin
        if TryDT(Txt, O) then
            Observer.Observe(Name, O)
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure P136_SetFilter_Date_BlankAndFormulaText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        FD(Observer, 'empty', '');
        FD(Observer, 'blankQuotes', '''''');
        FD(Observer, 'notBlankQuotes', '<>''''');
        FD(Observer, 'blankSpace', ' ');
        FD(Observer, 'zeroD', '0D');
        FD(Observer, 'oneM', '1M');
        FD(Observer, 'oneMAngles', '<1M>');
        FD(Observer, 'geOneM', '>=1M');
        FD(Observer, 'minusOneD', '-1D');
        FD(Observer, 'garbage', 'x');
        FD(Observer, 'dotsOnly', '..');
        FD(Observer, 'upTo', '..150124');
        FD(Observer, 'from', '150124..');
        FD(Observer, 'notEqual', '<>150124');
        FD(Observer, 'lt', '<150124');
        FD(Observer, 'or', '010124|290224');
        FD(Observer, 'andRange', '>=010124&<=150124');
        Observer.Expect('empty', '4|');
        Observer.Expect('blankQuotes', '1|''''');
        Observer.Expect('notBlankQuotes', '3|<>''''');
        Observer.Expect('blankSpace', '4|');
        Observer.Expect('zeroD', '0|10/16/26');
        Observer.Expect('oneM', '0|10/01/26');
        Observer.Expect('oneMAngles', '0|11/16/26');
        Observer.Expect('geOneM', '0|>=10/01/26');
        Observer.Expect('minusOneD', '0|10/15/26');
        Observer.Expect('garbage|text', 'The filter "x" is not valid for the D field on the LT P136 Row table. The format of the Date ''x'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('garbage|code', 'Filter:CSide');
        Observer.Expect('dotsOnly|text', 'The filter ".." is not valid for the D field on the LT P136 Row table. Both sides of the range (''..'') cannot be empty.');
        Observer.Expect('dotsOnly|code', 'Filter:CSide');
        Observer.Expect('upTo|text', 'The filter "..150124" is not valid for the D field on the LT P136 Row table. The format of the Date ''150124'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('upTo|code', 'Filter:CSide');
        Observer.Expect('from|text', 'The filter "150124.." is not valid for the D field on the LT P136 Row table. The format of the Date ''150124'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('from|code', 'Filter:CSide');
        Observer.Expect('notEqual|text', 'The filter "<>150124" is not valid for the D field on the LT P136 Row table. The format of the Date ''150124'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('notEqual|code', 'Filter:CSide');
        Observer.Expect('lt|text', 'The filter "<150124" is not valid for the D field on the LT P136 Row table. The format of the Date ''150124'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('lt|code', 'Filter:CSide');
        Observer.Expect('or|text', 'The filter "010124|290224" is not valid for the D field on the LT P136 Row table. The format of the Date ''290224'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('or|code', 'Filter:CSide');
        Observer.Expect('andRange|text', 'The filter ">=010124&<=150124" is not valid for the D field on the LT P136 Row table. The format of the Date ''150124'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('andRange|code', 'Filter:CSide');
        Observer.Verify();
    end;





    [Test]
    procedure P136_SetFilter_Date_Spellings()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        FD(Observer, 'ddmmyy', '010124');
        FD(Observer, 'ddmmyyyy', '01012024');
        FD(Observer, 'yyyymmdd', '20240101');
        FD(Observer, 'dotsShortYear', '1.1.24');
        FD(Observer, 'dotsFull', '15.01.2024');
        FD(Observer, 'slashes', '1/15/24');
        FD(Observer, 'slashesFull', '01/15/2024');
        FD(Observer, 'dashesIso', '2024-01-15');
        FD(Observer, 'dashesDmy', '15-01-24');
        FD(Observer, 'withDay', 'Mon');
        FD(Observer, 'monthName', '15 Jan 2024');
        FD(Observer, 'textMonth', 'January 15, 2024');
        FD(Observer, 'tooLarge', '320124');
        FD(Observer, 'badMonth', '011324');
        FD(Observer, 'leapDay', '290224');
        FD(Observer, 'nonLeap', '290223');
        FD(Observer, 'year1', '010101');
        FD(Observer, 'year99', '010199');
        Observer.Expect('ddmmyy', '1|01/01/24');
        Observer.Expect('ddmmyyyy', '1|01/01/24');
        Observer.Expect('yyyymmdd|text', 'The filter "20240101" is not valid for the D field on the LT P136 Row table. The format of the Date ''20240101'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('yyyymmdd|code', 'Filter:CSide');
        Observer.Expect('dotsShortYear', '1|01/01/24');
        Observer.Expect('dotsFull|text', 'The filter "15.01.2024" is not valid for the D field on the LT P136 Row table. The format of the Date ''15.01.2024'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('dotsFull|code', 'Filter:CSide');
        Observer.Expect('slashes', '1|01/15/24');
        Observer.Expect('slashesFull', '1|01/15/24');
        Observer.Expect('dashesIso', '1|01/15/24');
        Observer.Expect('dashesDmy|text', 'The filter "15-01-24" is not valid for the D field on the LT P136 Row table. The format of the Date ''15-01-24'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('dashesDmy|code', 'Filter:CSide');
        Observer.Expect('withDay', '0|09/28/26');
        Observer.Expect('monthName', '1|01/15/24');
        Observer.Expect('textMonth|text', 'The filter "January 15, 2024" is not valid for the D field on the LT P136 Row table. The format of the Date ''January 15, 2024'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('textMonth|code', 'Filter:CSide');
        Observer.Expect('tooLarge|text', 'The filter "320124" is not valid for the D field on the LT P136 Row table. The format of the Date ''320124'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('tooLarge|code', 'Filter:CSide');
        Observer.Expect('badMonth', '0|01/13/24');
        Observer.Expect('leapDay|text', 'The filter "290224" is not valid for the D field on the LT P136 Row table. The format of the Date ''290224'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('leapDay|code', 'Filter:CSide');
        Observer.Expect('nonLeap|text', 'The filter "290223" is not valid for the D field on the LT P136 Row table. The format of the Date ''290223'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('nonLeap|code', 'Filter:CSide');
        Observer.Expect('year1', '0|01/01/01');
        Observer.Expect('year99', '0|01/01/99');
        Observer.Verify();
    end;





    [Test]
    procedure P136_SetFilter_Date_TodayFormulas()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        FDOnly(Observer, 'T', 'T');
        FDOnly(Observer, 'W', 'W');
        FDOnly(Observer, 'CM', 'CM');
        FDOnly(Observer, 'CW', 'CW');
        FDOnly(Observer, 'CY', 'CY');
        FDOnly(Observer, 'CQ', 'CQ');
        FDOnly(Observer, 'lowerT', 't');
        FDOnly(Observer, 'tPlus', 'T+1D');
        FDOnly(Observer, 'tAngles', '<T>');
        FDOnly(Observer, 'cmAngles', '<CM>');
        FDOnly(Observer, 'cmRange', '<CM-1M>..<CM>');
        FDOnly(Observer, 'geT', '>=T');
        FDOnly(Observer, 'oneMDot', '..1M');
        FDOnly(Observer, 'oneDOnly', '1D');
        FDOnly(Observer, 'plusOneD', '+1D');
        FDOnly(Observer, 'plusOneDAngles', '<+1D>');
        FDOnly(Observer, 'angleOpenOnly', '<+1D');
        Observer.Expect('T', 'ok');
        Observer.Expect('W', 'ok');
        Observer.Expect('CM', 'ok');
        Observer.Expect('CW', 'ok');
        Observer.Expect('CY', 'ok');
        Observer.Expect('CQ', 'ok');
        Observer.Expect('lowerT', 'ok');
        Observer.Expect('tPlus', 'ok');
        Observer.Expect('tAngles|text', 'The filter "<T>" is not valid for the D field on the LT P136 Row table. An error occurred while interpreting the filter: Did not expect ''>''.\\For more information, see https://go.microsoft.com/fwlink/?linkid=2158058.');
        Observer.Expect('tAngles|code', 'Filter:CSide');
        Observer.Expect('cmAngles', 'ok');
        Observer.Expect('cmRange', 'ok');
        Observer.Expect('geT', 'ok');
        Observer.Expect('oneMDot', 'ok');
        Observer.Expect('oneDOnly', 'ok');
        Observer.Expect('plusOneD', 'ok');
        Observer.Expect('plusOneDAngles', 'ok');
        Observer.Expect('angleOpenOnly', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure P136_SetFilter_DateFormula()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        FDF(Observer, 'empty', '');
        FDF(Observer, 'blankQuotes', '''''');
        FDF(Observer, 'notBlankQuotes', '<>''''');
        FDF(Observer, 'oneM', '1M');
        FDF(Observer, 'oneMAngles', '<1M>');
        FDF(Observer, 'oneD', '1D');
        FDF(Observer, 'oneDAngles', '<1D>');
        FDF(Observer, 'notOneM', '<>1M');
        FDF(Observer, 'geOneD', '>=1D');
        FDF(Observer, 'orBoth', '1M|1D');
        FDF(Observer, 'range', '1D..1M');
        FDF(Observer, 'cm', 'CM');
        FDF(Observer, 'garbage', 'x');
        FDF(Observer, 'zero', '0D');
        FDF(Observer, 'lowerM', '1m');
        FDF(Observer, 'twoMonths', '2M');
        FDF(Observer, 'angleOpenOnly', '<1M');
        FDF(Observer, 'blankSpace', ' ');
        FDF(Observer, 'plusOneM', '+1M');
        FDF(Observer, 'wildcard', '*');
        FDF(Observer, 'wildcardM', '*M');
        Observer.Expect('empty', '4|');
        Observer.Expect('blankQuotes', '1|''''');
        Observer.Expect('notBlankQuotes', '3|<>''''');
        Observer.Expect('oneM', '2|1M');
        Observer.Expect('oneMAngles|text', 'The filter "<1M>" is not valid for the DF field on the LT P136 Row table. An error occurred while interpreting the filter: Did not expect ''>''.\\For more information, see https://go.microsoft.com/fwlink/?linkid=2158058.');
        Observer.Expect('oneMAngles|code', 'Filter:CSide');
        Observer.Expect('oneD', '1|1D');
        Observer.Expect('oneDAngles|text', 'The filter "<1D>" is not valid for the DF field on the LT P136 Row table. An error occurred while interpreting the filter: Did not expect ''>''.\\For more information, see https://go.microsoft.com/fwlink/?linkid=2158058.');
        Observer.Expect('oneDAngles|code', 'Filter:CSide');
        Observer.Expect('notOneM', '2|<>1M');
        Observer.Expect('geOneD', '3|>=1D');
        Observer.Expect('orBoth', '2|1M|1D');
        Observer.Expect('range', '3|1D..1M');
        Observer.Expect('cm', '0|CM');
        Observer.Expect('garbage|text', 'The filter "x" is not valid for the DF field on the LT P136 Row table. The date formula ''X'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Observer.Expect('garbage|code', 'Filter:CSide');
        Observer.Expect('zero', '0|0D');
        Observer.Expect('lowerM', '2|1M');
        Observer.Expect('twoMonths', '0|2M');
        Observer.Expect('angleOpenOnly', '2|<1M');
        Observer.Expect('blankSpace', '4|');
        Observer.Expect('plusOneM', '0|+1M');
        Observer.Expect('wildcard', '1|''''');
        Observer.Expect('wildcardM|text', 'The filter "*M" is not valid for the DF field on the LT P136 Row table. The date formula ''*M'' should include a number.');
        Observer.Expect('wildcardM|code', 'Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure P136_SetFilter_Time_And_DateTime()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        FT(Observer, 'tEmpty', '');
        FT(Observer, 'tBlankQuotes', '''''');
        FT(Observer, 'tNotBlank', '<>''''');
        FT(Observer, 'tHms', '08:00:00');
        FT(Observer, 'tHm', '08:00');
        FT(Observer, 'tH', '8:00');
        FT(Observer, 'tCompact', '080000');
        FT(Observer, 'tRange', '08:00..12:00');
        FT(Observer, 'tGe', '>=12:00:00');
        FT(Observer, 'tGarbage', 'x');
        FT(Observer, 'tAmPm', '8:00 AM');
        FT(Observer, 'tFormula', '1H');
        FDT(Observer, 'dtEmpty', '');
        FDT(Observer, 'dtBlankQuotes', '''''');
        FDT(Observer, 'dtNotBlank', '<>''''');
        FDT(Observer, 'dtDateOnly', '010124');
        FDT(Observer, 'dtDateTime', '010124 080000');
        FDT(Observer, 'dtDotted', '01.01.2024 08:00:00');
        FDT(Observer, 'dtIso', '2024-01-01T08:00:00');
        FDT(Observer, 'dtRange', '010124..150124');
        FDT(Observer, 'dtGarbage', 'x');
        FDT(Observer, 'dtFormula', '1M');
        Observer.Expect('tEmpty', '4|');
        Observer.Expect('tBlankQuotes', '1|''''');
        Observer.Expect('tNotBlank', '3|<>''''');
        Observer.Expect('tHms', '1| 8:00:00 AM');
        Observer.Expect('tHm', '1| 8:00:00 AM');
        Observer.Expect('tH', '1| 8:00:00 AM');
        Observer.Expect('tCompact', '1| 8:00:00 AM');
        Observer.Expect('tRange', '2| 8:00:00 AM..12:00:00 PM');
        Observer.Expect('tGe', '2|>=12:00:00 PM');
        Observer.Expect('tGarbage|text', 'The filter "x" is not valid for the T field on the LT P136 Row table. The value "x" can''t be evaluated into type Time.');
        Observer.Expect('tGarbage|code', 'Filter:CSide');
        Observer.Expect('tAmPm', '1| 8:00:00 AM');
        Observer.Expect('tFormula|text', 'The filter "1H" is not valid for the T field on the LT P136 Row table. The value "1H" can''t be evaluated into type Time.');
        Observer.Expect('tFormula|code', 'Filter:CSide');
        Observer.Expect('dtEmpty', '4|');
        Observer.Expect('dtBlankQuotes', '1|''''..''''');
        Observer.Expect('dtNotBlank', '3|<>''''');
        Observer.Expect('dtDateOnly', '1|01/01/24 12:00 AM..01/01/24 11:59:59 PM');
        Observer.Expect('dtDateTime', '1|01/01/24 08:00 AM');
        Observer.Expect('dtDotted', '1|01/01/24 08:00 AM');
        Observer.Expect('dtIso|text', 'The filter "2024-01-01T08:00:00" is not valid for the DT field on the LT P136 Row table. The date is not valid.');
        Observer.Expect('dtIso|code', 'Filter:CSide');
        Observer.Expect('dtRange|text', 'The filter "010124..150124" is not valid for the DT field on the LT P136 Row table. The value "150124" can''t be evaluated into type DateTime.');
        Observer.Expect('dtRange|code', 'Filter:CSide');
        Observer.Expect('dtGarbage|text', 'The filter "x" is not valid for the DT field on the LT P136 Row table. The value "x" can''t be evaluated into type DateTime.');
        Observer.Expect('dtGarbage|code', 'Filter:CSide');
        Observer.Expect('dtFormula', '0|10/01/26 12:00 AM..10/01/26 11:59:59 PM');
        Observer.Verify();
    end;
}
