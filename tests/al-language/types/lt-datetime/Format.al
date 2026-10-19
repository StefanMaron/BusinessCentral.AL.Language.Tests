// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Topic: Format of Date, Time, DateTime, Duration with standard format numbers and custom strings
// BC versions: 29 (27 and 28 by CI)

codeunit 73804 "LT DtT Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFmt(V: Variant; Number: Integer; var Result: Text)
    var
        D: Date;
        T: Time;
        DT: DateTime;
        Du: Duration;
    begin
        if V.IsDate() then begin
            D := V;
            Result := Format(D, 0, Number);
        end else if V.IsTime() then begin
            T := V;
            Result := Format(T, 0, Number);
        end else if V.IsDateTime() then begin
            DT := V;
            Result := Format(DT, 0, Number);
        end else begin
            Du := V;
            Result := Format(Du, 0, Number);
        end;
    end;

    local procedure Fmt(V: Variant; Number: Integer): Text
    var
        Result: Text;
    begin
        if TryFmt(V, Number, Result) then
            exit(Result);
        exit('ERR:' + GetLastErrorText());
    end;

    [Test]
    procedure Date_Format_Numbers()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
        I: Integer;
    begin
        D := 20240305D;
        for I := 0 to 9 do
            Observer.Observe('date fmt ' + Format(I), Fmt(D, I));
        Observer.Observe('date fmt 10', Fmt(D, 10));
        Observer.Observe('date fmt 99', Fmt(D, 99));
        Observer.Observe('date fmt -1', Fmt(D, -1));
        Observer.Observe('date len 5', Format(D, 5, 9));
        Observer.Observe('date len 5 default', Format(D, 5));
        Observer.Observe('date len 20', Format(D, 20, 9));
        Observer.Observe('date default', Format(D));
        Observer.Expect('date fmt 0', '03/05/24');
        Observer.Expect('date fmt 1', '03/05/24');
        Observer.Expect('date fmt 2', '030524D');
        Observer.Expect('date fmt 3', '24/03/05');
        Observer.Expect('date fmt 4', 'March 5, 2024');
        Observer.Expect('date fmt 5', '030524');
        Observer.Expect('date fmt 6', '240305');
        Observer.Expect('date fmt 7', 'Mar 5, 2024');
        Observer.Expect('date fmt 8', 'ERR:Standard format number 8 does not exist for the type ''Date''.');
        Observer.Expect('date fmt 9', '2024-03-05');
        Observer.Expect('date fmt 10', 'ERR:Standard format number 10 does not exist for the type ''Date''.');
        Observer.Expect('date fmt 99', 'ERR:Standard format number 99 does not exist for the type ''Date''.');
        Observer.Expect('date fmt -1', 'ERR:Standard format number -1 does not exist for the type ''Date''.');
        Observer.Expect('date len 5', '2024-');
        Observer.Expect('date len 5 default', '03/05');
        Observer.Expect('date len 20', '          2024-03-05');
        Observer.Expect('date default', '03/05/24');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Format_0D_And_Bounds()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        for I := 0 to 9 do
            Observer.Observe('0D fmt ' + Format(I), Format(0D, 0, I));
        Observer.Observe('0D default', Format(0D));
        asserterror Observer.Observe('min 9', Format(00010101D, 0, 9));
        Observer.ObserveError('af74');
        asserterror Observer.Observe('min 0', Format(00010101D, 0, 0));
        Observer.ObserveError('af76');
        asserterror Observer.Observe('min 1', Format(00010101D, 0, 1));
        Observer.ObserveError('af78');
        asserterror Observer.Observe('min 4', Format(00010101D, 0, 4));
        Observer.ObserveError('af80');
        Observer.Observe('max 9', Format(99991231D, 0, 9));
        Observer.Observe('max 0', Format(99991231D, 0, 0));
        Observer.Observe('max 1', Format(99991231D, 0, 1));
        Observer.Observe('max 4', Format(99991231D, 0, 4));
        Observer.Expect('0D fmt 0', '');
        Observer.Expect('0D fmt 1', '');
        Observer.Expect('0D fmt 2', '');
        Observer.Expect('0D fmt 3', '');
        Observer.Expect('0D fmt 4', '');
        Observer.Expect('0D fmt 5', '');
        Observer.Expect('0D fmt 6', '');
        Observer.Expect('0D fmt 7', '');
        Observer.Expect('0D fmt 8', '');
        Observer.Expect('0D fmt 9', '');
        Observer.Expect('0D default', '');
        Observer.Expect('af74|text', 'The date is not valid.');
        Observer.Expect('af74|code', 'DateInvalid');
        Observer.Expect('af76|text', 'The date is not valid.');
        Observer.Expect('af76|code', 'DateInvalid');
        Observer.Expect('af78|text', 'The date is not valid.');
        Observer.Expect('af78|code', 'DateInvalid');
        Observer.Expect('af80|text', 'The date is not valid.');
        Observer.Expect('af80|code', 'DateInvalid');
        Observer.Expect('max 9', '9999-12-31');
        Observer.Expect('max 0', '12/31/9999');
        Observer.Expect('max 1', '12/31/9999');
        Observer.Expect('max 4', 'December 31, 9999');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Format_Custom()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := 20240305D;
        Observer.Observe('Day', Format(D, 0, '<Day>'));
        Observer.Observe('Day,2', Format(D, 0, '<Day,2>'));
        Observer.Observe('Day,3', Format(D, 0, '<Day,3>'));
        Observer.Observe('Month', Format(D, 0, '<Month>'));
        Observer.Observe('Month,2', Format(D, 0, '<Month,2>'));
        Observer.Observe('Month Text', Format(D, 0, '<Month Text>'));
        Observer.Observe('Month Text,3', Format(D, 0, '<Month Text,3>'));
        Observer.Observe('Year', Format(D, 0, '<Year>'));
        Observer.Observe('Year4', Format(D, 0, '<Year4>'));
        Observer.Observe('Closing', Format(D, 0, '<Closing>'));
        Observer.Observe('Standard Format 9', Format(D, 0, '<Standard Format,9>'));
        Observer.Observe('Standard Format 0', Format(D, 0, '<Standard Format,0>'));
        Observer.Observe('Standard Format 1', Format(D, 0, '<Standard Format,1>'));
        Observer.Observe('Standard Format 4', Format(D, 0, '<Standard Format,4>'));
        Observer.Observe('Day+Month', Format(D, 0, '<Day,2>.<Month,2>.<Year4>'));
        Observer.Observe('dash', Format(D, 0, '<Year4>-<Month,2>-<Day,2>'));
        Observer.Observe('literal', Format(D, 0, 'Date: <Day>/<Month>'));
        asserterror Observer.Observe('Day Text', Format(D, 0, '<Day Text>'));
        Observer.ObserveError('af110');
        Observer.Observe('Weekday Text', Format(D, 0, '<Weekday Text>'));
        Observer.Observe('Week', Format(D, 0, '<Week>'));
        Observer.Observe('Week,2', Format(D, 0, '<Week,2>'));
        asserterror Observer.Observe('bad tag', Format(D, 0, '<Foo>'));
        Observer.ObserveError('af116');
        Observer.Observe('empty custom', Format(D, 0, ''));
        Observer.Observe('Closing on closing', Format(ClosingDate(D), 0, '<Closing><Day>'));
        Observer.Observe('Closing format 9', Format(ClosingDate(D), 0, 9));
        Observer.Observe('Closing format 0', Format(ClosingDate(D), 0, 0));
        Observer.Observe('Closing format 1', Format(ClosingDate(D), 0, 1));
        Observer.Expect('Day', '5');
        Observer.Expect('Day,2', '05');
        Observer.Expect('Day,3', '005');
        Observer.Expect('Month', '3');
        Observer.Expect('Month,2', '03');
        Observer.Expect('Month Text', 'March');
        Observer.Expect('Month Text,3', 'Mar');
        Observer.Expect('Year', '24');
        Observer.Expect('Year4', '2024');
        Observer.Expect('Closing', '');
        Observer.Expect('Standard Format 9', '2024-03-05');
        Observer.Expect('Standard Format 0', '03/05/24');
        Observer.Expect('Standard Format 1', '03/05/24');
        Observer.Expect('Standard Format 4', 'March 5, 2024');
        Observer.Expect('Day+Month', '05.03.2024');
        Observer.Expect('dash', '2024-03-05');
        Observer.Expect('literal', 'Date: 5/3');
        Observer.Expect('af110|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\<Day Text>');
        Observer.Expect('af110|code', 'InvalidFormatString');
        Observer.Expect('Weekday Text', 'Tuesday');
        Observer.Expect('Week', '10');
        Observer.Expect('Week,2', '10');
        Observer.Expect('af116|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\<Foo>');
        Observer.Expect('af116|code', 'InvalidFormatString');
        Observer.Expect('empty custom', '');
        Observer.Expect('Closing on closing', 'C5');
        Observer.Expect('Closing format 9', '2024-03-05');
        Observer.Expect('Closing format 0', 'C03/05/24');
        Observer.Expect('Closing format 1', 'C03/05/24');
        Observer.Verify();
    end;

    [Test]
    procedure Time_Format_Numbers()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
        I: Integer;
    begin
        T := 134506.078T;
        for I := 0 to 9 do
            Observer.Observe('time fmt ' + Format(I), Fmt(T, I));
        Observer.Observe('time fmt 10', Fmt(T, 10));
        Observer.Observe('time fmt -1', Fmt(T, -1));
        Observer.Observe('time default', Format(T));
        Observer.Observe('time len 4', Format(T, 4, 9));
        Observer.Expect('time fmt 0', ' 1:45:06 PM');
        Observer.Expect('time fmt 1', ' 1:45:06.078 PM');
        Observer.Expect('time fmt 2', '134506.078T');
        Observer.Expect('time fmt 3', 'ERR:Standard format number 3 does not exist for the type ''Time''.');
        Observer.Expect('time fmt 4', 'ERR:Standard format number 4 does not exist for the type ''Time''.');
        Observer.Expect('time fmt 5', 'ERR:Standard format number 5 does not exist for the type ''Time''.');
        Observer.Expect('time fmt 6', 'ERR:Standard format number 6 does not exist for the type ''Time''.');
        Observer.Expect('time fmt 7', 'ERR:Standard format number 7 does not exist for the type ''Time''.');
        Observer.Expect('time fmt 8', 'ERR:Standard format number 8 does not exist for the type ''Time''.');
        Observer.Expect('time fmt 9', '13:45:06.078');
        Observer.Expect('time fmt 10', 'ERR:Standard format number 10 does not exist for the type ''Time''.');
        Observer.Expect('time fmt -1', 'ERR:Standard format number -1 does not exist for the type ''Time''.');
        Observer.Expect('time default', ' 1:45:06 PM');
        Observer.Expect('time len 4', '13:4');
        Observer.Verify();
    end;

    [Test]
    procedure Time_Format_Values()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        for I := 0 to 9 do
            Observer.Observe('0T fmt ' + Format(I), Format(0T, 0, I));
        for I := 0 to 2 do begin
            Observer.Observe('midnight fmt ' + Format(I), Format(000000T, 0, I));
            Observer.Observe('noon fmt ' + Format(I), Format(120000T, 0, I));
            Observer.Observe('1am fmt ' + Format(I), Format(010000T, 0, I));
            Observer.Observe('1pm fmt ' + Format(I), Format(130000T, 0, I));
            Observer.Observe('max fmt ' + Format(I), Format(235959.999T, 0, I));
        end;
        Observer.Expect('0T fmt 0', '');
        Observer.Expect('0T fmt 1', '');
        Observer.Expect('0T fmt 2', '');
        Observer.Expect('0T fmt 3', '');
        Observer.Expect('0T fmt 4', '');
        Observer.Expect('0T fmt 5', '');
        Observer.Expect('0T fmt 6', '');
        Observer.Expect('0T fmt 7', '');
        Observer.Expect('0T fmt 8', '');
        Observer.Expect('0T fmt 9', '');
        Observer.Expect('midnight fmt 0', '12:00:00 AM');
        Observer.Expect('noon fmt 0', '12:00:00 PM');
        Observer.Expect('1am fmt 0', ' 1:00:00 AM');
        Observer.Expect('1pm fmt 0', ' 1:00:00 PM');
        Observer.Expect('max fmt 0', '11:59:59 PM');
        Observer.Expect('midnight fmt 1', '12:00:00 AM');
        Observer.Expect('noon fmt 1', '12:00:00 PM');
        Observer.Expect('1am fmt 1', ' 1:00:00 AM');
        Observer.Expect('1pm fmt 1', ' 1:00:00 PM');
        Observer.Expect('max fmt 1', '11:59:59.999 PM');
        Observer.Expect('midnight fmt 2', '000000T');
        Observer.Expect('noon fmt 2', '120000T');
        Observer.Expect('1am fmt 2', '010000T');
        Observer.Expect('1pm fmt 2', '130000T');
        Observer.Expect('max fmt 2', '235959.999T');
        Observer.Verify();
    end;

    [Test]
    procedure Time_Format_Custom()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
    begin
        T := 134506.078T;
        Observer.Observe('Hours24', Format(T, 0, '<Hours24>'));
        Observer.Observe('Hours24,2', Format(T, 0, '<Hours24,2>'));
        Observer.Observe('Hours12', Format(T, 0, '<Hours12>'));
        Observer.Observe('Hours12,2', Format(T, 0, '<Hours12,2>'));
        Observer.Observe('Minutes', Format(T, 0, '<Minutes>'));
        Observer.Observe('Minutes,2', Format(T, 0, '<Minutes,2>'));
        Observer.Observe('Seconds', Format(T, 0, '<Seconds>'));
        Observer.Observe('Seconds,2', Format(T, 0, '<Seconds,2>'));
        Observer.Observe('Thousands', Format(T, 0, '<Thousands>'));
        Observer.Observe('Thousands,3', Format(T, 0, '<Thousands,3>'));
        Observer.Observe('Second dec', Format(T, 0, '<Second dec>'));
        Observer.Observe('Second dec,3', Format(T, 0, '<Second dec,3>'));
        Observer.Observe('AM/PM', Format(T, 0, '<AM/PM>'));
        Observer.Observe('AM/PM morning', Format(090000T, 0, '<AM/PM>'));
        Observer.Observe('Hours12 midnight', Format(000000T, 0, '<Hours12>'));
        Observer.Observe('Hours12 noon', Format(120000T, 0, '<Hours12>'));
        Observer.Observe('hms', Format(T, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('hms ms', Format(T, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>'));
        Observer.Observe('Standard Format 9', Format(T, 0, '<Standard Format,9>'));
        Observer.Observe('Standard Format 0', Format(T, 0, '<Standard Format,0>'));
        Observer.Observe('Standard Format 2', Format(T, 0, '<Standard Format,2>'));
        asserterror Observer.Observe('bad tag', Format(T, 0, '<Foo>'));
        Observer.ObserveError('af187');
        Observer.Observe('literal', Format(T, 0, 'At <Hours24>h'));
        Observer.Expect('Hours24', '13');
        Observer.Expect('Hours24,2', '13');
        Observer.Expect('Hours12', '1');
        Observer.Expect('Hours12,2', ' 1');
        Observer.Expect('Minutes', '45');
        Observer.Expect('Minutes,2', '45');
        Observer.Expect('Seconds', '6');
        Observer.Expect('Seconds,2', '06');
        Observer.Expect('Thousands', '78');
        Observer.Expect('Thousands,3', ' 78');
        Observer.Expect('Second dec', '.078');
        Observer.Expect('Second dec,3', '***');
        Observer.Expect('AM/PM', 'PM');
        Observer.Expect('AM/PM morning', 'AM');
        Observer.Expect('Hours12 midnight', '12');
        Observer.Expect('Hours12 noon', '12');
        Observer.Expect('hms', '13:45:06');
        Observer.Expect('hms ms', '13:45:06. 78');
        Observer.Expect('Standard Format 9', '13:45:06.078');
        Observer.Expect('Standard Format 0', ' 1:45:06 PM');
        Observer.Expect('Standard Format 2', '134506.078T');
        Observer.Expect('af187|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\<Foo>');
        Observer.Expect('af187|code', 'InvalidFormatString');
        Observer.Expect('literal', 'At 13h');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_Format_Numbers()
    var
        Observer: Codeunit "Probe Observer";
        DT: DateTime;
        I: Integer;
    begin
        DT := CreateDateTime(20240305D, 134506.078T);
        for I := 0 to 9 do
            Observer.Observe('dt fmt ' + Format(I), Fmt(DT, I));
        Observer.Observe('dt fmt 10', Fmt(DT, 10));
        Observer.Observe('dt fmt -1', Fmt(DT, -1));
        Observer.Observe('dt default', Format(DT));
        Observer.Observe('dt len 8', Format(DT, 8, 9));
        Observer.Expect('dt fmt 0', '03/05/24 01:45 PM');
        Observer.Expect('dt fmt 1', '03/05/24 01:45:06.078 PM');
        Observer.Expect('dt fmt 2', '03/05/24 01:45 PM');
        Observer.Expect('dt fmt 3', '03/05/24 01:45:06 PM');
        Observer.Expect('dt fmt 4', 'ERR:Standard format number 4 does not exist for the type ''DateTime''.');
        Observer.Expect('dt fmt 5', 'ERR:Standard format number 5 does not exist for the type ''DateTime''.');
        Observer.Expect('dt fmt 6', 'ERR:Standard format number 6 does not exist for the type ''DateTime''.');
        Observer.Expect('dt fmt 7', 'ERR:Standard format number 7 does not exist for the type ''DateTime''.');
        Observer.Expect('dt fmt 8', 'ERR:Standard format number 8 does not exist for the type ''DateTime''.');
        Observer.Expect('dt fmt 9', '2024-03-05T13:45:06.078Z');
        Observer.Expect('dt fmt 10', 'ERR:Standard format number 10 does not exist for the type ''DateTime''.');
        Observer.Expect('dt fmt -1', 'ERR:Standard format number -1 does not exist for the type ''DateTime''.');
        Observer.Expect('dt default', '03/05/24 01:45 PM');
        Observer.Expect('dt len 8', '2024-03-');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_Format_Values()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        for I := 0 to 9 do
            Observer.Observe('0DT fmt ' + Format(I), Format(0DT, 0, I));
        asserterror Observer.Observe('min 9', Format(CreateDateTime(00010101D, 000000T), 0, 9));
        Observer.ObserveError('af218');
        asserterror Observer.Observe('min 0', Format(CreateDateTime(00010101D, 000000T), 0, 0));
        Observer.ObserveError('af222');
        Observer.Observe('max 9', Format(CreateDateTime(99991231D, 235959.999T), 0, 9));
        Observer.Observe('max 0', Format(CreateDateTime(99991231D, 235959.999T), 0, 0));
        Observer.Observe('date only 9', Format(CreateDateTime(20240305D, 0T), 0, 9));
        Observer.Observe('date only 0', Format(CreateDateTime(20240305D, 0T), 0, 0));
        Observer.Observe('midnight 9', Format(CreateDateTime(20240305D, 000000T), 0, 9));
        asserterror Observer.Observe('time only 9', Format(CreateDateTime(0D, 123456T), 0, 9));
        Observer.ObserveError('af230');
        asserterror Observer.Observe('time only 0', Format(CreateDateTime(0D, 123456T), 0, 0));
        Observer.ObserveError('af233');
        Observer.Expect('0DT fmt 0', '');
        Observer.Expect('0DT fmt 1', '');
        Observer.Expect('0DT fmt 2', '');
        Observer.Expect('0DT fmt 3', '');
        Observer.Expect('0DT fmt 4', '');
        Observer.Expect('0DT fmt 5', '');
        Observer.Expect('0DT fmt 6', '');
        Observer.Expect('0DT fmt 7', '');
        Observer.Expect('0DT fmt 8', '');
        Observer.Expect('0DT fmt 9', '');
        Observer.Expect('af218|text', 'The date is not valid.');
        Observer.Expect('af218|code', 'DateInvalid');
        Observer.Expect('af222|text', 'The date is not valid.');
        Observer.Expect('af222|code', 'DateInvalid');
        Observer.Expect('max 9', '9999-12-31T23:59:59.999Z');
        Observer.Expect('max 0', '12/31/9999 11:59 PM');
        Observer.Expect('date only 9', '2024-03-05T00:00:00Z');
        Observer.Expect('date only 0', '03/05/24 12:00 AM');
        Observer.Expect('midnight 9', '2024-03-05T00:00:00Z');
        Observer.Expect('af230|text', 'The date is not valid.');
        Observer.Expect('af230|code', 'DateInvalid');
        Observer.Expect('af233|text', 'The date is not valid.');
        Observer.Expect('af233|code', 'DateInvalid');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_Format_Custom()
    var
        Observer: Codeunit "Probe Observer";
        DT: DateTime;
    begin
        DT := CreateDateTime(20240305D, 134506.078T);
        Observer.Observe('year4', Format(DT, 0, '<Year4>'));
        Observer.Observe('day month', Format(DT, 0, '<Day,2>.<Month,2>.<Year4>'));
        Observer.Observe('date time', Format(DT, 0, '<Year4>-<Month,2>-<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('ms', Format(DT, 0, '<Thousands,3>'));
        Observer.Observe('AM/PM', Format(DT, 0, '<AM/PM>'));
        Observer.Observe('Hours12', Format(DT, 0, '<Hours12,2>'));
        Observer.Observe('Standard 9', Format(DT, 0, '<Standard Format,9>'));
        Observer.Observe('Standard 0', Format(DT, 0, '<Standard Format,0>'));
        Observer.Observe('Standard 1', Format(DT, 0, '<Standard Format,1>'));
        Observer.Observe('Standard 2', Format(DT, 0, '<Standard Format,2>'));
        Observer.Observe('Standard 3', Format(DT, 0, '<Standard Format,3>'));
        asserterror Observer.Observe('bad tag', Format(DT, 0, '<Foo>'));
        Observer.ObserveError('af249');
        Observer.Observe('0DT custom', Format(0DT, 0, '<Year4>'));
        Observer.Expect('year4', '2024');
        Observer.Expect('day month', '05.03.2024');
        Observer.Expect('date time', '2024-03-05 13:45:06');
        Observer.Expect('ms', '078');
        Observer.Expect('AM/PM', 'PM');
        Observer.Expect('Hours12', '01');
        Observer.Expect('Standard 9', '2024-03-05T13:45:06.078Z');
        Observer.Expect('Standard 0', '03/05/24 01:45 PM');
        Observer.Expect('Standard 1', '03/05/24 01:45:06.078 PM');
        Observer.Expect('Standard 2', '03/05/24 01:45 PM');
        Observer.Expect('Standard 3', '03/05/24 01:45:06 PM');
        Observer.Expect('af249|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\<Foo>');
        Observer.Expect('af249|code', 'InvalidFormatString');
        Observer.Expect('0DT custom', '');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_Format()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
        I: Integer;
    begin
        D := 90061001;
        for I := 0 to 9 do
            Observer.Observe('dur fmt ' + Format(I), Fmt(D, I));
        Observer.Observe('dur default', Format(D));
        Observer.Observe('dur 0', Format(Duration_Zero()));
        Observer.Observe('dur 1 ms', Format(Duration_From(1)));
        Observer.Observe('dur 999 ms', Format(Duration_From(999)));
        Observer.Observe('dur 1 s', Format(Duration_From(1000)));
        Observer.Observe('dur 1 min', Format(Duration_From(60000)));
        Observer.Observe('dur 1 h', Format(Duration_From(3600000)));
        Observer.Observe('dur 1 d', Format(Duration_From(86400000)));
        Observer.Observe('dur 2 d', Format(Duration_From(172800000)));
        Observer.Observe('dur 1h30m', Format(Duration_From(5400000)));
        Observer.Observe('dur neg', Format(Duration_From(-5400000)));
        Observer.Observe('dur neg 9', Format(Duration_From(-5400000), 0, 9));
        Observer.Observe('dur 1 s 9', Format(Duration_From(1000), 0, 9));
        Observer.Observe('dur 1 d 9', Format(Duration_From(86400000), 0, 9));
        asserterror Observer.Observe('dur custom', Format(Duration_From(5400000), 0, '<Hours24,2>:<Minutes,2>'));
        Observer.ObserveError('af279');
        Observer.Expect('dur fmt 0', '1 day 1 hour 1 minute 1 second 1 millisecond');
        Observer.Expect('dur fmt 1', '1 day 1 hour 1 minute 1 second 1 millisecond');
        Observer.Expect('dur fmt 2', '1 0 1 2 1 4 1 6 1 8');
        Observer.Expect('dur fmt 3', 'ERR:Standard format number 3 does not exist for the type ''Duration''.');
        Observer.Expect('dur fmt 4', 'ERR:Standard format number 4 does not exist for the type ''Duration''.');
        Observer.Expect('dur fmt 5', 'ERR:Standard format number 5 does not exist for the type ''Duration''.');
        Observer.Expect('dur fmt 6', 'ERR:Standard format number 6 does not exist for the type ''Duration''.');
        Observer.Expect('dur fmt 7', 'ERR:Standard format number 7 does not exist for the type ''Duration''.');
        Observer.Expect('dur fmt 8', 'ERR:Standard format number 8 does not exist for the type ''Duration''.');
        Observer.Expect('dur fmt 9', 'P1DT1H1M1.001S');
        Observer.Expect('dur default', '1 day 1 hour 1 minute 1 second 1 millisecond');
        Observer.Expect('dur 0', '');
        Observer.Expect('dur 1 ms', '1 millisecond');
        Observer.Expect('dur 999 ms', '999 milliseconds');
        Observer.Expect('dur 1 s', '1 second');
        Observer.Expect('dur 1 min', '1 minute');
        Observer.Expect('dur 1 h', '1 hour');
        Observer.Expect('dur 1 d', '1 day');
        Observer.Expect('dur 2 d', '2 days');
        Observer.Expect('dur 1h30m', '1 hour 30 minutes');
        Observer.Expect('dur neg', '-1 hour 30 minutes');
        Observer.Expect('dur neg 9', '-P0DT1H30M0.0S');
        Observer.Expect('dur 1 s 9', 'P0DT0H0M1.0S');
        Observer.Expect('dur 1 d 9', 'P1DT0H0M0.0S');
        Observer.Expect('af279|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\<Hours24,2>:<Minutes,2>');
        Observer.Expect('af279|code', 'InvalidFormatString');
        Observer.Verify();
    end;

    local procedure Duration_Zero(): Duration
    var
        D: Duration;
    begin
        exit(D);
    end;

    local procedure Duration_From(Ms: BigInteger): Duration
    begin
        exit(Ms);
    end;

    [Test]
    procedure Format_Length_Truncation()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('date len 1', Format(20240305D, 1, 9));
        Observer.Observe('date len 4', Format(20240305D, 4, 9));
        Observer.Observe('date len 10', Format(20240305D, 10, 9));
        Observer.Observe('date len 11', Format(20240305D, 11, 9));
        Observer.Observe('date len -1', Format(20240305D, -1, 9));
        Observer.Observe('time len 3', Format(134506T, 3, 9));
        Observer.Observe('dt len 10', Format(CreateDateTime(20240305D, 134506T), 10, 9));
        Observer.Observe('dt len 30', Format(CreateDateTime(20240305D, 134506T), 30, 9));
        Observer.Observe('date len 5 fmt 0', Format(20240305D, 5, 0));
        Observer.Observe('date len 5 custom', Format(20240305D, 5, '<Year4>-<Month,2>'));
        Observer.Expect('date len 1', '2');
        Observer.Expect('date len 4', '2024');
        Observer.Expect('date len 10', '2024-03-05');
        Observer.Expect('date len 11', ' 2024-03-05');
        Observer.Expect('date len -1', '2');
        Observer.Expect('time len 3', '13:');
        Observer.Expect('dt len 10', '2024-03-05');
        Observer.Expect('dt len 30', '          2024-03-05T13:45:06Z');
        Observer.Expect('date len 5 fmt 0', '03/05');
        Observer.Expect('date len 5 custom', '2024-');
        Observer.Verify();
    end;
}
