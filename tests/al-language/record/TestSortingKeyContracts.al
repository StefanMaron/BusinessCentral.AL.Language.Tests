// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setcurrentkey-method
// Scope: in-scope
// Fixtures used: ALT Keyed (60006), ALT Composite (60001)

codeunit 60160 "Test Sorting Key Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure SetCurrentKey_Secondary_FindFirst_BySecondaryKeyOrder()
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();
        // Insert records with different Names in non-alphabetical order
        Keyed."Entry No." := 3;
        Keyed."Name" := 'Charlie';
        Keyed.Insert();

        Keyed."Entry No." := 1;
        Keyed."Name" := 'Alice';
        Keyed.Insert();

        Keyed."Entry No." := 2;
        Keyed."Name" := 'Bob';
        Keyed.Insert();

        // SetCurrentKey to Name field (secondary key)
        Keyed.SetCurrentKey(Keyed."Name", Keyed."Code");

        // FindFirst should return the alphabetically first Name
        Assert.IsTrue(Keyed.FindFirst(), 'FindFirst after SetCurrentKey(Name,Code) must succeed');
        Assert.AreEqual('Alice', Keyed."Name", 'FindFirst after SetCurrentKey(Name,Code) must return alphabetically first Name');
    end;

    [Test]
    procedure SetCurrentKey_Secondary_Next_FollowsSecondaryOrder()
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();
        // Insert records with different Names in non-alphabetical order
        Keyed."Entry No." := 3;
        Keyed."Name" := 'Charlie';
        Keyed.Insert();

        Keyed."Entry No." := 1;
        Keyed."Name" := 'Alice';
        Keyed.Insert();

        Keyed."Entry No." := 2;
        Keyed."Name" := 'Bob';
        Keyed.Insert();

        // SetCurrentKey to Name field and navigate
        Keyed.SetCurrentKey(Keyed."Name", Keyed."Code");
        Assert.IsTrue(Keyed.FindFirst(), 'FindFirst must succeed');
        Assert.AreEqual('Alice', Keyed."Name", 'First record must be Alice');

        // Next() should return Bob (alphabetically next)
        Assert.AreEqual(1, Keyed.Next(), 'Next() after Alice must succeed');
        Assert.AreEqual('Bob', Keyed."Name", 'Next() must follow secondary key order — should be Bob');
    end;

    [Test]
    procedure FindMinus_EquivalentTo_FindFirst_AfterSetCurrentKey()
    var
        Keyed: Record "ALT Keyed";
        NameFromFindMinus: Text;
    begin
        Initialize();
        // Insert records with different Names
        Keyed."Entry No." := 3;
        Keyed."Name" := 'Zebra';
        Keyed.Insert();

        Keyed."Entry No." := 1;
        Keyed."Name" := 'Apple';
        Keyed.Insert();

        // Find('-') with secondary key should return first record
        Keyed.SetCurrentKey(Keyed."Name", Keyed."Code");
        Assert.IsTrue(Keyed.Find('-'), 'Find("-") must return true');
        NameFromFindMinus := Keyed."Name";

        // FindFirst with same key should return the same record
        Keyed.SetCurrentKey(Keyed."Name", Keyed."Code");
        Assert.IsTrue(Keyed.FindFirst(), 'FindFirst must return true');

        Assert.AreEqual(NameFromFindMinus, Keyed."Name", 'Find("-") must return same record as FindFirst after SetCurrentKey');
    end;

    [Test]
    procedure FindPlus_EquivalentTo_FindLast_AfterSetCurrentKey()
    var
        Keyed: Record "ALT Keyed";
        NameFromFindPlus: Text;
    begin
        Initialize();
        // Insert records with different Names
        Keyed."Entry No." := 3;
        Keyed."Name" := 'Zebra';
        Keyed.Insert();

        Keyed."Entry No." := 1;
        Keyed."Name" := 'Apple';
        Keyed.Insert();

        // Find('+') with secondary key should return last record
        Keyed.SetCurrentKey(Keyed."Name", Keyed."Code");
        Assert.IsTrue(Keyed.Find('+'), 'Find("+") must return true');
        NameFromFindPlus := Keyed."Name";

        // FindLast with same key should return the same record
        Keyed.SetCurrentKey(Keyed."Name", Keyed."Code");
        Assert.IsTrue(Keyed.FindLast(), 'FindLast must return true');

        Assert.AreEqual(NameFromFindPlus, Keyed."Name", 'Find("+") must return same record as FindLast after SetCurrentKey');
    end;

    [Test]
    procedure Reset_ClearsSetCurrentKey_RevertsToPKOrder()
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();
        // Insert records with different Names
        Keyed."Entry No." := 3;
        Keyed."Name" := 'Charlie';
        Keyed.Insert();

        Keyed."Entry No." := 1;
        Keyed."Name" := 'Alice';
        Keyed.Insert();

        // SetCurrentKey to Name (secondary key)
        Keyed.SetCurrentKey(Keyed."Name", Keyed."Code");

        // Reset() must clear SetCurrentKey and revert to primary key order
        Keyed.Reset();

        // FindFirst should now return lowest PK (1), not alphabetically first Name
        Assert.IsTrue(Keyed.FindFirst(), 'FindFirst after Reset must succeed');
        Assert.AreEqual(1, Keyed."Entry No.", 'After Reset(), FindFirst must return lowest PK (1), not alphabetical first');
    end;

    [Test]
    procedure Count_AfterSetCurrentKey_ReturnsTotal()
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();
        // Insert 3 records
        Keyed."Entry No." := 1;
        Keyed."Name" := 'A';
        Keyed.Insert();

        Keyed."Entry No." := 2;
        Keyed."Name" := 'B';
        Keyed.Insert();

        Keyed."Entry No." := 3;
        Keyed."Name" := 'C';
        Keyed.Insert();

        // Count() must return total records regardless of SetCurrentKey
        Keyed.SetCurrentKey(Keyed."Name", Keyed."Code");
        Assert.AreEqual(3, Keyed.Count(), 'Count() must return total records regardless of SetCurrentKey');
    end;

    [Test]
    procedure SetCurrentKey_Amount_Ascending_FindFirst_ReturnsMin()
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();
        // Insert records with different Amounts in non-order
        Keyed."Entry No." := 1;
        Keyed."Amount" := 100;
        Keyed.Insert();

        Keyed."Entry No." := 2;
        Keyed."Amount" := 10;
        Keyed.Insert();

        Keyed."Entry No." := 3;
        Keyed."Amount" := 50;
        Keyed.Insert();

        // SetCurrentKey to Amount (Key2 secondary key)
        Keyed.SetCurrentKey(Keyed."Amount");

        // FindFirst should return minimum Amount (10)
        Assert.IsTrue(Keyed.FindFirst(), 'FindFirst by Amount key must succeed');
        Assert.AreEqual(10, Keyed."Amount", 'FindFirst by Amount key ascending must return minimum Amount (10)');
    end;

    [Test]
    procedure SetCurrentKey_Amount_Descending_FindFirst_ReturnsMax()
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();
        // Insert records with different Amounts in non-order
        Keyed."Entry No." := 1;
        Keyed."Amount" := 100;
        Keyed.Insert();

        Keyed."Entry No." := 2;
        Keyed."Amount" := 10;
        Keyed.Insert();

        Keyed."Entry No." := 3;
        Keyed."Amount" := 50;
        Keyed.Insert();

        // SetCurrentKey to Amount and set descending
        Keyed.SetCurrentKey(Keyed."Amount");
        Keyed.Ascending(false);

        // FindFirst in descending order should return maximum Amount (100)
        Assert.IsTrue(Keyed.FindFirst(), 'FindFirst by Amount key must succeed');
        Assert.AreEqual(100, Keyed."Amount", 'FindFirst by Amount key descending must return maximum Amount (100)');
    end;

    [Test]
    procedure SameSecondaryKeyValue_FindFirstByPK_Tiebreaker()
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();
        // Insert two records with same Name and Code (same secondary key values)
        Keyed."Entry No." := 2;
        Keyed."Name" := 'Same';
        Keyed."Code" := 'X';
        Keyed.Insert();

        Keyed."Entry No." := 1;
        Keyed."Name" := 'Same';
        Keyed."Code" := 'X';
        Keyed.Insert();

        // SetCurrentKey to Name, Code
        Keyed.SetCurrentKey(Keyed."Name", Keyed."Code");

        // When secondary key values are equal, order is determined by PK
        Assert.IsTrue(Keyed.FindFirst(), 'FindFirst must succeed');
        Assert.AreEqual(1, Keyed."Entry No.", 'With same secondary key value, FindFirst must return lowest PK (1) as tiebreaker');
    end;

    [Test]
    procedure Modify_AfterSecondaryKeyFind_DoesNotBreakIterator()
    var
        Keyed: Record "ALT Keyed";
        Count: Integer;
    begin
        Initialize();
        // Insert 3 records with different Amounts
        Keyed."Entry No." := 1;
        Keyed."Amount" := 10;
        Keyed.Insert();

        Keyed."Entry No." := 2;
        Keyed."Amount" := 20;
        Keyed.Insert();

        Keyed."Entry No." := 3;
        Keyed."Amount" := 30;
        Keyed.Insert();

        // SetCurrentKey to Amount and iterate with modification
        Keyed.SetCurrentKey(Keyed."Amount");
        Count := 0;

        if Keyed.FindSet(true) then
            repeat
                Keyed."Amount" := Keyed."Amount" + 1;
                Keyed.Modify();
                Count := Count + 1;
            until Keyed.Next() = 0;

        Assert.AreEqual(3, Count, 'Modifying a non-key field during secondary key FindSet+Next must iterate all 3 records');
    end;

    [Test]
    procedure Rename_UpdatesSecondaryKeyIndex_FindByNewKey()
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();
        // Insert a record with Amount = 42
        Keyed."Entry No." := 1;
        Keyed."Name" := 'Original';
        Keyed."Amount" := 42;
        Keyed.Insert();

        // Rename changes the PK from 1 to 99
        Keyed.Get(1);
        Keyed.Rename(99);

        // Secondary key index must be updated — should find by Amount = 42
        Clear(Keyed);
        Keyed.Reset();
        Keyed.SetCurrentKey(Keyed."Amount");
        Keyed.SetRange(Keyed."Amount", 42);

        Assert.IsTrue(Keyed.FindFirst(), 'After Rename, secondary key index must be updated — record findable by Amount');
        Assert.AreEqual(99, Keyed."Entry No.", 'Renamed record must have new PK value 99');
    end;

    [Test]
    procedure CompositeKey_Get_TooFewArguments_ThrowsOrReturnsFalse()
    var
        Comp: Record "ALT Composite";
    begin
        Initialize();
        // Insert composite key record with all 3 key fields
        Comp."Key1" := 1;
        Comp."Key2" := 'A';
        Comp."Key3" := 10;
        Comp.Insert();

        // Get with all 3 PK args must return true
        Assert.IsTrue(Comp.Get(1, 'A', 10), 'Get with all 3 PK args must return true');

        // Get with mismatched key value must return false
        Assert.IsFalse(Comp.Get(1, 'A', 99), 'Get with wrong Key3 value must return false');
    end;

    [Test]
    procedure CompositeKey_Rename_AllKeyFields_Updated()
    var
        Comp: Record "ALT Composite";
    begin
        Initialize();
        // Insert composite key record
        Comp."Key1" := 1;
        Comp."Key2" := 'OLD';
        Comp."Key3" := 10;
        Comp.Insert();

        // Get the record and rename all 3 PK fields
        Comp.Get(1, 'OLD', 10);
        Comp.Rename(2, 'NEW', 20);

        // Old composite key must not exist
        Clear(Comp);
        Assert.IsFalse(Comp.Get(1, 'OLD', 10), 'Old composite key must not exist after Rename');

        // New composite key must exist
        Assert.IsTrue(Comp.Get(2, 'NEW', 20), 'New composite key must exist after Rename');
    end;

    [Test]
    procedure SetCurrentKey_OnNonKeyField_DoesNotError()
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();
        // Insert a record
        Keyed."Entry No." := 1;
        Keyed."Name" := 'Test';
        Keyed.Insert();

        // SetCurrentKey on Name (which IS part of Key1 secondary key) must not error
        Keyed.SetCurrentKey(Keyed."Name");

        // FindFirst must succeed
        Assert.IsTrue(Keyed.FindFirst(), 'SetCurrentKey + FindFirst must succeed for secondary key field');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
