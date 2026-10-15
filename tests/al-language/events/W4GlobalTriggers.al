// Probe (observe only): Codeunit "Global Triggers" mask bits, setup events that write the table they are asked about, DeleteAll(false) and Truncate with OnDatabaseDelete enabled.
// Settles docs/probes-needed.md rows 66, 67, 73 (batch 4).
// Object ids 68028 - 68039. The subscribers are StaticAutomatic but react to W4 tables only.

table 68028 "W4 GT Mask0"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Info; Text[20]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 68029 "W4 GT Mask1"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Info; Text[20]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 68030 "W4 GT Mask2"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Info; Text[20]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 68031 "W4 GT Mask4"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Info; Text[20]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 68032 "W4 GT Mask8"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Info; Text[20]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 68033 "W4 GT Mask16"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Info; Text[20]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

// The mask subscriber of this table writes a row of the table while it is asked.
table 68034 "W4 GT Writer Mask"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Info; Text[20]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

// The setup subscriber (GetDatabaseTableTriggerSetup) of this table writes a row of the table while it is asked.
table 68035 "W4 GT Writer Setup"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Info; Text[20]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

// Mask 15 and OnDatabaseDelete enabled.
table 68036 "W4 GT Del"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Info; Text[20]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 68037 "W4 GT Log"
{
    SingleInstance = true;

    var
        Text: Text;
        Busy: Boolean;

    procedure Add(Line: Text)
    begin
        Text += Line + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Text;
        Text := '';
    end;

    procedure IsBusy(): Boolean
    begin
        exit(Busy);
    end;

    procedure SetBusy(NewBusy: Boolean)
    begin
        Busy := NewBusy;
    end;
}

codeunit 68038 "W4 GT Subs"
{
    var
        Log: Codeunit "W4 GT Log";

    local procedure Tag(TableId: Integer): Text
    begin
        case TableId of
            Database::"W4 GT Mask0":
                exit('m0');
            Database::"W4 GT Mask1":
                exit('m1');
            Database::"W4 GT Mask2":
                exit('m2');
            Database::"W4 GT Mask4":
                exit('m4');
            Database::"W4 GT Mask8":
                exit('m8');
            Database::"W4 GT Mask16":
                exit('m16');
            Database::"W4 GT Writer Mask":
                exit('wm');
            Database::"W4 GT Writer Setup":
                exit('ws');
            Database::"W4 GT Del":
                exit('del');
        end;
        exit('');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetGlobalTableTriggerMask', '', false, false)]
    local procedure OnGetMask(TableId: Integer; var TableTriggerMask: Integer)
    var
        Nested: Record "W4 GT Writer Mask";
    begin
        case TableId of
            Database::"W4 GT Mask0":
                TableTriggerMask := 0;
            Database::"W4 GT Mask1":
                TableTriggerMask := 1;
            Database::"W4 GT Mask2":
                TableTriggerMask := 2;
            Database::"W4 GT Mask4":
                TableTriggerMask := 4;
            Database::"W4 GT Mask8":
                TableTriggerMask := 8;
            Database::"W4 GT Mask16":
                TableTriggerMask := 16;
            Database::"W4 GT Writer Setup", Database::"W4 GT Del":
                TableTriggerMask := 15;
            Database::"W4 GT Writer Mask":
                begin
                    Log.Add('mask(wm)');
                    if not Log.IsBusy() then begin
                        Log.SetBusy(true);
                        Nested.Id := 99;
                        Nested.Info := 'nested';
                        Nested.Insert(true);
                        Log.SetBusy(false);
                    end;
                    TableTriggerMask := 15;
                    exit;
                end;
            else
                exit;
        end;
        Log.Add('mask(' + Tag(TableId) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetDatabaseTableTriggerSetup', '', false, false)]
    local procedure OnGetSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        Nested: Record "W4 GT Writer Setup";
    begin
        case TableId of
            Database::"W4 GT Del":
                begin
                    OnDatabaseInsert := true;
                    OnDatabaseModify := true;
                    OnDatabaseDelete := true;
                    OnDatabaseRename := true;
                    Log.Add('setup(del)');
                end;
            Database::"W4 GT Writer Setup":
                begin
                    Log.Add('setup(ws)');
                    if not Log.IsBusy() then begin
                        Log.SetBusy(true);
                        Nested.Id := 99;
                        Nested.Info := 'nested';
                        Nested.Insert(true);
                        Log.SetBusy(false);
                    end;
                    OnDatabaseInsert := true;
                    OnDatabaseModify := true;
                    OnDatabaseDelete := true;
                    OnDatabaseRename := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalInsert', '', false, false)]
    local procedure OnGlobalInsert(RecRef: RecordRef)
    begin
        if Tag(RecRef.Number()) <> '' then
            Log.Add('gI(' + Tag(RecRef.Number()) + ' ' + Format(RecRef.Field(1).Value()) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalModify', '', false, false)]
    local procedure OnGlobalModify(RecRef: RecordRef; xRecRef: RecordRef)
    begin
        if Tag(RecRef.Number()) <> '' then
            Log.Add('gM(' + Tag(RecRef.Number()) + ' ' + Format(RecRef.Field(1).Value()) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalDelete', '', false, false)]
    local procedure OnGlobalDelete(RecRef: RecordRef)
    begin
        if Tag(RecRef.Number()) <> '' then
            Log.Add('gD(' + Tag(RecRef.Number()) + ' ' + Format(RecRef.Field(1).Value()) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalRename', '', false, false)]
    local procedure OnGlobalRename(RecRef: RecordRef; xRecRef: RecordRef)
    begin
        if Tag(RecRef.Number()) <> '' then
            Log.Add('gR(' + Tag(RecRef.Number()) + ' ' + Format(xRecRef.Field(1).Value()) + '>' + Format(RecRef.Field(1).Value()) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseInsert', '', false, false)]
    local procedure OnDatabaseInsert(RecRef: RecordRef)
    begin
        if Tag(RecRef.Number()) <> '' then
            Log.Add('dI(' + Tag(RecRef.Number()) + ' ' + Format(RecRef.Field(1).Value()) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseModify', '', false, false)]
    local procedure OnDatabaseModify(RecRef: RecordRef)
    begin
        if Tag(RecRef.Number()) <> '' then
            Log.Add('dM(' + Tag(RecRef.Number()) + ' ' + Format(RecRef.Field(1).Value()) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseDelete', '', false, false)]
    local procedure OnDatabaseDelete(RecRef: RecordRef)
    begin
        if Tag(RecRef.Number()) <> '' then
            Log.Add('dD(' + Tag(RecRef.Number()) + ' ' + Format(RecRef.Field(1).Value()) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseRename', '', false, false)]
    local procedure OnDatabaseRename(RecRef: RecordRef; xRecRef: RecordRef)
    begin
        if Tag(RecRef.Number()) <> '' then
            Log.Add('dR(' + Tag(RecRef.Number()) + ' ' + Format(xRecRef.Field(1).Value()) + '>' + Format(RecRef.Field(1).Value()) + ')');
    end;
}

// md:66 - which bit of the mask enables which OnGlobal event.
codeunit 68039 "W4 GT Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "W4 GT Log";

    local procedure Exercise(TableNo: Integer): Text
    var
        RR: RecordRef;
    begin
        RR.Open(TableNo);
        RR.DeleteAll();
        RR.Init();
        RR.Field(1).Value := 1;
        RR.Field(2).Value := 'a';
        RR.Insert(true);
        RR.Field(2).Value := 'b';
        RR.Modify(true);
        RR.Rename(2);
        RR.Delete(true);
        exit(Log.Take());
    end;

    [Test]
    procedure GlobalMask_Zero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('events_mask_0', Exercise(Database::"W4 GT Mask0"));
        Observer.Expect('events_mask_0', 'mask(m0);dI(m0 1);dM(m0 1);dR(m0 1>2);dD(m0 2);');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalMask_One()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('events_mask_1', Exercise(Database::"W4 GT Mask1"));
        Observer.Expect('events_mask_1', 'mask(m1);dI(m1 1);dM(m1 1);dR(m1 1>2);dD(m1 2);');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalMask_Two()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('events_mask_2', Exercise(Database::"W4 GT Mask2"));
        Observer.Expect('events_mask_2', 'mask(m2);dI(m2 1);dM(m2 1);dR(m2 1>2);dD(m2 2);');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalMask_Four()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('events_mask_4', Exercise(Database::"W4 GT Mask4"));
        Observer.Expect('events_mask_4', 'mask(m4);dI(m4 1);dM(m4 1);dR(m4 1>2);dD(m4 2);');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalMask_Eight()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('events_mask_8', Exercise(Database::"W4 GT Mask8"));
        Observer.Expect('events_mask_8', 'mask(m8);dI(m8 1);dM(m8 1);gR(m8 1>2);dR(m8 1>2);dD(m8 2);');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalMask_Sixteen()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('events_mask_16', Exercise(Database::"W4 GT Mask16"));
        Observer.Expect('events_mask_16', 'mask(m16);dI(m16 1);dM(m16 1);dR(m16 1>2);dD(m16 2);');
        Observer.Verify();
    end;

    [Test]
    procedure MaskSubscriberWritesTheAskedTable()
    var
        R: Record "W4 GT Writer Mask";
        Observer: Codeunit "Probe Observer";
    begin
        R.DeleteAll();
        Observer.Observe('log_after_first_deleteall', Log.Take());
        Observer.Observe('count_after_first_deleteall', Format(R.Count()));
        R.Id := 1;
        R.Info := 'a';
        R.Insert(true);
        Observer.Observe('log_after_insert', Log.Take());
        Observer.Observe('count_after_insert', Format(R.Count()));
        R.Info := 'b';
        R.Modify(true);
        Observer.Observe('log_after_modify', Log.Take());
        R.DeleteAll();
        Observer.Observe('log_after_second_deleteall', Log.Take());
        Observer.Observe('count_after_second_deleteall', Format(R.Count()));
        Observer.Expect('log_after_first_deleteall', 'mask(wm);dD(wm 99);');
        Observer.Expect('count_after_first_deleteall', '0');
        Observer.Expect('log_after_insert', 'dI(wm 1);');
        Observer.Expect('count_after_insert', '1');
        Observer.Expect('log_after_modify', 'dM(wm 1);');
        Observer.Expect('log_after_second_deleteall', 'dD(wm 1);');
        Observer.Expect('count_after_second_deleteall', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetupSubscriberWritesTheAskedTable()
    var
        R: Record "W4 GT Writer Setup";
        Observer: Codeunit "Probe Observer";
    begin
        R.DeleteAll();
        Observer.Observe('log_after_first_deleteall', Log.Take());
        Observer.Observe('count_after_first_deleteall', Format(R.Count()));
        R.Id := 1;
        R.Info := 'a';
        R.Insert(true);
        Observer.Observe('log_after_insert', Log.Take());
        Observer.Observe('count_after_insert', Format(R.Count()));
        R.Info := 'b';
        R.Modify(true);
        Observer.Observe('log_after_modify', Log.Take());
        R.DeleteAll(true);
        Observer.Observe('log_after_second_deleteall', Log.Take());
        Observer.Observe('count_after_second_deleteall', Format(R.Count()));
        Observer.Expect('log_after_first_deleteall', 'mask(ws);setup(ws);dD(ws 99);');
        Observer.Expect('count_after_first_deleteall', '0');
        Observer.Expect('log_after_insert', 'dI(ws 1);');
        Observer.Expect('count_after_insert', '1');
        Observer.Expect('log_after_modify', 'dM(ws 1);');
        Observer.Expect('log_after_second_deleteall', 'dD(ws 1);');
        Observer.Expect('count_after_second_deleteall', '0');
        Observer.Verify();
    end;

    local procedure Seed(var R: Record "W4 GT Del")
    var
        i: Integer;
    begin
        R.Reset();
        R.DeleteAll();
        for i := 1 to 3 do begin
            R.Id := i;
            R.Info := 'row';
            R.Insert(true);
        end;
        Log.Take();
    end;

    [Test]
    procedure DeleteAllFalse_WithDatabaseDeleteEnabled()
    var
        R: Record "W4 GT Del";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(R);
        R.DeleteAll(false);
        Observer.Observe('log_deleteall_false', Log.Take());
        Observer.Observe('count_after', Format(R.Count()));
        Observer.Expect('log_deleteall_false', 'dD(del 1);dD(del 2);dD(del 3);');
        Observer.Expect('count_after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAllTrue_WithDatabaseDeleteEnabled()
    var
        R: Record "W4 GT Del";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(R);
        R.DeleteAll(true);
        Observer.Observe('log_deleteall_true', Log.Take());
        Observer.Observe('count_after', Format(R.Count()));
        Observer.Expect('log_deleteall_true', 'dD(del 1);dD(del 2);dD(del 3);');
        Observer.Expect('count_after', '0');
        Observer.Verify();
    end;

    // Truncate may raise on BC: no asserterror, the failure text is then the finding.
    [Test]
    procedure Truncate_WithDatabaseDeleteEnabled()
    var
        R: Record "W4 GT Del";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(R);
        R.Truncate();
        Observer.Observe('log_truncate', Log.Take());
        Observer.Observe('count_after', Format(R.Count()));
        Observer.Expect('log_truncate', '');
        Observer.Expect('count_after', '0');
        Observer.Verify();
    end;
}
