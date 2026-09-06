// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-get-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Composite (60001)

codeunit 60053 "Test Record Get"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Record_Get_ExistingKey_ReturnsTrue()
    var
        Rec: Record "ALT Universal";
        Result: Boolean;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 42;
        Rec.Insert();
        Clear(Rec);
        Result := Rec.Get(1);
        Assert.IsTrue(Result, 'Get(1) must return true when Entry No.=1 exists in table');
    end;

    [Test]
    procedure Record_Get_NonExistentKey_ReturnsFalse()
    var
        Rec: Record "ALT Universal";
        Result: Boolean;
    begin
        Initialize();
        Result := Rec.Get(9999);
        Assert.IsFalse(Result, 'Get(9999) must return false when no record with Entry No.=9999 exists');
    end;

    [Test]
    procedure Record_Get_CompositeKey_FindsRecord()
    var
        Rec: Record "ALT Composite";
        Result: Boolean;
    begin
        Initialize();
        Rec."Key1" := 1;
        Rec."Key2" := 'ABC';
        Rec."Key3" := 10;
        Rec."Value1" := 'Test Data';
        Rec.Insert();
        Clear(Rec);
        Result := Rec.Get(1, 'ABC', 10);
        Assert.IsTrue(Result, 'Get(1,ABC,10) must return true for composite key match');
    end;

    [Test]
    procedure Record_Get_LoadsAllFields()
    var
        Rec: Record "ALT Universal";
        ExpectedInteger: Integer;
        ExpectedText: Text[100];
    begin
        Initialize();
        ExpectedInteger := 42;
        ExpectedText := 'TestValue';
        Rec."Entry No." := 1;
        Rec."Integer Field" := ExpectedInteger;
        Rec."Text Field" := ExpectedText;
        Rec.Insert();
        Clear(Rec);
        Rec.Get(1);
        Assert.AreEqual(ExpectedInteger, Rec."Integer Field", 'Get() must load Integer Field with correct value');
        Assert.AreEqual(ExpectedText, Rec."Text Field", 'Get() must load Text Field with correct value');
    end;

    [Test]
    procedure Record_GetBySystemId_ValidSystemId_ReturnsTrue()
    var
        Rec: Record "ALT Universal";
        Fetched: Record "ALT Universal";
        SystemId: Guid;
        Result: Boolean;
    begin
        Initialize();
        SystemId := CreateGuid();
        Rec."Entry No." := 1;
        Rec.SystemId := SystemId;
        Rec.Insert(false, true);
        Clear(Fetched);
        Result := Fetched.GetBySystemId(SystemId);
        Assert.IsTrue(Result, 'GetBySystemId(validGuid) must return true when SystemId exists');
    end;

    [Test]
    procedure Record_GetBySystemId_InvalidSystemId_ReturnsFalse()
    var
        Rec: Record "ALT Universal";
        InvalidGuid: Guid;
        Result: Boolean;
    begin
        Initialize();
        InvalidGuid := CreateGuid();
        Result := Rec.GetBySystemId(InvalidGuid);
        Assert.IsFalse(Result, 'GetBySystemId(invalidGuid) must return false when SystemId does not exist');
    end;

    [Test]
    procedure Record_Copy_CopiedRecord_HasSameFilters()
    var
        Rec1: Record "ALT Universal";
        Rec2: Record "ALT Universal";
        FilterText: Text;
    begin
        Initialize();
        Rec1."Entry No." := 1;
        Rec1.Insert();
        Rec1."Entry No." := 2;
        Rec1.Insert();
        Rec1.SetRange("Entry No.", 1, 2);
        FilterText := Rec1.GetFilter("Entry No.");
        Rec2.Copy(Rec1);
        Assert.AreEqual(FilterText, Rec2.GetFilter("Entry No."), 'Copy() must preserve filters from source record');
    end;

    [Test]
    procedure Record_Copy_ShareTableTrue_SameUnderlying()
    var
        Rec1: Record "ALT Universal" temporary;
        Rec2: Record "ALT Universal" temporary;
    begin
        Initialize();
        Rec1."Entry No." := 1;
        Rec1."Integer Field" := 100;
        Rec1.Insert();
        Rec2.Copy(Rec1, true);
        Rec2."Entry No." := 2;
        Rec2."Integer Field" := 100;
        Rec2.Insert();
        Rec1.SetRange("Integer Field", 100);
        Assert.AreEqual(2, Rec1.Count(), 'Copy(true) with shared table reference: both records reference same table data');
    end;

    [Test]
    procedure Record_ChangeCompany_ValidCompany_ChangesContext()
    var
        Rec: Record "ALT Universal";
        Result: Boolean;
    begin
        Initialize();
        Result := Rec.ChangeCompany('');
        Assert.IsTrue(Result, 'ChangeCompany('''') must return true (empty string = current company)');
    end;

    [Test]
    procedure Record_CurrentCompany_ReturnsCompanyName()
    var
        Rec: Record "ALT Universal";
        CompanyName: Text[30];
    begin
        Initialize();
        CompanyName := Rec.CurrentCompany();
        Assert.AreNotEqual('', CompanyName, 'CurrentCompany() must return non-empty company name string');
    end;

    [Test]
    procedure Record_IsTemporary_RegularTable_ReturnsFalse()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Assert.IsFalse(Rec.IsTemporary(), 'IsTemporary() must return false for regular persistent table ALT Universal');
    end;

    [Test]
    procedure Record_IsTemporary_TemporaryTable_ReturnsTrue()
    var
        TempRec: Record "ALT Universal" temporary;
    begin
        Initialize();
        Assert.IsTrue(TempRec.IsTemporary(), 'IsTemporary() must return true for temporary record variable');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
