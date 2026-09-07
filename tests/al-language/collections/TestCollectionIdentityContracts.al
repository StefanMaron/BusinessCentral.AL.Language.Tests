codeunit 60164 "Test Collection Identity"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    trigger OnRun()
    begin
        Cleanup.Initialize();
    end;

    [Test]
    procedure List_IndexOf_MultipleOccurrences_ReturnsFirst()
    var
        L: List of [Integer];
    begin
        L.Add(5);
        L.Add(10);
        L.Add(5);
        L.Add(15);
        Assert.AreEqual(1, L.IndexOf(5), 'List.IndexOf must return index of FIRST occurrence (1-based: position 1)');
    end;

    [Test]
    procedure List_PreservesInsertionOrder()
    var
        L: List of [Text];
    begin
        L.Add('first');
        L.Add('second');
        L.Add('third');
        Assert.AreEqual('first', L.Get(1), 'List must preserve insertion order: first element at index 1');
        Assert.AreEqual('second', L.Get(2), 'List must preserve insertion order: second element at index 2');
        Assert.AreEqual('third', L.Get(3), 'List must preserve insertion order: third element at index 3');
    end;

    [Test]
    procedure List_AddRange_EmptyList_IsNoOp()
    var
        L: List of [Integer];
        Empty: List of [Integer];
    begin
        L.Add(1);
        L.Add(2);
        L.AddRange(Empty);
        Assert.AreEqual(2, L.Count(), 'AddRange with empty list must be a no-op (count stays 2)');
    end;

    [Test]
    procedure List_Contains_ExactMatch_CaseSensitive()
    var
        L: List of [Text];
    begin
        L.Add('Hello');
        Assert.IsTrue(L.Contains('Hello'), 'List.Contains must match exact case');
        Assert.IsFalse(L.Contains('hello'), 'List.Contains must be case-sensitive — lowercase must not match uppercase');
    end;

    [Test]
    procedure Dictionary_Keys_Values_SameOrderConsistency()
    var
        D: Dictionary of [Text, Integer];
        Keys: List of [Text];
        Values: List of [Integer];
    begin
        D.Add('alpha', 1);
        D.Add('beta', 2);
        D.Add('gamma', 3);
        Keys := D.Keys();
        Values := D.Values();
        Assert.AreEqual(D.Get(Keys.Get(1)), Values.Get(1), 'D.Keys()[1] must correspond to D.Values()[1]');
        Assert.AreEqual(D.Get(Keys.Get(2)), Values.Get(2), 'D.Keys()[2] must correspond to D.Values()[2]');
        Assert.AreEqual(D.Get(Keys.Get(3)), Values.Get(3), 'D.Keys()[3] must correspond to D.Values()[3]');
    end;

    [Test]
    procedure Dictionary_Add_ExistingKey_Throws()
    var
        D: Dictionary of [Text, Integer];
    begin
        D.Add('key', 1);
        asserterror D.Add('key', 2);
        Assert.AreNotEqual('', GetLastErrorText(), 'Dictionary.Add on existing key must throw an error');
    end;

    [Test]
    procedure Dictionary_InsertionOrder_Preserved()
    var
        D: Dictionary of [Text, Integer];
        Keys: List of [Text];
    begin
        D.Add('first', 1);
        D.Add('second', 2);
        D.Add('third', 3);
        Keys := D.Keys();
        Assert.AreEqual('first', Keys.Get(1), 'Dictionary.Keys() must preserve insertion order: first');
        Assert.AreEqual('second', Keys.Get(2), 'Dictionary.Keys() must preserve insertion order: second');
        Assert.AreEqual('third', Keys.Get(3), 'Dictionary.Keys() must preserve insertion order: third');
    end;

    [Test]
    procedure Record_AfterRename_StillPositionedAtNewKey()
    var
        Rec: Record "ALT Universal";
    begin
        Cleanup.Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 42;
        Rec.Insert();
        Rec.Get(1);
        Rec.Rename(99);
        Assert.AreEqual(99, Rec."Entry No.", 'After Rename, Rec variable must position at NEW key value');
        Assert.AreEqual(42, Rec."Integer Field", 'After Rename, field values must be preserved');
    end;

    [Test]
    procedure Record_AfterDelete_FieldValuesPreserved()
    var
        Rec: Record "ALT Universal";
    begin
        Cleanup.Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 77;
        Rec.Insert();
        Rec.Get(1);
        Rec.Delete();
        Assert.AreEqual(1, Rec."Entry No.", 'After Delete, Rec."Entry No." must still hold deleted value');
        Assert.AreEqual(77, Rec."Integer Field", 'After Delete, field values must be preserved in variable');
    end;

    [Test]
    procedure Record_Copy_ShareTableFalse_CopiesActiveFilters()
    var
        Rec1: Record "ALT Universal";
        Rec2: Record "ALT Universal";
        i: Integer;
    begin
        Cleanup.Initialize();
        for i := 1 to 5 do begin
            Rec1."Entry No." := i;
            Rec1.Insert();
        end;
        Rec1.SetRange("Entry No.", 2, 4);
        Rec2.Copy(Rec1, false);
        Assert.AreEqual(Rec1.Count(), Rec2.Count(), 'Copy(ShareTable=false) must copy active filters');
    end;

    [Test]
    procedure Record_TwoVariables_IndependentFilters()
    var
        Rec1: Record "ALT Universal";
        Rec2: Record "ALT Universal";
        i: Integer;
    begin
        Cleanup.Initialize();
        for i := 1 to 5 do begin
            Rec1."Entry No." := i;
            Rec1.Insert();
        end;
        Rec1.SetRange("Entry No.", 1, 3);
        Rec2.Reset();
        Assert.AreEqual(3, Rec1.Count(), 'Rec1 with filter 1..3 must count 3');
        Assert.AreEqual(5, Rec2.Count(), 'Rec2 with no filter must count all 5');
    end;

    [Test]
    procedure Record_Init_AfterGet_ResetsNonPKToTableDefaults()
    var
        Rec: Record "ALT Universal";
        Rec2: Record "ALT Universal";
    begin
        Cleanup.Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 99;
        Rec."Text Field" := 'hello';
        Rec.Insert();
        Rec.Get(1);
        Rec.Init();
        // BC documentation: "Keys and timestamps are not initialized."
        // The PK (Entry No.) survives Init() — only non-PK fields are reset.
        Assert.AreEqual(1, Rec."Entry No.", 'Init() must NOT reset the PK — keys survive Init() per BC docs');
        Assert.AreEqual(0, Rec."Integer Field", 'Init() must reset Integer Field to 0');
        Assert.AreEqual('', Rec."Text Field", 'Init() must reset Text Field to empty');
        Assert.IsTrue(Rec2.Get(1), 'Init() must NOT remove record from database');
    end;

    [Test]
    procedure List_EmptyList_Count_IsZero()
    var
        L: List of [Integer];
    begin
        Assert.AreEqual(0, L.Count(), 'Uninitialized/empty List must have Count = 0');
    end;

    [Test]
    procedure List_EmptyList_Contains_ReturnsFalse()
    var
        L: List of [Integer];
    begin
        Assert.IsFalse(L.Contains(42), 'Empty List.Contains must return false for any value');
    end;

    [Test]
    procedure Dictionary_Keys_After_Remove_ExcludesRemoved()
    var
        D: Dictionary of [Text, Integer];
        Keys: List of [Text];
    begin
        D.Add('a', 1);
        D.Add('b', 2);
        D.Add('c', 3);
        D.Remove('b');
        Keys := D.Keys();
        Assert.AreEqual(2, Keys.Count(), 'After Remove, Keys() must have 2 elements');
        Assert.IsFalse(Keys.Contains('b'), 'After Remove, Keys() must not contain removed key');
        Assert.IsTrue(Keys.Contains('a'), 'After Remove, Keys() must still contain "a"');
        Assert.IsTrue(Keys.Contains('c'), 'After Remove, Keys() must still contain "c"');
    end;
}
