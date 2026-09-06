// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-validate-method
// Scope: in-scope
// Fixtures used: ALT Triggered (60002), ALT Trigger Log (60003), ALT Universal (60000)

codeunit 60065 "Test Record Validate"
{
    Subtype = Test;
    TestPermissions = Disabled;
    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Record_Validate_WithNewValue_SetsAndValidates()
    var
        Triggered: Record "ALT Triggered";
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered.Insert(false);
        Triggered.Validate("Watched Field", 'Hello');
        Assert.AreEqual('Hello', Triggered."Watched Field", 'Validate must set the field value to the new value');
    end;

    [Test]
    procedure Record_Validate_WithoutNewValue_ValidatesExistingValue()
    var
        Triggered: Record "ALT Triggered";
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered."Watched Field" := 'Existing';
        Triggered.Insert(false);
        Triggered.Validate("Watched Field");
        Assert.AreEqual('Existing', Triggered."Watched Field", 'Validate without new value must keep existing value');
    end;

    [Test]
    procedure Record_Validate_FiresOnValidateTrigger()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered.Insert(false);
        Triggered.Validate("Watched Field", 'TriggerTest');
        TrigLog.SetRange("TriggerName", 'OnValidate');
        Assert.AreEqual(1, TrigLog.Count(), 'OnValidate trigger must fire exactly once when Validate() is called');
    end;

    [Test]
    procedure Record_Validate_OnValidateNewValue_InTriggerLog()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 1;
        Triggered.Insert(false);
        Triggered.Validate("Watched Field", 'LoggedValue');
        TrigLog.SetRange("TriggerName", 'OnValidate');
        Assert.IsTrue(TrigLog.FindFirst(), 'OnValidate trigger log entry must exist');
        Assert.AreEqual('LoggedValue', TrigLog."NewValue", 'Trigger log must record the new value passed to Validate');
    end;

    [Test]
    procedure Record_FieldError_ThrowsErrorWithDefaultMessage()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec.Get(1);
        asserterror Rec.FieldError("Integer Field");
        Assert.AreNotEqual('', GetLastErrorText(), 'FieldError must throw an error with a non-empty message');
    end;

    [Test]
    procedure Record_FieldError_ThrowsErrorWithCustomMessage()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec.Get(1);
        asserterror Rec.FieldError("Integer Field", 'Custom error message');
        Assert.IsTrue(StrPos(GetLastErrorText(), 'Custom error message') > 0, 'FieldError with custom text must include the custom message');
    end;

    [Test]
    procedure Record_FieldError_ErrorMessageContainsFieldName()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec.Get(1);
        asserterror Rec.FieldError("Integer Field");
        Assert.IsTrue(StrPos(GetLastErrorText(), 'Integer Field') > 0, 'Error message must contain the field name');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
