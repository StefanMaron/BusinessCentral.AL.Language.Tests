// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-overview
// Scope: in-scope (Cloud-compatible)
// Fixtures used: Storage Write Probe (67815), Storage Write Recorder (67816) -- declared below. Deliberately NOT the
// xRec Stamp fixtures of codeunit 67812: a SingleInstance fixture shared between two test codeunits is refused by
// the repo's own guard (issue #261).
// BC versions: 27.0+
//
// WHAT THIS PINS. TestXRecStampFields (67812) pins, for a code-driven Insert(true) / Modify(true), that the
// AutoIncrement key and the Created/Modified stamps are written BELOW the table trigger: inside OnInsert
// Rec."Entry No." is 0 and the stamps are default, inside OnModify Rec.SystemModifiedAt is still the stored value.
// This codeunit asks the same question of the OTHER routes that reach the same data layer, and of the integration
// events around the trigger:
//   - the OnBeforeInsertEvent / OnAfterInsertEvent / OnBeforeModifyEvent / OnAfterModifyEvent subscribers
//     (before the trigger: nothing written; after the storage write: the key and the stamps are there),
//   - Insert(false), which runs no trigger but still writes the key and the stamps,
//   - RecordRef.Insert(true),
//   - ModifyAll(Field, Value, true), whose per-row OnModify must see the stored SystemModifiedAt.
//
// Written for StefanMaron/BusinessCentral.AL.Runner#5509. All DateTime/Guid comparisons go through
// Format(_, 0, 9): Assert compares DateTimes at minute resolution (AlRunner#4439).

table 67815 "Storage Write Probe"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; Payload; Text[30])
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        Capture('OnInsert');
    end;

    trigger OnModify()
    begin
        Capture('OnModify');
    end;

    local procedure Capture(TriggerName: Text)
    var
        Recorder: Codeunit "Storage Write Recorder";
    begin
        Recorder.Put(TriggerName, 'Rec.EntryNo', Format(Rec."Entry No.", 0, 9));
        Recorder.Put(TriggerName, 'Rec.SystemCreatedAt', Format(Rec.SystemCreatedAt, 0, 9));
        Recorder.Put(TriggerName, 'Rec.SystemModifiedAt', Format(Rec.SystemModifiedAt, 0, 9));
        Recorder.Put(TriggerName, 'Rec.SystemCreatedBy', Format(Rec.SystemCreatedBy, 0, 9));
        Recorder.Put(TriggerName, 'Rec.Payload', Rec.Payload);
    end;
}

// SingleInstance so what a trigger or subscriber saw survives the call that ran it.
codeunit 67816 "Storage Write Recorder"
{
    SingleInstance = true;

    var
        Seen: Dictionary of [Text, Text];

    procedure Wipe()
    begin
        Clear(Seen);
    end;

    procedure Put(TriggerName: Text; What: Text; Value: Text)
    begin
        Seen.Set(TriggerName + '|' + What, Value);
    end;

    procedure Read(TriggerName: Text; What: Text): Text
    begin
        exit(Seen.Get(TriggerName + '|' + What));
    end;
}

codeunit 67813 "Test Storage Write Routes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Recorder: Codeunit "Storage Write Recorder";
        NullGuidTxt: Label '{00000000-0000-0000-0000-000000000000}', Locked = true;

    [Test]
    procedure StorageWrite_InsertTrue_BeforeEventSeesNothingWritten_AfterEventSeesTheWrite()
    // CLAIM: OnBeforeInsertEvent runs before the trigger, so key and stamps are not written yet; OnAfterInsertEvent
    //        runs after the storage write, so it sees the assigned key and both Created/Modified stamps.
    var
        Subscriber: Codeunit "Storage Write Subscriber";
        P: Record "Storage Write Probe";
    begin
        Initialize();
        BindSubscription(Subscriber);

        P.Payload := 'one';
        P.Insert(true);

        Assert.AreEqual('0', Recorder.Read('EvBeforeInsert', 'Rec.EntryNo'), 'Rec."Entry No." in OnBeforeInsertEvent must still be 0');
        Assert.AreEqual('', Recorder.Read('EvBeforeInsert', 'Rec.SystemCreatedAt'), 'Rec.SystemCreatedAt in OnBeforeInsertEvent must still be the default DateTime');
        Assert.AreEqual('', Recorder.Read('EvBeforeInsert', 'Rec.SystemModifiedAt'), 'Rec.SystemModifiedAt in OnBeforeInsertEvent must still be the default DateTime');

        Assert.AreNotEqual(0, P."Entry No.", 'control: after Insert the key must be assigned');
        Assert.AreEqual(Format(P."Entry No.", 0, 9), Recorder.Read('EvAfterInsert', 'Rec.EntryNo'), 'Rec."Entry No." in OnAfterInsertEvent must be the assigned key');
        Assert.AreNotEqual('', Recorder.Read('EvAfterInsert', 'Rec.SystemCreatedAt'), 'Rec.SystemCreatedAt in OnAfterInsertEvent must be stamped');
        Assert.AreEqual(Format(P.SystemCreatedAt, 0, 9), Recorder.Read('EvAfterInsert', 'Rec.SystemCreatedAt'), 'OnAfterInsertEvent must see the stamp that ends up on the record');
        Assert.AreEqual(Format(P.SystemModifiedAt, 0, 9), Recorder.Read('EvAfterInsert', 'Rec.SystemModifiedAt'), 'OnAfterInsertEvent must see the SystemModifiedAt that ends up on the record');
        UnbindSubscription(Subscriber);
    end;

    [Test]
    procedure StorageWrite_InsertFalse_RunsNoTrigger_ButStillWritesKeyAndStamps()
    // CLAIM: Insert(false) skips OnInsert but the storage layer still assigns the AutoIncrement key and stamps the
    //        record; the event subscribers still see "nothing written" before and "written" after.
    var
        Subscriber: Codeunit "Storage Write Subscriber";
        P: Record "Storage Write Probe";
    begin
        Initialize();
        BindSubscription(Subscriber);

        P.Payload := 'one';
        P.Insert(false);

        Assert.AreNotEqual(0, P."Entry No.", 'Insert(false) must still assign the AutoIncrement key');
        Assert.AreNotEqual('', Format(P.SystemCreatedAt, 0, 9), 'Insert(false) must still stamp SystemCreatedAt');
        Assert.AreNotEqual(NullGuidTxt, Format(P.SystemCreatedBy, 0, 9), 'Insert(false) must still stamp SystemCreatedBy');

        Assert.AreEqual('0', Recorder.Read('EvBeforeInsert', 'Rec.EntryNo'), 'Rec."Entry No." in OnBeforeInsertEvent must still be 0 for Insert(false)');
        Assert.AreEqual('', Recorder.Read('EvBeforeInsert', 'Rec.SystemCreatedAt'), 'Rec.SystemCreatedAt in OnBeforeInsertEvent must still be default for Insert(false)');
        Assert.AreEqual(Format(P."Entry No.", 0, 9), Recorder.Read('EvAfterInsert', 'Rec.EntryNo'), 'Rec."Entry No." in OnAfterInsertEvent must be the assigned key for Insert(false)');
        UnbindSubscription(Subscriber);
    end;

    [Test]
    procedure StorageWrite_RecordRefInsertTrue_TriggerSeesNothingWritten()
    // CLAIM: RecordRef.Insert(true) reaches the same table trigger with the same before-write state: key 0 and
    //        default stamps inside OnInsert; both are present on the record once Insert has returned.
    var
        RR: RecordRef;
        P: Record "Storage Write Probe";
        AssignedKey: Integer;
    begin
        Initialize();

        RR.Open(Database::"Storage Write Probe");
        RR.Field(P.FieldNo(Payload)).Value := 'one';
        RR.Insert(true);
        AssignedKey := RR.Field(P.FieldNo("Entry No.")).Value;

        Assert.AreEqual('0', Recorder.Read('OnInsert', 'Rec.EntryNo'), 'Rec."Entry No." in OnInsert via RecordRef must still be 0');
        Assert.AreEqual('', Recorder.Read('OnInsert', 'Rec.SystemCreatedAt'), 'Rec.SystemCreatedAt in OnInsert via RecordRef must still be the default DateTime');
        Assert.AreEqual('', Recorder.Read('OnInsert', 'Rec.SystemModifiedAt'), 'Rec.SystemModifiedAt in OnInsert via RecordRef must still be the default DateTime');
        Assert.AreEqual(NullGuidTxt, Recorder.Read('OnInsert', 'Rec.SystemCreatedBy'), 'Rec.SystemCreatedBy in OnInsert via RecordRef must still be the null guid');

        Assert.AreNotEqual(0, AssignedKey, 'control: after RecordRef.Insert the key must be assigned');
        Assert.IsTrue(P.Get(AssignedKey), 'control: the row must be stored under the assigned key');
        Assert.AreNotEqual('', Format(P.SystemCreatedAt, 0, 9), 'control: the stored row must carry a SystemCreatedAt');
    end;

    [Test]
    procedure StorageWrite_Modify_BeforeEventSeesStoredStamp_AfterEventSeesTheNewOne()
    // CLAIM: OnBeforeModifyEvent runs before the trigger and the storage write, so Rec.SystemModifiedAt is still the
    //        stored value; OnAfterModifyEvent runs after the storage write, so it sees the new stamp.
    var
        Subscriber: Codeunit "Storage Write Subscriber";
        P: Record "Storage Write Probe";
        StoredModifiedAt: Text;
    begin
        Initialize();
        P.Payload := 'one';
        P.Insert(false);
        P.Get(P."Entry No.");
        StoredModifiedAt := Format(P.SystemModifiedAt, 0, 9);
        Assert.AreNotEqual('', StoredModifiedAt, 'control: the stored row must carry a SystemModifiedAt');
        Sleep(50);
        Recorder.Wipe();
        BindSubscription(Subscriber);

        P.Payload := 'two';
        P.Modify(true);

        Assert.AreEqual(StoredModifiedAt, Recorder.Read('EvBeforeModify', 'Rec.SystemModifiedAt'), 'Rec.SystemModifiedAt in OnBeforeModifyEvent must still be the stored value');
        Assert.AreNotEqual(StoredModifiedAt, Format(P.SystemModifiedAt, 0, 9), 'control: after Modify the record must carry a newer SystemModifiedAt');
        Assert.AreEqual(Format(P.SystemModifiedAt, 0, 9), Recorder.Read('EvAfterModify', 'Rec.SystemModifiedAt'), 'Rec.SystemModifiedAt in OnAfterModifyEvent must be the new stamp');
        UnbindSubscription(Subscriber);
    end;

    [Test]
    procedure StorageWrite_ModifyAllTrue_PerRowTriggerSeesStoredStamp()
    // CLAIM: ModifyAll(Field, Value, true) runs OnModify per row, and Rec.SystemModifiedAt inside it is still the
    //        value stored before the ModifyAll; the row carries a newer stamp afterwards.
    var
        P: Record "Storage Write Probe";
        RowKey: Integer;
        StoredModifiedAt: Text;
    begin
        Initialize();
        P.Payload := 'one';
        P.Insert(false);
        P.Get(P."Entry No.");
        RowKey := P."Entry No.";
        StoredModifiedAt := Format(P.SystemModifiedAt, 0, 9);
        Assert.AreNotEqual('', StoredModifiedAt, 'control: the stored row must carry a SystemModifiedAt');
        Sleep(50);
        Recorder.Wipe();

        P.Reset();
        P.ModifyAll(Payload, 'two', true);

        Assert.AreEqual(Format(RowKey, 0, 9), Recorder.Read('OnModify', 'Rec.EntryNo'), 'control: OnModify must have run for the row');
        Assert.AreEqual('two', Recorder.Read('OnModify', 'Rec.Payload'), 'control: OnModify must see the new Payload');
        Assert.AreEqual(StoredModifiedAt, Recorder.Read('OnModify', 'Rec.SystemModifiedAt'), 'Rec.SystemModifiedAt in the per-row OnModify of ModifyAll must still be the stored value');

        P.Get(RowKey);
        Assert.AreNotEqual(StoredModifiedAt, Format(P.SystemModifiedAt, 0, 9), 'after ModifyAll the row must carry a newer SystemModifiedAt');
    end;

    local procedure Initialize()
    var
        P: Record "Storage Write Probe";
    begin
        P.DeleteAll();
        Recorder.Wipe();
    end;
}

// Manual so it only observes the tests that bind it; SingleInstance state lives in the shared recorder.
codeunit 67814 "Storage Write Subscriber"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"Storage Write Probe", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeInsert(var Rec: Record "Storage Write Probe")
    begin
        Capture('EvBeforeInsert', Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Storage Write Probe", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsert(var Rec: Record "Storage Write Probe")
    begin
        Capture('EvAfterInsert', Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Storage Write Probe", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModify(var Rec: Record "Storage Write Probe")
    begin
        Capture('EvBeforeModify', Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Storage Write Probe", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModify(var Rec: Record "Storage Write Probe")
    begin
        Capture('EvAfterModify', Rec);
    end;

    local procedure Capture(EventName: Text; var Rec: Record "Storage Write Probe")
    var
        Recorder: Codeunit "Storage Write Recorder";
    begin
        Recorder.Put(EventName, 'Rec.EntryNo', Format(Rec."Entry No.", 0, 9));
        Recorder.Put(EventName, 'Rec.SystemCreatedAt', Format(Rec.SystemCreatedAt, 0, 9));
        Recorder.Put(EventName, 'Rec.SystemModifiedAt', Format(Rec.SystemModifiedAt, 0, 9));
    end;
}
