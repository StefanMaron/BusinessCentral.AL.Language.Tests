// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-class
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: the count and every row (4), with every column, of the platform table Tenant Report Layout Selection on the fresh tenant of a test container (read through RecordRef by table name).
// First rows of the platform tables are also pinned in platform/lt-platform-tables/PtCloudTables.al. Object id 78109.

codeunit 78109 "LT AD Plat Rows Layout"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TableIdByName(TableName: Text): Integer
    var
        AllObj: Record AllObj;
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object Name", TableName);
        if AllObj.FindFirst() then
            exit(AllObj."Object ID");
        exit(-1);
    end;

    local procedure RowText(var RR: RecordRef): Text
    var
        FR: FieldRef;
        i: Integer;
        Result: Text;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if FR.Class() = FieldClass::Normal then
                if FR.Type() in [FieldType::Blob, FieldType::Media, FieldType::MediaSet] then
                    Result += FR.Name() + '=<' + Format(FR.Type()) + '>|'
                else
                    Result += FR.Name() + '=' + Format(FR.Value()) + '|';
        end;
        exit(Result);
    end;

    local procedure Dump(var Observer: Codeunit "Probe Observer"; TableName: Text; Skip: Integer; Take: Integer)
    var
        RR: RecordRef;
        Id: Integer;
        n: Integer;
    begin
        Id := TableIdByName(TableName);
        Observer.Observe(TableName + ' id', Format(Id));
        if Id < 0 then
            exit;
        RR.Open(Id);
                if RR.FindSet() then
            repeat
                n += 1;
                if (n > Skip) and (n <= Skip + Take) then
                    Observer.Observe(TableName + ' row ' + Format(n), RowText(RR));
            until (RR.Next() = 0) or (n >= Skip + Take);
    end;

    [Test]
    procedure Rows_TenantReportLayoutSelection()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Tenant Report Layout Selection', 0, 10);
        Observer.Finish();
    end;

    [Test]
    procedure Count_TenantReportLayoutSelection()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Id: Integer;
    begin
        Id := TableIdByName('Tenant Report Layout Selection');
        Observer.Observe('id', Format(Id));
        RR.Open(Id);
        Observer.Observe('count', Format(RR.Count()));
        Observer.Finish();
    end;
}
