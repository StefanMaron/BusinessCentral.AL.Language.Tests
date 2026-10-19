// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-formatregion-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT Y Helper (75500, report/lt-y-report-props/YHelper.al); objects of BdRegionReports.al and BdRegionFixtures.al
// Probe: corpus issue 657. Every literal asserted below is what the BC tiers of the corpus matrix produced.
// Facts: a report with the FormatRegion property: the header of its SaveAs Xml dataset, its dataset columns and Format() in OnInitReport, OnPreReport,
// OnAfterGetRecord and OnPostReport for 14 property values; the same report started with Run, RunModal, Execute, SaveAs Pdf/Word/Excel/Html and
// through a request page; CurrReport.FormatRegion := for 14 values (SaveAs Xml and Run), after CurrReport.Language :=, and inside a report that has
// the property; the decimalformatter of Decimal columns; SummaryML of layouts in several languages.
// Linux suspects: SaveAs Pdf/Word/Excel/Html end in the bc-linux RDLC stub error on the Linux tier; those two tests are kept as source under
// BD_LINUX_SUSPECT (not compiled) until the Windows nightly measures them.
// BC versions: 27-29

codeunit 81070 "BD Region Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "BD Region Helper";
        Log: Codeunit "BD Region Log";
        ReqLog: Text;

    [TryFunction]
    local procedure TrySaveAsXml(ReportId: Integer; var Xml: Text)
    begin
        Xml := Helper.SaveAsXml(ReportId);
    end;

    local procedure Dataset(var Observer: Codeunit "Probe Observer"; ReportId: Integer)
    var
        Xml: Text;
    begin
        ClearLastError();
        if TrySaveAsXml(ReportId, Xml) then begin
            Observer.Observe('header', Helper.HeaderFacts(Xml));
            Observer.Observe('columns', Helper.Columns(Xml));
        end else
            Observer.ObserveError('saveas');
        Observer.Observe('log', Log.Take());
    end;

    [TryFunction]
    local procedure TryRun(ReportId: Integer)
    begin
        Report.Run(ReportId, false);
    end;

    [TryFunction]
    local procedure TryRunModal(ReportId: Integer)
    begin
        Report.RunModal(ReportId, false);
    end;

    [TryFunction]
    local procedure TryExecute(ReportId: Integer)
    begin
        Report.Execute(ReportId, '');
    end;

    [TryFunction]
    local procedure TrySaveAs(ReportId: Integer; Fmt: ReportFormat; var Size: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(ReportId, '', Fmt, OutS);
        Size := TempBlob.Length();
    end;

    local procedure RunWay(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean)
    begin
        Observer.Observe(Name + ' ok', Format(Ok));
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' log', Log.Take());
    end;

    local procedure SaveAsWay(var Observer: Codeunit "Probe Observer"; Fmt: ReportFormat)
    var
        Size: Integer;
        Ok: Boolean;
    begin
        Log.Take();
        ClearLastError();
        Ok := TrySaveAs(Report::"BD Region De", Fmt, Size);
        Observer.Observe(Format(Fmt) + ' ok', Format(Ok));
        Observer.Observe(Format(Fmt) + ' has output', Format(Size > 0));
        Observer.ObserveError(Format(Fmt));
        Observer.Observe(Format(Fmt) + ' log', Log.Take());
    end;

    local procedure Setter(var Observer: Codeunit "Probe Observer"; Region: Text; RegionSet: Boolean; Language: Integer)
    begin
        Log.SetCulture(Region, RegionSet, Language);
        Dataset(Observer, Report::"BD Region Setter");
        Log.SetCulture(Region, RegionSet, Language);
        ClearLastError();
        RunWay(Observer, 'run', TryRun(Report::"BD Region Setter Proc"));
        Log.SetCulture('', false, 0);
    end;

    // Setter in two tests (the dataset part, then the run part) where one message would pass 1800 characters.
    local procedure SetterDataset(var Observer: Codeunit "Probe Observer"; Region: Text; RegionSet: Boolean; Language: Integer)
    begin
        Log.SetCulture(Region, RegionSet, Language);
        Dataset(Observer, Report::"BD Region Setter");
        Log.SetCulture('', false, 0);
    end;

    local procedure SetterRun(var Observer: Codeunit "Probe Observer"; Region: Text; RegionSet: Boolean; Language: Integer)
    begin
        Log.SetCulture(Region, RegionSet, Language);
        ClearLastError();
        RunWay(Observer, 'run', TryRun(Report::"BD Region Setter Proc"));
        Log.SetCulture('', false, 0);
    end;

    [Test]
    procedure BdProperty_De_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region De");
        Observer.Finish();
    end;

    [Test]
    procedure BdProperty_Gb_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region Gb");
        Observer.Finish();
    end;

    [Test]
    procedure BdProperty_Fr_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region Fr");
        Observer.Finish();
    end;

    [Test]
    procedure BdProperty_Jp_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region Jp");
        Observer.Finish();
    end;

    [Test]
    procedure BdProperty_Zz_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region Zz");
        Observer.Finish();
    end;

    [Test]
    procedure BdProperty_Dk_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region Dk");
        Observer.Finish();
    end;

    [Test]
    procedure BdProperty_Us_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region Us");
        Observer.Finish();
    end;

    [Test]
    procedure BdProperty_Nl_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region Nl");
        Observer.Finish();
    end;

    [Test]
    procedure BdProperty_Ch_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region Ch");
        Observer.Finish();
    end;

    [Test]
    procedure BdProperty_It_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region It");
        Observer.Finish();
    end;

    [Test]
    procedure BdProperty_Es_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region Es");
        Observer.Finish();
    end;

    [Test]
    procedure BdProperty_Se_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region Se");
        Observer.Finish();
    end;

    [Test]
    procedure BdProperty_No_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region No");
        Observer.Finish();
    end;

    [Test]
    procedure BdProperty_NotSet_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region Empty");
        Observer.Finish();
    end;

    [Test]
    procedure BdProperty_De_RunRunModalExecute()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        ClearLastError();
        RunWay(Observer, 'run', TryRun(Report::"BD Region De Proc"));
        ClearLastError();
        RunWay(Observer, 'runmodal', TryRunModal(Report::"BD Region De Proc"));
        ClearLastError();
        RunWay(Observer, 'execute', TryExecute(Report::"BD Region De Proc"));
        Observer.Finish();
    end;

#if BD_LINUX_SUSPECT
    // Linux suspect: on the Linux tier every SaveAs Pdf/Word/Excel/Html ends in the bc-linux RDLC stub error; kept as source, not compiled.
    [Test]
    procedure BdProperty_De_SaveAsPdfWord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SaveAsWay(Observer, ReportFormat::Pdf);
        SaveAsWay(Observer, ReportFormat::Word);
        Observer.Finish();
    end;
#endif

#if BD_LINUX_SUSPECT
    // Linux suspect: on the Linux tier every SaveAs Pdf/Word/Excel/Html ends in the bc-linux RDLC stub error; kept as source, not compiled.
    [Test]
    procedure BdProperty_De_SaveAsExcelHtml()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SaveAsWay(Observer, ReportFormat::Excel);
        SaveAsWay(Observer, ReportFormat::Html);
        Observer.Finish();
    end;
#endif

    [TryFunction]
    local procedure TryRequestSaveAsXml(var RP: TestRequestPage "BD Region De Req")
    begin
        RP.SaveAsXml('bdparams.xml', 'bddata.xml');
    end;

    [RequestPageHandler]
    procedure BdReqHandler(var RP: TestRequestPage "BD Region De Req")
    var
        Ok: Boolean;
    begin
        ReqLog := 'handler log=' + Log.Take() + ' amount=' + RP.ReqAmt.Value();
        ClearLastError();
        Ok := TryRequestSaveAsXml(RP);
        ReqLog += ' saveasxml ok=' + Format(Ok) + ' error=' + GetLastErrorText() + ' code=' + GetLastErrorCode() + ' log=' + Log.Take();
        ClearLastError();
    end;

    [Test]
    [HandlerFunctions('BdReqHandler')]
    procedure BdProperty_De_TestRequestPageSaveAsXml()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Log.Take();
        ReqLog := '';
        ClearLastError();
        Ok := TryRun(Report::"BD Region De Req");
        Observer.Observe('handler', ReqLog);
        Observer.Observe('run ok', Format(Ok));
        Observer.ObserveError('run');
        Observer.Observe('run log', Log.Take());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryGlobalLanguage(Language: Integer)
    begin
        GlobalLanguage(Language);
    end;

    [Test]
    procedure BdSetter_EnGB()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'en-GB', true, 0);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetter_JaJP()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'ja-JP', true, 0);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetter_NlNL()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'nl-NL', true, 0);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetter_DeCH()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'de-CH', true, 0);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetter_ItIT()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'it-IT', true, 0);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetter_SvSE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'sv-SE', true, 0);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetter_EnUS()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterDataset(Observer, 'en-US', true, 0);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetter_EnUS_Run()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterRun(Observer, 'en-US', true, 0);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetter_ZzZZ()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'zz-ZZ', true, 0);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetter_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, '', true, 0);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetter_DeDE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'de-DE', true, 0);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetter_FrFR()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'fr-FR', true, 0);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetter_DaDK()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'da-DK', true, 0);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetter_Lower()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'de-de', true, 0);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetter_Neutral()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'de', true, 0);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetterLanguage_1031_EnUS()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterDataset(Observer, 'en-US', true, 1031);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetterLanguage_1031_EnUS_Run()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterRun(Observer, 'en-US', true, 1031);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetterLanguage_1031_DeDE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'de-DE', true, 1031);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetterLanguage_1031_None()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterDataset(Observer, '', false, 1031);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetterLanguage_1031_None_Run()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterRun(Observer, '', false, 1031);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetterLanguage_1036_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, '', true, 1036);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetterLanguage_1036_EnUS()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterDataset(Observer, 'en-US', true, 1036);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetterLanguage_1036_EnUS_Run()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterRun(Observer, 'en-US', true, 1036);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetterLanguage_1033_EnUS()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterDataset(Observer, 'en-US', true, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetterLanguage_1033_EnUS_Run()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterRun(Observer, 'en-US', true, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetterLanguage_1030_FrFR()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'fr-FR', true, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetterInPropertyReport_FrFR()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.SetCulture('fr-FR', true, 0);
        Dataset(Observer, Report::"BD Region Setter De");
        Log.SetCulture('', false, 0);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetterInPropertyReport_EnUS()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.SetCulture('en-US', true, 0);
        Dataset(Observer, Report::"BD Region Setter De");
        Log.SetCulture('', false, 0);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetterInPropertyReport_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.SetCulture('', true, 0);
        Dataset(Observer, Report::"BD Region Setter De");
        Log.SetCulture('', false, 0);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetterInPropertyReport_None()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.SetCulture('', false, 0);
        Dataset(Observer, Report::"BD Region Setter De");
        Log.SetCulture('', false, 0);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetterInPropertyReport_JaJP()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.SetCulture('ja-JP', true, 0);
        Dataset(Observer, Report::"BD Region Setter De");
        Log.SetCulture('', false, 0);
        Observer.Finish();
    end;

    [Test]
    procedure BdDecimalFormatter_Columns()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BD Amount Row";
        Xml: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Plain := 1234.567;
        Row.Places25 := 1234.567;
        Row.Places00 := 1234.567;
        Row.Auto1 := 1234.567;
        Row.Auto2 := 1234.567;
        Row.Insert();
        Xml := Helper.SaveAsXml(Report::"BD Decimal Formatter");
        Observer.Observe('columns', Helper.Columns(Xml));
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Plain := 1234.5;
        Row.Places25 := 1234.5;
        Row.Places00 := 1234;
        Row.Auto1 := 1234.5;
        Row.Auto2 := 1234.5;
        Row.Insert();
        Xml := Helper.SaveAsXml(Report::"BD Decimal Formatter");
        Observer.Observe('columns short', Helper.Columns(Xml));
        Row.DeleteAll();
        Observer.Finish();
    end;

    [Test]
    procedure BdSummaryML_1033()
    var
        Observer: Codeunit "Probe Observer";
        YHelper: Codeunit "LT Y Helper";
        Original: Integer;
        Result: Text;
    begin
        Original := GlobalLanguage();
        if not TryGlobalLanguage(1033) then
            Observer.ObserveError('globallanguage');
        Result := YHelper.LayoutSummaries(Report::"BD Summary Langs");
        GlobalLanguage(Original);
        Observer.Observe('layouts', Result);
        Observer.Finish();
    end;

    [Test]
    procedure BdSummaryML_1031()
    var
        Observer: Codeunit "Probe Observer";
        YHelper: Codeunit "LT Y Helper";
        Original: Integer;
        Result: Text;
    begin
        Original := GlobalLanguage();
        if not TryGlobalLanguage(1031) then
            Observer.ObserveError('globallanguage');
        Result := YHelper.LayoutSummaries(Report::"BD Summary Langs");
        GlobalLanguage(Original);
        Observer.Observe('layouts', Result);
        Observer.Finish();
    end;

    [Test]
    procedure BdSummaryML_1036()
    var
        Observer: Codeunit "Probe Observer";
        YHelper: Codeunit "LT Y Helper";
        Original: Integer;
        Result: Text;
    begin
        Original := GlobalLanguage();
        if not TryGlobalLanguage(1036) then
            Observer.ObserveError('globallanguage');
        Result := YHelper.LayoutSummaries(Report::"BD Summary Langs");
        GlobalLanguage(Original);
        Observer.Observe('layouts', Result);
        Observer.Finish();
    end;

    [Test]
    procedure BdSummaryML_1030()
    var
        Observer: Codeunit "Probe Observer";
        YHelper: Codeunit "LT Y Helper";
        Original: Integer;
        Result: Text;
    begin
        Original := GlobalLanguage();
        if not TryGlobalLanguage(1030) then
            Observer.ObserveError('globallanguage');
        Result := YHelper.LayoutSummaries(Report::"BD Summary Langs");
        GlobalLanguage(Original);
        Observer.Observe('layouts', Result);
        Observer.Finish();
    end;

    [Test]
    procedure BdSummaryML_1043()
    var
        Observer: Codeunit "Probe Observer";
        YHelper: Codeunit "LT Y Helper";
        Original: Integer;
        Result: Text;
    begin
        Original := GlobalLanguage();
        if not TryGlobalLanguage(1043) then
            Observer.ObserveError('globallanguage');
        Result := YHelper.LayoutSummaries(Report::"BD Summary Langs");
        GlobalLanguage(Original);
        Observer.Observe('layouts', Result);
        Observer.Finish();
    end;

    [Test]
    procedure BdSummaryML_1040()
    var
        Observer: Codeunit "Probe Observer";
        YHelper: Codeunit "LT Y Helper";
        Original: Integer;
        Result: Text;
    begin
        Original := GlobalLanguage();
        if not TryGlobalLanguage(1040) then
            Observer.ObserveError('globallanguage');
        Result := YHelper.LayoutSummaries(Report::"BD Summary Langs");
        GlobalLanguage(Original);
        Observer.Observe('layouts', Result);
        Observer.Finish();
    end;

}
