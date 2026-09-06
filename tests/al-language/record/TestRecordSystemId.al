// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-getbysystemid-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000)

codeunit 60061 "Test Record SystemId"
{
    Subtype = Test;
    TestPermissions = Disabled;
    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Record_GetBySystemId_ExistingSystemId_ReturnsTrue()
    var
        Rec: Record "ALT Universal";
        Fetched: Record "ALT Universal";
        SystemId: Guid;
        Result: Boolean;
    begin
        Initialize();
        SystemId := CreateGuid();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 42;
        Rec.SystemId := SystemId;
        Rec.Insert(false, true);
        Clear(Fetched);
        Result := Fetched.GetBySystemId(SystemId);
        Assert.IsTrue(Result, 'GetBySystemId with existing SystemId must return true');
    end;

    [Test]
    procedure Record_GetBySystemId_InvalidSystemId_ReturnsFalse()
    var
        Rec: Record "ALT Universal";
        InvalidGuid: Guid;
        Result: Boolean;
    begin
        Initialize();
        InvalidGuid := CreateGuid();
        Result := Rec.GetBySystemId(InvalidGuid);
        Assert.IsFalse(Result, 'GetBySystemId with non-existent SystemId must return false');
    end;

    [Test]
    procedure Record_GetBySystemId_ReturnsCorrectRecord()
    var
        Rec: Record "ALT Universal";
        Fetched: Record "ALT Universal";
        SystemId: Guid;
        ExpectedEntryNo: Integer;
        ExpectedIntField: Integer;
    begin
        Initialize();
        ExpectedEntryNo := 42;
        ExpectedIntField := 99;
        SystemId := CreateGuid();
        Rec."Entry No." := ExpectedEntryNo;
        Rec."Integer Field" := ExpectedIntField;
        Rec.SystemId := SystemId;
        Rec.Insert(false, true);
        Clear(Fetched);
        Fetched.GetBySystemId(SystemId);
        Assert.AreEqual(ExpectedEntryNo, Fetched."Entry No.", 'GetBySystemId must return record with correct Entry No.');
        Assert.AreEqual(ExpectedIntField, Fetched."Integer Field", 'GetBySystemId must return record with correct Integer Field');
    end;

    [Test]
    procedure Record_GetBySystemId_ZeroGuid_ReturnsFalse()
    var
        Rec: Record "ALT Universal";
        ZeroGuid: Guid;
        Result: Boolean;
    begin
        Initialize();
        ZeroGuid := '00000000-0000-0000-0000-000000000000';
        Result := Rec.GetBySystemId(ZeroGuid);
        Assert.IsFalse(Result, 'GetBySystemId with zero Guid must return false');
    end;

    [Test]
    procedure Record_Insert_DuplicateSystemId_Refused()
    // CLAIM: inserting a second row with an already-used explicit SystemId raises a
    // unique-constraint error; SystemId is a physically unique key even though it is
    // not one of the table's declared AL keys.
    var
        First: Record "ALT Universal";
        Second: Record "ALT Universal";
        DuplicateId: Guid;
    begin
        Initialize();
        DuplicateId := CreateGuid();
        First."Entry No." := 1;
        First.SystemId := DuplicateId;
        First.Insert(false, true);

        Second."Entry No." := 2;
        Second.SystemId := DuplicateId;
        asserterror Second.Insert(false, true);
        Assert.ExpectedError('unique index');
    end;

    [Test]
    procedure Record_Insert_DifferentSystemIds_BothSucceed()
    // Negative control for Record_Insert_DuplicateSystemId_Refused: two DIFFERENT
    // explicit SystemIds must both insert cleanly, so an implementation that refused
    // every second Insert() (regardless of SystemId) would fail this test.
    var
        First: Record "ALT Universal";
        Second: Record "ALT Universal";
    begin
        Initialize();
        First."Entry No." := 1;
        First.SystemId := CreateGuid();
        First.Insert(false, true);

        Second."Entry No." := 2;
        Second.SystemId := CreateGuid();
        Second.Insert(false, true);

        Assert.IsTrue(First.SystemId <> Second.SystemId, 'Distinct explicit SystemIds must both be accepted');
        Assert.RecordCount(First, 2);
    end;

    [Test]
    procedure Record_Modify_KeepsOriginalSystemId()
    // CLAIM: Modify() never changes an existing row's SystemId, even when the record
    // buffer's SystemId slot no longer carries the original value (e.g. because the
    // buffer was Clear()'d and re-populated by field assignment instead of Get()).
    var
        Rec: Record "ALT Universal";
        Fetched: Record "ALT Universal";
        OriginalId: Guid;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 1;
        Rec.Insert(true);
        OriginalId := Rec.SystemId;

        Rec."Integer Field" := 42;
        Rec.Modify(true);

        Assert.AreEqual(OriginalId, Rec.SystemId, 'Modify must not change the record''s own SystemId');

        Clear(Fetched);
        Assert.IsTrue(Fetched.GetBySystemId(OriginalId), 'The original SystemId must still resolve after Modify');
        Assert.AreEqual(42, Fetched."Integer Field", 'GetBySystemId after Modify must return the modified field value');
    end;

    [Test]
    procedure Record_Modify_AfterGet_KeepsOriginalSystemId()
    // CLAIM: same as Record_Modify_KeepsOriginalSystemId, but through the more common
    // AL shape of a fresh Get() (a genuinely new buffer read from storage) before the
    // Modify(), rather than reusing the Insert-time variable.
    var
        Rec: Record "ALT Universal";
        Fetched: Record "ALT Universal";
        OriginalId: Guid;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 1;
        Rec.Insert(true);
        OriginalId := Rec.SystemId;

        Clear(Rec);
        Rec.Get(1);
        Rec."Integer Field" := 42;
        Rec.Modify(true);

        Assert.AreEqual(OriginalId, Rec.SystemId, 'Modify after Get must not change the record''s own SystemId');
        Clear(Fetched);
        Assert.IsTrue(Fetched.GetBySystemId(OriginalId), 'The original SystemId must still resolve after Modify-after-Get');
        Assert.AreEqual(42, Fetched."Integer Field", 'GetBySystemId after Modify-after-Get must return the modified field value');
    end;

    [Test]
    procedure Record_ModifyAll_OnSystemId_Fails()
    // CLAIM: ModifyAll cannot target the SystemId field. The platform refuses the whole
    // statement with an error rather than updating the rows and rather than quietly
    // ignoring the field, so no row's SystemId is changed and the other fields are not
    // updated either.
    var
        Rec: Record "ALT Universal";
        Fetched: Record "ALT Universal";
        OriginalId: Guid;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 7;
        Rec.Insert(true);
        OriginalId := Rec.SystemId;
        // Make the row durable first. The refused ModifyAll raises an error, and an error
        // rolls the write transaction back to the last commit point — so without this the
        // row read below is gone because of the rollback, and the test could not tell
        // "ModifyAll left the SystemId alone" apart from "there is no row any more".
        Commit();

        Rec.Reset();
        asserterror Rec.ModifyAll(SystemId, CreateGuid());
        Assert.ExpectedError('cannot change the value of the SystemId field');

        Clear(Fetched);
        Fetched.Get(1);
        Assert.AreEqual(OriginalId, Fetched.SystemId, 'A refused ModifyAll must leave the stored SystemId untouched');
        Assert.IsTrue(Fetched.GetBySystemId(OriginalId), 'The original SystemId must still resolve after a refused ModifyAll');
    end;

    [Test]
    procedure Record_ModifyAll_OnTemporarySystemId_Fails()
    // CLAIM: the refusal is a property of the ModifyAll statement, not of the storage
    // behind it — a temporary record refuses it the same way.
    var
        TempRec: Record "ALT Universal" temporary;
        OriginalId: Guid;
    begin
        Initialize();
        TempRec."Entry No." := 1;
        TempRec.Insert(true);
        OriginalId := TempRec.SystemId;

        TempRec.Reset();
        asserterror TempRec.ModifyAll(SystemId, CreateGuid());
        Assert.ExpectedError('cannot change the value of the SystemId field');

        TempRec.Get(1);
        Assert.AreEqual(OriginalId, TempRec.SystemId, 'A refused ModifyAll must leave a temporary row''s SystemId untouched');
    end;

    [Test]
    procedure Record_ModifyAll_OnOrdinaryField_SucceedsAndKeepsSystemId()
    // Negative control for the two tests above. ModifyAll itself must still work: an
    // implementation that refused every ModifyAll, or one that rewrote SystemId on an
    // ordinary bulk update, both fail here. Asserts the concrete updated value, so an
    // implementation that silently did nothing fails too.
    var
        Rec: Record "ALT Universal";
        Fetched: Record "ALT Universal";
        OriginalId: Guid;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 7;
        Rec.Insert(true);
        OriginalId := Rec.SystemId;

        Rec.Reset();
        Rec.ModifyAll("Integer Field", 42);

        Clear(Fetched);
        Fetched.Get(1);
        Assert.AreEqual(42, Fetched."Integer Field", 'ModifyAll on an ordinary field must update it to 42');
        Assert.AreEqual(OriginalId, Fetched.SystemId, 'ModifyAll on an ordinary field must not change the row''s SystemId');
    end;

    [Test]
    procedure Record_Insert_SystemIdOfADeletedRow_IsAcceptedAgain()
    // CLAIM: the SystemId uniqueness constraint is over the rows that currently EXIST, not
    // over every id the table has ever held. Deleting a row frees its SystemId, so a later
    // Insert carrying that same id succeeds and resolves to the NEW row.
    //
    // The pair with Record_Insert_DuplicateSystemId_Refused above is the whole point: same
    // two inserts, same id, and the only difference is the Delete in between. One must be
    // refused and the other must not, so an implementation that answered the same way to both
    // -- refusing always, or accepting always -- fails one of them.
    var
        First: Record "ALT Universal";
        Second: Record "ALT Universal";
        Fetched: Record "ALT Universal";
        ReusedId: Guid;
    begin
        Initialize();
        ReusedId := CreateGuid();
        First."Entry No." := 1;
        First."Integer Field" := 1;
        First.SystemId := ReusedId;
        First.Insert(false, true);

        First.Get(1);
        First.Delete();

        Second."Entry No." := 2;
        Second."Integer Field" := 2;
        Second.SystemId := ReusedId;
        Second.Insert(false, true);

        Clear(Fetched);
        Assert.IsTrue(Fetched.GetBySystemId(ReusedId), 'a deleted row''s SystemId must be usable again, and must resolve after the re-insert');
        Assert.AreEqual(2, Fetched."Entry No.", 'GetBySystemId must return the row that holds the id NOW, not the deleted one');
        Assert.AreEqual(2, Fetched."Integer Field", 'the re-inserted row''s own field values must be the ones that come back');
    end;

    [Test]
    procedure Record_Insert_SystemIdFreedByDeleteAll_IsAcceptedAgain()
    // CLAIM: the same holds when the rows go away in bulk rather than one at a time. Stated
    // separately because DeleteAll is a different platform path from Delete, and a runtime
    // that tracked live SystemIds could plausibly maintain that tracking on one and not the
    // other -- which would show up here and nowhere else.
    var
        Rec: Record "ALT Universal";
        Reused: Record "ALT Universal";
        Fetched: Record "ALT Universal";
        ReusedId: Guid;
        i: Integer;
    begin
        Initialize();
        for i := 1 to 5 do begin
            Rec.Init();
            Rec."Entry No." := i;
            Rec."Integer Field" := i;
            Rec.SystemId := CreateGuid();
            Rec.Insert(false, true);
            if i = 3 then
                ReusedId := Rec.SystemId;
        end;

        Rec.Reset();
        Rec.DeleteAll();

        Reused."Entry No." := 99;
        Reused."Integer Field" := 99;
        Reused.SystemId := ReusedId;
        Reused.Insert(false, true);

        Clear(Fetched);
        Assert.IsTrue(Fetched.GetBySystemId(ReusedId), 'a SystemId freed by DeleteAll must be usable again');
        Assert.AreEqual(99, Fetched."Entry No.", 'GetBySystemId must return the re-inserted row');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
