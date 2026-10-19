// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveaspdf-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (File, TemporaryPath, Report.SaveAs* to a file name and TestRequestPage.SaveAs* are Scope = OnPrem)
// Fixtures used: Probe Observer (69160); self-contained table 98600, reports 98601 and 98602 (hand-written layouts LtAmOpSave.rdlc and
// LtAmOpRp.rdlc), helper codeunit 98605, test codeunits 98603 and 98604
// Corpus #595 items 4-11 and 16-18 with an RDLC layout (corpus CI with rdlc_renderer: true): Report.SaveAsExcel, SaveAsHtml, SaveAsPdf and
// SaveAsWord, static (report id, file name, record) and on a Report variable (with and without SetTableView); TestRequestPage.SaveAsExcel,
// SaveAsPdf and SaveAsWord from a request page handler. Per call: the return value, the last error, whether the file exists, its signature,
// and the text the layout computes from the rows it got (AMTXT[FIRST|LAST|ROWS]), so the Record filter is visible. PDF text is compressed:
// only its page count is asserted.
// BC versions: 27 - 29

table 98600 "LT AM OP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 98601 "LT AM OP Save Rpt"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = LtAmOpSave;

    dataset
    {
        dataitem(T; "LT AM OP Row")
        {
            column(Id; Id) { }
            column(Txt; Txt) { }
        }
    }

    rendering
    {
        layout(LtAmOpSave)
        {
            Type = RDLC;
            LayoutFile = './report/lt-am-rdlc-saveas/LtAmOpSave.rdlc';
        }
    }
}

report 98602 "LT AM OP RP Rpt"
{
    UsageCategory = None;
    DefaultRenderingLayout = LtAmOpRp;

    dataset
    {
        dataitem(T; "LT AM OP Row")
        {
            column(Id; Id) { }
            column(Txt; Txt) { }

            trigger OnPreDataItem()
            begin
                T.SetFilter(Id, '>=%1', Threshold);
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(ThresholdField; Threshold) { ApplicationArea = All; }
            }
        }
    }

    rendering
    {
        layout(LtAmOpRp)
        {
            Type = RDLC;
            LayoutFile = './report/lt-am-rdlc-saveas/LtAmOpRp.rdlc';
        }
    }

    var
        Threshold: Integer;
}

codeunit 98605 "LT AM OP File Facts"
{
    procedure Seed()
    var
        Row: Record "LT AM OP Row";
        Index: Integer;
    begin
        Row.DeleteAll();
        for Index := 1 to 4 do begin
            Row.Id := Index;
            Row.Txt := 'row' + Format(Index);
            Row.Insert();
        end;
        Commit();
    end;

    procedure FreshName(Tag: Text; Ext: Text): Text
    var
        Name: Text;
    begin
        Name := TemporaryPath() + 'lt-am-op-' + Tag + '.' + Ext;
        if Exists(Name) then
            Erase(Name);
        exit(Name);
    end;

    // Observes whether the file exists, its signature and the layout text it carries, then erases it.
    procedure Describe(var Observer: Codeunit "Probe Observer"; Tag: Text; Name: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        SaveFile: File;
        InStr: InStream;
        OutStr: OutStream;
        Kind: Text;
    begin
        Observer.Observe(Tag + ' exists', Format(Exists(Name)));
        if not Exists(Name) then
            exit;
        SaveFile.Open(Name);
        SaveFile.CreateInStream(InStr);
        TempBlob.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
        SaveFile.Close();
        Erase(Name);
        Kind := Head(TempBlob);
        Observer.Observe(Tag + ' kind', Kind);
        case Kind of
            'pdf':
                Observer.Observe(Tag + ' pdf pages', Format(PdfPages(TempBlob)));
            'zip':
                Observer.Observe(Tag + ' zip marker', ZipMarker(TempBlob));
            'markup':
                Observer.Observe(Tag + ' marker', Marker(AllText(TempBlob, TextEncoding::UTF8)));
        end;
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

    // The part name and layout text of the first XML part that carries the layout text: 'part=marker', or '' when none does.
    local procedure ZipMarker(var TempBlob: Codeunit "Temp Blob"): Text
    var
        DataCompression: Codeunit "Data Compression";
        EntryBlob: Codeunit "Temp Blob";
        Names: List of [Text];
        Name: Text;
        InS: InStream;
        EntryOut: OutStream;
        Length: Integer;
        Content: Text;
        Found: Text;
    begin
        TempBlob.CreateInStream(InS);
        DataCompression.OpenZipArchive(InS, false);
        DataCompression.GetEntryList(Names);
        foreach Name in Names do
            if (Found = '') and Name.EndsWith('.xml') then begin
                Clear(EntryBlob);
                EntryBlob.CreateOutStream(EntryOut);
                DataCompression.ExtractEntry(Name, EntryOut, Length);
                if not TryAllText(EntryBlob, TextEncoding::UTF8, Content) then
                    Content := '';
                if Marker(Content) <> '' then
                    Found := Name + '=' + Marker(Content);
            end;
        DataCompression.CloseZipArchive();
        exit(Found);
    end;
}

codeunit 98603 "LT AM OP SaveAs Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Facts: Codeunit "LT AM OP File Facts";

    [TryFunction]
    local procedure TryStatic(Fmt: Text; Name: Text; Filtered: Boolean; var Saved: Boolean)
    var
        Row: Record "LT AM OP Row";
    begin
        Row.SetFilter(Id, '>=%1', 3);
        case Fmt of
            'pdf':
                if Filtered then
                    Saved := Report.SaveAsPdf(Report::"LT AM OP Save Rpt", Name, Row)
                else
                    Saved := Report.SaveAsPdf(Report::"LT AM OP Save Rpt", Name);
            'docx':
                if Filtered then
                    Saved := Report.SaveAsWord(Report::"LT AM OP Save Rpt", Name, Row)
                else
                    Saved := Report.SaveAsWord(Report::"LT AM OP Save Rpt", Name);
            'xlsx':
                if Filtered then
                    Saved := Report.SaveAsExcel(Report::"LT AM OP Save Rpt", Name, Row)
                else
                    Saved := Report.SaveAsExcel(Report::"LT AM OP Save Rpt", Name);
            'html':
                if Filtered then
                    Saved := Report.SaveAsHtml(Report::"LT AM OP Save Rpt", Name, Row)
                else
                    Saved := Report.SaveAsHtml(Report::"LT AM OP Save Rpt", Name);
        end;
    end;

    [TryFunction]
    local procedure TryInstance(Fmt: Text; Name: Text; Filtered: Boolean; var Saved: Boolean)
    var
        Row: Record "LT AM OP Row";
        Rpt: Report "LT AM OP Save Rpt";
    begin
        if Filtered then begin
            Row.SetFilter(Id, '>=%1', 3);
            Rpt.SetTableView(Row);
        end;
        case Fmt of
            'pdf':
                Saved := Rpt.SaveAsPdf(Name);
            'docx':
                Saved := Rpt.SaveAsWord(Name);
            'xlsx':
                Saved := Rpt.SaveAsExcel(Name);
            'html':
                Saved := Rpt.SaveAsHtml(Name);
        end;
    end;

    local procedure One(var Observer: Codeunit "Probe Observer"; Form: Text; Fmt: Text; Filtered: Boolean)
    var
        Tag: Text;
        Name: Text;
        Ok: Boolean;
        Saved: Boolean;
    begin
        Tag := Form + ' ' + Fmt;
        if Filtered then
            Tag += ' filtered';
        Name := Facts.FreshName(Form + '-' + Format(Filtered), Fmt);
        ClearLastError();
        if Form = 'static' then
            Ok := TryStatic(Fmt, Name, Filtered, Saved)
        else
            Ok := TryInstance(Fmt, Name, Filtered, Saved);
        Observer.Observe(Tag + ' ok', Format(Ok));
        Observer.Observe(Tag + ' saved', Format(Saved));
        Observer.ObserveError(Tag + ' error');
        Facts.Describe(Observer, Tag, Name);
    end;

    local procedure Both(Form: Text; Fmt: Text)
    var
        Observer: Codeunit "Probe Observer";
    begin
        Facts.Seed();
        One(Observer, Form, Fmt, false);
        One(Observer, Form, Fmt, true);
        Observer.Finish();
    end;

    [Test]
    procedure Static_SaveAsPdf()
    begin
        Both('static', 'pdf');
    end;

    [Test]
    procedure Static_SaveAsWord()
    begin
        Both('static', 'docx');
    end;

    [Test]
    procedure Static_SaveAsExcel()
    begin
        Both('static', 'xlsx');
    end;

    [Test]
    procedure Static_SaveAsHtml()
    begin
        Both('static', 'html');
    end;

    [Test]
    procedure Instance_SaveAsPdf()
    begin
        Both('instance', 'pdf');
    end;

    [Test]
    procedure Instance_SaveAsWord()
    begin
        Both('instance', 'docx');
    end;

    [Test]
    procedure Instance_SaveAsExcel()
    begin
        Both('instance', 'xlsx');
    end;

    [Test]
    procedure Instance_SaveAsHtml()
    begin
        Both('instance', 'html');
    end;
}

codeunit 98604 "LT AM OP RP SaveAs Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT AM OP File Facts";
        Target: Text;
        Kind: Text;

    [RequestPageHandler]
    procedure SaveHandler(var RP: TestRequestPage "LT AM OP RP Rpt")
    begin
        RP.ThresholdField.SetValue(3);
        ClearLastError();
        case Kind of
            'xlsx':
                RP.SaveAsExcel(Target);
            'pdf':
                RP.SaveAsPdf(Target);
            'docx':
                RP.SaveAsWord(Target);
        end;
        Observer.ObserveError('handler');
        Observer.Observe('file in handler', Format(Exists(Target)));
        Observer.Observe('cancel ok', Format(TryCancel(RP)));
        Observer.ObserveError('cancel');
    end;

    [TryFunction]
    local procedure TryCancel(var RP: TestRequestPage "LT AM OP RP Rpt")
    begin
        RP.Cancel().Invoke();
    end;

    local procedure RunKind(NewKind: Text)
    begin
        Facts.Seed();
        Kind := NewKind;
        Target := Facts.FreshName('rp', NewKind);
        ClearLastError();
        Report.Run(Report::"LT AM OP RP Rpt");
        Observer.ObserveError('after run');
        Facts.Describe(Observer, NewKind, Target);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('SaveHandler')]
    procedure RequestPage_SaveAsExcel()
    begin
        RunKind('xlsx');
    end;

    [Test]
    [HandlerFunctions('SaveHandler')]
    procedure RequestPage_SaveAsPdf()
    begin
        RunKind('pdf');
    end;

    [Test]
    [HandlerFunctions('SaveHandler')]
    procedure RequestPage_SaveAsWord()
    begin
        RunKind('docx');
    end;
}
