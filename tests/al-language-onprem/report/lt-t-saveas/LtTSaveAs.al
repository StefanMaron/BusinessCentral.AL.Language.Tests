// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveaspdf-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (File, TemporaryPath, Report.SaveAs* are Scope = OnPrem)
// Fixtures used: Probe Observer (codeunit 69160); layout ./ProbeRpSaveLayout.rdl of the app root; self-contained table 98100, report 98101, test codeunit 98102
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
            LayoutFile = './ProbeRpSaveLayout.rdl';
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
            Erase(Name);
        end;
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

    [Test]
    procedure Instance_All()
    var
        Row: Record "LT T Save Row";
        Rpt: Report "LT T Save Report";
        Name: Text;
        Ok: Boolean;
    begin
        Seed();
        Name := FileName('xml');
        Ok := Rpt.SaveAsXml(Name);
        Describe('i xml', Ok, Name);
        Name := FileName('pdf');
        Ok := Rpt.SaveAsPdf(Name);
        Describe('i pdf', Ok, Name);
        Name := FileName('html');
        Ok := Rpt.SaveAsHtml(Name);
        Describe('i html', Ok, Name);
        Name := FileName('xlsx');
        Ok := Rpt.SaveAsExcel(Name);
        Describe('i excel', Ok, Name);
        Name := FileName('docx');
        Ok := Rpt.SaveAsWord(Name);
        Describe('i word', Ok, Name);
        FilterRows(Row);
        Rpt.SetTableView(Row);
        Name := FileName('xml');
        Ok := Rpt.SaveAsXml(Name);
        Describe('i xml filtered', Ok, Name);
        Observer.Finish();
    end;
}
