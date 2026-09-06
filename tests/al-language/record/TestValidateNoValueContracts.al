codeunit 60196 "Test Validate No Value"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    [Test]
    procedure Validate_WithValue_SetsAndFiresTrigger()
    var
        T: Record "ALT Triggered";
        TL: Record "ALT Trigger Log";
    begin
        Initialize();

        T."Entry No." := 1;
        T.Insert(false);

        T.Validate("Watched Field", 'NewValue');

        Assert.AreEqual('NewValue', T."Watched Field", 'Validate(field, value) must set the field');

        TL.SetRange("TriggerName", 'OnValidate');
        Assert.AreEqual(1, TL.Count(), 'OnValidate must fire once');
    end;

    [Test]
    procedure Validate_WithoutValue_FiresTrigger()
    var
        T: Record "ALT Triggered";
        TL: Record "ALT Trigger Log";
    begin
        Initialize();

        T."Entry No." := 1;
        T."Watched Field" := 'CurrentValue';
        T.Insert(false);

        T.Get(1);
        T.Validate("Watched Field");

        TL.SetRange("TriggerName", 'OnValidate');
        Assert.AreEqual(1, TL.Count(), 'Validate() without value must also fire OnValidate trigger');
    end;

    [Test]
    procedure Validate_WithoutValue_UsesCurrentFieldValue()
    var
        T: Record "ALT Triggered";
        TL: Record "ALT Trigger Log";
    begin
        Initialize();

        T."Entry No." := 1;
        T."Watched Field" := 'ShouldBeInLog';
        T.Insert(false);

        T.Get(1);
        T.Validate("Watched Field");

        TL.SetRange("TriggerName", 'OnValidate');
        TL.FindFirst();
        Assert.AreEqual('ShouldBeInLog', TL."NewValue", 'Validate() without value must pass CURRENT field value to trigger');
    end;

    [Test]
    procedure Validate_WithoutValue_DoesNotChangeField()
    var
        T: Record "ALT Triggered";
    begin
        Initialize();

        T."Entry No." := 1;
        T."Watched Field" := 'Unchanged';
        T.Insert(false);

        T.Get(1);
        T.Validate("Watched Field");

        Assert.AreEqual('Unchanged', T."Watched Field", 'Validate() without value must NOT change the field value');
    end;

    [Test]
    procedure Validate_WithValue_ChangesField_ThenFiresTrigger()
    var
        T: Record "ALT Triggered";
        TL: Record "ALT Trigger Log";
    begin
        Initialize();

        T."Entry No." := 1;
        T."Watched Field" := 'Old';
        T.Insert(false);

        T.Get(1);
        T.Validate("Watched Field", 'New');

        Assert.AreEqual('New', T."Watched Field", 'Validate with value must change field to new value');

        TL.SetRange("TriggerName", 'OnValidate');
        TL.FindFirst();
        Assert.AreEqual('New', TL."NewValue", 'Trigger must see the new value "New"');
    end;

    [Test]
    procedure Validate_MultipleNoValue_FiresEachTime()
    var
        T: Record "ALT Triggered";
        TL: Record "ALT Trigger Log";
    begin
        Initialize();

        T."Entry No." := 1;
        T."Watched Field" := 'test';
        T.Insert(false);

        T.Get(1);
        T.Validate("Watched Field");
        T.Validate("Watched Field");
        T.Validate("Watched Field");

        TL.SetRange("TriggerName", 'OnValidate');
        Assert.AreEqual(3, TL.Count(), 'Each Validate() call (with or without value) fires OnValidate once');
    end;

    [Test]
    procedure Validate_NoValue_AfterInsert_FiresTrigger()
    var
        T: Record "ALT Triggered";
        TL: Record "ALT Trigger Log";
    begin
        Initialize();

        T."Entry No." := 1;
        T."Watched Field" := 'PostInsert';
        T.Insert(false);

        T.Validate("Watched Field");

        TL.SetRange("TriggerName", 'OnValidate');
        TL.FindFirst();
        Assert.AreEqual('PostInsert', TL."NewValue", 'Validate after insert must use current field value');
    end;

    [Test]
    procedure Validate_WithValue_ThenNoValue_BothFire()
    var
        T: Record "ALT Triggered";
        TL: Record "ALT Trigger Log";
    begin
        Initialize();

        T."Entry No." := 1;
        T."Watched Field" := 'initial';
        T.Insert(false);

        T.Get(1);
        T.Validate("Watched Field", 'updated');
        T.Validate("Watched Field");

        TL.SetRange("TriggerName", 'OnValidate');
        Assert.AreEqual(2, TL.Count(), 'Both Validate calls must each fire OnValidate');
    end;

    [Test]
    procedure Validate_EmptyField_NoValue_FiresWithEmpty()
    var
        T: Record "ALT Triggered";
        TL: Record "ALT Trigger Log";
    begin
        Initialize();

        T."Entry No." := 1;
        T."Watched Field" := '';
        T.Insert(false);

        T.Get(1);
        T.Validate("Watched Field");

        TL.SetRange("TriggerName", 'OnValidate');
        TL.FindFirst();
        Assert.AreEqual('', TL."NewValue", 'Validate() on empty field must fire trigger with empty value');
    end;

    [Test]
    procedure Validate_Sequence_WithAndWithout()
    var
        T: Record "ALT Triggered";
        TL: Record "ALT Trigger Log";
    begin
        Initialize();

        T."Entry No." := 1;
        T.Insert(false);

        T.Validate("Watched Field", 'step1');
        T.Validate("Watched Field");
        T.Validate("Watched Field", 'step2');

        TL.SetRange("TriggerName", 'OnValidate');
        Assert.AreEqual(3, TL.Count(), 'Three Validate calls (2 with value, 1 without) must fire OnValidate 3 times');
    end;
}
