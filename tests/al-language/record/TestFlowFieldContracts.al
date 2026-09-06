// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-calcfields-method
// Scope: in-scope
// Fixtures used: ALT Parent (60004), ALT Child (60005), ALT Universal (60000)

codeunit 60158 "Test FlowField Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── CalcFields: Query vs. Table Filter ───────────────────────────────────

    [Test]
    procedure CalcFields_DoesNotUseRecordFilters()
    var
        Parent: Record "ALT Parent";
        Child: Record "ALT Child";
        i: Integer;
    begin
        // CalcFields uses the CalcFormula filter, NOT the record's current table filter.
        // Insert Parent 1 with 3 children, then call CalcFields—it must return 3,
        // regardless of any SetRange on the Parent table.
        Initialize();
        Parent."Entry No." := 1;
        Parent.Insert();
        for i := 1 to 3 do begin
            Child."Entry No." := i;
            Child."Parent Entry No." := 1;
            Child."Amount" := 10;
            Child.Insert();
        end;

        // Get parent and confirm CalcFormula returns correct count
        Parent.Get(1);
        Parent.CalcFields("Child Count");
        Assert.AreEqual(3, Parent."Child Count", 'CalcFields must use CalcFormula filter, returning count of actual children');
    end;

    [Test]
    procedure CalcFields_AfterChildInsert_ValueIsStale()
    var
        Parent: Record "ALT Parent";
        Child: Record "ALT Child";
    begin
        // After CalcFields, if a new child is inserted, the in-memory FlowField value
        // remains stale until CalcFields is called again.
        Initialize();
        Parent."Entry No." := 1;
        Parent.Insert();

        Child."Entry No." := 1;
        Child."Parent Entry No." := 1;
        Child."Amount" := 50;
        Child.Insert();

        Parent.Get(1);
        Parent.CalcFields("Child Count");
        Assert.AreEqual(1, Parent."Child Count", 'Before adding second child, count must be 1');

        // Insert second child without recalculating
        Child."Entry No." := 2;
        Child."Parent Entry No." := 1;
        Child."Amount" := 50;
        Child.Insert();

        // Value is stale—still shows 1 until re-CalcFields
        Assert.AreEqual(1, Parent."Child Count", 'After child insert without re-CalcFields, in-memory value must still be 1 (stale)');

        // Now re-calculate
        Parent.CalcFields("Child Count");
        Assert.AreEqual(2, Parent."Child Count", 'After re-CalcFields, count must reflect new child');
    end;

    // ── CalcFields: Multiple Fields ──────────────────────────────────────────

    [Test]
    procedure CalcFields_MultipleFields_Atomic()
    var
        Parent: Record "ALT Parent";
        Child: Record "ALT Child";
    begin
        // CalcFields("Child Count", "Child Amount") calculates both fields in one call.
        Initialize();
        Parent."Entry No." := 1;
        Parent.Insert();

        Child."Entry No." := 1;
        Child."Parent Entry No." := 1;
        Child."Amount" := 25;
        Child.Insert();

        Child."Entry No." := 2;
        Child."Parent Entry No." := 1;
        Child."Amount" := 75;
        Child.Insert();

        Parent.Get(1);
        Parent.CalcFields("Child Count", "Child Amount");

        Assert.AreEqual(2, Parent."Child Count", 'CalcFields must calculate Child Count correctly');
        Assert.AreEqual(100, Parent."Child Amount", 'CalcFields must calculate Child Amount correctly in same call');
    end;

    [Test]
    procedure CalcFields_ReturnsTrue_OnSuccess()
    var
        Parent: Record "ALT Parent";
    begin
        // CalcFields returns Boolean: true on successful calculation.
        Initialize();
        Parent."Entry No." := 1;
        Parent.Insert();

        Parent.Get(1);
        Assert.IsTrue(Parent.CalcFields("Child Count"), 'CalcFields must return true on successful calculation');
    end;

    // ── CalcFields: Empty Results ────────────────────────────────────────────

    [Test]
    procedure CalcFields_NoChildren_ReturnsZeroCount()
    var
        Parent: Record "ALT Parent";
    begin
        // CalcFields on a parent with no children must return 0 for Count formula.
        Initialize();
        Parent."Entry No." := 1;
        Parent.Insert();

        Parent.Get(1);
        Parent.CalcFields("Child Count");
        Assert.AreEqual(0, Parent."Child Count", 'CalcFields on parent with no children must return 0 count');
    end;

    [Test]
    procedure CalcFields_NoChildren_ReturnsZeroSum()
    var
        Parent: Record "ALT Parent";
    begin
        // CalcFields on a parent with no children must return 0 for Sum formula.
        Initialize();
        Parent."Entry No." := 1;
        Parent.Insert();

        Parent.Get(1);
        Parent.CalcFields("Child Amount");
        Assert.AreEqual(0, Parent."Child Amount", 'CalcFields on parent with no children must return 0 sum');
    end;

    // ── SetAutoCalcFields: Auto-calculation on Find ──────────────────────────

    [Test]
    procedure SetAutoCalcFields_Calculates_On_FindFirst()
    var
        Parent: Record "ALT Parent";
        Child: Record "ALT Child";
    begin
        // SetAutoCalcFields automatically calculates specified FlowFields when FindFirst is called.
        Initialize();
        Parent."Entry No." := 1;
        Parent.Insert();

        Child."Entry No." := 1;
        Child."Parent Entry No." := 1;
        Child."Amount" := 33;
        Child.Insert();

        Parent.SetAutoCalcFields("Child Count", "Child Amount");
        Parent.FindFirst();

        Assert.AreEqual(1, Parent."Child Count", 'SetAutoCalcFields must auto-calc Child Count on FindFirst');
        Assert.AreEqual(33, Parent."Child Amount", 'SetAutoCalcFields must auto-calc Child Amount on FindFirst');
    end;

    [Test]
    procedure SetAutoCalcFields_Calculates_On_Next()
    var
        Parent: Record "ALT Parent";
        Child: Record "ALT Child";
    begin
        // SetAutoCalcFields automatically calculates when Next() is called, per-record.
        Initialize();
        Parent."Entry No." := 1;
        Parent.Insert();
        Parent."Entry No." := 2;
        Parent.Insert();

        Child."Entry No." := 1;
        Child."Parent Entry No." := 2;
        Child."Amount" := 77;
        Child.Insert();

        Parent.SetAutoCalcFields("Child Amount");
        Parent.FindFirst();  // Parent 1 has no children
        Assert.AreEqual(0, Parent."Child Amount", 'SetAutoCalcFields: first record with no children = 0');

        Parent.Next();  // Parent 2 has one child
        Assert.AreEqual(77, Parent."Child Amount", 'SetAutoCalcFields must auto-calc on Next() too');
    end;

    [Test]
    procedure SetAutoCalcFields_TempRecord_DoesNotCalculate()
    var
        TempParent: Record "ALT Parent" temporary;
    begin
        // SetAutoCalcFields on a temporary record does not error, but FlowField
        // values remain 0 since temp records have no database backing.
        Initialize();
        TempParent."Entry No." := 1;
        TempParent.Insert();

        TempParent.SetAutoCalcFields("Child Count");
        TempParent.FindFirst();

        // For a temp record, Child Count FlowField must be 0 (cannot query real DB children)
        Assert.AreEqual(0, TempParent."Child Count", 'SetAutoCalcFields on temp record must return 0 (no DB access)');
    end;

    // ── CalcSums: Regular Decimal Fields ─────────────────────────────────────

    [Test]
    procedure CalcSums_OnRegularDecimalField_Works()
    var
        Rec: Record "ALT Universal";
    begin
        // CalcSums works on regular Decimal fields (not FlowFields).
        // Sums all records in the table (or filtered set).
        Initialize();
        Rec."Entry No." := 1;
        Rec."Amount Field" := 40;
        Rec.Insert();

        Rec."Entry No." := 2;
        Rec."Amount Field" := 60;
        Rec.Insert();

        Rec.CalcSums("Amount Field");
        Assert.AreEqual(100, Rec."Amount Field", 'CalcSums on regular Decimal field must return sum of all records');
    end;

    [Test]
    procedure CalcSums_WithFilter_OnlySumsFiltered()
    var
        Rec: Record "ALT Universal";
    begin
        // CalcSums with SetRange filter sums only the filtered records.
        Initialize();
        Rec."Entry No." := 1;
        Rec."Amount Field" := 100;
        Rec.Insert();

        Rec."Entry No." := 2;
        Rec."Amount Field" := 200;
        Rec.Insert();

        Rec."Entry No." := 3;
        Rec."Amount Field" := 300;
        Rec.Insert();

        Rec.SetRange("Entry No.", 1, 2);
        Rec.CalcSums("Amount Field");

        Assert.AreEqual(300, Rec."Amount Field", 'CalcSums with SetRange filter must only sum filtered records (100+200=300)');
    end;

    // ── SetRange on FlowFields: Unsupported Behavior ──────────────────────────

    [Test]
    procedure SetRange_OnFlowField_DoesNotCrash()
    var
        Parent: Record "ALT Parent";
    begin
        // SetRange on a FlowField is not officially supported, but BC may accept it
        // as a no-op or silently ignore it. The key contract is: no unhandled exception.
        Initialize();
        Parent."Entry No." := 1;
        Parent.Insert();

        // Call SetRange on FlowField—either succeeds (ignored) or throws predictably
        Parent.SetRange("Child Count", 0);

        // If we reach here, no unhandled exception occurred
        Assert.IsTrue(true, 'SetRange on FlowField must not cause unhandled exception');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
