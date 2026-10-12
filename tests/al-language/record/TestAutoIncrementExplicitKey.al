// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoincrement-property
// Scope: in-scope (Cloud-compatible)
// Fixtures used: AutoInc Explicit Probe (67820), AutoInc Unique Probe (67823), AutoInc Explicit Control (67821),
//                AutoInc Explicit Subscriber (67824) -- declared in TestAutoIncrementExplicitKey.Objects.al
// BC versions: 27.0+ (measured on every cloud leg of the corpus matrix)
//
// WHAT THIS PINS. TestAutoIncrementContracts (60201) covers only zero-key inserts, Init and Truncate. This codeunit
// asks what the AutoIncrement COUNTER does when the AL code puts a value into the AutoIncrement field itself:
// the caller before Insert, the table's own OnInsert, an OnBeforeInsertEvent subscriber, a Rename; and what a failed
// Insert, a delete or an asserterror rollback does to the counter.
//
// The answers were MEASURED by a probe on the cloud legs before these assertions were written. What a real
// service tier does:
//   - An explicit key above the counter RAISES it: the next zero-key Insert gets explicit + 1. The same when the
//     key arrives from OnInsert or from an OnBeforeInsertEvent subscriber.
//   - An explicit key at or below the counter leaves it alone; Delete, DeleteAll and a refused duplicate explicit
//     key do not move it either.
//   - Rename on a table whose key is the AutoIncrement field is refused.
//   - An Insert that fails on a unique secondary key has already taken its counter value, and the key it took is
//     not left on the record variable.
//   - An Insert refused by an error in OnInsert and caught by asserterror leaves the counter where it was: the
//     data rolls back, the counter does not.
// BC's AutoIncrement is a SQL IDENTITY column written with IDENTITY_INSERT for explicit keys (the platform's own
// duplicate-key message for the mismatch case names it), which is the behaviour above.
//
// Every key is asserted RELATIVE to a key the test just received, never as an absolute number: the counter of a
// table survives DeleteAll and the tests run in one database, so the starting value depends on what ran before.
//
// Written for StefanMaron/BusinessCentral.AL.Runner#5513.

codeunit 67822 "Test AutoInc Explicit Key"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Control: Codeunit "AutoInc Explicit Control";

    [Test]
    procedure AutoInc_CallerKeyAboveCounter_NextZeroKeyFollowsIt()
    // CLAIM: after the caller inserts an explicit key above the counter, the next zero-key Insert gets that key + 1.
    var
        K1: Integer;
    begin
        Initialize();
        K1 := InsertZero();
        Assert.IsTrue(InsertExplicit(K1 + 10), 'an explicit key must be accepted');
        Assert.AreEqual(K1 + 11, InsertZero(), 'the next zero-key key must follow the explicit key, not the old counter');
        Assert.AreEqual(K1 + 12, InsertZero(), 'and the counter keeps advancing from there');
        AssertOnlyKeys(K1, K1 + 10, K1 + 11, K1 + 12);
    end;

    [Test]
    procedure AutoInc_CallerKeyEqualToNext_NextZeroKeyDoesNotCollide()
    // CLAIM: an explicit key equal to the value the counter would hand out next does not make the next zero-key
    //        Insert collide with it.
    var
        K1: Integer;
        K3: Integer;
    begin
        Initialize();
        K1 := InsertZero();
        Assert.IsTrue(InsertExplicit(K1 + 1), 'an explicit key equal to the next counter value must be accepted');
        Assert.IsTrue(TryInsertZero(K3), 'the next zero-key Insert must succeed, not hit a duplicate key');
        Assert.AreEqual(K1 + 2, K3, 'and it must get the key after the explicit one');
    end;

    [Test]
    procedure AutoInc_OnInsertAssignedKey_NextZeroKeyFollowsIt()
    // CLAIM: a key the table's own OnInsert puts into the AutoIncrement field is stored, raises the counter, and
    //        was not yet assigned when OnInsert started.
    var
        K1: Integer;
        Trig: Integer;
    begin
        Initialize();
        K1 := InsertZero();
        Control.AssignKeyInOnInsert(K1 + 10);
        Trig := InsertZero();
        Assert.AreEqual(0, Control.GetSawInOnInsert(), 'OnInsert must start with the AutoIncrement field still 0');
        Assert.AreEqual(K1 + 10, Trig, 'the key OnInsert assigned must be the stored key');
        Control.Reset();
        Assert.AreEqual(K1 + 11, InsertZero(), 'the next zero-key key must follow the key OnInsert assigned');
        AssertOnlyKeys(K1, K1 + 10, K1 + 11, 0);
    end;

    [Test]
    procedure AutoInc_OnInsertAssignedKeyEqualToNext_NextZeroKeyDoesNotCollide()
    // CLAIM: the same for an OnInsert key equal to the next counter value -- the shape of
    //        "Entry No." := Last."Entry No." + 1 in an OnInsert trigger.
    var
        K1: Integer;
        K3: Integer;
    begin
        Initialize();
        K1 := InsertZero();
        Control.AssignKeyInOnInsert(K1 + 1);
        Assert.AreEqual(K1 + 1, InsertZero(), 'the key OnInsert assigned must be the stored key');
        Control.Reset();
        Assert.IsTrue(TryInsertZero(K3), 'the next zero-key Insert must succeed, not hit a duplicate key');
        Assert.AreEqual(K1 + 2, K3, 'and it must get the key after the one OnInsert assigned');
    end;

    [Test]
    procedure AutoInc_BeforeInsertSubscriberKey_NextZeroKeyFollowsIt()
    // CLAIM: a key an OnBeforeInsertEvent subscriber puts into the AutoIncrement field is stored and raises the counter.
    var
        Sub: Codeunit "AutoInc Explicit Subscriber";
        K1: Integer;
    begin
        Initialize();
        K1 := InsertZero();
        Sub.SetKey(K1 + 10);
        BindSubscription(Sub);
        Assert.AreEqual(K1 + 10, InsertZero(), 'the key the subscriber assigned must be the stored key');
        UnbindSubscription(Sub);
        Assert.AreEqual(K1 + 11, InsertZero(), 'the next zero-key key must follow the subscriber''s key');
    end;

    [Test]
    procedure AutoInc_CallerKeyIntoAGapBelowCounter_DoesNotLowerIt()
    // CLAIM: filling a gap below the counter with an explicit key leaves the counter where it was.
    var
        P: Record "AutoInc Explicit Probe";
        K1: Integer;
        K2: Integer;
        K3: Integer;
    begin
        Initialize();
        K1 := InsertZero();
        K2 := InsertZero();
        K3 := InsertZero();
        P.Get(K2);
        P.Delete(false);
        Assert.IsTrue(InsertExplicit(K2), 'refilling the gap must be accepted');
        Assert.AreEqual(K3 + 1, InsertZero(), 'the counter must carry on from the last key handed out, not from the gap');
        AssertOnlyKeys(K1, K2, K3, K3 + 1);
    end;

    [Test]
    procedure AutoInc_DeleteAll_DoesNotRewindCounter()
    // CLAIM: deleting every row does not rewind the counter.
    var
        P: Record "AutoInc Explicit Probe";
        K3: Integer;
    begin
        Initialize();
        InsertZero();
        InsertZero();
        K3 := InsertZero();
        P.DeleteAll();
        Assert.AreEqual(K3 + 1, InsertZero(), 'the counter must carry on after DeleteAll');
        Assert.AreEqual(1, P.Count(), 'only the new row must be stored');
    end;

    [Test]
    procedure AutoInc_CallerLowKeyAfterDeleteAll_DoesNotLowerCounter()
    // CLAIM: an explicit low key into an emptied table does not lower the counter.
    var
        P: Record "AutoInc Explicit Probe";
        K1: Integer;
        K3: Integer;
    begin
        Initialize();
        K1 := InsertZero();
        InsertZero();
        K3 := InsertZero();
        P.DeleteAll();
        Assert.IsTrue(InsertExplicit(K1), 'the explicit key must be accepted');
        Assert.AreEqual(K3 + 1, InsertZero(), 'the counter must still carry on from the last key handed out');
        AssertOnlyKeys(K1, K3 + 1, 0, 0);
    end;

    [Test]
    procedure AutoInc_CallerKeyDuplicatingAStoredRow_IsRefusedAndKeepsCounter()
    // CLAIM: an explicit key that already exists is refused (Insert returns false under a Boolean receiver) and the
    //        refusal does not move the counter.
    var
        K1: Integer;
        K3: Integer;
    begin
        Initialize();
        K1 := InsertZero();
        Assert.IsFalse(InsertExplicit(K1), 'a key that is already stored must be refused');
        Assert.IsTrue(TryInsertZero(K3), 'the next zero-key Insert must succeed');
        Assert.AreEqual(K1 + 1, K3, 'and it must get the next value, as if the refused insert had not happened');
    end;

    [Test]
    procedure AutoInc_ZeroedKeyOnAReusedRecord_GetsTheNextValue()
    // CLAIM: Init keeps the key, so a reused record variable inserts again only after the key is set to 0; then it
    //        gets the next value.
    var
        P: Record "AutoInc Explicit Probe";
        K1: Integer;
    begin
        Initialize();
        P.Payload := 'first';
        P.Insert(true);
        K1 := P."Entry No.";
        P.Init();
        P."Entry No." := 0;
        P.Payload := 'second';
        P.Insert(true);
        Assert.AreEqual(K1 + 1, P."Entry No.", 'a zeroed key must get the next value');
    end;

    [Test]
    procedure AutoInc_Rename_OfTheAutoIncrementKey_IsRefused()
    // CLAIM: Rename on a table whose primary key is the AutoIncrement field raises the AutoIncrement error.
    var
        P: Record "AutoInc Explicit Probe";
        K1: Integer;
    begin
        Initialize();
        K1 := InsertZero();
        P.Get(K1);
        asserterror P.Rename(K1 + 50);
        Assert.ExpectedError('You cannot change the value of an AutoIncrement field.');
    end;

    [Test]
    procedure AutoInc_FailedInsertOnUniqueKey_ConsumesTheCounterValue()
    // CLAIM: an Insert that fails on a unique secondary key has already taken its AutoIncrement value, so the
    //        next successful Insert skips it.
    var
        U: Record "AutoInc Unique Probe";
        K1: Integer;
    begin
        Initialize();
        U.Code := 'X';
        Assert.IsTrue(U.Insert(true), 'control: the first row must be inserted');
        K1 := U."Entry No.";
        Clear(U);
        U.Code := 'X';
        Assert.IsFalse(U.Insert(true), 'a second row with the same unique Code must be refused');
        Clear(U);
        U.Code := 'Y';
        Assert.IsTrue(U.Insert(true), 'a row with a new Code must be inserted');
        Assert.AreEqual(K1 + 2, U."Entry No.", 'the refused Insert must have consumed one value');
    end;

    [Test]
    procedure AutoInc_FailedInsertOnUniqueKey_LeavesTheKeyZeroOnTheRecord()
    // CLAIM: after an Insert that failed on a unique secondary key, the AutoIncrement field on the record variable
    //        is 0 again.
    var
        U: Record "AutoInc Unique Probe";
    begin
        Initialize();
        U.Code := 'X';
        U.Insert(true);
        Clear(U);
        U.Code := 'X';
        Assert.IsFalse(U.Insert(true), 'control: the Insert must be refused');
        Assert.AreEqual(0, U."Entry No.", 'the key taken for the refused Insert must not stay on the record');
    end;

    [Test]
    procedure AutoInc_InsertRefusedByOnInsert_ThenAsserterror_DoesNotRollTheCounterBack()
    // CLAIM: an Insert refused by an error in OnInsert and caught by asserterror leaves the counter where it was --
    //        the key the earlier Insert took is not handed out again, as with a SQL identity.
    var
        P: Record "AutoInc Explicit Probe";
        K1: Integer;
    begin
        Initialize();
        K1 := InsertZero();
        Control.FailInOnInsert();
        P.Payload := 'refused';
        asserterror P.Insert(true);
        Assert.ExpectedError('AutoInc probe: OnInsert refused the row');
        Control.Reset();
        Assert.AreEqual(K1 + 1, InsertZero(), 'the counter must not have been rolled back with the data');
    end;

    [Test]
    procedure AutoInc_NegativeCallerKey_DoesNotLowerCounter()
    // CLAIM: a negative explicit key is accepted and leaves the counter where it was.
    var
        K1: Integer;
    begin
        Initialize();
        K1 := InsertZero();
        Assert.IsTrue(InsertExplicit(-5), 'a negative explicit key must be accepted');
        Assert.AreEqual(K1 + 1, InsertZero(), 'the next zero-key key must follow the counter, not the negative key');
    end;

    [Test]
    procedure AutoInc_ExplicitKeyRefusedOnUniqueKey_StillRaisesCounter()
    // CLAIM: an Insert with an explicit key that fails on a unique secondary key has still raised the counter to that
    //        key, and the explicit key stays on the record variable (unlike a counter-assigned one).
    var
        U: Record "AutoInc Unique Probe";
        K1: Integer;
    begin
        Initialize();
        U.Code := 'X';
        U.Insert(true);
        K1 := U."Entry No.";
        Clear(U);
        U."Entry No." := K1 + 50;
        U.Code := 'X';
        Assert.IsFalse(U.Insert(true), 'control: the Insert must be refused');
        Assert.AreEqual(K1 + 50, U."Entry No.", 'an explicit key stays on the record after a refused Insert');
        Clear(U);
        U.Code := 'Y';
        Assert.IsTrue(U.Insert(true), 'a row with a new Code must be inserted');
        Assert.AreEqual(K1 + 51, U."Entry No.", 'the counter must have been raised by the refused explicit key');
    end;

    [Test]
    procedure AutoInc_ExplicitKeyRefusedByOnInsert_DoesNotRaiseCounter()
    // CLAIM: an explicit key whose Insert is refused by an error in OnInsert never reaches storage, so it does not
    //        raise the counter. Commit first, so the refusal's rollback has no bearing on the counter.
    var
        P: Record "AutoInc Explicit Probe";
        K1: Integer;
    begin
        Initialize();
        K1 := InsertZero();
        Commit();
        Control.FailInOnInsert();
        P."Entry No." := K1 + 40;
        P.Payload := 'refused';
        asserterror P.Insert(true);
        Assert.ExpectedError('AutoInc probe: OnInsert refused the row');
        Control.Reset();
        Assert.AreEqual(K1 + 1, InsertZero(), 'the refused explicit key must not have raised the counter');
    end;

    local procedure Initialize()
    var
        P: Record "AutoInc Explicit Probe";
        U: Record "AutoInc Unique Probe";
    begin
        P.DeleteAll();
        U.DeleteAll();
        Control.Reset();
    end;

    local procedure InsertZero(): Integer
    var
        P: Record "AutoInc Explicit Probe";
    begin
        P."Entry No." := 0;
        P.Payload := 'zero';
        P.Insert(true);
        exit(P."Entry No.");
    end;

    local procedure TryInsertZero(var KeyValue: Integer): Boolean
    var
        P: Record "AutoInc Explicit Probe";
        Ok: Boolean;
    begin
        P."Entry No." := 0;
        P.Payload := 'zero';
        Ok := P.Insert(true);
        KeyValue := P."Entry No.";
        exit(Ok);
    end;

    local procedure InsertExplicit(KeyValue: Integer): Boolean
    var
        P: Record "AutoInc Explicit Probe";
    begin
        P."Entry No." := KeyValue;
        P.Payload := 'explicit';
        exit(P.Insert(true));
    end;

    // Count plus Get, not a FindSet loop: see AlRunner#5516 (a FindSet after a truncate can lag the inserts).
    // A 0 among the expected keys is not a key: it is skipped.
    local procedure AssertOnlyKeys(Key1: Integer; Key2: Integer; Key3: Integer; Key4: Integer)
    var
        P: Record "AutoInc Explicit Probe";
        Expected: Integer;
    begin
        if Key1 <> 0 then
            Expected += 1;
        if Key2 <> 0 then
            Expected += 1;
        if Key3 <> 0 then
            Expected += 1;
        if Key4 <> 0 then
            Expected += 1;
        Assert.AreEqual(Expected, P.Count(), 'the table must hold exactly the expected rows');
        if Key1 <> 0 then
            Assert.IsTrue(P.Get(Key1), 'key ' + Format(Key1) + ' must be stored');
        if Key2 <> 0 then
            Assert.IsTrue(P.Get(Key2), 'key ' + Format(Key2) + ' must be stored');
        if Key3 <> 0 then
            Assert.IsTrue(P.Get(Key3), 'key ' + Format(Key3) + ' must be stored');
        if Key4 <> 0 then
            Assert.IsTrue(P.Get(Key4), 'key ' + Format(Key4) + ' must be stored');
    end;
}
