// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT AM Log (79250) and report LT AM Rdlc Rpt (79253, generated RDLC layout with an empty body) of
// AMReports.al; self-contained report 79256 with the hand-written layout LtAmRdlcText.rdlc, test codeunit 79257, subscriber codeunit 79258
// What Report.SaveAs and Report.Run do with an RDLC layout (corpus #601 item 1, corpus CI with rdlc_renderer: true): per ReportFormat
// (Pdf, Word, Excel, Html) whether it saves, the file signature, the PDF page count, the zip main part, whether the text the layout computes
// from the dataset and the request page (AMTXT[...]) is in the output, and the order of SubstituteReport, OnPreRendering and OnDocumentReady.
// PDF bytes are never compared (not stable) and PDF text is compressed, so only its page count is asserted.
// BC versions: 27 - 29

report 79256 "LT AM Rdlc Text Rpt"
{
    DefaultRenderingLayout = LtAmRdlcText;

    dataset
    {
        dataitem(AmRow; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 3));
            column(AmNum; Number)
            {
            }
            column(AmReq; ReqText)
            {
            }
            column(AmMark; 'AMMARK')
            {
            }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(ReqText; ReqText)
                {
                    ApplicationArea = All;
                    Caption = 'Request text';
                }
            }
        }
    }

    rendering
    {
        layout(LtAmRdlcText)
        {
            Type = RDLC;
            LayoutFile = './report/lt-am-rdlc-output/LtAmRdlcText.rdlc';
        }
    }

    trigger OnPreRendering(var RenderingPayload: JsonObject)
    var
        Keys: Text;
        KeyName: Text;
    begin
        foreach KeyName in RenderingPayload.Keys() do
            Keys += KeyName + ',';
        AmLog.Add('OnPreRendering(' + Keys + ')');
    end;

    var
        AmLog: Codeunit "LT AM Log";
        ReqText: Text[30];
}

codeunit 79258 "LT AM Rdlc Subscribers"
{
    var
        AmLog: Codeunit "LT AM Log";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SubstituteReport', '', false, false)]
    local procedure AmSubstitute(ReportId: Integer; RunMode: Option Normal,ParametersOnly,Execute,Print,SaveAs,RunModal; RequestPageXml: Text; RecordRef: RecordRef; var NewReportId: Integer)
    begin
        if ReportId <> 79256 then
            exit;
        AmLog.Add('SubstituteReport(' + Format(ReportId) + ',' + Format(RunMode) + ',req=' + Format(StrPos(RequestPageXml, 'AMREQ42') > 0) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'OnDocumentReady', '', false, false)]
    local procedure AmDocumentReady(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var TargetStream: OutStream; var Success: Boolean)
    begin
        if ObjectId <> 79256 then
            exit;
        // The document stream is not read here: reading it could change what the caller receives.
        AmLog.Add('OnDocumentReady(' + Format(ObjectId) + ',keys=' + Format(ObjectPayload.Keys().Count()) + ',documenttype=' + Value(ObjectPayload, 'documenttype') +
            ',layoutmimetype=' + Value(ObjectPayload, 'layoutmimetype') + ',layoutname=' + Value(ObjectPayload, 'layoutname') + ',objectname=' + Value(ObjectPayload, 'objectname') +
            ',success=' + Format(Success) + ')');
    end;

    local procedure Value(Payload: JsonObject; KeyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not Payload.Get(KeyName, Token) then
            exit('<absent>');
        if not Token.IsValue() then
            exit('<not a value>');
        exit(Token.AsValue().AsText());
    end;
}

codeunit 79257 "LT AM Rdlc Output Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        AmLog: Codeunit "LT AM Log";
        RequestXmlTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters><Options><Field name="ReqText">AMREQ42</Field></Options></ReportParameters>', Locked = true;

    [TryFunction]
    local procedure TrySaveAs(ReportId: Integer; Fmt: ReportFormat; var TempBlob: Codeunit "Temp Blob"; var Saved: Boolean)
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Saved := Report.SaveAs(ReportId, RequestXmlTxt, Fmt, OutS);
    end;

    [TryFunction]
    local procedure TryRun(ReportId: Integer)
    begin
        Report.Run(ReportId, false, false);
    end;

    local procedure Head(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Txt: Text;
    begin
        if TempBlob.Length() = 0 then
            exit('empty');
        TempBlob.CreateInStream(InS, TextEncoding::Windows);
        InS.ReadText(Txt, 5);
        if Txt.StartsWith('%PDF-') then
            exit('pdf');
        if Txt.StartsWith('PK') then
            exit('zip');
        if Txt.StartsWith('<') then
            exit('markup');
        exit('other');
    end;

    local procedure AllText(var TempBlob: Codeunit "Temp Blob"; Encoding: TextEncoding): Text
    var
        InS: InStream;
        Line: Text;
        All: TextBuilder;
    begin
        TempBlob.CreateInStream(InS, Encoding);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            All.Append(Line);
            All.Append(' ');
        end;
        exit(All.ToText());
    end;

    [TryFunction]
    local procedure TryAllText(var TempBlob: Codeunit "Temp Blob"; Encoding: TextEncoding; var Content: Text)
    begin
        Content := AllText(TempBlob, Encoding);
    end;

    local procedure PdfPages(var TempBlob: Codeunit "Temp Blob"): Integer
    var
        Txt: Text;
        Pos: Integer;
        Pages: Integer;
    begin
        Txt := AllText(TempBlob, TextEncoding::Windows).Replace('/Type /Page', '/Type/Page');
        Pos := StrPos(Txt, '/Type/Page');
        while Pos > 0 do begin
            if CopyStr(Txt, Pos + 10, 1) <> 's' then
                Pages += 1;
            Txt := CopyStr(Txt, Pos + 10);
            Pos := StrPos(Txt, '/Type/Page');
        end;
        exit(Pages);
    end;

    // The text the layout computes, from 'AMTXT[' to the next ']', or '' when the output does not contain it.
    local procedure Marker(Content: Text): Text
    var
        Pos: Integer;
        Rest: Text;
    begin
        Pos := StrPos(Content, 'AMTXT[');
        if Pos = 0 then
            exit('');
        Rest := CopyStr(Content, Pos);
        Pos := StrPos(Rest, ']');
        if Pos = 0 then
            exit(CopyStr(Rest, 1, 80));
        exit(CopyStr(Rest, 1, Pos));
    end;

    local procedure ZipFacts(var TempBlob: Codeunit "Temp Blob"; var Entries: Text; var WithMarker: Text; var MarkerText: Text; var Unreadable: Text)
    var
        DataCompression: Codeunit "Data Compression";
        EntryBlob: Codeunit "Temp Blob";
        Names: List of [Text];
        Name: Text;
        InS: InStream;
        EntryOut: OutStream;
        Length: Integer;
        Content: Text;
    begin
        TempBlob.CreateInStream(InS);
        DataCompression.OpenZipArchive(InS, false);
        DataCompression.GetEntryList(Names);
        foreach Name in Names do begin
            Entries += Name + ',';
            // Only the XML parts are read as text; a binary part (an image, a thumbnail) cannot be read as UTF-8 text.
            if Name.EndsWith('.xml') or Name.EndsWith('.rels') then begin
                Clear(EntryBlob);
                EntryBlob.CreateOutStream(EntryOut);
                DataCompression.ExtractEntry(Name, EntryOut, Length);
                if not TryAllText(EntryBlob, TextEncoding::UTF8, Content) then
                    if not TryAllText(EntryBlob, TextEncoding::UTF16, Content) then begin
                        Content := '';
                        Unreadable += Name + ',';
                    end;
                if Marker(Content) <> '' then begin
                    WithMarker += Name + ',';
                    MarkerText := Marker(Content);
                end;
            end;
        end;
        DataCompression.CloseZipArchive();
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; ReportId: Integer; Fmt: ReportFormat)
    var
        TempBlob: Codeunit "Temp Blob";
        Saved: Boolean;
        Ok: Boolean;
        Kind: Text;
        Entries: Text;
        WithMarker: Text;
        MarkerText: Text;
        Unreadable: Text;
    begin
        AmLog.Start();
        ClearLastError();
        Ok := TrySaveAs(ReportId, Fmt, TempBlob, Saved);
        Observer.Observe('log', AmLog.Take());
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('saved', Format(Saved));
        Observer.Observe('has_output', Format(TempBlob.Length() > 0));
        Kind := Head(TempBlob);
        Observer.Observe('kind', Kind);
        case Kind of
            'pdf':
                Observer.Observe('pdf_pages', Format(PdfPages(TempBlob)));
            'zip':
                begin
                    ZipFacts(TempBlob, Entries, WithMarker, MarkerText, Unreadable);
                    Observer.Observe('main_part', Format(Entries.Contains('word/document.xml,')) + '/' + Format(Entries.Contains('xl/workbook.xml,')));
                    Observer.Observe('entries_with_marker', WithMarker);
                    Observer.Observe('marker', MarkerText);
                    Observer.Observe('unreadable_parts', Unreadable);
                end;
            'markup':
                Observer.Observe('marker', Marker(AllText(TempBlob, TextEncoding::UTF8)));
        end;
    end;

    [Test]
    procedure EmptyRdlc_SaveAsPdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Rdlc Rpt", ReportFormat::Pdf);
        Observer.Finish();
    end;

    [Test]
    procedure EmptyRdlc_SaveAsWord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Rdlc Rpt", ReportFormat::Word);
        Observer.Finish();
    end;

    [Test]
    procedure EmptyRdlc_SaveAsExcel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Rdlc Rpt", ReportFormat::Excel);
        Observer.Finish();
    end;

    [Test]
    procedure EmptyRdlc_SaveAsHtml()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Rdlc Rpt", ReportFormat::Html);
        Observer.Finish();
    end;

    [Test]
    procedure TextRdlc_SaveAsPdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Rdlc Text Rpt", ReportFormat::Pdf);
        Observer.Finish();
    end;

    [Test]
    procedure TextRdlc_SaveAsWord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Rdlc Text Rpt", ReportFormat::Word);
        Observer.Finish();
    end;

    [Test]
    procedure TextRdlc_SaveAsExcel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Rdlc Text Rpt", ReportFormat::Excel);
        Observer.Finish();
    end;

    [Test]
    procedure TextRdlc_SaveAsHtml()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Rdlc Text Rpt", ReportFormat::Html);
        Observer.Finish();
    end;

    [Test]
    procedure TextRdlc_SaveAsXml_DoesNotRender()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Rdlc Text Rpt", ReportFormat::Xml);
        Observer.Finish();
    end;

    [Test]
    procedure TextRdlc_Run_NoRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        AmLog.Start();
        ClearLastError();
        Ok := TryRun(Report::"LT AM Rdlc Text Rpt");
        Observer.Observe('log', AmLog.Take());
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Finish();
    end;
}
