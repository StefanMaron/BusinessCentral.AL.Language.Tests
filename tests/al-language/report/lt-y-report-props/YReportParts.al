// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT Y Helper (75500)
// Probe: observed values; every literal asserted below is what the BC 29 tier produced.
// Facts: BC 29 (app runtime 18.0): DefaultHeaderFooterPart, DefaultThemePart, layout HeaderFooterPart, ThemePart and Subtype compile and show in the
// Report Metadata row (DefaultHeaderFooterPartName, DefaultThemePartName) and in the Report Layout List rows of the report. Before BC 29 the properties do not
// compile (must-not-compile cases 0800-0805), so the whole file is guarded. No rendering is asserted.
// BC versions: 29

#if BC29PLUS
report 75570 "LT Y Rep Parts"
{
    UsageCategory = None;
    Caption = 'LT Y parts';
    UseRequestPage = false;
    DefaultRenderingLayout = PartsBody;
    DefaultHeaderFooterPart = PartsHf;
    DefaultThemePart = PartsTheme;
    WordMergeDataItem = Row;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(NumCol; Number) { }
        }
    }

    rendering
    {
        layout(PartsBody)
        {
            Type = Word;
            Subtype = Body;
            LayoutFile = './report/lt-y-report-props/LtYPartsBody.docx';
            HeaderFooterPart = PartsHf;
            ThemePart = PartsTheme;
        }
        layout(PartsHf)
        {
            Type = Word;
            Subtype = HeaderFooter;
            LayoutFile = './report/lt-y-report-props/LtYPartsHf.docx';
        }
        layout(PartsTheme)
        {
            Type = Word;
            Subtype = Theme;
            LayoutFile = './report/lt-y-report-props/LtYPartsTheme.dotx';
        }
    }
}

codeunit 75571 "LT Y Report Parts Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Y Helper";

    [Test]
    procedure ReportParts_MetadataRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('meta', Helper.Facts(2000000139, 1, Report::"LT Y Rep Parts", 'DefaultLayout,DefaultLayoutName,DefaultHeaderFooterPartName,DefaultThemePartName'));
        Observer.Expect('meta', 'DefaultLayout=Word;DefaultLayoutName=PartsBody;DefaultHeaderFooterPartName=PartsHf;DefaultThemePartName=PartsTheme;');
        Observer.Verify();
    end;

    [Test]
    procedure ReportParts_LayoutListRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('rows', PartColumns());
        Observer.Expect('rows', 'TODO');
        Observer.Verify();
    end;

    // Per layout of the report: its name, then every column whose name mentions Subtype, Part, Theme or HeaderFooter.
    local procedure PartColumns(): Text
    var
        LayoutList: Record "Report Layout List";
        RR: RecordRef;
        FR: FieldRef;
        i: Integer;
        Result: Text;
    begin
        LayoutList.SetRange("Report ID", Report::"LT Y Rep Parts");
        if LayoutList.FindSet() then
            repeat
                RR.GetTable(LayoutList);
                Result += '[' + LayoutList.Name;
                for i := 1 to RR.FieldCount() do begin
                    FR := RR.FieldIndex(i);
                    if FR.Name.Contains('Subtype') or FR.Name.Contains('Part') or FR.Name.Contains('Theme') or FR.Name.Contains('HeaderFooter') then
                        Result += ' ' + FR.Name + '=' + Format(FR.Value);
                end;
                Result += ']';
            until LayoutList.Next() = 0
        else
            Result := 'no layouts';
        exit(Result);
    end;
}
#endif
