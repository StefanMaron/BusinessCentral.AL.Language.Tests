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

    local procedure Standard(TableNo: Integer; InsertRequest: Text; FilterRequest: Text; ChangeRequest: Text)
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure LanguageSelection_InsertModifyDelete()
    begin
        Standard(2000000050, '1=LT PT Language;2=99999;3=99999;4=LTP;5=true;6=lt-PT', '1=LT PT Language;6=lt-PT', '5=false');
    end;

    [Test]
    procedure LicensePermission_InsertModifyDelete()
    begin
        Standard(2000000043, '1=1;2=99999;10=1', '1=1;2=99999', '10=2');
    end;

    [Test]
    procedure EntityText_InsertModifyDelete()
    begin
        Standard(2000000132, '1=LTPT;2=18;3={11111111-1111-1111-1111-111111111111};4=0;5=preview', '1=LTPT;2=18', '5=changed');
    end;

    [Test]
    procedure TenantReportLayoutSelection_InsertModifyDelete()
    begin
        Standard(2000000233, '1=99999;2=LTPT Layout;3={22222222-2222-2222-2222-222222222222};4=LTPT;5={33333333-3333-3333-3333-333333333333}', '1=99999;4=LTPT', '2=Changed');
    end;

    [Test]
    procedure MediaResources_InsertModifyDelete()
    begin
        Standard(2000000182, '1=LTPT1', '1=LTPT1', '');
    end;

    [Test]
    procedure ObjectAccessIntentOverride_InsertModifyDelete()
    begin
        Standard(2000000205, '1=3;2=99999;3=1', '1=3;2=99999', '3=2');
    end;

    [Test]
    procedure TenantWebService_ExistingObject_InsertModifyDelete()
    begin
        // Page 10 exists in every Cronus database.
        Standard(2000000168, '3=8;6=10;9=LTPTSvc;12=true', '3=8;9=LTPTSvc', '12=false');
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
        Observer.Finish();
    end;
}
