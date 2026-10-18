// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: OnPrem app only: the Web Service table (2000000076) has Scope = OnPrem, so a RecordRef from a Target = Cloud app cannot open it.
// Fixtures used: Probe Observer (69160)
// Probe: the columns and the rows of the Web Service table in a fresh tenant (issue 580 item 7). Object id 61281.

codeunit 61281 "LT PT Web Service Rows"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Columns(var RR: RecordRef): Text
    var
        FR: FieldRef;
        Index: Integer;
        Result: Text;
    begin
        for Index := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(Index);
            Result += Format(FR.Number) + ':' + FR.Name + ':' + Format(FR.Type) + ':' + Format(FR.Length) + ':' + Format(FR.Class) + ';';
        end;
        exit(Result);
    end;

    local procedure Row(var RR: RecordRef): Text
    var
        FR: FieldRef;
        Index: Integer;
        Result: Text;
    begin
        for Index := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(Index);
            Result += Format(FR.Number) + '=' + Format(FR.Value) + ';';
        end;
        exit(Result);
    end;

    [Test]
    procedure WebService_Content()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Index: Integer;
    begin
        RR.Open(2000000076);
        Observer.Observe('columns', Columns(RR));
        Observer.Observe('count', Format(RR.Count()));
        if RR.FindSet() then
            repeat
                Index += 1;
                Observer.Observe('row' + Format(Index), Row(RR));
            until RR.Next() = 0;
        Observer.Finish();
    end;

    [Test]
    procedure WebService_Content_More1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;

    [Test]
    procedure WebService_Content_More2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;

    [Test]
    procedure WebService_Content_More3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;

    [Test]
    procedure WebService_Content_More4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;

    [Test]
    procedure WebService_Content_More5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;
}
