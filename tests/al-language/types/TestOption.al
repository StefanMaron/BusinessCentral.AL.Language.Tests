// Scope: in-scope
// ALT Universal field 14: "Option Field" Option(' ',Draft,Active,Closed)

codeunit 60098 "Test Option"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Option default value ─────────────────────────────────────────────────

    [Test]
    procedure Option_Default_IsZero()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec.Get(1);
        Assert.AreEqual(0, Rec."Option Field", 'Option field must default to 0 (first ordinal)');
    end;

    // ── Option assignment and persistence ────────────────────────────────────

    [Test]
    procedure Option_SetValue_Persists()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Option Field" := 2;
        Rec.Insert();
        Rec.Get(1);
        Assert.AreEqual(2, Rec."Option Field", 'Option field must persist value 2 after Insert and Get');
    end;

    // ── Option formatting ───────────────────────────────────────────────────

    [Test]
    procedure Option_Format_ReturnsName()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Option Field" := 1;
        Rec.Insert();
        Assert.AreEqual('Draft', Format(Rec."Option Field"), 'Format(option=1) must return ''Draft''');
    end;

    // ── Option comparison ───────────────────────────────────────────────────

    [Test]
    procedure Option_Comparison_SameValue_Equal()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Option Field" := 2;
        Rec.Insert();
        Rec.Get(1);
        Assert.IsTrue(Rec."Option Field" = 2, 'Fetched option field must equal 2');
    end;

    // ── Option maximum value ────────────────────────────────────────────────

    [Test]
    procedure Option_MaxValue_Stores()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Option Field" := 3;
        Rec.Insert();
        Rec.Get(1);
        Assert.AreEqual(3, Rec."Option Field", 'Option field must store and persist value 3');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
