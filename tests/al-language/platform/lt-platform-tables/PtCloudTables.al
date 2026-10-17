// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope; the platform tables that have Scope = Cloud (or no scope) in the system symbols, opened by RecordRef in a Cloud app.
// Fixtures used: PtHelper.al (LT PT Arg, LT PT Runner, LT PT Ops)
// Probe: platform tables that have no row provider in the AL runtime. For each table: the column list, whether rows exist, the first row, an Insert, a
// second Insert of the same key, a Modify, a Delete and an Insert without triggers. Every request runs in its own Codeunit.Run, so an error is observed
// as text and code. Object id 67107.

codeunit 67107 "LT PT Cloud Tables"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Ops: Codeunit "LT PT Ops";

    local procedure Standard(var Observer: Codeunit "Probe Observer"; TableNo: Integer; InsertRequest: Text; FilterRequest: Text; ChangeRequest: Text)
    begin
        Observer.Observe('columns', Ops.Perform(TableNo, 'columns', '', false));
        Observer.Observe('has_rows', Ops.Perform(TableNo, 'hasrows', '', false));
        Observer.Observe('first_row', Ops.Perform(TableNo, 'first', '', false));
        Observer.Observe('insert', Ops.Perform(TableNo, 'insert', InsertRequest, true));
        Observer.Observe('find_inserted', Ops.Perform(TableNo, 'find', FilterRequest, false));
        Observer.Observe('count_inserted', Ops.Perform(TableNo, 'count', FilterRequest, false));
        Observer.Observe('insert_duplicate', Ops.Perform(TableNo, 'insert', InsertRequest, true));
        Observer.Observe('modify', Ops.Perform(TableNo, 'modify', FilterRequest + '|' + ChangeRequest, true));
        Observer.Observe('find_modified', Ops.Perform(TableNo, 'find', FilterRequest, false));
        Observer.Observe('delete', Ops.Perform(TableNo, 'delete', FilterRequest, true));
        Observer.Observe('count_deleted', Ops.Perform(TableNo, 'count', FilterRequest, false));
        Observer.Observe('insert_no_triggers', Ops.Perform(TableNo, 'insert', InsertRequest, false));
        Observer.Observe('delete_all_no_triggers', Ops.Perform(TableNo, 'deleteall', FilterRequest, false));
        Observer.Observe('count_after_delete_all', Ops.Perform(TableNo, 'count', FilterRequest, false));
    end;

    [Test]
    procedure LanguageSelection_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Standard(Observer, 2000000050, '1=LT PT Language;2=99999;3=99999;4=LTP;5=true;6=lt-PT', '1=LT PT Language;6=lt-PT', '5=false');
        Observer.Expect('columns', 'ok:1:Name:Text:80:Normal;6:Language Tag:Text:80:Normal;2:Language ID:Integer:4:Normal;3:Primary Language ID:Integer:4:Normal;4:Abbreviated Name:Text:3:Normal;5:Enabled:Boolean:4:Normal;');
        Observer.Expect('has_rows', 'ok:Yes');
        Observer.Expect('first_row', 'ok:1=Afrikaans (South Africa);6=af-ZA;2=1078;3=1078;4=AFK;5=No;');
        Observer.Expect('insert', 'error:The Language Selection table is read-only.|DB:Ok');
        Observer.Expect('find_inserted', 'ok:none');
        Observer.Expect('count_inserted', 'ok:0');
        Observer.Expect('insert_duplicate', 'error:The Language Selection table is read-only.|DB:Ok');
        Observer.Expect('modify', 'error:There is no Language Selection within the filter.\\Filters: Name: LT PT Language, Region: lt-PT|DB:NothingInsideFilter');
        Observer.Expect('find_modified', 'ok:none');
        Observer.Expect('delete', 'error:There is no Language Selection within the filter.\\Filters: Name: LT PT Language, Region: lt-PT|DB:NothingInsideFilter');
        Observer.Expect('count_deleted', 'ok:0');
        Observer.Expect('insert_no_triggers', 'error:The Language Selection table is read-only.|DB:Ok');
        Observer.Expect('delete_all_no_triggers', 'error:The Language Selection table is read-only.|DB:Ok');
        Observer.Expect('count_after_delete_all', 'ok:0');
        Observer.Verify();
    end;

    [Test]
    procedure LicensePermission_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Standard(Observer, 2000000043, '1=1;2=99999;10=1', '1=1;2=99999', '10=2');
        Observer.Expect('columns', 'ok:1:Object Type:Option:4:Normal;2:Object Number:Integer:4:Normal;10:Read Permission:Option:4:Normal;11:Insert Permission:Option:4:Normal;12:Modify Permission:Option:4:Normal;13:Delete Permission:Option:4:Normal;14:Execute Permission:Option:4:Normal;15:Limited Usage Permission:Option:4:Normal;');
        Observer.Expect('has_rows', 'ok:Yes');
        Observer.Expect('first_row', 'ok:1=TableData;2=0;10= ;11= ;12= ;13= ;14= ;15= ;');
        Observer.Expect('insert', 'error:The License Permission table is read-only.|DB:Ok');
        Observer.Expect('find_inserted', 'ok:1=Table;2=99999;10=Yes;11=Yes;12=Yes;13=Yes;14=Yes;15= ;');
        Observer.Expect('count_inserted', 'ok:1');
        Observer.Expect('insert_duplicate', 'error:The License Permission table is read-only.|DB:Ok');
        Observer.Expect('modify', 'error:The License Permission table is read-only.|DB:Ok');
        Observer.Expect('find_modified', 'ok:1=Table;2=99999;10=Yes;11=Yes;12=Yes;13=Yes;14=Yes;15= ;');
        Observer.Expect('delete', 'error:The License Permission table is read-only.|DB:Ok');
        Observer.Expect('count_deleted', 'ok:1');
        Observer.Expect('insert_no_triggers', 'error:The License Permission table is read-only.|DB:Ok');
        Observer.Expect('delete_all_no_triggers', 'error:The License Permission table is read-only.|DB:Ok');
        Observer.Expect('count_after_delete_all', 'ok:1');
        Observer.Verify();
    end;

    [Test]
    procedure EntityText_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Standard(Observer, 2000000132, '1=LTPT;2=18;3={11111111-1111-1111-1111-111111111111};4=0;5=preview', '1=LTPT;2=18', '5=changed');
        Observer.Expect('columns', 'ok:1:Company:Text:30:Normal;2:Source Table Id:Integer:4:Normal;3:Source System Id:GUID:16:Normal;4:Scenario:Option:4:Normal;5:Preview Text:Text:1024:Normal;6:Text:BLOB:8:Normal;');
        Observer.Expect('has_rows', 'ok:No');
        Observer.Expect('first_row', 'ok:none');
        Observer.Expect('insert', 'ok:Yes');
        Observer.Expect('find_inserted', 'ok:1=LTPT;2=18;3=<guid>;4=Marketing Text;5=preview;6=<BLOB>;');
        Observer.Expect('count_inserted', 'ok:1');
        Observer.Expect('insert_duplicate', 'ok:No');
        Observer.Expect('modify', 'ok:Yes');
        Observer.Expect('find_modified', 'ok:1=LTPT;2=18;3=<guid>;4=Marketing Text;5=changed;6=<BLOB>;');
        Observer.Expect('delete', 'ok:Yes');
        Observer.Expect('count_deleted', 'ok:0');
        Observer.Expect('insert_no_triggers', 'ok:Yes');
        Observer.Expect('delete_all_no_triggers', 'ok:done');
        Observer.Expect('count_after_delete_all', 'ok:0');
        Observer.Verify();
    end;

    [Test]
    procedure TenantReportLayoutSelection_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Standard(Observer, 2000000233, '1=99999;2=LTPT Layout;3={22222222-2222-2222-2222-222222222222};4=LTPT;5={33333333-3333-3333-3333-333333333333}', '1=99999;4=LTPT', '2=Changed');
#if BC29PLUS
        Observer.Expect('columns', 'ok:1:Report ID:Integer:4:Normal;4:Company Name:Text:30:Normal;5:User ID:GUID:16:Normal;2:Layout Name:Text:250:Normal;3:App ID:GUID:16:Normal;6:Header Part Name:Text:300:Normal;7:Theme Part Name:Text:300:Normal;');
#else
        Observer.Expect('columns', 'ok:1:Report ID:Integer:4:Normal;4:Company Name:Text:30:Normal;5:User ID:GUID:16:Normal;2:Layout Name:Text:250:Normal;3:App ID:GUID:16:Normal;');
#endif
        Observer.Expect('has_rows', 'ok:Yes');
#if BC29PLUS
        Observer.Expect('first_row', 'ok:1=1302;4=;5=<blank guid>;2=StandardSalesProFormaInv.docx;3=<guid>;6=;7=;');
#else
        Observer.Expect('first_row', 'ok:1=1302;4=;5=<blank guid>;2=StandardSalesProFormaInv.docx;3=<guid>;');
#endif
        Observer.Expect('insert', 'ok:Yes');
#if BC29PLUS
        Observer.Expect('find_inserted', 'ok:1=99999;4=LTPT;5=<guid>;2=LTPT Layout;3=<guid>;6=;7=;');
#else
        Observer.Expect('find_inserted', 'ok:1=99999;4=LTPT;5=<guid>;2=LTPT Layout;3=<guid>;');
#endif
        Observer.Expect('count_inserted', 'ok:1');
        Observer.Expect('insert_duplicate', 'ok:No');
        Observer.Expect('modify', 'ok:Yes');
#if BC29PLUS
        Observer.Expect('find_modified', 'ok:1=99999;4=LTPT;5=<guid>;2=Changed;3=<guid>;6=;7=;');
#else
        Observer.Expect('find_modified', 'ok:1=99999;4=LTPT;5=<guid>;2=Changed;3=<guid>;');
#endif
        Observer.Expect('delete', 'ok:Yes');
        Observer.Expect('count_deleted', 'ok:0');
        Observer.Expect('insert_no_triggers', 'ok:Yes');
        Observer.Expect('delete_all_no_triggers', 'ok:done');
        Observer.Expect('count_after_delete_all', 'ok:0');
        Observer.Verify();
    end;

    [Test]
    procedure MediaResources_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Standard(Observer, 2000000182, '1=LTPT1', '1=LTPT1', '');
        Observer.Expect('columns', 'ok:1:Code:Code:50:Normal;2:MediaSet Reference:MediaSet:16:Normal;3:Media Reference:Media:16:Normal;4:Blob:BLOB:8:Normal;');
        Observer.Expect('has_rows', 'ok:Yes');
        Observer.Expect('first_row', 'ok:1=1305-1-DEFAULT.PNG;2=<MediaSet>;3=<Media>;4=<BLOB>;');
        Observer.Expect('insert', 'ok:Yes');
        Observer.Expect('find_inserted', 'ok:1=LTPT1;2=<MediaSet>;3=<Media>;4=<BLOB>;');
        Observer.Expect('count_inserted', 'ok:1');
        Observer.Expect('insert_duplicate', 'ok:No');
        Observer.Expect('modify', 'ok:Yes');
        Observer.Expect('find_modified', 'ok:1=LTPT1;2=<MediaSet>;3=<Media>;4=<BLOB>;');
        Observer.Expect('delete', 'ok:Yes');
        Observer.Expect('count_deleted', 'ok:0');
        Observer.Expect('insert_no_triggers', 'ok:Yes');
        Observer.Expect('delete_all_no_triggers', 'ok:done');
        Observer.Expect('count_after_delete_all', 'ok:0');
        Observer.Verify();
    end;

    [Test]
    procedure ObjectAccessIntentOverride_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Standard(Observer, 2000000205, '1=3;2=99999;3=1', '1=3;2=99999', '3=2');
        Observer.Expect('columns', 'ok:1:Object Type:Option:4:Normal;2:Object ID:Integer:4:Normal;3:Access Intent:Option:4:Normal;');
        Observer.Expect('has_rows', 'ok:No');
        Observer.Expect('first_row', 'ok:none');
        Observer.Expect('insert', 'ok:Yes');
        Observer.Expect('find_inserted', 'ok:1=Report;2=99999;3=ReadOnly;');
        Observer.Expect('count_inserted', 'ok:1');
        Observer.Expect('insert_duplicate', 'ok:No');
        Observer.Expect('modify', 'ok:Yes');
        Observer.Expect('find_modified', 'ok:1=Report;2=99999;3=ReadWrite;');
        Observer.Expect('delete', 'ok:Yes');
        Observer.Expect('count_deleted', 'ok:0');
        Observer.Expect('insert_no_triggers', 'ok:Yes');
        Observer.Expect('delete_all_no_triggers', 'ok:done');
        Observer.Expect('count_after_delete_all', 'ok:0');
        Observer.Verify();
    end;

    [Test]
    procedure TenantWebService_ExistingObject_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Page 10 exists in every Cronus database.
        Standard(Observer, 2000000168, '3=8;6=10;9=LTPTSvc;12=true', '3=8;9=LTPTSvc', '12=false');
        Observer.Expect('columns', 'ok:3:Object Type:Option:4:Normal;9:Service Name:Text:250:Normal;6:Object ID:Integer:4:Normal;12:Published:Boolean:4:Normal;13:ExcludeFieldsOutsideRepeater:Boolean:4:Normal;14:ExcludeNonEditableFlowFields:Boolean:4:Normal;');
        Observer.Expect('has_rows', 'ok:Yes');
        Observer.Expect('first_row', 'ok:3=Codeunit;9=WorkflowActionResponse;6=1544;12=Yes;13=No;14=No;');
        Observer.Expect('insert', 'ok:Yes');
        Observer.Expect('find_inserted', 'ok:3=Page;9=LTPTSvc;6=10;12=Yes;13=No;14=No;');
        Observer.Expect('count_inserted', 'ok:1');
        Observer.Expect('insert_duplicate', 'ok:No');
        Observer.Expect('modify', 'ok:Yes');
        Observer.Expect('find_modified', 'ok:3=Page;9=LTPTSvc;6=10;12=No;13=No;14=No;');
        Observer.Expect('delete', 'ok:Yes');
        Observer.Expect('count_deleted', 'ok:0');
        Observer.Expect('insert_no_triggers', 'ok:Yes');
        Observer.Expect('delete_all_no_triggers', 'ok:done');
        Observer.Expect('count_after_delete_all', 'ok:0');
        Observer.Verify();
    end;

    [Test]
    procedure TenantWebService_Edges()
    var
        Observer: Codeunit "Probe Observer";
        T: Integer;
    begin
        T := 2000000168;
        Observer.Observe('insert_nonexistent_object', Ops.Perform(T, 'insert', '3=8;6=99999;9=LTPTMissing;12=true', true));
        Observer.Observe('insert_nonexistent_object_no_triggers', Ops.Perform(T, 'insert', '3=8;6=99998;9=LTPTMissing2;12=true', false));
        Observer.Observe('insert_blank_name', Ops.Perform(T, 'insert', '3=8;6=10', true));
        Observer.Observe('insert_type_blank', Ops.Perform(T, 'insert', '3=0;6=10;9=LTPTBlankType', true));
        Observer.Observe('insert_type_codeunit', Ops.Perform(T, 'insert', '3=5;6=1;9=LTPTCodeunit', true));
        Observer.Observe('insert_type_query', Ops.Perform(T, 'insert', '3=9;6=10;9=LTPTQuery', true));
        Observer.Observe('insert_one', Ops.Perform(T, 'insert', '3=8;6=10;9=LTPTOne', true));
        Observer.Observe('insert_same_object_other_name', Ops.Perform(T, 'insert', '3=8;6=10;9=LTPTTwo', true));
        Observer.Observe('count_same_object', Ops.Perform(T, 'count', '3=8;6=10', false));
        Observer.Observe('insert_name_case', Ops.Perform(T, 'insert', '3=8;6=10;9=ltptone', true));
        Observer.Expect('insert_nonexistent_object', 'ok:Yes');
        Observer.Expect('insert_nonexistent_object_no_triggers', 'ok:Yes');
        Observer.Expect('insert_blank_name', 'ok:Yes');
        Observer.Expect('insert_type_blank', 'ok:Yes');
        Observer.Expect('insert_type_codeunit', 'ok:Yes');
        Observer.Expect('insert_type_query', 'ok:Yes');
        Observer.Expect('insert_one', 'ok:Yes');
        Observer.Expect('insert_same_object_other_name', 'ok:Yes');
        Observer.Expect('count_same_object', 'ok:3');
        Observer.Expect('insert_name_case', 'ok:Yes');
        Observer.Verify();
    end;
}
