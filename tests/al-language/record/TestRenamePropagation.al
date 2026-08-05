// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-rename-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Relation Parent (60028), ALT Relation Child (60029)
//
// CLAIM UNDER TEST: renaming a record's primary key propagates to other tables that hold a
// TableRelation to it, and ValidateTableRelation = false suppresses that propagation the same
// way it suppresses input validation -- it is not just an input-validation switch. "Soft Ref"
// carries no TableRelation at all and is the control: it must NEVER propagate, proving the test
// can detect a non-propagating field.

codeunit 60236 "Test Rename Propagation"
{
    Subtype = Test;
    TestPermissions = Disabled;
    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Record_Rename_ValidatedRelation_PropagatesToReferencingRecords()
    var
        Parent: Record "ALT Relation Parent";
        Child: Record "ALT Relation Child";
    begin
        Initialize();
        Parent."Code" := 'OLDCODE';
        Parent.Insert(false);

        Child."Entry No." := 1;
        Child."Validated Ref" := 'OLDCODE';
        Child.Insert(false);

        Parent.Rename('NEWCODE');

        Child.Get(1);
        Assert.AreEqual('NEWCODE', Child."Validated Ref", 'A field with a normal TableRelation must follow the parent rename');
    end;

    [Test]
    procedure Record_Rename_UnvalidatedRelation_DoesNotPropagate()
    var
        Parent: Record "ALT Relation Parent";
        Child: Record "ALT Relation Child";
    begin
        Initialize();
        Parent."Code" := 'OLDCODE';
        Parent.Insert(false);

        Child."Entry No." := 1;
        Child."Unvalidated Ref" := 'OLDCODE';
        Child.Insert(false);

        Parent.Rename('NEWCODE');

        Child.Get(1);
        Assert.AreEqual('OLDCODE', Child."Unvalidated Ref",
            'ValidateTableRelation = false suppresses rename PROPAGATION too, not just input validation');
    end;

    [Test]
    procedure Record_Rename_NoTableRelation_DoesNotPropagate()
    var
        Parent: Record "ALT Relation Parent";
        Child: Record "ALT Relation Child";
    begin
        Initialize();
        Parent."Code" := 'OLDCODE';
        Parent.Insert(false);

        Child."Entry No." := 1;
        Child."Soft Ref" := 'OLDCODE';
        Child.Insert(false);

        Parent.Rename('NEWCODE');

        Child.Get(1);
        Assert.AreEqual('OLDCODE', Child."Soft Ref",
            'Control: a field with NO TableRelation must never be touched by a parent rename');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
