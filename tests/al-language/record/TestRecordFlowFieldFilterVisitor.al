// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-flowfields
// Scope: in-scope
// Fixtures used: ALT Parent (60004), ALT Child (60005)
// Note: proves the temp-table filter visitor evaluates a FlowField (count) used
// in a SetRange filter without NRE-ing on the self-referencing / empty-CalcFormula
// probe, and that by-name source-table resolution makes the count correct.
// Retargeted from the runner-extras "FF Visitor Parent"/"FF Visitor Child" private
// fixtures onto the corpus's equivalent ALT Parent/ALT Child FlowField-count shape.
// BC versions: 24+

codeunit 60227 "Test Record FF Filter Visitor"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure SetRangeOnFlowField_NoChildren_SelectsAllParents()
    var
        Parent: Record "ALT Parent";
    begin
        Initialize();
        // [GIVEN] Two parents, no children at all → each parent's "Child Count" is 0.
        InsertParent(1);
        InsertParent(2);

        // [WHEN] Filtering parents whose FlowField "Child Count" = 0 (the Purch.-Post pattern).
        Parent.SetRange("Child Count", 0);

        // [THEN] Both parents match (count 0) — visitor evaluated the FlowField without NRE.
        Assert.AreEqual(2, Parent.Count(), 'Both zero-child parents should match Child Count = 0');
        Assert.IsTrue(Parent.FindFirst(), 'FindFirst should succeed on the filtered set');
    end;

    [Test]
    procedure SetRangeOnFlowField_WithChildren_ExcludesNonZeroParent()
    var
        Parent: Record "ALT Parent";
    begin
        Initialize();
        // [GIVEN] Parent 1 has 3 children, parent 2 has none.
        InsertParent(1);
        InsertParent(2);
        InsertChild(101, 1);
        InsertChild(102, 1);
        InsertChild(103, 1);

        // [WHEN] Filtering parents whose "Child Count" = 0.
        Parent.SetRange("Child Count", 0);

        // [THEN] Only parent 2 (zero children) matches; parent 1 (count 3) is excluded.
        Assert.AreEqual(1, Parent.Count(), 'Only the zero-child parent should match Child Count = 0');
        Parent.FindFirst();
        Assert.AreEqual(2, Parent."Entry No.", 'The matching parent must be parent 2');

        // [AND] A direct CalcFields on parent 1 yields the real count 3.
        Parent.Reset();
        Parent.Get(1);
        Parent.CalcFields("Child Count");
        Assert.AreEqual(3, Parent."Child Count", 'CalcFields must compute the real child count');
    end;

    local procedure InsertParent(No: Integer)
    var
        Parent: Record "ALT Parent";
    begin
        Parent.Init();
        Parent."Entry No." := No;
        Parent.Insert();
    end;

    local procedure InsertChild(EntryNo: Integer; ParentNo: Integer)
    var
        Child: Record "ALT Child";
    begin
        Child.Init();
        Child."Entry No." := EntryNo;
        Child."Parent Entry No." := ParentNo;
        Child.Insert();
    end;

    local procedure Initialize()
    var
        Parent: Record "ALT Parent";
        Child: Record "ALT Child";
    begin
        Parent.DeleteAll();
        Child.DeleteAll();
    end;
}
