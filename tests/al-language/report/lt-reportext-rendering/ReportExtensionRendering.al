// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-extension-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT P175 Meta Helper (71578), layout files ./FixtureLayout.rdlc and ./ProbeSaveAsDatasetLayout.rdl of the app root
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a report extension with a rendering section (two RDLC layouts) on a base report that declares one layout and DefaultRenderingLayout:
// the Report Layout List rows of the base report (the extension's layouts are listed: pinned for BC 27.5 in record/TestEventSubscriptionColumnsReportLayoutListContracts.al),
// which layout Report Metadata DefaultLayoutName / Report.DefaultLayout names as the default, and a base report without an own rendering section extended by one.
// Report.SaveAsXml is OnPrem scope, so what SaveAsXml shows of the extension's layouts is not testable here (not testable in the Cloud app).
// BC versions: 29 (27 and 28 by CI)

report 72955 "LT P175 Ext Base"
{
    Caption = 'LT P175 ext base';
    UsageCategory = None;
    DefaultRenderingLayout = BaseRdlc;

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
        layout(BaseRdlc)
        {
            Type = RDLC;
            LayoutFile = './FixtureLayout.rdlc';
            Caption = 'P175 base layout';
        }
    }
}

report 72957 "LT P175 Ext Base NoRender"
{
    Caption = 'LT P175 ext base no rendering';
    UsageCategory = None;

    dataset
    {
        dataitem(Item; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(Num; Number) { }
        }
    }
}

reportextension 72956 "LT P175 Ext Rendering" extends "LT P175 Ext Base"
{
    rendering
    {
        layout(ExtRdlcA)
        {
            Type = RDLC;
            LayoutFile = './ProbeSaveAsDatasetLayout.rdl';
            Caption = 'P175 ext A';
            Summary = 'P175 ext A summary';
        }
        layout(ExtRdlcB)
        {
            Type = RDLC;
            LayoutFile = './FixtureLayout.rdlc';
            Caption = 'P175 ext B';
        }
    }
}

reportextension 72958 "LT P175 Ext NoRender Ext" extends "LT P175 Ext Base NoRender"
{
    rendering
    {
        layout(ExtOnly)
        {
            Type = RDLC;
            LayoutFile = './FixtureLayout.rdlc';
            Caption = 'P175 ext only';
        }
    }
}

codeunit 71581 "LT P175 Report Ext Render"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Dump(var Observer: Codeunit "Probe Observer"; ReportId: Integer; FromIdx: Integer; ToIdx: Integer)
    var
        Helper: Codeunit "LT P175 Meta Helper";
        RR: RecordRef;
    begin
        Observer.Observe('found', Format(Helper.OpenOne(RR, 2000000139, 1, ReportId)));
        Helper.DumpRange(Observer, RR, '', FromIdx, ToIdx);
        RR.Close();
    end;

    [Test]
    procedure P175_ExtRender_LayoutListOfBase()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P175 Meta Helper";
    begin
        Helper.LayoutRows(Observer, 'base ', Report::"LT P175 Ext Base");
        Observer.Expect('base columns', 'Report ID,Name,Runtime Package ID,Caption,CaptionML,Layout,Layout Format,Custom Type,MIME Type,Description,Application ID,Report Name,Layout Publisher,User Defined,ReportIsInstalled,IsObsolete,ExcelLayoutMultipleDataSheets,Layout Status,Layout Subtype,HeaderFooterPart,ThemePart,');
        Observer.Expect('base row1', 'name=BaseRdlc;caption=P175 base layout;format=RDLC;desc=BaseRdlc;obsolete=No');
        Observer.Expect('base row1 app is this app', 'Yes');
        Observer.Expect('base row2', 'name=ExtRdlcA;caption=P175 ext A;format=RDLC;desc=P175 ext A summary;obsolete=No');
        Observer.Expect('base row2 app is this app', 'Yes');
        Observer.Expect('base row3', 'name=ExtRdlcB;caption=P175 ext B;format=RDLC;desc=ExtRdlcB;obsolete=No');
        Observer.Expect('base row3 app is this app', 'Yes');
        Observer.Expect('base rows', '3');
        Observer.Verify();
    end;

    [Test]
    procedure P175_ExtRender_LayoutListOfBaseWithoutRendering()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P175 Meta Helper";
    begin
        Helper.LayoutRows(Observer, 'norender ', Report::"LT P175 Ext Base NoRender");
        Observer.Expect('norender columns', 'Report ID,Name,Runtime Package ID,Caption,CaptionML,Layout,Layout Format,Custom Type,MIME Type,Description,Application ID,Report Name,Layout Publisher,User Defined,ReportIsInstalled,IsObsolete,ExcelLayoutMultipleDataSheets,Layout Status,Layout Subtype,HeaderFooterPart,ThemePart,');
        Observer.Expect('norender row1', 'name=ExtOnly;caption=P175 ext only;format=RDLC;desc=ExtOnly;obsolete=No');
        Observer.Expect('norender row1 app is this app', 'Yes');
        Observer.Expect('norender rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P175_ExtRender_DefaultLayoutOfBase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('base', Format(Report.DefaultLayout(Report::"LT P175 Ext Base")));
        Observer.Observe('norender', Format(Report.DefaultLayout(Report::"LT P175 Ext Base NoRender")));
        Observer.Expect('base', 'RDLC');
        Observer.Expect('norender', 'RDLC');
        Observer.Verify();
    end;

    [Test]
    procedure P175_ExtRender_MetadataBase_Part1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, Report::"LT P175 Ext Base", 1, 16);
        Observer.Expect('found', 'Yes');
        Observer.Expect('ID', '72955');
        Observer.Expect('Name', 'LT P175 Ext Base');
        Observer.Expect('Caption', 'LT P175 ext base');
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
        Observer.Expect('DefaultLayout', 'RDLC');
        Observer.Verify();
    end;

    [Test]
    procedure P175_ExtRender_MetadataBase_Part2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, Report::"LT P175 Ext Base", 17, 40);
        Observer.Expect('found', 'Yes');
        Observer.Expect('WordMergeDataItem', '');
        Observer.Expect('FirstDataItemTableID', '2000000026');
        Observer.Expect('MaxRows', '0');
        Observer.Expect('MaxDocuments', '0');
        Observer.Expect('Timeout', '');
        Observer.Expect('AllowScheduling', 'Yes');
        Observer.Expect('DefaultLayoutName', 'BaseRdlc');
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
    procedure P175_ExtRender_MetadataNoRender_Part2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, Report::"LT P175 Ext Base NoRender", 17, 40);
        Observer.Expect('found', 'Yes');
        Observer.Expect('WordMergeDataItem', '');
        Observer.Expect('FirstDataItemTableID', '2000000026');
        Observer.Expect('MaxRows', '0');
        Observer.Expect('MaxDocuments', '0');
        Observer.Expect('Timeout', '');
        Observer.Expect('AllowScheduling', 'Yes');
        Observer.Expect('DefaultLayoutName', '');
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
}
