// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: OnPrem (the tables have Scope = OnPrem in the system symbols; a Cloud app gets AL0296, see must-not-compile cases 0020 to 0022).
// Fixtures used: tests/al-language/platform/lt-platform-tables/PtHelper.al (LT PT Ops)
// Probe: platform tables that have no row provider in the AL runtime, the OnPrem ones: the column list, whether rows exist, the first row, an Insert,
// a second Insert of the same key, a Modify, a Delete and an Insert without triggers (the same sequence as PtCloudTables.al). Object id 61229.

codeunit 61229 "LT PT OnPrem Tables"
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
    procedure WebService_InsertModifyDelete()
    begin
        Standard(Database::"Web Service", '3=8;6=10;9=LTPTSvc;12=true', '3=8;9=LTPTSvc', '12=false');
    end;

    [Test]
    procedure ConfigurationPackageFile_InsertModifyDelete()
    begin
        Standard(Database::"Configuration Package File", '1=LTPT;2=LT PT Package;3=1033;4=1;5=7', '1=LTPT', '2=Renamed');
    end;

    [Test]
    procedure DocumentServiceScenario_InsertModifyDelete()
    begin
        Standard(Database::"Document Service Scenario", '1=0;2={44444444-4444-4444-4444-444444444444};3=LTPT;4=true;5=false', '1=0;2={44444444-4444-4444-4444-444444444444}', '4=false');
    end;

    [Test]
    procedure DocumentService_InsertModifyDelete()
    begin
        Standard(Database::"Document Service", '1=LTPT;3=LT PT Service;5=http://localhost/ltpt;7=ltpt;21=1', '1=LTPT', '3=Renamed');
    end;

    [Test]
    procedure TableInformation_InsertModifyDelete()
    begin
        Standard(Database::"Table Information", '1=LTPT;2=99999;3=LT PT Table;4=5', '1=LTPT;2=99999', '4=6');
    end;

    [Test]
    procedure ReportSettingsOverride_InsertModifyDelete()
    begin
        Standard(Database::"Report Settings Override", '1=99999;2=LTPT;3=30;4=100;5=10;6=en-US;7=1033', '1=99999;2=LTPT', '3=60');
    end;

    [Test]
    procedure Device_InsertModifyDelete()
    begin
        Standard(Database::"Device", '1=LTPT0001;2=LT PT Device;3=1;4=true', '1=LTPT0001', '4=false');
    end;

    [Test]
    procedure TenantProfile_InsertModifyDelete()
    begin
        Standard(Database::"Tenant Profile", '1={55555555-5555-5555-5555-555555555555};2=LTPTPROFILE;3=LT PT Profile;4=9022;5=false', '2=LTPTPROFILE', '3=Renamed');
    end;

    [Test]
    procedure TenantProfilePageMetadata_InsertModifyDelete()
    begin
        Standard(Database::"Tenant Profile Page Metadata", '1={55555555-5555-5555-5555-555555555555};2=LTPTPROFILE;3=99999;6=1', '2=LTPTPROFILE;3=99999', '7=2');
    end;
}
