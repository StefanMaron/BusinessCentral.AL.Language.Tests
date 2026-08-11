// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-error-handling
// Scope: in-scope
// Fixtures used: ALT Universal (60000, database-backed), ALT Temp Only (60025, TableType=Temporary)
//
// Pins down what asserterror rolls back when the error is UNRELATED to the write that
// preceded it — i.e. not a trigger firing on the write itself (TestTriggerRollback.al covers
// that shape), but a plain Error() raised by later, separate statements.
//
// The trigger already discovered this once, incidentally: CFV Tests (60942) originally
// asserted against fixture rows seeded by its own Initialize() right after an unrelated
// asserterror and failed on real BC 27.5/28.3, because the error rolled the write
// transaction back PAST that Initialize() call to the last Commit() (session start, since
// none had been issued). This suite isolates that mechanism on its own:
//   - does an uncommitted write survive an unrelated asserterror? (no)
//   - does Commit() move the surviving boundary forward? (yes — only writes since the last
//     Commit() are undone)
//   - do temporary-table writes participate in that rollback at all? (no — TableType=Temporary
//     has no database backing, so there is nothing for the SQL transaction to undo)
codeunit 60943 "Test AssertError Rollback"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Record_Insert_UnrelatedAssertError_NoCommit_RowIsRolledBack()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        Rec."Entry No." := 1;
        Rec.Insert(false);
        Assert.AreEqual(1, Rec.Count(), 'row must exist immediately after Insert, before the unrelated error');

        asserterror Error('unrelated error, nothing to do with the row above');
        Assert.ExpectedError('unrelated error, nothing to do with the row above');

        Assert.AreEqual(0, Rec.Count(),
            'an unrelated asserterror with no intervening Commit() must roll back the uncommitted Insert');
    end;

    [Test]
    procedure Record_Insert_Commit_UnrelatedAssertError_RowSurvives()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        Rec."Entry No." := 1;
        Rec.Insert(false);
        Commit();

        asserterror Error('unrelated error after the commit');
        Assert.ExpectedError('unrelated error after the commit');

        Assert.AreEqual(1, Rec.Count(),
            'a Commit() before the error must make the Insert durable — the rollback boundary moves to the Commit(), not further back');
    end;

    [Test]
    procedure Record_Insert_Commit_SecondInsert_UnrelatedAssertError_OnlyUncommittedRowRolledBack()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        Rec."Entry No." := 1;
        Rec.Insert(false);
        Commit();

        Rec."Entry No." := 2;
        Rec.Insert(false);
        Assert.AreEqual(2, Rec.Count(), 'both rows must exist immediately after the second Insert');

        asserterror Error('unrelated error after the second, uncommitted insert');
        Assert.ExpectedError('unrelated error after the second, uncommitted insert');

        Assert.IsTrue(Rec.Get(1), 'the row committed before the error must survive');
        Assert.IsFalse(Rec.Get(2), 'the row inserted after the last Commit() must be rolled back by the unrelated error');
        Assert.AreEqual(1, Rec.Count(), 'only the committed row must remain');
    end;

    [Test]
    procedure Record_Modify_UnrelatedAssertError_NoCommit_ChangeIsRolledBack()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        Rec."Entry No." := 1;
        Rec."Integer Field" := 10;
        Rec.Insert(false);
        Commit();

        Rec.Get(1);
        Rec."Integer Field" := 99;
        Rec.Modify(false);

        asserterror Error('unrelated error after the uncommitted modify');
        Assert.ExpectedError('unrelated error after the uncommitted modify');

        Clear(Rec);
        Rec.Get(1);
        Assert.AreEqual(10, Rec."Integer Field",
            'an unrelated asserterror with no intervening Commit() must roll back the uncommitted Modify, restoring the committed value');
    end;

    [Test]
    procedure TempVar_Insert_UnrelatedAssertError_NoCommit_RowSurvives()
    var
        TempRec: Record "ALT Universal" temporary;
    begin
        Initialize();

        TempRec."Entry No." := 1;
        TempRec.Insert(false);

        asserterror Error('unrelated error, temp record has no database backing');
        Assert.ExpectedError('unrelated error, temp record has no database backing');

        Assert.AreEqual(1, TempRec.Count(),
            'a temporary-variable record has no SQL transaction to roll back — the row must survive an unrelated asserterror even without a Commit()');
    end;

    [Test]
    procedure TempOnly_Insert_UnrelatedAssertError_NoCommit_RowSurvives()
    var
        TempOnly: Record "ALT Temp Only";
    begin
        Initialize();

        TempOnly."Entry No." := 1;
        TempOnly.Insert(false);

        asserterror Error('unrelated error, TableType=Temporary has no database backing either');
        Assert.ExpectedError('unrelated error, TableType=Temporary has no database backing either');

        Assert.AreEqual(1, TempOnly.Count(),
            'TableType=Temporary is always in-memory — the row must survive an unrelated asserterror even without a Commit()');
    end;

    local procedure Initialize()
    var
        Rec: Record "ALT Universal";
        TempOnly: Record "ALT Temp Only";
    begin
        Rec.DeleteAll(false);
        TempOnly.DeleteAll(false);
    end;
}
