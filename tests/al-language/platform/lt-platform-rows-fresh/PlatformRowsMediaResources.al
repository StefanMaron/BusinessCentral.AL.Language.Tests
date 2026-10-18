// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-class
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: the count and every row, in 4 tests of 12 rows each,, with every column, of the platform table MediaResources on the fresh tenant of a test container (read through RecordRef by table name).
// First rows of the platform tables are also pinned in platform/lt-platform-tables/PtCloudTables.al. Object id 78110.

codeunit 78110 "LT AD Plat Rows Media"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TableIdByName(TableName: Text): Integer
    var
        AllObj: Record AllObj;
    begin
        if TableName = 'MediaResources' then
            exit(2000000182);
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object Name", TableName);
        if AllObj.FindFirst() then
            exit(AllObj."Object ID");
        exit(-1);
    end;

    local procedure RowText(var RR: RecordRef; MaxField: Integer): Text
    var
        FR: FieldRef;
        i: Integer;
        Result: Text;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if (FR.Class() = FieldClass::Normal) and ((MaxField = 0) or (FR.Number() <= MaxField)) then
                if FR.Type() in [FieldType::Blob, FieldType::Media, FieldType::MediaSet] then
                    Result += FR.Name() + '=<' + Format(FR.Type()) + '>|'
                else
                    Result += FR.Name() + '=' + Format(FR.Value()) + '|';
        end;
        exit(Result);
    end;

    local procedure KeyText(var RR: RecordRef; KeyField: Text): Text
    var
        FR: FieldRef;
        i: Integer;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if FR.Name() = KeyField then
                exit(Format(FR.Value()));
        end;
    end;

    // Rows are named by the value of KeyField (not by position), because the rows of a platform table differ between BC versions.
    local procedure Dump(var Observer: Codeunit "Probe Observer"; TableName: Text; KeyField: Text; MaxField: Integer; Skip: Integer; Take: Integer)
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
                    Observer.Observe(TableName + ' row ' + KeyText(RR, KeyField), RowText(RR, MaxField));
            until (RR.Next() = 0) or (n >= Skip + Take);
    end;

    [Test]
    procedure Rows_MediaResources_01()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'MediaResources', 'Code', 0, 0, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_MediaResources_02()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'MediaResources', 'Code', 0, 12, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_MediaResources_03()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'MediaResources', 'Code', 0, 24, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_MediaResources_04()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'MediaResources', 'Code', 0, 36, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Count_MediaResources()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Id: Integer;
    begin
        Id := TableIdByName('MediaResources');
        Observer.Observe('id', Format(Id));
        RR.Open(Id);
        Observer.Observe('count', Format(RR.Count()));
        Observer.Finish();
    end;
}
