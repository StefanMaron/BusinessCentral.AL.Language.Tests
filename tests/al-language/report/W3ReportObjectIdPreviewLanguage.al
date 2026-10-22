//sub:report
// CurrReport.ObjectId (md:666), CurrReport.Preview (md:671), CurrReport.Language and FormatRegion (md:471).
// The report ids in observed texts are replaced by <id>.

codeunit 67756 "W3 ObjId Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

report 67757 "W3 ObjId Cap"
{
    ProcessingOnly = true;
    UseRequestPage = false;
    Caption = 'W3 ObjId Caption';

    dataset
    {
        dataitem(Row; "W3 Row")
        {
        }
    }

    var
        L: Codeunit "W3 ObjId Log";

    trigger OnPreReport()
    begin
        L.Add('pre: names=' + CurrReport.ObjectId(true) + ' ids=' + CurrReport.ObjectId(false) + ' preview=' + Format(CurrReport.Preview()));
    end;
}

report 67758 "W3 ObjId NoCap"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
        }
    }

    var
        L: Codeunit "W3 ObjId Log";

    trigger OnPreReport()
    begin
        L.Add('pre: names=' + CurrReport.ObjectId(true) + ' ids=' + CurrReport.ObjectId(false) + ' preview=' + Format(CurrReport.Preview()));
    end;
}

// Not ProcessingOnly, with a request page, so SaveAs and the request page actions can reach OnPreReport.
report 67759 "W3 ObjId Save"
{
    ProcessingOnly = false;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            column(Id; Id) { }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Ctl; CtlVal)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        CtlVal: Integer;
        L: Codeunit "W3 ObjId Log";

    trigger OnPreReport()
    begin
        L.Add('pre: names=' + CurrReport.ObjectId(true) + ' ids=' + CurrReport.ObjectId(false) + ' preview=' + Format(CurrReport.Preview()));
    end;
}

// Language and FormatRegion set in OnPreReport; the columns hold values that depend on the culture.
report 67760 "W3 Lang Rpt"
{
    ProcessingOnly = false;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            column(Id; Id) { }
            column(DecC; DecVar) { }
            column(DateC; DateVar) { }
            column(DtC; DtVar) { }
            column(BoolC; BoolVar) { }

            trigger OnAfterGetRecord()
            begin
                DecVar := 1234.5;
                DateVar := DMY2Date(25, 12, 2024);
                DtVar := CreateDateTime(DateVar, 143005T);
                BoolVar := true;
            end;
        }
    }

    var
        DecVar: Decimal;
        DateVar: Date;
        DtVar: DateTime;
        BoolVar: Boolean;
        ModeValue: Text;
        L: Codeunit "W3 ObjId Log";

    procedure SetMode(NewMode: Text)
    begin
        ModeValue := NewMode;
    end;

    [TryFunction]
    local procedure TrySetLanguage(Value: Integer)
    begin
        CurrReport.Language := Value;
    end;

    [TryFunction]
    local procedure TrySetFormatRegion(Value: Text)
    begin
        CurrReport.FormatRegion := Value;
    end;

    local procedure Formats(): Text
    begin
        exit(Format(DMY2Date(25, 12, 2024)) + '|' + Format(1234.5) + '|' + Format(true));
    end;

    trigger OnPreReport()
    var
        Before: Text;
    begin
        L.Add('language before set equals GlobalLanguage=' + Format(CurrReport.Language = GlobalLanguage()) + ' region=[' + CurrReport.FormatRegion + ']');
        case ModeValue of
            'lang':
                begin
                    Before := Formats();
                    CurrReport.Language := 1031;
                    L.Add('language after set=' + Format(CurrReport.Language) + ' Format changed=' + Format(Before <> Formats()));
                end;
            'region':
                begin
                    Before := Formats();
                    CurrReport.FormatRegion := 'de-DE';
                    L.Add('region after set=[' + CurrReport.FormatRegion + '] Format changed=' + Format(Before <> Formats()));
                end;
            'both':
                begin
                    CurrReport.Language := 1031;
                    CurrReport.FormatRegion := 'de-DE';
                    L.Add('both set language=' + Format(CurrReport.Language) + ' region=[' + CurrReport.FormatRegion + ']');
                end;
            'rejects':
                begin
                    if TrySetLanguage(0) then
                        L.Add('Language 0 accepted')
                    else
                        L.Add('Language 0 error=' + GetLastErrorText() + ' code=' + GetLastErrorCode());
                    if TrySetLanguage(-1) then
                        L.Add('Language -1 accepted, reads ' + Format(CurrReport.Language))
                    else
                        L.Add('Language -1 error=' + GetLastErrorText() + ' code=' + GetLastErrorCode());
                    if TrySetLanguage(65536) then
                        L.Add('Language 65536 accepted, reads ' + Format(CurrReport.Language))
                    else
                        L.Add('Language 65536 error=' + GetLastErrorText() + ' code=' + GetLastErrorCode());
                    if TrySetLanguage(1) then
                        L.Add('Language 1 accepted, reads ' + Format(CurrReport.Language))
                    else
                        L.Add('Language 1 error=' + GetLastErrorText() + ' code=' + GetLastErrorCode());
                    L.Add('language after the rejects=' + Format(CurrReport.Language));
                end;
            'regions':
                begin
                    if TrySetFormatRegion('xx-YY') then
                        L.Add('region xx-YY accepted, reads [' + CurrReport.FormatRegion + ']')
                    else
                        L.Add('region xx-YY error=' + GetLastErrorText() + ' code=' + GetLastErrorCode());
                    if TrySetFormatRegion('de') then
                        L.Add('region de accepted, reads [' + CurrReport.FormatRegion + ']')
                    else
                        L.Add('region de error=' + GetLastErrorText() + ' code=' + GetLastErrorCode());
                    if TrySetFormatRegion('') then
                        L.Add('region empty accepted, reads [' + CurrReport.FormatRegion + ']')
                    else
                        L.Add('region empty error=' + GetLastErrorText() + ' code=' + GetLastErrorCode());
                    if TrySetFormatRegion('fr-FR') then
                        L.Add('region fr-FR accepted, reads [' + CurrReport.FormatRegion + ']')
                    else
                        L.Add('region fr-FR error=' + GetLastErrorText() + ' code=' + GetLastErrorCode());
                end;
        end;
    end;
}

codeunit 67761 "W3 ObjId Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "W3 ObjId Log";
        Dataset: Codeunit "W3 Dataset";
        Runner: Codeunit "W3 Runner";

    local procedure Seed()
    var
        Row: Record "W3 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Commit();
        L.Take();
    end;

    local procedure Mask(Value: Text): Text
    begin
        Value := Value.Replace(Format(Report::"W3 ObjId Cap"), '<cap>');
        Value := Value.Replace(Format(Report::"W3 ObjId NoCap"), '<nocap>');
        Value := Value.Replace(Format(Report::"W3 ObjId Save"), '<save>');
        exit(Value);
    end;

    [TryFunction]
    local procedure TrySetGlobalLanguage(Value: Integer)
    begin
        GlobalLanguage(Value);
    end;

    [TryFunction]
    local procedure TryInvokePreview(var RP: TestRequestPage "W3 ObjId Save")
    begin
        RP.Preview().Invoke();
    end;

    [TryFunction]
    local procedure TryCancel(var RP: TestRequestPage "W3 ObjId Save")
    begin
        RP.Cancel().Invoke();
    end;

    // md:666: the text of ObjectId on a report variable that has not run.
    [Test]
    procedure ObjectId_ReportVariable_WithAndWithoutCaption()
    var
        Observer: Codeunit "Probe Observer";
        Cap: Report "W3 ObjId Cap";
        NoCap: Report "W3 ObjId NoCap";
    begin
        Observer.Observe('Cap names', Mask(Cap.ObjectId(true)));
        Observer.Observe('Cap ids', Mask(Cap.ObjectId(false)));
        Observer.Observe('NoCap names', Mask(NoCap.ObjectId(true)));
        Observer.Observe('NoCap ids', Mask(NoCap.ObjectId(false)));
        Observer.Expect('Cap names', 'Report W3 ObjId Caption');
        Observer.Expect('Cap ids', 'Report <cap>');
        Observer.Expect('NoCap names', 'Report W3 ObjId NoCap');
        Observer.Expect('NoCap ids', 'Report <nocap>');
        Observer.Verify();
    end;

    // md:666: CurrReport.ObjectId inside a trigger, the same two reports.
    [Test]
    procedure ObjectId_CurrReport_InOnPreReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"W3 ObjId Cap");
        Report.Run(Report::"W3 ObjId NoCap");
        Observer.Observe('log', Mask(L.Take()));
        Observer.Expect('log', 'pre: names=Report W3 ObjId Caption ids=Report <cap> preview=No;pre: names=Report W3 ObjId NoCap ids=Report <nocap> preview=No;');
        Observer.Verify();
    end;

    // md:666: does the text with names depend on the session language?
    [Test]
    procedure ObjectId_WithAnotherGlobalLanguage()
    var
        Observer: Codeunit "Probe Observer";
        Cap: Report "W3 ObjId Cap";
        NoCap: Report "W3 ObjId NoCap";
        OldLanguage: Integer;
        Ok: Boolean;
    begin
        OldLanguage := GlobalLanguage();
        Ok := TrySetGlobalLanguage(1031);
        Observer.Observe('set 1031 ok', Format(Ok));
        Observer.ObserveError('set 1031');
        if Ok then begin
            Observer.Observe('Cap names', Mask(Cap.ObjectId(true)));
            Observer.Observe('NoCap names', Mask(NoCap.ObjectId(true)));
            Observer.Observe('Cap ids', Mask(Cap.ObjectId(false)));
        end;
        TrySetGlobalLanguage(OldLanguage);
        Observer.Observe('language restored', Format(GlobalLanguage() = OldLanguage));
        Observer.Expect('set 1031 ok', 'Ja');
        Observer.Expect('set 1031|text', '');
        Observer.Expect('set 1031|code', '');
        Observer.Expect('Cap names', 'Report W3 ObjId Caption');
        Observer.Expect('NoCap names', 'Report W3 ObjId NoCap');
        Observer.Expect('Cap ids', 'Report <cap>');
        Observer.Expect('language restored', 'Yes');
        Observer.Verify();
    end;

    // md:671: CurrReport.Preview in OnPreReport for each way to run.
    [Test]
    procedure Preview_ReportRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"W3 ObjId Cap");
        Observer.Observe('log', Mask(L.Take()));
        Observer.Expect('log', 'pre: names=Report W3 ObjId Caption ids=Report <cap> preview=No;');
        Observer.Verify();
    end;

    [Test]
    procedure Preview_ReportRunModal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.RunModal(Report::"W3 ObjId Cap");
        Observer.Observe('log', Mask(L.Take()));
        Observer.Expect('log', 'pre: names=Report W3 ObjId Caption ids=Report <cap> preview=No;');
        Observer.Verify();
    end;

    [Test]
    procedure Preview_ReportExecute()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Execute(Report::"W3 ObjId Cap", '');
        Observer.Observe('log', Mask(L.Take()));
        Observer.Expect('log', 'pre: names=Report W3 ObjId Caption ids=Report <cap> preview=Yes;');
        Observer.Verify();
    end;

    [Test]
    procedure Preview_ReportSaveAs()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
    begin
        Seed();
        Observer.Observe('saved', Format(Dataset.Save(Report::"W3 ObjId Save", '', Xml)));
        Observer.Observe('log', Mask(L.Take()));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('log', 'pre: names=Report W3 ObjId Save ids=Report <save> preview=No;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PreviewActionHandler')]
    procedure Preview_RequestPagePreviewAction()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Runner.Exec(Report::"W3 ObjId Save", 0, '', Result);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('log', Mask(L.Take()));
        Observer.Expect('ok', 'No');
        Observer.Expect('error|text', 'Report 67759 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('error|code', 'ReportNoLayout');
        Observer.Expect('log', 'Preview action invoked;Cancel after Preview error=The TestPage is not open.;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure PreviewActionHandler(var RP: TestRequestPage "W3 ObjId Save")
    begin
        if TryInvokePreview(RP) then
            L.Add('Preview action invoked')
        else
            L.Add('Preview action error=' + GetLastErrorText());
        if not TryCancel(RP) then
            L.Add('Cancel after Preview error=' + GetLastErrorText());
    end;

    local procedure LangRun(Mode: Text; var Observer: Codeunit "Probe Observer")
    var
        Rpt: Report "W3 Lang Rpt";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Xml: Text;
    begin
        Seed();
        Rpt.SetMode(Mode);
        TempBlob.CreateOutStream(OutS);
        Rpt.SaveAs('', ReportFormat::Xml, OutS);
        Xml := Dataset.ReadAll(TempBlob);
        Observer.Observe('log', L.Take());
        Observer.Observe('columns', Dataset.ColumnLines(Xml));
        Observer.Observe('item language', Dataset.ItemAttribute(Xml, 1, 'language'));
        Observer.Observe('item formatRegion', Dataset.ItemAttribute(Xml, 1, 'formatRegion'));
    end;

    // md:471: Language before any set, after Language := 1031, and the columns afterwards.
    [Test]
    procedure Language_NoSet_ReadsTheSessionLanguage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        LangRun('', Observer);
        Observer.Expect('log', 'language before set equals GlobalLanguage=Yes region=[];');
        Observer.Expect('columns', '<Column name="Id">1</Column>|<Column name="DecC" decimalformatter="#,##0.00">1234.5</Column>|<Column name="DateC">12/25/2024</Column>|<Column name="DtC">12/25/2024 2:30:05 PM</Column>|<Column name="BoolC">True</Column>|');
        Observer.Expect('item language', 'en-US');
        Observer.Expect('item formatRegion', 'en-US');
        Observer.Verify();
    end;

    [Test]
    procedure Language_Set1031_FormatAndColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        LangRun('lang', Observer);
        Observer.Expect('log', 'language before set equals GlobalLanguage=Yes region=[];language after set=1031 Format changed=Ja;');
        Observer.Expect('columns', '<Column name="Id">1</Column>|<Column name="DecC" decimalformatter="#,##0.00">1234.5</Column>|<Column name="DateC">12/25/2024</Column>|<Column name="DtC">12/25/2024 2:30:05 PM</Column>|<Column name="BoolC">True</Column>|');
        Observer.Expect('item language', 'de-DE');
        Observer.Expect('item formatRegion', 'en-US');
        Observer.Verify();
    end;

    [Test]
    procedure FormatRegion_SetDeDE_FormatAndColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        LangRun('region', Observer);
        Observer.Expect('log', 'language before set equals GlobalLanguage=Yes region=[];region after set=[de-DE] Format changed=Yes;');
        Observer.Expect('columns', '<Column name="Id">1</Column>|<Column name="DecC" decimalformatter="#,##0.00">1234,5</Column>|<Column name="DateC">25.12.2024</Column>|<Column name="DtC">25.12.2024 14:30:05</Column>|<Column name="BoolC">True</Column>|');
        Observer.Expect('item language', 'en-US');
        Observer.Expect('item formatRegion', 'de-DE');
        Observer.Verify();
    end;

    [Test]
    procedure LanguageAndFormatRegion_BothSet_Columns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        LangRun('both', Observer);
        Observer.Expect('log', 'language before set equals GlobalLanguage=Yes region=[];both set language=1031 region=[de-DE];');
        Observer.Expect('columns', '<Column name="Id">1</Column>|<Column name="DecC" decimalformatter="#,##0.00">1234,5</Column>|<Column name="DateC">25.12.2024</Column>|<Column name="DtC">25.12.2024 14:30:05</Column>|<Column name="BoolC">True</Column>|');
        Observer.Expect('item language', 'de-DE');
        Observer.Expect('item formatRegion', 'de-DE');
        Observer.Verify();
    end;

    [Test]
    procedure Language_RejectedValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        LangRun('rejects', Observer);
        Observer.Expect('log', 'language before set equals GlobalLanguage=Yes region=[];Language 0 error=Invalid language ID supplied: 0. code=Argument;Language -1 accepted, reads 1033;Language 65536 error=An unsupported language was selected (''65536'' - ''Requested culture is not supported by the current platform''). code=ReportLanguageNotFound;Language 1 error=An unsupported language was selected (''1'' - ''Requested culture is not supported by the current platform''). code=ReportLanguageNotFound;language after the rejects=1033;');
        Observer.Expect('columns', '<Column name="Id">1</Column>|<Column name="DecC" decimalformatter="#,##0.00">1234.5</Column>|<Column name="DateC">12/25/2024</Column>|<Column name="DtC">12/25/2024 2:30:05 PM</Column>|<Column name="BoolC">True</Column>|');
        Observer.Expect('item language', 'en-US');
        Observer.Expect('item formatRegion', 'en-US');
        Observer.Verify();
    end;

    [Test]
    procedure FormatRegion_OddValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        LangRun('regions', Observer);
        Observer.Expect('log', 'language before set equals GlobalLanguage=Yes region=[];region xx-YY error=An unsupported language was selected (''xx-YY'' - ''Requested culture is not supported by the current platform''). code=ReportFormatCultureNotFound;region de error=An unsupported language was selected (''de'' - ''Requested culture is not supported by the current platform''). code=ReportFormatCultureNotFound;region empty error=Invalid language ID supplied: 0. code=Argument;region fr-FR accepted, reads [fr-FR];');
        Observer.Expect('columns', '<Column name="Id">1</Column>|<Column name="DecC" decimalformatter="#,##0.00">1234,5</Column>|<Column name="DateC">25/12/2024</Column>|<Column name="DtC">25/12/2024 14:30:05</Column>|<Column name="BoolC">True</Column>|');
        Observer.Expect('item language', 'en-US');
        Observer.Expect('item formatRegion', 'fr-FR');
        Observer.Verify();
    end;
}
