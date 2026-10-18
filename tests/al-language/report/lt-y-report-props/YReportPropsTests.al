// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT Y Helper (75500), LT Y Seen (75501), reports of YReports.al (75501-75519)
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced.
// Facts: see YReports.al. GlobalLanguage is set back to the language the test started with.
// BC versions: 27-29

codeunit 75510 "LT Y Report Props Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Y Helper";

    [TryFunction]
    local procedure TryDataItemsXml(ReportId: Integer; var Result: Text)
    begin
        Result := Helper.DataItemsXml(ReportId);
    end;

    local procedure Region(var Observer: Codeunit "Probe Observer"; ReportId: Integer)
    var
        Xml: Text;
    begin
        if TryDataItemsXml(ReportId, Xml) then
            Observer.Observe('xml', Xml)
        else
            Observer.Observe('xml', Helper.Failed());
        Observer.Observe('meta', Helper.RowOf(2000000139, 1, ReportId));
    end;

    [Test]
    procedure FormatRegion_DeDE_XmlAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Region(Observer, Report::"LT Y Rep Region De");
        Observer.Finish();
    end;

    [Test]
    procedure FormatRegion_EnGB_XmlAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Region(Observer, Report::"LT Y Rep Region Gb");
        Observer.Finish();
    end;

    [Test]
    procedure FormatRegion_FrFR_XmlAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Region(Observer, Report::"LT Y Rep Region Fr");
        Observer.Finish();
    end;

    [Test]
    procedure FormatRegion_JaJP_XmlAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Region(Observer, Report::"LT Y Rep Region Jp");
        Observer.Finish();
    end;

    [Test]
    procedure FormatRegion_NotSet_XmlAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Region(Observer, Report::"LT Y Rep Region None");
        Observer.Finish();
    end;

    [Test]
    procedure FormatRegion_UnknownRegion_XmlOrError()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Region(Observer, Report::"LT Y Rep Region Bad");
        Observer.Finish();
    end;

    [Test]
    procedure Props_Metadata_PaperSourcesExternalImagesMultiSheet()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('meta', Helper.RowOf(2000000139, 1, Report::"LT Y Rep Props"));
        Observer.Observe('layouts', Helper.LayoutRows(Report::"LT Y Rep Props"));
        Observer.Finish();
    end;

    [Test]
    procedure Props_SaveAsPdf_StillSucceeds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('head', Helper.SaveAsHead(Report::"LT Y Rep Props", ReportFormat::Pdf, 4));
        Observer.Observe('nonempty', Format(Helper.SaveAsSize(Report::"LT Y Rep Props", ReportFormat::Pdf) > 0));
        Observer.Finish();
    end;

    [Test]
    procedure PdfFontEmbedding_Yes_SaveAsPdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('head', Helper.SaveAsHead(Report::"LT Y Rep Pdf Yes", ReportFormat::Pdf, 4));
        Observer.Observe('nonempty', Format(Helper.SaveAsSize(Report::"LT Y Rep Pdf Yes", ReportFormat::Pdf) > 0));
        Observer.Finish();
    end;

    [Test]
    procedure PdfFontEmbedding_No_SaveAsPdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('head', Helper.SaveAsHead(Report::"LT Y Rep Pdf No", ReportFormat::Pdf, 4));
        Observer.Observe('nonempty', Format(Helper.SaveAsSize(Report::"LT Y Rep Pdf No", ReportFormat::Pdf) > 0));
        Observer.Finish();
    end;

    [Test]
    procedure PdfFontEmbedding_Default_SaveAsPdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('head', Helper.SaveAsHead(Report::"LT Y Rep Pdf Default", ReportFormat::Pdf, 4));
        Observer.Observe('nonempty', Format(Helper.SaveAsSize(Report::"LT Y Rep Pdf Default", ReportFormat::Pdf) > 0));
        Observer.Finish();
    end;

    [Test]
    procedure PdfFontEmbedding_Sizes_Observed()
    var
        Observer: Codeunit "Probe Observer";
        SizeYes: Integer;
        SizeNo: Integer;
        SizeDefault: Integer;
    begin
        SizeYes := Helper.SaveAsSize(Report::"LT Y Rep Pdf Yes", ReportFormat::Pdf);
        SizeNo := Helper.SaveAsSize(Report::"LT Y Rep Pdf No", ReportFormat::Pdf);
        SizeDefault := Helper.SaveAsSize(Report::"LT Y Rep Pdf Default", ReportFormat::Pdf);
        Observer.Observe('yes_vs_no', Format(SizeYes) + ' ' + Format(SizeNo));
        Observer.Observe('default_vs_yes', Format(SizeDefault) + ' ' + Format(SizeYes));
        Observer.Finish();
    end;

    [Test]
    procedure ExcelLayoutMultipleDataSheets_Multi_Workbook()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ExcelFacts(Observer, Report::"LT Y Rep Excel Multi");
        Observer.Finish();
    end;

    [Test]
    procedure ExcelLayoutMultipleDataSheets_Single_Workbook()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ExcelFacts(Observer, Report::"LT Y Rep Excel Single");
        Observer.Finish();
    end;

    [Test]
    procedure ExcelLayoutMultipleDataSheets_Unset_Workbook()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ExcelFacts(Observer, Report::"LT Y Rep Excel Unset");
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryZipEntries(ReportId: Integer; var Result: Text)
    begin
        Result := Helper.ZipEntries(ReportId, ReportFormat::Excel);
    end;

    [TryFunction]
    local procedure TryWorkbook(ReportId: Integer; var Result: Text)
    begin
        Result := Helper.ZipEntryText(ReportId, ReportFormat::Excel, 'xl/workbook.xml');
    end;

    [TryFunction]
    local procedure TryExcelLayout(ReportId: Integer; var Result: Text)
    var
        InS: InStream;
        Found: Boolean;
    begin
        Found := Report.ExcelLayout(ReportId, InS);
        Result := Format(Found) + ' eos=' + Format(InS.EOS());
    end;

    local procedure ExcelFacts(var Observer: Codeunit "Probe Observer"; ReportId: Integer)
    var
        Text1: Text;
    begin
        Observer.Observe('default_layout', Format(Report.DefaultLayout(ReportId)));
        Observer.Observe('meta', Helper.RowOf(2000000139, 1, ReportId));
        Observer.Observe('layouts', Helper.LayoutRows(ReportId));
        if TryExcelLayout(ReportId, Text1) then
            Observer.Observe('excel_layout', Text1)
        else
            Observer.Observe('excel_layout', Helper.Failed());
        if TryZipEntries(ReportId, Text1) then
            Observer.Observe('entries', Text1)
        else
            Observer.Observe('entries', Helper.Failed());
        if TryWorkbook(ReportId, Text1) then
            Observer.Observe('workbook', Text1)
        else
            Observer.Observe('workbook', Helper.Failed());
    end;

    [Test]
    procedure AdditionalSearchTermsML_Report_CompilesAndRuns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('meta', Helper.RowOf(2000000139, 1, Report::"LT Y Rep Props"));
        Observer.Finish();
    end;

    // A data item filter tab has no caption member in TestRequestPage, so the heading itself is not observable from AL; what a language switch changes in the
    // request page parameters text (the data items with their filter fields) is observed here.
    local procedure ParametersFor(LanguageId: Integer): Text
    var
        Original: Integer;
        Parameters: Text;
    begin
        Original := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Parameters := Report.RunRequestPage(Report::"LT Y Rep Heading");
        GlobalLanguage(Original);
        exit(Parameters);
    end;

    [RequestPageHandler]
    procedure HeadingHandler(var RP: TestRequestPage "LT Y Rep Heading")
    begin
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('HeadingHandler')]
    procedure RequestFilterHeadingML_English()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('data_items', Helper.DataItemRows(Report::"LT Y Rep Heading"));
        Observer.Observe('parameters', ParametersFor(1033));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HeadingHandler')]
    procedure RequestFilterHeadingML_German()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('parameters', ParametersFor(1031));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HeadingHandler')]
    procedure RequestFilterHeadingML_FrenchFallsBack()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('parameters', ParametersFor(1036));
        Observer.Finish();
    end;

    local procedure LayoutsFor(LanguageId: Integer): Text
    var
        Original: Integer;
        Result: Text;
    begin
        Original := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Result := Helper.LayoutRows(Report::"LT Y Rep Summary");
        GlobalLanguage(Original);
        exit(Result);
    end;

    [Test]
    procedure SummaryML_English()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('layouts', LayoutsFor(1033));
        Observer.Finish();
    end;

    [Test]
    procedure SummaryML_German()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('layouts', LayoutsFor(1031));
        Observer.Finish();
    end;

    [Test]
    procedure SummaryML_FrenchFallsBack()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('layouts', LayoutsFor(1036));
        Observer.Finish();
    end;
}
