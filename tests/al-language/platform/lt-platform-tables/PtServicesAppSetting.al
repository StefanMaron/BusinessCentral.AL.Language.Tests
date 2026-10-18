// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope; platform tables opened by RecordRef or by record variable in a Cloud app.
// Fixtures used: Probe Observer (69160), LT PT Ops and LT PT Arg (PtHelper.al); own codeunits 67514 and 67517. The Web Service table (2000000076) is Scope = OnPrem and is probed in tests/al-language-onprem/platform/PtWebServiceRows.al.
// Probe: the columns and rows of NAV App Setting (2000000201) and Tenant Web Service (2000000168) in a fresh tenant, and Insert, Modify, Delete and a get-or-insert pattern on NAV App Setting from an extension (issue 580 items 3 and 7).
// BC versions: 27+

codeunit 67514 "LT PT Services Content"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Ops: Codeunit "LT PT Ops";

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
                Observer.Observe('row' + Format(Index), Row(RR));
            until RR.Next() = 0;
    end;

    local procedure Standard(var Observer: Codeunit "Probe Observer"; TableNo: Integer; InsertRequest: Text; FilterRequest: Text; ChangeRequest: Text)
    begin
        Observer.Observe('insert', Ops.Perform(TableNo, 'insert', InsertRequest, true));
        Observer.Observe('find_inserted', Ops.Perform(TableNo, 'find', FilterRequest, false));
        Observer.Observe('count_inserted', Ops.Perform(TableNo, 'count', FilterRequest, false));
        Observer.Observe('insert_duplicate', Ops.Perform(TableNo, 'insert', InsertRequest, true));
        Observer.Observe('modify', Ops.Perform(TableNo, 'modify', FilterRequest + '|' + ChangeRequest, true));
        Observer.Observe('find_modified', Ops.Perform(TableNo, 'find', FilterRequest, false));
        Observer.Observe('delete', Ops.Perform(TableNo, 'delete', FilterRequest, true));
        Observer.Observe('count_deleted', Ops.Perform(TableNo, 'count', FilterRequest, false));
        Observer.Observe('insert_no_triggers', Ops.Perform(TableNo, 'insert', InsertRequest, false));
        Observer.Observe('modify_no_triggers', Ops.Perform(TableNo, 'modify', FilterRequest + '|' + ChangeRequest, false));
        Observer.Observe('delete_all_no_triggers', Ops.Perform(TableNo, 'deleteall', FilterRequest, false));
        Observer.Observe('count_after_delete_all', Ops.Perform(TableNo, 'count', FilterRequest, false));
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
    procedure NavAppSetting_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Standard(Observer, 2000000201, '1=11111111-2222-3333-4444-555555555555;2=true', '1=11111111-2222-3333-4444-555555555555', '2=false');
        Observer.Finish();
    end;

    [Test]
    procedure NavAppSetting_SeveralRowsAndBlankGuid()
    var
        Observer: Codeunit "Probe Observer";
        T: Integer;
    begin
        T := 2000000201;
        Observer.Observe('insert_one', Ops.Perform(T, 'insert', '1=11111111-2222-3333-4444-555555555551;2=true', true));
        Observer.Observe('insert_two', Ops.Perform(T, 'insert', '1=11111111-2222-3333-4444-555555555552;2=true', true));
        Observer.Observe('count_both', Ops.Perform(T, 'count', '2=true', false));
        Observer.Observe('insert_blank_guid', Ops.Perform(T, 'insert', '1=00000000-0000-0000-0000-000000000000;2=true', true));
        Observer.Observe('count_after_blank_guid', Ops.Perform(T, 'count', '', false));
        Observer.Finish();
    end;

    [Test]
    procedure NavAppSetting_GetOrInsert()
    var
        Observer: Codeunit "Probe Observer";
        Arg: Record "LT PT Arg" temporary;
    begin
        Arg.Init();
        Arg.Id := 1;
        Arg.Insert();
        Observer.Observe('first_call', RunText(Arg));
        Observer.Observe('second_call', RunText(Arg));
        Observer.Finish();
    end;

    local procedure RunText(var Arg: Record "LT PT Arg" temporary): Text
    begin
        ClearLastError();
        if not Codeunit.Run(Codeunit::"LT PT Nas Runner", Arg) then
            exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        exit('ok:' + Arg.Result);
    end;

    [Test]
    procedure TenantWebService_Content()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Content(Observer, 2000000168);
        Observer.Finish();
    end;

    [Test]
    procedure TenantWebService_Content_More1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;

    [Test]
    procedure TenantWebService_Content_More2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;

    [Test]
    procedure TenantWebService_Content_More3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;

    [Test]
    procedure TenantWebService_Content_More4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;

    [Test]
    procedure TenantWebService_Content_More5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;
}

// Get-or-insert on NAV App Setting through the typed record: Get by the app id, insert when it is missing, then read the row back. Not a test codeunit.
codeunit 67517 "LT PT Nas Runner"
{
    TableNo = "LT PT Arg";

    trigger OnRun()
    var
        Setting: Record "NAV App Setting";
        AppId: Guid;
        Existed: Boolean;
    begin
        Evaluate(AppId, '11111111-2222-3333-4444-555555555556');
        Existed := Setting.Get(AppId);
        if not Existed then begin
            Setting.Init();
            Setting."App ID" := AppId;
            Setting."Allow HttpClient Requests" := true;
            Setting.Insert(true);
        end;
        Setting.Get(AppId);
        Rec.Result := 'existed=' + Format(Existed) + ' allow=' + Format(Setting."Allow HttpClient Requests") + ' count=' + Format(Setting.Count());
    end;
}
