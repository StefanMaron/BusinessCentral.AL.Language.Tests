// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-getbysystemid-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000)

codeunit 60061 "Test Record SystemId"
{
    Subtype = Test;
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

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
