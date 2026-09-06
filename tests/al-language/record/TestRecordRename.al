// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-rename-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Composite (60001)

codeunit 60057 "Test Record Rename"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Record_Rename_SinglePK_ChangesKey()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 42;
        Rec.Insert();
        Rec.Rename(2);
        Clear(Rec);
        Assert.IsFalse(Rec.Get(1), 'After Rename(2), Get(1) must return false — old key should not exist');
    end;

    [Test]
    procedure Record_Rename_OldKeyGone_NotFound()
    var
        Rec: Record "ALT Universal";
        OldKeyExists: Boolean;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 100;
        Rec.Insert();
        Rec.Rename(2);
        Clear(Rec);
        OldKeyExists := Rec.Get(1);
        Assert.IsFalse(OldKeyExists, 'Old key Entry No.=1 must not be found after Rename(2)');
    end;

    [Test]
    procedure Record_Rename_NewKeyFound()
    var
        Rec: Record "ALT Universal";
        NewKeyExists: Boolean;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 100;
        Rec.Insert();
        Rec.Rename(2);
        Clear(Rec);
        NewKeyExists := Rec.Get(2);
        Assert.IsTrue(NewKeyExists, 'New key Entry No.=2 must be found after Rename(2)');
    end;

    [Test]
    procedure Record_Rename_CompositeKey_RenamesAll()
    var
        Rec: Record "ALT Composite";
        NewKeyExists: Boolean;
        OldKeyExists: Boolean;
    begin
        Initialize();
        Rec."Key1" := 1;
        Rec."Key2" := 'A';
        Rec."Key3" := 10;
        Rec."Value1" := 'Original';
        Rec.Insert();
        Rec.Rename(2, 'B', 20);
        Clear(Rec);
        NewKeyExists := Rec.Get(2, 'B', 20);
        OldKeyExists := Rec.Get(1, 'A', 10);
        Assert.IsTrue(NewKeyExists, 'New composite key (2,B,20) must be found after Rename');
        Assert.IsFalse(OldKeyExists, 'Old composite key (1,A,10) must not be found after Rename');
    end;

    [Test]
    procedure Record_Rename_DuplicateTargetKey_Throws()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 42;
        Rec.Insert();
        Rec.Init();
        Rec."Entry No." := 2;
        Rec."Integer Field" := 99;
        Rec.Insert();
        Rec.Get(1);
        asserterror Rec.Rename(2);
        Assert.ExpectedError('already exists');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
