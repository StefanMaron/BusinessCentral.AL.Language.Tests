// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-relations
// https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-wordxmlpart-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained tables 69346 and 69347, report 69347, codeunit 69346
// Probe: written against a real BC 29.0 service tier (29.0.54011.55816); every literal below is what that tier produced. Other BC versions were not measured.
//
// TableRelation Field."No." where(TableNo = field(F)) with F a FlowField: the relation check calculates the FlowField itself, so Validate passes with and without a prior CalcFields,
// and a number that is not a field of the table gives DB:RecordNotFound ("... contains a value (99) that cannot be found in the related table (Field)."), the same as with a plain field.
// Report.WordXmlPart(ReportId) and Report.WordXmlPart(ReportId, Boolean) answer the XML of the data set as text for a report that has only an RDLC layout, with either flag; an unknown report id fails (AL:MetadataNotFound).
// The text contains the column names and the Word data namespace marker.
// BC versions: 29.0
table 69346 "PZ Rel Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; TblNo; Integer) { }
        field(3; TblFlow; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("PZ Rel Source".TableNo where(Id = field(Id)));
        }
        field(4; FieldNoViaFlow; Integer)
        {
            TableRelation = Field."No." where(TableNo = field(TblFlow));
        }
        field(5; FieldNoViaPlain; Integer)
        {
            TableRelation = Field."No." where(TableNo = field(TblNo));
        }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 69347 "PZ Rel Source"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; TableNo; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

report 69347 "PZ Word Report"
{
    DefaultLayout = RDLC;

    dataset
    {
        dataitem(Src; "PZ Rel Source")
        {
            column(IdCol; Id) { }
        }
    }
}

codeunit 69346 "PZ Misc Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "PZ Rel Row";
        Src: Record "PZ Rel Source";
    begin
        Row.DeleteAll();
        Src.DeleteAll();
        Src.Id := 1;
        Src.TableNo := Database::"PZ Rel Source";
        Src.Insert();
        Row.Id := 1;
        Row.TblNo := Database::"PZ Rel Source";
        Row.Insert();
    end;

    [TryFunction]
    local procedure TryValidateFlow(var Row: Record "PZ Rel Row"; Value: Integer)
    begin
        Row.Validate(FieldNoViaFlow, Value);
    end;

    [Test]
    procedure Validate_TableRelationFilteredByAFlowField()
    var
        Row: Record "PZ Rel Row";
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.Get(1);
        Observer.Observe('flow_before_calc', Format(Row.TblFlow));
        Row.Validate(FieldNoViaPlain, 1);
        Observer.Observe('plain_relation_validate_ok', Format(Row.FieldNoViaPlain));
        Ok := TryValidateFlow(Row, 1);
        Observer.Observe('flow_relation_without_calcfields', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode() + ' value=' + Format(Row.FieldNoViaFlow));
        ClearLastError();
        Row.Get(1);
        Row.CalcFields(TblFlow);
        Observer.Observe('flow_after_calc', Format(Row.TblFlow = Row.TblNo));
        Row.Validate(FieldNoViaFlow, 1);
        Observer.Observe('flow_relation_after_calcfields', Format(Row.FieldNoViaFlow));
        Observer.Expect('flow_before_calc', '0');
        Observer.Expect('plain_relation_validate_ok', '1');
        Observer.Expect('flow_relation_without_calcfields', 'Yes | value=1');
        Observer.Expect('flow_after_calc', 'Yes');
        Observer.Expect('flow_relation_after_calcfields', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_TableRelation_MissingFieldNumber()
    var
        Row: Record "PZ Rel Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.Get(1);
        Row.CalcFields(TblFlow);
        asserterror Row.Validate(FieldNoViaFlow, 99);
        Observer.ObserveError('flow_relation_missing_value');
        asserterror Row.Validate(FieldNoViaPlain, 99);
        Observer.ObserveError('plain_relation_missing_value');
        Observer.Expect('flow_relation_missing_value|text', 'The field FieldNoViaFlow of table PZ Rel Row contains a value (99) that cannot be found in the related table (Field).');
        Observer.Expect('flow_relation_missing_value|code', 'DB:RecordNotFound');
        Observer.Expect('plain_relation_missing_value|text', 'The field FieldNoViaPlain of table PZ Rel Row contains a value (99) that cannot be found in the related table (Field).');
        Observer.Expect('plain_relation_missing_value|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryWordXmlPart(ReportId: Integer; var Result: Text)
    begin
        Result := Report.WordXmlPart(ReportId);
    end;

    [TryFunction]
    local procedure TryWordXmlPartFlag(ReportId: Integer; Flag: Boolean; var Result: Text)
    begin
        Result := Report.WordXmlPart(ReportId, Flag);
    end;

    [Test]
    procedure WordXmlPart_BothOverloads_ReportWithoutWordLayout()
    var
        Result: Text;
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Ok := TryWordXmlPart(Report::"PZ Word Report", Result);
        Observer.Observe('one_argument', Format(Ok) + ' length>0=' + Format(StrLen(Result) > 0) + ' starts_with_xml=' + Format(Result.StartsWith('<')) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Clear(Result);
        Ok := TryWordXmlPartFlag(Report::"PZ Word Report", true, Result);
        Observer.Observe('with_flag_true', Format(Ok) + ' length>0=' + Format(StrLen(Result) > 0) + ' starts_with_xml=' + Format(Result.StartsWith('<')) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Clear(Result);
        Ok := TryWordXmlPart(99999999, Result);
        Observer.Observe('missing_report', Format(Ok) + ' result_empty=' + Format(Result = '') + ' code=' + GetLastErrorCode());
        ClearLastError();
        Clear(Result);
        Ok := TryWordXmlPartFlag(Report::"PZ Word Report", false, Result);
        Observer.Observe('with_flag_false', Format(Ok) + ' length>0=' + Format(StrLen(Result) > 0) + ' starts_with_xml=' + Format(Result.StartsWith('<')) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Observer.Expect('one_argument', 'Yes length>0=Yes starts_with_xml=Yes |');
        Observer.Expect('with_flag_true', 'Yes length>0=Yes starts_with_xml=Yes |');
        Observer.Expect('missing_report', 'No result_empty=Yes code=AL:MetadataNotFound');
        Observer.Expect('with_flag_false', 'Yes length>0=Yes starts_with_xml=Yes |');
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_Content_IncludesTheColumns()
    var
        Result: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Result := Report.WordXmlPart(Report::"PZ Word Report");
        Observer.Observe('contains_idcol', Format(StrPos(Result, 'IdCol') > 0));
        Observer.Observe('contains_src', Format(StrPos(Result, 'Src') > 0));
        Observer.Observe('contains_word_namespace_marker', Format(StrPos(Result, 'urn:microsoft-dynamics-nav') > 0));
        Observer.Expect('contains_idcol', 'Yes');
        Observer.Expect('contains_src', 'Yes');
        Observer.Expect('contains_word_namespace_marker', 'Yes');
        Observer.Verify();
    end;
}
