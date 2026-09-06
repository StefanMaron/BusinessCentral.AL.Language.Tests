// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setcurrentkey-method
// Scope: in-scope
// Fixtures used: ALT Keyed (60006)

codeunit 60056 "Test Record Sort"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Record_SetCurrentKey_ValidKey_SetsKey()
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();
        // Insert 3 ALT Keyed records with different Names
        Keyed."Entry No." := 1;
        Keyed."Name" := 'Alice';
        Keyed."Code" := 'CODE1';
        Keyed.Insert();

        Keyed."Entry No." := 2;
        Keyed."Name" := 'Bob';
        Keyed."Code" := 'CODE2';
        Keyed.Insert();

        Keyed."Entry No." := 3;
        Keyed."Name" := 'Charlie';
        Keyed."Code" := 'CODE3';
        Keyed.Insert();

        // SetCurrentKey("Name","Code") - should not throw
        Keyed.SetCurrentKey(Keyed."Name", Keyed."Code");

        // FindFirst should return true and load the first record
        Assert.IsTrue(Keyed.FindFirst(), 'SetCurrentKey should allow FindFirst without throwing');

        // Verify we got the first record by Name order (Alice)
        Assert.AreEqual('Alice', Keyed."Name", 'After SetCurrentKey(Name,Code), FindFirst should return Name=Alice');
    end;

    [Test]
    procedure Record_SetCurrentKey_SingleField_SortsAscending()
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();
        // Insert Keyed records with different Amounts
        Keyed."Entry No." := 1;
        Keyed."Amount" := 30;
        Keyed.Insert();

        Keyed."Entry No." := 2;
        Keyed."Amount" := 10;
        Keyed.Insert();

        Keyed."Entry No." := 3;
        Keyed."Amount" := 20;
        Keyed.Insert();

        // SetCurrentKey("Amount"); FindFirst should return Amount=10 (lowest/first)
        Keyed.SetCurrentKey(Keyed."Amount");
        Assert.IsTrue(Keyed.FindFirst(), 'FindFirst on sorted Amount should succeed');
        Assert.AreEqual(10, Keyed."Amount", 'After SetCurrentKey(Amount), FindFirst must return Amount=10 (smallest)');
    end;

    [Test]
    procedure Record_SetCurrentKey_MultiField_SortsCorrectly()
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();
        // Insert records with different Name/Code combinations
        // Name='B',Code='X'
        Keyed."Entry No." := 1;
        Keyed."Name" := 'B';
        Keyed."Code" := 'X';
        Keyed.Insert();

        // Name='A',Code='Y'
        Keyed."Entry No." := 2;
        Keyed."Name" := 'A';
        Keyed."Code" := 'Y';
        Keyed.Insert();

        // Name='A',Code='X'
        Keyed."Entry No." := 3;
        Keyed."Name" := 'A';
        Keyed."Code" := 'X';
        Keyed.Insert();

        // SetCurrentKey("Name","Code"); FindFirst should return Name='A', Code='X' (first by Name, then Code)
        Keyed.SetCurrentKey(Keyed."Name", Keyed."Code");
        Assert.IsTrue(Keyed.FindFirst(), 'FindFirst on multi-field key should succeed');

        // Must be Name='A' (first by primary sort) AND Code='X' (first within Name='A' by secondary sort)
        Assert.AreEqual('A', Keyed."Name", 'Multi-field sort: first Name must be A');
        Assert.AreEqual('X', Keyed."Code", 'Multi-field sort: within Name=A, first Code must be X');
    end;

    [Test]
    procedure Record_Ascending_Default_IsAscending()
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();
        // Rec.Ascending() default must return true
        Assert.IsTrue(Keyed.Ascending(), 'Record.Ascending() default must be true');
    end;

    [Test]
    procedure Record_Ascending_SetFalse_IsDescending()
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();
        // Rec.Ascending(false); Rec.Ascending() must return false
        Keyed.Ascending(false);
        Assert.IsFalse(Keyed.Ascending(), 'After Ascending(false), Ascending() must return false');
    end;

    [Test]
    procedure Record_Ascending_SetTrue_IsAscending()
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();
        // Rec.Ascending(false); Rec.Ascending(true); Rec.Ascending() must return true
        Keyed.Ascending(false);
        Keyed.Ascending(true);
        Assert.IsTrue(Keyed.Ascending(), 'After Ascending(true), Ascending() must return true');
    end;

    [Test]
    procedure Record_Ascending_DescendingOrder_FindFirstReturnsLast()
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();
        // Insert Keyed Entry 1 Amount=10, Entry 2 Amount=20
        Keyed."Entry No." := 1;
        Keyed."Amount" := 10;
        Keyed.Insert();

        Keyed."Entry No." := 2;
        Keyed."Amount" := 20;
        Keyed.Insert();

        // SetCurrentKey("Amount"); Ascending(false); FindFirst should return Amount=20 (highest/last in ascending order)
        Keyed.SetCurrentKey(Keyed."Amount");
        Keyed.Ascending(false);
        Assert.IsTrue(Keyed.FindFirst(), 'FindFirst in descending order should succeed');
        Assert.AreEqual(20, Keyed."Amount", 'Descending order: FindFirst must return Amount=20 (largest)');
    end;

    [Test]
    procedure Record_GetAscending_AscendingField_ReturnsTrue()
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();
        // SetCurrentKey("Amount"); GetAscending("Amount") must return true (default ascending)
        Keyed.SetCurrentKey(Keyed."Amount");
        Assert.IsTrue(Keyed.GetAscending(Keyed."Amount"), 'GetAscending(Amount) default must return true');
    end;

    [Test]
    procedure Record_GetAscending_DescendingField_ReturnsFalse()
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();
        // SetCurrentKey("Amount"); SetAscending("Amount", false); GetAscending("Amount") must return false
        Keyed.SetCurrentKey(Keyed."Amount");
        Keyed.SetAscending(Keyed."Amount", false);
        Assert.IsFalse(Keyed.GetAscending(Keyed."Amount"), 'After SetAscending(false), GetAscending must return false');
    end;

    [Test]
    procedure Record_SetAscending_SetFalse_DescendingOrder()
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();
        // SetCurrentKey("Amount"); SetAscending("Amount", false)
        // Insert Entry 1 Amount=5, Entry 2 Amount=15; FindFirst -> Amount must be 15
        Keyed."Entry No." := 1;
        Keyed."Amount" := 5;
        Keyed.Insert();

        Keyed."Entry No." := 2;
        Keyed."Amount" := 15;
        Keyed.Insert();

        Keyed.SetCurrentKey(Keyed."Amount");
        Keyed.SetAscending(Keyed."Amount", false);
        Assert.IsTrue(Keyed.FindFirst(), 'FindFirst after SetAscending(false) should succeed');
        Assert.AreEqual(15, Keyed."Amount", 'SetAscending(false): FindFirst must return Amount=15 (largest)');
    end;

    [Test]
    procedure Record_SetAscending_SetTrue_AscendingOrder()
    var
        Keyed: Record "ALT Keyed";
    begin
        Initialize();
        // After SetAscending("Amount", false) then SetAscending("Amount", true)
        // Insert Entry 1 Amount=5, Entry 2 Amount=15; FindFirst -> Amount must be 5
        Keyed."Entry No." := 1;
        Keyed."Amount" := 5;
        Keyed.Insert();

        Keyed."Entry No." := 2;
        Keyed."Amount" := 15;
        Keyed.Insert();

        Keyed.SetCurrentKey(Keyed."Amount");
        Keyed.SetAscending(Keyed."Amount", false);
        Keyed.SetAscending(Keyed."Amount", true);
        Assert.IsTrue(Keyed.FindFirst(), 'FindFirst after SetAscending(true) should succeed');
        Assert.AreEqual(5, Keyed."Amount", 'SetAscending(true): FindFirst must return Amount=5 (smallest)');
    end;

    [Test]
    procedure Record_CurrentKey_DefaultKey_ReturnsPKFields()
    var
        Keyed: Record "ALT Keyed";
        CurrentKeyText: Text;
    begin
        Initialize();
        // Rec.CurrentKey() must not be '' (must contain key field names)
        CurrentKeyText := Keyed.CurrentKey();
        Assert.AreNotEqual('', CurrentKeyText, 'CurrentKey() default must not be empty');
        // PK is "Entry No." so it must be referenced in the key
        Assert.IsTrue(StrPos(CurrentKeyText, 'Entry No.') > 0, 'CurrentKey() must include primary key field Entry No.');
    end;

    [Test]
    procedure Record_CurrentKey_AfterSetCurrentKey_ReturnsNewKey()
    var
        Keyed: Record "ALT Keyed";
        CurrentKeyText: Text;
    begin
        Initialize();
        // SetCurrentKey("Amount"); CurrentKey() must contain 'Amount'
        Keyed.SetCurrentKey(Keyed."Amount");
        CurrentKeyText := Keyed.CurrentKey();
        Assert.IsTrue(StrPos(CurrentKeyText, 'Amount') > 0, 'After SetCurrentKey(Amount), CurrentKey() must contain Amount');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
