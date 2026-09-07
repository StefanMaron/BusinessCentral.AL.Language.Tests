// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setrange-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Status (60009)
// Contract tests: each must fail if filtering runtime behavior changes

codeunit 60149 "Test Filter Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;
    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ===== Filter edge cases =====

    [Test]
    procedure SetRange_SameValueBothEnds_EquivalentToSingleValue()
    var
        Rec: Record "ALT Universal";
        i: Integer;
    begin
        Initialize();
        for i := 1 to 3 do begin
            Rec."Entry No." := i;
            Rec.Insert();
        end;
        Rec.SetRange("Entry No.", 2, 2);
        Assert.AreEqual(1, Rec.Count(), 'SetRange(field, x, x) must behave identical to SetRange(field, x)');
    end;

    [Test]
    procedure SetRange_ThenSetRange_NoArgs_ClearsFilter()
    var
        Rec: Record "ALT Universal";
        i: Integer;
    begin
        Initialize();
        for i := 1 to 5 do begin
            Rec."Entry No." := i;
            Rec.Insert();
        end;
        Rec.SetRange("Entry No.", 1, 3);
        Assert.AreEqual(3, Rec.Count(), 'SetRange(1,3) must filter to 3 records');
        Rec.SetRange("Entry No.");
        Assert.AreEqual(5, Rec.Count(), 'SetRange with no args must clear that field filter and return all 5');
    end;

    [Test]
    procedure ClosingDate_InFilter_MatchesClosingDate()
    var
        Rec: Record "ALT Universal";
        Rec2: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Date Field" := ClosingDate(20241231D);
        Rec.Insert();
        Rec2.SetRange("Date Field", ClosingDate(20241231D));
        Assert.AreEqual(1, Rec2.Count(), 'Closing date filter must match closing date records exactly');
    end;

    [Test]
    procedure ClosingDate_DoesNotMatch_NormalDate()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Date Field" := ClosingDate(20241231D);
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec."Date Field" := 20241231D;
        Rec.Insert();
        Rec.SetRange("Date Field", ClosingDate(20241231D));
        Assert.AreEqual(1, Rec.Count(), 'ClosingDate filter must NOT match normal date 20241231D, only closing date');
    end;

    [Test]
    procedure EnumField_SetFilter_Pipe_MatchesMultipleValues()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Status Field" := "ALT Status"::Active;
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec."Status Field" := "ALT Status"::Draft;
        Rec.Insert();
        Rec."Entry No." := 3;
        Rec."Status Field" := "ALT Status"::Closed;
        Rec.Insert();
        Rec.SetFilter("Status Field", '%1|%2', "ALT Status"::Active, "ALT Status"::Draft);
        Assert.AreEqual(2, Rec.Count(), 'Enum SetFilter with | must match both values (Active and Draft only)');
    end;

    [Test]
    procedure FilterGroup2_CombinesWithFilterGroup0_AsAND()
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
        Rec.SetRange("Entry No.", 2, 5);
        Assert.AreEqual(2, Rec.Count(), 'FilterGroup(2) AND FilterGroup(0) must intersect: only 2 and 3');
    end;

    [Test]
    procedure SetRange_WithFilter_FindSet_IteratesOnlyFiltered()
    var
        Rec: Record "ALT Universal";
        Count: Integer;
        i: Integer;
    begin
        Initialize();
        for i := 1 to 5 do begin
            Rec."Entry No." := i;
            Rec.Insert();
        end;
        Rec.SetRange("Entry No.", 2, 4);
        Count := 0;
        if Rec.FindSet() then
            repeat
                Count += 1;
            until Rec.Next() = 0;
        Assert.AreEqual(3, Count, 'FindSet with SetRange(2,4) must iterate exactly 3 records');
    end;

    [Test]
    procedure CopyFilters_TransfersAllFilterGroups()
    var
        Rec: Record "ALT Universal";
        Rec2: Record "ALT Universal";
        i: Integer;
    begin
        Initialize();
        for i := 1 to 5 do begin
            Rec."Entry No." := i;
            Rec.Insert();
        end;
        Rec.SetRange("Entry No.", 1, 3);
        Rec2.CopyFilters(Rec);
        Assert.AreEqual(Rec.Count(), Rec2.Count(), 'CopyFilters must produce same record set on target record');
    end;

    [Test]
    procedure Reset_AfterFilterGroup2_ClearsBothGroups()
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
        Rec.SetRange("Entry No.", 2, 4);
        Rec.Reset();
        Assert.AreEqual(5, Rec.Count(), 'Reset must clear all filter groups and return all 5 records');
    end;

    // ===== Specific error codes and boundary conditions =====

    [Test]
    procedure FindFirst_OnEmptyFilteredSet_ReturnsFalse_NoError()
    var
        Rec: Record "ALT Universal";
        i: Integer;
    begin
        Initialize();
        for i := 1 to 3 do begin
            Rec."Entry No." := i;
            Rec.Insert();
        end;
        Rec.SetRange("Entry No.", 99);
        Assert.IsFalse(Rec.FindFirst(), 'FindFirst on empty filtered set must return false, not throw error');
    end;

    [Test]
    procedure GetRangeMin_WithoutFilter_Throws()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        asserterror Rec.GetRangeMin("Entry No.");
        Assert.AreNotEqual('', GetLastErrorText(), 'GetRangeMin without filter must throw with non-empty error message');
    end;

    [Test]
    procedure GetRangeMax_WithoutFilter_Throws()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        asserterror Rec.GetRangeMax("Entry No.");
        Assert.AreNotEqual('', GetLastErrorText(), 'GetRangeMax without filter must throw with non-empty error message');
    end;

    [Test]
    procedure GetRangeMin_AfterSetRange_ReturnsExactBound()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec.SetRange("Entry No.", 5, 10);
        Assert.AreEqual(5, Rec.GetRangeMin("Entry No."), 'GetRangeMin must return exact lower bound 5 of SetRange(5,10)');
    end;

    [Test]
    procedure GetRangeMax_AfterSetRange_ReturnsExactBound()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec.SetRange("Entry No.", 5, 10);
        Assert.AreEqual(10, Rec.GetRangeMax("Entry No."), 'GetRangeMax must return exact upper bound 10 of SetRange(5,10)');
    end;

    [Test]
    procedure SetFilter_WithWildcard_MatchesPrefix()
    var
        Rec: Record "ALT Universal";
    begin
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
        Rec.SetFilter("Code Field", 'AP*');
        Assert.AreEqual(2, Rec.Count(), 'SetFilter with AP* must match APPLE and APRICOT but not BANANA');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
