codeunit 60150 "Test Collection Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    // ========== List<T> Contracts ==========

    [Test]
    procedure List_Assignment_IsReference()
    var
        L1: List of [Integer];
        L2: List of [Integer];
    begin
        // Arrange
        L1.Add(1);
        L1.Add(2);
        L1.Add(3);

        // Act
        L2 := L1;  // reference, not copy
        L2.Add(99); // modify via reference

        // Assert
        Assert.AreEqual(4, L1.Count(), 'List assignment uses reference semantics — original is affected by changes to assigned reference');
        Assert.AreEqual(4, L2.Count(), 'Both list variables point to same data');
    end;

    [Test]
    procedure List_Get_OutOfBounds_Throws()
    var
        L: List of [Integer];
        _D: Integer;
    begin
        // Arrange
        L.Add(1);

        // Act & Assert
        asserterror _D := L.Get(2); // index 2 doesn't exist (only index 1)
        Assert.AreNotEqual('', GetLastErrorText(), 'List.Get with out-of-bounds index must throw');
    end;

    [Test]
    procedure List_RemoveAt_ShiftsElements()
    var
        L: List of [Integer];
    begin
        // Arrange
        L.Add(10);
        L.Add(20);
        L.Add(30);

        // Act
        L.RemoveAt(2); // remove middle element (1-based)

        // Assert
        Assert.AreEqual(2, L.Count(), 'After RemoveAt, count must be 2');
        Assert.AreEqual(10, L.Get(1), 'First element must still be 10');
        Assert.AreEqual(30, L.Get(2), 'Second element must now be 30 (shifted)');
    end;

    [Test]
    procedure List_RemoveRange_RemovesContiguousBlock()
    var
        L: List of [Integer];
    begin
        // Arrange
        L.Add(1);
        L.Add(2);
        L.Add(3);
        L.Add(4);
        L.Add(5);

        // Act
        L.RemoveRange(2, 3); // remove 3 elements starting at index 2 (removes 2,3,4)

        // Assert
        Assert.AreEqual(2, L.Count(), 'RemoveRange(2,3) on 5-element list must leave 2 elements');
        Assert.AreEqual(1, L.Get(1), 'First remaining must be 1');
        Assert.AreEqual(5, L.Get(2), 'Second remaining must be 5');
    end;

    [Test]
    procedure List_Contains_AfterRemove_ReturnsFalse()
    var
        L: List of [Integer];
    begin
        // Arrange
        L.Add(42);
        L.Add(99);

        // Act
        L.Remove(42);

        // Assert
        Assert.IsFalse(L.Contains(42), 'After Remove, Contains must return false');
        Assert.IsTrue(L.Contains(99), 'Remaining element must still be found');
    end;

    [Test]
    procedure List_AddRange_AppendsList()
    var
        L1: List of [Integer];
        L2: List of [Integer];
    begin
        // Arrange
        L1.Add(1);
        L1.Add(2);
        L2.Add(3);
        L2.Add(4);

        // Act
        L1.AddRange(L2);

        // Assert
        Assert.AreEqual(4, L1.Count(), 'AddRange must append all elements');
        Assert.AreEqual(3, L1.Get(3), 'Third element must be first from L2');
        Assert.AreEqual(4, L1.Get(4), 'Fourth element must be second from L2');
    end;

    [Test]
    procedure List_Reverse_ReversesOrder()
    var
        L: List of [Integer];
    begin
        // Arrange
        L.Add(1);
        L.Add(2);
        L.Add(3);

        // Act
        L.Reverse();

        // Assert
        Assert.AreEqual(3, L.Get(1), 'After Reverse, first must be 3');
        Assert.AreEqual(2, L.Get(2), 'After Reverse, second must be 2');
        Assert.AreEqual(1, L.Get(3), 'After Reverse, third must be 1');
    end;

    [Test]
    procedure List_LastIndexOf_FindsLastOccurrence()
    var
        L: List of [Integer];
    begin
        // Arrange
        L.Add(5);
        L.Add(10);
        L.Add(5);
        L.Add(15);

        // Act & Assert
        Assert.AreEqual(3, L.LastIndexOf(5), 'LastIndexOf must return last occurrence position 3');
    end;

    // ========== Dictionary<K,V> Contracts ==========

    [Test]
    procedure Dictionary_Set_ExistingKey_UpdatesValue()
    var
        D: Dictionary of [Text, Integer];
    begin
        // Arrange
        D.Add('key', 1);

        // Act
        D.Set('key', 99); // update existing

        // Assert
        Assert.AreEqual(1, D.Count(), 'Dictionary count must not change after Set on existing key');
        Assert.AreEqual(99, D.Get('key'), 'Set must update the value for existing key');
    end;

    [Test]
    procedure Dictionary_Get_MissingKey_Throws()
    var
        D: Dictionary of [Text, Integer];
        _D: Integer;
    begin
        // Act & Assert
        asserterror _D := D.Get('nothere');
        Assert.AreNotEqual('', GetLastErrorText(), 'Dictionary.Get on missing key must throw');
    end;

    [Test]
    procedure Dictionary_Remove_DecreasesCount()
    var
        D: Dictionary of [Text, Integer];
    begin
        // Arrange
        D.Add('a', 1);
        D.Add('b', 2);

        // Act
        D.Remove('a');

        // Assert
        Assert.AreEqual(1, D.Count(), 'After Remove, count must decrease by 1');
        Assert.IsFalse(D.ContainsKey('a'), 'Removed key must not be found by ContainsKey');
    end;

    [Test]
    procedure Dictionary_Keys_Values_CountMatch()
    var
        D: Dictionary of [Text, Integer];
    begin
        // Arrange
        D.Add('x', 1);
        D.Add('y', 2);
        D.Add('z', 3);

        // Act & Assert
        Assert.AreEqual(D.Count(), D.Keys().Count(), 'Keys() count must equal Dictionary count');
        Assert.AreEqual(D.Count(), D.Values().Count(), 'Values() count must equal Dictionary count');
    end;

    [Test]
    procedure Dictionary_Assignment_IsReference()
    var
        D1: Dictionary of [Text, Integer];
        D2: Dictionary of [Text, Integer];
    begin
        // Arrange
        D1.Add('a', 1);

        // Act
        D2 := D1;
        D2.Add('b', 2);

        // Assert
        Assert.IsTrue(D1.ContainsKey('b'), 'Dictionary assignment uses reference semantics — original sees new key added via reference');
    end;

    // ========== Interface Contracts ==========

    [Test]
    procedure Interface_Error_PropagatesThroughInterface()
    var
        C: Interface IALTCompute;
        D: Codeunit ALTDouble;
        S: Codeunit ALTSquare;
    begin
        // Arrange & Act
        C := D;
        // ALTDouble.Compute(x) = 2*x
        Assert.AreEqual(6, C.Compute(3), 'Interface call must return correct value');

        // Act again with different implementation
        C := S;
        // ALTSquare.Compute(x) = x²
        Assert.AreEqual(9, C.Compute(3), 'After reassignment, interface call must use new implementation');
    end;

    [Test]
    procedure Interface_Reassignment_DoesNotLeakState()
    var
        C: Interface IALTCompute;
        D: Codeunit ALTDouble;
        S: Codeunit ALTSquare;
    begin
        // Arrange, Act & Assert
        C := D;
        Assert.AreEqual(10, C.Compute(5), 'ALTDouble must return 2*5=10');

        C := S;
        Assert.AreEqual(25, C.Compute(5), 'ALTSquare must return 5*5=25');

        C := D;
        Assert.AreEqual(10, C.Compute(5), 'Reassigning back to Double must return 2*5=10 — no state leak');
    end;

    // ========== Temporary Table Contracts ==========

    [Test]
    procedure TempTable_IsTemporary_ReturnsTrue()
    var
        TempRec: Record "ALT Universal" temporary;
    begin
        // Act & Assert
        Assert.IsTrue(TempRec.IsTemporary(), 'Temporary record variable must report IsTemporary=true');
    end;

    [Test]
    procedure TempTable_Operations_NotVisibleToRegularTable()
    var
        TempRec: Record "ALT Universal" temporary;
        RegRec: Record "ALT Universal";
    begin
        // Arrange
        Initialize(); // clears regular table

        // Act
        TempRec."Entry No." := 999;
        TempRec.Insert();

        // Assert
        Assert.AreEqual(0, RegRec.Count(), 'Insert into temp table must NOT be visible to regular table');
        Assert.AreEqual(1, TempRec.Count(), 'Temp table must have 1 record');
    end;

    [Test]
    procedure TempTable_FindFirst_WorksOnTempData()
    var
        TempRec: Record "ALT Universal" temporary;
    begin
        // Arrange
        TempRec."Entry No." := 1;
        TempRec."Integer Field" := 42;
        TempRec.Insert();
        TempRec."Entry No." := 2;
        TempRec."Integer Field" := 99;
        TempRec.Insert();

        // Act
        TempRec.FindFirst();

        // Assert
        Assert.AreEqual(1, TempRec."Entry No.", 'FindFirst on temp table must position at lowest key');
        Assert.AreEqual(42, TempRec."Integer Field", 'FindFirst on temp must load correct field values');
    end;

    [Test]
    procedure TempTable_SetRange_FiltersCorrectly()
    var
        TempRec: Record "ALT Universal" temporary;
    begin
        // Arrange
        TempRec."Entry No." := 1;
        TempRec.Insert();
        TempRec."Entry No." := 2;
        TempRec.Insert();
        TempRec."Entry No." := 3;
        TempRec.Insert();

        // Act
        TempRec.SetRange("Entry No.", 1, 2);

        // Assert
        Assert.AreEqual(2, TempRec.Count(), 'SetRange on temp table must filter same as regular table');
    end;

    [Test]
    procedure TempTable_DeleteAll_ClearsOnlyTempData()
    var
        TempRec: Record "ALT Universal" temporary;
        RegRec: Record "ALT Universal";
    begin
        // Arrange
        Initialize();
        RegRec."Entry No." := 1;
        RegRec.Insert(); // regular table
        TempRec."Entry No." := 1;
        TempRec.Insert(); // temp table

        // Act
        TempRec.DeleteAll(); // clear temp only

        // Assert
        Assert.AreEqual(0, TempRec.Count(), 'Temp DeleteAll must clear temp data');
        Assert.AreEqual(1, RegRec.Count(), 'Temp DeleteAll must NOT affect regular table');
    end;
}
