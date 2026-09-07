// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-joker-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000)

codeunit 60066 "Test Record TestField"
{
    Subtype = Test;
    TestPermissions = Disabled;
    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // Group 1: TestField(Field) — no value arg
    [Test]
    procedure Record_TestField_EmptyInteger_Throws()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 0;
        Rec.Insert();
        Rec.Get(1);
        asserterror Rec.TestField("Integer Field");
        Assert.AreNotEqual('', GetLastErrorText(), 'TestField on zero Integer must throw an error');
    end;

    [Test]
    procedure Record_TestField_PopulatedInteger_Succeeds()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 42;
        Rec.Insert();
        Rec.Get(1);
        Rec.TestField("Integer Field");
        Assert.AreEqual(42, Rec."Integer Field", 'TestField on non-zero Integer must succeed without throwing and preserve value');
    end;

    [Test]
    procedure Record_TestField_EmptyText_Throws()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Text Field" := '';
        Rec.Insert();
        Rec.Get(1);
        asserterror Rec.TestField("Text Field");
        Assert.AreNotEqual('', GetLastErrorText(), 'TestField on empty Text must throw an error');
    end;

    [Test]
    procedure Record_TestField_PopulatedText_Succeeds()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Text Field" := 'value';
        Rec.Insert();
        Rec.Get(1);
        Rec.TestField("Text Field");
        Assert.AreEqual('value', Rec."Text Field", 'TestField on non-empty Text must succeed without throwing and preserve value');
    end;

    
    
    [Test]
    procedure Record_TestField_IntegerMatch_Succeeds()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 7;
        Rec.Insert();
        Rec.Get(1);
        Rec.TestField("Integer Field", 7);
        Assert.AreEqual(7, Rec."Integer Field", 'TestField with matching Integer must succeed without throwing');
    end;

    [Test]
    procedure Record_TestField_IntegerMismatch_Throws()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 7;
        Rec.Insert();
        Rec.Get(1);
        asserterror Rec.TestField("Integer Field", 99);
        Assert.AreNotEqual('', GetLastErrorText(), 'TestField with mismatched Integer must throw an error');
    end;

    
    [Test]
    procedure Record_TestField_DecimalMatch_Succeeds()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Decimal Field" := 3.14;
        Rec.Insert();
        Rec.Get(1);
        Rec.TestField("Decimal Field", 3.14);
        Assert.AreEqual(3.14, Rec."Decimal Field", 'TestField Decimal match must succeed without throwing');
    end;

    [Test]
    procedure Record_TestField_DecimalMismatch_Throws()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Decimal Field" := 3.14;
        Rec.Insert();
        Rec.Get(1);
        asserterror Rec.TestField("Decimal Field", 99.99);
        Assert.AreNotEqual('', GetLastErrorText(), 'TestField Decimal mismatch must throw an error');
    end;

    
    [Test]
    procedure Record_TestField_BooleanTrue_Succeeds()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Boolean Field" := true;
        Rec.Insert();
        Rec.Get(1);
        Rec.TestField("Boolean Field", true);
        Assert.IsTrue(Rec."Boolean Field", 'TestField Boolean true match must succeed without throwing');
    end;

    [Test]
    procedure Record_TestField_BooleanFalse_MatchFalse_Succeeds()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Boolean Field" := false;
        Rec.Insert();
        Rec.Get(1);
        Rec.TestField("Boolean Field", false);
        Assert.IsFalse(Rec."Boolean Field", 'TestField Boolean false match must succeed without throwing');
    end;

    [Test]
    procedure Record_TestField_BooleanMismatch_Throws()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Boolean Field" := false;
        Rec.Insert();
        Rec.Get(1);
        asserterror Rec.TestField("Boolean Field", true);
        Assert.AreNotEqual('', GetLastErrorText(), 'TestField Boolean mismatch must throw an error');
    end;

    
    [Test]
    procedure Record_TestField_TextMatch_Succeeds()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Text Field" := 'abc';
        Rec.Insert();
        Rec.Get(1);
        Rec.TestField("Text Field", 'abc');
        Assert.AreEqual('abc', Rec."Text Field", 'TestField Text match must succeed without throwing');
    end;

    [Test]
    procedure Record_TestField_TextMismatch_Throws()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Text Field" := 'abc';
        Rec.Insert();
        Rec.Get(1);
        asserterror Rec.TestField("Text Field", 'xyz');
        Assert.AreNotEqual('', GetLastErrorText(), 'TestField Text mismatch must throw an error');
    end;

    
    [Test]
    procedure Record_TestField_CodeMatch_Succeeds()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Code Field" := 'ABC';
        Rec.Insert();
        Rec.Get(1);
        Rec.TestField("Code Field", 'ABC');
        Assert.AreEqual('ABC', Rec."Code Field", 'TestField Code match must succeed without throwing');
    end;

    [Test]
    procedure Record_TestField_CodeMismatch_Throws()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Code Field" := 'ABC';
        Rec.Insert();
        Rec.Get(1);
        asserterror Rec.TestField("Code Field", 'XYZ');
        Assert.AreNotEqual('', GetLastErrorText(), 'TestField Code mismatch must throw an error');
    end;

    
    [Test]
    procedure Record_TestField_GuidMatch_Succeeds()
    var
        Rec: Record "ALT Universal";
        G: Guid;
    begin
        Initialize();
        G := CreateGuid();
        Rec."Entry No." := 1;
        Rec."Guid Field" := G;
        Rec.Insert();
        Rec.Get(1);
        Rec.TestField("Guid Field", G);
        Assert.AreEqual(G, Rec."Guid Field", 'TestField Guid match must succeed without throwing');
    end;

    [Test]
    procedure Record_TestField_GuidMismatch_Throws()
    var
        Rec: Record "ALT Universal";
        G: Guid;
        G2: Guid;
    begin
        Initialize();
        G := CreateGuid();
        G2 := CreateGuid();
        Rec."Entry No." := 1;
        Rec."Guid Field" := G;
        Rec.Insert();
        Rec.Get(1);
        asserterror Rec.TestField("Guid Field", G2);
        Assert.AreNotEqual('', GetLastErrorText(), 'TestField Guid mismatch must throw an error');
    end;

    
    [Test]
    procedure Record_TestField_BigIntegerMatch_Succeeds()
    var
        Rec: Record "ALT Universal";
        Expected: BigInteger;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."BigInteger Field" := 1000000000;
        Rec.Insert();
        Rec.Get(1);
        Rec.TestField("BigInteger Field", 1000000000);
        Expected := 1000000000;
        Assert.AreEqual(Expected, Rec."BigInteger Field", 'TestField BigInteger match must succeed without throwing');
    end;

    [Test]
    procedure Record_TestField_BigIntegerMismatch_Throws()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."BigInteger Field" := 1000000000;
        Rec.Insert();
        Rec.Get(1);
        asserterror Rec.TestField("BigInteger Field", 999999999);
        Assert.AreNotEqual('', GetLastErrorText(), 'TestField BigInteger mismatch must throw an error');
    end;

    
    [Test]
    procedure Record_TestField_EnumMatch_Succeeds()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Status Field" := "ALT Status"::Active;
        Rec.Insert();
        Rec.Get(1);
        Rec.TestField("Status Field", "ALT Status"::Active);
        Assert.AreEqual("ALT Status"::Active, Rec."Status Field", 'TestField Enum match must succeed without throwing');
    end;

    [Test]
    procedure Record_TestField_EnumMismatch_Throws()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Status Field" := "ALT Status"::Draft;
        Rec.Insert();
        Rec.Get(1);
        asserterror Rec.TestField("Status Field", "ALT Status"::Active);
        Assert.AreNotEqual('', GetLastErrorText(), 'TestField Enum mismatch must throw an error');
    end;

    
    [Test]
    procedure Record_TestField_AnyMatch_Succeeds()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 5;
        Rec.Insert();
        Rec.Get(1);
        Rec.TestField("Integer Field", 5);
        Assert.AreEqual(5, Rec."Integer Field", 'TestField Any match must succeed without throwing');
    end;

    [Test]
    procedure Record_TestField_AnyMismatch_Throws()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 5;
        Rec.Insert();
        Rec.Get(1);
        asserterror Rec.TestField("Integer Field", 99);
        Assert.AreNotEqual('', GetLastErrorText(), 'TestField Any mismatch must throw an error');
    end;

    
    [Test]
    procedure Record_TestField_AfterInsert_NonZeroInteger_Succeeds()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 123;
        Rec.Insert();
        Rec.Get(1);
        Rec.TestField("Integer Field");
        Assert.AreEqual(123, Rec."Integer Field", 'TestField on newly inserted record with non-zero Integer must succeed');
    end;

    [Test]
    procedure Record_TestField_EmptyCode_Throws()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Code Field" := '';
        Rec.Insert();
        Rec.Get(1);
        asserterror Rec.TestField("Code Field");
        Assert.AreNotEqual('', GetLastErrorText(), 'TestField on empty Code field must throw an error');
    end;

    [Test]
    procedure Record_TestField_CodeBlank_Throws()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec.Get(1);
        asserterror Rec.TestField("Code Field");
        Assert.AreNotEqual('', GetLastErrorText(), 'TestField on blank Code field after insert must throw an error');
    end;

    [Test]
    procedure Record_TestField_BigInteger_Zero_Throws()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."BigInteger Field" := 0;
        Rec.Insert();
        Rec.Get(1);
        asserterror Rec.TestField("BigInteger Field");
        Assert.AreNotEqual('', GetLastErrorText(), 'TestField on zero BigInteger field must throw an error');
    end;

    [Test]
    procedure Record_TestField_Decimal_Zero_Throws()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Decimal Field" := 0;
        Rec.Insert();
        Rec.Get(1);
        asserterror Rec.TestField("Decimal Field");
        Assert.AreNotEqual('', GetLastErrorText(), 'TestField on zero Decimal field must throw an error');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
