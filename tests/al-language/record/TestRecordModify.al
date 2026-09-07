// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Triggered (60002), ALT Trigger Log (60003)

codeunit 60051 "Test Record Modify"
{
    Subtype = Test;
    TestPermissions = Disabled;
    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Record_Modify_ExistingRecord_ReturnsTrue()
    var
        Universal: Record "ALT Universal";
        Result: Boolean;
    begin
        Initialize();
        Universal."Entry No." := 1;
        Universal."Integer Field" := 10;
        Universal.Insert();

        Universal.Get(1);
        Result := Universal.Modify();

        Assert.IsTrue(Result, 'Modify() must return true when record exists');
    end;

    [Test]
    procedure Record_Modify_NonExistentRecord_ReturnsFalse()
    var
        Universal: Record "ALT Universal";
        Result: Boolean;
    begin
        Initialize();
        Universal."Entry No." := 9999;
        Universal."Integer Field" := 10;

        Result := Universal.Modify();

        Assert.IsFalse(Result, 'Modify() must return false when record does not exist in table');
    end;

    [Test]
    procedure Record_Modify_RunTriggerTrue_FiresOnModify()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
        InitialCount: Integer;
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered."Name" := 'Test';
        Triggered.Insert(false);

        TrigLog.SetRange("TriggerName", 'OnModify');
        InitialCount := TrigLog.Count();

        Triggered.Get(1);
        Triggered."Value" := 100;
        Triggered.Modify(true);

        TrigLog.SetRange("TriggerName", 'OnModify');
        Assert.AreEqual(InitialCount + 1, TrigLog.Count(), 'OnModify trigger must fire exactly once when RunTrigger=true');
    end;

    [Test]
    procedure Record_Modify_ChangedField_Persisted()
    var
        Universal: Record "ALT Universal";
    begin
        Initialize();
        Universal."Entry No." := 1;
        Universal."Integer Field" := 10;
        Universal.Insert();

        Universal.Get(1);
        Universal."Integer Field" := 42;
        Universal.Modify();

        Universal.Get(1);
        Assert.AreEqual(42, Universal."Integer Field", 'Modified field value must persist in database');
    end;

    [Test]
    procedure Record_ModifyAll_BulkUpdate_AllRecordsUpdated()
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

        Universal.ModifyAll("Integer Field", 99, true);

        Universal.SetRange("Integer Field", 99);
        Count := Universal.Count();
        Assert.AreEqual(3, Count, 'ModifyAll must update all 3 records to value 99');
    end;

    [Test]
    procedure Record_ModifyAll_WithFilter_OnlyMatchingUpdated()
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
        Universal.ModifyAll("Integer Field", 77, true);

        Universal.SetRange("Entry No.");
        Universal.SetRange("Integer Field", 77);
        Count := Universal.Count();
        Assert.AreEqual(3, Count, 'ModifyAll with filter must update only matching records (3), not all 5');
    end;

    [Test]
    procedure Record_ModifyAll_RunTriggerTrue_FiresTriggerPerRecord()
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
        Triggered."Entry No." := 3;
        Triggered."Name" := 'Test3';
        Triggered.Insert(false);

        TrigLog.SetRange("TriggerName", 'OnModify');
        InitialCount := TrigLog.Count();

        Triggered.ModifyAll("Value", 1, true);

        TrigLog.SetRange("TriggerName", 'OnModify');
        Assert.AreEqual(InitialCount + 3, TrigLog.Count(), 'OnModify trigger must fire once per record (3 records)');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
