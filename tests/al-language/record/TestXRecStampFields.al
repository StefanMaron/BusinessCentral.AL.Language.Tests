// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-overview
// Scope: in-scope (Cloud-compatible)
// Fixtures used: xRec Stamp Probe (67810), xRec Stamp Recorder (67811) -- declared in TestXRecStampFields.Objects.al
// BC versions: 27.0+ (measured on every cloud leg of the corpus matrix)
//
// WHAT THIS PINS. TestXRecContracts (60179) pins the user fields of xRec inside the table triggers. This
// codeunit pins the other half: what xRec and Rec hold for the SYSTEM fields (SystemId, SystemCreatedAt,
// SystemModifiedAt, SystemCreatedBy, SystemModifiedBy) and for an AutoIncrement primary-key field, read from
// inside OnInsert / OnModify / OnDelete of a code-driven Insert(true) / Modify(true) / Delete(true).
//
// The answers were MEASURED by a probe on every cloud leg before these assertions were written, not
// reasoned out. Summary of what a real service tier does:
//   OnInsert: the AutoIncrement key is NOT assigned yet (0, on Rec and on xRec). The Created/Modified stamps
//             are NOT written yet (default, on Rec and on xRec). SystemId IS already on Rec; xRec has none.
//   OnModify: xRec carries the stored row's stamps. Rec.SystemModifiedAt still holds the OLD value, i.e. it is
//             re-stamped after the trigger, not before it.
//   OnDelete: Rec and xRec both carry the stored row's stamps.
// The AutoIncrement value and the stamps come from the storage layer below the trigger, so a before-image
// taken above that layer cannot contain them.
//
// All DateTime/Guid comparisons go through Format(_, 0, 9): Assert compares DateTimes at minute resolution,
// which would pass two instants up to a minute apart (AlRunner#4439).
//
// Written for StefanMaron/BusinessCentral.AL.Runner#4331.

codeunit 67812 "Test xRec Stamp Fields"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Recorder: Codeunit "xRec Stamp Recorder";
        NullGuidTxt: Label '{00000000-0000-0000-0000-000000000000}', Locked = true;

    [Test]
    procedure XRecStamp_Insert_XRecSystemFieldsAreDefaultInOnInsert()
    // CLAIM: inside OnInsert of a code-driven Insert(true), xRec holds no SystemId and no Created/Modified
    //        stamp -- all default -- while the row that is stored afterwards does carry them.
    var
        P: Record "xRec Stamp Probe";
    begin
        Initialize();

        P.Payload := 'one';
        P.Insert(true);

        Assert.AreEqual(NullGuidTxt, Recorder.Read('OnInsert', 'xRec.SystemId'), 'xRec.SystemId in OnInsert must be the null guid');
        Assert.AreEqual('', Recorder.Read('OnInsert', 'xRec.SystemCreatedAt'), 'xRec.SystemCreatedAt in OnInsert must be the default DateTime');
        Assert.AreEqual('', Recorder.Read('OnInsert', 'xRec.SystemModifiedAt'), 'xRec.SystemModifiedAt in OnInsert must be the default DateTime');
        Assert.AreEqual(NullGuidTxt, Recorder.Read('OnInsert', 'xRec.SystemCreatedBy'), 'xRec.SystemCreatedBy in OnInsert must be the null guid');
        Assert.AreEqual(NullGuidTxt, Recorder.Read('OnInsert', 'xRec.SystemModifiedBy'), 'xRec.SystemModifiedBy in OnInsert must be the null guid');

        // Control: the probe can see real values, and the stored row does carry them.
        P.Get(P."Entry No.");
        Assert.AreNotEqual('', Format(P.SystemCreatedAt, 0, 9), 'the stored row must carry a SystemCreatedAt, or the default reading above proves nothing');
        Assert.AreNotEqual('', Format(P.SystemModifiedAt, 0, 9), 'the stored row must carry a SystemModifiedAt');
        Assert.AreNotEqual(NullGuidTxt, Format(P.SystemId, 0, 9), 'the stored row must carry a SystemId');
        Assert.AreNotEqual(NullGuidTxt, Format(P.SystemCreatedBy, 0, 9), 'the stored row must carry a SystemCreatedBy');
    end;

    [Test]
    procedure XRecStamp_Insert_XRecAutoIncrementKeyIsZeroInOnInsert()
    // CLAIM: inside OnInsert, xRec."Entry No." of an AutoIncrement key is 0, and the row that is stored
    //        afterwards got a non-zero key.
    var
        P: Record "xRec Stamp Probe";
    begin
        Initialize();

        P.Payload := 'one';
        P.Insert(true);

        Assert.AreEqual('0', Recorder.Read('OnInsert', 'xRec.EntryNo'), 'xRec."Entry No." in OnInsert must be 0');
        Assert.AreNotEqual(0, P."Entry No.", 'control: the Insert must have assigned a non-zero AutoIncrement key');
    end;

    [Test]
    procedure XRecStamp_Insert_RecSystemStampsNotYetWrittenInOnInsert()
    // CLAIM: inside OnInsert, Rec already carries its SystemId (the same one that is stored), but the
    //        Created/Modified stamps are still default -- they are written below the trigger.
    var
        P: Record "xRec Stamp Probe";
    begin
        Initialize();

        P.Payload := 'one';
        P.Insert(true);

        Assert.AreEqual(Format(P.SystemId, 0, 9), Recorder.Read('OnInsert', 'Rec.SystemId'), 'Rec.SystemId in OnInsert must already be the id that ends up stored');
        Assert.AreEqual('', Recorder.Read('OnInsert', 'Rec.SystemCreatedAt'), 'Rec.SystemCreatedAt in OnInsert must still be the default DateTime');
        Assert.AreEqual('', Recorder.Read('OnInsert', 'Rec.SystemModifiedAt'), 'Rec.SystemModifiedAt in OnInsert must still be the default DateTime');
        Assert.AreEqual(NullGuidTxt, Recorder.Read('OnInsert', 'Rec.SystemCreatedBy'), 'Rec.SystemCreatedBy in OnInsert must still be the null guid');
        Assert.AreEqual(NullGuidTxt, Recorder.Read('OnInsert', 'Rec.SystemModifiedBy'), 'Rec.SystemModifiedBy in OnInsert must still be the null guid');

        // Control: after the Insert returns, the stamps are there.
        Assert.AreNotEqual('', Format(P.SystemCreatedAt, 0, 9), 'after Insert the record must carry SystemCreatedAt');
    end;

    [Test]
    procedure XRecStamp_Insert_RecAutoIncrementKeyNotYetAssignedInOnInsert()
    // CLAIM: inside OnInsert, Rec."Entry No." of an AutoIncrement key is still 0; the key is assigned after
    //        the trigger returns.
    var
        P: Record "xRec Stamp Probe";
    begin
        Initialize();

        P.Payload := 'one';
        P.Insert(true);

        Assert.AreEqual('0', Recorder.Read('OnInsert', 'Rec.EntryNo'), 'Rec."Entry No." in OnInsert must still be 0');
        Assert.AreNotEqual(0, P."Entry No.", 'control: after Insert the key must be assigned');
    end;

    [Test]
    procedure XRecStamp_Modify_XRecHoldsStoredStampsInOnModify()
    // CLAIM: inside OnModify, xRec carries the stored row's SystemId, SystemCreatedAt/By, SystemModifiedAt/By
    //        (as they were before this Modify) and its key.
    var
        P: Record "xRec Stamp Probe";
        RowKey: Integer;
        StoredId: Text;
        StoredCreatedAt: Text;
        StoredModifiedAt: Text;
        StoredCreatedBy: Text;
        StoredModifiedBy: Text;
    begin
        Initialize();
        P.Payload := 'one';
        P.Insert(false);
        P.Get(P."Entry No.");
        RowKey := P."Entry No.";
        StoredId := Format(P.SystemId, 0, 9);
        StoredCreatedAt := Format(P.SystemCreatedAt, 0, 9);
        StoredModifiedAt := Format(P.SystemModifiedAt, 0, 9);
        StoredCreatedBy := Format(P.SystemCreatedBy, 0, 9);
        StoredModifiedBy := Format(P.SystemModifiedBy, 0, 9);
        Assert.AreNotEqual('', StoredModifiedAt, 'control: the stored row must carry a SystemModifiedAt');
        Recorder.Wipe();

        P.Payload := 'two';
        P.Modify(true);

        Assert.AreEqual(Format(RowKey, 0, 9), Recorder.Read('OnModify', 'xRec.EntryNo'), 'xRec."Entry No." in OnModify must be the stored key');
        Assert.AreEqual(StoredId, Recorder.Read('OnModify', 'xRec.SystemId'), 'xRec.SystemId in OnModify must be the stored id');
        Assert.AreEqual(StoredCreatedAt, Recorder.Read('OnModify', 'xRec.SystemCreatedAt'), 'xRec.SystemCreatedAt in OnModify must be the stored value');
        Assert.AreEqual(StoredModifiedAt, Recorder.Read('OnModify', 'xRec.SystemModifiedAt'), 'xRec.SystemModifiedAt in OnModify must be the value stored BEFORE this Modify');
        Assert.AreEqual(StoredCreatedBy, Recorder.Read('OnModify', 'xRec.SystemCreatedBy'), 'xRec.SystemCreatedBy in OnModify must be the stored value');
        Assert.AreEqual(StoredModifiedBy, Recorder.Read('OnModify', 'xRec.SystemModifiedBy'), 'xRec.SystemModifiedBy in OnModify must be the stored value');
    end;

    [Test]
    procedure XRecStamp_Modify_RecModifiedAtNotYetRestampedInOnModify()
    // CLAIM: inside OnModify, Rec.SystemModifiedAt still holds the value stored before this Modify; the new
    //        stamp is written after the trigger returns. SystemCreatedAt and SystemId are unchanged.
    var
        P: Record "xRec Stamp Probe";
        StoredModifiedAt: Text;
        StoredCreatedAt: Text;
    begin
        Initialize();
        P.Payload := 'one';
        P.Insert(false);
        P.Get(P."Entry No.");
        StoredModifiedAt := Format(P.SystemModifiedAt, 0, 9);
        StoredCreatedAt := Format(P.SystemCreatedAt, 0, 9);
        Sleep(50);
        Recorder.Wipe();

        P.Payload := 'two';
        P.Modify(true);

        Assert.AreEqual(StoredModifiedAt, Recorder.Read('OnModify', 'Rec.SystemModifiedAt'), 'Rec.SystemModifiedAt in OnModify must still be the pre-Modify value');
        Assert.AreEqual(StoredCreatedAt, Recorder.Read('OnModify', 'Rec.SystemCreatedAt'), 'Rec.SystemCreatedAt in OnModify must be the stored value');

        // Control: the stamp does move once the Modify has completed, so the reading above is the old value
        // and not a value that never changes.
        Assert.AreNotEqual(StoredModifiedAt, Format(P.SystemModifiedAt, 0, 9), 'after Modify the record must carry a newer SystemModifiedAt');
    end;

    [Test]
    procedure XRecStamp_Delete_XRecHoldsStoredStampsInOnDelete()
    // CLAIM: inside OnDelete, xRec carries the stored row's stamps and id, and so does Rec.
    var
        P: Record "xRec Stamp Probe";
        StoredId: Text;
        StoredCreatedAt: Text;
        StoredModifiedAt: Text;
    begin
        Initialize();
        P.Payload := 'one';
        P.Insert(false);
        P.Get(P."Entry No.");
        StoredId := Format(P.SystemId, 0, 9);
        StoredCreatedAt := Format(P.SystemCreatedAt, 0, 9);
        StoredModifiedAt := Format(P.SystemModifiedAt, 0, 9);
        Assert.AreNotEqual('', StoredCreatedAt, 'control: the stored row must carry a SystemCreatedAt');
        Recorder.Wipe();

        P.Delete(true);

        Assert.AreEqual(StoredId, Recorder.Read('OnDelete', 'xRec.SystemId'), 'xRec.SystemId in OnDelete must be the stored id');
        Assert.AreEqual(StoredCreatedAt, Recorder.Read('OnDelete', 'xRec.SystemCreatedAt'), 'xRec.SystemCreatedAt in OnDelete must be the stored value');
        Assert.AreEqual(StoredModifiedAt, Recorder.Read('OnDelete', 'xRec.SystemModifiedAt'), 'xRec.SystemModifiedAt in OnDelete must be the stored value');
        Assert.AreEqual(StoredId, Recorder.Read('OnDelete', 'Rec.SystemId'), 'Rec.SystemId in OnDelete must be the stored id');
        Assert.AreEqual(StoredCreatedAt, Recorder.Read('OnDelete', 'Rec.SystemCreatedAt'), 'Rec.SystemCreatedAt in OnDelete must be the stored value');
    end;

    local procedure Initialize()
    var
        P: Record "xRec Stamp Probe";
    begin
        P.DeleteAll();
        Recorder.Wipe();
    end;
}
