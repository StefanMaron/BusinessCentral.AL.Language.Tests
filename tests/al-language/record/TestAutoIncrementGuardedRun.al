// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: GuardRun Probe A to D, F to I, K and M (67840 to 67843, 67845 to 67848, 67850, 67855) and the
//                failing codeunits GuardRun Inner A to D, F to I, K, M and GuardRun Outer H, I, M -- declared in
//                TestAutoIncrementGuardedRun.Objects.al
// BC versions: 27.0+ (measured on every cloud leg of the corpus matrix and on the Windows nightly)
//
// WHAT THIS PINS. TestAutoIncrementEdges (67826) covers what a rollback to the last Commit does to an AutoIncrement
// counter after a Truncate. This codeunit covers the other way a transaction ends: a guarded Codeunit.Run (the call
// used in an if, or its result captured) that fails after it wrote.
//
// The answers were MEASURED by a probe version of this file (corpus PR 568) before any assertion was written, on the
// ten cloud legs and the Windows nightly:
//   - A failed guarded run is rolled back as a whole: the rows it removed with Truncate(true), Truncate(false) or
//     DeleteAll come back, the rows it inserted go.
//   - After a Truncate inside it, the counter is where it stood before the Truncate, whether or not the Truncate
//     restarted it: the failed run's Insert took 4, and the caller's next Insert gets 4 again. It is the value the
//     counter had, not one derived from the rows that came back (row 3 deleted before the run: the next key is 4).
//   - Without a Truncate (a plain Insert, or DeleteAll then Insert) the value the failed run took is consumed: the
//     caller's next Insert gets 5.
//   - Nested: an inner failing run that truncated is restored the same way before the outer run continues, and a
//     value the outer run takes afterwards is consumed like any other if the outer run fails too.
//   - An inner run that SUCCEEDS (Truncate(true), Insert) is as durable as a Commit: when the outer run then fails, the
//     inner run's row stays, the outer run's own Insert goes, and the value the outer run took is consumed (corpus PR
//     568's probe M, ten cloud legs).
//
// Not here: a guarded run started while the caller still has an uncommitted write (a Truncate included) is refused
// by BC with "An error occurred and the transaction is stopped"; that is the write-transaction check, not the counter.
//
// Written for StefanMaron/BusinessCentral.AL.Runner#5527.

codeunit 67840 "Test AutoInc Guarded Run"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure AutoInc_GuardedRun_TruncateTrueThenError_RowsAndCounterComeBack()
    // CLAIM: a guarded run that does Truncate(true), Insert and Error leaves the committed rows and the counter where they were: the caller's next Insert gets 4.
    var
        R: Record "GuardRun Probe A";
        Ok: Boolean;
        C3: Integer;
        Next: Integer;
    begin
        R.Truncate(true);
        ZeroA();
        ZeroA();
        C3 := ZeroA();
        Commit();
        Ok := Codeunit.Run(Codeunit::"GuardRun Inner A");
        Assert.AreEqual(false, Ok, 'the guarded run must report failure');
        Next := ZeroNextA();
        Assert.AreEqual(C3 + 1, Next, 'the counter is back where it stood before the Truncate, not at the restart');
        Assert.AreEqual(4, R.Count(), 'the stored rows');
        Assert.IsTrue(R.Get(1), 'row 1 is back');
        Assert.IsTrue(R.Get(2), 'row 2 is back');
        Assert.IsTrue(R.Get(C3), 'row 3 is back');
        Assert.IsTrue(R.Get(Next), 'the callers own Insert is stored');
    end;

    [Test]
    procedure AutoInc_GuardedRun_TruncateFalseThenError_RowsAndCounterComeBack()
    // CLAIM: the same with Truncate(false): the Insert inside the failed run took 4 and the caller's next Insert gets it again.
    var
        R: Record "GuardRun Probe B";
        Ok: Boolean;
        C3: Integer;
        Next: Integer;
    begin
        R.Truncate(true);
        ZeroB();
        ZeroB();
        C3 := ZeroB();
        Commit();
        Ok := Codeunit.Run(Codeunit::"GuardRun Inner B");
        Assert.AreEqual(false, Ok, 'the guarded run must report failure');
        Next := ZeroNextB();
        Assert.AreEqual(C3 + 1, Next, 'the value the failed run took is handed out again');
        Assert.AreEqual(4, R.Count(), 'the stored rows');
        Assert.IsTrue(R.Get(1), 'row 1 is back');
        Assert.IsTrue(R.Get(C3), 'row 3 is back');
        Assert.IsTrue(R.Get(Next), 'the callers own Insert is stored');
    end;

    [Test]
    procedure AutoInc_GuardedRun_PlainInsertThenError_TheValueIsConsumed()
    // CLAIM: control, no Truncate: a guarded run that Inserts and fails rolls its row back but does not give its value back.
    var
        R: Record "GuardRun Probe C";
        Ok: Boolean;
        C3: Integer;
        Next: Integer;
    begin
        R.Truncate(true);
        ZeroC();
        ZeroC();
        C3 := ZeroC();
        Commit();
        Ok := Codeunit.Run(Codeunit::"GuardRun Inner C");
        Assert.AreEqual(false, Ok, 'the guarded run must report failure');
        Next := ZeroNextC();
        Assert.AreEqual(C3 + 2, Next, 'the value the failed run took is consumed');
        Assert.AreEqual(4, R.Count(), 'the stored rows');
        Assert.IsTrue(R.Get(1), 'row 1 survives');
        Assert.IsTrue(R.Get(C3), 'row 3 survives');
        Assert.IsFalse(R.Get(C3 + 1), 'the failed runs row is rolled back');
        Assert.IsTrue(R.Get(Next), 'the callers own Insert is stored');
    end;

    [Test]
    procedure AutoInc_GuardedRun_DeleteAllThenError_TheValueIsConsumed()
    // CLAIM: control for the Truncate shapes: DeleteAll, Insert and Error in a guarded run brings the rows back and consumes the value.
    var
        R: Record "GuardRun Probe D";
        Ok: Boolean;
        C3: Integer;
        Next: Integer;
    begin
        R.Truncate(true);
        ZeroD();
        ZeroD();
        C3 := ZeroD();
        Commit();
        Ok := Codeunit.Run(Codeunit::"GuardRun Inner D");
        Assert.AreEqual(false, Ok, 'the guarded run must report failure');
        Next := ZeroNextD();
        Assert.AreEqual(C3 + 2, Next, 'the value the failed run took is consumed');
        Assert.AreEqual(4, R.Count(), 'the stored rows');
        Assert.IsTrue(R.Get(1), 'row 1 is back');
        Assert.IsTrue(R.Get(C3), 'row 3 is back');
        Assert.IsFalse(R.Get(C3 + 1), 'the failed runs row is rolled back');
    end;

    [Test]
    procedure AutoInc_GuardedRun_TruncateTrueThenError_DeletedLastRow_CounterIsNotTheRowsHighWaterMark()
    // CLAIM: the counter comes back as it stood, not as the highest stored key: with row 3 deleted and committed before the run, the next Insert gets 4, not 3.
    var
        R: Record "GuardRun Probe F";
        Ok: Boolean;
        C3: Integer;
        Next: Integer;
    begin
        R.Truncate(true);
        ZeroF();
        ZeroF();
        C3 := ZeroF();
        R.Get(C3);
        R.Delete();
        Commit();
        Ok := Codeunit.Run(Codeunit::"GuardRun Inner F");
        Assert.AreEqual(false, Ok, 'the guarded run must report failure');
        Next := ZeroNextF();
        Assert.AreEqual(C3 + 1, Next, 'the counter is where it stood before the Truncate, which is past the deleted row');
        Assert.AreEqual(3, R.Count(), 'the stored rows');
        Assert.IsTrue(R.Get(1), 'row 1 is back');
        Assert.IsTrue(R.Get(2), 'row 2 is back');
        Assert.IsFalse(R.Get(C3), 'the deleted row stays deleted');
        Assert.IsTrue(R.Get(Next), 'the callers own Insert is stored');
    end;

    [Test]
    procedure AutoInc_GuardedRun_TruncateTrueThenError_NeverUsedTable_CounterIsUnstarted()
    // CLAIM: a table nobody has taken a value from: the failed run's Insert took 1, and the caller's next Insert gets 1.
    var
        R: Record "GuardRun Probe G";
        Ok: Boolean;
        C3: Integer;
        Next: Integer;
    begin
        R.Truncate(true);
        Commit();
        Ok := Codeunit.Run(Codeunit::"GuardRun Inner G");
        Assert.AreEqual(false, Ok, 'the guarded run must report failure');
        Next := ZeroNextG();
        Assert.AreEqual(1, Next, 'the value the failed run took is handed out again');
        Assert.AreEqual(1, R.Count(), 'the stored rows');
        Assert.IsTrue(R.Get(Next), 'the callers own Insert is stored');
    end;

    [Test]
    procedure AutoInc_GuardedRun_NestedInnerFails_OuterSucceeds_InnerRestoredTheCounter()
    // CLAIM: an outer run swallows a failing inner run that truncated, then Inserts and succeeds: the outer's Insert gets 4 and the caller's next 5.
    var
        R: Record "GuardRun Probe H";
        Ok: Boolean;
        C3: Integer;
        Next: Integer;
    begin
        R.Truncate(true);
        ZeroH();
        ZeroH();
        C3 := ZeroH();
        Commit();
        Ok := Codeunit.Run(Codeunit::"GuardRun Outer H");
        Assert.AreEqual(true, Ok, 'the guarded run must report success');
        Next := ZeroNextH();
        Assert.AreEqual(C3 + 2, Next, 'the outer run took C3 + 1 after the inner rollback; the caller gets the next one');
        Assert.AreEqual(5, R.Count(), 'the stored rows');
        Assert.IsTrue(R.Get(1), 'row 1 is back');
        Assert.IsTrue(R.Get(C3), 'row 3 is back');
        Assert.IsTrue(R.Get(C3 + 1), 'the outer runs Insert survives');
        Assert.IsTrue(R.Get(Next), 'the callers own Insert is stored');
    end;

    [Test]
    procedure AutoInc_GuardedRun_NestedInnerFails_OuterFails_OnlyTheInnerTruncateIsRestored()
    // CLAIM: an outer run swallows a failing inner run that truncated, Inserts and then fails: the outer's value 4 is consumed, the caller's next Insert gets 5, and the committed rows are there.
    var
        R: Record "GuardRun Probe I";
        Ok: Boolean;
        C3: Integer;
        Next: Integer;
    begin
        R.Truncate(true);
        ZeroI();
        ZeroI();
        C3 := ZeroI();
        Commit();
        Ok := Codeunit.Run(Codeunit::"GuardRun Outer I");
        Assert.AreEqual(false, Ok, 'the guarded run must report failure');
        Next := ZeroNextI();
        Assert.AreEqual(C3 + 2, Next, 'the outer run took C3 + 1, which is consumed');
        Assert.AreEqual(4, R.Count(), 'the stored rows');
        Assert.IsTrue(R.Get(1), 'row 1 is back');
        Assert.IsTrue(R.Get(C3), 'row 3 is back');
        Assert.IsFalse(R.Get(C3 + 1), 'the outer runs row is rolled back');
        Assert.IsTrue(R.Get(Next), 'the callers own Insert is stored');
    end;

    [Test]
    procedure AutoInc_GuardedRun_NestedInnerSucceeds_OuterFails_TheInnerRunIsDurable()
    // CLAIM: an outer run that first runs a guarded inner run that truncates and Inserts (and succeeds), then Inserts and fails: the inner run's result stays, only the outer's own Insert goes, and the value the outer took is consumed.
    var
        R: Record "GuardRun Probe M";
        Ok: Boolean;
        Next: Integer;
    begin
        R.Truncate(true);
        ZeroM();
        ZeroM();
        ZeroM();
        Commit();
        Ok := Codeunit.Run(Codeunit::"GuardRun Outer M");
        Assert.AreEqual(false, Ok, 'the outer run must report failure');
        Next := ZeroNextM();
        Assert.AreEqual(3, Next, 'the inner run restarted the counter and took 1, the outer run took 2, which is consumed');
        Assert.AreEqual(2, R.Count(), 'the inner run''s row and the callers own');
        Assert.IsTrue(R.Get(1), 'the inner run''s row stays');
        Assert.AreEqual('inner', R.Payload, 'row 1 is the inner run''s, the caller''s old row 1 is gone');
        Assert.IsFalse(R.Get(2), 'the outer run''s Insert is rolled back');
        Assert.IsTrue(R.Get(Next), 'the callers own Insert is stored');
    end;

    [Test]
    procedure AutoInc_GuardedRun_TruncateTrueThenError_CallerNeverTruncates_RowsAndCounterComeBack()
    // CLAIM: control for the caller's Truncate(true): the caller primes with DeleteAll, and the same shape as the first test gives the same answer.
    var
        R: Record "GuardRun Probe K";
        Ok: Boolean;
        C3: Integer;
        Next: Integer;
    begin
        R.DeleteAll();
        ZeroK();
        ZeroK();
        C3 := ZeroK();
        Commit();
        Ok := Codeunit.Run(Codeunit::"GuardRun Inner K");
        Assert.AreEqual(false, Ok, 'the guarded run must report failure');
        Next := ZeroNextK();
        Assert.AreEqual(C3 + 1, Next, 'the counter is back where it stood before the Truncate');
        Assert.AreEqual(4, R.Count(), 'the stored rows');
        Assert.IsTrue(R.Get(1), 'row 1 is back');
        Assert.IsTrue(R.Get(C3), 'row 3 is back');
        Assert.IsTrue(R.Get(Next), 'the callers own Insert is stored');
    end;

    local procedure ZeroA(): Integer
    var
        R: Record "GuardRun Probe A";
    begin
        R."Entry No." := 0;
        R.Payload := 'zero';
        R.Insert(true);
        exit(R."Entry No.");
    end;

    local procedure ZeroNextA(): Integer
    var
        R: Record "GuardRun Probe A";
    begin
        R."Entry No." := 0;
        R.Payload := 'next';
        Assert.IsTrue(R.Insert(true), 'the caller''s next Insert must be accepted');
        exit(R."Entry No.");
    end;

    local procedure ZeroB(): Integer
    var
        R: Record "GuardRun Probe B";
    begin
        R."Entry No." := 0;
        R.Payload := 'zero';
        R.Insert(true);
        exit(R."Entry No.");
    end;

    local procedure ZeroNextB(): Integer
    var
        R: Record "GuardRun Probe B";
    begin
        R."Entry No." := 0;
        R.Payload := 'next';
        Assert.IsTrue(R.Insert(true), 'the caller''s next Insert must be accepted');
        exit(R."Entry No.");
    end;

    local procedure ZeroC(): Integer
    var
        R: Record "GuardRun Probe C";
    begin
        R."Entry No." := 0;
        R.Payload := 'zero';
        R.Insert(true);
        exit(R."Entry No.");
    end;

    local procedure ZeroNextC(): Integer
    var
        R: Record "GuardRun Probe C";
    begin
        R."Entry No." := 0;
        R.Payload := 'next';
        Assert.IsTrue(R.Insert(true), 'the caller''s next Insert must be accepted');
        exit(R."Entry No.");
    end;

    local procedure ZeroD(): Integer
    var
        R: Record "GuardRun Probe D";
    begin
        R."Entry No." := 0;
        R.Payload := 'zero';
        R.Insert(true);
        exit(R."Entry No.");
    end;

    local procedure ZeroNextD(): Integer
    var
        R: Record "GuardRun Probe D";
    begin
        R."Entry No." := 0;
        R.Payload := 'next';
        Assert.IsTrue(R.Insert(true), 'the caller''s next Insert must be accepted');
        exit(R."Entry No.");
    end;

    local procedure ZeroF(): Integer
    var
        R: Record "GuardRun Probe F";
    begin
        R."Entry No." := 0;
        R.Payload := 'zero';
        R.Insert(true);
        exit(R."Entry No.");
    end;

    local procedure ZeroNextF(): Integer
    var
        R: Record "GuardRun Probe F";
    begin
        R."Entry No." := 0;
        R.Payload := 'next';
        Assert.IsTrue(R.Insert(true), 'the caller''s next Insert must be accepted');
        exit(R."Entry No.");
    end;

    local procedure ZeroG(): Integer
    var
        R: Record "GuardRun Probe G";
    begin
        R."Entry No." := 0;
        R.Payload := 'zero';
        R.Insert(true);
        exit(R."Entry No.");
    end;

    local procedure ZeroNextG(): Integer
    var
        R: Record "GuardRun Probe G";
    begin
        R."Entry No." := 0;
        R.Payload := 'next';
        Assert.IsTrue(R.Insert(true), 'the caller''s next Insert must be accepted');
        exit(R."Entry No.");
    end;

    local procedure ZeroH(): Integer
    var
        R: Record "GuardRun Probe H";
    begin
        R."Entry No." := 0;
        R.Payload := 'zero';
        R.Insert(true);
        exit(R."Entry No.");
    end;

    local procedure ZeroNextH(): Integer
    var
        R: Record "GuardRun Probe H";
    begin
        R."Entry No." := 0;
        R.Payload := 'next';
        Assert.IsTrue(R.Insert(true), 'the caller''s next Insert must be accepted');
        exit(R."Entry No.");
    end;

    local procedure ZeroI(): Integer
    var
        R: Record "GuardRun Probe I";
    begin
        R."Entry No." := 0;
        R.Payload := 'zero';
        R.Insert(true);
        exit(R."Entry No.");
    end;

    local procedure ZeroNextI(): Integer
    var
        R: Record "GuardRun Probe I";
    begin
        R."Entry No." := 0;
        R.Payload := 'next';
        Assert.IsTrue(R.Insert(true), 'the caller''s next Insert must be accepted');
        exit(R."Entry No.");
    end;

    local procedure ZeroM(): Integer
    var
        R: Record "GuardRun Probe M";
    begin
        R."Entry No." := 0;
        R.Payload := 'zero';
        R.Insert(true);
        exit(R."Entry No.");
    end;

    local procedure ZeroNextM(): Integer
    var
        R: Record "GuardRun Probe M";
    begin
        R."Entry No." := 0;
        R.Payload := 'next';
        Assert.IsTrue(R.Insert(true), 'the caller''s next Insert must be accepted');
        exit(R."Entry No.");
    end;

    local procedure ZeroK(): Integer
    var
        R: Record "GuardRun Probe K";
    begin
        R."Entry No." := 0;
        R.Payload := 'zero';
        R.Insert(true);
        exit(R."Entry No.");
    end;

    local procedure ZeroNextK(): Integer
    var
        R: Record "GuardRun Probe K";
    begin
        R."Entry No." := 0;
        R.Payload := 'next';
        Assert.IsTrue(R.Insert(true), 'the caller''s next Insert must be accepted');
        exit(R."Entry No.");
    end;
}
