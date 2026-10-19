// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoincrement-property
// Scope: in-scope (Cloud-compatible)
// Fixtures used: AutoInc Edge A to H (67825, 67829 to 67832, 67835 to 67837), AutoInc Edge Big (67827),
//                AutoInc Unique Probe (67823, from TestAutoIncrementExplicitKey.Objects.al)
//                -- declared in TestAutoIncrementEdges.Objects.al
// BC versions: 27.0+ (measured on every cloud leg of the corpus matrix)
//
// WHAT THIS PINS. TestAutoIncrementExplicitKey (67822) covers what an AL-assigned key does to the AutoIncrement counter.
// This codeunit covers what a TRANSACTION does to it, and the limits of its type.
//
// The answers were MEASURED by a probe version of this file on the ten cloud legs (identical on all of them) before
// any assertion was written:
//   - A counter value is consumed for good: an Insert refused by an error in OnInsert, then rolled back by asserterror,
//     does not give its key back (DeleteAll shape, and Truncate with a Commit after it). Its row IS rolled back with
//     everything written since the last Commit.
//   - After a Truncate, a rollback to the last Commit brings the rows the Truncate removed back and leaves the counter
//     where it stood before the Truncate, whatever was taken after it. With Truncate(true) that is "the key of the
//     rolled-back Insert is handed out again" when the table had never been used, and "the value after the highest
//     key the counter had reached" when it had. Truncate(false) does not reseed, but its rollback gives the same.
//     Only the shapes are measured here, not the mechanism behind them.
//   - A BigInteger AutoIncrement key past Int32 follows the counter. (An Integer key past Int32 does not wrap: the
//     Insert ends the transaction, and the test fails. No passing test can pin that, so it is not here.)
//   - A Rename is refused when it changes the AutoIncrement value and accepted when it leaves it alone (composite key).
//   - A FindSet after Truncate(true), Insert, Insert lists every row, whichever test ran before (a Count/FindSet
//     disagreement in a test following a passing one is a defect on any tier).
//
// Written for StefanMaron/BusinessCentral.AL.Runner#5522, #5521, #5516 and #5517.

codeunit 67826 "Test AutoInc Counter Edge"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure AutoInc_TruncateTrue_RefusedInsertRolledBack_NextInsertGetsTheKeyAgain()
    // CLAIM: after Truncate(true), a first Insert and an Insert refused by OnInsert (caught by asserterror), the next
    //        Insert gets the key the first one had: the restart is rolled back with the transaction.
    var
        P: Record "AutoInc Edge A";
        K1: Integer;
        K3: Integer;
    begin
        P.Truncate(true);
        Commit();
        P.Truncate(true);
        K1 := ZeroA();
        RefuseA();
        K3 := ZeroA();
        Assert.AreEqual(1, K1, 'Truncate(true) restarts the counter at 1');
        Assert.AreEqual(K1, K3, 'the key of the rolled-back Insert must be handed out again');
        Assert.AreEqual(1, P.Count(), 'only the second Insert survives: the first one is rolled back with the refused one');
        Assert.IsTrue(P.Get(K3), 'the surviving row must be the one with the re-issued key');
    end;

    [Test]
    procedure AutoInc_TruncateTrue_TwoInsertsThenRefusedInsert_RestartIsRolledBackWholesale()
    // CLAIM: the same with two successful Inserts before the refused one: the restart is undone as a whole, not by one.
    var
        P: Record "AutoInc Edge B";
        K1: Integer;
        K2: Integer;
        K4: Integer;
    begin
        P.Truncate(true);
        Commit();
        P.Truncate(true);
        K1 := ZeroB();
        K2 := ZeroB();
        RefuseB();
        K4 := ZeroB();
        Assert.AreEqual(1, K1, 'Truncate(true) restarts the counter at 1');
        Assert.AreEqual(K1 + 1, K2, 'the counter advances between the two Inserts');
        Assert.AreEqual(K1, K4, 'both consumed values are handed out again, starting from the first');
        Assert.AreEqual(1, P.Count(), 'only the last Insert survives');
    end;

    [Test]
    procedure AutoInc_TruncateTrue_CommittedRows_RefusedInsertRolledBack_RestoresRowsAndCounter()
    // CLAIM: Truncate(true) of committed rows, an Insert, and a refused Insert caught by asserterror: the rollback
    //        brings the committed rows back and the counter is where it stood before the Truncate.
    var
        P: Record "AutoInc Edge C";
        C1: Integer;
        C2: Integer;
        C3: Integer;
        W1: Integer;
        W3: Integer;
    begin
        P.Truncate(true);
        C1 := ZeroC();
        C2 := ZeroC();
        C3 := ZeroC();
        Commit();
        P.Truncate(true);
        W1 := ZeroC();
        RefuseC();
        W3 := ZeroC();
        Assert.AreEqual(1, W1, 'Truncate(true) restarts the counter at 1');
        Assert.AreEqual(C3 + 1, W3, 'the counter must be back where it stood before the Truncate, not at the restart');
        Assert.AreEqual(4, P.Count(), 'the three committed rows come back, next to the new one');
        Assert.IsTrue(P.Get(C1) and P.Get(C2) and P.Get(C3) and P.Get(W3), 'every expected key must be stored');
    end;

    [Test]
    procedure AutoInc_TruncateTrue_CommitAfterTheTruncate_RefusedInsertConsumesItsValue()
    // CLAIM: with a Commit between the Truncate(true) and the Inserts, the restart is durable, and the refused
    //        Insert's value is consumed like any other.
    var
        P: Record "AutoInc Edge D";
        K1: Integer;
        K3: Integer;
    begin
        P.Truncate(true);
        Commit();
        K1 := ZeroD();
        RefuseD();
        K3 := ZeroD();
        Assert.AreEqual(K1 + 1, K3, 'the value taken by the first Insert is not handed out again');
        Assert.AreEqual(1, P.Count(), 'only the last Insert survives');
        Assert.IsFalse(P.Get(K1), 'the first Insert is rolled back with the refused one');
    end;

    [Test]
    procedure AutoInc_DeleteAll_RefusedInsertRolledBack_ConsumesItsValueAndRollsBackTheRow()
    // CLAIM: without a Truncate, the Insert before the refused one is rolled back too, and its key is not reused.
    var
        P: Record "AutoInc Edge E";
        K1: Integer;
        K3: Integer;
    begin
        P.DeleteAll();
        K1 := ZeroE();
        RefuseE();
        K3 := ZeroE();
        Assert.AreEqual(K1 + 1, K3, 'the counter must not have been rolled back with the data');
        Assert.AreEqual(1, P.Count(), 'only the last Insert survives');
        Assert.IsFalse(P.Get(K1), 'the first Insert is rolled back with the refused one');
    end;

    [Test]
    procedure AutoInc_TruncateFalse_CommittedRows_RefusedInsertRolledBack_RestoresRowsAndCounter()
    // CLAIM: Truncate(false) does not reseed, but its rollback restores the rows and the counter as well.
    var
        P: Record "AutoInc Edge F";
        C1: Integer;
        C2: Integer;
        W1: Integer;
        W3: Integer;
    begin
        P.DeleteAll();
        C1 := ZeroF();
        C2 := ZeroF();
        Commit();
        P.Truncate(false);
        W1 := ZeroF();
        RefuseF();
        W3 := ZeroF();
        Assert.AreEqual(C2 + 1, W1, 'Truncate(false) does not restart the counter');
        Assert.AreEqual(W1, W3, 'the value taken after the Truncate is handed out again once the transaction rolls back');
        Assert.AreEqual(3, P.Count(), 'the two committed rows come back, next to the new one');
        Assert.IsTrue(P.Get(C1) and P.Get(C2) and P.Get(W3), 'every expected key must be stored');
    end;

    [Test]
    procedure AutoInc_TruncateTrue_DeletedLastRow_RollbackRestoresTheCounterNotTheRowsHighWaterMark()
    // CLAIM: the counter after the rollback is the value it had before the Truncate, not one derived from the rows the
    //        rollback brought back: with the highest key's row deleted before the Truncate, the next key is still the
    //        one after the deleted row's.
    var
        P: Record "AutoInc Edge H";
        C1: Integer;
        C2: Integer;
        C3: Integer;
        W1: Integer;
        W3: Integer;
    begin
        P.Truncate(true);
        C1 := ZeroH();
        C2 := ZeroH();
        C3 := ZeroH();
        P.Get(C3);
        P.Delete();
        Commit();
        P.Truncate(true);
        W1 := ZeroH();
        RefuseH();
        W3 := ZeroH();
        Assert.AreEqual(1, W1, 'Truncate(true) restarts the counter at 1');
        Assert.AreEqual(C3 + 1, W3, 'the counter must be where it stood before the Truncate, which is past the deleted row');
        Assert.AreEqual(3, P.Count(), 'the two committed rows come back, next to the new one');
        Assert.IsTrue(P.Get(C1) and P.Get(C2) and P.Get(W3), 'every expected key must be stored');
    end;

    [Test]
    procedure AutoInc_BigIntegerKey_ExplicitAboveInt32_NextZeroKeysFollowIt()
    // CLAIM: an explicit BigInteger key above Int32.MaxValue raises the counter, and the zero-key Inserts after it
    //        get Big + 1 and Big + 2 (not a key truncated to 32 bits).
    var
        B: Record "AutoInc Edge Big";
        Big: BigInteger;
        Z3: BigInteger;
        Z4: BigInteger;
    begin
        B.DeleteAll();
        Big := 500000000;
        Big := Big * 10;
        B.Payload := 'z1';
        B.Insert(true);
        Clear(B);
        B."Entry No." := Big;
        B.Payload := 'explicit';
        B.Insert(true);
        Clear(B);
        B.Payload := 'z3';
        B.Insert(true);
        Z3 := B."Entry No.";
        Clear(B);
        B.Payload := 'z4';
        B.Insert(true);
        Z4 := B."Entry No.";
        Assert.AreEqual(Big + 1, Z3, 'the next key must follow the explicit BigInteger key');
        Assert.AreEqual(Big + 2, Z4, 'and the counter keeps advancing from there');
        Assert.AreEqual(4, B.Count(), 'all four rows must be stored');
        Assert.IsTrue(B.Get(Big), 'the explicit key must be stored as given');
    end;

    [Test]
    procedure AutoInc_TruncateTrue_ReadInsertRead_ListsEveryRow_FirstTest()
    begin
        TruncateInsertReadInsertRead();
    end;

    [Test]
    procedure AutoInc_TruncateTrue_ReadInsertRead_ListsEveryRow_FollowingTest()
    // CLAIM: the same shape in a test that follows a passing one lists every row too: Count and a FindSet loop agree.
    begin
        TruncateInsertReadInsertRead();
    end;

    local procedure TruncateInsertReadInsertRead()
    var
        P: Record "AutoInc Edge G";
    begin
        P.Truncate(true);
        ZeroG();
        ZeroG();
        ZeroG();
        AssertListedRowsEqual(3);
        ZeroG();
        AssertListedRowsEqual(4);
    end;

    local procedure AssertListedRowsEqual(Expected: Integer)
    var
        P: Record "AutoInc Edge G";
        Listed: Integer;
    begin
        Assert.AreEqual(Expected, P.Count(), 'Count must see every row');
        if P.FindSet() then
            repeat
                Listed += 1;
            until P.Next() = 0;
        Assert.AreEqual(Expected, Listed, 'a FindSet loop must list every row Count sees');
    end;

    [Test]
    procedure AutoInc_UniqueKeyRefusedInsert_UnderAsserterror_LeavesTheKeyZeroOnTheRecord()
    // CLAIM: a zero-key Insert refused on a unique secondary key and NOT trapped by a Boolean receiver leaves the
    //        AutoIncrement field at 0 on the record variable, as the Boolean-receiver form does (codeunit 67822).
    var
        U: Record "AutoInc Unique Probe";
    begin
        U.DeleteAll();
        U.Code := 'X';
        U.Insert(true);
        Clear(U);
        U.Code := 'X';
        asserterror U.Insert(true);
        Assert.ExpectedError('There is already a record in table AutoInc Unique Probe that has the same values in a unique index');
        Assert.AreEqual(0, U."Entry No.", 'the key taken for the refused Insert must not stay on the record');
    end;

    [Test]
    procedure AutoInc_Rename_OfAKeyFieldOtherThanTheAutoIncrementOne_IsAccepted()
    // CLAIM: in a composite key whose first field is the AutoIncrement one, a Rename that leaves that field's value
    //        alone is accepted: only a changed AutoIncrement value is refused.
    var
        C: Record "AutoInc Edge Composite";
        K: Integer;
    begin
        C.DeleteAll();
        C.Code := 'A';
        C.Insert(true);
        K := C."Entry No.";
        C.Get(K, 'A');
        C.Rename(K, 'B');
        Assert.AreEqual('B', C.Code, 'the record variable must carry the new key');
        Assert.AreEqual(K, C."Entry No.", 'the AutoIncrement value must be untouched');
        Assert.IsTrue(C.Get(K, 'B'), 'the row must be stored under the new key');
        Assert.IsFalse(C.Get(K, 'A'), 'and no longer under the old one');
    end;

    [Test]
    procedure AutoInc_Rename_ThatChangesTheAutoIncrementValue_IsRefused()
    // CLAIM: a Rename that changes the AutoIncrement value of a composite key raises the AutoIncrement error, and
    //        the row keeps its key.
    var
        C: Record "AutoInc Edge Composite";
        K: Integer;
    begin
        C.DeleteAll();
        C.Code := 'A';
        C.Insert(true);
        K := C."Entry No.";
        C.Get(K, 'A');
        Commit();
        asserterror C.Rename(K + 50, 'A');
        Assert.ExpectedError('You cannot change the value of an AutoIncrement field.');
        Assert.ExpectedError('Field: Entry No.');
        Assert.ExpectedError('Table: AutoInc Edge Composite');
        Assert.IsTrue(C.Get(K, 'A'), 'the committed row must keep its key');
    end;

    local procedure ZeroA(): Integer
    var
        P: Record "AutoInc Edge A";
    begin
        P."Entry No." := 0;
        P.Payload := 'zero';
        P.Insert(true);
        exit(P."Entry No.");
    end;

    local procedure RefuseA()
    var
        P: Record "AutoInc Edge A";
    begin
        P.Payload := 'refuse';
        asserterror P.Insert(true);
        Assert.ExpectedError('AutoInc edge: OnInsert refused the row');
        Assert.AreEqual(0, P."Entry No.", 'a refused Insert must not leave the key it would have taken on the record');
    end;

    local procedure ZeroB(): Integer
    var
        P: Record "AutoInc Edge B";
    begin
        P."Entry No." := 0;
        P.Payload := 'zero';
        P.Insert(true);
        exit(P."Entry No.");
    end;

    local procedure RefuseB()
    var
        P: Record "AutoInc Edge B";
    begin
        P.Payload := 'refuse';
        asserterror P.Insert(true);
        Assert.ExpectedError('AutoInc edge: OnInsert refused the row');
        Assert.AreEqual(0, P."Entry No.", 'a refused Insert must not leave the key it would have taken on the record');
    end;

    local procedure ZeroC(): Integer
    var
        P: Record "AutoInc Edge C";
    begin
        P."Entry No." := 0;
        P.Payload := 'zero';
        P.Insert(true);
        exit(P."Entry No.");
    end;

    local procedure RefuseC()
    var
        P: Record "AutoInc Edge C";
    begin
        P.Payload := 'refuse';
        asserterror P.Insert(true);
        Assert.ExpectedError('AutoInc edge: OnInsert refused the row');
        Assert.AreEqual(0, P."Entry No.", 'a refused Insert must not leave the key it would have taken on the record');
    end;

    local procedure ZeroD(): Integer
    var
        P: Record "AutoInc Edge D";
    begin
        P."Entry No." := 0;
        P.Payload := 'zero';
        P.Insert(true);
        exit(P."Entry No.");
    end;

    local procedure RefuseD()
    var
        P: Record "AutoInc Edge D";
    begin
        P.Payload := 'refuse';
        asserterror P.Insert(true);
        Assert.ExpectedError('AutoInc edge: OnInsert refused the row');
        Assert.AreEqual(0, P."Entry No.", 'a refused Insert must not leave the key it would have taken on the record');
    end;

    local procedure ZeroE(): Integer
    var
        P: Record "AutoInc Edge E";
    begin
        P."Entry No." := 0;
        P.Payload := 'zero';
        P.Insert(true);
        exit(P."Entry No.");
    end;

    local procedure RefuseE()
    var
        P: Record "AutoInc Edge E";
    begin
        P.Payload := 'refuse';
        asserterror P.Insert(true);
        Assert.ExpectedError('AutoInc edge: OnInsert refused the row');
        Assert.AreEqual(0, P."Entry No.", 'a refused Insert must not leave the key it would have taken on the record');
    end;

    local procedure ZeroF(): Integer
    var
        P: Record "AutoInc Edge F";
    begin
        P."Entry No." := 0;
        P.Payload := 'zero';
        P.Insert(true);
        exit(P."Entry No.");
    end;

    local procedure RefuseF()
    var
        P: Record "AutoInc Edge F";
    begin
        P.Payload := 'refuse';
        asserterror P.Insert(true);
        Assert.ExpectedError('AutoInc edge: OnInsert refused the row');
        Assert.AreEqual(0, P."Entry No.", 'a refused Insert must not leave the key it would have taken on the record');
    end;

    local procedure ZeroG(): Integer
    var
        P: Record "AutoInc Edge G";
    begin
        P."Entry No." := 0;
        P.Payload := 'zero';
        P.Insert(true);
        exit(P."Entry No.");
    end;

    local procedure ZeroH(): Integer
    var
        P: Record "AutoInc Edge H";
    begin
        P."Entry No." := 0;
        P.Payload := 'zero';
        P.Insert(true);
        exit(P."Entry No.");
    end;

    local procedure RefuseH()
    var
        P: Record "AutoInc Edge H";
    begin
        P.Payload := 'refuse';
        asserterror P.Insert(true);
        Assert.ExpectedError('AutoInc edge: OnInsert refused the row');
        Assert.AreEqual(0, P."Entry No.", 'a refused Insert must not leave the key it would have taken on the record');
    end;


    // Corpus issue 668 item 33 (writer BQ): "You cannot change the value of an AutoIncrement field." on Modify (microsoft/AL issue 6934).
    // LT BQ AutoInc Removed has a BigInteger AutoIncrement field marked ObsoleteState = Removed; LT BQ AutoInc Plain has a normal BigInteger
    // AutoIncrement field outside the key (record/lt-bq-odd-leads/BqObjects.al). Each case is a test of its own: its error, if any, is the
    // result.
    local procedure BqSeedAutoIncPlain()
    var
        P: Record "LT BQ AutoInc Plain";
    begin
        P.DeleteAll();
        P.Init();
        P.Id := 1;
        P.Name := 'one';
        P.Insert();
        P.Init();
        P.Id := 2;
        P.Name := 'two';
        P.Insert();
    end;

    [Test]
    procedure AutoInc_RemovedField_InsertAndModify_BQ()
    var
        R: Record "LT BQ AutoInc Removed";
        Observer: Codeunit "Probe Observer";
    begin
        R.DeleteAll();
        R.Init();
        R.Id := 1;
        R.Name := 'a';
        R.Insert();
        Observer.Observe('insert', 'no error');
        R.Get(1);
        R.Name := 'b';
        R.Modify();
        Observer.Observe('modify', 'no error');
        R.ModifyAll(Name, 'c');
        Observer.Observe('modifyAll', 'no error');
        R.Get(1);
        Observer.Observe('name', R.Name);
        Observer.Expect('insert', 'no error');
        Observer.Expect('modify', 'no error');
        Observer.Expect('modifyAll', 'no error');
        Observer.Expect('name', 'c');
        Observer.Verify();
    end;

    [Test]
    procedure AutoInc_NonKeyField_ModifyUnchangedAndOtherField_BQ()
    var
        P: Record "LT BQ AutoInc Plain";
        Copied: Record "LT BQ AutoInc Plain";
        Observer: Codeunit "Probe Observer";
    begin
        BqSeedAutoIncPlain();
        P.Get(1);
        Observer.Observe('seqAssigned', Format(P.Seq > 0));
        P.Modify();
        Observer.Observe('modifyUnchanged', 'no error');
        P.Name := 'uno';
        P.Modify();
        Observer.Observe('modifyOtherField', 'no error');
        P.Get(1);
        Copied := P;
        Copied.Name := 'copied';
        Copied.Modify();
        Observer.Observe('modifyAssignedCopy', 'no error');
        Observer.Expect('seqAssigned', 'Yes');
        Observer.Expect('modifyUnchanged', 'no error');
        Observer.Expect('modifyOtherField', 'no error');
        Observer.Expect('modifyAssignedCopy', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure AutoInc_NonKeyField_ModifyChangedValue_BQ()
    var
        P: Record "LT BQ AutoInc Plain";
        Observer: Codeunit "Probe Observer";
    begin
        BqSeedAutoIncPlain();
        P.Get(1);
        P.Seq := P.Seq + 1000;
        asserterror P.Modify();
        Observer.Observe('text', GetLastErrorText().Replace(Format(P.Seq), '<seq>'));
        Observer.Observe('code', GetLastErrorCode());
        Observer.Expect('text', 'You cannot change the value of an AutoIncrement field.\\Field: Seq\Table: LT BQ AutoInc Plain\\Identification fields and values:\Id=''1''');
        Observer.Expect('code', 'DB:ModifyOnIdentityField');
        Observer.Verify();
    end;

    [Test]
    procedure AutoInc_NonKeyField_ModifyAll_BQ()
    var
        P: Record "LT BQ AutoInc Plain";
        Observer: Codeunit "Probe Observer";
    begin
        BqSeedAutoIncPlain();
        asserterror P.ModifyAll(Seq, 99999);
        Observer.ObserveError('modifyAll');
        Observer.Finish();
    end;

    [Test]
    procedure AutoInc_NonKeyField_TransferFieldsFromAnotherRow_BQ()
    var
        P: Record "LT BQ AutoInc Plain";
        Other: Record "LT BQ AutoInc Plain";
        Observer: Codeunit "Probe Observer";
    begin
        BqSeedAutoIncPlain();
        P.Get(1);
        Other.Get(2);
        P.TransferFields(Other, false);
        Observer.Observe('seqTaken', Format(P.Seq = Other.Seq));
        asserterror P.Modify();
        Observer.ObserveError('modify');
        Observer.Finish();
    end;
}
