// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveaspdf-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (File, TemporaryPath, Report.SaveAs* are Scope = OnPrem)
// Fixtures used: Probe Observer (codeunit 69160); layout ./report/lt-t-saveas/LtTSave1.rdl of the app root; self-contained table 98100, report 98101, test codeunit 98102
// Facts: Report.SaveAsExcel, SaveAsHtml, SaveAsPdf, SaveAsWord and SaveAsXml, static (report id, file name, record) and on a Report variable: the return value, whether the file exists, and the Record filter the data comes from.
// BC versions: 27.0 and later

table 98100 "LT T Save Row"
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

report 98101 "LT T Save Report"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(T; "LT T Save Row")
        {
            column(Id; Id) { }
            column(Txt; Txt) { }
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './report/lt-t-saveas/LtTSave1.rdl';
            Caption = 'LT T layout';
        }
    }
}

codeunit 98102 "LT T Save As Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Row: Record "LT T Save Row";
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

    local procedure FileName(Ext: Text): Text
    var
        Name: Text;
    begin
        Name := TemporaryPath() + 'lt-t-save.' + Ext;
        if Exists(Name) then
            Erase(Name);
        exit(Name);
    end;

    local procedure Describe(Tag: Text; Ok: Boolean; Name: Text)
    var
        SaveFile: File;
        InStr: InStream;
        Value: Byte;
        One: Text[1];
        Head: Text;
        Count: Integer;
        Full: Text;
    begin
        Observer.Observe(Tag + ' ok', Format(Ok));
        Observer.ObserveError(Tag + ' last error');
        Observer.Observe(Tag + ' exists', Format(Exists(Name)));
        if Exists(Name) then begin
            SaveFile.Open(Name);
            SaveFile.CreateInStream(InStr);
            while (not InStr.EOS()) and (Count < 5) do begin
                InStr.Read(Value);
                One[1] := Value;
                Head += One;
                Count += 1;
            end;
            Observer.Observe(Tag + ' length>0', Format(SaveFile.Len() > 0));
            SaveFile.Close();
            Observer.Observe(Tag + ' head', Head);
            if Name.EndsWith('.xml') then begin
                SaveFile.Open(Name);
                SaveFile.CreateInStream(InStr);
                while not InStr.EOS() do begin
                    InStr.ReadText(Head);
                    Full += Head + '|';
                end;
                SaveFile.Close();
                Observer.Observe(Tag + ' ids', ColumnValues(Full, 'Id'));
                Observer.Observe(Tag + ' txts', ColumnValues(Full, 'Txt'));
            end;
            Erase(Name);
        end;
    end;

    local procedure ColumnValues(Source: Text; ColumnName: Text): Text
    var
        StartTag: Text;
        StartAt: Integer;
        EndAt: Integer;
        Result: Text;
    begin
        StartTag := '<Column name="' + ColumnName + '">';
        while true do begin
            StartAt := Source.IndexOf(StartTag);
            if StartAt = 0 then
                break;
            Source := Source.Substring(StartAt + StrLen(StartTag));
            EndAt := Source.IndexOf('</Column>');
            Result += Source.Substring(1, EndAt - 1) + ',';
            Source := Source.Substring(EndAt);
        end;
        exit(Result);
    end;

    local procedure FilterRows(var Row: Record "LT T Save Row")
    begin
        Row.SetFilter(Id, '>=%1', 3);
    end;

    [Test]
    procedure Static_Xml()
    var
        Row: Record "LT T Save Row";
        Name: Text;
        Ok: Boolean;
    begin
        Seed();
        Name := FileName('xml');
        Ok := Report.SaveAsXml(Report::"LT T Save Report", Name);
        Describe('xml', Ok, Name);
        FilterRows(Row);
        Name := FileName('xml');
        Ok := Report.SaveAsXml(Report::"LT T Save Report", Name, Row);
        Describe('xml filtered', Ok, Name);
        Observer.Finish();
    end;

    [Test]
    procedure Static_Pdf()
    var
        Row: Record "LT T Save Row";
        Name: Text;
        Ok: Boolean;
    begin
        Seed();
        Name := FileName('pdf');
        Ok := Report.SaveAsPdf(Report::"LT T Save Report", Name);
        Describe('pdf', Ok, Name);
        FilterRows(Row);
        Name := FileName('pdf');
        Ok := Report.SaveAsPdf(Report::"LT T Save Report", Name, Row);
        Describe('pdf filtered', Ok, Name);
        Observer.Finish();
    end;

    [Test]
    procedure Static_Html()
    var
        Row: Record "LT T Save Row";
        Name: Text;
        Ok: Boolean;
    begin
        Seed();
        Name := FileName('html');
        Ok := Report.SaveAsHtml(Report::"LT T Save Report", Name);
        Describe('html', Ok, Name);
        FilterRows(Row);
        Name := FileName('html');
        Ok := Report.SaveAsHtml(Report::"LT T Save Report", Name, Row);
        Describe('html filtered', Ok, Name);
        Observer.Finish();
    end;

    [Test]
    procedure Static_Excel()
    var
        Row: Record "LT T Save Row";
        Name: Text;
        Ok: Boolean;
    begin
        Seed();
        Name := FileName('xlsx');
        Ok := Report.SaveAsExcel(Report::"LT T Save Report", Name);
        Describe('excel', Ok, Name);
        FilterRows(Row);
        Name := FileName('xlsx');
        Ok := Report.SaveAsExcel(Report::"LT T Save Report", Name, Row);
        Describe('excel filtered', Ok, Name);
        Observer.Finish();
    end;

    [Test]
    procedure Static_Word()
    var
        Row: Record "LT T Save Row";
        Name: Text;
        Ok: Boolean;
    begin
        Seed();
        Name := FileName('docx');
        Ok := Report.SaveAsWord(Report::"LT T Save Report", Name);
        Describe('word', Ok, Name);
        FilterRows(Row);
        Name := FileName('docx');
        Ok := Report.SaveAsWord(Report::"LT T Save Report", Name, Row);
        Describe('word filtered', Ok, Name);
        Observer.Finish();
    end;

    local procedure InstanceOne(Tag: Text; Ext: Text; Filtered: Boolean)
    var
        Row: Record "LT T Save Row";
        Rpt: Report "LT T Save Report";
        Name: Text;
        Ok: Boolean;
    begin
        Seed();
        if Filtered then begin
            FilterRows(Row);
            Rpt.SetTableView(Row);
        end;
        Name := FileName(Ext);
        case Ext of
            'xml':
                Ok := Rpt.SaveAsXml(Name);
            'pdf':
                Ok := Rpt.SaveAsPdf(Name);
            'html':
                Ok := Rpt.SaveAsHtml(Name);
            'xlsx':
                Ok := Rpt.SaveAsExcel(Name);
            'docx':
                Ok := Rpt.SaveAsWord(Name);
        end;
        Describe(Tag, Ok, Name);
    end;

    [Test]
    procedure Instance_Xml()
    begin
        InstanceOne('i xml', 'xml', false);
        InstanceOne('i xml filtered', 'xml', true);
        Observer.Finish();
    end;

    [Test]
    procedure Instance_Html()
    begin
        InstanceOne('i html', 'html', false);
        Observer.Finish();
    end;

    [Test]
    procedure Instance_Pdf()
    begin
        InstanceOne('i pdf', 'pdf', false);
        InstanceOne('i pdf filtered', 'pdf', true);
        Observer.Finish();
    end;

    [Test]
    procedure Instance_Excel()
    begin
        InstanceOne('i excel', 'xlsx', false);
        Observer.Finish();
    end;

    [Test]
    procedure Instance_Word()
    begin
        InstanceOne('i word', 'docx', false);
        Observer.Finish();
    end;

    [Test]
    procedure Instance_SecondUse()
    var
        Rpt: Report "LT T Save Report";
        Name: Text;
        Ok: Boolean;
    begin
        Seed();
        Name := FileName('xml');
        Ok := Rpt.SaveAsXml(Name);
        Observer.Observe('first ok', Format(Ok));
        Erase(Name);
        Ok := Rpt.SaveAsXml(Name);
        Observer.Observe('second same format ok', Format(Ok));
        Observer.Observe('second same format exists', Format(Exists(Name)));
        ClearLastError();
        Ok := Rpt.SaveAsPdf(FileName('pdf'));
        Observer.Observe('other format ok', Format(Ok));
        Observer.ObserveError('other format');
        Clear(Rpt);
        Ok := Rpt.SaveAsXml(Name);
        Observer.Observe('after clear ok', Format(Ok));
        Observer.Finish();
    end;
}
