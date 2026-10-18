// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT AM Log, LT AM Word/Excel/Rdlc Rpt and LT AM Subscribers of AMReports.al
// What Report.SaveAs puts in the stream for a report with a Word, an Excel or an RDLC layout, per ReportFormat: whether it saves, the file
// signature (pdf, zip, markup), the zip entries, the PDF page count, whether a request page value reaches the output, and the order of
// SubstituteReport, OnPreRendering and OnDocumentReady on a real render. PDF bytes are never compared (not stable).
// BC versions: 27 - 29

codeunit 79255 "LT AM Report Output Tests"
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

    local procedure ZipFacts(var TempBlob: Codeunit "Temp Blob"; var Entries: Text; var WithReq: Text; var WithMark: Text)
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
                Content := AllText(EntryBlob, TextEncoding::UTF8);
                if Content.Contains('AMREQ42') then
                    WithReq += Name + ',';
                if Content.Contains('AMMARK') then
                    WithMark += Name + ',';
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
        WithReq: Text;
        WithMark: Text;
        Txt: Text;
    begin
        AmLog.Start();
        ClearLastError();
        Ok := TrySaveAs(ReportId, Fmt, TempBlob, Saved);
        Observer.Observe('log', AmLog.Take());
        Observer.Observe('ok', Format(Ok));
        if not Ok then
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
                    ZipFacts(TempBlob, Entries, WithReq, WithMark);
                    Observer.Observe('main_part', Format(Entries.Contains('word/document.xml,')) + '/' + Format(Entries.Contains('xl/workbook.xml,')));
                    Observer.Observe('entries_with_request_value', WithReq);
                    Observer.Observe('entries_with_constant_column', WithMark);
                end;
            'markup':
                begin
                    Txt := AllText(TempBlob, TextEncoding::UTF8);
                    Observer.Observe('has_request_value', Format(Txt.Contains('AMREQ42')));
                    Observer.Observe('has_constant_column', Format(Txt.Contains('AMMARK')));
                end;
        end;
    end;

    [Test]
    procedure WordLayout_SaveAsPdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Word Rpt", ReportFormat::Pdf);
        Observer.Finish();
    end;

    [Test]
    procedure WordLayout_SaveAsWord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Word Rpt", ReportFormat::Word);
        Observer.Finish();
    end;

    [Test]
    procedure WordLayout_SaveAsHtml()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Word Rpt", ReportFormat::Html);
        Observer.Finish();
    end;

    [Test]
    procedure WordLayout_SaveAsExcel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Word Rpt", ReportFormat::Excel);
        Observer.Finish();
    end;

    [Test]
    procedure ExcelLayout_SaveAsExcel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Excel Rpt", ReportFormat::Excel);
        Observer.Finish();
    end;

    [Test]
    procedure ExcelLayout_SaveAsPdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Excel Rpt", ReportFormat::Pdf);
        Observer.Finish();
    end;

    [Test]
    procedure RdlcLayout_SaveAsPdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Rdlc Rpt", ReportFormat::Pdf);
        Observer.Finish();
    end;

    [Test]
    procedure RdlcLayout_SaveAsWord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Rdlc Rpt", ReportFormat::Word);
        Observer.Finish();
    end;

    [Test]
    procedure RdlcLayout_SaveAsExcel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Rdlc Rpt", ReportFormat::Excel);
        Observer.Finish();
    end;

    [Test]
    procedure RdlcLayout_SaveAsHtml()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Rdlc Rpt", ReportFormat::Html);
        Observer.Finish();
    end;
}
