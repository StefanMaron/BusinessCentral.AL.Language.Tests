// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope; platform tables opened by RecordRef in a Cloud app.
// Fixtures used: Probe Observer (69160); own codeunit 67514
// Probe: the rows and the columns of NAV App Setting (2000000201), Web Service (2000000076) and Tenant Web Service (2000000168) in a fresh tenant (issue 580 items 3 and 7).
// BC versions: 27+

codeunit 67514 "LT PT Services Content"
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
        Value: Text;
    begin
        for Index := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(Index);
            case FR.Type of
                FieldType::Blob, FieldType::Media, FieldType::MediaSet:
                    Value := '<' + Format(FR.Type) + '>';
                else
                    Value := Format(FR.Value);
            end;
            Result += Format(FR.Number) + '=' + Value + ';';
        end;
        exit(Result);
    end;

    local procedure Content(var Observer: Codeunit "Probe Observer"; TableNo: Integer)
    var
        RR: RecordRef;
        Index: Integer;
    begin
        RR.Open(TableNo);
        Observer.Observe('columns', Columns(RR));
        Observer.Observe('count', Format(RR.Count()));
        if RR.FindSet() then
            repeat
                Index += 1;
                if Index <= 40 then
                    Observer.Observe('row' + Format(Index), Row(RR));
            until RR.Next() = 0;
    end;

    [Test]
    procedure NavAppSetting_Content()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Content(Observer, 2000000201);
        Observer.Finish();
    end;

    [Test]
    procedure WebService_Content()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Content(Observer, 2000000076);
        Observer.Finish();
    end;

    [Test]
    procedure TenantWebService_Content()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Content(Observer, 2000000168);
        Observer.Finish();
    end;
}
