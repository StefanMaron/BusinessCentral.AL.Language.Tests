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

    // Writer BP (corpus issue 664, microsoft/AL issues 6107 and 8080): FieldRef.Value as the left side of `in [..]` and as the selector of a
    // case statement (Integer, Text and Enum fields). The forms compile; the test pins what they give at runtime.
    [Test]
    procedure FieldRef_Value_InListAndCase_BP()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        FRef: FieldRef;
        Rec: Record "ALT Universal";
        Res: Boolean;
        Arm: Text;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 1;
        Rec."Text Field" := 'Ja';
        Rec."Status Field" := Rec."Status Field"::Active;
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec."Integer Field" := 5;
        Rec."Text Field" := 'Nein';
        Rec."Status Field" := Rec."Status Field"::Closed;
        Rec.Insert();

        RecRef.Open(Database::"ALT Universal");
        RecRef.FindSet();
        repeat
            FRef := RecRef.Field(3);
            Res := Format(FRef.Value) in ['0', '1'];
            Observer.Observe(Format(RecRef.Field(1).Value) + ' int in [0,1]', Format(Res));
            Res := RecRef.Field(6).Value() in ['Ano', 'Ja'];
            Observer.Observe(Format(RecRef.Field(1).Value) + ' text in [Ano,Ja]', Format(Res));
            Arm := 'none';
            case Format(RecRef.Field(15).Value) of
                Format(Rec."Status Field"::Active):
                    Arm := 'Active';
                Format(Rec."Status Field"::Closed):
                    Arm := 'Closed';
                else
                    Arm := 'else';
            end;
            Observer.Observe(Format(RecRef.Field(1).Value) + ' enum case', Arm);
            Arm := 'none';
            case Format(RecRef.Field(3).Value) of
                '1':
                    Arm := 'one';
                '5':
                    Arm := 'five';
                else
                    Arm := 'else';
            end;
            Observer.Observe(Format(RecRef.Field(1).Value) + ' int case', Arm);
        until RecRef.Next() = 0;
        Observer.Finish();
    end;
}
