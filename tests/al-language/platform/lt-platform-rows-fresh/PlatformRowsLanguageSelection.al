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
    procedure Rows_LanguageSelection_01()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 'Language Tag', 0, 0, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_02()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 'Language Tag', 0, 12, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_03()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 'Language Tag', 0, 24, 6);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_03b()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 'Language Tag', 0, 30, 6);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_04()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 'Language Tag', 0, 36, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_05()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 'Language Tag', 0, 48, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_06()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 'Language Tag', 0, 60, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_07()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 'Language Tag', 0, 72, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_08()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 'Language Tag', 0, 84, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_09()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 'Language Tag', 0, 96, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_10()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 'Language Tag', 0, 108, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_11()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 'Language Tag', 0, 120, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_12()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 'Language Tag', 0, 132, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_13()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 'Language Tag', 0, 144, 6);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_13b()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 'Language Tag', 0, 150, 6);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_14()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 'Language Tag', 0, 156, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_15()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 'Language Tag', 0, 168, 6);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_15b()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 'Language Tag', 0, 174, 6);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_16()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 'Language Tag', 0, 180, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_17()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 'Language Tag', 0, 192, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_18()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 'Language Tag', 0, 204, 12);
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
        Observer.Expect('id', '2000000050');
        Observer.Expect('count', '212');
        Observer.Verify();
    end;
}
