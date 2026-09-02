// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-triggers-overview
// Scope: in-scope
// Fixtures used: ALT Error Trigger (60023), ALT Universal (60000)
codeunit 60156 "Test Trigger Rollback"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    var
        ErrRec: Record "ALT Error Trigger";
    begin
        ErrRec.DeleteAll(false);
        Cleanup.Initialize();
    end;

    [Test]
    procedure OnInsert_NoError_InsertSucceeds()
    var
        ErrRec: Record "ALT Error Trigger";
    begin
        Initialize();

        ErrRec."Entry No." := 1;
        ErrRec."Should Error" := false;
        ErrRec.Insert(true);

        Assert.AreEqual(1, ErrRec.Count(), 'Insert with Should Error=false must succeed');
    end;

    [Test]
    procedure OnInsert_Throws_RecordNotInserted()
    var
        ErrRec: Record "ALT Error Trigger";
    begin
        Initialize();

        ErrRec."Entry No." := 1;
        ErrRec."Should Error" := true;
        asserterror ErrRec.Insert(true);

        Assert.AreEqual('OnInsert error triggered', GetLastErrorText(), 'asserterror must capture OnInsert error text');
        // Count()=1 here does NOT mean this Insert's own row survived OnInsert throwing — see
        // OnInsert_Throws_NothingElseSinceCommit_NoPhantomRow below, which proves a failing
        // Insert(true) with nothing else going on leaves the table genuinely empty. What's
        // actually happening: the test immediately before this one
        // (OnInsert_NoError_InsertSucceeds) leaves a row behind (nothing rolled it back — it
        // never hit an asserterror), and THIS test's own Initialize() does an uncommitted
        // DeleteAll(false) that the asserterror's rollback undoes, restoring that row. See
        // OnInsert_Throws_UncommittedDeleteAllIsRolledBack_NotPhantomRow for the same shape
        // made self-contained (no reliance on test execution order).
        Assert.AreEqual(1, ErrRec.Count(), 'After asserterror on Insert with OnInsert error, Count() reflects the last commit point, not a phantom row from this insert');
    end;

    [Test]
    procedure OnInsert_Throws_NothingElseSinceCommit_NoPhantomRow()
    var
        ErrRec: Record "ALT Error Trigger";
    begin
        Initialize();
        Commit();

        ErrRec."Entry No." := 1;
        ErrRec."Should Error" := true;
        asserterror ErrRec.Insert(true);

        Assert.AreEqual(0, ErrRec.Count(),
            'A failing Insert(true) with nothing else written since the last commit point must leave the table empty — no phantom row from the failed insert''s own field buffer');
    end;

    [Test]
    procedure OnInsert_Throws_NothingElseSinceCommit_KeyIsFreeAgain()
    var
        ErrRec: Record "ALT Error Trigger";
    begin
        Initialize();
        Commit();

        ErrRec."Entry No." := 1;
        ErrRec."Should Error" := true;
        asserterror ErrRec.Insert(true);

        Clear(ErrRec);
        ErrRec."Entry No." := 1;
        ErrRec.Insert(false);

        Assert.AreEqual(1, ErrRec.Count(),
            'The key must be immediately free again after a failing Insert(true) — a plain re-Insert onto the same key must succeed, not raise a duplicate-key error');
    end;

    [Test]
    procedure OnInsert_Throws_UncommittedDeleteAllIsRolledBack_NotPhantomRow()
    var
        ErrRec: Record "ALT Error Trigger";
    begin
        Initialize();

        ErrRec."Entry No." := 1;
        ErrRec."Should Error" := false;
        ErrRec.Insert(false);
        Commit();

        ErrRec.DeleteAll(false);

        Clear(ErrRec);
        ErrRec."Entry No." := 1;
        ErrRec."Should Error" := true;
        asserterror ErrRec.Insert(true);

        Assert.AreEqual(1, ErrRec.Count(),
            'The committed row from before the uncommitted DeleteAll must be restored by the rollback');
        Clear(ErrRec);
        Assert.IsTrue(ErrRec.Get(1), 'The restored row must exist');
        Assert.AreEqual(false, ErrRec."Should Error",
            'The restored row must be the ORIGINAL committed row (Should Error=false), not the failed insert''s own buffer (which would carry Should Error=true)');
    end;

    [Test]
    procedure OnDelete_Throws_UncommittedInsertIsRolledBack_RecordAbsent()
    var
        ErrRec: Record "ALT Error Trigger";
    begin
        Initialize();
        Commit();

        ErrRec."Entry No." := 1;
        ErrRec."Should Error" := true;
        ErrRec.Insert(false);

        ErrRec.Get(1);
        asserterror ErrRec.Delete(true);

        // Contrast with OnDelete_Throws_RecordStillExists above: THAT test's Insert survives
        // only because a Commit() in the PRECEDING test already made an equal row durable at
        // this test's own commit-point baseline. Here nothing precedes the Commit() at the
        // top of this test, so the uncommitted Insert is rolled back along with everything
        // else since that commit point, same as any other trigger failure — the record is
        // NOT specially exempted just because the failing write targeted it.
        Assert.AreEqual(0, ErrRec.Count(),
            'An uncommitted Insert must still roll back on a later asserterror, even when the asserterror''d statement is itself a failing trigger on the SAME record');
    end;

    [Test]
    procedure OnDelete_Throws_EarlierLandedDeleteOnSameTableStillRollsBack()
    var
        Row1: Record "ALT Error Trigger";
        Row2: Record "ALT Error Trigger";
    begin
        Initialize();

        Row1."Entry No." := 1;
        Row1."Should Error" := false;
        Row1.Insert(false);
        Row2."Entry No." := 2;
        Row2."Should Error" := true;
        Row2.Insert(false);
        Commit();

        asserterror DeleteBothRows();

        // Row 1's delete physically landed before row 2's delete failed in ITS OWN trigger —
        // the general rollback must still undo row 1's landed delete, not just leave the
        // table exactly as the failed statement left it.
        Assert.IsTrue(Row1.Get(1),
            'Row 1''s landed delete (made earlier in the same asserterror''d statement) must be rolled back even though the statement''s LAST write on this table (row 2''s delete) never landed');
    end;

    local procedure DeleteBothRows()
    var
        ErrRec: Record "ALT Error Trigger";
    begin
        ErrRec.Get(1);
        ErrRec.Delete(false);
        ErrRec.Get(2);
        ErrRec.Delete(true);
    end;

    [Test]
    procedure OnInsert_Throws_ErrorTextContainsMessage()
    var
        ErrRec: Record "ALT Error Trigger";
    begin
        Initialize();

        ErrRec."Entry No." := 1;
        ErrRec."Should Error" := true;
        asserterror ErrRec.Insert(true);

        Assert.IsTrue(
            StrPos(GetLastErrorText(), 'OnInsert error triggered') > 0,
            'OnInsert error text must be preserved through asserterror'
        );
    end;

    [Test]
    procedure OnModify_Throws_ValueNotModified()
    var
        ErrRec: Record "ALT Error Trigger";
    begin
        Initialize();

        ErrRec."Entry No." := 1;
        ErrRec."Value" := 10;
        ErrRec."Should Error" := false;
        ErrRec.Insert(false);
        // Commit to make the insert durable before the asserterror block.
        // Without Commit(), asserterror rolls back ALL uncommitted work in the implicit
        // transaction (including this Insert), leaving the table empty after the error.
        Commit();

        ErrRec.Get(1);
        ErrRec."Should Error" := true;
        ErrRec."Value" := 99;
        asserterror ErrRec.Modify(true);

        Assert.AreEqual('OnModify error triggered', GetLastErrorText(), 'OnModify error text must be captured');

        // After the error, get a fresh copy from the database to check it wasn't modified
        Clear(ErrRec);
        ErrRec.Get(1);
        Assert.AreEqual(10, ErrRec."Value", 'After OnModify error, field value must remain unchanged (rolled back)');
        Assert.AreEqual(false, ErrRec."Should Error", 'After OnModify error, record state must be rolled back');
    end;

    [Test]
    procedure OnDelete_Throws_RecordStillExists()
    var
        ErrRec: Record "ALT Error Trigger";
    begin
        Initialize();

        ErrRec."Entry No." := 1;
        ErrRec."Should Error" := true;
        ErrRec.Insert(false);

        ErrRec.Get(1);
        asserterror ErrRec.Delete(true);

        Assert.AreEqual('OnDelete error triggered', GetLastErrorText(), 'OnDelete error text must be captured');
        Assert.IsTrue(ErrRec.Get(1), 'After OnDelete error, record must still exist (not deleted)');
    end;

    [Test]
    procedure OnValidate_Throws_FieldValueRolledBack()
    var
        ErrRec: Record "ALT Error Trigger";
    begin
        Initialize();

        ErrRec."Entry No." := 1;
        ErrRec."Value" := 10;
        ErrRec."Should Error" := false;
        ErrRec.Insert(false);

        ErrRec.Get(1);
        ErrRec."Should Error" := true;
        asserterror ErrRec.Validate("Value", 99);

        Assert.AreEqual('OnValidate error triggered', GetLastErrorText(), 'OnValidate error text must be captured');
        Assert.AreEqual(10, ErrRec."Value", 'After OnValidate error, field value must be rolled back to original');
    end;

    [Test]
    procedure Insert_RunTriggerFalse_BypassesOnInsertError()
    var
        ErrRec: Record "ALT Error Trigger";
    begin
        Initialize();

        ErrRec."Entry No." := 1;
        ErrRec."Should Error" := true;
        ErrRec.Insert(false);

        Assert.AreEqual(1, ErrRec.Count(), 'Insert(false) must succeed even when OnInsert would throw');
    end;

    [Test]
    procedure Delete_RunTriggerFalse_BypassesOnDeleteError()
    var
        ErrRec: Record "ALT Error Trigger";
    begin
        Initialize();

        ErrRec."Entry No." := 1;
        ErrRec."Should Error" := true;
        ErrRec.Insert(false);

        ErrRec.Get(1);
        ErrRec.Delete(false);

        Assert.AreEqual(0, ErrRec.Count(), 'Delete(false) must succeed even when OnDelete would throw');
    end;
}
