// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-find-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Keyed (60006)

codeunit 60054 "Test Record Find"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Record_Find_ExactMatch_ReturnsTrue()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        InsertRecord(Rec, 5);
        Rec."Entry No." := 5;
        Assert.IsTrue(Rec.Find('='), 'Record.Find("=") must return true when record exists');
    end;

    [Test]
    procedure Record_Find_FirstRecord_ReturnsTrue()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        InsertRecord(Rec, 3);
        InsertRecord(Rec, 7);
        InsertRecord(Rec, 1);
        Rec."Entry No." := 0;
        Assert.IsTrue(Rec.Find('-'), 'Record.Find("-") must return true');
        Assert.AreEqual(1, Rec."Entry No.", 'Find("-") must load first record (Entry No. = 1)');
    end;

    [Test]
    procedure Record_Find_LastRecord_ReturnsTrue()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        InsertRecord(Rec, 3);
        InsertRecord(Rec, 7);
        InsertRecord(Rec, 1);
        Rec."Entry No." := 0;
        Assert.IsTrue(Rec.Find('+'), 'Record.Find("+") must return true');
        Assert.AreEqual(7, Rec."Entry No.", 'Find("+") must load last record (Entry No. = 7)');
    end;

    [Test]
    procedure Record_Find_EmptyTable_ReturnsFalse()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Assert.IsFalse(Rec.Find('='), 'Record.Find() on empty table must return false');
    end;

    [Test]
    procedure Record_FindFirst_NonEmptyTable_ReturnsTrue()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        InsertRecord(Rec, 5);
        InsertRecord(Rec, 2);
        InsertRecord(Rec, 8);
        Assert.IsTrue(Rec.FindFirst(), 'Record.FindFirst() on non-empty table must return true');
    end;

    [Test]
    procedure Record_FindFirst_EmptyTable_ReturnsFalse()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Assert.IsFalse(Rec.FindFirst(), 'Record.FindFirst() on empty table must return false');
    end;

    [Test]
    procedure Record_FindFirst_LoadsFirstRecord()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        InsertRecord(Rec, 3);
        InsertRecord(Rec, 1);
        InsertRecord(Rec, 2);
        Assert.IsTrue(Rec.FindFirst(), 'Record.FindFirst() must return true');
        Assert.AreEqual(1, Rec."Entry No.", 'FindFirst() must load first record (Entry No. = 1)');
    end;

    [Test]
    procedure Record_FindLast_NonEmptyTable_ReturnsTrue()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        InsertRecord(Rec, 5);
        InsertRecord(Rec, 2);
        InsertRecord(Rec, 8);
        Assert.IsTrue(Rec.FindLast(), 'Record.FindLast() on non-empty table must return true');
    end;

    [Test]
    procedure Record_FindLast_EmptyTable_ReturnsFalse()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Assert.IsFalse(Rec.FindLast(), 'Record.FindLast() on empty table must return false');
    end;

    [Test]
    procedure Record_FindLast_LoadsLastRecord()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        InsertRecord(Rec, 3);
        InsertRecord(Rec, 1);
        InsertRecord(Rec, 2);
        Assert.IsTrue(Rec.FindLast(), 'Record.FindLast() must return true');
        Assert.AreEqual(3, Rec."Entry No.", 'FindLast() must load last record (Entry No. = 3)');
    end;

    [Test]
    procedure Record_FindSet_MultipleRecords_ReturnsTrue()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        InsertRecord(Rec, 1);
        InsertRecord(Rec, 2);
        InsertRecord(Rec, 3);
        Assert.IsTrue(Rec.FindSet(), 'Record.FindSet() on non-empty table must return true');
    end;

    [Test]
    procedure Record_FindSet_EmptyTable_ReturnsFalse()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Assert.IsFalse(Rec.FindSet(), 'Record.FindSet() on empty table must return false');
    end;

    [Test]
    procedure Record_FindSet_IteratesAllRecords()
    var
        Rec: Record "ALT Universal";
        Count: Integer;
    begin
        Initialize();
        InsertRecord(Rec, 1);
        InsertRecord(Rec, 2);
        InsertRecord(Rec, 3);
        Count := 0;
        if Rec.FindSet() then begin
            Count := 1;
            while Rec.Next() <> 0 do
                Count += 1;
        end;
        Assert.AreEqual(3, Count, 'FindSet + Next iteration must count all 3 records');
    end;

    [Test]
    procedure Record_FindSet_ForUpdateTrue_LockRecords()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        InsertRecord(Rec, 1);
        InsertRecord(Rec, 2);
        Assert.IsTrue(Rec.FindSet(true, false), 'Record.FindSet(true, false) must return true without error');
    end;

    [Test]
    procedure Record_Next_DefaultStep_AdvancesOne()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        InsertRecord(Rec, 1);
        InsertRecord(Rec, 2);
        InsertRecord(Rec, 3);
        Assert.IsTrue(Rec.FindSet(), 'FindSet must return true');
        Assert.AreEqual(1, Rec."Entry No.", 'Initial record must be Entry No. 1');
        Rec.Next();
        Assert.AreEqual(2, Rec."Entry No.", 'After Next(), Entry No. must be 2');
    end;

    [Test]
    procedure Record_Next_NegativeStep_GoesBackward()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        InsertRecord(Rec, 1);
        InsertRecord(Rec, 2);
        InsertRecord(Rec, 3);
        Assert.IsTrue(Rec.FindLast(), 'FindLast must return true');
        Assert.AreEqual(3, Rec."Entry No.", 'Initial record must be Entry No. 3');
        Rec.Next(-1);
        Assert.AreEqual(2, Rec."Entry No.", 'After Next(-1), Entry No. must be 2');
    end;

    [Test]
    procedure Record_Next_EndOfSet_ReturnsZero()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        InsertRecord(Rec, 1);
        InsertRecord(Rec, 2);
        Assert.IsTrue(Rec.FindSet(), 'FindSet must return true');
        Assert.IsTrue(Rec.Next() <> 0, 'First Next() must not return 0');
        Assert.AreEqual(0, Rec.Next(), 'Second Next() at end of set must return 0');
    end;

    [Test]
    procedure Record_Mark_MarkTrue_MarksRecord()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        InsertRecord(Rec, 1);
        InsertRecord(Rec, 2);
        InsertRecord(Rec, 3);
        Assert.IsTrue(Rec.FindSet(), 'FindSet must return true');
        while Rec.Next() <> 0 do
            if Rec."Entry No." = 2 then
                Rec.Mark(true);
        Rec.MarkedOnly(true);
        Assert.IsTrue(Rec.FindFirst(), 'FindFirst on marked records must return true');
        Assert.AreEqual(2, Rec."Entry No.", 'Only marked record (Entry No. 2) must be found');
    end;

    [Test]
    procedure Record_Mark_MarkFalse_UnmarksRecord()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        InsertRecord(Rec, 1);
        Assert.IsTrue(Rec.FindFirst(), 'FindFirst must return true');
        Rec.Mark(true);
        Rec.Mark(false);
        Rec.MarkedOnly(true);
        Assert.IsFalse(Rec.FindFirst(), 'After unmark, FindFirst on marked records must return false');
    end;

    [Test]
    procedure Record_MarkedOnly_True_ShowsOnlyMarked()
    var
        Rec: Record "ALT Universal";
        Count: Integer;
    begin
        Initialize();
        InsertRecord(Rec, 1);
        InsertRecord(Rec, 2);
        Assert.IsTrue(Rec.FindFirst(), 'FindFirst must return true');
        Rec.Mark(true);
        Rec.MarkedOnly(true);
        Count := Rec.Count();
        Assert.AreEqual(1, Count, 'MarkedOnly(true) must show only 1 marked record');
    end;

    [Test]
    procedure Record_MarkedOnly_False_ShowsAll()
    var
        Rec: Record "ALT Universal";
        Count: Integer;
    begin
        Initialize();
        InsertRecord(Rec, 1);
        InsertRecord(Rec, 2);
        Assert.IsTrue(Rec.FindFirst(), 'FindFirst must return true');
        Rec.Mark(true);
        Rec.MarkedOnly(true);
        Rec.MarkedOnly(false);
        Count := Rec.Count();
        Assert.AreEqual(2, Count, 'MarkedOnly(false) must show all 2 records');
    end;

    [Test]
    procedure Record_ClearMarks_AfterMark_ClearsAllMarks()
    var
        Rec: Record "ALT Universal";
        Count: Integer;
    begin
        Initialize();
        InsertRecord(Rec, 1);
        InsertRecord(Rec, 2);
        if Rec.FindSet() then
            repeat
                Rec.Mark(true);
            until Rec.Next() = 0;
        Rec.ClearMarks();
        Rec.MarkedOnly(true);
        Count := Rec.Count();
        Assert.AreEqual(0, Count, 'After ClearMarks, no marked records should exist');
    end;

    [Test]
    procedure Record_Reset_ClearsFilters()
    var
        Rec: Record "ALT Universal";
        Count: Integer;
    begin
        Initialize();
        InsertRecord(Rec, 1);
        InsertRecord(Rec, 2);
        InsertRecord(Rec, 3);
        Rec.SetRange("Entry No.", 1, 2);
        Count := Rec.Count();
        Assert.AreEqual(2, Count, 'SetRange must limit count to 2');
        Rec.Reset();
        Count := Rec.Count();
        Assert.AreEqual(3, Count, 'After Reset(), all 3 records must be visible');
    end;

    [Test]
    procedure Record_Reset_ResetsSortOrder()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        InsertRecord(Rec, 1);
        InsertRecord(Rec, 2);
        Rec.SetCurrentKey("Integer Field");
        Rec.Reset();
        Assert.IsTrue(Rec.FindFirst(), 'After Reset(), FindFirst must work without error');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    local procedure InsertRecord(var Rec: Record "ALT Universal"; EntryNo: Integer)
    begin
        Rec."Entry No." := EntryNo;
        Rec."Integer Field" := EntryNo * 10;
        Rec."Text Field" := 'Test ' + Format(EntryNo);
        Rec."Code Field" := 'CODE' + Format(EntryNo);
        Rec."Amount Field" := EntryNo * 100;
        Rec.Insert();
    end;
}
