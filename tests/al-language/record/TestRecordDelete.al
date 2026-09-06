// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-delete-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Triggered (60002), ALT Trigger Log (60003)

codeunit 60052 "Test Record Delete"
{
    Subtype = Test;
    TestPermissions = Disabled;
    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Record_Delete_ExistingRecord_ReturnsTrue()
    var
        Universal: Record "ALT Universal";
        Result: Boolean;
        EntryNo: Integer;
    begin
        Initialize();
        Universal."Entry No." := 1;
        Universal."Integer Field" := 10;
        Universal.Insert();
        EntryNo := Universal."Entry No.";

        Universal.Get(EntryNo);
        Result := Universal.Delete();

        Assert.IsTrue(Result, 'Delete() must return true when record exists');
    end;

    [Test]
    procedure Record_Delete_NonExistentRecord_ReturnsFalse()
    var
        Universal: Record "ALT Universal";
        Result: Boolean;
    begin
        Initialize();
        Universal."Entry No." := 9999;
        Universal."Integer Field" := 10;

        Result := Universal.Delete();

        Assert.IsFalse(Result, 'Delete() must return false when record does not exist in table');
    end;

    [Test]
    procedure Record_Delete_RunTriggerTrue_FiresOnDelete()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
        InitialCount: Integer;
        EntryNo: Integer;
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered."Name" := 'Test';
        Triggered.Insert(false);
        EntryNo := Triggered."Entry No.";

        TrigLog.SetRange("TriggerName", 'OnDelete');
        InitialCount := TrigLog.Count();

        Triggered.Get(EntryNo);
        Triggered.Delete(true);

        TrigLog.SetRange("TriggerName", 'OnDelete');
        Assert.AreEqual(InitialCount + 1, TrigLog.Count(), 'OnDelete trigger must fire exactly once when RunTrigger=true');
    end;

    [Test]
    procedure Record_Delete_TableEmptyAfterDelete()
    var
        Universal: Record "ALT Universal";
        EntryNo: Integer;
    begin
        Initialize();
        Universal."Entry No." := 1;
        Universal."Integer Field" := 10;
        Universal.Insert();
        EntryNo := Universal."Entry No.";

        Universal.Get(EntryNo);
        Universal.Delete();

        Assert.IsTrue(Universal.IsEmpty(), 'Table must be empty after deleting the only record');
    end;

    [Test]
    procedure Record_DeleteAll_AllRecordsDeleted_TableIsEmpty()
    var
        Universal: Record "ALT Universal";
    begin
        Initialize();

        Universal."Entry No." := 1;
        Universal."Integer Field" := 10;
        Universal.Insert();
        Universal."Entry No." := 2;
        Universal."Integer Field" := 20;
        Universal.Insert();
        Universal."Entry No." := 3;
        Universal."Integer Field" := 30;
        Universal.Insert();

        Universal.DeleteAll(true);

        Assert.IsTrue(Universal.IsEmpty(), 'Table must be empty after DeleteAll()');
    end;

    [Test]
    procedure Record_DeleteAll_WithFilter_OnlyMatchingDeleted()
    var
        Universal: Record "ALT Universal";
        Count: Integer;
    begin
        Initialize();

        Universal."Entry No." := 1;
        Universal."Integer Field" := 10;
        Universal.Insert();
        Universal."Entry No." := 2;
        Universal."Integer Field" := 20;
        Universal.Insert();
        Universal."Entry No." := 3;
        Universal."Integer Field" := 30;
        Universal.Insert();
        Universal."Entry No." := 4;
        Universal."Integer Field" := 40;
        Universal.Insert();
        Universal."Entry No." := 5;
        Universal."Integer Field" := 50;
        Universal.Insert();

        Universal.SetRange("Entry No.", 1, 3);
        Universal.DeleteAll(true);

        Universal.SetRange("Entry No.");
        Count := Universal.Count();
        Assert.AreEqual(2, Count, 'DeleteAll with filter must delete only matching records (3), leaving 2 of 5 total');
    end;

    [Test]
    procedure Record_DeleteAll_RunTriggerTrue_FiresTriggerPerRecord()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
        InitialCount: Integer;
    begin
        Initialize();

        Triggered."Entry No." := 1;
        Triggered."Name" := 'Test1';
        Triggered.Insert(false);
        Triggered."Entry No." := 2;
        Triggered."Name" := 'Test2';
        Triggered.Insert(false);

        TrigLog.SetRange("TriggerName", 'OnDelete');
        InitialCount := TrigLog.Count();

        Triggered.DeleteAll(true);

        TrigLog.SetRange("TriggerName", 'OnDelete');
        Assert.AreEqual(InitialCount + 2, TrigLog.Count(), 'OnDelete trigger must fire once per record (2 records)');
    end;

    [Test]
    procedure Record_Truncate_AllRecordsDeleted_TableIsEmpty()
    var
        Universal: Record "ALT Universal";
    begin
        Initialize();

        Universal."Entry No." := 1;
        Universal."Integer Field" := 10;
        Universal.Insert();
        Universal."Entry No." := 2;
        Universal."Integer Field" := 20;
        Universal.Insert();
        Universal."Entry No." := 3;
        Universal."Integer Field" := 30;
        Universal.Insert();

        Universal.Truncate();

        Assert.IsTrue(Universal.IsEmpty(), 'Table must be empty after Truncate()');
    end;

    [Test]
    procedure Record_Truncate_ResetAutoIncrement_ResetsCounter()
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();

        TrigLog.Init();
        TrigLog."Entry No." := 0;
        TrigLog."TriggerName" := 'Test1';
        TrigLog.Insert();
        TrigLog."Entry No." := 0;
        TrigLog."TriggerName" := 'Test2';
        TrigLog.Insert();

        TrigLog.Truncate(true);
        Assert.IsTrue(TrigLog.IsEmpty(), 'Truncate(true) must clear the table');

        // After Truncate(true), auto-increment resets to 1
        TrigLog."Entry No." := 0;
        TrigLog."TriggerName" := 'Test3';
        TrigLog.Insert();
        TrigLog.FindFirst();
        Assert.AreEqual(1, TrigLog."Entry No.", 'After Truncate(true), auto-increment resets to 1');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
