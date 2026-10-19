// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-types
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table LT W Pt Row (69883) in events/lt-platform-triggers; own log 81112 and subscribers 81113 (copies of
// LT W Pt Log 69880 and the Filter Helper subscribers of 69881, so no SingleInstance codeunit is shared with another test codeunit); own runner 81078 and tests 81079
// Probe: corpus issue 657. Filter texts that MakeIntFilter, MakeTimeFilter and MakeDateTimeFilter (codeunit "Filter Helper Triggers") may be raised for,
// Decimal filter texts that are neither a number nor letters only, Time filter texts in other forms, the GetFilter text of a Time with milliseconds and
// Integer filter texts with blank space inside. As in PtObserve.al each text is set with the log mode 0 (subscribers silent), 1 (log), 2 (log and change the
// text to W:...) and 3 (the subscriber repairs the text). The work date is set to 2022-06-15 (the second MakeDateTimeFilter call of mode 2 is made from it).
// BC versions: 27-29

codeunit 81078 "BD Filter Runner"
{
    trigger OnRun()
    var
        Log: Codeunit "BD Pt Log";
    begin
        Log.SetResult(Run(Log.Which()));
    end;

    local procedure Run(Which: Text): Text
    var
        Row: Record "LT W Pt Row";
    begin
        case Which of
            'int_range_x':
                begin
                    Row.SetFilter(Id, '1..x');
                    exit(Row.GetFilter(Id));
                end;
            'int_x_or_1':
                begin
                    Row.SetFilter(Id, 'x|1');
                    exit(Row.GetFilter(Id));
                end;
            'int_dec':
                begin
                    Row.SetFilter(Id, '1.5');
                    exit(Row.GetFilter(Id));
                end;
            'int_space':
                begin
                    Row.SetFilter(Id, '1 2');
                    exit(Row.GetFilter(Id));
                end;
            'int_space_range':
                begin
                    Row.SetFilter(Id, '1 .. 5');
                    exit(Row.GetFilter(Id));
                end;
            'int_space_or':
                begin
                    Row.SetFilter(Id, '1 | 2');
                    exit(Row.GetFilter(Id));
                end;
            'int_lead':
                begin
                    Row.SetFilter(Id, ' 5');
                    exit(Row.GetFilter(Id));
                end;
            'int_word_range':
                begin
                    Row.SetFilter(Id, 'abc..xyz');
                    exit(Row.GetFilter(Id));
                end;
            'time_range_x':
                begin
                    Row.SetFilter(T, '1..x');
                    exit(Row.GetFilter(T));
                end;
            'time_x_or_1':
                begin
                    Row.SetFilter(T, 'x|1');
                    exit(Row.GetFilter(T));
                end;
            'time_dec':
                begin
                    Row.SetFilter(T, '1.5');
                    exit(Row.GetFilter(T));
                end;
            'time_13':
                begin
                    Row.SetFilter(T, '13:00:00');
                    exit(Row.GetFilter(T));
                end;
            'time_9':
                begin
                    Row.SetFilter(T, '9:00');
                    exit(Row.GetFilter(T));
                end;
            'time_digits':
                begin
                    Row.SetFilter(T, '120000');
                    exit(Row.GetFilter(T));
                end;
            'time_pm':
                begin
                    Row.SetFilter(T, '12:00:00 PM');
                    exit(Row.GetFilter(T));
                end;
            'time_0905':
                begin
                    Row.SetFilter(T, '09:05:07');
                    exit(Row.GetFilter(T));
                end;
            'time_range':
                begin
                    Row.SetFilter(T, '12:00:00..13:00:00');
                    exit(Row.GetFilter(T));
                end;
            'time_1300':
                begin
                    Row.SetFilter(T, '1300');
                    exit(Row.GetFilter(T));
                end;
            'dt_abc':
                begin
                    Row.SetFilter(DT, 'abc');
                    exit(Row.GetFilter(DT));
                end;
            'dt_range_x':
                begin
                    Row.SetFilter(DT, '1..x');
                    exit(Row.GetFilter(DT));
                end;
            'dt_x_or_1':
                begin
                    Row.SetFilter(DT, 'x|1');
                    exit(Row.GetFilter(DT));
                end;
            'dt_words':
                begin
                    Row.SetFilter(DT, 'abc..xyz');
                    exit(Row.GetFilter(DT));
                end;
            'dt_text':
                begin
                    Row.SetFilter(DT, '01/01/20 13:00');
                    exit(Row.GetFilter(DT));
                end;
            'dec_comma':
                begin
                    Row.SetFilter(Amount, '1,5');
                    exit(Row.GetFilter(Amount));
                end;
            'dec_dots':
                begin
                    Row.SetFilter(Amount, '1.2.3');
                    exit(Row.GetFilter(Amount));
                end;
            'dec_range_x':
                begin
                    Row.SetFilter(Amount, '1..x');
                    exit(Row.GetFilter(Amount));
                end;
            'dec_x_or_1':
                begin
                    Row.SetFilter(Amount, 'x|1');
                    exit(Row.GetFilter(Amount));
                end;
            'dec_exp':
                begin
                    Row.SetFilter(Amount, '1e5');
                    exit(Row.GetFilter(Amount));
                end;
            'dec_space':
                begin
                    Row.SetFilter(Amount, '1 000');
                    exit(Row.GetFilter(Amount));
                end;
            'dec_minus_space':
                begin
                    Row.SetFilter(Amount, '- 1');
                    exit(Row.GetFilter(Amount));
                end;
            'dec_group':
                begin
                    Row.SetFilter(Amount, '1,234.5');
                    exit(Row.GetFilter(Amount));
                end;
            'time_ms_range':
                begin
                    Row.SetRange(T, 120000.123T);
                    exit(Row.GetFilter(T));
                end;
            'time_ms_filter':
                begin
                    Row.SetFilter(T, '>=%1', 090507.5T);
                    exit(Row.GetFilter(T));
                end;
            'time_ms_view':
                begin
                    Row.SetRange(T, 235959.999T);
                    exit(Row.GetView());
                end;
        end;
        exit('unknown case ' + Which);
    end;
}

codeunit 81079 "BD Filter Event Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Act(Which: Text)
    var
        Log: Codeunit "BD Pt Log";
        Mode: Integer;
        Ok: Boolean;
        Err: Text;
        FirstErr: Text;
        OldWorkDate: Date;
    begin
        OldWorkDate := WorkDate();
        WorkDate(DMY2Date(15, 6, 2022));
        for Mode := 0 to 3 do begin
            Log.SetMode(Mode);
            Log.Reset();
            Log.SetWhich(Which);
            ClearLastError();
            Ok := Codeunit.Run(Codeunit::"BD Filter Runner");
            Err := '';
            if not Ok then
                Err := GetLastErrorText();
            ClearLastError();
            Log.SetMode(0);
            if Mode = 0 then begin
                FirstErr := Err;
                Observer.Observe(Which + '|err', Err);
            end else
                Observer.Observe(Which + '|m' + Format(Mode) + '|err-same', Format(Err = FirstErr));
            Observer.Observe(Which + '|m' + Format(Mode), 'ok=' + Format(Ok) + ' res=' + Log.Result() + ' log=' + Log.Dump());
        end;
        WorkDate(OldWorkDate);
    end;
    [Test]
    procedure BdFilter_Int_1()
    begin
        Act('int_range_x');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_Int_2()
    begin
        Act('int_x_or_1');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_Int_3()
    begin
        Act('int_dec');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_Int_4()
    begin
        Act('int_space');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_Int_5()
    begin
        Act('int_space_range');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_Int_6()
    begin
        Act('int_space_or');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_Int_7()
    begin
        Act('int_lead');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_Int_8()
    begin
        Act('int_word_range');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_Time_1()
    begin
        Act('time_range_x');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_Time_2()
    begin
        Act('time_x_or_1');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_Time_3()
    begin
        Act('time_dec');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_Time_4()
    begin
        Act('time_13');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_Time_5()
    begin
        Act('time_9');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_Time_6()
    begin
        Act('time_digits');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_Time_7()
    begin
        Act('time_pm');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_Time_8()
    begin
        Act('time_0905');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_Time_9()
    begin
        Act('time_range');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_Time_10()
    begin
        Act('time_1300');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_DateTime_1()
    begin
        Act('dt_abc');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_DateTime_2()
    begin
        Act('dt_range_x');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_DateTime_3()
    begin
        Act('dt_x_or_1');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_DateTime_4()
    begin
        Act('dt_words');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_DateTime_5()
    begin
        Act('dt_text');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_Decimal_1()
    begin
        Act('dec_comma');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_Decimal_2()
    begin
        Act('dec_dots');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_Decimal_3()
    begin
        Act('dec_range_x');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_Decimal_4()
    begin
        Act('dec_x_or_1');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_Decimal_5()
    begin
        Act('dec_exp');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_Decimal_6()
    begin
        Act('dec_space');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_Decimal_7()
    begin
        Act('dec_minus_space');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_Decimal_8()
    begin
        Act('dec_group');
        Observer.Finish();
    end;
    [Test]
    procedure BdFilter_TimeMilliseconds()
    begin
        Act('time_ms_range');
        Act('time_ms_filter');
        Observer.Finish();
    end;

    [Test]
    procedure BdFilter_TimeMillisecondsView()
    begin
        Act('time_ms_view');
        Observer.Finish();
    end;
}

codeunit 81112 "BD Pt Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];
        ModeValue: Integer;
        WhichValue: Text;
        ResultValue: Text;

    procedure SetMode(NewMode: Integer)
    begin
        ModeValue := NewMode;
    end;

    procedure Mode(): Integer
    begin
        exit(ModeValue);
    end;

    procedure Reset()
    begin
        Clear(Lines);
        ResultValue := '';
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Count(): Integer
    begin
        exit(Lines.Count());
    end;

    procedure CountOf(Prefix: Text): Integer
    var
        Line: Text;
        N: Integer;
    begin
        foreach Line in Lines do
            if Line.StartsWith(Prefix) then
                N += 1;
        exit(N);
    end;

    procedure Dump(): Text
    var
        Line: Text;
        Joined: Text;
    begin
        foreach Line in Lines do begin
            if Joined <> '' then
                Joined += ' | ';
            Joined += Line;
        end;
        exit('[' + Joined + ']');
    end;

    procedure SetWhich(NewWhich: Text)
    begin
        WhichValue := NewWhich;
    end;

    procedure Which(): Text
    begin
        exit(WhichValue);
    end;

    procedure SetResult(NewResult: Text)
    begin
        ResultValue := NewResult;
    end;

    procedure Result(): Text
    begin
        exit(ResultValue);
    end;
}

codeunit 81113 "BD Pt Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Filter Helper Triggers", 'MakeDateTimeFilter', '', false, false)]
    local procedure MakeDateTimeFilter(var DateTimeFilterText: Text)
    var
        Log: Codeunit "BD Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('MakeDateTimeFilter(' + 'DateTimeFilterText=' + DateTimeFilterText + ')');
        if Log.Mode() = 3 then begin
            if DateTimeFilterText.Contains('..') then
                DateTimeFilterText := '01/01/20 12:00 PM..12/31/20 12:00 PM'
            else
                DateTimeFilterText := '12/31/20 12:00 PM';
        end;
        if Log.Mode() = 2 then begin
            DateTimeFilterText := 'W:DateTimeFilterText';
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Filter Helper Triggers", 'MakeIntFilter', '', false, false)]
    local procedure MakeIntFilter(var IntFilterText: Text)
    var
        Log: Codeunit "BD Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('MakeIntFilter(' + 'IntFilterText=' + IntFilterText + ')');
        if Log.Mode() = 3 then begin
            if IntFilterText.Contains('..') then
                IntFilterText := '1..5'
            else
                IntFilterText := '5';
        end;
        if Log.Mode() = 2 then begin
            IntFilterText := 'W:IntFilterText';
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Filter Helper Triggers", 'MakeDateFilter', '', false, false)]
    local procedure MakeDateFilter(var DateFilterText: Text)
    var
        Log: Codeunit "BD Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('MakeDateFilter(' + 'DateFilterText=' + DateFilterText + ')');
        if Log.Mode() = 3 then begin
            if DateFilterText.Contains('..') then
                DateFilterText := '2020-01-01..2020-12-31'
            else
                DateFilterText := '2020-12-31';
        end;
        if Log.Mode() = 2 then begin
            DateFilterText := 'W:DateFilterText';
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Filter Helper Triggers", 'MakeTextFilter', '', false, false)]
    local procedure MakeTextFilter(var TextFilterText: Text)
    var
        Log: Codeunit "BD Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('MakeTextFilter(' + 'TextFilterText=' + TextFilterText + ')');
        if Log.Mode() = 3 then begin
            if TextFilterText.Contains('..') then
                TextFilterText := 'A*'
            else
                TextFilterText := 'A*';
        end;
        if Log.Mode() = 2 then begin
            TextFilterText := 'W:TextFilterText';
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Filter Helper Triggers", 'MakeCodeFilter', '', false, false)]
    local procedure MakeCodeFilter(var TextFilterText: Text)
    var
        Log: Codeunit "BD Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('MakeCodeFilter(' + 'TextFilterText=' + TextFilterText + ')');
        if Log.Mode() = 3 then begin
            if TextFilterText.Contains('..') then
                TextFilterText := 'A*'
            else
                TextFilterText := 'A*';
        end;
        if Log.Mode() = 2 then begin
            TextFilterText := 'W:TextFilterText';
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Filter Helper Triggers", 'MakeTimeFilter', '', false, false)]
    local procedure MakeTimeFilter(var TimeFilterText: Text)
    var
        Log: Codeunit "BD Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('MakeTimeFilter(' + 'TimeFilterText=' + TimeFilterText + ')');
        if Log.Mode() = 3 then begin
            if TimeFilterText.Contains('..') then
                TimeFilterText := '12:00:00..13:00:00'
            else
                TimeFilterText := '12:00:00';
        end;
        if Log.Mode() = 2 then begin
            TimeFilterText := 'W:TimeFilterText';
        end;
    end;

}
