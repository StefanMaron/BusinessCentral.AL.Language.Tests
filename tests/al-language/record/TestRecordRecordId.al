// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-recordid-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Composite (60001)

codeunit 60062 "Test Record RecordId"
{
    Subtype = Test;
    TestPermissions = Disabled;
    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Record_RecordId_InsertedRecord_HasNonEmptyRecordId()
    var
        Rec: Record "ALT Universal";
        RecordIdText: Text;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 42;
        Rec.Insert();
        RecordIdText := Format(Rec.RecordId());
        Assert.AreNotEqual('', RecordIdText, 'Record.RecordId() must not be empty for inserted record');
    end;

    [Test]
    procedure Record_RecordId_TableNo_MatchesTableId()
    var
        Rec: Record "ALT Universal";
        RecordIdValue: RecordId;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 42;
        Rec.Insert();
        RecordIdValue := Rec.RecordId();
        Assert.AreEqual(60000, RecordIdValue.TableNo(), 'RecordId().TableNo must equal 60000 (ALT Universal table number)');
    end;

    [Test]
    procedure Record_RecordId_CompositeKey_RecordIdContainsAllKeyFields()
    var
        Rec: Record "ALT Composite";
        RecordIdText: Text;
    begin
        Initialize();
        Rec."Key1" := 1;
        Rec."Key2" := 'X';
        Rec."Key3" := 5;
        Rec."Value1" := 'Test Data';
        Rec.Insert();
        RecordIdText := Format(Rec.RecordId());
        Assert.AreNotEqual('', RecordIdText, 'RecordId() for composite key record must not be empty');
        Assert.IsTrue(RecordIdText.Contains('1'), 'RecordId() for composite key must contain key value 1');
    end;

    [Test]
    procedure Record_TableName_ReturnsCorrectName()
    var
        Rec: Record "ALT Universal";
        TableNameResult: Text;
    begin
        Initialize();
        TableNameResult := Rec.TableName();
        Assert.AreEqual('ALT Universal', TableNameResult, 'Record.TableName() must return "ALT Universal"');
    end;

    [Test]
    procedure Record_TableCaption_ReturnsCaption()
    var
        Rec: Record "ALT Universal";
        CaptionResult: Text;
    begin
        Initialize();
        CaptionResult := Rec.TableCaption();
        Assert.AreNotEqual('', CaptionResult, 'Record.TableCaption() must not be empty');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
