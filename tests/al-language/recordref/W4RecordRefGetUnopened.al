// Probe (observe only): RecordRef.Get(RecordId) on a RecordRef that was never opened (Data Type Management does `if not RecRef.Get(RecID) then RecRef.Open(RecID.TableNo)`).
// Settles docs/probes-needed.md row 977 (batch 4). Object ids 68074 - 68075.

table 68074 "W4 RecRef Get Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Info; Text[20]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 68075 "W4 RecRef Get Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "W4 RecRef Get Row";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Info := 'one';
        R.Insert();
    end;

    local procedure IdOf(Id: Integer): RecordId
    var
        R: Record "W4 RecRef Get Row";
    begin
        R.Id := Id;
        exit(R.RecordId());
    end;

    [TryFunction]
    local procedure TryGet(var RR: RecordRef; Id: RecordId; var Found: Boolean)
    begin
        Found := RR.Get(Id);
    end;

    [TryFunction]
    local procedure TryGetOrOpen(var RR: RecordRef; Id: RecordId)
    begin
        if not RR.Get(Id) then
            RR.Open(Id.TableNo());
    end;

    local procedure Outcome(Ok: Boolean; Found: Boolean): Text
    begin
        if Ok then
            exit('ok found=' + Format(Found));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Get_OnUnopenedRecordRef_ExistingRow()
    var
        RR: RecordRef;
        Found: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('get', Outcome(TryGet(RR, IdOf(1), Found), Found));
        ClearLastError();
        Observer.Observe('number_after', Format(RR.Number()));
        Observer.Observe('isopen_proxy_name', RR.Name());
        Observer.Expect('get', 'ok found=Yes');
        Observer.Expect('number_after', '68074');
        Observer.Expect('isopen_proxy_name', 'W4 RecRef Get Row');
        Observer.Verify();
    end;

    [Test]
    procedure Get_OnUnopenedRecordRef_MissingRow()
    var
        RR: RecordRef;
        Found: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('get', Outcome(TryGet(RR, IdOf(99), Found), Found));
        ClearLastError();
        Observer.Observe('number_after', Format(RR.Number()));
        Observer.Expect('get', 'ok found=No');
        Observer.Expect('number_after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure GetOrOpen_Pattern_OfDataTypeManagement()
    var
        RR: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        if TryGetOrOpen(RR, IdOf(99)) then
            Observer.Observe('missing_row', 'ok number=' + Format(RR.Number()) + ' name=' + RR.Name())
        else begin
            Observer.Observe('missing_row', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
        Clear(RR);
        if TryGetOrOpen(RR, IdOf(1)) then
            Observer.Observe('existing_row', 'ok number=' + Format(RR.Number()) + ' info=' + Format(RR.FieldExist(2)))
        else begin
            Observer.Observe('existing_row', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
        Observer.Expect('missing_row', 'ok number=68074 name=W4 RecRef Get Row');
        Observer.Expect('existing_row', 'ok number=68074 info=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Get_AfterOpen_ForComparison()
    var
        RR: RecordRef;
        Found: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        RR.Open(Database::"W4 RecRef Get Row");
        Observer.Observe('existing', Outcome(TryGet(RR, IdOf(1), Found), Found));
        ClearLastError();
        Observer.Observe('info_after_existing', Format(RR.Field(2).Value()));
        Observer.Observe('missing', Outcome(TryGet(RR, IdOf(99), Found), Found));
        ClearLastError();
        Observer.Expect('existing', 'ok found=Yes');
        Observer.Expect('info_after_existing', 'one');
        Observer.Expect('missing', 'ok found=No');
        Observer.Verify();
    end;
}
