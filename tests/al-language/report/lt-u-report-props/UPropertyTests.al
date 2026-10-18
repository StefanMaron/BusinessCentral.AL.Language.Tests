// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160), Permissions Mock, ALTPermissionSet (60022), objects of UReportObjects.al, UTestIsolation.al, UPageObjects.al
// Probe (issue 601): report layouts selected by RDLCLayout and WordLayout, SaveAs, request page fields (TableRelation, AutoFormat, DateFormula, DrillDownPageID, Width),
// report extension CalcFields and TableRelation, InherentPermissions and request page Permissions under the permissions mock, queries with InherentPermissions,
// XmlPort field and text attribute Occurrence, TextType, validation on import, and the TestIsolation of test runner codeunits. Object id 69789.

codeunit 69789 "LT U Property Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        DrillPages: Integer;

    local procedure SeedParent()
    var
        Parent: Record "ALT Parent";
        Child: Record "ALT Child";
    begin
        Child.DeleteAll();
        Parent.DeleteAll();
        Parent.Init();
        Parent."Entry No." := 69789;
        Parent.Code := 'LTU-P';
        Parent.Insert();
        Child.Init();
        Child."Entry No." := 69781;
        Child."Parent Entry No." := 69789;
        Child.Code := 'LTU-C1';
        Child.Amount := 10;
        Child.Insert();
        Child."Entry No." := 69782;
        Child.Code := 'LTU-C2';
        Child.Amount := 5;
        Child.Insert();
    end;

    local procedure SeedPageSrc()
    var
        Src: Record "LT U Page Src";
    begin
        Src.DeleteAll();
        Src.Init();
        Src.Id := 1;
        Src.Txt := 'one';
        Src.Insert();
    end;

    local procedure ReadAll(var InS: InStream) Result: Text
    var
        Line: Text;
    begin
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '\n';
        end;
    end;

    [Test]
    procedure Report_RdlcAndWordLayout_AreSelected()
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Magic: Text;
        Rdlc: Text;
    begin
        Observer.Observe('rdlc_found', Format(Report.RdlcLayout(Report::"LT U Report", InS)));
        Rdlc := ReadAll(InS);
        Observer.Observe('rdlc_length_positive', Format(StrLen(Rdlc) > 0));
        Observer.Observe('rdlc_is_report_definition', Format(Rdlc.Contains('<Report ')));
        Observer.Observe('rdlc_names_entryno', Format(Rdlc.Contains('EntryNo')));
        Observer.Observe('rdlc_names_parentcode', Format(Rdlc.Contains('ParentCode')));
        Observer.Observe('word_found', Format(Report.WordLayout(Report::"LT U Report", InS)));
        InS.Read(Magic, 2);
        Observer.Observe('word_is_zip', Magic);
        Observer.Observe('plain_rdlc_found', Format(Report.RdlcLayout(Report::"LT U Report Plain", InS)));
        Observer.Observe('plain_word_found', Format(Report.WordLayout(Report::"LT U Report Plain", InS)));
        Observer.Finish();
    end;

    [Test]
    procedure Report_SaveAs_UsesTheLayouts()
    var
        TempBlob: Codeunit "Temp Blob";
        State: Codeunit "LT U State";
        OutS: OutStream;
        InS: InStream;
        Html: Text;
    begin
        SeedParent();
        State.Reset();
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(Report::"LT U Report", '', ReportFormat::Pdf, OutS);
        Observer.Observe('pdf_length_positive', Format(TempBlob.Length() > 0));
        Observer.Observe('state_after_pdf', State.Dump());

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(Report::"LT U Report", '', ReportFormat::Word, OutS);
        Observer.Observe('word_length_positive', Format(TempBlob.Length() > 0));

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(Report::"LT U Report", '', ReportFormat::Html, OutS);
        TempBlob.CreateInStream(InS);
        Html := ReadAll(InS);
        Observer.Observe('html_length_positive', Format(StrLen(Html) > 0));
        Observer.Observe('html_has_parent_code', Format(Html.Contains('LTU-P')));

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(Report::"LT U Report", '', ReportFormat::Xml, OutS);
        TempBlob.CreateInStream(InS);
        Html := ReadAll(InS);
        Observer.Observe('xml_has_parent_code', Format(Html.Contains('LTU-P')));
        Observer.Observe('xml_has_entryno_column', Format(Html.Contains('<EntryNo>69789</EntryNo>')));
        Observer.Finish();
    end;

    [Test]
    procedure ReportExtension_CalcFields_AndBaseCalcFields()
    var
        TempBlob: Codeunit "Temp Blob";
        State: Codeunit "LT U State";
        OutS: OutStream;
    begin
        SeedParent();
        State.Reset();
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(Report::"LT U Report", '', ReportFormat::Xml, OutS);
        Observer.Observe('state', State.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RequestPageFieldsHandler,DrillPageHandler')]
    procedure Report_RequestPageFields_Relation_AutoFormat_DateFormula()
    var
        Mock: Codeunit "Permissions Mock";
    begin
        SeedPageSrc();
        DrillPages := 0;
        Report.Run(Report::"LT U Report", true, false);
        Observer.Observe('drill_pages_opened', Format(DrillPages));
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure RequestPageFieldsHandler(var Req: TestRequestPage "LT U Report")
    var
    begin
        asserterror Req.RelField.SetValue(9999);
        Observer.ObserveError('rel_missing');
        Req.RelField.SetValue(1);
        Observer.Observe('rel_existing', Req.RelField.Value);
        asserterror Req.ExtRelField.SetValue(9999);
        Observer.ObserveError('ext_rel_missing');
        Req.ExtRelField.SetValue(1);
        Observer.Observe('ext_rel_existing', Req.ExtRelField.Value);
        Req.AmtField.SetValue(1234.5);
        Observer.Observe('amount_value', Req.AmtField.Value);
        Req.DfField.SetValue('1D');
        Observer.Observe('date_formula_1d', Req.DfField.Value);
        Req.DfField.SetValue('<1W>');
        Observer.Observe('date_formula_1w', Req.DfField.Value);
        Req.DfField.SetValue('CM+1D');
        Observer.Observe('date_formula_cm', Req.DfField.Value);
        Req.WidthField.SetValue('0123456789012345678901234567890');
        Observer.Observe('width_value', Req.WidthField.Value);
        Req.DrillField.SetValue(1);
        asserterror Req.DrillField.Drilldown();
        Observer.ObserveError('drill');
        Req.Cancel().Invoke();
    end;

    [PageHandler]
    procedure DrillPageHandler(var List: TestPage "LT U Lookup List")
    begin
        DrillPages += 1;
    end;

    [Test]
    [HandlerFunctions('PermissionedRequestHandler')]
    procedure Report_RequestPagePermissions_AndInherentPermissions()
    var
        Mock: Codeunit "Permissions Mock";
        State: Codeunit "LT U State";
        Src: Record "LT U Page Src";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        WasStarted: Boolean;
    begin
        SeedPageSrc();
        SeedParent();
        State.Reset();
        WasStarted := Mock.IsStarted();
        if not WasStarted then
            Mock.Start();
        Mock.Set('ALTPermissionSet');
        asserterror Src.FindFirst();
        Observer.ObserveError('direct_read_of_src');
        asserterror Report.Run(Report::"LT U Report Plain", false, false);
        Observer.ObserveError('plain_report_run');
        Observer.Observe('state_after_plain', State.Dump());
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(Report::"LT U Report", '', ReportFormat::Xml, OutS);
        Observer.Observe('inherent_report_saveas_length_positive', Format(TempBlob.Length() > 0));
        Report.Run(Report::"LT U Report", true, false);
        Mock.ClearAssignments();
        if not WasStarted then
            Mock.Stop();
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure PermissionedRequestHandler(var Req: TestRequestPage "LT U Report")
    var
    begin
        Req.RelField.SetValue(1);
        Observer.Observe('request_page_rel_with_permissions', Req.RelField.Value);
        asserterror Req.ExtRelField.SetValue(1);
        Observer.ObserveError('request_page_ext_rel');
        Req.Cancel().Invoke();
    end;

    [Test]
    procedure Query_InherentPermissions_UnderTheMock()
    var
        Mock: Codeunit "Permissions Mock";
        Inherent: Query "LT U Query Inherent";
        Plain: Query "LT U Query Plain";
        Universal: Record "ALT Universal";
        WasStarted: Boolean;
    begin
        Universal.DeleteAll();
        Universal."Entry No." := 69789;
        Universal.Insert();
        WasStarted := Mock.IsStarted();
        if not WasStarted then
            Mock.Start();
        Mock.Set('ALTPermissionSet');
        Observer.Observe('plain_open', Format(Plain.Open()));
        Observer.ObserveError('plain_open');
        Observer.Observe('inherent_open', Format(Inherent.Open()));
        Observer.Observe('inherent_read', Format(Inherent.Read()));
        Observer.Observe('inherent_entryno', Format(Inherent.EntryNo));
        Inherent.Close();
        Mock.ClearAssignments();
        if not WasStarted then
            Mock.Stop();
        Universal.DeleteAll();
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryImport(XmlText: Text)
    begin
        ImportText(XmlText);
    end;

    local procedure ImportObserve(Name: Text; XmlText: Text)
    var
        Ok: Boolean;
    begin
        Ok := TryImport(XmlText);
        Observer.Observe(Name + '|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError(Name);
    end;

    local procedure ImportText(XmlText: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText(XmlText);
        TempBlob.CreateInStream(InS);
        Xmlport.Import(Xmlport::"LT U XmlPort", InS);
    end;

    [Test]
    procedure XmlPort_Import_Occurrence_Validation_TextType()
    var
        State: Codeunit "LT U State";
        Src: Record "LT U Page Src";
    begin
        SeedPageSrc();
        State.Reset();
        ImportObserve('full_row', '<?xml version="1.0" encoding="utf-8"?><Root><Row Id="10" Dec="2.5" RequiredText="r" OptionalText="o" BigAttr="bigvalue"><Txt>abc</Txt><Rel>1</Rel><Rel2>9999</Rel2></Row></Root>');
        Observer.Observe('state_full_row', State.Dump());
        Observer.Observe('row10_exists', Format(Src.Get(10)));
        Observer.Observe('row10_note', Src.Note);
        Observer.Observe('row10_dec', Format(Src.Dec));
        Observer.Observe('row10_rel', Format(Src.Rel));
        Observer.Observe('row10_rel2', Format(Src.Rel2));
        Observer.Finish();
    end;

    [Test]
    procedure XmlPort_Import_MissingAndInvalid()
    var
        State: Codeunit "LT U State";
        Src: Record "LT U Page Src";
    begin
        SeedPageSrc();
        State.Reset();
        ImportObserve('missing_required_field_attribute', '<?xml version="1.0" encoding="utf-8"?><Root><Row Dec="2.5" RequiredText="r"><Txt>abc</Txt></Row></Root>');
        ImportObserve('missing_required_text_attribute', '<?xml version="1.0" encoding="utf-8"?><Root><Row Id="11" Dec="2.5"><Txt>abc</Txt></Row></Root>');
        ImportObserve('missing_optional_field_attribute', '<?xml version="1.0" encoding="utf-8"?><Root><Row Id="12" RequiredText="r"><Txt>abc</Txt></Row></Root>');
        Observer.Observe('row12_exists', Format(Src.Get(12)));
        Observer.Observe('row12_note', Src.Note);
        Observer.Observe('row12_txt', Src.Txt);
        ImportObserve('bad_relation_validated', '<?xml version="1.0" encoding="utf-8"?><Root><Row Id="13" RequiredText="r"><Rel>9999</Rel></Row></Root>');
        Observer.Observe('row13_exists', Format(Src.Get(13)));
        ImportObserve('bad_relation_not_validated', '<?xml version="1.0" encoding="utf-8"?><Root><Row Id="14" RequiredText="r"><Rel2>9999</Rel2></Row></Root>');
        Observer.Observe('row14_exists', Format(Src.Get(14)));
        Observer.Observe('row14_rel2', Format(Src.Rel2));
        Observer.Observe('state', State.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure XmlPort_Export_OptionalAttributes()
    var
        TempBlob: Codeunit "Temp Blob";
        Src: Record "LT U Page Src";
        OutS: OutStream;
        InS: InStream;
    begin
        SeedPageSrc();
        Src.Get(1);
        Src.Dec := 0;
        Src.Modify();
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(Xmlport::"LT U XmlPort", OutS);
        TempBlob.CreateInStream(InS);
        Observer.Observe('export_zero_dec', ReadAll(InS));
        Src.Dec := 7.5;
        Src.Modify();
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(Xmlport::"LT U XmlPort", OutS);
        TempBlob.CreateInStream(InS);
        Observer.Observe('export_dec_7_5', ReadAll(InS));
        Observer.Finish();
    end;

    [Test]
    procedure Runner_Function_RollsBackEachTest()
    var
        Row: Record "LT U Isolation Row";
        State: Codeunit "LT U State";
    begin
        Row.DeleteAll();
        State.Reset();
        Observer.Observe('run_result', Format(Codeunit.Run(Codeunit::"LT U Runner Function")));
        Observer.ObserveError('run');
        Observer.Observe('seen', State.Dump());
        Observer.Observe('rows_after', Format(Row.Count()));
        Row.DeleteAll();
        Observer.Finish();
    end;

    [Test]
    procedure Runner_Codeunit_RollsBackAfterTheCodeunit()
    var
        Row: Record "LT U Isolation Row";
        State: Codeunit "LT U State";
    begin
        Row.DeleteAll();
        State.Reset();
        Observer.Observe('run_result', Format(Codeunit.Run(Codeunit::"LT U Runner Codeunit")));
        Observer.ObserveError('run');
        Observer.Observe('seen', State.Dump());
        Observer.Observe('rows_after', Format(Row.Count()));
        Row.DeleteAll();
        Observer.Finish();
    end;
}
