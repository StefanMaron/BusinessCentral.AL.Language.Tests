// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-rename-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000)
// A Rename is a write like Insert, Modify and Delete: an error after it, caught by asserterror,
// rolls it back to the last commit point, and a committed Rename survives a later error.

codeunit 67590 "Test Record Rename Rollback"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure SeedCommitted()
    var
        Rec: Record "ALT Universal";
    begin
        Cleanup.Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 42;
        Rec.Insert();
        Commit();
    end;

    [Test]
    procedure Rename_ThenError_InAssertError_IsRolledBack()
    var
        Rec: Record "ALT Universal";
    begin
        SeedCommitted();

        asserterror begin
            Rec.Get(1);
            Rec.Rename(2);
            Error('boom');
        end;

        Assert.AreEqual('boom', GetLastErrorText(), 'asserterror must capture the error raised after the Rename');
        Clear(Rec);
        Assert.IsTrue(Rec.Get(1), 'The Rename must be rolled back: the old key 1 must exist again');
        Assert.AreEqual(42, Rec."Integer Field", 'The rolled-back row must keep its field values');
        Assert.IsFalse(Rec.Get(2), 'The Rename must be rolled back: the new key 2 must not exist');
    end;

    [Test]
    procedure Rename_Committed_SurvivesALaterError()
    var
        Rec: Record "ALT Universal";
    begin
        SeedCommitted();

        Rec.Get(1);
        Rec.Rename(2);
        Commit();
        asserterror Error('boom');

        Clear(Rec);
        Assert.IsFalse(Rec.Get(1), 'A committed Rename must not come undone: the old key 1 must stay gone');
        Assert.IsTrue(Rec.Get(2), 'A committed Rename must not come undone: the new key 2 must exist');
    end;

    [Test]
    procedure Delete_ThenError_InAssertError_IsRolledBack_Control()
    var
        Rec: Record "ALT Universal";
    begin
        SeedCommitted();

        asserterror begin
            Rec.Get(1);
            Rec.Delete();
            Error('boom');
        end;

        Clear(Rec);
        Assert.IsTrue(Rec.Get(1), 'The Delete must be rolled back: key 1 must exist again');
    end;
}
