// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT P175 Meta Helper (71578), layout file ./ProbeRlLayout.docx of the app root
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (own file): the Word layout file ProbeRlLayout.docx is referenced like in record/TestEventSubscriptionColumnsReportLayoutListContracts.al; if the file is not
// present at compile time this file is dropped.
// Facts: every column of Report Metadata (2000000139) for a report whose default layout is a Word layout (WordMergeDataItem set), and its Report Layout List rows.
// BC versions: 29 (27 and 28 by CI)

report 72954 "LT P175 Rpt Word"
{
    Caption = 'LT P175 word';
    UsageCategory = None;
    DefaultRenderingLayout = OneWord;
    WordMergeDataItem = Item;

    dataset
    {
        dataitem(Item; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(Num; Number) { }
        }
    }

    rendering
    {
        layout(OneWord)
        {
            Type = Word;
            LayoutFile = './ProbeRlLayout.docx';
            Caption = 'P175 one word';
            Summary = 'P175 word summary';
        }
    }
}

codeunit 71580 "LT P175 Report Meta Word"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Dump(var Observer: Codeunit "Probe Observer"; FromIdx: Integer; ToIdx: Integer)
    var
        Helper: Codeunit "LT P175 Meta Helper";
        RR: RecordRef;
    begin
        Observer.Observe('found', Format(Helper.OpenOne(RR, 2000000139, 1, Report::"LT P175 Rpt Word")));
        Helper.DumpRange(Observer, RR, '', FromIdx, ToIdx);
        RR.Close();
    end;

    [Test]
    procedure P175_Meta_Word_Part1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 1, 16);
        Observer.Expect('found', 'Yes');
        Observer.Expect('ID', '72954');
        Observer.Expect('Name', 'LT P175 Rpt Word');
        Observer.Expect('Caption', 'LT P175 word');
        Observer.Expect('UseRequestPage', 'Yes');
        Observer.Expect('UseSystemPrinter', 'No');
        Observer.Expect('EnableExternalImages', 'No');
        Observer.Expect('EnableHyperLinks', 'No');
        Observer.Expect('EnableExternalAssemblies', 'No');
        Observer.Expect('ProcessingOnly', 'No');
        Observer.Expect('ShowPrintStatus', 'Yes');
        Observer.Expect('TransactionType', 'UpdateNoLocks');
        Observer.Expect('PaperSourceFirstPage', '0');
        Observer.Expect('PaperSourceDefaultPage', '0');
        Observer.Expect('PaperSourceLastPage', '0');
        Observer.Expect('PreviewMode', 'Normal');
        Observer.Expect('DefaultLayout', 'Word');
        Observer.Verify();
    end;

    [Test]
    procedure P175_Meta_Word_Part2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 17, 40);
        Observer.Expect('found', 'Yes');
        Observer.Expect('WordMergeDataItem', 'Item');
        Observer.Expect('FirstDataItemTableID', '2000000026');
        Observer.Expect('MaxRows', '0');
        Observer.Expect('MaxDocuments', '0');
        Observer.Expect('Timeout', '');
        Observer.Expect('AllowScheduling', 'Yes');
        Observer.Expect('DefaultLayoutName', 'OneWord');
        Observer.Expect('FormatRegion', '');
        Observer.Expect('ExcelLayoutMultipleDataSheets', 'No');
        Observer.Expect('App ID', 'blank=No');
        Observer.Expect('InherentPermissions', '');
        Observer.Expect('InherentEntitlements', '');
        Observer.Expect('AL Namespace', '');
        Observer.Expect('DefaultHeaderFooterPartName', '');
        Observer.Expect('DefaultThemePartName', '');
        Observer.Verify();
    end;

    [Test]
    procedure P175_LayoutList_Word()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P175 Meta Helper";
    begin
        Helper.LayoutRows(Observer, 'word ', Report::"LT P175 Rpt Word");
        Observer.Observe('default layout', Format(Report.DefaultLayout(Report::"LT P175 Rpt Word")));
        Observer.Expect('word columns', 'Report ID,Name,Runtime Package ID,Caption,CaptionML,Layout,Layout Format,Custom Type,MIME Type,Description,Application ID,Report Name,Layout Publisher,User Defined,ReportIsInstalled,IsObsolete,ExcelLayoutMultipleDataSheets,Layout Status,Layout Subtype,HeaderFooterPart,ThemePart,');
        Observer.Expect('word row1', 'name=OneWord;caption=P175 one word;format=Word;desc=P175 word summary;obsolete=No');
        Observer.Expect('word row1 app is this app', 'Yes');
        Observer.Expect('word rows', '1');
        Observer.Expect('default layout', 'Word');
        Observer.Verify();
    end;
}
