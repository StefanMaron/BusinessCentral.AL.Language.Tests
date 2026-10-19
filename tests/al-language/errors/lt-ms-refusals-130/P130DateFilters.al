// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: own table 73548, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SetFilter on a Date field with a literal TEXT (no %1): the session's own formatted date (Format(D) and Format(D, 0, 0..9)), custom formats, 6 and 8 digit forms,
//   separators, month names, operators with those texts, an empty text, '', <>'', blanks, date words and formulas (T, W, CM, 1M ...), count and GetFilter, or the error text and code
// Settles issue 130 reasons 7, 14, 21, 22 (SetFilter: text filter value for Date: an empty '', a formula such as 1M, a region's date format)
// BC versions: 29 (27 and 28 by CI)

table 73548 "LT P130 Filter Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Dt; Date) { }
        field(3; Gd; Guid) { }
        field(4; Tm; Time) { }
        field(5; Dtm; DateTime) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 73549 "LT P130 Date Filters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT P130 Filter Row";
    begin
        R.DeleteAll();
        Add(1, 20240102D);
        Add(2, 20240103D);
        Add(3, 20240104D);
        Add(4, 20240301D);
        Add(5, 20240305D);
        Add(6, 20241231D);
        Add(7, 0D);
    end;

    local procedure Add(Id: Integer; D: Date)
    var
        R: Record "LT P130 Filter Row";
    begin
        R.Id := Id;
        R.Dt := D;
        R.Insert();
    end;

    [TryFunction]
    local procedure TrySet(var R: Record "LT P130 Filter Row"; FilterText: Text)
    begin
        R.SetFilter(Dt, FilterText);
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; FilterText: Text)
    var
        R: Record "LT P130 Filter Row";
    begin
        if TrySet(R, FilterText) then
            Observer.Observe(Name, 'ok count=' + Format(R.Count()) + ' filter=' + R.GetFilter(Dt))
        else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;





    [Test]
    procedure P130_DateFilter_OperatorsWithSessionFormat()
    var
        Observer: Codeunit "Probe Observer";
        D1: Date;
        D2: Date;
    begin
        Seed();
        D1 := 20240103D;
        D2 := 20240301D;
        Probe(Observer, 'ge', '>=' + Format(D1));
        Probe(Observer, 'gt', '>' + Format(D1));
        Probe(Observer, 'le', '<=' + Format(D1));
        Probe(Observer, 'lt', '<' + Format(D1));
        Probe(Observer, 'ne', '<>' + Format(D1));
        Probe(Observer, 'range', Format(D1) + '..' + Format(D2));
        Probe(Observer, 'open_start', '..' + Format(D1));
        Probe(Observer, 'open_end', Format(D1) + '..');
        Probe(Observer, 'or', Format(D1) + '|' + Format(D2));
        Probe(Observer, 'range_or_single', Format(D1) + '..' + Format(D2) + '|' + Format(20241231D));
        Probe(Observer, 'and_ge_le', '>=' + Format(D1) + '&<=' + Format(D2));
        Probe(Observer, 'ne_or', '<>' + Format(D1) + '&<>' + Format(D2));
        Probe(Observer, 'range_reversed', Format(D2) + '..' + Format(D1));
        Probe(Observer, 'spaces_around_range', ' ' + Format(D1) + ' .. ' + Format(D2) + ' ');
        Probe(Observer, 'iso_range', '2024-01-03..2024-03-01');
        Probe(Observer, 'iso_ge', '>=2024-01-03');
        Observer.Expect('ge', 'ok count=5 filter=>=01/03/24');
        Observer.Expect('gt', 'ok count=4 filter=>01/03/24');
        Observer.Expect('le', 'ok count=3 filter=<=01/03/24');
        Observer.Expect('lt', 'ok count=2 filter=<01/03/24');
        Observer.Expect('ne', 'ok count=6 filter=<>01/03/24');
        Observer.Expect('range', 'ok count=3 filter=01/03/24..03/01/24');
        Observer.Expect('open_start', 'ok count=3 filter=..01/03/24');
        Observer.Expect('open_end', 'ok count=5 filter=01/03/24..');
        Observer.Expect('or', 'ok count=2 filter=01/03/24|03/01/24');
        Observer.Expect('range_or_single', 'ok count=4 filter=01/03/24..03/01/24|12/31/24');
        Observer.Expect('and_ge_le', 'ok count=3 filter=>=01/03/24&<=03/01/24');
        Observer.Expect('ne_or', 'ok count=5 filter=<>01/03/24&<>03/01/24');
        Observer.Expect('range_reversed', 'ok count=0 filter=03/01/24..01/03/24');
        Observer.Expect('spaces_around_range', 'ok count=3 filter=01/03/24..03/01/24');
        Observer.Expect('iso_range', 'ok count=3 filter=01/03/24..03/01/24');
        Observer.Expect('iso_ge', 'ok count=5 filter=>=01/03/24');
        Observer.Verify();
    end;

    // Corpus issue 672 item 2 (AL issue 7325): the value of a DateTime and a Time field after Insert, read back with Get into another
    // record variable, for 1 to 9, 998 and 999 milliseconds (value read back | read back = value written | written variable = value).
    [Test]
    procedure BT_DateTimeAndTime_MillisecondsAfterWrite()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P130 Filter Row";
        Back: Record "LT P130 Filter Row";
        Ms: List of [Integer];
        M: Integer;
        T: Time;
        DT: DateTime;
    begin
        R.DeleteAll();
        Ms.AddRange(1, 2, 3, 4, 5, 6, 7, 8, 9, 998, 999);
        foreach M in Ms do begin
            T := 000000T + M;
            DT := CreateDateTime(20240325D, T);
            R.Init();
            R.Id := M;
            R.Tm := T;
            R.Dtm := DT;
            R.Insert();
            Back.Get(M);
            Observer.Observe('dtm ' + Format(M), Format(Back.Dtm, 0, 9) + '|' + Format(Back.Dtm = DT) + '|' + Format(R.Dtm = DT));
            Observer.Observe('tm ' + Format(M), Format(Back.Tm, 0, 9) + '|' + Format(Back.Tm = T) + '|' + Format(R.Tm = T));
        end;
        Observer.Expect('dtm 1', '2024-03-25T00:00:00Z|No|Yes');
        Observer.Expect('tm 1', '00:00:00|No|Yes');
        Observer.Expect('dtm 2', '2024-03-25T00:00:00.003Z|No|Yes');
        Observer.Expect('tm 2', '00:00:00.003|No|Yes');
        Observer.Expect('dtm 3', '2024-03-25T00:00:00.003Z|Yes|Yes');
        Observer.Expect('tm 3', '00:00:00.003|Yes|Yes');
        Observer.Expect('dtm 4', '2024-03-25T00:00:00.003Z|No|Yes');
        Observer.Expect('tm 4', '00:00:00.003|No|Yes');
        Observer.Expect('dtm 5', '2024-03-25T00:00:00.007Z|No|Yes');
        Observer.Expect('tm 5', '00:00:00.007|No|Yes');
        Observer.Expect('dtm 6', '2024-03-25T00:00:00.007Z|No|Yes');
        Observer.Expect('tm 6', '00:00:00.007|No|Yes');
        Observer.Expect('dtm 7', '2024-03-25T00:00:00.007Z|Yes|Yes');
        Observer.Expect('tm 7', '00:00:00.007|Yes|Yes');
        Observer.Expect('dtm 8', '2024-03-25T00:00:00.007Z|No|Yes');
        Observer.Expect('tm 8', '00:00:00.007|No|Yes');
        Observer.Expect('dtm 9', '2024-03-25T00:00:00.01Z|No|Yes');
        Observer.Expect('tm 9', '00:00:00.01|No|Yes');
        Observer.Expect('dtm 998', '2024-03-25T00:00:00.997Z|No|Yes');
        Observer.Expect('tm 998', '00:00:00.997|No|Yes');
        Observer.Expect('dtm 999', '2024-03-25T00:00:01Z|No|Yes');
        Observer.Expect('tm 999', '00:00:01|No|Yes');
        Observer.Verify();
    end;

    // Corpus issue 672 item 2: a DateTime range whose upper end is 23:59:59.999 (rows stored at 2024-03-25 00:00:00.000 and at
    // 2024-03-24 23:59:59.997), GetFilters of that range, and equality filters with a millisecond the database cannot hold.
    [Test]
    procedure BT_DateTimeFilter_999Milliseconds()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P130 Filter Row";
    begin
        R.DeleteAll();
        R.Init();
        R.Id := 1;
        R.Dtm := CreateDateTime(20240325D, 000000T);
        R.Insert();
        R.Init();
        R.Id := 2;
        R.Dtm := CreateDateTime(20240324D, 235959.997T);
        R.Insert();
        R.Init();
        R.Id := 3;
        R.Tm := 120000T;
        R.Insert();
        R.Reset();
        R.SetRange(Dtm, CreateDateTime(20240301D, 000000T), CreateDateTime(20240324D, 235959.999T));
        Observer.Observe('to .999 count', Format(R.Count()));
        Observer.Observe('to .999 getfilters', R.GetFilters());
        R.SetRange(Dtm, CreateDateTime(20240301D, 000000T), CreateDateTime(20240324D, 235959.998T));
        Observer.Observe('to .998 count', Format(R.Count()));
        R.SetRange(Dtm, CreateDateTime(20240301D, 000000T), CreateDateTime(20240324D, 235959.996T));
        Observer.Observe('to .996 count', Format(R.Count()));
        R.SetRange(Dtm, CreateDateTime(20240325D, 000000.001T));
        Observer.Observe('eq .001 count', Format(R.Count()));
        R.SetRange(Dtm, CreateDateTime(20240324D, 235959.999T));
        Observer.Observe('eq prev .999 count', Format(R.Count()));
        R.SetRange(Dtm);
        R.SetRange(Tm, 120000.001T);
        Observer.Observe('time eq .001 count', Format(R.Count()));
        R.SetRange(Tm, 120000.002T);
        Observer.Observe('time eq .002 count', Format(R.Count()));
        Observer.Expect('to .999 count', '2');
        Observer.Expect('to .999 getfilters', 'Dtm: 03/01/24 12:00 AM..03/24/24 11:59:59.999 PM');
        Observer.Expect('to .998 count', '1');
        Observer.Expect('to .996 count', '1');
        Observer.Expect('eq .001 count', '1');
        Observer.Expect('eq prev .999 count', '1');
        Observer.Expect('time eq .001 count', '1');
        Observer.Expect('time eq .002 count', '0');
        Observer.Verify();
    end;

    // Builds the values inside the asserterror (DMY2Date, ClosingDate, CreateDateTime), so an error of any step is captured; Stage names
    // the step that ran last.
    local procedure StoreDates(var Observer: Codeunit "Probe Observer"; Name: Text; Y: Integer; Mo: Integer; Dd: Integer; Closing: Boolean; DtY: Integer; DtMo: Integer; DtDd: Integer; DtTime: Time)
    var
        R: Record "LT P130 Filter Row";
        Back: Record "LT P130 Filter Row";
        D: Date;
        DT: DateTime;
        Stage: Text;
    begin
        R.DeleteAll();
        ClearLastError();
        asserterror begin
            Stage := 'date';
            if Y <> 0 then
                D := DMY2Date(Dd, Mo, Y);
            Stage := 'closingdate';
            if Closing then
                D := ClosingDate(D);
            Stage := 'createdatetime';
            if DtY <> 0 then
                DT := CreateDateTime(DMY2Date(DtDd, DtMo, DtY), DtTime);
            Stage := 'insert';
            R.Init();
            R.Id := 900;
            R.Dt := D;
            R.Dtm := DT;
            R.Insert();
            Stage := 'get';
            Back.Get(900);
            Stage := 'stored';
            Error('stored:' + Format(Back.Dt, 0, 9) + '|' + Format(Back.Dtm, 0, 9) + '|' + Format(Back.Dt = D) + '|' + Format(Back.Dtm = DT));
        end;
        Observer.Observe(Name + '|stage', Stage);
        Observer.ObserveError(Name);
    end;

    // Corpus issue 672 item 8: Insert of a Date and a DateTime outside the SQL datetime range (before 1753-01-01, after
    // 9999-12-31 23:59:59.997) and of 0D / 0DT: the step that failed and its error, or what Get reads back
    // (stored:Dt | Dtm | Dt = written | Dtm = written).
    [Test]
    procedure BT_DateAndDateTime_SqlRangeOnInsert()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StoreDates(Observer, 'blank', 0, 0, 0, false, 0, 0, 0, 0T);
        StoreDates(Observer, 'date 1753-01-01', 1753, 1, 1, false, 0, 0, 0, 0T);
        StoreDates(Observer, 'date 1752-12-31', 1752, 12, 31, false, 0, 0, 0, 0T);
        StoreDates(Observer, 'date 0001-01-01', 1, 1, 1, false, 0, 0, 0, 0T);
        StoreDates(Observer, 'date closing 1752-12-31', 1752, 12, 31, true, 0, 0, 0, 0T);
        StoreDates(Observer, 'datetime 1753-01-01 00:00', 0, 0, 0, false, 1753, 1, 1, 000000T);
        StoreDates(Observer, 'datetime 1752-12-31 12:00', 0, 0, 0, false, 1752, 12, 31, 120000T);
        Observer.Expect('blank|stage', 'stored');
        Observer.Expect('blank|text', 'stored:||Yes|Yes');
        Observer.Expect('blank|code', 'Dialog');
        Observer.Expect('date 1753-01-01|stage', 'get');
        Observer.Expect('date 1753-01-01|text', 'Cannot write the value 01/01/1753 to the field Dt in the table LT P130 Filter Row because the value is either too long or the content is invalid.');
        Observer.Expect('date 1753-01-01|code', 'NDBCS:BadCSideData');
        Observer.Expect('date 1752-12-31|stage', 'get');
        Observer.Expect('date 1752-12-31|text', 'Cannot write the value 12/31/1752 to the field Dt in the table LT P130 Filter Row because the value is either too long or the content is invalid.');
        Observer.Expect('date 1752-12-31|code', 'NDBCS:BadCSideData');
        Observer.Expect('date 0001-01-01|stage', 'stored');
        Observer.Expect('date 0001-01-01|text', 'stored:||Yes|Yes');
        Observer.Expect('date 0001-01-01|code', 'Dialog');
        Observer.Expect('date closing 1752-12-31|stage', 'get');
        Observer.Expect('date closing 1752-12-31|text', 'Cannot write the value C12/31/1752 to the field Dt in the table LT P130 Filter Row because the value is either too long or the content is invalid.');
        Observer.Expect('date closing 1752-12-31|code', 'NDBCS:BadCSideData');
        Observer.Expect('datetime 1753-01-01 00:00|stage', 'get');
        Observer.Expect('datetime 1753-01-01 00:00|text', 'Cannot write the value 01/01/1753 12:00 AM to the field Dtm in the table LT P130 Filter Row because the value is either too long or the content is invalid.');
        Observer.Expect('datetime 1753-01-01 00:00|code', 'NDBCS:BadCSideData');
        Observer.Expect('datetime 1752-12-31 12:00|stage', 'get');
        Observer.Expect('datetime 1752-12-31 12:00|text', 'Cannot write the value 12/31/1752 12:00 PM to the field Dtm in the table LT P130 Filter Row because the value is either too long or the content is invalid.');
        Observer.Expect('datetime 1752-12-31 12:00|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    // Corpus issue 672 item 8, upper end of the SQL datetime range (same form as BT_DateAndDateTime_SqlRangeOnInsert).
    [Test]
    procedure BT_DateAndDateTime_SqlRangeOnInsert_Max()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StoreDates(Observer, 'datetime 9999-12-31 23:59:59.997', 0, 0, 0, false, 9999, 12, 31, 235959.997T);
        StoreDates(Observer, 'datetime 9999-12-31 23:59:59.999', 0, 0, 0, false, 9999, 12, 31, 235959.999T);
        Observer.Expect('datetime 9999-12-31 23:59:59.997|stage', 'stored');
        Observer.Expect('datetime 9999-12-31 23:59:59.997|text', 'stored:|9999-12-31T23:59:59.997Z|Yes|Yes');
        Observer.Expect('datetime 9999-12-31 23:59:59.997|code', 'Dialog');
        Observer.Expect('datetime 9999-12-31 23:59:59.999|stage', 'get');
        Observer.Expect('datetime 9999-12-31 23:59:59.999|text', 'Cannot write the value 12/31/9999 11:59 PM to the field Dtm in the table LT P130 Filter Row because the value is either too long or the content is invalid.');
        Observer.Expect('datetime 9999-12-31 23:59:59.999|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;
}
