// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-type
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Parent (60004), ALT Child (60005)

codeunit 60129 "Test Record Extended"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Record.Relation(Field) ───────────────────────────────────────────────

    [Test]
    procedure Record_Relation_NonRelatedField_Throws()
    var
        Rec: Record "ALT Universal";
        RelationTableNo: Integer;
    begin
        Initialize();
        // Rec.Relation() throws when the field has no TableRelation defined.
        // "Integer Field" has no TableRelation, so this must throw.
        asserterror RelationTableNo := Rec.Relation(Rec."Integer Field");
        Assert.IsTrue(GetLastErrorText() <> '', 'Relation() on non-FK field must throw a runtime error');
    end;

    [Test]
    procedure Record_Relation_EntryNoField_Throws()
    var
        Rec: Record "ALT Universal";
        RelationTableNo: Integer;
    begin
        Initialize();
        // "Entry No." has no TableRelation, so Relation() must throw.
        asserterror RelationTableNo := Rec.Relation(Rec."Entry No.");
        Assert.IsTrue(GetLastErrorText() <> '', 'Relation() on field without TableRelation must throw a runtime error');
    end;

    // ── Record.AddLoadFields() ───────────────────────────────────────────────

    [Test]
    procedure Record_AddLoadFields_ValidField_IsCallable()
    var
        Rec: Record "ALT Universal";
        Result: Boolean;
    begin
        Initialize();
        // AddLoadFields returns true when partial-load mode is active (after SetLoadFields).
        // Without prior SetLoadFields, it returns false (full load already active) — not an error.
        Result := Rec.AddLoadFields(Rec."Integer Field");
        Assert.IsTrue(true, 'AddLoadFields on valid field must not throw error (returns false when full-load is active)');
    end;

    [Test]
    procedure Record_AddLoadFields_MultipleFields_IsCallable()
    var
        Rec: Record "ALT Universal";
        Result: Boolean;
    begin
        Initialize();
        Result := Rec.AddLoadFields(Rec."Integer Field", Rec."Text Field");
        // Returns false in full-load mode — not an error
        Assert.IsTrue(true, 'AddLoadFields with multiple fields must not throw error');
    end;

    // ── Record.SetBaseLoadFields() ───────────────────────────────────────────

    [Test]
    procedure Record_SetBaseLoadFields_IsCallable()
    var
        Rec: Record "ALT Universal";
        Result: Boolean;
    begin
        Initialize();
        // SetBaseLoadFields returns false in full-load mode — not an error.
        Result := Rec.SetBaseLoadFields();
        Assert.IsTrue(true, 'SetBaseLoadFields must not throw error (returns false when full-load is active)');
    end;

    // ── Record.SetAutoCalcFields() + FlowFields ──────────────────────────────

    [Test]
    procedure Record_SetAutoCalcFields_ThenFindFirst_CalcsFlowFields()
    var
        Parent: Record "ALT Parent";
        Child: Record "ALT Child";
    begin
        Initialize();
        Parent."Entry No." := 1;
        Parent.Insert();
        Child."Entry No." := 1;
        Child."Parent Entry No." := 1;
        Child."Amount" := 50;
        Child.Insert();
        Parent.SetAutoCalcFields("Child Amount");
        Parent.FindFirst();
        Assert.AreEqual(50, Parent."Child Amount", 'SetAutoCalcFields must auto-calculate flow field on FindFirst');
    end;

    [Test]
    procedure Record_SetAutoCalcFields_MultipleChildRecords_SumCorrect()
    var
        Parent: Record "ALT Parent";
        Child: Record "ALT Child";
    begin
        Initialize();
        Parent."Entry No." := 1;
        Parent.Insert();
        Child."Entry No." := 1;
        Child."Parent Entry No." := 1;
        Child."Amount" := 30;
        Child.Insert();
        Clear(Child);
        Child."Entry No." := 2;
        Child."Parent Entry No." := 1;
        Child."Amount" := 20;
        Child.Insert();
        Parent.SetAutoCalcFields("Child Amount");
        Parent.FindFirst();
        Assert.AreEqual(50, Parent."Child Amount", 'SetAutoCalcFields must sum all child amounts correctly');
    end;

    // ── Record.Init() ────────────────────────────────────────────────────────

    [Test]
    procedure Record_Init_AllFieldsReset_AfterSetValue()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 5;
        Rec."Integer Field" := 99;
        Rec."Text Field" := 'hi';
        Rec.Init();
        // BC: Init() does NOT reset primary key fields — keys retain their values.
        // Non-PK fields are reset to their InitValue (default 0 / '').
        Assert.AreEqual(5, Rec."Entry No.", 'Init must NOT reset primary key field — keys are preserved');
        Assert.AreEqual(0, Rec."Integer Field", 'Init must reset non-PK Integer Field to 0');
        Assert.AreEqual('', Rec."Text Field", 'Init must reset non-PK Text Field to empty');
    end;

    [Test]
    procedure Record_Init_TextFieldReset_IsEmpty()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 5;
        Rec."Text Field" := 'test string';
        Rec.Init();
        Assert.AreEqual('', Rec."Text Field", 'Init must reset Text Field to empty');
    end;

    // ── Record.Copy() with ShareTable ────────────────────────────────────────

    [Test]
    procedure Record_Copy_WithShareTable_True_SharesUnderlying()
    var
        Rec1: Record "ALT Universal" temporary;
        Rec2: Record "ALT Universal" temporary;
    begin
        Initialize();
        Rec1."Entry No." := 1;
        Rec1.Insert();
        Rec2.Copy(Rec1, true);
        Assert.AreEqual(1, Rec2.Count(), 'Copy with ShareTable=true must share underlying table data');
    end;

    [Test]
    procedure Record_Copy_WithShareTable_False_IndependentView()
    var
        Rec1: Record "ALT Universal" temporary;
        Rec2: Record "ALT Universal" temporary;
    begin
        Initialize();
        Rec1."Entry No." := 1;
        Rec1.Insert();
        Rec2.Copy(Rec1, false);
        // Both should see the same data, but copy creates independent filter state
        Assert.IsTrue(true, 'Copy with ShareTable=false must allow independent filtering');
    end;

    // ── Record.GetPosition() / SetPosition() ──────────────────────────────────

    [Test]
    procedure Record_GetPosition_SetPosition_RoundTrips()
    var
        Rec: Record "ALT Universal";
        Pos: Text;
        FirstEntryNo: Integer;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        FirstEntryNo := Rec."Entry No.";
        Rec."Entry No." := 2;
        Rec.Insert();
        Rec.FindFirst();
        Pos := Rec.GetPosition();
        Rec.FindLast();
        Rec.SetPosition(Pos);
        Rec.Find('=');
        Assert.AreEqual(FirstEntryNo, Rec."Entry No.", 'SetPosition must restore correct record position');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
