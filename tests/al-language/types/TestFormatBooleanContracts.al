codeunit 60197 "Test Format Boolean Contracts"
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
    procedure Format_True_DefaultFormat_ReturnsYes()
    begin
        Initialize();

        Assert.AreEqual('Yes', Format(true), 'Format(true) must return "Yes" in BC English locale default');
    end;

    [Test]
    procedure Format_False_DefaultFormat_ReturnsNo()
    begin
        Initialize();

        Assert.AreEqual('No', Format(false), 'Format(false) must return "No" in BC English locale default');
    end;

    [Test]
    procedure Format_True_StandardFormat2_Returns1()
    begin
        Initialize();

        Assert.AreEqual('1', Format(true, 0, '<Standard Format,2>'), 'Format(true) with Standard Format 2 must return "1"');
    end;

    [Test]
    procedure Format_False_StandardFormat2_Returns0()
    begin
        Initialize();

        Assert.AreEqual('0', Format(false, 0, '<Standard Format,2>'), 'Format(false) with Standard Format 2 must return "0"');
    end;

    [Test]
    procedure Format_True_NotTrue()
    begin
        Initialize();

        Assert.AreNotEqual('True', Format(true), 'Format(true) must NOT return "True" (BC uses "Yes")');
    end;

    [Test]
    procedure Format_True_NotOne()
    begin
        Initialize();

        Assert.AreNotEqual('1', Format(true), 'Format(true) default must NOT return "1" (that requires format string)');
    end;

    [Test]
    procedure Format_Boolean_InRecord()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        Rec."Entry No." := 1;
        Rec."Boolean Field" := true;
        Rec.Insert();

        Rec.Get(1);
        Assert.AreEqual('Yes', Format(Rec."Boolean Field"), 'Format(record."Boolean Field" = true) must return "Yes"');
    end;

    [Test]
    procedure Format_False_Boolean_InRecord()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        Rec."Entry No." := 1;
        Rec."Boolean Field" := false;
        Rec.Insert();

        Rec.Get(1);
        Assert.AreEqual('No', Format(Rec."Boolean Field"), 'Format(record."Boolean Field" = false) must return "No"');
    end;

    [Test]
    procedure Format_LowerCase_True_IsYes()
    begin
        Initialize();

        Assert.AreEqual('yes', LowerCase(Format(true)), 'LowerCase(Format(true)) must be "yes" not "true"');
    end;

    [Test]
    procedure Format_Boolean_Evaluate_Roundtrip()
    var
        B: Boolean;
        S: Text;
        B2: Boolean;
    begin
        Initialize();

        B := true;
        S := Format(B);
        Evaluate(B2, S);

        Assert.AreEqual(B, B2, 'Format(true) → Evaluate must roundtrip correctly');
    end;
}
