// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Parent (60004), ALT Child (60005)
// Purpose: CONTRACT tests proving specific non-obvious behaviors in record navigation edge cases

codeunit 60155 "Test Record Nav Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Find(">") at Last Record ─────────────────────────────────────────────────

    [Test]
    procedure Find_GreaterThan_AtLastRecord_ReturnsFalse()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        // Insert Entry No 1,2,3
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec.Insert();
        Rec."Entry No." := 3;
        Rec.Insert();
        // Position at last record
        Rec.FindLast();
        // Find(">") from last record must return false
        Assert.IsFalse(Rec.Find('>'), 'Find(">") at last record must return false — no record is greater');
        Assert.AreEqual(3, Rec."Entry No.", 'Record pointer must remain at last record after failed Find(">")')
    end;

    // ── Find("<") at First Record ────────────────────────────────────────────────

    [Test]
    procedure Find_LessThan_AtFirstRecord_ReturnsFalse()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        // Insert Entry No 1,2,3
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec.Insert();
        Rec."Entry No." := 3;
        Rec.Insert();
        // Position at first record
        Rec.FindFirst();
        // Find("<") from first record must return false
        Assert.IsFalse(Rec.Find('<'), 'Find("<") at first record must return false — no record is less');
        Assert.AreEqual(1, Rec."Entry No.", 'Record pointer must remain at first record after failed Find("<")')
    end;

    // ── Find(">") from middle record ─────────────────────────────────────────────

    [Test]
    procedure Find_GreaterThan_PositionsAtNextRecord()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        // Insert Entry No 1,2,3
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec.Insert();
        Rec."Entry No." := 3;
        Rec.Insert();
        // Position at record 1 using Find(=)
        Rec."Entry No." := 1;
        Rec.Find('=');
        // Find(">") from record 1 should position at record 2
        Assert.IsTrue(Rec.Find('>'), 'Find(">") from record 1 must return true');
        Assert.AreEqual(2, Rec."Entry No.", 'Find(">") must move to next record (2)')
    end;

    // ── Find("<") from middle record ─────────────────────────────────────────────

    [Test]
    procedure Find_LessThan_PositionsAtPreviousRecord()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        // Insert Entry No 1,2,3
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec.Insert();
        Rec."Entry No." := 3;
        Rec.Insert();
        // Position at last record
        Rec.FindLast();
        // Find("<") from record 3 should position at record 2
        Assert.IsTrue(Rec.Find('<'), 'Find("<") from record 3 must return true');
        Assert.AreEqual(2, Rec."Entry No.", 'Find("<") must move to previous record (2)')
    end;

    // ── Next(Negative) goes backward ─────────────────────────────────────────────

    [Test]
    procedure Next_NegativeSteps_GoesBackward()
    var
        Rec: Record "ALT Universal";
        Steps: Integer;
    begin
        Initialize();
        // Insert Entry No 1,2,3
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec.Insert();
        Rec."Entry No." := 3;
        Rec.Insert();
        // Position at last record
        Rec.FindLast();
        // Next(-1) should move to record 2 and return -1
        Steps := Rec.Next(-1);
        Assert.AreEqual(-1, Steps, 'Next(-1) must return -1 (negative number of steps moved)');
        Assert.AreEqual(2, Rec."Entry No.", 'Next(-1) from record 3 must position at record 2')
    end;

    // ── Next(Negative) beyond first record ───────────────────────────────────────

    [Test]
    procedure Next_NegativeSteps_BeyondFirst_ReturnsZero()
    var
        Rec: Record "ALT Universal";
        Steps: Integer;
    begin
        Initialize();
        // Insert Entry No 1,2
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec.Insert();
        // Position at first record
        Rec.FindFirst();
        // Next(-1) from first record must return 0 (cannot move further back)
        Steps := Rec.Next(-1);
        Assert.AreEqual(0, Steps, 'Next(-1) from first record must return 0 (cannot go further back)')
    end;

    // ── Next(-2) jumps back two records ──────────────────────────────────────────

    [Test]
    procedure Next_NegativeTwo_JumpsBackTwo()
    var
        Rec: Record "ALT Universal";
        Steps: Integer;
    begin
        Initialize();
        // Insert Entry No 1,2,3,4,5
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec.Insert();
        Rec."Entry No." := 3;
        Rec.Insert();
        Rec."Entry No." := 4;
        Rec.Insert();
        Rec."Entry No." := 5;
        Rec.Insert();
        // Position at last record
        Rec.FindLast();
        // Next(-2) should move from 5 to 3 and return -2
        Steps := Rec.Next(-2);
        Assert.AreEqual(-2, Steps, 'Next(-2) must return -2 (negative number of steps moved)');
        Assert.AreEqual(3, Rec."Entry No.", 'Next(-2) from 5 must position at record 3')
    end;

    // ── SetCurrentKey on non-existent key ────────────────────────────────────────

    [Test]
    procedure SetCurrentKey_NonexistentKey_HandledGracefully()
    var
        Rec: Record "ALT Universal";
        Result: Boolean;
    begin
        Initialize();
        // SetCurrentKey on a non-key field in ALT Universal (Integer Field is not a key)
        Rec.SetCurrentKey("Integer Field");
        // In BC, SetCurrentKey on non-key field does not throw, uses available index or PK
        Assert.IsTrue(true, 'SetCurrentKey on non-key field must not throw in BC (uses available index or PK)');
        // Verify find still works
        Rec."Entry No." := 1;
        Rec.Insert();
        Result := Rec.FindFirst();
        Assert.IsTrue(Result, 'FindFirst must work after SetCurrentKey on non-key field')
    end;

    // ── CalcFields on uninserted record ──────────────────────────────────────────

    [Test]
    procedure CalcFields_OnUninsertedRecord_ReturnZero()
    var
        Parent: Record "ALT Parent";
    begin
        Initialize();
        // ALT Parent has FlowField "Child Count" = count of ALT Child
        // Create uninserted record (not in database)
        Parent."Entry No." := 9999;
        // CalcFields on uninserted record
        Parent.CalcFields("Child Count");
        // Must return 0 (no children found)
        Assert.AreEqual(0, Parent."Child Count", 'CalcFields on uninserted record must return 0 (no children found)')
    end;

    // ── CalcSums with no matching records ────────────────────────────────────────

    [Test]
    procedure CalcSums_FilterMatchesNoRecords_ReturnsZero()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        // Insert some records
        Rec."Entry No." := 1;
        Rec."Amount Field" := 100;
        Rec.Insert();
        // Set filter that matches nothing
        Rec.SetRange("Entry No.", 99999);
        // CalcSums must return 0, not throw
        Rec.CalcSums("Amount Field");
        Assert.AreEqual(0, Rec."Amount Field", 'CalcSums with no matching records must return 0, not error')
    end;

    // ── Copy(ShareTable=true) shares underlying table ──────────────────────────────

    [Test]
    procedure Copy_ShareTable_True_InsertVisibleInBoth()
    var
        Rec1: Record "ALT Universal" temporary;
        Rec2: Record "ALT Universal" temporary;
    begin
        Initialize();
        // Insert first record
        Rec1."Entry No." := 1;
        Rec1.Insert();
        // Copy with ShareTable=true → same underlying table
        Rec2.Copy(Rec1, true);
        // Both must see same count
        Assert.AreEqual(Rec1.Count(), Rec2.Count(), 'After Copy(ShareTable:=true), both must see same count');
        // Insert via Rec1
        Rec1."Entry No." := 2;
        Rec1.Insert();
        // Rec2 with shared table must see new record
        Assert.AreEqual(Rec1.Count(), Rec2.Count(), 'After insert via Rec1, Rec2 with shared table must see new record')
    end;

    // ── Copy(ShareTable=false) creates independent view ──────────────────────────

    [Test]
    procedure Copy_ShareTable_False_IndependentView()
    var
        Rec: Record "ALT Universal" temporary;
        Rec1: Record "ALT Universal" temporary;
        Rec2: Record "ALT Universal" temporary;
        i: Integer;
    begin
        Initialize();
        // Insert 5 records into Rec
        for i := 1 to 5 do begin
            Rec."Entry No." := i;
            Rec.Insert();
        end;
        // Copy Rec into Rec1 with ShareTable=true so Rec1 shares Rec's temp table (sees all 5 records)
        Rec1.Copy(Rec, true);
        Rec1.SetRange("Entry No.", 1, 3);
        // Copy Rec1 into Rec2 with ShareTable=false (independent copy, inherits the 1..3 filter)
        Rec2.Copy(Rec1, false);
        // Rec1 has filter 1..3 → count = 3
        Assert.AreEqual(3, Rec1.Count(), 'Rec1 with SetRange 1..3 must count 3 records');
        // Rec2 is an independent copy (ShareTable=false) — only the filter is copied, not the temp table data
        Assert.AreEqual(0, Rec2.Count(), 'Copy(ShareTable:=false) on temp record creates empty independent buffer — only filter is copied')
    end;

    // ── MarkedOnly(true) with no marks ───────────────────────────────────────────

    [Test]
    procedure MarkedOnly_True_WithNoMarks_FindFirst_ReturnsFalse()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        // Insert Entry No 1,2,3 (no marks applied)
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec.Insert();
        Rec."Entry No." := 3;
        Rec.Insert();
        // Enable MarkedOnly filter with no marks
        Rec.MarkedOnly(true);
        // FindFirst must return false (no marked records)
        Assert.IsFalse(Rec.FindFirst(), 'MarkedOnly(true) with no marked records must cause FindFirst to return false')
    end;

    // ── GetBySystemId on deleted record ──────────────────────────────────────────

    [Test]
    procedure GetBySystemId_DeletedRecord_ReturnsFalse()
    var
        Rec: Record "ALT Universal";
        Rec2: Record "ALT Universal";
        ID: Guid;
    begin
        Initialize();
        // Insert a record
        Rec."Entry No." := 1;
        Rec.Insert();
        // Get it and capture its SystemId
        Rec.Get(1);
        ID := Rec.SystemId;
        // Delete the record
        Rec.Delete();
        // GetBySystemId on deleted record must return false, not throw
        Assert.IsFalse(Rec2.GetBySystemId(ID), 'GetBySystemId on a deleted record SystemId must return false, not throw')
    end;

    // ── Init() does NOT reset primary key, but DOES reset non-PK fields ─────────

    [Test]
    procedure Init_On_Gotten_Record_PKSurvives_NonPKReset()
    var
        Rec: Record "ALT Universal";
        Rec2: Record "ALT Universal";
    begin
        Initialize();
        // Insert record with Entry No 1
        Rec."Entry No." := 1;
        Rec."Integer Field" := 99;
        Rec.Insert();
        // Get the record
        Rec.Get(1);
        // Call Init() — BC documentation: "Keys and timestamps are not initialized."
        Rec.Init();
        // Primary key field MUST survive Init() — BC docs explicitly state keys are NOT initialized
        Assert.AreEqual(1, Rec."Entry No.", 'Record.Init() must NOT reset the primary key — keys survive Init() per BC docs');
        // Non-PK fields must be reset to defaults
        Assert.AreEqual(0, Rec."Integer Field", 'Record.Init() must reset non-PK fields to their defaults');
        // Verify Init does NOT remove from database — record 1 still exists
        Assert.IsTrue(Rec2.Get(1), 'Record.Init() must NOT remove record from database — it only resets the variable')
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
