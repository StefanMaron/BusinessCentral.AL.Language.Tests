// Probe (observe only): platform tables without a provider (read only), a temporary record of a CRM table, a field declared ObsoleteState = Removed in a RecordRef,
// a TableFilter field, the hidden SystemId field and key in a RecordRef, SetPermissionFilter, partial records (AddLoadFields / SetBaseLoadFields without SetLoadFields).
// Settles docs/probes-needed.md rows 290, 391, 517 (partly), 619, 673 (partly), 808, 809 (batch 4). Object ids 68052 - 68059.
// Compile finding for row 517: Document Service, Tenant Profile Page Metadata, Web Service, MCP Configuration, Performance Profile Scheduler and Document Service Scenario
// have scope OnPrem (AL0296 in a Cloud app): they cannot be probed from this app.

table 68052 "W4 CRM Temp"
{
    TableType = CRM;
    ExternalName = 'w4crm';
    fields
    {
        field(1; Id; Guid) { ExternalName = 'w4crmid'; ExternalType = 'Uniqueidentifier'; ExternalAccess = Insert; }
        field(2; Name; Text[50]) { ExternalName = 'name'; ExternalType = 'String'; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 68053 "W4 Removed Field"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Old; Integer) { ObsoleteState = Removed; ObsoleteReason = 'Probe of a removed field.'; ObsoleteTag = '1.0'; }
        field(3; Cur; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 68054 "W4 TF Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Flt; TableFilter) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 68055 "W4 Partial Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Cd; Code[10]) { }
        field(3; Txt; Text[20]) { }
        field(4; Dec; Decimal) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
        key(KC; Cd) { }
    }
}

codeunit 68056 "W4 Platform Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // ---- md:517: read only; tables with no provider, count of the rows a test tenant holds ----
    [TryFunction]
    local procedure TryCountTable(TableNo: Integer; var Result: Text)
    var
        RR: RecordRef;
    begin
        RR.Open(TableNo);
        Result := Format(RR.Count());
    end;

    local procedure Outcome(Ok: Boolean; Value: Text): Text
    begin
        if Ok then
            exit('ok:[' + Value + ']');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure PlatformTablesWithoutProvider_ReadCounts()
    var
        Result: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('tenant_report_layout_selection_count', Outcome(TryCountTable(Database::"Tenant Report Layout Selection", Result), Result));
        ClearLastError();
        Observer.Observe('media_resources_count', Outcome(TryCountTable(Database::"Media Resources", Result), Result));
        ClearLastError();
        Observer.Observe('signup_context_count', Outcome(TryCountTable(Database::"Signup Context", Result), Result));
        ClearLastError();
        Observer.Observe('tenant_web_service_count', Outcome(TryCountTable(Database::"Tenant Web Service", Result), Result));
        ClearLastError();
        Observer.Observe('tenant_web_service_odata_count', Outcome(TryCountTable(Database::"Tenant Web Service OData", Result), Result));
        ClearLastError();
        Observer.Expect('tenant_report_layout_selection_count', 'ok:[4]');
        Observer.Expect('media_resources_count', 'ok:[46]');
        Observer.Expect('signup_context_count', 'ok:[0]');
        Observer.Expect('tenant_web_service_count', 'ok:[64]');
        Observer.Expect('tenant_web_service_odata_count', 'ok:[29]');
        Observer.Verify();
    end;

    // ---- md:808: a temporary record of a CRM table, no connection registered ----
    [Test]
    procedure CrmTable_TemporaryRecord()
    var
        Crm: Record "W4 CRM Temp" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        Crm.Init();
        Crm.Id := CreateGuid();
        Crm.Name := 'one';
        Crm.Insert();
        Observer.Observe('count_after_insert', Format(Crm.Count()));
        Crm.Reset();
        Observer.Observe('count_after_reset', Format(Crm.Count()));
        Observer.Observe('findfirst', Format(Crm.FindFirst()));
        Observer.Observe('name', Crm.Name);
        Crm.DeleteAll();
        Observer.Observe('count_after_deleteall', Format(Crm.Count()));
        Observer.Observe('isempty', Format(Crm.IsEmpty()));
        Observer.Expect('count_after_insert', '1');
        Observer.Expect('count_after_reset', '1');
        Observer.Expect('findfirst', 'Yes');
        Observer.Expect('name', 'one');
        Observer.Expect('count_after_deleteall', '0');
        Observer.Expect('isempty', 'Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryCrmCount(var Result: Text)
    var
        Crm: Record "W4 CRM Temp";
    begin
        Result := Format(Crm.Count());
    end;

    [Test]
    procedure CrmTable_NonTemporaryRecord_WithoutConnection()
    var
        Result: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('count', Outcome(TryCrmCount(Result), Result));
        ClearLastError();
        Observer.Expect('count', 'error:Table connection  for table type CRM must be registered using RegisterTableConnection or cmdlet New-NAVTableConnection before it can be used.|Argument');
        Observer.Verify();
    end;

    // ---- md:809: a field declared ObsoleteState = Removed, seen through a RecordRef ----
    [TryFunction]
    local procedure TryFieldName(var RR: RecordRef; FieldNo: Integer; var Result: Text)
    begin
        Result := RR.Field(FieldNo).Name();
    end;

    [Test]
    procedure RemovedField_InRecordRef()
    var
        RR: RecordRef;
        Result: Text;
        Names: Text;
        i: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        RR.Open(Database::"W4 Removed Field");
        Observer.Observe('field_count', Format(RR.FieldCount()));
        Observer.Observe('field_exist_1', Format(RR.FieldExist(1)));
        Observer.Observe('field_exist_2', Format(RR.FieldExist(2)));
        Observer.Observe('field_exist_3', Format(RR.FieldExist(3)));
        for i := 1 to RR.FieldCount() do
            Names += Format(RR.FieldIndex(i).Number()) + ':' + RR.FieldIndex(i).Name() + ',';
        Observer.Observe('field_index_loop', Names);
        Observer.Observe('field_2_name', Outcome(TryFieldName(RR, 2, Result), Result));
        ClearLastError();
        Observer.Observe('field_3_name', Outcome(TryFieldName(RR, 3, Result), Result));
        ClearLastError();
        Observer.Expect('field_count', '2');
        Observer.Expect('field_exist_1', 'Yes');
        Observer.Expect('field_exist_2', 'No');
        Observer.Expect('field_exist_3', 'Yes');
        Observer.Expect('field_index_loop', '1:Id,3:Cur,');
        Observer.Expect('field_2_name', 'error:Field Old (2) of table W4 Removed Field (68053) is obsoleted, reason: Probe of a removed field.|MetadataObsolete');
        Observer.Expect('field_3_name', 'ok:[Cur]');
        Observer.Verify();
    end;

    [Test]
    procedure RemovedField_GeneralLedgerSetupField110()
    var
        RR: RecordRef;
        Result: Text;
        Observer: Codeunit "Probe Observer";
    begin
        RR.Open(Database::"General Ledger Setup");
        Observer.Observe('field_exist_110', Format(RR.FieldExist(110)));
        Observer.Observe('field_110_name', Outcome(TryFieldName(RR, 110, Result), Result));
        ClearLastError();
        Observer.Expect('field_exist_110', 'No');
        Observer.Expect('field_110_name', 'error:Field Acc. Sched. for Balance Sheet (110) of table General Ledger Setup (98) is obsoleted, reason: Financial Reporting is replacing Account Schedules for financial statements|MetadataObsolete');
        Observer.Verify();
    end;

    // ---- md:391: a TableFilter field nobody set ----
    [TryFunction]
    local procedure TrySetTableFilter(var RR: RecordRef; Value: Text)
    begin
        RR.Field(2).Value := Value;
    end;

    [Test]
    procedure TableFilterField_Format()
    var
        Row: Record "W4 TF Row";
        Got: Record "W4 TF Row";
        RR: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Observer.Observe('unset_in_memory', '[' + Format(Row.Flt) + ']');
        Row.Id := 1;
        Row.Insert();
        Got.Get(1);
        Observer.Observe('unset_after_insert_and_get', '[' + Format(Got.Flt) + ']');
        RR.GetTable(Got);
        Observer.Observe('unset_via_fieldref_format', '[' + Format(RR.Field(2).Value()) + ']');
        Observer.Observe('unset_via_fieldref_type', Format(RR.Field(2).Type()));
        Row.DeleteAll();
        Observer.Expect('unset_in_memory', '[]');
        Observer.Expect('unset_after_insert_and_get', '[]');
        Observer.Expect('unset_via_fieldref_format', '[]');
        Observer.Expect('unset_via_fieldref_type', 'TableFilter');
        Observer.Verify();
    end;

    [Test]
    procedure TableFilterField_SetFromText()
    var
        Row: Record "W4 TF Row";
        RR: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        RR.Open(Database::"W4 TF Row");
        Observer.Observe('set_where_const', Outcome(TrySetTableFilter(RR, 'WHERE(Id=CONST(1))'), ''));
        ClearLastError();
        Observer.Observe('after_where_const', '[' + Format(RR.Field(2).Value()) + ']');
        Observer.Observe('set_plain_text', Outcome(TrySetTableFilter(RR, 'Id: 1'), ''));
        ClearLastError();
        Observer.Observe('after_plain_text', '[' + Format(RR.Field(2).Value()) + ']');
        Observer.Observe('set_empty', Outcome(TrySetTableFilter(RR, ''), ''));
        ClearLastError();
        Observer.Observe('after_empty', '[' + Format(RR.Field(2).Value()) + ']');
#if BC28PLUS
        Observer.Expect('set_where_const', 'error:The value "WHERE(Id=CONST(1))" can''t be evaluated into type TableFilter.|Evaluate:Argument');
#else
        Observer.Expect('set_where_const', 'error:The supplied value is not valid.|Argument');
#endif
        Observer.Expect('after_where_const', '[]');
        Observer.Expect('set_plain_text', 'error:The value "Id: 1" can''t be evaluated into type TableFilter.|Evaluate:Argument');
        Observer.Expect('after_plain_text', '[]');
        Observer.Expect('set_empty', 'error:The value "" can''t be evaluated into type TableFilter.|Evaluate:Argument');
        Observer.Expect('after_empty', '[]');
        Observer.Verify();
    end;

    // ---- md:619: the hidden SystemId field and key in a RecordRef ----
    [Test]
    procedure RecordRef_SystemIdFieldAndHiddenKey()
    var
        RR: RecordRef;
        KR: KeyRef;
        Names: Text;
        i: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        RR.Open(Database::"W4 Sort Row");
        Observer.Observe('keycount', Format(RR.KeyCount()));
        Observer.Observe('systemid_exist', Format(RR.FieldExist(2000000000)));
        Observer.Observe('systemid_name', RR.Field(2000000000).Name());
        Observer.Observe('systemid_caption', RR.Field(2000000000).Caption());
        Observer.Observe('systemid_type', Format(RR.Field(2000000000).Type()));
        Observer.Observe('systemid_number', Format(RR.Field(2000000000).Number()));
        Observer.Observe('systemid_class', Format(RR.Field(2000000000).Class()));
        KR := RR.KeyIndex(RR.KeyCount());
        Observer.Observe('last_key_field_count', Format(KR.FieldCount()));
        for i := 1 to KR.FieldCount() do
            Names += KR.FieldIndex(i).Name() + ',';
        Observer.Observe('last_key_field_names', Names);
        RR.CurrentKeyIndex(RR.KeyCount());
        Observer.Observe('current_key_text_after_select_last', RR.CurrentKey());
        Observer.Expect('keycount', '4');
        Observer.Expect('systemid_exist', 'Yes');
        Observer.Expect('systemid_name', '$systemId');
        Observer.Expect('systemid_caption', 'System ID');
        Observer.Expect('systemid_type', 'GUID');
        Observer.Expect('systemid_number', '2000000000');
        Observer.Expect('systemid_class', 'Normal');
        Observer.Expect('last_key_field_count', '1');
        Observer.Expect('last_key_field_names', '$systemId,');
        Observer.Expect('current_key_text_after_select_last', 'System ID');
        Observer.Verify();
    end;

    // ---- md:673: SetPermissionFilter as a user who can read everything ----
    [Test]
    procedure SetPermissionFilter_RecordAndRecordRef()
    var
        R: Record "W4 Sort Row";
        RR: RecordRef;
        Before: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Insert();
        R.Id := 2;
        R.Insert();
        Before := R.Count();
        R.SetPermissionFilter();
        Observer.Observe('record_filters', '[' + R.GetFilters() + ']');
        Observer.Observe('record_view', '[' + R.GetView() + ']');
        Observer.Observe('record_count_same', Format(R.Count() = Before));
        RR.Open(Database::"W4 Sort Row");
        RR.SetPermissionFilter();
        Observer.Observe('recref_filters', '[' + RR.GetFilters() + ']');
        Observer.Observe('recref_view', '[' + RR.GetView() + ']');
        Observer.Observe('recref_count_same', Format(RR.Count() = Before));
        R.Reset();
        R.DeleteAll();
        Observer.Expect('record_filters', '[]');
        Observer.Expect('record_view', '[VERSION(1) SORTING(Id)]');
        Observer.Expect('record_count_same', 'Yes');
        Observer.Expect('recref_filters', '[]');
        Observer.Expect('recref_view', '[VERSION(1) SORTING(Id)]');
        Observer.Expect('recref_count_same', 'Yes');
        Observer.Verify();
    end;

    // ---- md:290: partial records without a SetLoadFields ----
    [TryFunction]
    local procedure TryLoaded(var R: Record "W4 Partial Row"; FieldNo: Integer; var Result: Text)
    begin
        case FieldNo of
            1:
                Result := Format(R.AreFieldsLoaded(Id));
            2:
                Result := Format(R.AreFieldsLoaded(Cd));
            3:
                Result := Format(R.AreFieldsLoaded(Txt));
            4:
                Result := Format(R.AreFieldsLoaded(Dec));
        end;
    end;

    local procedure LoadedFlags(var R: Record "W4 Partial Row"): Text
    var
        Result: Text;
        Flags: Text;
        i: Integer;
    begin
        for i := 1 to 4 do begin
            if TryLoaded(R, i, Result) then
                Flags += Result + ','
            else begin
                Flags += 'error:' + GetLastErrorText() + ',';
                ClearLastError();
            end;
        end;
        exit(Flags);
    end;

    local procedure SeedPartial()
    var
        R: Record "W4 Partial Row";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Cd := 'C';
        R.Txt := 'T';
        R.Dec := 5;
        R.Insert();
    end;

    [Test]
    procedure PartialRecords_AddLoadFieldsWithoutSetLoadFields()
    var
        R: Record "W4 Partial Row";
        Observer: Codeunit "Probe Observer";
    begin
        SeedPartial();
        R.AddLoadFields(Txt);
        R.Get(1);
        Observer.Observe('loaded_id_cd_txt_dec_after_add_then_get', LoadedFlags(R));
        Observer.Observe('txt_value', R.Txt);
        Observer.Observe('dec_value', Format(R.Dec));
        R.DeleteAll();
        Observer.Expect('loaded_id_cd_txt_dec_after_add_then_get', 'Yes,Yes,Yes,Yes,');
        Observer.Expect('txt_value', 'T');
        Observer.Expect('dec_value', '5');
        Observer.Verify();
    end;

    [Test]
    procedure PartialRecords_SetBaseLoadFieldsWithoutSetLoadFields()
    var
        R: Record "W4 Partial Row";
        Observer: Codeunit "Probe Observer";
    begin
        SeedPartial();
        R.SetBaseLoadFields();
        R.Get(1);
        Observer.Observe('loaded_id_cd_txt_dec', LoadedFlags(R));
        R.DeleteAll();
        Observer.Expect('loaded_id_cd_txt_dec', 'Yes,Yes,Yes,Yes,');
        Observer.Verify();
    end;

    [Test]
    procedure PartialRecords_SetBaseLoadFieldsOnAPartialRecord()
    var
        R: Record "W4 Partial Row";
        Observer: Codeunit "Probe Observer";
    begin
        SeedPartial();
        R.SetLoadFields(Txt);
        R.SetBaseLoadFields();
        R.Get(1);
        Observer.Observe('loaded_id_cd_txt_dec', LoadedFlags(R));
        R.DeleteAll();
        Observer.Expect('loaded_id_cd_txt_dec', 'Yes,Yes,Yes,Yes,');
        Observer.Verify();
    end;

    [Test]
    procedure PartialRecords_RecordLoadFields()
    var
        R: Record "W4 Partial Row";
        Observer: Codeunit "Probe Observer";
    begin
        SeedPartial();
        R.LoadFields(Cd);
        R.Get(1);
        Observer.Observe('loaded_id_cd_txt_dec', LoadedFlags(R));
        R.DeleteAll();
        Observer.Expect('loaded_id_cd_txt_dec', 'Yes,Yes,Yes,Yes,');
        Observer.Verify();
    end;

    [Test]
    procedure PartialRecords_RecordRefLoadFields()
    var
        RR: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        SeedPartial();
        RR.Open(Database::"W4 Partial Row");
        RR.SetLoadFields(2);
        RR.AddLoadFields(4);
        RR.Get(RecordIdOfRow());
        Observer.Observe('recref_loaded_id', Format(RR.AreFieldsLoaded(1)));
        Observer.Observe('recref_loaded_cd', Format(RR.AreFieldsLoaded(2)));
        Observer.Observe('recref_loaded_txt', Format(RR.AreFieldsLoaded(3)));
        Observer.Observe('recref_loaded_dec', Format(RR.AreFieldsLoaded(4)));
        Observer.Expect('recref_loaded_id', 'Yes');
        Observer.Expect('recref_loaded_cd', 'Yes');
        Observer.Expect('recref_loaded_txt', 'Yes');
        Observer.Expect('recref_loaded_dec', 'Yes');
        Observer.Verify();
    end;

    local procedure RecordIdOfRow(): RecordId
    var
        R: Record "W4 Partial Row";
    begin
        R.Get(1);
        exit(R.RecordId());
    end;

    [TryFunction]
    local procedure TryAddUnknown(var RR: RecordRef)
    begin
        RR.AddLoadFields(9999);
    end;

    [TryFunction]
    local procedure TrySetUnknown(var RR: RecordRef)
    begin
        RR.SetLoadFields(9999);
    end;

    [Test]
    procedure PartialRecords_UnknownFieldNumber()
    var
        RR: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        RR.Open(Database::"W4 Partial Row");
        Observer.Observe('addloadfields_9999', Outcome(TryAddUnknown(RR), ''));
        ClearLastError();
        Observer.Observe('setloadfields_9999', Outcome(TrySetUnknown(RR), ''));
        ClearLastError();
        Observer.Expect('addloadfields_9999', 'error:The supplied field number ''9999'' cannot be found in the ''W4 Partial Row'' table.|FieldNotFound');
        Observer.Expect('setloadfields_9999', 'error:The supplied field number ''9999'' cannot be found in the ''W4 Partial Row'' table.|FieldNotFound');
        Observer.Verify();
    end;
}
