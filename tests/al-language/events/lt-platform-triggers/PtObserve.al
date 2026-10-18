// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-types
// Scope: in-scope
// Fixtures used: Probe Observer (69160); PtFixtures.al (69880, 69881) and PtObjects.al (69882-69885, 70480)
// BC versions: 27.0 to 29.0
// Round 1 (observe only): every question is asked with the log mode 0 (subscribers silent), 1 (log) and 2 (log and change the var parameters).

codeunit 69886 "LT W Pt Observe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Short(Value: Text): Text
    begin
        exit(CopyStr(Value, 1, 330));
    end;

    local procedure Act(Which: Text)
    var
        Log: Codeunit "LT W Pt Log";
        Mode: Integer;
        Ok: Boolean;
        Err: Text;
        FirstErr: Text;
        Res: Text;
        LogText: Text;
    begin
        for Mode := 0 to 3 do begin
            Log.SetMode(Mode);
            Log.Reset();
            Log.SetWhich(Which);
            Ok := Codeunit.Run(Codeunit::"LT W Pt Runner");
            Err := '';
            if not Ok then
                Err := GetLastErrorText();
            ClearLastError();
            Log.SetMode(0);
            Res := Log.Result();
            // the host name and the build numbers differ from run to run
            if Which in ['appver', 'appbuild', 'buildfile', 'platfile', 'geturl'] then
                Res := Format(Res <> '');
            LogText := Log.Dump();
            // the second event of a failed DateTime filter carries a text made from the work date
            if (Which = 'baddatetime') and (Mode = 2) then
                LogText := 'count=' + Format(Log.Count());
            if Mode = 0 then begin
                FirstErr := Err;
                Observer.Observe(Which + '|err', Err);
            end else
                Observer.Observe(Which + '|m' + Format(Mode) + '|err-same', Format(Err = FirstErr));
            Observer.Observe(Which + '|m' + Format(Mode), 'ok=' + Format(Ok) + ' res=' + Res + ' log=' + Short(LogText));
        end;
    end;

    [Test]
    procedure Version()
    begin
        Act('appver');
        Act('appbuild');
        Act('buildfile');
        Act('platfile');
        Observer.Finish();
    end;

    [Test]
    procedure Round_Format()
    begin
        Act('round');
        Act('format');
        Act('evaluate');
        Observer.Finish();
    end;

    [Test]
    procedure Captions()
    begin
        Act('fieldcap');
        Act('fieldcaptxt');
        Observer.Finish();
    end;

    [Test]
    procedure Filter_Date()
    begin
        Act('datefilter');
        Act('datefiltertext');
        Observer.Finish();
    end;

    [Test]
    procedure Filter_DateTime_Time()
    begin
        Act('datetimefilter');
        Act('timefilter');
        Observer.Finish();
    end;

    [Test]
    procedure Filter_View()
    begin
        Act('view');
        Observer.Finish();
    end;

    [Test]
    procedure Bad_Date()
    begin
        Act('baddate');
        Act('baddate2');
        Observer.Finish();
    end;

    [Test]
    procedure Bad_DateTime()
    begin
        Act('baddatetime');
        Observer.Finish();
    end;

    [Test]
    procedure Bad_Time()
    begin
        Act('badtime');
        Observer.Finish();
    end;

    [Test]
    procedure Bad_Int()
    begin
        Act('badint');
        Observer.Finish();
    end;

    [Test]
    procedure Bad_Decimal()
    begin
        Act('baddec');
        Observer.Finish();
    end;

    [Test]
    procedure Notifications()
    begin
        Act('mynotif');
        Act('mynotifoff');
        Observer.Finish();
    end;

    [Test]
    procedure GetUrl_Copilot()
    begin
        Act('geturl');
        Act('copilotactive');
        Observer.Finish();
    end;

    [Test]
    procedure Privacy_Feature()
    begin
        Act('privstate');
        Act('feature');
        Observer.Finish();
    end;

    [Test]
    procedure LegacyBar()
    begin
        Act('legacybar');
        Observer.Finish();
    end;

    [Test]
    procedure Report_Xml()
    begin
        Act('saveasxml');
        Observer.Finish();
    end;

    [Test]
    procedure Report_Pdf()
    begin
        Act('saveaspdf');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PageH')]
    procedure PageRun_Zero()
    begin
        Act('pagerun0');
        Observer.Finish();
    end;

    [PageHandler]
    procedure PageH(var P: TestPage "LT W Pt Card")
    begin
    end;

    local procedure Seed()
    var
        Row: Record "LT W Pt Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row."Code Value" := 'ALPHA';
        Row.Txt := 'first';
        Row.Amount := 1234.5;
        Row.D := DMY2Date(15, 3, 2020);
        Row.DT := CreateDateTime(DMY2Date(15, 3, 2020), 130000T);
        Row.T := 130000T;
        Row.Cnt := 7;
        Row.Cap := 'X';
        Row.Insert();
    end;

    [Test]
    procedure TestPage_List()
    var
        Log: Codeunit "LT W Pt Log";
        List: TestPage "LT W Pt List";
        Mode: Integer;
    begin
        Seed();
        for Mode := 0 to 2 do begin
            Log.SetMode(Mode);
            Log.Reset();
            List.OpenView();
            Observer.Observe('open|m' + Format(Mode), Short(Log.Dump()));
            Observer.Observe('amount|m' + Format(Mode), List.AmountCtl.Value());
            Observer.Observe('log-after-amount|m' + Format(Mode), Short(Log.Dump()));
            Log.Reset();
            List.Filter.SetFilter(D, '>=' + Format(DMY2Date(1, 1, 2020)));
            Observer.Observe('datefilter|m' + Format(Mode), Short(Log.Dump()));
            Log.Reset();
            List.Filter.SetFilter(DT, '>=' + Format(CreateDateTime(DMY2Date(1, 1, 2020), 120000T)));
            Observer.Observe('datetimefilter|m' + Format(Mode), Short(Log.Dump()));
            Log.Reset();
            List.Filter.SetFilter(T, '>=' + Format(120000T));
            Observer.Observe('timefilter|m' + Format(Mode), Short(Log.Dump()));
            Log.Reset();
            List.Close();
            Observer.Observe('close|m' + Format(Mode), Short(Log.Dump()));
            Log.SetMode(0);
        end;
        Observer.Finish();
    end;

    [Test]
    procedure TestPage_BadFilter()
    var
        Log: Codeunit "LT W Pt Log";
        List: TestPage "LT W Pt List";
    begin
        Seed();
        List.OpenView();
        Log.SetMode(1);
        Log.Reset();
        asserterror List.Filter.SetFilter(D, 'abc');
        Observer.ObserveError('baddate-m1');
        Observer.Observe('baddate-m1-log', Short(Log.Dump()));
        Log.SetMode(3);
        Log.Reset();
        List.Filter.SetFilter(D, 'abc');
        Observer.Observe('baddate-m3-log', Short(Log.Dump()));
        Observer.Observe('baddate-m3-filter', List.Filter.GetFilter(D));
        Observer.Observe('baddate-m3-rows', Format(List.First()));
        Log.SetMode(0);
        List.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TestPage_CardCue()
    var
        Log: Codeunit "LT W Pt Log";
        Card: TestPage "LT W Pt Card";
        Mode: Integer;
    begin
        Seed();
        for Mode := 0 to 2 do begin
            Log.SetMode(Mode);
            Log.Reset();
            Card.OpenEdit();
            Observer.Observe('open|m' + Format(Mode), Short(Log.Dump()));
            Observer.Observe('cue|m' + Format(Mode), Card.CntCue.Value());
            Observer.Observe('amount|m' + Format(Mode), Card.AmountCtl.Value());
            Observer.Observe('log-after-reads|m' + Format(Mode), Short(Log.Dump()));
            Log.Reset();
            Card.Close();
            Observer.Observe('close|m' + Format(Mode), Short(Log.Dump()));
            Log.SetMode(0);
        end;
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('FilterPageH')]
    procedure FilterPageBuilder_Run()
    var
        Log: Codeunit "LT W Pt Log";
        Fpb: FilterPageBuilder;
        PtRow: Record "LT W Pt Row";
        Mode: Integer;
        Ok: Boolean;
    begin
        for Mode := 0 to 2 do begin
            Log.SetMode(Mode);
            Log.Reset();
            Clear(Fpb);
            Fpb.AddTable('Rows', Database::"LT W Pt Row");
            Fpb.AddField('Rows', PtRow.D);
            Fpb.AddField('Rows', PtRow.Cap);
            Fpb.SetView('Rows', 'WHERE(D=FILTER(010120..))');
            Ok := Fpb.RunModal();
            Observer.Observe('runmodal|m' + Format(Mode), Format(Ok));
            Observer.Observe('view|m' + Format(Mode), Fpb.GetView('Rows', false));
            Observer.Observe('log-after-view|m' + Format(Mode), Short(Log.Dump()));
            Log.SetMode(0);
        end;
        Observer.Finish();
    end;

    [FilterPageHandler]
    procedure FilterPageH(var Rec: RecordRef): Boolean
    begin
        exit(true);
    end;
}
