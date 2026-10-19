codeunit 60073 "Test FieldRef Value"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure FieldRef_Value_IntegerField_ReturnsCorrectValue()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Universal";
    begin
        // BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-value-method
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 42;
        Rec.Insert();

        RecRef.Open(60000);
        RecRef.FindFirst();
        FldRef := RecRef.Field(3);
        Assert.AreEqual(42, FldRef.Value(), 'Integer Field must equal 42');
    end;

    [Test]
    procedure FieldRef_Value_TextAssign_SetsThenGets()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Universal";
        TextValue: Text[100];
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec.Insert();

        RecRef.Open(60000);
        RecRef.FindFirst();
        FldRef := RecRef.Field(6);  // Text Field
        FldRef.Value := 'hello';
        RecRef.Modify();

        TextValue := FldRef.Value();
        Assert.AreEqual('hello', TextValue, 'Text Field must equal hello');
    end;

    [Test]
    procedure FieldRef_Value_DecimalField_RoundTrips()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Universal";
        DecimalValue: Decimal;
    begin
        Initialize();
        Rec."Entry No." := 3;
        Rec."Decimal Field" := 3.14;
        Rec.Insert();

        RecRef.Open(60000);
        RecRef.FindFirst();
        FldRef := RecRef.Field(5);
        DecimalValue := FldRef.Value();
        Assert.AreEqual(3.14, DecimalValue, 'Decimal Field must equal 3.14');
    end;

    [Test]
    procedure FieldRef_Value_BooleanField_ReturnsTrue()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Universal";
        BoolValue: Boolean;
    begin
        Initialize();
        Rec."Entry No." := 4;
        Rec."Boolean Field" := true;
        Rec.Insert();

        RecRef.Open(60000);
        RecRef.FindFirst();
        FldRef := RecRef.Field(2);
        BoolValue := FldRef.Value();
        Assert.IsTrue(BoolValue, 'Boolean Field must equal true');
    end;

    [Test]
    procedure FieldRef_Value_CodeField_ReturnsCode()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Universal";
        CodeValue: Code[20];
    begin
        Initialize();
        Rec."Entry No." := 5;
        Rec."Code Field" := 'ABC';
        Rec.Insert();

        RecRef.Open(60000);
        RecRef.FindFirst();
        FldRef := RecRef.Field(7);
        CodeValue := FldRef.Value();
        Assert.AreEqual('ABC', CodeValue, 'Code Field must equal ABC');
    end;

    [Test]
    procedure FieldRef_Value_DateField_ReturnsDate()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Universal";
        DateValue: Date;
        ExpectedDate: Date;
    begin
        Initialize();
        Rec."Entry No." := 6;
        ExpectedDate := DMY2Date(1, 1, 2024);
        Rec."Date Field" := ExpectedDate;
        Rec.Insert();

        RecRef.Open(60000);
        RecRef.FindFirst();
        FldRef := RecRef.Field(8);
        DateValue := FldRef.Value();
        Assert.AreEqual(ExpectedDate, DateValue, 'Date Field must equal expected date');
    end;

    [Test]
    procedure FieldRef_Value_ModifyViaFieldRef_PersistsToDatabase()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Universal";
        RecRef2: RecordRef;
        FldRef2: FieldRef;
    begin
        Initialize();
        Rec."Entry No." := 7;
        Rec."Integer Field" := 100;
        Rec.Insert();

        RecRef.Open(60000);
        RecRef.FindFirst();
        FldRef := RecRef.Field(3);
        FldRef.Value := 200;
        RecRef.Modify();

        // Reopen and verify
        RecRef2.Open(60000);
        RecRef2.FindFirst();
        FldRef2 := RecRef2.Field(3);
        Assert.AreEqual(200, FldRef2.Value(), 'Modified Integer Field must persist as 200');
    end;

    [Test]
    procedure FieldRef_Value_AllFieldsAccessible_FieldCount()
    var
        RecRef: RecordRef;
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 8;
        Rec.Insert();

        RecRef.Open(60000);
        Assert.IsTrue(RecRef.FieldCount >= 10, 'FieldCount must be at least 10');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
