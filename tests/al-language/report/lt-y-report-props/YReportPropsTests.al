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
            Observer.Observe('xml', Helper.AsciiOnly(Xml))
        else
            Observer.Observe('xml', Helper.Failed());
        Observer.Observe('meta', Helper.ReportFacts(ReportId));
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
        Observer.Observe('meta', Helper.ReportFacts(Report::"LT Y Rep Props"));
        Observer.Observe('layouts', Helper.LayoutFacts(Report::"LT Y Rep Props"));
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
    local procedure TryWorkbookFacts(ReportId: Integer; var Result: Text)
    begin
        Result := Helper.WorkbookFacts(ReportId);
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
        Observer.Observe('meta', Helper.ReportFacts(ReportId));
        Observer.Observe('layouts', Helper.LayoutFacts(ReportId));
        if TryExcelLayout(ReportId, Text1) then
            Observer.Observe('excel_layout', Text1)
        else
            Observer.Observe('excel_layout', Helper.Failed());
        if TryWorkbookFacts(ReportId, Text1) then
            Observer.Observe('workbook', Text1)
        else
            Observer.Observe('workbook', Helper.Failed());
    end;

    [Test]
    procedure AdditionalSearchTermsML_Report_CompilesAndRuns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('meta', Helper.ReportFacts(Report::"LT Y Rep Props"));
        Observer.Finish();
    end;

    // A data item filter tab has no caption member in TestRequestPage and the request page parameters text does not carry the heading, so the heading
    // itself is not observable from AL; the data item rows (Request Filter Fields) of the report with RequestFilterHeadingML are.
    [Test]
    procedure RequestFilterHeadingML_DataItem_CompilesAndListsFilterFields()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('data_items', Helper.DataItemRows(Report::"LT Y Rep Heading"));
        Observer.Finish();
    end;

    local procedure LayoutsFor(LanguageId: Integer): Text
    var
        Original: Integer;
        Result: Text;
    begin
        Original := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Result := Helper.LayoutSummaries(Report::"LT Y Rep Summary");
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
