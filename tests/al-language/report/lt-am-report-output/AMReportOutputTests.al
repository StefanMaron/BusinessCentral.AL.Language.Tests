// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT AM Log, LT AM Word/Excel/Rdlc Rpt and LT AM Subscribers of AMReports.al
// What Report.SaveAs puts in the stream for a report with a Word, an Excel or an RDLC layout, per ReportFormat: whether it saves, the file
// signature (pdf, zip, markup), the zip entries, the PDF page count, whether a request page value reaches the output, and the order of
// SubstituteReport, OnPreRendering and OnDocumentReady on a real render. PDF bytes are never compared (not stable).
// Not pinned: report 79253 (RDLC layout). The Linux tier of the CI stubs the RDLC renderer: SaveAs returns false with no output for Pdf, Word,
// Excel and Html, so nothing it does after the refusal is Business Central's. It gets tests once the corpus CI runs with BC_RDLC_RENDERER=mono.
// Word layout to Excel and Excel layout to Pdf return false without an error and without OnPreRendering on every leg (27.5, 28.5, 29.0);
// these two rows are worth a look on the Windows nightly. The generated Word layout has no content controls, so neither the request value nor
// a column value appears in the Word, Html or PDF output; the Excel layout writes both into its data sheet.
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

    [TryFunction]
    local procedure TryAllText(var TempBlob: Codeunit "Temp Blob"; Encoding: TextEncoding; var Content: Text)
    begin
        Content := AllText(TempBlob, Encoding);
    end;

    local procedure ZipFacts(var TempBlob: Codeunit "Temp Blob"; var Entries: Text; var WithReq: Text; var WithMark: Text; var Unreadable: Text)
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
        Unreadable: Text;
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
                    ZipFacts(TempBlob, Entries, WithReq, WithMark, Unreadable);
                    Observer.Observe('main_part', Format(Entries.Contains('word/document.xml,')) + '/' + Format(Entries.Contains('xl/workbook.xml,')));
                    Observer.Observe('entries_with_request_value', WithReq);
                    Observer.Observe('entries_with_constant_column', WithMark);
                    Observer.Observe('unreadable_parts', Unreadable);
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
        Observer.Expect('log', 'SubstituteReport(79251,SaveAs,req=Yes);OnPreRendering();OnDocumentReady(79251,keys=19,documenttype=application/pdf,layoutmimetype=Application/ReportLayout/Word,layoutname=LtAmWordLayout,objectname=LT AM Word Rpt,success=No);');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('has_output', 'Yes');
        Observer.Expect('kind', 'pdf');
        Observer.Expect('pdf_pages', '1');
        Observer.Verify();
    end;

    [Test]
    procedure WordLayout_SaveAsWord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Word Rpt", ReportFormat::Word);
        Observer.Expect('log', 'SubstituteReport(79251,SaveAs,req=Yes);OnPreRendering();OnDocumentReady(79251,keys=19,documenttype=application/vnd.openxmlformats-officedocument.wordprocessingml.document,layoutmimetype=Application/ReportLayout/Word,layoutname=LtAmWordLayout,objectname=LT AM Word Rpt,success=No);');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('has_output', 'Yes');
        Observer.Expect('kind', 'zip');
        Observer.Expect('main_part', 'Yes/No');
        Observer.Expect('entries_with_request_value', '');
        Observer.Expect('entries_with_constant_column', '');
        Observer.Expect('unreadable_parts', '');
        Observer.Verify();
    end;

    [Test]
    procedure WordLayout_SaveAsHtml()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Word Rpt", ReportFormat::Html);
        Observer.Expect('log', 'SubstituteReport(79251,SaveAs,req=Yes);OnPreRendering();OnDocumentReady(79251,keys=19,documenttype=text/html,layoutmimetype=Application/ReportLayout/Word,layoutname=LtAmWordLayout,objectname=LT AM Word Rpt,success=No);');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('has_output', 'Yes');
        Observer.Expect('kind', 'markup');
        Observer.Expect('has_request_value', 'No');
        Observer.Expect('has_constant_column', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure WordLayout_SaveAsExcel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Word Rpt", ReportFormat::Excel);
        Observer.Expect('log', 'SubstituteReport(79251,SaveAs,req=Yes);');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('saved', 'No');
        Observer.Expect('has_output', 'No');
        Observer.Expect('kind', 'empty');
        Observer.Verify();
    end;

    [Test]
    procedure ExcelLayout_SaveAsExcel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Excel Rpt", ReportFormat::Excel);
        Observer.Expect('log', 'SubstituteReport(79252,SaveAs,req=Yes);OnPreRendering();OnDocumentReady(79252,keys=19,documenttype=application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,layoutmimetype=Application/ReportLayout/Excel,layoutname=LtAmExcelLayout,objectname=LT AM Excel Rpt,success=No);');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('has_output', 'Yes');
        Observer.Expect('kind', 'zip');
        Observer.Expect('main_part', 'No/Yes');
        Observer.Expect('entries_with_request_value', 'xl/worksheets/sheet1.xml,');
        Observer.Expect('entries_with_constant_column', 'xl/worksheets/sheet1.xml,');
        Observer.Expect('unreadable_parts', '');
        Observer.Verify();
    end;

    [Test]
    procedure ExcelLayout_SaveAsPdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Excel Rpt", ReportFormat::Pdf);
        Observer.Expect('log', 'SubstituteReport(79252,SaveAs,req=Yes);');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('saved', 'No');
        Observer.Expect('has_output', 'No');
        Observer.Expect('kind', 'empty');
        Observer.Verify();
    end;
}
