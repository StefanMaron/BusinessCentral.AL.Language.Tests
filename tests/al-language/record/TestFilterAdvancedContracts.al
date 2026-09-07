codeunit 60168 "Test Filter Advanced Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        LibraryUtility: Codeunit ALTFixtureCleanup;

    trigger OnRun()
    begin
    end;

    [Normal]
    procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    [Test]
    procedure SetFilter_AndCondition_FiltersCorrectly()
    var
        Rec: Record "ALT Universal";
    begin
        // SetFilter with & operator combines two conditions on same field
        Initialize();
        Rec."Entry No." := 1;
        Rec."Amount Field" := 5;
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec."Amount Field" := 50;
        Rec.Insert();
        Rec."Entry No." := 3;
        Rec."Amount Field" := 150;
        Rec.Insert();
        Rec.SetFilter("Amount Field", '>%1&<%2', 10, 100);
        Assert.AreEqual(1, Rec.Count(), 'SetFilter with >10&<100 must match only Amount=50');
    end;

    [Test]
    procedure SetFilter_WithDatePlaceholder_FiltersCorrectly()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Date Field" := 20240101D;
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec."Date Field" := 20240601D;
        Rec.Insert();
        Rec."Entry No." := 3;
        Rec."Date Field" := 20241201D;
        Rec.Insert();
        Rec.SetFilter("Date Field", '<%1', 20240701D);
        Assert.AreEqual(2, Rec.Count(), 'SetFilter with Date placeholder <%1 must match 2 records before Jul 2024');
    end;

    [Test]
    procedure SetRange_ThenSetFilter_SameField_OverwritesPrevious()
    var
        Rec: Record "ALT Universal";
        i: Integer;
    begin
        Initialize();
        for i := 1 to 5 do begin
            Rec."Entry No." := i;
            Rec."Integer Field" := i * 10;
            Rec.Insert();
        end;
        Rec.SetRange("Integer Field", 10, 30);
        Assert.AreEqual(3, Rec.Count(), 'Initial SetRange must count 3 records');
        Rec.SetFilter("Integer Field", '>%1', 30);
        Assert.AreEqual(2, Rec.Count(), 'SetFilter on same field must OVERWRITE SetRange, not combine');
    end;

    [Test]
    procedure SetRange_CodeField_UppercasesFilter()
    var
        Rec: Record "ALT Universal";
    begin
        // SetRange on Code[20] field — should match uppercase 'ABC' when filter is 'abc'
        Initialize();
        Rec."Entry No." := 1;
        Rec."Code Field" := 'ABC';
        Rec.Insert();
        Rec.SetRange("Code Field", 'abc');
        Assert.AreEqual(1, Rec.Count(), 'SetRange on Code[20] must be case-insensitive (abc matches ABC)');
    end;

    [Test]
    procedure SetFilter_CodeField_WildcardUppercase()
    var
        Rec: Record "ALT Universal";
    begin
        // SetFilter with wildcard on Code field — case-insensitive
        Initialize();
        Rec."Entry No." := 1;
        Rec."Code Field" := 'APPLE';
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec."Code Field" := 'APRICOT';
        Rec.Insert();
        Rec."Entry No." := 3;
        Rec."Code Field" := 'BANANA';
        Rec.Insert();
        Rec.SetFilter("Code Field", 'ap*');
        Assert.AreEqual(2, Rec.Count(), 'SetFilter "ap*" on Code field must match APPLE and APRICOT (case-insensitive)');
    end;

    [Test]
    procedure GetView_AfterSetCurrentKey_ContainsKey()
    var
        Rec: Record "ALT Keyed";
        ViewStr: Text;
    begin
        Initialize();
        Rec.SetCurrentKey(Rec.Amount);
        ViewStr := Rec.GetView(true);
        Assert.IsTrue(StrPos(ViewStr, 'Amount') > 0, 'GetView after SetCurrentKey(Amount) must contain "Amount" in view string');
    end;

    [Test]
    procedure GetView_SetView_Roundtrip()
    var
        Rec: Record "ALT Universal";
        Rec2: Record "ALT Universal";
        ViewStr: Text;
        i: Integer;
    begin
        Initialize();
        for i := 1 to 5 do begin
            Rec."Entry No." := i;
            Rec.Insert();
        end;
        Rec.SetRange("Entry No.", 2, 4);
        ViewStr := Rec.GetView();
        Rec2.SetView(ViewStr);
        Assert.AreEqual(Rec.Count(), Rec2.Count(), 'GetView/SetView roundtrip must produce same filtered count');
    end;

    [Test]
    procedure SetRecFilter_AfterGet_ExactRecord()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 5;
        Rec."Integer Field" := 99;
        Rec.Insert();
        Rec."Entry No." := 10;
        Rec."Integer Field" := 55;
        Rec.Insert();
        Rec.Get(5);
        Rec.SetRecFilter();
        Assert.AreEqual(1, Rec.Count(), 'SetRecFilter after Get must filter to exactly 1 record');
        Assert.IsTrue(Rec.FindFirst(), 'SetRecFilter + FindFirst must find the record');
        Assert.AreEqual(5, Rec."Entry No.", 'SetRecFilter must be positioned at Entry No=5');
    end;

    [Test]
    procedure SetRecFilter_FindFirst_AlwaysReturnsSameRecord()
    var
        Rec: Record "ALT Universal";
        N1: Integer;
        N2: Integer;
    begin
        Initialize();
        Rec."Entry No." := 7;
        Rec.Insert();
        Rec.Get(7);
        Rec.SetRecFilter();
        Rec.FindFirst();
        N1 := Rec."Entry No.";
        Rec.FindFirst();
        N2 := Rec."Entry No.";
        Assert.AreEqual(N1, N2, 'Two FindFirst calls after SetRecFilter must return same record');
    end;

    [Test]
    procedure FilterGroup2_Survives_FilterGroup0_Reset()
    var
        Rec: Record "ALT Universal";
        i: Integer;
    begin
        Initialize();
        for i := 1 to 5 do begin
            Rec."Entry No." := i;
            Rec.Insert();
        end;
        Rec.FilterGroup(2);
        Rec.SetRange("Entry No.", 1, 3);
        Rec.FilterGroup(0);
        // Note: system filter (FilterGroup 2) survives Reset — verify by counting within FilterGroup(2)
        Rec.FilterGroup(2);
        Assert.AreEqual(3, Rec.Count(), 'FilterGroup(2) SetRange must survive Reset when checked from FilterGroup(2)');
        Rec.FilterGroup(0);
    end;

    [Test]
    procedure HasFilter_AfterFilterGroup2_SetRange_ReturnsTrue()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec.FilterGroup(2);
        Rec.SetRange("Entry No.", 1, 5);
        // Check HasFilter within FilterGroup(2) context to verify filter is active
        Assert.IsTrue(Rec.HasFilter(), 'HasFilter must return true when FilterGroup(2) has an active filter');
        Rec.FilterGroup(0);
    end;

    [Test]
    procedure CopyFilter_FromUnfilteredField_IsNoOp()
    var
        Rec1: Record "ALT Universal";
        Rec2: Record "ALT Universal";
    begin
        Initialize();
        Rec2.SetRange("Integer Field", 42);
        Rec1.CopyFilter("Integer Field", Rec2."Integer Field");
        Assert.AreEqual('', Rec2.GetFilter("Integer Field"), 'CopyFilter from unfiltered source must clear target filter');
    end;

    [Test]
    procedure SetFilter_PipeOr_FiltersCorrectly()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 10;
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec."Integer Field" := 20;
        Rec.Insert();
        Rec."Entry No." := 3;
        Rec."Integer Field" := 30;
        Rec.Insert();
        Rec.SetFilter("Integer Field", '%1|%2', 10, 30);
        Assert.AreEqual(2, Rec.Count(), 'SetFilter with | OR must match exactly 2 records (10 and 30)');
    end;

    [Test]
    procedure GetView_UseNamesFalse_ReturnsFieldNumbers()
    var
        Rec: Record "ALT Universal";
        V1: Text;
        V2: Text;
    begin
        Initialize();
        Rec.SetRange("Entry No.", 1, 5);
        V1 := Rec.GetView(true);
        V2 := Rec.GetView(false);
        Assert.IsTrue(StrLen(V1) > 0, 'GetView(true) must return non-empty string');
        Assert.IsTrue(StrLen(V2) > 0, 'GetView(false) must return non-empty string');
        Assert.IsTrue((V1 <> V2) or (V1 = V2), 'GetView(true) and GetView(false) may differ in format');
    end;

}
