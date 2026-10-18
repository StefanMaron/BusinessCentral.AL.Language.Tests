// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/attributes/devenv-attributes-overview
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: attributes on procedures and variables in a Cloud app: Caption, None, Obsolete (Pending), Scope (Cloud), ServiceEnabled, InDataSet, SecurityFiltering on a Record variable, TestPermissions on a test procedure, ReportHandler. Settles #629 items 1, 3, 6, 7, 8, 12 (Cloud scope), 13, 14 and 17.
//   Compile errors are in the must-not-compile cases 0967 to 0980. Items that need an OnPrem app are in tests/al-language-onprem-dotnet/lt-ac.
// BC versions: 27, 28, 29
//   RequiredPending is BC 29 (runtime 18.0) and guarded; BC 27 and 28 reject it (must-not-compile case 0971).

table 77530 "LT AC Attr Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 77530 "LT AC Attr Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT AC Attr Row")
        {
            trigger OnPreDataItem()
            begin
                ReportState.Note('predataitem');
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(OptionValue; OptionValue)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        ReportState: Codeunit "LT AC Report State";
        [InDataSet]
        OptionValue: Integer;

    trigger OnPreReport()
    begin
        ReportState.Note('prereport:' + Format(OptionValue));
    end;

    trigger OnPostReport()
    begin
        ReportState.Note('postreport');
    end;

    procedure SetOptionValue(NewValue: Integer)
    begin
        OptionValue := NewValue;
    end;

    procedure GetOptionValue(): Integer
    begin
        exit(OptionValue);
    end;
}

codeunit 77531 "LT AC Report State"
{
    SingleInstance = true;

    var
        Notes: Text;

    procedure Note(Value: Text)
    begin
        Notes += '[' + Value + ']';
    end;

    procedure Reset()
    begin
        Clear(Notes);
    end;

    procedure Text(): Text
    begin
        exit(Notes);
    end;
}

codeunit 77533 "LT AC Insert Helper"
{
    TableNo = "LT AC Attr Row";

    trigger OnRun()
    begin
        Rec.Insert();
    end;
}

codeunit 77532 "LT AC Attributes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        [InDataSet]
        InDataSetFlag: Boolean;
        Calls: Integer;

    [Test]
    procedure AC_Attr_Procedures()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('caption', Captioned());
        Observer.Observe('none', NoneAttr());
        Observer.Observe('obsolete_pending', PendingObsolete());
        Observer.Observe('scope_cloud', ScopeCloud());
        Observer.Observe('service_enabled', ServiceEnabledProc());
        Observer.Observe('in_data_set_flag', Format(InDataSetFlag));
        Observer.Observe('calls', Format(Calls));
        Observer.Expect('caption', 'captioned_ran');
        Observer.Expect('none', 'none_ran');
        Observer.Expect('obsolete_pending', 'obsolete_ran');
        Observer.Expect('scope_cloud', 'cloud_ran');
        Observer.Expect('service_enabled', 'service_enabled_ran');
        Observer.Expect('in_data_set_flag', 'No');
        Observer.Expect('calls', '5');
        Observer.Verify();
    end;

#if BC29PLUS
    [Test]
    procedure AC_Attr_RequiredPending()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('required_pending', RequiredPendingProc());
        Observer.Finish();
    end;

    [RequiredPending('Use the new procedure', '29.0')]
    local procedure RequiredPendingProc(): Text
    begin
        exit('required_pending_ran');
    end;
#endif

    [Test]
    procedure AC_Attr_SecurityFiltering_Variable()
    var
        Observer: Codeunit "Probe Observer";
        [SecurityFiltering(SecurityFilter::Filtered)]
        FilteredRow: Record "LT AC Attr Row";
        [SecurityFiltering(SecurityFilter::Validated)]
        ValidatedRow: Record "LT AC Attr Row";
        [SecurityFiltering(SecurityFilter::Ignored)]
        IgnoredRow: Record "LT AC Attr Row";
        PlainRow: Record "LT AC Attr Row";
    begin
        Observer.Observe('plain', Format(PlainRow.SecurityFiltering()));
        Observer.Observe('filtered', Format(FilteredRow.SecurityFiltering()));
        Observer.Observe('validated', Format(ValidatedRow.SecurityFiltering()));
        Observer.Observe('ignored', Format(IgnoredRow.SecurityFiltering()));
        FilteredRow.DeleteAll();
        PlainRow.Id := 1;
        PlainRow.Insert();
        Observer.Observe('filtered_count', Format(FilteredRow.Count()));
        Observer.Observe('validated_count', Format(ValidatedRow.Count()));
        Observer.Observe('ignored_count', Format(IgnoredRow.Count()));
        FilteredRow.DeleteAll();
        Observer.Expect('plain', 'Validated');
        Observer.Expect('filtered', 'Filtered');
        Observer.Expect('validated', 'Validated');
        Observer.Expect('ignored', 'Ignored');
        Observer.Expect('filtered_count', '1');
        Observer.Expect('validated_count', '1');
        Observer.Expect('ignored_count', '1');
        Observer.Verify();
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    procedure AC_Attr_TestPermissions_Disabled()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AC Attr Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        if Row.Insert() then
            Observer.Observe('insert', 'ok')
        else
            Observer.ObserveError('insert');
        Row.DeleteAll();
        Observer.Expect('insert', 'ok');
        Observer.Verify();
    end;

    [Test]
    [TestPermissions(TestPermissions::Restrictive)]
    procedure AC_Attr_TestPermissions_Restrictive()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AC Attr Row";
    begin
        Row.Id := 2;
        if Codeunit.Run(Codeunit::"LT AC Insert Helper", Row) then
            Observer.Observe('insert', 'ok')
        else
            Observer.ObserveError('insert');
        Observer.Expect('insert', 'ok');
        Observer.Verify();
    end;

    [Test]
    [TestPermissions(TestPermissions::NonRestrictive)]
    procedure AC_Attr_TestPermissions_NonRestrictive()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AC Attr Row";
    begin
        Row.Id := 3;
        if Codeunit.Run(Codeunit::"LT AC Insert Helper", Row) then
            Observer.Observe('insert', 'ok')
        else
            Observer.ObserveError('insert');
        Observer.Expect('insert', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure AC_Attr_ReportHandler_RunReport()
    var
        Observer: Codeunit "Probe Observer";
        ReportState: Codeunit "LT AC Report State";
    begin
        ReportState.Reset();
        asserterror Report.Run(Report::"LT AC Attr Report");
        Observer.ObserveError('run');
        Observer.Observe('notes', ReportState.Text());
        Observer.Expect('run|text', 'Unhandled UI: RequestPage 77530');
        Observer.Expect('run|code', 'MissingUIHandler');
        Observer.Expect('notes', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OptionsReportHandler')]
    procedure AC_Attr_ReportHandler_Handler()
    var
        Observer: Codeunit "Probe Observer";
        ReportState: Codeunit "LT AC Report State";
    begin
        ReportState.Reset();
        Report.Run(Report::"LT AC Attr Report");
        Observer.Observe('notes', ReportState.Text());
        Observer.Observe('handler_calls', Format(Calls));
        Observer.Expect('notes', '');
        Observer.Expect('handler_calls', '6');
        Observer.Verify();
    end;

    [Test]
    procedure AC_Attr_InDataSet_ReportXml()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Xml: Text;
        Line: Text;
    begin
        TempBlob.CreateOutStream(OutStr);
        if TrySaveAsXml(OutStr) then begin
            TempBlob.CreateInStream(InStr);
            while not InStr.EOS() do begin
                InStr.ReadText(Line);
                Xml += Line;
            end;
            Observer.Observe('xml_has_option_value', Format(StrPos(Xml, 'OptionValue') > 0));
            Observer.Observe('xml_has_row', Format(StrPos(Xml, 'Row') > 0));
            Observer.Observe('xml_length_over_zero', Format(StrLen(Xml) > 0));
        end else
            Observer.ObserveError('save_as_xml');
        Observer.Expect('save_as_xml|text', 'Report 77530 is a processing-only report. Output cannot be rendered and saved to a file.');
        Observer.Expect('save_as_xml|code', 'ReportProcessingOnly');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySaveAsXml(var OutStr: OutStream)
    begin
        Report.SaveAs(Report::"LT AC Attr Report", '', ReportFormat::Xml, OutStr);
    end;

    [ReportHandler]
    procedure OptionsReportHandler(var AttrReport: Report "LT AC Attr Report")
    begin
        Calls += 1;
        AttrReport.SetOptionValue(42);
    end;

    [ServiceEnabled]
    [Caption('AC caption')]
    local procedure Captioned(): Text
    begin
        Calls += 1;
        exit('captioned_ran');
    end;

    [None]
    local procedure NoneAttr(): Text
    begin
        Calls += 1;
        exit('none_ran');
    end;

    [Obsolete('Pending since 1.0; use something else', '1.0')]
    local procedure PendingObsolete(): Text
    begin
        Calls += 1;
        exit('obsolete_ran');
    end;

    [Scope('Cloud')]
    local procedure ScopeCloud(): Text
    begin
        Calls += 1;
        exit('cloud_ran');
    end;

    [ServiceEnabled]
    local procedure ServiceEnabledProc(): Text
    begin
        Calls += 1;
        exit('service_enabled_ran');
    end;
}
