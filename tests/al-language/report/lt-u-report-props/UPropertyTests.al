// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160), Permissions Mock, ALTPermissionSet (60022), objects of UReportObjects.al, UTestIsolation.al, UPageObjects.al
// Probe (issue 601): report layouts selected by RDLCLayout and WordLayout, SaveAs, request page fields (TableRelation, AutoFormat, DateFormula; DrillDownPageID and Width are not probed, see the hand-off note),
// report extension CalcFields and TableRelation, InherentPermissions and request page Permissions under the permissions mock, queries with InherentPermissions,
// XmlPort field and text attribute Occurrence, TextType, validation on import, and the TestIsolation of test runner codeunits. Object id 69789.

codeunit 69789 "LT U Property Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

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

    local procedure After(Value: Text; Marker: Text; Len: Integer): Text
    begin
        if StrPos(Value, Marker) = 0 then
            exit('<not found>');
        exit(CopyStr(Value, StrPos(Value, Marker) + StrLen(Marker), Len));
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

    // The rendered formats (Pdf, Word, Html) need the Windows reporting service; the Linux BC of the CI cannot render RDLC (see the hand-off note), so only the Xml format is pinned.
    [Test]
    procedure Report_SaveAs_Xml_UsesTheDataset()
    var
        TempBlob: Codeunit "Temp Blob";
        State: Codeunit "LT U State";
        OutS: OutStream;
        InS: InStream;
        Xml: Text;
    begin
        SeedParent();
        State.Reset();
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(Report::"LT U Report", '', ReportFormat::Xml, OutS);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xml := ReadAll(InS);
        Observer.Observe('xml_has_parent_code', Format(Xml.Contains('LTU-P')));
        Observer.Observe('xml_entryno_column', After(Xml, 'name="EntryNo">', 5));
        Observer.Observe('xml_parentcode_column', After(Xml, 'name="ParentCode">', 6));
        Observer.Observe('xml_dataitem_parent', Format(Xml.Contains('name="Parent"')));
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
        Report.Run(Report::"LT U Report Plain", false, false);
        Observer.Observe('plain_report_run|no_error', 'true');
        Observer.Observe('state_after_plain', State.Dump());
        TempBlob.CreateOutStream(OutS);
        asserterror Report.SaveAs(Report::"LT U Report", '', ReportFormat::Xml, OutS);
        Observer.ObserveError('saveas_inherent');
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
        asserterror begin Req.AmtField.SetValue(1234.5); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('amount_set|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('amount_value', Req.AmtField.Value); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('amount_value|failed')
        else
            ClearLastError();
        asserterror begin Req.DfField.SetValue('1D'); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('date_formula_1d_set|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('date_formula_1d', Req.DfField.Value); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('date_formula_1d|failed')
        else
            ClearLastError();
        asserterror begin Req.DfField.SetValue('<1W>'); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('date_formula_1w_set|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('date_formula_1w', Req.DfField.Value); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('date_formula_1w|failed')
        else
            ClearLastError();
        asserterror begin Req.DfField.SetValue('CM+1D'); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('date_formula_cm_set|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('date_formula_cm', Req.DfField.Value); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('date_formula_cm|failed')
        else
            ClearLastError();
        asserterror begin Req.RelField.SetValue(9999); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('rel_missing_set|failed')
        else
            ClearLastError();
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
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        Observer.Observe('export_zero_dec', ReadAll(InS));
        Src.Dec := 7.5;
        Src.Modify();
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(Xmlport::"LT U XmlPort", OutS);
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        Observer.Observe('export_dec_7_5', ReadAll(InS));
        Observer.Finish();
    end;
}
