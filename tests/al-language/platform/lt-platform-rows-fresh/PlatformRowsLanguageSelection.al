// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-class
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: the count and every row, in 18 tests of 12 rows each,, with every column, of the platform table Language Selection on the fresh tenant of a test container (read through RecordRef by table name).
// First rows of the platform tables are also pinned in platform/lt-platform-tables/PtCloudTables.al. Object id 78100.

codeunit 78100 "LT AD Plat Rows Language"
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
    procedure Rows_LanguageSelection_01()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 0, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_02()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 12, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_03()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 24, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_04()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 36, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_05()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 48, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_06()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 60, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_07()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 72, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_08()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 84, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_09()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 96, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_10()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 108, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_11()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 120, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_12()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 132, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_13()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 144, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_14()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 156, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_15()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 168, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_16()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 180, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_17()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 192, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_18()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 204, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Count_LanguageSelection()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Id: Integer;
    begin
        Id := TableIdByName('Language Selection');
        Observer.Observe('id', Format(Id));
        RR.Open(Id);
        Observer.Observe('count', Format(RR.Count()));
        Observer.Finish();
    end;
}
