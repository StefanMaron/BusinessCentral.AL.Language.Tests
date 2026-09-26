// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-rename-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Rename Key Parent (60009), ALT Rename Key Child (60010),
//                ALT Rename Key Trig Child (60011), ALT Rename Tenant Parent (60012),
//                ALT Rename Company Child (60013)
//
// CLAIM UNDER TEST: rename propagation ("Test Rename Propagation", 60236) also reaches
//   - a referencing field that is part of the child's PRIMARY KEY: the child row is re-keyed,
//     so it is found by Get under the new key and no longer under the old one. That holds
//     whether or not the child table declares an OnRename trigger, and the child's own
//     OnRename trigger does NOT run for a propagated rename;
//   - a per-company child referencing a per-tenant (DataPerCompany = false) parent.
// Every arm has a control row pointing at a different parent, which must not move.
codeunit 60018 "Test Rename Key Relation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Rename_KeyFieldRelation_ChildIsReKeyed()
    var
        Parent: Record "ALT Rename Key Parent";
        Child: Record "ALT Rename Key Child";
    begin
        Initialize();
        InsertKeyParent('OLDKEY');
        InsertKeyParent('OTHERKEY');
        // Three children under the renamed parent: every one must be re-keyed, not just the first.
        InsertKeyChild('OLDKEY', 1);
        InsertKeyChild('OLDKEY', 2);
        InsertKeyChild('OLDKEY', 3);
        InsertKeyChild('OTHERKEY', 1);

        Parent.Get('OLDKEY');
        Parent.Rename('NEWKEY');

        Assert.IsTrue(Child.Get('NEWKEY', 1), 'Child line 1 must be found under the parent''s new key');
        Assert.IsTrue(Child.Get('NEWKEY', 2), 'Child line 2 must be found under the parent''s new key');
        Assert.IsTrue(Child.Get('NEWKEY', 3), 'Child line 3 must be found under the parent''s new key');
        Child.SetRange("Parent Code", 'NEWKEY');
        Assert.AreEqual(3, Child.Count(), 'All three children must be under the parent''s new key');
        Child.SetRange("Parent Code", 'OLDKEY');
        Assert.AreEqual(0, Child.Count(), 'No child may be left under the parent''s old key');
        Assert.IsTrue(Child.Get('OTHERKEY', 1), 'Control: a child of another parent must not move');
        Child.Reset();
        Assert.AreEqual(4, Child.Count(), 'The rename must re-key the children, not add or drop rows');
    end;

    [Test]
    procedure Rename_KeyFieldRelation_ChildWithRenameTrigger_IsReKeyedWithoutRunningIt()
    var
        Parent: Record "ALT Rename Key Parent";
        Child: Record "ALT Rename Key Trig Child";
    begin
        Initialize();
        InsertKeyParent('OLDTRIG');
        InsertKeyParent('OTHERTRIG');
        Child."Parent Code" := 'OLDTRIG';
        Child."Line No." := 1;
        Child.Insert();
        Child."Parent Code" := 'OTHERTRIG';
        Child.Insert();

        Parent.Get('OLDTRIG');
        Parent.Rename('NEWTRIG');

        Assert.IsTrue(Child.Get('NEWTRIG', 1), 'The child must be found under the parent''s new key');
        Assert.AreEqual(0, Child."Rename Trigger Runs", 'A propagated rename must not run the child''s OnRename trigger');
        Assert.IsFalse(Child.Get('OLDTRIG', 1), 'No child may be left under the parent''s old key');
        Assert.IsTrue(Child.Get('OTHERTRIG', 1), 'Control: a child of another parent must not move');
    end;

    [Test]
    procedure Rename_PerTenantParent_PerCompanyChildFollows()
    var
        Parent: Record "ALT Rename Tenant Parent";
        Child: Record "ALT Rename Company Child";
    begin
        Initialize();
        Parent.Code := 'OLDTENANT';
        Parent.Insert();
        Parent.Code := 'OTHERTENANT';
        Parent.Insert();
        Child."Entry No." := 1;
        Child."Parent Code" := 'OLDTENANT';
        Child.Insert();
        Child."Entry No." := 2;
        Child."Parent Code" := 'OTHERTENANT';
        Child.Insert();

        Parent.Get('OLDTENANT');
        Parent.Rename('NEWTENANT');

        Child.Get(1);
        Assert.AreEqual('NEWTENANT', Child."Parent Code", 'A per-company child must follow a per-tenant parent''s rename');
        Child.Get(2);
        Assert.AreEqual('OTHERTENANT', Child."Parent Code", 'Control: a child of another parent must not move');
    end;

    local procedure InsertKeyParent(ParentCode: Code[20])
    var
        Parent: Record "ALT Rename Key Parent";
    begin
        Parent.Code := ParentCode;
        Parent.Insert();
    end;

    local procedure InsertKeyChild(ParentCode: Code[20]; LineNo: Integer)
    var
        Child: Record "ALT Rename Key Child";
    begin
        Child."Parent Code" := ParentCode;
        Child."Line No." := LineNo;
        Child.Insert();
    end;

    local procedure Initialize()
    var
        KeyParent: Record "ALT Rename Key Parent";
        KeyChild: Record "ALT Rename Key Child";
        TrigChild: Record "ALT Rename Key Trig Child";
        TenantParent: Record "ALT Rename Tenant Parent";
        CompanyChild: Record "ALT Rename Company Child";
    begin
        KeyChild.DeleteAll();
        TrigChild.DeleteAll();
        KeyParent.DeleteAll();
        CompanyChild.DeleteAll();
        TenantParent.DeleteAll();
    end;
}
