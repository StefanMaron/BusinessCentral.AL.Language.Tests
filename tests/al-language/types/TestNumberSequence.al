// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/
//   dev-itpro/developer/methods-auto/numbersequence/numbersequence-data-type
// Scope: in-scope (Cloud-compatible)
// Fixtures used: none — NumberSequence is a static system type, not a table
// BC versions: 27.5+
//
// CLAIM OF THIS FILE: every NumberSequence failure mode raises a TRAPPABLE AL error.
// The Base App depends on that. Codeunit "Sequence No. Mgt." wraps NumberSequence
// Current, Next and Range in [TryFunction]s and creates the sequence when one of them
// returns false, and the No. Series code does the same for a sequence-backed
// No. Series Line. If any of these errors were untrappable, those [TryFunction]s would
// abort instead of returning false and the Base App would never reach the code that
// creates the missing sequence.

codeunit 60640 "Test NumberSequence"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        MissingSeqNameTok: Label 'ALTSeqMissing', Locked = true;
        SeqNameTok: Label 'ALTSeqPresent', Locked = true;

    // ── NumberSequence.Exists ────────────────────────────────────────────────

    [Test]
    procedure NumberSequence_Exists_Missing_ReturnsFalse()
    // CLAIM: Exists() answers false for a sequence that was never inserted. It does
    // not error.
    begin
        Initialize();

        Assert.IsFalse(NumberSequence.Exists(MissingSeqNameTok), 'Exists must be false for a sequence that does not exist');
    end;

    [Test]
    procedure NumberSequence_Exists_AfterInsert_ReturnsTrue()
    // CLAIM: Exists() answers true once the sequence has been inserted.
    begin
        Initialize();

        NumberSequence.Insert(SeqNameTok, 100, 1, true);

        Assert.IsTrue(NumberSequence.Exists(SeqNameTok), 'Exists must be true after Insert');
    end;

    // ── NumberSequence.Current ───────────────────────────────────────────────

    [Test]
    procedure NumberSequence_Current_AfterInsert_ReturnsSeed()
    // CLAIM: Current() on a freshly inserted sequence returns the seed it was created
    // with — a concrete, non-default value.
    var
        CurrentNo: BigInteger;
    begin
        Initialize();

        NumberSequence.Insert(SeqNameTok, 100, 1, true);
        CurrentNo := NumberSequence.Current(SeqNameTok);

        Assert.AreEqual(100, CurrentNo, 'Current must return the seed the sequence was created with');
    end;

    [Test]
    procedure NumberSequence_Current_Missing_TryFunction_ReturnsFalse()
    // CLAIM: Current() on a missing sequence raises a TRAPPABLE error. A [TryFunction]
    // around it returns false and execution continues in the caller.
    var
        CurrentNo: BigInteger;
    begin
        Initialize();

        Assert.IsFalse(TryCurrent(MissingSeqNameTok, CurrentNo), 'A [TryFunction] calling Current on a missing sequence must return false, not abort');
        Assert.IsSubstring(GetLastErrorText(), MissingSeqNameTok);
    end;

    [Test]
    procedure NumberSequence_Current_Missing_Throws()
    // CLAIM: the same call outside a [TryFunction] errors, and the error text names the
    // sequence that was asked for.
    var
        CurrentNo: BigInteger;
    begin
        Initialize();

        asserterror CurrentNo := NumberSequence.Current(MissingSeqNameTok);

        Assert.IsSubstring(GetLastErrorText(), MissingSeqNameTok);
    end;

    // ── NumberSequence.Next ──────────────────────────────────────────────────

    [Test]
    procedure NumberSequence_Next_AfterInsert_ReturnsSeedThenIncrements()
    // CLAIM: the first Next() on a freshly inserted sequence returns the seed, and the
    // second returns seed + increment.
    var
        First: BigInteger;
        Second: BigInteger;
    begin
        Initialize();

        NumberSequence.Insert(SeqNameTok, 100, 5, true);
        First := NumberSequence.Next(SeqNameTok);
        Second := NumberSequence.Next(SeqNameTok);

        Assert.AreEqual(100, First, 'The first Next must return the seed');
        Assert.AreEqual(105, Second, 'The second Next must return seed + increment');
    end;

    [Test]
    procedure NumberSequence_Next_Missing_TryFunction_ReturnsFalse()
    // CLAIM: Next() on a missing sequence raises a TRAPPABLE error.
    var
        NextNo: BigInteger;
    begin
        Initialize();

        Assert.IsFalse(TryNext(MissingSeqNameTok, NextNo), 'A [TryFunction] calling Next on a missing sequence must return false, not abort');
        Assert.IsSubstring(GetLastErrorText(), MissingSeqNameTok);
    end;

    // ── NumberSequence.Range ─────────────────────────────────────────────────

    [Test]
    procedure NumberSequence_Range_AfterInsert_ReservesCount()
    // CLAIM: Range() returns the first number of the reserved block, and the next
    // allocation continues after the whole block.
    var
        FirstOfRange: BigInteger;
        AfterRange: BigInteger;
    begin
        Initialize();

        NumberSequence.Insert(SeqNameTok, 100, 1, true);
        FirstOfRange := NumberSequence.Range(SeqNameTok, 3);
        AfterRange := NumberSequence.Next(SeqNameTok);

        Assert.AreEqual(100, FirstOfRange, 'Range must return the first number of the reserved block');
        Assert.AreEqual(103, AfterRange, 'The allocation after a 3-wide range must skip the whole block');
    end;

    [Test]
    procedure NumberSequence_Range_Missing_TryFunction_ReturnsFalse()
    // CLAIM: Range() on a missing sequence raises a TRAPPABLE error.
    var
        FirstOfRange: BigInteger;
    begin
        Initialize();

        Assert.IsFalse(TryRange(MissingSeqNameTok, 3, FirstOfRange), 'A [TryFunction] calling Range on a missing sequence must return false, not abort');
        Assert.IsSubstring(GetLastErrorText(), MissingSeqNameTok);
    end;

    // ── NumberSequence.Restart ───────────────────────────────────────────────

    [Test]
    procedure NumberSequence_Restart_ResetsCurrentToNewSeed()
    // CLAIM: Restart() sets the sequence back to a new seed.
    var
        CurrentNo: BigInteger;
        Consumed: BigInteger;
    begin
        Initialize();

        NumberSequence.Insert(SeqNameTok, 100, 1, true);
        Consumed := NumberSequence.Next(SeqNameTok);
        Consumed := NumberSequence.Next(SeqNameTok);
        Assert.AreEqual(101, Consumed, 'Two allocations from seed 100 with increment 1 must land on 101');
        NumberSequence.Restart(SeqNameTok, 500);
        CurrentNo := NumberSequence.Current(SeqNameTok);

        Assert.AreEqual(500, CurrentNo, 'Current must report the seed Restart was given');
    end;

    [Test]
    procedure NumberSequence_Restart_Missing_TryFunction_ReturnsFalse()
    // CLAIM: Restart() on a missing sequence raises a TRAPPABLE error.
    begin
        Initialize();

        Assert.IsFalse(TryRestart(MissingSeqNameTok, 1), 'A [TryFunction] calling Restart on a missing sequence must return false, not abort');
        Assert.IsSubstring(GetLastErrorText(), MissingSeqNameTok);
    end;

    // ── NumberSequence.Insert ────────────────────────────────────────────────

    [Test]
    procedure NumberSequence_Insert_Duplicate_TryFunction_ReturnsFalse()
    // CLAIM: inserting a sequence that already exists raises a TRAPPABLE error.
    begin
        Initialize();

        NumberSequence.Insert(SeqNameTok, 100, 1, true);

        Assert.IsFalse(TryInsert(SeqNameTok, 100, 1), 'A [TryFunction] inserting a duplicate sequence must return false, not abort');
        Assert.IsSubstring(GetLastErrorText(), SeqNameTok);
    end;

    // ── NumberSequence.Delete ────────────────────────────────────────────────

    [Test]
    procedure NumberSequence_Delete_RemovesSequence()
    // CLAIM: Delete() removes the sequence, so Exists() goes back to false.
    begin
        Initialize();

        NumberSequence.Insert(SeqNameTok, 100, 1, true);
        NumberSequence.Delete(SeqNameTok);

        Assert.IsFalse(NumberSequence.Exists(SeqNameTok), 'Exists must be false after Delete');
    end;

    [Test]
    procedure NumberSequence_Delete_Missing_TryFunction_ReturnsTrue()
    // CLAIM: deleting a sequence that does not exist is a no-op, not an error.
    begin
        Initialize();

        Assert.IsTrue(TryDelete(MissingSeqNameTok), 'Deleting a sequence that does not exist must succeed');
        Assert.IsFalse(NumberSequence.Exists(MissingSeqNameTok), 'The sequence must still not exist afterwards');
    end;

    // ── helpers ──────────────────────────────────────────────────────────────

    [TryFunction]
    local procedure TryCurrent(SequenceName: Text; var CurrentNo: BigInteger)
    begin
        CurrentNo := NumberSequence.Current(SequenceName);
    end;

    [TryFunction]
    local procedure TryNext(SequenceName: Text; var NextNo: BigInteger)
    begin
        NextNo := NumberSequence.Next(SequenceName);
    end;

    [TryFunction]
    local procedure TryRange(SequenceName: Text; RangeSize: Integer; var FirstOfRange: BigInteger)
    begin
        FirstOfRange := NumberSequence.Range(SequenceName, RangeSize);
    end;

    [TryFunction]
    local procedure TryRestart(SequenceName: Text; Seed: BigInteger)
    begin
        NumberSequence.Restart(SequenceName, Seed);
    end;

    [TryFunction]
    local procedure TryInsert(SequenceName: Text; Seed: BigInteger; Increment: BigInteger)
    begin
        NumberSequence.Insert(SequenceName, Seed, Increment, true);
    end;

    [TryFunction]
    local procedure TryDelete(SequenceName: Text)
    begin
        NumberSequence.Delete(SequenceName);
    end;

    local procedure Initialize()
    begin
        // Number sequences are database objects, not rows, so one created by a test
        // outlives that test. Drop both names this codeunit uses before every test.
        if NumberSequence.Exists(SeqNameTok) then
            NumberSequence.Delete(SeqNameTok);
        if NumberSequence.Exists(MissingSeqNameTok) then
            NumberSequence.Delete(MissingSeqNameTok);
    end;
}
