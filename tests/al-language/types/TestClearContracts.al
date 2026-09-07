// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000)

codeunit 60181 "Test Clear Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Clear() on simple types ─────────────────────────────────────────────────

    [Test]
    procedure Clear_Integer_ResetsToZero()
    var
        I: Integer;
    begin
        Initialize();
        I := 42;
        Clear(I);
        Assert.AreEqual(0, I, 'Clear(Integer) must reset to 0');
    end;

    [Test]
    procedure Clear_Text_ResetsToEmpty()
    var
        T: Text;
    begin
        Initialize();
        T := 'hello';
        Clear(T);
        Assert.AreEqual('', T, 'Clear(Text) must reset to empty string');
    end;

    [Test]
    procedure Clear_Boolean_ResetsToFalse()
    var
        B: Boolean;
    begin
        Initialize();
        B := true;
        Clear(B);
        Assert.IsFalse(B, 'Clear(Boolean) must reset to false');
    end;

    [Test]
    procedure Clear_Decimal_ResetsToZero()
    var
        D: Decimal;
    begin
        Initialize();
        D := 3.14;
        Clear(D);
        Assert.AreEqual(0, D, 'Clear(Decimal) must reset to 0');
    end;

    [Test]
    procedure Clear_Guid_ResetsToNullGuid()
    var
        G: Guid;
    begin
        Initialize();
        G := CreateGuid();
        Clear(G);
        Assert.IsTrue(IsNullGuid(G), 'Clear(Guid) must reset to null GUID');
    end;

    [Test]
    procedure Clear_Date_ResetsToZero()
    var
        D: Date;
    begin
        Initialize();
        D := Today();
        Clear(D);
        Assert.AreEqual(0D, D, 'Clear(Date) must reset to 0D');
    end;

    // ── Clear() on Record variables ─────────────────────────────────────────────

    [Test]
    procedure Clear_Record_ResetsAllFields()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 42;
        Rec."Integer Field" := 99;
        Rec."Text Field" := 'test';
        Clear(Rec);
        Assert.AreEqual(0, Rec."Entry No.", 'Clear(Record) must reset Entry No. to 0');
        Assert.AreEqual(0, Rec."Integer Field", 'Clear(Record) must reset Integer Field to 0');
        Assert.AreEqual('', Rec."Text Field", 'Clear(Record) must reset Text Field to empty');
    end;

    [Test]
    procedure Clear_Record_DoesNotDeleteFromDB()
    var
        Rec: Record "ALT Universal";
        Rec2: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Clear(Rec);
        Assert.IsTrue(Rec2.Get(1), 'Clear(Record) must NOT remove record from database');
    end;

    // ── ClearAll() vs Clear() ───────────────────────────────────────────────────

    [Test]
    procedure ClearAll_ResetsCodeunitLevelVars()
    var
        I: Integer;
    begin
        Initialize();
        ClearAll();
        Assert.AreEqual(0, I, 'After ClearAll, new Integer variable must be 0 (default)');
        Assert.IsTrue(true, 'ClearAll must not throw');
    end;

    // ── Clear() on collections ──────────────────────────────────────────────────

    [Test]
    procedure Clear_List_ResetsToEmpty()
    var
        L: List of [Integer];
    begin
        Initialize();
        L.Add(1);
        L.Add(2);
        L.Add(3);
        Clear(L);
        Assert.AreEqual(0, L.Count(), 'Clear(List) must reset list to empty');
    end;

    [Test]
    procedure Clear_Dictionary_ResetsToEmpty()
    var
        D: Dictionary of [Text, Integer];
    begin
        Initialize();
        D.Add('a', 1);
        D.Add('b', 2);
        Clear(D);
        Assert.AreEqual(0, D.Count(), 'Clear(Dictionary) must reset dictionary to empty');
    end;

    [Test]
    procedure Clear_TextBuilder_ResetsToEmpty()
    var
        TB: TextBuilder;
    begin
        Initialize();
        TB.Append('hello');
        TB.Append(' world');
        Clear(TB);
        Assert.AreEqual('', TB.ToText(), 'Clear(TextBuilder) must reset to empty string');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
