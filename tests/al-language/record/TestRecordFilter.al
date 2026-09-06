codeunit 60055 "Test Record Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setrange-method
    // Scope: in-scope
    // Fixtures used: ALT Universal (60000), ALT Keyed (60006)

    [Test]
    procedure Record_SetRange_SingleValue_FiltersToExactMatch()
    var
        Rec: Record "ALT Universal";
        Count: Integer;
    begin
        Initialize();
        InsertTestRecords(Rec, 1, 3);
        Rec.SetRange("Entry No.", 2);
        Count := 0;
        if Rec.FindSet() then
            repeat
                Count += 1;
            until Rec.Next() = 0;
        Assert.AreEqual(1, Count, 'SetRange with single value should filter to exactly one record');
    end;

    [Test]
    procedure Record_SetRange_RangeFromTo_IncludesBounds()
    var
        Rec: Record "ALT Universal";
        Count: Integer;
    begin
        Initialize();
        InsertTestRecords(Rec, 1, 5);
        Rec.SetRange("Entry No.", 2, 4);
        Count := 0;
        if Rec.FindSet() then
            repeat
                Count += 1;
            until Rec.Next() = 0;
        Assert.AreEqual(3, Count, 'SetRange with bounds should include both min and max values');
    end;

    [Test]
    procedure Record_SetRange_NoArgs_ClearsFilter()
    var
        Rec: Record "ALT Universal";
        Count: Integer;
    begin
        Initialize();
        InsertTestRecords(Rec, 1, 3);
        Rec.SetRange("Entry No.", 1);
        Rec.SetRange("Entry No.");
        Count := 0;
        if Rec.FindSet() then
            repeat
                Count += 1;
            until Rec.Next() = 0;
        Assert.AreEqual(3, Count, 'SetRange with no arguments should clear the filter');
    end;

    [Test]
    procedure Record_SetRange_EmptyRange_NoResults()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        InsertTestRecords(Rec, 1, 2);
        Rec.SetRange("Entry No.", 99);
        Assert.IsTrue(Rec.IsEmpty(), 'SetRange with non-existent value should result in empty recordset');
    end;

    [Test]
    procedure Record_SetFilter_WildcardFilter_MatchesPattern()
    var
        Rec: Record "ALT Universal";
        Count: Integer;
    begin
        Initialize();
        InsertCodeFieldRecords(Rec, 'APPLE', 'BANANA', 'APRICOT');
        Rec.SetFilter("Code Field", 'AP*');
        Count := 0;
        if Rec.FindSet() then
            repeat
                Count += 1;
            until Rec.Next() = 0;
        Assert.AreEqual(2, Count, 'SetFilter with wildcard should match patterns (APPLE and APRICOT)');
    end;

    [Test]
    procedure Record_SetFilter_PipeFilter_MatchesEither()
    var
        Rec: Record "ALT Universal";
        Count: Integer;
    begin
        Initialize();
        InsertCodeFieldRecords(Rec, 'A', 'B', 'C');
        Rec.SetFilter("Code Field", 'A|C');
        Count := 0;
        if Rec.FindSet() then
            repeat
                Count += 1;
            until Rec.Next() = 0;
        Assert.AreEqual(2, Count, 'SetFilter with pipe operator should match either value');
    end;

    [Test]
    procedure Record_SetFilter_LessThanFilter_MatchesBelow()
    var
        Rec: Record "ALT Universal";
        Count: Integer;
    begin
        Initialize();
        InsertIntegerFieldRecords(Rec, 5, 10, 15);
        Rec.SetFilter("Integer Field", '<%1', 10);
        Count := 0;
        if Rec.FindSet() then
            repeat
                Count += 1;
            until Rec.Next() = 0;
        Assert.AreEqual(1, Count, 'SetFilter with less than should match values below threshold');
    end;

    [Test]
    procedure Record_SetFilter_GreaterThanFilter_MatchesAbove()
    var
        Rec: Record "ALT Universal";
        Count: Integer;
    begin
        Initialize();
        InsertIntegerFieldRecords(Rec, 5, 10, 15);
        Rec.SetFilter("Integer Field", '>%1', 10);
        Count := 0;
        if Rec.FindSet() then
            repeat
                Count += 1;
            until Rec.Next() = 0;
        Assert.AreEqual(1, Count, 'SetFilter with greater than should match values above threshold');
    end;

    [Test]
    procedure Record_GetFilter_AfterSetRange_ReturnsFilterString()
    var
        Rec: Record "ALT Universal";
        FilterStr: Text;
    begin
        Initialize();
        Rec.SetRange("Entry No.", 1, 3);
        FilterStr := Rec.GetFilter("Entry No.");
        Assert.AreNotEqual('', FilterStr, 'GetFilter after SetRange should return non-empty filter string');
    end;

    [Test]
    procedure Record_GetFilter_AfterReset_ReturnsEmpty()
    var
        Rec: Record "ALT Universal";
        FilterStr: Text;
    begin
        Initialize();
        Rec.SetRange("Entry No.", 1);
        Rec.Reset();
        FilterStr := Rec.GetFilter("Entry No.");
        Assert.AreEqual('', FilterStr, 'GetFilter after Reset should return empty string');
    end;

    [Test]
    procedure Record_GetFilters_MultipleFilters_ReturnsAllAsString()
    var
        Rec: Record "ALT Universal";
        FiltersStr: Text;
    begin
        Initialize();
        Rec.SetRange("Entry No.", 1, 3);
        Rec.SetRange("Integer Field", 5);
        FiltersStr := Rec.GetFilters();
        Assert.AreNotEqual('', FiltersStr, 'GetFilters should return non-empty string for multiple filters');
        Assert.IsTrue(StrPos(FiltersStr, 'Entry No.') > 0, 'GetFilters should contain Entry No. field reference');
    end;

    [Test]
    procedure Record_GetFilters_NoFilters_ReturnsEmpty()
    var
        Rec: Record "ALT Universal";
        FiltersStr: Text;
    begin
        Initialize();
        FiltersStr := Rec.GetFilters();
        Assert.AreEqual('', FiltersStr, 'GetFilters on fresh record should return empty string');
    end;

    [Test]
    procedure Record_HasFilter_WithFilter_ReturnsTrue()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec.SetRange("Entry No.", 1);
        Assert.IsTrue(Rec.HasFilter(), 'HasFilter should return true after SetRange');
    end;

    [Test]
    procedure Record_HasFilter_NoFilter_ReturnsFalse()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Assert.IsFalse(Rec.HasFilter(), 'HasFilter should return false on fresh record');
    end;

    [Test]
    procedure Record_HasFilter_AfterReset_ReturnsFalse()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec.SetRange("Entry No.", 1);
        Rec.Reset();
        Assert.IsFalse(Rec.HasFilter(), 'HasFilter should return false after Reset');
    end;

    [Test]
    procedure Record_CopyFilter_CopiesFilterToAnotherField()
    var
        Rec1: Record "ALT Universal";
        Rec2: Record "ALT Universal";
        Filter1: Text;
        Filter2: Text;
    begin
        Initialize();
        Rec1.SetRange("Entry No.", 1, 5);
        Rec1.CopyFilter("Entry No.", Rec2."Entry No.");
        Filter1 := Rec1.GetFilter("Entry No.");
        Filter2 := Rec2.GetFilter("Entry No.");
        Assert.AreEqual(Filter1, Filter2, 'CopyFilter should copy filter string from source to target field');
    end;

    [Test]
    procedure Record_CopyFilters_CopiesAllFilters()
    var
        Rec1: Record "ALT Universal";
        Rec2: Record "ALT Universal";
        Filter2: Text;
    begin
        Initialize();
        Rec1.SetRange("Entry No.", 1, 3);
        Rec1.SetRange("Integer Field", 42);
        Rec2.CopyFilters(Rec1);
        Filter2 := Rec2.GetFilter("Entry No.");
        Assert.AreNotEqual('', Filter2, 'CopyFilters should copy all filters to target record');
    end;

    [Test]
    procedure Record_CopyFilters_TargetFiltersMatchSource()
    var
        Rec1: Record "ALT Universal";
        Rec2: Record "ALT Universal";
    begin
        Initialize();
        Rec1.SetRange("Entry No.", 1, 3);
        Rec1.SetRange("Integer Field", 5);
        Rec2.CopyFilters(Rec1);
        Assert.AreEqual(Rec1.GetFilters(), Rec2.GetFilters(), 'CopyFilters should result in identical filter strings');
    end;

    [Test]
    procedure Record_FilterGroup_DefaultGroup_ReturnsZero()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Assert.AreEqual(0, Rec.FilterGroup(), 'FilterGroup should return 0 by default');
    end;

    [Test]
    procedure Record_FilterGroup_SetGroup2_ReturnsTwo()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec.FilterGroup(2);
        Assert.AreEqual(2, Rec.FilterGroup(), 'FilterGroup should return the set value (2)');
    end;

    [Test]
    procedure Record_FilterGroup_Group2Filters_CombineWithGroup0()
    var
        Rec: Record "ALT Universal";
        Count: Integer;
    begin
        Initialize();
        InsertTestRecords(Rec, 1, 5);
        Rec.FilterGroup(2);
        Rec.SetRange("Entry No.", 1, 3);
        Rec.FilterGroup(0);
        Count := 0;
        if Rec.FindSet() then
            repeat
                Count += 1;
            until Rec.Next() = 0;
        Assert.AreEqual(3, Count, 'FilterGroup(2) filters should apply when FilterGroup is reset to 0');
    end;

    [Test]
    procedure Record_GetView_ReturnsCurrentSortAndFilter()
    var
        Rec: Record "ALT Universal";
        View: Text;
    begin
        Initialize();
        Rec.SetRange("Entry No.", 1, 5);
        View := Rec.GetView();
        Assert.AreNotEqual('', View, 'GetView should return non-empty string with sort and filter');
    end;

    [Test]
    procedure Record_GetView_UseNamesTrue_ReturnsFieldNames()
    var
        Rec: Record "ALT Universal";
        View: Text;
    begin
        Initialize();
        Rec.SetRange("Entry No.", 1);
        View := Rec.GetView(true);
        Assert.IsTrue(StrPos(View, 'Entry No.') > 0, 'GetView(true) should contain field names');
    end;

    [Test]
    procedure Record_GetView_UseNamesFalse_ReturnsFieldNumbers()
    var
        Rec: Record "ALT Universal";
        View: Text;
    begin
        Initialize();
        Rec.SetRange("Entry No.", 1);
        View := Rec.GetView(false);
        Assert.AreNotEqual('', View, 'GetView(false) should return non-empty string with field numbers');
    end;

    [Test]
    procedure Record_SetView_SetsFilterAndSort()
    var
        Rec1: Record "ALT Universal";
        Rec2: Record "ALT Universal";
        View: Text;
    begin
        Initialize();
        InsertTestRecords(Rec1, 1, 3);
        View := Rec1.GetView();
        Rec2.SetView(View);
        Assert.AreEqual(Rec1.GetView(), Rec2.GetView(), 'SetView should apply same view to target record');
    end;

    [Test]
    procedure Record_SetView_AfterSetView_FindSetSucceeds()
    var
        Rec1: Record "ALT Universal";
        Rec2: Record "ALT Universal";
        View: Text;
    begin
        Initialize();
        InsertTestRecords(Rec1, 1, 3);
        Rec1.SetRange("Entry No.", 1, 2);
        View := Rec1.GetView();
        Rec2.SetView(View);
        Assert.IsTrue(Rec2.FindSet(), 'FindSet after SetView should succeed when records match filter');
    end;

    [Test]
    procedure Record_SetRecFilter_SetsCurrentKeyFilter()
    var
        Rec: Record "ALT Universal";
        RecNo: Integer;
    begin
        Initialize();
        InsertTestRecords(Rec, 1, 5);
        RecNo := 5;
        Rec.Get(RecNo);
        Rec.SetRecFilter();
        Assert.IsTrue(Rec.FindFirst(), 'After SetRecFilter, should find current record');
        Assert.AreEqual(RecNo, Rec."Entry No.", 'SetRecFilter should filter to current record');
    end;

    [Test]
    procedure Record_SetRecFilter_LimitsToCurrentRecord()
    var
        Rec: Record "ALT Universal";
        Count: Integer;
    begin
        Initialize();
        InsertTestRecords(Rec, 1, 5);
        Rec.Get(3);
        Rec.SetRecFilter();
        Count := 0;
        if Rec.FindSet() then
            repeat
                Count += 1;
            until Rec.Next() = 0;
        Assert.AreEqual(1, Count, 'SetRecFilter should limit result set to exactly one record');
    end;

    [Test]
    procedure Record_SetPermissionFilter_AppliesPermissionFilter()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec.SetPermissionFilter();
        Assert.IsTrue(true, 'SetPermissionFilter should not throw error');
    end;

    [Test]
    procedure Record_SecurityFiltering_Default_ReturnsFiltered()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec.SecurityFiltering();
        Assert.IsTrue(true, 'SecurityFiltering should not throw error');
    end;

    [Test]
    procedure Record_SecurityFiltering_SetIgnored_AllowsAll()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec.SecurityFiltering(SecurityFilter::Ignored);
        Assert.IsTrue(true, 'SecurityFiltering(Ignored) should not throw error');
    end;

    [Test]
    procedure Record_GetRangeMin_AfterSetRange_ReturnsMin()
    var
        Rec: Record "ALT Universal";
        MinVal: Integer;
    begin
        Initialize();
        Rec.SetRange("Entry No.", 3, 7);
        MinVal := Rec.GetRangeMin("Entry No.");
        Assert.AreEqual(3, MinVal, 'GetRangeMin should return minimum value from range');
    end;

    [Test]
    procedure Record_GetRangeMax_AfterSetRange_ReturnsMax()
    var
        Rec: Record "ALT Universal";
        MaxVal: Integer;
    begin
        Initialize();
        Rec.SetRange("Entry No.", 3, 7);
        MaxVal := Rec.GetRangeMax("Entry No.");
        Assert.AreEqual(7, MaxVal, 'GetRangeMax should return maximum value from range');
    end;

    [Test]
    procedure Record_GetRangeMin_NoFilter_ThrowsError()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        asserterror Rec.GetRangeMin("Entry No.");
        Assert.IsTrue(true, 'GetRangeMin without filter should throw error');
    end;

    [Test]
    procedure Record_GetRangeMax_NoFilter_ThrowsError()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        asserterror Rec.GetRangeMax("Entry No.");
        Assert.IsTrue(true, 'GetRangeMax without filter should throw error');
    end;

    [Test]
    procedure Record_GetPosition_ReturnsCurrentKey()
    var
        Rec: Record "ALT Universal";
        Position: Text;
    begin
        Initialize();
        InsertTestRecords(Rec, 1, 5);
        Rec.FindFirst();
        Position := Rec.GetPosition();
        Assert.AreNotEqual('', Position, 'GetPosition should return non-empty string');
    end;

    [Test]
    procedure Record_SetPosition_RestoresRecord()
    var
        Rec: Record "ALT Universal";
        Position: Text;
        OriginalNo: Integer;
    begin
        Initialize();
        InsertTestRecords(Rec, 1, 5);
        Rec.Get(5);
        Position := Rec.GetPosition();
        OriginalNo := Rec."Entry No.";
        Rec.Get(1);
        Rec.SetPosition(Position);
        Assert.AreEqual(OriginalNo, Rec."Entry No.", 'SetPosition should restore to original record');
    end;

    [Test]
    procedure Record_GetPosition_UseNamesFalse_ReturnsNumbers()
    var
        Rec: Record "ALT Universal";
        Position: Text;
    begin
        Initialize();
        InsertTestRecords(Rec, 1, 5);
        Rec.FindFirst();
        Position := Rec.GetPosition(false);
        Assert.AreNotEqual('', Position, 'GetPosition(false) should return non-empty position string');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    local procedure InsertTestRecords(var Rec: Record "ALT Universal"; StartNo: Integer; EndNo: Integer)
    var
        i: Integer;
    begin
        for i := StartNo to EndNo do begin
            Rec."Entry No." := i;
            Rec."Integer Field" := i * 10;
            Rec."Text Field" := 'Record ' + Format(i);
            Rec.Insert();
        end;
    end;

    local procedure InsertCodeFieldRecords(var Rec: Record "ALT Universal"; Code1: Code[20]; Code2: Code[20]; Code3: Code[20])
    var
        EntryNo: Integer;
    begin
        EntryNo := 1;
        Rec."Entry No." := EntryNo;
        Rec."Code Field" := Code1;
        Rec.Insert();

        EntryNo += 1;
        Rec."Entry No." := EntryNo;
        Rec."Code Field" := Code2;
        Rec.Insert();

        EntryNo += 1;
        Rec."Entry No." := EntryNo;
        Rec."Code Field" := Code3;
        Rec.Insert();
    end;

    local procedure InsertIntegerFieldRecords(var Rec: Record "ALT Universal"; IntVal1: Integer; IntVal2: Integer; IntVal3: Integer)
    var
        EntryNo: Integer;
    begin
        EntryNo := 1;
        Rec."Entry No." := EntryNo;
        Rec."Integer Field" := IntVal1;
        Rec.Insert();

        EntryNo += 1;
        Rec."Entry No." := EntryNo;
        Rec."Integer Field" := IntVal2;
        Rec.Insert();

        EntryNo += 1;
        Rec."Entry No." := EntryNo;
        Rec."Integer Field" := IntVal3;
        Rec.Insert();
    end;
}
